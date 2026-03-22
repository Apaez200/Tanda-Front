class ParticipantInfo {
  final String address;
  final int turn;
  final int totalPaid;
  final int collateralHeld;
  final int lastPaidRound;
  final bool hasReceivedPayout;
  final int missedPayments;

  double get totalPaidMXN => totalPaid / 1000000000;
  double get collateralHeldMXN => collateralHeld / 1000000000;
  bool get hasNeverPaid => lastPaidRound == 4294967295; // u32::MAX

  const ParticipantInfo({
    required this.address,
    required this.turn,
    required this.totalPaid,
    required this.collateralHeld,
    required this.lastPaidRound,
    required this.hasReceivedPayout,
    required this.missedPayments,
  });
}
