class Participant {
  const Participant({
    required this.name,
    required this.hasDeposited,
    required this.isMe,
    required this.turn,
  });

  final String name;
  final bool hasDeposited;
  final bool isMe;
  final int turn;
}
