/// How recently a player was active, for the friends list.
///
/// Deliberately coarse: exact "last seen 4m ago" invites staring at a list,
/// and a green dot only has to answer "could I challenge them right now?".
enum Presence {
  /// Active within [Presence.onlineWindow] — show the green dot.
  online,

  /// Active today, but not right now.
  recent,

  /// Seen at some point, a while ago.
  away,

  /// Never recorded — a save from before presence existed, or a player who
  /// has not synced. Not the same as "offline".
  unknown,
}

extension PresenceRules on Presence {
  /// Only [online] earns the dot.
  bool get showsDot => this == Presence.online;
}

/// A player is "online" if they were active within this window. Five minutes
/// is long enough to survive a save that hasn't fired yet and short enough
/// that the dot means something.
const Duration onlineWindow = Duration(minutes: 5);

/// The presence bucket for someone last active at [lastSeen], as of [now].
Presence presenceFor(DateTime? lastSeen, {DateTime? now}) {
  if (lastSeen == null) return Presence.unknown;
  final since = (now ?? DateTime.now()).difference(lastSeen);
  // A clock-skewed future timestamp reads as "just now" rather than "unknown";
  // devices disagree about the time and that shouldn't blank the dot.
  if (since < onlineWindow) return Presence.online;
  if (since < const Duration(hours: 24)) return Presence.recent;
  return Presence.away;
}

/// A short human label — "Online", "3h ago", "6d ago".
String presenceLabel(DateTime? lastSeen, {DateTime? now}) {
  final p = presenceFor(lastSeen, now: now);
  if (p == Presence.unknown) return 'Never seen';
  if (p == Presence.online) return 'Online';
  final since = (now ?? DateTime.now()).difference(lastSeen!);
  if (since.inHours < 1) return '${since.inMinutes}m ago';
  if (since.inHours < 24) return '${since.inHours}h ago';
  if (since.inDays < 30) return '${since.inDays}d ago';
  return 'Over a month ago';
}
