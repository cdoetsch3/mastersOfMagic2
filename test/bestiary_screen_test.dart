/// The Bestiary screen, its search law and the entry page (ruling, Christian
/// playtest 2026-09-30, note 8 — mockup "A field guide + C's search box").
///
/// ⭐ Mutation-verified: each `reason:` names the wrong implementation it
/// kills. ⚠️ Drop tables are read through `DropTable` only and the facts are
/// derived at test time (a loot lane is retuning weights); the rate strings
/// are pinned on a synthetic creature whose table this file owns.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/bestiary_record.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/drop_table.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/provenance.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:masters_of_magic_2/screens/bestiary_screen.dart';
import 'package:masters_of_magic_2/screens/coming_soon_screen.dart';
import 'package:masters_of_magic_2/screens/profile_screen.dart';
import 'package:mom_engine/mom_engine.dart';

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}

/// ⚠️ The scope wraps the MaterialApp so pushed routes can read it; the
/// surface is tall because a ListView only builds what fits.
Future<void> _pump(
  WidgetTester tester,
  PlayerProfile profile,
  Widget home,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    GameStateScope(
      state: GameState(_Mem(), profile),
      child: MaterialApp(home: home),
    ),
  );
}

final _woods = World.byId('whispering_woods');
final _fawn = Bestiary.byId('listening_fawn')!;

PlayerProfile _met(Map<String, BestiaryEntry> record) =>
    PlayerProfile.newPlayer()..bestiary.addAll(record);

String _nameOf(String id) => ItemCatalogue.displayName(ItemCatalogue.byId(id));

/// A def the fawn drops that some OTHER creature drops too — the case where
/// a drop search could leak an unmet creature.
String get _sharedDrop => _fawn.drops.possibleDrops.firstWhere(
  (id) =>
      ItemCatalogue.tryById(id) != null &&
      Bestiary.all.any(
        (d) => d.id != _fawn.id && d.drops.possibleDrops.contains(id),
      ),
);

void main() {
  group('the record helpers', () {
    test('rates print as whole percents, <1% under one', () {
      expect(bestiaryRate(1), '100%', reason: 'a guaranteed entry');
      expect(bestiaryRate(0.45), '45%', reason: 'kills a fraction printed raw');
      expect(
        bestiaryRate(0.006),
        '<1%',
        reason: 'kills rounding before the floor check (0.6% would read 1%)',
      );
      expect(bestiaryRate(0.015), '2%', reason: 'kills truncation (1%)');
    });

    test('charges are counted in words', () {
      Spell move(int cost, {bool x = false}) => Spell(
        id: 't',
        name: 't',
        chargeCost: cost,
        priority: 9,
        effect: const DamageEffect(1, 2),
        xCost: x,
      );
      expect(bestiaryChargeLabel(move(1)), '1 charge', reason: 'singular');
      expect(
        bestiaryChargeLabel(move(2)),
        '2 charges',
        reason: 'kills a label that never pluralises',
      );
      expect(
        bestiaryChargeLabel(move(0, x: true)),
        'X charge',
        reason: 'kills an X spell printed as "0 charges"',
      );
    });

    test('the rank pill says Common / Mini / Boss', () {
      expect(EnemyRank.values.map(bestiaryRankLabel), [
        'Common',
        'Mini',
        'Boss',
      ], reason: "kills a pill reusing EnemyRank.label ('Wild', 'Mini-boss')");
    });

    test('the Profile count is met creatures the roster still knows', () {
      final record = {
        'listening_fawn': const BestiaryEntry(seen: 1),
        'heartwood': const BestiaryEntry(seen: 2, slain: 1),
        'thornback_sprite': const BestiaryEntry(),
        'retired_creature': const BestiaryEntry(seen: 5),
      };
      expect(
        bestiarySeenLabel(record),
        '2 seen',
        reason:
            'kills counting every entry (4), entries with seen 0 (3), or '
            'ids no longer in the roster (3)',
      );
    });
  });

  group('⭐ the search law (BestiaryListing.build)', () {
    test('no query: every zone with creatures, in map order, full tallies', () {
      final listing = BestiaryListing.build('', {
        _fawn.id: const BestiaryEntry(seen: 1),
      });
      final expected = [
        for (final z in World.locations)
          if (Bestiary.forZone(z.id).isNotEmpty) z.id,
      ];
      expect(
        listing.chapters.map((c) => c.zone.id),
        expected,
        reason: 'kills chapters in Bestiary.all order, or empty-zone chapters',
      );
      final woods = listing.chapters.firstWhere((c) => c.zone.id == _woods.id);
      expect(
        woods.label,
        '${_woods.name} · Lv ${_woods.minLevel}–${_woods.maxLevel} · 1/11',
        reason: 'the ruled label — kills a tally of rows rather than of met',
      );
    });

    test('a met creature matches by name, case-insensitively', () {
      final listing = BestiaryListing.build('LISTENING', {
        _fawn.id: const BestiaryEntry(seen: 1),
      });
      expect(
        [for (final c in listing.chapters) ...c.rows.map((d) => d.id)],
        [_fawn.id],
        reason: 'kills a case-sensitive match',
      );
    });

    test('⚠️ an unmet creature never matches by its own name', () {
      expect(
        BestiaryListing.build('listening fawn', const {}).chapters,
        isEmpty,
        reason: 'kills a search that reveals an unmet name',
      );
    });

    test('⭐ a drop finds the MET creatures that drop it — never the unmet', () {
      final name = _nameOf(_sharedDrop);
      final listing = BestiaryListing.build(name, {
        _fawn.id: const BestiaryEntry(seen: 1),
      });
      expect(
        [for (final c in listing.chapters) ...c.rows.map((d) => d.id)],
        [_fawn.id],
        reason:
            'kills a drop search over every table — "$name" is dropped by '
            'creatures never met, which must stay ???-and-unlisted',
      );
      expect(
        listing.dropLine,
        '1 creature drops $name',
        reason: 'kills a count that includes the unmet droppers',
      );
    });

    test('a zone name lists that zone, met or not', () {
      final listing = BestiaryListing.build('thunderspire', const {});
      expect(
        listing.chapters.single.zone.name,
        World.byId('thunderspire_peaks').name,
        reason: 'kills a zone name that matches nothing',
      );
      expect(
        listing.chapters.single.rows.length,
        Bestiary.forZone('thunderspire_peaks').length,
        reason: 'kills a zone match limited to met creatures',
      );
    });

    test('⭐ also gathered at: the zones where a matched drop is gathered', () {
      // A creature whose table holds something that is also gathered — and
      // ⚠️ gathered somewhere other than where it drops, or a footer built
      // from the drop zones would pass by coincidence.
      Set<String> zones(String id, bool Function(ItemSource) by) => {
        for (final s in Provenance.sourcesOf(id))
          if (by(s)) s.location.id,
      };
      late EnemyDef holder;
      late String item;
      outer:
      for (final d in Bestiary.all) {
        for (final id in d.drops.possibleDrops) {
          if (ItemCatalogue.tryById(id) == null) continue;
          final gathered = zones(id, (s) => s.gathered);
          final dropped = zones(id, (s) => s.dropped);
          if (gathered.isNotEmpty &&
              (gathered.length != dropped.length ||
                  !gathered.containsAll(dropped))) {
            holder = d;
            item = id;
            break outer;
          }
        }
      }
      final listing = BestiaryListing.build(_nameOf(item), {
        holder.id: const BestiaryEntry(seen: 1),
      });
      expect(listing.gatheredAt.map((z) => z.id), [
        for (final z in World.locations)
          if (Provenance.sourcesOf(
            item,
          ).any((s) => s.gathered && s.location.id == z.id))
            z.id,
      ], reason: 'kills a footer of the zones that DROP it (or none at all)');
      expect(
        BestiaryListing.build(_nameOf(item), const {}).gatheredAt,
        isEmpty,
        reason: 'kills a footer that answers for a drop no met creature has',
      );
    });

    test('nothing matches → no chapters', () {
      expect(
        BestiaryListing.build('zzzz-no-such-thing', const {}).chapters,
        isEmpty,
      );
    });
  });

  group('the Profile row', () {
    testWidgets('⭐ counts met creatures and opens the Bestiary', (
      tester,
    ) async {
      await _pump(
        tester,
        _met({
          _fawn.id: const BestiaryEntry(seen: 2, slain: 1),
          'heartwood': const BestiaryEntry(seen: 1),
        }),
        const ProfileScreen(),
      );

      expect(
        find.text('2 seen'),
        findsOneWidget,
        reason: "kills the old '0 seen' placeholder on the Bestiary row",
      );
      await tester.tap(find.text('Bestiary'));
      await tester.pumpAndSettle();
      expect(
        find.byType(BestiaryScreen),
        findsOneWidget,
        reason: 'kills a row still wired to the placeholder',
      );
      expect(find.byType(ComingSoonScreen), findsNothing);
    });
  });

  group('BestiaryScreen', () {
    testWidgets('the AppBar pill is met / total', (tester) async {
      await _pump(
        tester,
        _met({_fawn.id: const BestiaryEntry(seen: 1)}),
        const BestiaryScreen(),
      );
      expect(
        find.text('1 / ${Bestiary.all.length}'),
        findsOneWidget,
        reason: 'kills a pill counting the zone, or the record, not the roster',
      );
    });

    testWidgets('⭐ unmet rows: ???, Not yet met, and the rank pill anyway', (
      tester,
    ) async {
      await _pump(
        tester,
        _met({_fawn.id: const BestiaryEntry(seen: 1, slain: 3)}),
        const BestiaryScreen(),
      );
      await tester.enterText(find.byType(TextField), 'whispering');
      await tester.pumpAndSettle();

      final roster = Bestiary.forZone(_woods.id);
      expect(
        find.text(
          '${_woods.name} · Lv ${_woods.minLevel}–${_woods.maxLevel} '
          '· 1/${roster.length}',
        ),
        findsOneWidget,
        reason: 'the chapter label, as ruled',
      );
      expect(
        find.text('???'),
        findsNWidgets(roster.length - 1),
        reason: 'kills an unmet creature drawn by name',
      );
      expect(find.text('Not yet met'), findsNWidgets(roster.length - 1));
      expect(
        find.text(_fawn.name),
        findsOneWidget,
        reason: 'kills a met creature drawn as ???',
      );
      expect(
        find.text('slain 3'),
        findsOneWidget,
        reason: 'kills a met row without its kill count',
      );
      for (final rank in EnemyRank.values) {
        expect(
          find.text(bestiaryRankLabel(rank)),
          findsNWidgets(roster.where((d) => d.rank == rank).length),
          reason:
              'kills a rank pill drawn only for met rows — the player is '
              'meant to see which ranks are left',
        );
      }
    });

    testWidgets('a met row opens its entry; an unmet row is inert', (
      tester,
    ) async {
      await _pump(
        tester,
        _met({_fawn.id: const BestiaryEntry(seen: 1)}),
        const BestiaryScreen(),
      );
      await tester.enterText(find.byType(TextField), 'whispering');
      await tester.pumpAndSettle();

      await tester.tap(find.text('???').first);
      await tester.pumpAndSettle();
      expect(
        find.byType(BestiaryEntryScreen),
        findsNothing,
        reason: 'kills an unmet row that opens a page about ???',
      );

      await tester.tap(find.text(_fawn.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate(
          (w) => w is BestiaryEntryScreen && w.def.id == _fawn.id,
        ),
        findsOneWidget,
        reason: 'kills a met row that opens nothing, or the wrong creature',
      );
    });

    testWidgets('search: by drop, with the exact-name line', (tester) async {
      final name = _nameOf(_sharedDrop);
      await _pump(
        tester,
        _met({_fawn.id: const BestiaryEntry(seen: 1)}),
        const BestiaryScreen(),
      );
      await tester.enterText(find.byType(TextField), name);
      await tester.pumpAndSettle();

      expect(find.text(_fawn.name), findsOneWidget);
      expect(
        find.text('???'),
        findsNothing,
        reason:
            'kills a drop search that lists the unmet creatures dropping '
            '"$name"',
      );
      expect(find.text('1 creature drops $name'), findsOneWidget);
    });

    testWidgets('search: nothing → one dim line', (tester) async {
      await _pump(tester, PlayerProfile.newPlayer(), const BestiaryScreen());
      await tester.enterText(find.byType(TextField), 'zzzz-no-such-thing');
      await tester.pumpAndSettle();
      expect(
        find.text('Nothing matches.'),
        findsOneWidget,
        reason: 'kills an empty result drawn as a blank screen',
      );
    });

    testWidgets('⭐ the search field is press-stable', (tester) async {
      await _pump(tester, PlayerProfile.newPlayer(), const BestiaryScreen());
      final field = find.byType(TextField);
      final before = tester.getTopLeft(field);

      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(field),
        before,
        reason: 'kills a field inside the scrolling list — it scrolls away',
      );

      await tester.enterText(field, 'zzzz-no-such-thing');
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(field),
        before,
        reason: 'kills a field whose position follows its results',
      );
    });
  });

  group('BestiaryEntryScreen', () {
    // A creature this file owns: real item ids, a table whose rates are fixed.
    final ids = <String>[];
    for (final def in ItemCatalogue.all) {
      final n = ItemCatalogue.displayName(def);
      if (ids.any((id) => _nameOf(id) == n)) continue;
      ids.add(def.id);
      if (ids.length == 4) break;
    }
    final beast = EnemyDef(
      id: 'test_beast',
      name: 'Test Beast',
      zoneId: 'whispering_woods',
      // ⚠️ A boss on purpose: its rank earns a gear piece the page must NOT
      // list (the 📝 on the Drops section).
      rank: EnemyRank.boss,
      archetype: _fawn.archetype,
      elements: const [MagicElement.flora],
      lore: 'It was here before the path.',
      moves: const [
        Spell(
          id: 't_gore',
          name: 'Gore',
          chargeCost: 2,
          priority: 9,
          effect: DamageEffect(4, 7),
        ),
      ],
      drops: DropTable(
        always: [DropEntry(ids[0])],
        main: [
          DropEntry(ids[1], weight: 10),
          DropEntry(ids[2], weight: 45),
          const DropEntry.nothing(weight: 45),
        ],
        bonus: [DropEntry(ids[3], chance: 0.004)],
      ),
    );

    test('⭐ drop rows: always, main by weight, bonus — rates as ruled', () {
      expect(
        bestiaryDropRows(beast.drops),
        [
          (name: _nameOf(ids[0]), rate: '100%'),
          (name: _nameOf(ids[2]), rate: '45%'),
          (name: _nameOf(ids[1]), rate: '10%'),
          (name: _nameOf(ids[3]), rate: '<1%'),
        ],
        reason:
            'kills main in table order (10% before 45%), the nothing slot '
            'listed, weights printed raw, or bonus before main',
      );
    });

    testWidgets('⭐ the page: header, lore, moves, drops', (tester) async {
      await _pump(
        tester,
        _met({beast.id: const BestiaryEntry(seen: 3, slain: 2)}),
        BestiaryEntryScreen(def: beast),
      );
      await tester.pump();

      expect(find.text('Test Beast'), findsOneWidget, reason: 'AppBar title');
      expect(
        find.text('${_woods.name} · Boss · ${_fawn.archetype.name}'),
        findsOneWidget,
        reason: 'kills a header missing the zone, rank or archetype',
      );
      expect(
        find.text('seen 3 · slain 2'),
        findsOneWidget,
        reason: 'kills swapped or missing counts',
      );
      expect(find.text('Moves'), findsOneWidget);
      expect(
        find.text('2 charges · 4-7 damage'),
        findsOneWidget,
        reason:
            'kills a move row that drops the cost, or describes the effect '
            'with anything but spellEffectLine',
      );
      expect(
        find.text('45%'),
        findsOneWidget,
        reason: 'kills a main entry printed as its weight, not its share',
      );
      expect(
        find.textContaining('%'),
        findsNWidgets(4),
        reason:
            'kills a page that adds the boss rank-gear piece (or loses a '
            'row) — the table is what is shown',
      );
    });

    testWidgets('a mage reads Spells, not Moves', (tester) async {
      final mage = Bestiary.all.firstWhere((d) => d.isMage);
      await _pump(
        tester,
        PlayerProfile.newPlayer(),
        BestiaryEntryScreen(def: mage),
      );
      await tester.pump();
      expect(
        find.text('Spells'),
        findsOneWidget,
        reason: 'kills a mage whose loadout is labelled a creature kit',
      );
      expect(find.text('Moves'), findsNothing);
    });
  });
}
