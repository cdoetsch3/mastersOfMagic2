/// firestore.rules' `bots/{botId}` seed table vs [LadderRoster] (2026-09-25).
///
/// ⭐ The rules only let a bot doc be CREATED at exactly its two seeds, and
/// only let a corrupt rating be REPAIRED to exactly its seed — so the rules
/// carry a copy of every seed, and a copy can drift. Firestore rules have no
/// way to import Dart, so this test is the link: it parses the `seeds()` map
/// out of the rules file and fails the moment the two disagree.
///
/// ⚠️ A failure here means BOTH edits are needed — the table in
/// firestore.rules, and a rules deploy (`tool/deploy.sh --rules`). Until the
/// deploy lands, every create for a changed bot is refused by the server.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ladder/ladder_bots.dart';

void main() {
  /// `{botId: (geared, academy)}` as written in firestore.rules.
  Map<String, (int, int)> rulesSeeds() {
    final rules = File('firestore.rules').readAsStringSync();
    final start = rules.indexOf('function seeds()');
    expect(
      start,
      isNot(-1),
      reason: 'firestore.rules must define the bots seed table as seeds()',
    );
    final body = rules.substring(start, rules.indexOf('};', start));
    final entry = RegExp(
      r"'([a-z_]+)':\s*\{'ratingGeared':\s*(\d+),\s*'ratingAcademy':\s*(\d+)\}",
    );
    return {
      for (final m in entry.allMatches(body))
        m.group(1)!: (int.parse(m.group(2)!), int.parse(m.group(3)!)),
    };
  }

  test('the rules seed table names exactly the roster', () {
    expect(
      rulesSeeds().keys.toSet(),
      LadderRoster.all.map((b) => b.id).toSet(),
      reason:
          'a bot added to LadderRoster but not to firestore.rules can never '
          'have its doc created (isRosterBot() is false); one left in the '
          'rules after leaving the roster is dead weight',
    );
  });

  test('every rules seed matches the roster\'s seed formulas', () {
    final table = rulesSeeds();
    for (final bot in LadderRoster.all) {
      expect(
        table[bot.id],
        (bot.seedGeared, bot.seedAcademy),
        reason:
            '${bot.id}: the rules must hold the SAME (geared, academy) '
            'seeds the client writes — a re-seed in code without the rules '
            'makes every create for this bot a refused write',
      );
    }
  });
}
