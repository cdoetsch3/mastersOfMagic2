import 'travel.dart';
import 'world.dart';

/// A journey in progress, on a real clock.
///
/// ⭐ **Arrival is derived, never scheduled.** The trip stores when it left and
/// what it costs; where the player is at any moment is a function of the
/// current time. Nothing schedules a callback, so arriving while the app is
/// closed is not a special case — it is the only case, and reopening the app
/// simply asks the question again.
///
/// ⚠️ **The durations are frozen at departure.** Retuning an edge, or buying a
/// mount mid-journey, must not retroactively change a trip already in flight.
class ActiveTrip {
  /// Every location on the route, starting where the trip began.
  final List<String> stops;

  /// Cumulative **seconds** to reach each stop. Same length as [stops]; the
  /// first entry is always 0.
  ///
  /// Cumulative rather than per-leg because the question actually asked is
  /// "which stop have I reached by now", and that is a lookup here.
  ///
  /// ⚠️ Seconds, not minutes, even though edges are authored in minutes. A
  /// tier-5 mount is 20x: a 3-minute leg becomes 9 seconds, and rounding that
  /// to a whole minute would make the fastest mount in the game no better than
  /// a 5x one. The design's collapse (§4b.1: ~30 minutes to ~90 seconds) only
  /// survives at this resolution.
  final List<int> secondsAtStop;

  /// When the trip began. **Server time** — see `firestore.rules`; a client
  /// that could set this would be able to skip any wait.
  final DateTime departedAt;

  /// The mount ridden, if any. Recorded because a mount travels with you and
  /// is left wherever you stop (WORLD_DESIGN §4b.3).
  final String? mountId;

  const ActiveTrip({
    required this.stops,
    required this.secondsAtStop,
    required this.departedAt,
    this.mountId,
  });

  String get fromId => stops.first;
  String get toId => stops.last;

  int get totalSeconds => secondsAtStop.last;

  /// Rounded up, for display.
  int get totalMinutes => (totalSeconds / 60).ceil();

  DateTime get arrivesAt => departedAt.add(Duration(seconds: totalSeconds));

  /// Minutes elapsed, clamped to the trip's own length.
  ///
  /// ⚠️ Clamped at both ends deliberately. A device clock that jumps backwards
  /// would otherwise make a trip get *longer* the longer you wait, which reads
  /// as the game being broken rather than as the clock being wrong.
  Duration elapsedAt(DateTime now) {
    final raw = now.difference(departedAt);
    if (raw.isNegative) return Duration.zero;
    final total = Duration(seconds: totalSeconds);
    return raw > total ? total : raw;
  }

  Duration remainingAt(DateTime now) =>
      Duration(seconds: totalSeconds) - elapsedAt(now);

  bool isCompleteAt(DateTime now) => remainingAt(now) <= Duration.zero;

  /// How far along, 0..1. For a progress bar; 1 means arrived.
  double progressAt(DateTime now) {
    if (totalSeconds == 0) return 1;
    return elapsedAt(now).inSeconds / totalSeconds;
  }

  /// Index into [stops] of the last stop actually reached by [now].
  int stopIndexAt(DateTime now) {
    final seconds = elapsedAt(now).inSeconds;
    var index = 0;
    for (var i = 0; i < secondsAtStop.length; i++) {
      if (secondsAtStop[i] <= seconds) index = i;
    }
    return index;
  }

  /// ⭐ Where cancelling puts you: **the last stop you actually reached**, not
  /// where you set out from (ruling, 2026-07-28). Cancelling between B and C
  /// on an A→B→C→D trip leaves you at B, instantly.
  String stopReachedAt(DateTime now) => stops[stopIndexAt(now)];

  /// The stops passed so far, for revealing them on the map.
  List<String> stopsSeenAt(DateTime now) =>
      stops.sublist(0, stopIndexAt(now) + 1);

  /// The leg being walked right now, or null once arrived.
  ({String from, String to})? legAt(DateTime now) {
    final i = stopIndexAt(now);
    if (i >= stops.length - 1) return null;
    return (from: stops[i], to: stops[i + 1]);
  }

  /// Build a trip from a solved route, applying a mount's speed multiplier.
  ///
  /// §4b.3 is explicit that a mount has **no terrain rules** — it multiplies
  /// every leg equally, so this needs no per-kind logic.
  factory ActiveTrip.fromRoute(
    TravelRoute route,
    DateTime departedAt, {
    double speedMultiplier = 1,
    String? mountId,
  }) {
    final cumulative = <int>[0];
    var total = 0.0;
    for (var i = 0; i + 1 < route.stops.length; i++) {
      // ⚠️ [TravelTimes], never `leg.minutes`. The edge still carries the
      // hand-authored duration kept for tuning, and reading it here is exactly
      // the drift that having two durations invites.
      final minutes = TravelTimes.between(route.stops[i], route.stops[i + 1]);
      total += minutes * 60 / speedMultiplier;
      // Rounded on the running total, not per leg: rounding each leg up would
      // charge a fast mount a whole extra unit on every one of them.
      cumulative.add(total.ceil());
    }
    return ActiveTrip(
      stops: List.unmodifiable(route.stops),
      secondsAtStop: List.unmodifiable(cumulative),
      departedAt: departedAt,
      mountId: mountId,
    );
  }

  Map<String, dynamic> toJson() => {
    'stops': stops,
    'secondsAtStop': secondsAtStop,
    'departedAt': departedAt.toUtc().toIso8601String(),
    if (mountId != null) 'mountId': mountId,
  };

  /// Returns null rather than throwing on a malformed trip — a save that
  /// cannot be understood should strand nobody; they simply are not
  /// travelling.
  static ActiveTrip? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final stops = (json['stops'] as List?)?.cast<String>();
    final seconds = (json['secondsAtStop'] as List?)
        ?.map((m) => (m as num).toInt())
        .toList();
    final departed = DateTime.tryParse(json['departedAt'] as String? ?? '');
    if (stops == null ||
        seconds == null ||
        departed == null ||
        stops.length < 2 ||
        stops.length != seconds.length) {
      return null;
    }
    return ActiveTrip(
      stops: List.unmodifiable(stops),
      secondsAtStop: List.unmodifiable(seconds),
      departedAt: departed.toUtc(),
      mountId: json['mountId'] as String?,
    );
  }

  @override
  String toString() =>
      'ActiveTrip(${stops.join(" > ")}, ${totalMinutes}m from $departedAt)';
}
