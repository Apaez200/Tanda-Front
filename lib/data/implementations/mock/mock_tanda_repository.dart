import '../../../models/tanda_config_model.dart';
import '../../../models/participant_info_model.dart';
import '../../../models/round_info_model.dart';
import '../../../models/investment_pool_model.dart';
import '../../repositories/tanda_repository.dart';

class MockTandaRepository implements TandaRepository {
  final _config = const TandaConfig(
    admin: 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W',
    maxParticipants: 5,
    paymentAmount: 1000000000,
    periodSecs: 2592000,
    paymentToken: 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA',
    cetesToken: 'CD7MNVVTG3V3C7QRLLPOTKRLKJBXNEFZRHSHRZJYMNW2UTOMIMVZB32X',
    collateralBps: 1000,
    status: TandaStatus.active,
    startTime: 1700000000,
    currentRound: 1,
    totalRounds: 5,
  );

  @override
  Future<TandaConfig> getConfig() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _config;
  }

  @override
  Future<ParticipantInfo> getParticipant(String participantAddress) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ParticipantInfo(
      address: participantAddress,
      turn: 2,
      totalPaid: 1000000000,
      collateralHeld: 100000000,
      lastPaidRound: 0,
      hasReceivedPayout: false,
      missedPayments: 0,
    );
  }

  @override
  Future<RoundInfo> getRoundInfo() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return RoundInfo(
      round: 1,
      startTime: DateTime.now()
              .subtract(const Duration(days: 15))
              .millisecondsSinceEpoch ~/
          1000,
      beneficiary: 'GBENEFICIARY000000000000000000000000000000000000000000000',
      paymentsReceived: 3,
      totalCollected: 3000000000,
      isFinalized: false,
    );
  }

  @override
  Future<InvestmentPool> getCollateralPool() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const InvestmentPool(
      totalCetesTokens: 4500000000,
      totalUsdcInvested: 4500000000,
      accumulatedYield: 187500000,
    );
  }

  @override
  Future<List<ParticipantInfo>> getAllParticipants() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ParticipantInfo(address: 'GANA123000000000000000000000000000000000000000000000000000', turn: 0, totalPaid: 1000000000, collateralHeld: 100000000, lastPaidRound: 1, hasReceivedPayout: true, missedPayments: 0),
      ParticipantInfo(address: 'GCARLOS456000000000000000000000000000000000000000000000000', turn: 1, totalPaid: 1000000000, collateralHeld: 100000000, lastPaidRound: 1, hasReceivedPayout: false, missedPayments: 0),
      ParticipantInfo(address: 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W', turn: 2, totalPaid: 1000000000, collateralHeld: 100000000, lastPaidRound: 1, hasReceivedPayout: false, missedPayments: 0),
      ParticipantInfo(address: 'GLAURA012000000000000000000000000000000000000000000000000', turn: 3, totalPaid: 1000000000, collateralHeld: 100000000, lastPaidRound: 1, hasReceivedPayout: false, missedPayments: 0),
      ParticipantInfo(address: 'GROBERTO345000000000000000000000000000000000000000000000', turn: 4, totalPaid: 0, collateralHeld: 100000000, lastPaidRound: 4294967295, hasReceivedPayout: false, missedPayments: 1),
    ];
  }

  @override
  Future<String> register({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_HASH_REGISTER_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> makePayment({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_HASH_PAYMENT_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> finalizeRound({required String adminSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_HASH_FINALIZE_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> claimPayout({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_HASH_CLAIM_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<int> getCollateralPoolRaw() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 500000000; // 500 USDC en colateral
  }

  @override
  Future<List<String>> getTurnOrder() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      'GANA123000000000000000000000000000000000000000000000000000',
      'GCARLOS456000000000000000000000000000000000000000000000000',
      'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W',
      'GLAURA012000000000000000000000000000000000000000000000000',
      'GROBERTO345000000000000000000000000000000000000000000000',
    ];
  }

  @override
  Future<int> getRoundCetes(int round) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 900000000; // 900 CETES tokens por ronda
  }

  @override
  Future<String> handleMissedPayment({required String missedParticipantAddress}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_HASH_MISSED_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> reinvestPayout({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_HASH_REINVEST_${DateTime.now().millisecondsSinceEpoch}';
  }
}
