import 'package:conextar/models/roundtable_participant_model.dart';
import 'package:flutter/material.dart';

class ParticipantStack extends StatelessWidget {
  final List<RoundtableParticipantModel> participants;
  final double avatarRadius;
  final double overlapShift;

  const ParticipantStack({
    super.key,
    required this.participants,
    this.avatarRadius = 16,
    this.overlapShift = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const int maxDisplayed = 3;
    final int totalCount = participants.length;
    final int displayCount = totalCount > maxDisplayed
        ? maxDisplayed
        : totalCount;
    final bool hasMore = totalCount > maxDisplayed;

    if (totalCount == 0) {
      return Text(
        "NO OPERATORS",
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.5,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return SizedBox(
      height: avatarRadius * 2,
      width:
          (displayCount * overlapShift) +
          (hasMore ? overlapShift : (avatarRadius * 2 - overlapShift)),
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            return Positioned(
              left: index * overlapShift,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: avatarRadius - 1,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(
                    0.08,
                  ),
                  child: Icon(
                    Icons.person,
                    size: avatarRadius * 1.1,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ),
            );
          }),
          if (hasMore)
            Positioned(
              left: displayCount * overlapShift,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: avatarRadius - 1,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    "+${totalCount - maxDisplayed}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
