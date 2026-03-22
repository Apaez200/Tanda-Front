class RoundInfo {
  final int round;
  final int startTime;
  final String beneficiary;
  final int paymentsReceived;
  final int totalCollected;
  final bool isFinalized;

  double get totalCollectedMXN => totalCollected / 1000000000;

  DateTime get endDate => DateTime.fromMillisecondsSinceEpoch(
        (startTime + 2592000) * 1000,
      );

  const RoundInfo({
    required this.round,
    required this.startTime,
    required this.beneficiary,
    required this.paymentsReceived,
    required this.totalCollected,
    required this.isFinalized,
  });
}
