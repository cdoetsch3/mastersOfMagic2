import 'dart:async';

import 'package:flutter/material.dart';

import '../game/active_trip.dart';
import '../game/game_state.dart';
import '../game/world.dart';
import 'app_theme.dart';

/// `Next: Old Quarry · then Forgeholm, Concordance` — the stops still ahead
/// on a chained trip (ruling, Christian 2026-09-30, note 12), or null for a
/// single-leg trip and once arrived.
///
/// ⭐ Decided by the TRIP, not the leg: a chained trip keeps the line on its
/// last leg (`Next: Concordance`), so the Stop button below never jumps up a
/// line partway through the journey.
String? nextStopsLine(ActiveTrip trip, DateTime now) {
  if (trip.stops.length <= 2) return null;
  final leg = trip.legAt(now);
  if (leg == null) return null;
  final at = trip.stopIndexAt(now);
  final next = World.byId(trip.stops[at + 1]).name;
  final then = [for (final id in trip.stops.skip(at + 2)) World.byId(id).name];
  return then.isEmpty ? 'Next: $next' : 'Next: $next · then ${then.join(', ')}';
}

/// The journey in progress, at the top of the Map tab.
///
/// ⚠️ The ticker here is **display only**. Arrival is a function of the clock
/// (see `ActiveTrip`), so nothing breaks if this widget never runs — closing
/// the app mid-journey still lands you at your destination. This exists to
/// make the wait legible, not to make it happen.
class TravelProgressCard extends StatefulWidget {
  final GameState game;
  const TravelProgressCard({super.key, required this.game});

  @override
  State<TravelProgressCard> createState() => _TravelProgressCardState();
}

class _TravelProgressCardState extends State<TravelProgressCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      // Settles and persists only if the journey has actually finished — a
      // tick with nothing to settle costs no write.
      widget.game.tick();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.game.profile.trip;
    if (trip == null) return const SizedBox.shrink();

    final now = widget.game.now();
    final leg = trip.legAt(now);
    final next = nextStopsLine(trip, now);
    final destination = World.byId(trip.toId).name;
    final stopIfCancelled = World.byId(trip.stopReachedAt(now)).name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_walk,
                size: 18,
                color: AppColors.teal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Travelling to $destination',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                // ⭐ [formatRemaining] rounds the seconds UP, so this clock
                // reads 0:00 at the same instant the bar below reaches 1.0
                // and not a second earlier (ruling 2026-09-21).
                formatRemaining(trip.remainingAt(now)),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: trip.progressAt(now).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.borderDim,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            leg == null
                ? 'Arriving…'
                // ⭐ A chained trip names its next stop on the line below, so
                // this line stops short of naming it twice.
                : trip.stops.length > 2
                ? 'On the road from ${World.byId(leg.from).name}'
                : 'On the road from ${World.byId(leg.from).name} '
                      'to ${World.byId(leg.to).name}',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          if (next != null) ...[
            const SizedBox(height: 2),
            Text(
              next,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => widget.game.cancelTravel(),
              icon: const Icon(Icons.logout, size: 15),
              // ⭐ Names where you end up. Cancelling drops you at the last
              // place you actually reached, and a button saying "Cancel"
              // leaves the player guessing whether that means going back.
              label: Text('Stop at $stopIfCancelled'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
