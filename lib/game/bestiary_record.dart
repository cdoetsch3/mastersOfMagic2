/// What one character knows about one creature: how often a fight with it
/// began, and how often it was won (ruling, Christian playtest 2026-09-30,
/// note 8).
library;

import 'package:flutter/foundation.dart';

/// One row of `PlayerProfile.bestiary`, keyed there by `EnemyDef.id`.
///
/// ⭐ **Two counts, nothing derived.** "Met" is `seen > 0`; the Bestiary's
/// chapter tallies and the Profile row are read off these, never stored.
///
/// ⚠️ **[seen] counts fights STARTED, not creatures glimpsed.** It ticks when
/// the duel begins (`GameState.beginEncounter`), so a fight that is lost, fled
/// or abandoned by closing the app still counts — and a resumed run that
/// restarts the same encounter counts it again. [slain] ticks only on a win
/// (`GameState.winEncounter`).
@immutable
class BestiaryEntry {
  final int seen;
  final int slain;

  const BestiaryEntry({this.seen = 0, this.slain = 0});

  /// Whether the creature has been met — the one definition the screen and
  /// the Profile row share.
  bool get met => seen > 0;

  BestiaryEntry withSeen() => BestiaryEntry(seen: seen + 1, slain: slain);

  BestiaryEntry withSlain() => BestiaryEntry(seen: seen, slain: slain + 1);

  Map<String, dynamic> toJson() => {'seen': seen, 'slain': slain};

  /// ⚠️ Tolerant: a missing or malformed count reads as 0, so a damaged
  /// entry can only under-report, never claim a kill that did not happen.
  factory BestiaryEntry.fromJson(Object? json) {
    if (json is! Map) return const BestiaryEntry();
    int count(Object? v) => v is num ? v.toInt() : 0;
    return BestiaryEntry(
      seen: count(json['seen']),
      slain: count(json['slain']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BestiaryEntry && other.seen == seen && other.slain == slain;

  @override
  int get hashCode => Object.hash(seen, slain);

  @override
  String toString() => 'BestiaryEntry(seen: $seen, slain: $slain)';
}
