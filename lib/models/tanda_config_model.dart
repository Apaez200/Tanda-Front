enum TandaStatus { registering, active, completed }

class TandaConfig {
  final String admin;
  final int maxParticipants;
  final int paymentAmount;
  final int periodSecs;
  final String paymentToken;
  final String cetesToken;
  final int collateralBps;
  final TandaStatus status;
  final int startTime;
  final int currentRound;
  final int totalRounds;

  double get paymentAmountMXN => paymentAmount / 1000000000;

  const TandaConfig({
    required this.admin,
    required this.maxParticipants,
    required this.paymentAmount,
    required this.periodSecs,
    required this.paymentToken,
    required this.cetesToken,
    required this.collateralBps,
    required this.status,
    required this.startTime,
    required this.currentRound,
    required this.totalRounds,
  });
}
