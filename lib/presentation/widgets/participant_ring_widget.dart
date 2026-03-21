import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/participant_model.dart';

class ParticipantRingWidget extends StatelessWidget {
  const ParticipantRingWidget({
    super.key,
    required this.participants,
    required this.userHasDeposited,
  });

  final List<Participant> participants;
  final bool userHasDeposited;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      alignment: WrapAlignment.start,
      children: participants.map((p) => _ParticipantTile(participant: p, userHasDeposited: userHasDeposited)).toList(),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.userHasDeposited});

  final Participant participant;
  final bool userHasDeposited;

  @override
  Widget build(BuildContext context) {
    final deposited = participant.isMe ? userHasDeposited : participant.hasDeposited;
    final initial = participant.name.isNotEmpty ? participant.name.characters.first.toUpperCase() : '?';
    final border = participant.isMe
        ? Border.all(color: accentGold, width: 2)
        : Border.all(color: deposited ? successGreen.withOpacity(0.6) : softGray.withOpacity(0.4));

    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: deposited ? primaryGreen.withOpacity(0.45) : softGray.withOpacity(0.25),
                  border: border,
                  boxShadow: participant.isMe
                      ? [
                          BoxShadow(
                            color: accentGold.withOpacity(0.35),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: titleBold(20, color: offWhite),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: darkBg, width: 2),
                  ),
                  child: Text(
                    deposited ? '✅' : '⏳',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            participant.isMe ? 'Tú' : participant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyText(11, color: participant.isMe ? accentGold : offWhite, weight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          Text(
            'Turno ${participant.turn}',
            style: bodyText(10, color: softGray),
          ),
        ],
      ),
    );
  }
}
