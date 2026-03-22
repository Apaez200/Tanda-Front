import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../../core/constants/contract_constants.dart';
import '../../repositories/wallet_repository.dart';
import '../../services/accesly_service.dart';

class SorobanWalletRepository implements WalletRepository {
  static const _keyPublic = 'tanda_public_key';
  static const _keySecret = 'tanda_secret_key';

  final StellarSDK _sdk = StellarSDK(ContractConstants.horizonUrl);
  final SorobanServer _soroban =
      SorobanServer(ContractConstants.sorobanRpcUrl);

  @override
  Future<String?> getConnectedPublicKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPublic);
  }

  @override
  Future<Map<String, String>> generateTestnetKeypair() async {
    final keyPair = KeyPair.random();
    return {
      'publicKey': keyPair.accountId,
      'secretKey': keyPair.secretSeed,
    };
  }

  @override
  Future<bool> fundTestnetAccount(String publicKey) async {
    debugPrint('[Wallet] Funding testnet account $publicKey via FriendBot...');
    try {
      final funded = await FriendBot.fundTestAccount(publicKey);
      debugPrint('[Wallet] FriendBot result: $funded');
      return funded;
    } catch (e) {
      debugPrint('[Wallet] FriendBot error: $e');
      return false;
    }
  }

  @override
  Future<int> getUsdcBalance(String publicKey) async {
    try {
      final account = await _sdk.accounts.account(publicKey);
      for (final balance in account.balances) {
        if (balance.assetCode == 'USDC' ||
            balance.assetIssuer ==
                'GCYX6CVR3LRHHJ42DZTL5D5UKEOAZZVJ3LHRTR7DG2VYHLLUNSEMH4F4') {
          final amount = double.tryParse(balance.balance) ?? 0;
          return (amount * 1000000).toInt();
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> saveKeypair(String publicKey, String secretKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPublic, publicKey);
    await prefs.setString(_keySecret, secretKey);
  }

  @override
  Future<String?> getSavedSecretKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySecret);
  }

  @override
  Future<void> clearKeypair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPublic);
    await prefs.remove(_keySecret);
  }

  /// Asegura que la cuenta tenga trustline de USDC.
  /// Sin esto, el contrato falla con error #13 al verificar balance.
  /// Debe llamarse antes de register() o cualquier operación con USDC.
  Future<bool> ensureUsdcTrustline({required String signerSecretKey}) async {
    debugPrint('[Wallet] Checking USDC trustline...');
    final keyPair = KeyPair.fromSecretSeed(signerSecretKey);
    final account = await _sdk.accounts.account(keyPair.accountId);

    // Verificar si ya tiene trustline USDC
    for (final balance in account.balances) {
      if (balance.assetCode == 'USDC') {
        debugPrint('[Wallet] USDC trustline already exists');
        return true;
      }
    }

    debugPrint('[Wallet] Creating USDC trustline...');
    // Crear trustline para USDC (asset clásico que respalda el SAC)
    final usdcAsset = AssetTypeCreditAlphaNum4(
      'USDC',
      'GCYX6CVR3LRHHJ42DZTL5D5UKEOAZZVJ3LHRTR7DG2VYHLLUNSEMH4F4',
    );

    final changeTrustOp = ChangeTrustOperationBuilder(usdcAsset, '922337203685.4775807').build();
    final txBuilder = TransactionBuilder(account);
    txBuilder.addOperation(changeTrustOp);
    final tx = txBuilder.build();
    tx.sign(keyPair, Network.TESTNET);

    final response = await _sdk.submitTransaction(tx);
    return response.success;
  }

  /// Crea trustline USDC usando Accesly para firmar (cuando no hay secret key local).
  Future<bool> ensureUsdcTrustlineViaAccesly() async {
    final accesly = AcceslyService();
    if (!accesly.isConnected) return false;

    final accountId = accesly.currentWallet!.stellarAddress;
    final account = await _sdk.accounts.account(accountId);

    // Verificar si ya tiene trustline USDC
    for (final balance in account.balances) {
      if (balance.assetCode == 'USDC') return true;
    }

    // Construir TX de trustline sin firmar
    final usdcAsset = AssetTypeCreditAlphaNum4(
      'USDC',
      'GCYX6CVR3LRHHJ42DZTL5D5UKEOAZZVJ3LHRTR7DG2VYHLLUNSEMH4F4',
    );

    final changeTrustOp =
        ChangeTrustOperationBuilder(usdcAsset, '922337203685.4775807').build();
    final txBuilder = TransactionBuilder(account);
    txBuilder.addOperation(changeTrustOp);
    final tx = txBuilder.build();

    // Enviar a Accesly para que firme y submita
    final xdr = tx.toEnvelopeXdrBase64();
    final result = await accesly.signAndSubmit(xdr);
    return result.txHash.isNotEmpty;
  }

  /// Mints testnet USDC to [recipientPublicKey] using the USDC issuer's key.
  /// The issuer key must be provided via USDC_FAUCET_SECRET env variable.
  /// Uses classic Stellar payment (issuer → recipient).
  Future<bool> mintTestnetUsdc({
    required String recipientPublicKey,
    int? amount,
  }) async {
    final faucetSecret = ContractConstants.usdcFaucetSecret;
    if (faucetSecret.isEmpty) {
      throw Exception(
        'USDC faucet secret not configured. '
        'Run with --dart-define=USDC_FAUCET_SECRET=S...',
      );
    }

    final issuerKeyPair = KeyPair.fromSecretSeed(faucetSecret);
    final issuerAccount = await _sdk.accounts.account(issuerKeyPair.accountId);

    final usdcAsset = AssetTypeCreditAlphaNum4(
      'USDC',
      ContractConstants.usdcIssuerPublic,
    );

    final sendAmount = amount ?? ContractConstants.faucetAmountStroops;
    // Convert stroops (6 decimals) to Stellar amount string
    final amountStr = (sendAmount / 1000000).toStringAsFixed(7);

    final paymentOp = PaymentOperationBuilder(
      recipientPublicKey,
      usdcAsset,
      amountStr,
    ).build();

    final tx = TransactionBuilder(issuerAccount)
        .addOperation(paymentOp)
        .build();
    tx.sign(issuerKeyPair, Network.TESTNET);

    final response = await _sdk.submitTransaction(tx);
    return response.success;
  }

  /// Approve USDC allowance for the tanda contract.
  /// Must be called before make_payment.
  /// [tandaContractId] allows overriding the spender contract (for dynamic tanda IDs).
  Future<String> approveUsdcAllowance({
    required String signerSecretKey,
    required int amount,
    String? tandaContractOverride,
  }) async {
    final keyPair = KeyPair.fromSecretSeed(signerSecretKey);
    final account = await _sdk.accounts.account(keyPair.accountId);

    const usdcContractId = ContractConstants.usdcContractId;
    final tandaContractId = tandaContractOverride ?? ContractConstants.tandaContractId;
    debugPrint('[Wallet] Approving USDC allowance: amount=$amount, spender=$tandaContractId');

    // Get current ledger to compute a valid expiration (current + ~30 days of ledgers)
    // Stellar ledgers close every ~5 seconds, so 30 days ≈ 518,400 ledgers
    final latestLedger = await _soroban.getLatestLedger();
    final expirationLedger = (latestLedger.sequence ?? 0) + 518400;
    debugPrint('[Wallet] Current ledger: ${latestLedger.sequence}, expiration: $expirationLedger');

    // SAC approve(from, spender, amount, expiration_ledger)
    final hostFunction = InvokeContractHostFunction(
      usdcContractId,
      'approve',
      arguments: [
        Address.forAccountId(keyPair.accountId).toXdrSCVal(),
        Address.forContractId(tandaContractId).toXdrSCVal(),
        XdrSCVal.forI128Parts(0, amount),
        XdrSCVal.forU32(expirationLedger),
      ],
    );

    final operation = InvokeHostFuncOpBuilder(hostFunction).build();

    final tx =
        TransactionBuilder(account).addOperation(operation).build();

    final simRequest = SimulateTransactionRequest(tx);
    final simResponse = await _soroban.simulateTransaction(simRequest);

    if (simResponse.resultError != null) {
      throw Exception(
          'Error aprobando allowance: ${simResponse.resultError}');
    }

    tx.sorobanTransactionData = simResponse.transactionData;
    tx.addResourceFee(simResponse.minResourceFee!);
    tx.setSorobanAuth(simResponse.sorobanAuth);

    tx.sign(keyPair, Network.TESTNET);

    final sendResponse = await _soroban.sendTransaction(tx);
    if (sendResponse.status == SendTransactionResponse.STATUS_ERROR) {
      throw Exception(
          'Error enviando allowance: ${sendResponse.errorResultXdr ?? 'desconocido'}');
    }
    final hash = sendResponse.hash;
    if (hash == null) {
      throw Exception('No se recibió hash de transacción de allowance');
    }

    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await _soroban.getTransaction(hash);
      if (status.status == GetTransactionResponse.STATUS_SUCCESS) return hash;
      if (status.status == GetTransactionResponse.STATUS_FAILED) {
        throw Exception('Allowance transaction failed');
      }
    }
    throw Exception('Timeout waiting for allowance confirmation');
  }
}
