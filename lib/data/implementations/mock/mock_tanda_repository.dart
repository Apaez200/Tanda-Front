import '../../../models/tanda_config_model.dart';
import '../../../models/participant_info_model.dart';
import '../../../models/round_info_model.dart';
import '../../../models/investment_pool_model.dart';
import '../../mock/mock_state.dart';
import '../../repositories/tanda_repository.dart';

/// Mock implementation that reads all data from [MockState].
///
/// Every value returned here is derived from the shared state,
/// so deposits, claims, and balance changes are always consistent.
class MockTandaRepository implements TandaRepository {
  final _s = MockState.instance;

  static const _currentRound = 7;
  static const _totalRounds = 10;
  static const _maxParticipants = 10;
  static const _paymentStroops = 1000000000; // $1,000

  @override
  Future<TandaConfig> getConfig() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const TandaConfig(
      admin: 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W',
      maxParticipants: _maxParticipants,
      paymentAmount: _paymentStroops,
      periodSecs: 2592000,
      paymentToken: 'CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA',
      cetesToken: 'CD7MNVVTG3V3C7QRLLPOTKRLKJBXNEFZRHSHRZJYMNW2UTOMIMVZB32X',
      collateralBps: 1000,
      status: TandaStatus.active,
      startTime: 1700000000,
      currentRound: _currentRound,
      totalRounds: _totalRounds,
    );
  }

  @override
  Future<ParticipantInfo> getParticipant(String participantAddress) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return ParticipantInfo(
      address: participantAddress,
      turn: 4,
      totalPaid: _s.userTotalPaidStroops,
      collateralHeld: _s.userCollateralStroops,
      lastPaidRound: _s.userPaidCurrentRound ? _currentRound - 1 : _currentRound - 2,
      hasReceivedPayout: false,
      missedPayments: 0,
    );
  }

  @override
  Future<RoundInfo> getRoundInfo() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return RoundInfo(
      round: _currentRound,
      startTime: DateTime.now()
              .subtract(const Duration(days: 12))
              .millisecondsSinceEpoch ~/
          1000,
      beneficiary: 'GSOFIA_R78900000000000000000000000000000000000000000000000',
      paymentsReceived: _s.paymentsThisRound,
      totalCollected: (_s.paymentsThisRound * _paymentStroops),
      isFinalized: false,
    );
  }

  @override
  Future<InvestmentPool> getCollateralPool() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return InvestmentPool(
      totalCetesTokens: _s.totalCetesStroops,
      totalUsdcInvested: _s.poolInvestedStroops,
      accumulatedYield: _s.accumulatedYieldStroops,
    );
  }

  @override
  Future<List<ParticipantInfo>> getAllParticipants() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final userLastPaid = _s.userPaidCurrentRound ? _currentRound - 1 : _currentRound - 2;

    return [
      const ParticipantInfo(address: 'GANA_LOPEZ0000000000000000000000000000000000000000000000', turn: 0, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: true, missedPayments: 0),
      const ParticipantInfo(address: 'GCARLOS_MZ000000000000000000000000000000000000000000000000', turn: 1, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: true, missedPayments: 0),
      const ParticipantInfo(address: 'GMARIANA_P0000000000000000000000000000000000000000000000000', turn: 2, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: true, missedPayments: 0),
      const ParticipantInfo(address: 'GFERNANDO_000000000000000000000000000000000000000000000000', turn: 3, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: false, missedPayments: 0),
      ParticipantInfo(address: 'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W', turn: 4, totalPaid: _s.userTotalPaidStroops, collateralHeld: _s.userCollateralStroops, lastPaidRound: userLastPaid, hasReceivedPayout: false, missedPayments: 0),
      const ParticipantInfo(address: 'GLAURA_VR00000000000000000000000000000000000000000000000000', turn: 5, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: false, missedPayments: 0),
      const ParticipantInfo(address: 'GSOFIA_R78900000000000000000000000000000000000000000000000', turn: 6, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: false, missedPayments: 0),
      const ParticipantInfo(address: 'GROBERTO_S0000000000000000000000000000000000000000000000000', turn: 7, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: false, missedPayments: 0),
      const ParticipantInfo(address: 'GDIANA_MR00000000000000000000000000000000000000000000000000', turn: 8, totalPaid: 6000000000, collateralHeld: 600000000, lastPaidRound: 4, hasReceivedPayout: false, missedPayments: 1),
      const ParticipantInfo(address: 'GMIGUEL_AG0000000000000000000000000000000000000000000000000', turn: 9, totalPaid: 7000000000, collateralHeld: 700000000, lastPaidRound: 6, hasReceivedPayout: false, missedPayments: 0),
    ];
  }

  @override
  Future<String> register({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_REGISTER_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> makePayment({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    _s.recordDeposit(_s.lastDepositAmount);
    return 'MOCK_TX_PAYMENT_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> finalizeRound({required String adminSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_FINALIZE_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> claimPayout({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    final claimable = _s.poolTotal / _maxParticipants;
    _s.recordClaim(claimable);
    return 'MOCK_TX_CLAIM_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<int> getCollateralPoolRaw() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _s.collateralPoolStroops;
  }

  @override
  Future<List<String>> getTurnOrder() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      'GANA_LOPEZ0000000000000000000000000000000000000000000000',
      'GCARLOS_MZ000000000000000000000000000000000000000000000000',
      'GMARIANA_P0000000000000000000000000000000000000000000000000',
      'GFERNANDO_000000000000000000000000000000000000000000000000',
      'GDTZQTGPOBXU4AA2U3HEQ7RPRBGXKUEZQSAXEGTLSM2CC45BPJLJOB6W',
      'GLAURA_VR00000000000000000000000000000000000000000000000000',
      'GSOFIA_R78900000000000000000000000000000000000000000000000',
      'GROBERTO_S0000000000000000000000000000000000000000000000000',
      'GDIANA_MR00000000000000000000000000000000000000000000000000',
      'GMIGUEL_AG0000000000000000000000000000000000000000000000000',
    ];
  }

  @override
  Future<int> getRoundCetes(int round) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _s.totalCetesStroops ~/ (_currentRound > 0 ? _currentRound : 1);
  }

  @override
  Future<String> handleMissedPayment({required String missedParticipantAddress}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_MISSED_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> reinvestPayout({required String signerSecretKey}) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'MOCK_TX_REINVEST_${DateTime.now().millisecondsSinceEpoch}';
  }
}
