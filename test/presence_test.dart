import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/presence.dart';

void main() {
  final now = DateTime(2026, 7, 24, 12, 0);
  DateTime ago(Duration d) => now.subtract(d);

  group('presence buckets', () {
    test('active within the window is online', () {
      expect(presenceFor(now, now: now), Presence.online);
      expect(presenceFor(ago(const Duration(minutes: 4)), now: now),
          Presence.online);
    });

    test('past the window is no longer online', () {
      expect(presenceFor(ago(const Duration(minutes: 6)), now: now),
          Presence.recent);
      expect(presenceFor(ago(const Duration(hours: 5)), now: now),
          Presence.recent);
    });

    test('over a day is away', () {
      expect(presenceFor(ago(const Duration(days: 3)), now: now),
          Presence.away);
    });

    test('never recorded is unknown, which is not the same as offline', () {
      expect(presenceFor(null, now: now), Presence.unknown);
    });

    test('a clock-skewed future timestamp reads as online, not unknown', () {
      // Devices disagree about the time; that should not blank the dot.
      expect(presenceFor(now.add(const Duration(minutes: 3)), now: now),
          Presence.online);
    });

    test('only online shows the dot', () {
      expect(Presence.online.showsDot, isTrue);
      expect(Presence.recent.showsDot, isFalse);
      expect(Presence.away.showsDot, isFalse);
      expect(Presence.unknown.showsDot, isFalse);
    });
  });

  group('presence labels', () {
    test('read the way a person would say it', () {
      expect(presenceLabel(now, now: now), 'Online');
      expect(presenceLabel(ago(const Duration(minutes: 40)), now: now),
          '40m ago');
      expect(presenceLabel(ago(const Duration(hours: 6)), now: now), '6h ago');
      expect(presenceLabel(ago(const Duration(days: 6)), now: now), '6d ago');
      expect(presenceLabel(ago(const Duration(days: 90)), now: now),
          'Over a month ago');
      expect(presenceLabel(null, now: now), 'Never seen');
    });
  });

  group('lastSeenAt survives a save', () {
    test('round-trips through JSON', () {
      final profile = PlayerProfile.newPlayer()..lastSeenAt = now;
      final restored = PlayerProfile.fromJson(profile.toJson());
      expect(restored.lastSeenAt, now);
    });

    test('a save from before presence existed loads as unknown', () {
      final json = PlayerProfile.newPlayer().toJson()..remove('lastSeenAt');
      final restored = PlayerProfile.fromJson(json);
      expect(restored.lastSeenAt, isNull);
      expect(presenceFor(restored.lastSeenAt, now: now), Presence.unknown);
    });

    test('the timestamp crosses time zones intact', () {
      final profile = PlayerProfile.newPlayer()..lastSeenAt = now;
      // Serialized as UTC, read back as local — the instant must match.
      final json = profile.toJson();
      expect(json['lastSeenAt'], endsWith('Z'));
      expect(PlayerProfile.fromJson(json).lastSeenAt!.toUtc(), now.toUtc());
    });
  });
}
