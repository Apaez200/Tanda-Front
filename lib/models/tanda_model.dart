import '../models/tanda_config_model.dart';
import '../models/investment_pool_model.dart';

class Tanda {
  const Tanda({
    required this.id,
    required this.name,
    required this.amountPerPerson,
    required this.cutoffDay,
    required this.currentRound,
    required this.totalParticipants,
    required this.poolTotal,
    required this.accumulatedYield,
    required this.myTurn,
  });

  final String id;
  final String name;
  final double amountPerPerson;
  final int cutoffDay;
  final int currentRound;
  final int totalParticipants;
  final double poolTotal;
  final double accumulatedYield;
  final int myTurn;

  factory Tanda.fromContract({
    required TandaConfig config,
    required InvestmentPool pool,
    required int myTurn,
    required String contractId,
    String? savedName,
  }) {
    return Tanda(
      id: contractId,
      name: savedName ?? 'Rendix del Equipo',
      amountPerPerson: config.paymentAmountMXN,
      cutoffDay: 30,
      currentRound: config.currentRound,
      totalParticipants: config.maxParticipants,
      poolTotal: pool.totalUsdcInvestedMXN,
      accumulatedYield: pool.accumulatedYieldMXN,
      myTurn: myTurn,
    );
  }
}
