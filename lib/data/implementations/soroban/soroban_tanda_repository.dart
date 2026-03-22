import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../../core/constants/contract_constants.dart';
import '../../services/accesly_service.dart';
import '../../../models/tanda_config_model.dart';
import '../../../models/participant_info_model.dart';
import '../../../models/round_info_model.dart';
import '../../../models/investment_pool_model.dart';
import '../../../models/tanda_error_model.dart';
import '../../repositories/tanda_repository.dart';

class SorobanTandaRepository implements TandaRepository {
  final StellarSDK _sdk = StellarSDK(ContractConstants.horizonUrl);
  final SorobanServer _soroban =
      SorobanServer(ContractConstants.sorobanRpcUrl);
  String _contractId = ContractConstants.tandaContractId;

  /// Switch the active contract this repository talks to.
  void setContractId(String id) => _contractId = id;

  /// Current contract ID.
  String get contractId => _contractId;

  // ── Helpers privados ──────────────────────────────────────────────────

  /// Simulates a read-only contract call and returns the result value.
  Future<XdrSCVal> _queryContract(
      String functionName, List<XdrSCVal> args) async {
    debugPrint('[Query] $_contractId.$functionName (${args.length} args)');

    final hostFunction = InvokeContractHostFunction(
      _contractId,
      functionName,
      arguments: args,
    );

    final operation = InvokeHostFuncOpBuilder(hostFunction).build();

    // Use a dummy account for simulation (read-only calls don't need a real one)
    final dummyAccount = Account(
      'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF',
      BigInt.zero,
    );

    final tx = TransactionBuilder(dummyAccount).addOperation(operation).build();

    final simRequest = SimulateTransactionRequest(tx);
    final simResponse = await _soroban.simulateTransaction(simRequest);

    if (simResponse.resultError != null) {
      debugPrint('[Query] $functionName ERROR: ${simResponse.resultError}');
      _handleError(simResponse.resultError!);
    }

    final results = simResponse.results;
    if (results == null || results.isEmpty) {
      debugPrint('[Query] $functionName returned no results');
      throw TandaException(TandaContractError.unknown,
          rawMessage: 'No result from simulation');
    }
    final resultValue = results.first.resultValue;
    if (resultValue == null) {
      debugPrint('[Query] $functionName returned null result value');
      throw TandaException(TandaContractError.unknown,
          rawMessage: 'Null result value from simulation');
    }
    debugPrint('[Query] $functionName OK');
    return resultValue;
  }

  /// Builds, simulates, signs, and sends a contract transaction.
  /// If signerSecretKey is empty and Accesly is connected, uses Accesly to sign.
  Future<String> _invokeContract({
    required String signerSecretKey,
    required String functionName,
    required List<XdrSCVal> args,
  }) async {
    final useAccesly = signerSecretKey.isEmpty && kIsWeb && AcceslyService().isConnected;
    debugPrint('[TX] _invokeContract: fn=$functionName, useAccesly=$useAccesly');

    // Determine the account to use as source
    final String accountId;
    if (useAccesly) {
      accountId = AcceslyService().currentWallet!.stellarAddress;
    } else {
      accountId = KeyPair.fromSecretSeed(signerSecretKey).accountId;
    }

    final account = await _sdk.accounts.account(accountId);

    final hostFunction = InvokeContractHostFunction(
      _contractId,
      functionName,
      arguments: args,
    );

    final operation = InvokeHostFuncOpBuilder(hostFunction).build();

    final tx =
        TransactionBuilder(account).addOperation(operation).build();

    // Simulate to get footprint and resource fees
    debugPrint('[TX] Simulating $functionName...');
    final simRequest = SimulateTransactionRequest(tx);
    final simResponse = await _soroban.simulateTransaction(simRequest);

    if (simResponse.resultError != null) {
      debugPrint('[TX] Simulation ERROR: ${simResponse.resultError}');
      _handleError(simResponse.resultError!);
    }

    debugPrint('[TX] Simulation OK, fee=${simResponse.minResourceFee}');

    // Apply simulation results to transaction
    tx.sorobanTransactionData = simResponse.transactionData;
    tx.addResourceFee(simResponse.minResourceFee!);
    tx.setSorobanAuth(simResponse.sorobanAuth);

    if (useAccesly) {
      // Sign via Accesly's TEE-based signing
      debugPrint('[TX] Sending to Accesly for signing...');
      final xdr = tx.toEnvelopeXdrBase64();
      final result = await AcceslyService().signAndSubmit(xdr);
      debugPrint('[TX] Accesly result: hash=${result.txHash}');
      if (result.txHash.isNotEmpty) return result.txHash;
      // If no hash returned, submit the signed XDR ourselves
      if (result.signedXdr.isNotEmpty) {
        // Parse signed XDR and submit
        final sendResponse = await _soroban.sendTransaction(
          AbstractTransaction.fromEnvelopeXdrString(result.signedXdr) as Transaction,
        );
        if (sendResponse.status == SendTransactionResponse.STATUS_ERROR) {
          _handleError(sendResponse.errorResultXdr ?? 'Error desconocido');
        }
        return sendResponse.hash ?? '';
      }
      throw TandaException(TandaContractError.unknown,
          rawMessage: 'Accesly no devolvió TX hash ni XDR firmado');
    } else {
      // Sign locally with secret key
      final keyPair = KeyPair.fromSecretSeed(signerSecretKey);
      tx.sign(keyPair, Network.TESTNET);
    }

    // Send transaction
    debugPrint('[TX] Sending $functionName to network...');
    final sendResponse = await _soroban.sendTransaction(tx);
    if (sendResponse.status == SendTransactionResponse.STATUS_ERROR) {
      debugPrint('[TX] Send ERROR: ${sendResponse.errorResultXdr}');
      _handleError(sendResponse.errorResultXdr ?? 'Error desconocido');
    }

    final hash = sendResponse.hash;
    if (hash == null) {
      throw TandaException(TandaContractError.unknown,
          rawMessage: 'No se recibió hash de transacción');
    }
    debugPrint('[TX] Sent $functionName, hash=$hash. Polling...');

    // Poll for confirmation (up to 30 seconds)
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await _soroban.getTransaction(hash);
      if (status.status == GetTransactionResponse.STATUS_SUCCESS) {
        debugPrint('[TX] $functionName CONFIRMED after ${(i + 1) * 2}s');
        return hash;
      }
      if (status.status == GetTransactionResponse.STATUS_FAILED) {
        debugPrint('[TX] $functionName FAILED on-chain');
        _handleError('Transacción fallida en la red');
      }
    }
    debugPrint('[TX] $functionName TIMEOUT after 30s');
    throw TandaException(TandaContractError.unknown,
        rawMessage: 'Timeout esperando confirmación');
  }

  /// Maps Soroban error codes to typed TandaException.
  Never _handleError(String rawError) {
    final match = RegExp(r'#(\d+)').firstMatch(rawError);
    if (match != null) {
      final code = int.tryParse(match.group(1) ?? '') ?? -1;
      final error = TandaContractErrorMessage.fromCode(code);
      debugPrint('[Error] Contract error #$code: ${error.userMessage} (raw: $rawError)');
      throw TandaException(error, rawMessage: rawError);
    }
    debugPrint('[Error] Unknown error: $rawError');
    throw TandaException(TandaContractError.unknown, rawMessage: rawError);
  }

  // ── Queries ───────────────────────────────────────────────────────────

  @override
  Future<TandaConfig> getConfig() async {
    final result = await _queryContract('get_config', []);
    final fields = result.map!;
    return TandaConfig(
      admin: _extractAddress(fields, 'admin'),
      maxParticipants: _extractU32(fields, 'max_participants'),
      paymentAmount: _extractI128(fields, 'payment_amount'),
      periodSecs: _extractU64(fields, 'period_secs'),
      paymentToken: _extractAddress(fields, 'payment_token'),
      cetesToken: _extractAddress(fields, 'cetes_token'),
      collateralBps: _extractU32(fields, 'collateral_bps'),
      status: _extractStatus(fields, 'status'),
      startTime: _extractU64(fields, 'start_time'),
      currentRound: _extractU32(fields, 'current_round'),
      totalRounds: _extractU32(fields, 'total_rounds'),
    );
  }

  @override
  Future<ParticipantInfo> getParticipant(String participantAddress) async {
    final args = [
      Address.forAccountId(participantAddress).toXdrSCVal(),
    ];
    final result = await _queryContract('get_participant', args);
    final fields = result.map!;
    return ParticipantInfo(
      address: participantAddress,
      turn: _extractU32(fields, 'turn'),
      totalPaid: _extractI128(fields, 'total_paid'),
      collateralHeld: _extractI128(fields, 'collateral_held'),
      lastPaidRound: _extractU32(fields, 'last_paid_round'),
      hasReceivedPayout: _extractBool(fields, 'has_received_payout'),
      missedPayments: _extractU32(fields, 'missed_payments'),
    );
  }

  @override
  Future<RoundInfo> getRoundInfo() async {
    final result = await _queryContract('get_round_info', []);
    final fields = result.map!;
    return RoundInfo(
      round: _extractU32(fields, 'round'),
      startTime: _extractU64(fields, 'start_time'),
      beneficiary: _extractAddress(fields, 'beneficiary'),
      paymentsReceived: _extractU32(fields, 'payments_received'),
      totalCollected: _extractI128(fields, 'total_collected'),
      isFinalized: _extractBool(fields, 'is_finalized'),
    );
  }

  @override
  Future<InvestmentPool> getCollateralPool() async {
    final result = await _queryContract('get_investment_pool', []);
    final fields = result.map!;
    return InvestmentPool(
      totalCetesTokens: _extractI128(fields, 'total_cetes_tokens'),
      totalUsdcInvested: _extractI128(fields, 'total_usdc_invested'),
      accumulatedYield: _extractI128(fields, 'accumulated_yield'),
    );
  }

  @override
  Future<List<ParticipantInfo>> getAllParticipants() async {
    // get_participants returns Vec<Address>
    final result = await _queryContract('get_participants', []);
    final vec = result.vec;
    if (vec == null || vec.isEmpty) return [];

    final addresses = vec.map((v) {
      final addr = Address.fromXdr(v.address!);
      return addr.accountId ?? addr.contractId ?? '';
    }).where((a) => a.isNotEmpty).toSet().toList();

    return Future.wait(addresses.map(getParticipant));
  }

  @override
  Future<int> getCollateralPoolRaw() async {
    final result = await _queryContract('get_collateral_pool', []);
    final i128 = result.i128!;
    return i128.lo.uint64;
  }

  @override
  Future<List<String>> getTurnOrder() async {
    final result = await _queryContract('get_turn_order', []);
    final vec = result.vec;
    if (vec == null || vec.isEmpty) return [];
    return vec.map((v) {
      final addr = Address.fromXdr(v.address!);
      return addr.accountId ?? addr.contractId ?? '';
    }).where((a) => a.isNotEmpty).toList();
  }

  @override
  Future<int> getRoundCetes(int round) async {
    final result = await _queryContract('get_round_cetes', [
      XdrSCVal.forU32(round),
    ]);
    final i128 = result.i128!;
    return i128.lo.uint64;
  }

  // ── Transacciones ──────────────────────────────────────────────────────

  /// Resolve the account ID from secret key or Accesly wallet.
  String _resolveAccountId(String signerSecretKey) {
    if (signerSecretKey.isNotEmpty) {
      return KeyPair.fromSecretSeed(signerSecretKey).accountId;
    }
    if (kIsWeb && AcceslyService().isConnected) {
      return AcceslyService().currentWallet!.stellarAddress;
    }
    throw TandaException(TandaContractError.unknown,
        rawMessage: 'No hay wallet conectada para firmar');
  }

  @override
  Future<String> register({required String signerSecretKey}) async {
    final accountId = _resolveAccountId(signerSecretKey);
    return _invokeContract(
      signerSecretKey: signerSecretKey,
      functionName: 'register',
      args: [Address.forAccountId(accountId).toXdrSCVal()],
    );
  }

  @override
  Future<String> makePayment({required String signerSecretKey}) async {
    final accountId = _resolveAccountId(signerSecretKey);
    return _invokeContract(
      signerSecretKey: signerSecretKey,
      functionName: 'make_payment',
      args: [Address.forAccountId(accountId).toXdrSCVal()],
    );
  }

  @override
  Future<String> finalizeRound({required String adminSecretKey}) async {
    final accountId = _resolveAccountId(adminSecretKey);
    return _invokeContract(
      signerSecretKey: adminSecretKey,
      functionName: 'finalize_round',
      args: [Address.forAccountId(accountId).toXdrSCVal()],
    );
  }

  @override
  Future<String> claimPayout({required String signerSecretKey}) async {
    final accountId = _resolveAccountId(signerSecretKey);
    return _invokeContract(
      signerSecretKey: signerSecretKey,
      functionName: 'claim_payout',
      args: [Address.forAccountId(accountId).toXdrSCVal()],
    );
  }

  @override
  Future<String> handleMissedPayment({
    required String missedParticipantAddress,
  }) async {
    // Cualquiera puede llamar esta función — usamos la secret key del caller
    // pero el argumento es la address del participante que no pagó.
    // Para simplificar, el caller es quien firma.
    final callerSecret = await _getAnySignerKey();
    return _invokeContract(
      signerSecretKey: callerSecret,
      functionName: 'handle_missed_payment',
      args: [
        Address.forAccountId(missedParticipantAddress).toXdrSCVal(),
      ],
    );
  }

  @override
  Future<String> reinvestPayout({required String signerSecretKey}) async {
    final accountId = _resolveAccountId(signerSecretKey);
    return _invokeContract(
      signerSecretKey: signerSecretKey,
      functionName: 'reinvest_payout',
      args: [Address.forAccountId(accountId).toXdrSCVal()],
    );
  }

  /// Helper: obtiene la secret key guardada para firmar como caller genérico.
  Future<String> _getAnySignerKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('tanda_secret_key');
    if (key == null || key.isEmpty) {
      throw TandaException(TandaContractError.unknown,
          rawMessage: 'No hay wallet conectada para firmar');
    }
    return key;
  }

  // ── Helpers de parseo XDR ──────────────────────────────────────────────

  XdrSCVal _findField(List<XdrSCMapEntry> entries, String key) {
    for (final entry in entries) {
      if (entry.key.sym == key) return entry.val;
    }
    throw TandaException(TandaContractError.unknown,
        rawMessage: 'Campo "$key" no encontrado en respuesta del contrato');
  }

  String _extractAddress(List<XdrSCMapEntry> entries, String key) {
    final val = _findField(entries, key);
    final addr = Address.fromXdr(val.address!);
    return addr.accountId ?? addr.contractId ?? '';
  }

  int _extractU32(List<XdrSCMapEntry> entries, String key) {
    final val = _findField(entries, key);
    return val.u32!.uint32;
  }

  int _extractU64(List<XdrSCMapEntry> entries, String key) {
    final val = _findField(entries, key);
    return val.u64!.uint64;
  }

  int _extractI128(List<XdrSCMapEntry> entries, String key) {
    final val = _findField(entries, key);
    final i128 = val.i128!;
    // For typical tanda amounts, hi64 is 0 and lo64 fits in Dart int
    return i128.lo.uint64;
  }

  bool _extractBool(List<XdrSCMapEntry> entries, String key) {
    final val = _findField(entries, key);
    return val.b ?? false;
  }

  TandaStatus _extractStatus(List<XdrSCMapEntry> entries, String key) {
    final val = _findField(entries, key);
    if (val.u32 != null) {
      switch (val.u32!.uint32) {
        case 0:
          return TandaStatus.registering;
        case 1:
          return TandaStatus.active;
        case 2:
          return TandaStatus.completed;
      }
    }
    final sym = val.sym?.toLowerCase() ?? '';
    if (sym.contains('registering')) return TandaStatus.registering;
    if (sym.contains('active')) return TandaStatus.active;
    if (sym.contains('completed')) return TandaStatus.completed;
    return TandaStatus.registering;
  }
}
