import 'package:flutter/material.dart';

import '../game/presence.dart';
import 'app_theme.dart';

/// The friends-list presence indicator: a green dot when someone is active
/// right now, nothing when they are not.
///
/// Only [Presence.online] draws a dot. A row of amber and grey dots would make
/// the list look busy while telling you nothing you would act on — the single
/// question this answers is "can I challenge them right now?".
class PresenceDot extends StatelessWidget {
  final DateTime? lastSeen;
  final double size;

  /// Overridable so tests are not wall-clock dependent.
  final DateTime? now;

  const PresenceDot({
    super.key,
    required this.lastSeen,
    this.size = 9,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final presence = presenceFor(lastSeen, now: now);
    if (!presence.showsDot) return SizedBox(width: size, height: size);
    return Tooltip(
      message: 'Online now',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.55),
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dot plus its label — "Online", "3h ago", "Never seen".
class PresenceLabel extends StatelessWidget {
  final DateTime? lastSeen;
  final DateTime? now;

  const PresenceLabel({super.key, required this.lastSeen, this.now});

  @override
  Widget build(BuildContext context) {
    final online = presenceFor(lastSeen, now: now) == Presence.online;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceDot(lastSeen: lastSeen, now: now, size: 8),
        const SizedBox(width: 6),
        Text(
          presenceLabel(lastSeen, now: now),
          style: TextStyle(
            color: online ? AppColors.green : AppColors.textFaint,
            fontSize: 12,
            fontWeight: online ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
