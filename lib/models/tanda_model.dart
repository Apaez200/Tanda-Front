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
}
