import '../models/participant_info_model.dart';

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

  factory Participant.fromContract(
    ParticipantInfo info, {
    required String myAddress,
    required int currentRound,
  }) {
    final isMe = info.address == myAddress;
    final shortAddr = '${info.address.substring(0, 4)}...${info.address.substring(info.address.length - 4)}';
    return Participant(
      name: isMe ? 'Tú' : shortAddr,
      hasDeposited: !info.hasNeverPaid && info.lastPaidRound >= currentRound,
      isMe: isMe,
      turn: info.turn + 1, // contract is 0-based, UI is 1-based
    );
  }
}
