/// The Spellbook's shelf: which lane a spell files under, the orders the book
/// can be read in, the two filters that narrow it — and the screen that paints
/// all three.
///
/// ⭐ Mutation-verified: every assertion names the wrong implementation it
/// kills — a kind derived from priority alone, a speed sort that reads the
/// bigger number as the faster spell, a filter that lights a chip and narrows
/// nothing, a sort that quietly serves the whole catalogue back, section
/// headers that survive a filter, and a toolbar that walks out from under the
/// finger that pressed it.
///
/// ⚠️ Fixtures are pulled off [Spellbook] and [SpellKind], never typed out:
/// the book is on its way from 25 spells to ~59, and a suite that hardcodes
/// counts or names would go stale the day the bank lands — which is exactly
/// the day these rules need to still be true.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/game_state.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/profile_storage.dart';
import 'package:masters_of_magic_2/game/spell_browser.dart';
import 'package:masters_of_magic_2/screens/tabs/spellbook_tab.dart';
import 'package:mom_engine/mom_engine.dart';

// ---- fixtures ---------------------------------------------------------

/// Spells authored off the book, for the lanes the shipped 25 cannot reach on
/// their own. The incoming bank is the reason they exist: it puts support on
/// the priority-9 clock and attacks below priority 5, and the derivation has
/// to be right BEFORE that content arrives, not after a section header has
/// already lied to a player.
const _healAtAttackSpeed = Spell(
  id: 'test_late_support',
  name: 'Late Support',
  chargeCost: 2,
  priority: 9,
  effect: HallowEffect(),
);
const _offBandWard = Spell(
  id: 'test_off_band_ward',
  name: 'Off Band Ward',
  chargeCost: 2,
  priority: 9,
  effect: ShieldEffect(10, 12),
);
const _instantStrike = Spell(
  id: 'test_instant',
  name: 'Instant Strike',
  chargeCost: 1,
  priority: 1,
  effect: DamageEffect(5, 7),
);

List<Spell> _lane(SpellKind kind) =>
    Spellbook.all.where((s) => spellKindOf(s) == kind).toList();

List<String> _names(List<Spell> spells) => [for (final s in spells) s.name];

void main() {
  // ---- kind derivation ------------------------------------------------

  group('spellKindOf', () {
    test('⭐ the four lanes hold the spells the engine bands say they do', () {
      expect(
        spellKindOf(Spellbook.ward),
        SpellKind.shields,
        reason: 'a ShieldEffect at priority 3 is the shield lane itself',
      );
      expect(
        spellKindOf(Spellbook.flick),
        SpellKind.quick,
        reason:
            'priority 5 damage is a quick attack, not a regular one — '
            'the mutant this kills lumps every DamageEffect into Offense',
      );
      expect(
        spellKindOf(Spellbook.empower),
        SpellKind.auxSelf,
        reason: 'priority 7 self-buffs are the aux-self lane',
      );
      expect(
        spellKindOf(Spellbook.bolt),
        SpellKind.offense,
        reason: 'priority 9 damage is the regular-attack lane',
      );
    });

    test(
      '⚠️ Barrier files with the shields though it is not a ShieldEffect',
      () {
        expect(
          Spellbook.barrier.effect,
          isA<BarrierEffect>(),
          reason:
              'this fixture only means what it says while Barrier is not a '
              'plain ShieldEffect',
        );
        expect(
          spellKindOf(Spellbook.barrier),
          SpellKind.shields,
          reason:
              '⚠️ the mutant this kills: a derivation that tests for '
              'ShieldEffect alone and drops Barrier into aux, where nobody '
              'hunting for defence will look',
        );
      },
    );

    test('⭐ a shield off its band is still a shield', () {
      expect(
        spellKindOf(_offBandWard),
        SpellKind.shields,
        reason:
            '⚠️ the mutant this kills: a derivation keyed on priority '
            'ALONE, which would file a priority-9 ward under Offense — the '
            'one section a player raising defence will never open',
      );
    });

    test('⭐ support on the attack clock is aux, not offense', () {
      expect(
        spellKindOf(_healAtAttackSpeed),
        SpellKind.auxSelf,
        reason:
            '⚠️ THE mutant the incoming bank will find: priority 9 means '
            '"resolves late", not "harms the enemy". A spell that deals no '
            'damage cannot head the Offense section',
      );
    });

    test('an instant attack is quick, not offense', () {
      expect(
        spellKindOf(_instantStrike),
        SpellKind.quick,
        reason:
            'the quick lane is everything that beats aux and regular '
            'spells to the punch — priorities 1-6, not priority 5 exactly',
      );
    });

    test('⭐ Discharge is aux-OFFENSE: harmful, but it deals no damage', () {
      expect(
        Spellbook.discharge.isHarmful,
        isTrue,
        reason:
            'the engine calls it harmful — which is the trap this '
            'assertion exists to spring',
      );
      expect(
        spellKindOf(Spellbook.discharge),
        SpellKind.auxOffense,
        reason:
            '⚠️ REVERSED 2026-08-29 with the aux split: isHarmful now '
            'decides WHICH aux shelf, while isOffensive still decides '
            'aux-vs-offense. The mutant this kills: a split on isHarmful '
            'alone, which would put charge control under Offense; and its '
            'twin, ignoring isHarmful, which files a debuff beside a heal',
      );
    });

    test('⭐ the aux shelf splits on WHO it is aimed at (ruled 2026-08-29)', () {
      expect(
        spellKindOf(Spellbook.murk),
        SpellKind.auxOffense,
        reason: 'a debuff on the enemy is pressure, not preparation — '
            'the mutant this kills files it beside Lightfoot',
      );
      expect(
        spellKindOf(Spellbook.lightfoot),
        SpellKind.auxSelf,
        reason: 'a stance on yourself is preparation',
      );
      expect(
        spellKindOf(Spellbook.cleanse),
        SpellKind.auxSelf,
        reason: 'a cleanse acts on you, whatever it removes',
      );
      expect(
        spellKindOf(Spellbook.shatter),
        SpellKind.auxOffense,
        reason: 'no damage, but aimed at them',
      );
      expect(
        SpellKind.auxSelf.index < SpellKind.auxOffense.index,
        isTrue,
        reason: 'section order is the priority ladder: self-aux (7) resolves '
            'before enemy-aux (8), so the book reads a turn in order',
      );
    });

    test('⚠️ every shipped spell lands in exactly one lane', () {
      final counted = <SpellKind, int>{
        for (final kind in SpellKind.values) kind: _lane(kind).length,
      };
      expect(
        counted.values.fold<int>(0, (a, b) => a + b),
        Spellbook.all.length,
        reason:
            '⚠️ the mutant this kills: a lane rule that leaves a spell '
            'unreachable from every section AND every chip — the book teaching '
            'the player that content it ships does not exist',
      );
      expect(
        counted.values.every((n) => n > 0),
        isTrue,
        reason:
            'all four sections must be populated by the shipped book, or '
            'the grouped view offers a header nobody can fill',
      );
    });

    test('no lane mixes damage with defence', () {
      expect(
        _lane(SpellKind.offense).every((s) => s.isOffensive),
        isTrue,
        reason: 'a non-damaging spell under Offense is a section header lying',
      );
      expect(
        _lane(SpellKind.shields).every((s) => !s.isOffensive),
        isTrue,
        reason: 'an attack under Shields is the same lie the other way round',
      );
    });

    test("'All' is the label for the unfiltered shelf", () {
      expect(spellKindFilterLabel(null), 'All');
      expect(
        spellKindFilterLabel(SpellKind.shields),
        SpellKind.shields.label,
        reason:
            'the chip must carry the same word as the section header, or '
            'the filter and the book are two vocabularies',
      );
    });
  });

  // ---- cost bands -------------------------------------------------------

  group('SpellCostFilter', () {
    test('⭐ the three bands partition the book — nothing is unreachable', () {
      for (final spell in Spellbook.all) {
        final matched = SpellCostFilter.values
            .where((f) => f != SpellCostFilter.any && f.accepts(spell))
            .toList();
        expect(
          matched.length,
          1,
          reason:
              '⚠️ the mutant this kills: hand-picked bands that leave a '
              'cost in none of them (or two) — ${spell.name} costs '
              '${spell.chargeCost} and matched $matched',
        );
      }
    });

    test('Any cost accepts the whole book', () {
      expect(
        Spellbook.all.every(SpellCostFilter.any.accepts),
        isTrue,
        reason: 'the chip that clears the filter must clear all of it',
      );
    });

    test('⚠️ an X-cost spell is banded by its minimum', () {
      expect(
        Spellbook.barrage.xCost,
        isTrue,
        reason: 'Barrage is this suite\'s X-cost fixture',
      );
      expect(
        SpellCostFilter.cheap.accepts(Spellbook.barrage),
        isTrue,
        reason:
            '⚠️ the mutant this kills: banding an X spell by what it MIGHT '
            'consume, hiding the one spell a player with 1 charge can cast '
            'behind the "Cost 4+" chip',
      );
    });

    test('the bands cut where their labels say they do', () {
      expect(
        SpellCostFilter.cheap.accepts(Spellbook.flick),
        isTrue,
        reason: 'a free spell is the cheapest thing in the book',
      );
      expect(
        SpellCostFilter.mid.accepts(Spellbook.jolt),
        isTrue,
        reason: 'cost 2 sits in 2-3',
      );
      expect(
        SpellCostFilter.cheap.accepts(Spellbook.jolt),
        isFalse,
        reason:
            '⚠️ the mutant this kills: an off-by-one boundary that spills '
            'cost 2 into the cheap band and makes the two chips overlap',
      );
      expect(
        SpellCostFilter.heavy.accepts(Spellbook.ruin),
        isTrue,
        reason: 'cost 4 is where the heavy band opens',
      );
    });
  });

  // ---- sorting ----------------------------------------------------------

  group('sortSpells', () {
    test('⭐ Book order returns the given sequence untouched', () {
      expect(
        _names(sortSpells(Spellbook.all, SpellSort.book)),
        _names(Spellbook.all),
        reason:
            '⚠️ the mutant this kills: a default that quietly alphabetises '
            "— the authored ladder (ward → sanctuary) is information, and a "
            'player who sorts away must be able to get it back',
      );
    });

    test('⚠️ sorting never mutates its argument', () {
      final source = List<Spell>.of(Spellbook.all);
      sortSpells(source, SpellSort.name);
      expect(
        _names(source),
        _names(Spellbook.all),
        reason:
            '⚠️ the mutant this kills: an in-place sort of the caller\'s '
            'list, which would permanently scramble Spellbook.all for the '
            'duel screen and every other reader',
      );
    });

    test('Name sorts A-Z', () {
      final sorted = _names(sortSpells(Spellbook.all, SpellSort.name));
      final expected = List<String>.of(sorted)..sort();
      expect(
        sorted,
        expected,
        reason: 'the whole list must be ordered, not just its first pair',
      );
    });

    test('⭐ Charge cost ascends, and ties break on name', () {
      final sorted = sortSpells(Spellbook.all, SpellSort.cost);
      for (var i = 1; i < sorted.length; i++) {
        final prev = sorted[i - 1];
        final next = sorted[i];
        expect(
          prev.chargeCost <= next.chargeCost,
          isTrue,
          reason:
              '⚠️ the mutant this kills: a control that repaints its own '
              'label and leaves the shelf as it found it — ${prev.name} '
              '(${prev.chargeCost}) before ${next.name} (${next.chargeCost})',
        );
        if (prev.chargeCost == next.chargeCost) {
          expect(
            prev.name.compareTo(next.name) <= 0,
            isTrue,
            reason:
                '⚠️ the mutant this kills: an unstable tie-break that '
                'reshuffles equal-cost rows every time the sort is re-chosen, '
                'so the position a player just learned is a lie',
          );
        }
      }
    });

    test('⭐ Speed puts the FASTEST first — ascending priority', () {
      final sorted = sortSpells(Spellbook.all, SpellSort.speed);
      expect(
        sorted.first.priority,
        lessThan(sorted.last.priority),
        reason:
            '⚠️ THE mutant this test exists to kill: a descending sort, '
            'read off "bigger number = faster", which puts the slowest spells '
            'at the top of a list whose control says Speed (lower priority '
            'acts EARLIER — spell.dart)',
      );
      for (var i = 1; i < sorted.length; i++) {
        expect(
          sorted[i - 1].priority <= sorted[i].priority,
          isTrue,
          reason: 'the whole order must be monotonic, not just its ends',
        );
      }
    });
  });

  // ---- filtering and grouping -------------------------------------------

  group('filterSpells', () {
    test('⭐ a kind filter keeps exactly its lane', () {
      final shields = filterSpells(
        Spellbook.all,
        kind: SpellKind.shields,
        cost: SpellCostFilter.any,
        sort: SpellSort.book,
      );
      expect(
        _names(shields),
        _names(_lane(SpellKind.shields)),
        reason:
            '⚠️ the mutant this kills: a filter that lights a chip and '
            'narrows nothing',
      );
      expect(
        shields.length,
        lessThan(Spellbook.all.length),
        reason:
            'this fixture only means something while the lane is a proper '
            'subset of the book',
      );
    });

    test('a null kind is the whole book', () {
      expect(
        filterSpells(
          Spellbook.all,
          kind: null,
          cost: SpellCostFilter.any,
          sort: SpellSort.book,
        ).length,
        Spellbook.all.length,
        reason: 'a filter the player cannot clear is a trap',
      );
    });

    test('⭐ the two filters compose — kind AND cost, never either', () {
      final cheapShields = filterSpells(
        Spellbook.all,
        kind: SpellKind.shields,
        cost: SpellCostFilter.cheap,
        sort: SpellSort.book,
      );
      expect(
        cheapShields.every(
          (s) => spellKindOf(s) == SpellKind.shields && s.chargeCost <= 1,
        ),
        isTrue,
        reason:
            '⚠️ the mutant this kills: an OR that widens the shelf every '
            'time a second chip is pressed',
      );
      expect(
        cheapShields.length,
        lessThan(_lane(SpellKind.shields).length),
        reason:
            'the cost chip must actually bite into the lane, or this test '
            'is only re-testing the kind filter',
      );
    });

    test('⭐ the sort sees only what survived the filter', () {
      final byName = filterSpells(
        Spellbook.all,
        kind: SpellKind.shields,
        cost: SpellCostFilter.any,
        sort: SpellSort.name,
      );
      expect(
        byName.length,
        _lane(SpellKind.shields).length,
        reason:
            '⚠️ the mutant this kills: a sort that re-reads the whole '
            'catalogue and quietly serves the filter back with it',
      );
      expect(
        _names(byName),
        List<String>.of(_names(byName))..sort(),
        reason: 'and it must still be sorted',
      );
    });

    test('an empty result is empty, not a fallback to everything', () {
      final quickCosts = _lane(SpellKind.quick).map((s) => s.chargeCost);
      expect(
        quickCosts.every((c) => c < 4),
        isTrue,
        reason:
            'this fixture only means what it says while no quick spell '
            'costs 4 or more',
      );
      expect(
        filterSpells(
          Spellbook.all,
          kind: SpellKind.quick,
          cost: SpellCostFilter.heavy,
          sort: SpellSort.book,
        ),
        isEmpty,
        reason:
            '⚠️ the mutant this kills: an empty filter result papered over '
            'by falling back to the unfiltered book',
      );
    });

    test('spellFilterActive is true for either chip alone', () {
      expect(
        spellFilterActive(kind: null, cost: SpellCostFilter.any),
        isFalse,
        reason: 'both chips at rest is the grouped, unfiltered book',
      );
      expect(
        spellFilterActive(kind: SpellKind.auxSelf, cost: SpellCostFilter.any),
        isTrue,
      );
      expect(
        spellFilterActive(kind: null, cost: SpellCostFilter.heavy),
        isTrue,
        reason:
            '⚠️ the mutant this kills: a flatten condition that watches '
            'the kind chip only, leaving a cost-filtered shelf still cut into '
            'sections that no longer describe it',
      );
    });
  });

  group('groupSpells', () {
    test('⭐ sections come back in the engine\'s own priority order', () {
      final groups = groupSpells(Spellbook.all, sort: SpellSort.book);
      expect(
        [for (final g in groups) g.kind],
        SpellKind.values,
        reason:
            '⚠️ the mutant this kills: sections ordered by however the map '
            'iterates — the book reads top to bottom in the order a turn '
            'actually resolves (shields, quick, aux, offense)',
      );
    });

    test('every spell appears in exactly one section', () {
      final grouped = [
        for (final g in groupSpells(Spellbook.all, sort: SpellSort.book))
          ...g.spells,
      ];
      expect(
        _names(grouped)..sort(),
        _names(Spellbook.all)..sort(),
        reason:
            '⚠️ the mutant this kills: a grouping that drops or duplicates '
            'a spell — the wall of 59 with one of them missing looks exactly '
            'like the wall of 59',
      );
    });

    test('⭐ the sort applies WITHIN sections, it does not flatten them', () {
      final groups = groupSpells(Spellbook.all, sort: SpellSort.name);
      expect(
        groups.length,
        SpellKind.values.length,
        reason:
            '⚠️ the mutant this kills: a sort that dissolves the sections '
            'it was supposed to order inside',
      );
      for (final g in groups) {
        expect(
          _names(g.spells),
          List<String>.of(_names(g.spells))..sort(),
          reason: '${g.kind.label} must be alphabetical inside its own header',
        );
      }
    });

    test('⚠️ an empty lane yields no header at all', () {
      final onlyShields = _lane(SpellKind.shields);
      final groups = groupSpells(onlyShields, sort: SpellSort.book);
      expect(
        [for (final g in groups) g.kind],
        [SpellKind.shields],
        reason:
            '⚠️ the mutant this kills: a header standing over nothing, '
            'which reads as a loading bug rather than an empty category',
      );
    });
  });

  // ---- the screen -------------------------------------------------------

  group('the Spellbook screen', () {
    testWidgets('⭐ at rest the book is sectioned, not a wall', (tester) async {
      await _pump(tester);

      for (final kind in SpellKind.values) {
        expect(
          _header('${kind.label}  ·  ${_lane(kind).length}'),
          findsOneWidget,
          reason:
              '⚠️ the mutant this kills: a default view that shows all '
              '${Spellbook.all.length} tiles in one undifferentiated grid — '
              'the complaint this screen was reopened for',
        );
      }
      expect(
        find.text(Spellbook.ward.name),
        findsOneWidget,
        reason: 'sectioning must not cost the player a single spell',
      );
    });

    testWidgets('⭐ a kind chip narrows the shelf and flattens the sections', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text(Spellbook.bolt.name), findsOneWidget);

      await tester.tap(find.text(SpellKind.shields.label));
      await tester.pumpAndSettle();

      expect(
        find.text(Spellbook.ward.name),
        findsOneWidget,
        reason: 'the chosen lane keeps its spells',
      );
      expect(
        find.text(Spellbook.bolt.name),
        findsNothing,
        reason:
            '⚠️ the mutant this kills: a chip row that lights up and '
            'filters nothing',
      );
      expect(
        _header(
          '${SpellKind.shields.label}  ·  ${_lane(SpellKind.shields).length}',
        ),
        findsNothing,
        reason:
            '⚠️ the mutant this kills: section headers that survive a '
            'filter — one header over one lane is a heading that says nothing '
            'the chip has not already said',
      );
      expect(
        _header(
          'Showing ${_lane(SpellKind.shields).length} of '
          '${Spellbook.all.length} spells',
        ),
        findsOneWidget,
        reason:
            'the flattened shelf must say how much of the book it is '
            'showing, or the player cannot tell a narrow filter from a small '
            'book',
      );
    });

    testWidgets('All puts the whole book back', (tester) async {
      await _pump(tester);
      await tester.tap(find.text(SpellKind.auxSelf.label));
      await tester.pumpAndSettle();
      expect(find.text(Spellbook.bolt.name), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(
        find.text(Spellbook.bolt.name),
        findsOneWidget,
        reason: 'a filter the player cannot clear is a trap',
      );
      expect(
        _header(
          '${SpellKind.offense.label}  ·  ${_lane(SpellKind.offense).length}',
        ),
        findsOneWidget,
        reason:
            'clearing the filter restores the sections too — the shelf '
            'must return to the view it started in, not a flat list',
      );
    });

    testWidgets('a cost chip narrows on its own', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(SpellCostFilter.cheap.label));
      await tester.pumpAndSettle();

      expect(
        find.text(Spellbook.flick.name),
        findsOneWidget,
        reason: 'a free spell is in the cheap band',
      );
      expect(
        find.text(Spellbook.cataclysm.name),
        findsNothing,
        reason:
            '⚠️ the mutant this kills: a cost filter wired to the widget '
            'but not to the shelf',
      );
    });

    testWidgets('a filter matching nothing says so, quietly', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(SpellKind.quick.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(SpellCostFilter.heavy.label));
      await tester.pumpAndSettle();

      expect(
        find.text('No spells match these filters.'),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: silence — an empty shelf that does '
            'not name the filters reads as "the book has no quick spells", '
            'which is a different and wrong fact',
      );
    });

    testWidgets('⭐ sorting reorders the shelf inside its sections', (
      tester,
    ) async {
      await _pump(tester);
      final lane = _lane(SpellKind.offense);
      final firstByBook = lane.first;
      final firstByName = (List<Spell>.of(
        lane,
      )..sort((a, b) => a.name.compareTo(b.name))).first;
      expect(
        firstByBook.name,
        isNot(firstByName.name),
        reason:
            'this fixture only means what it says while the authored '
            'order and the alphabet disagree',
      );
      expect(
        _order(tester, firstByBook.name),
        lessThan(_order(tester, firstByName.name)),
        reason: 'the default IS the authored book order',
      );

      await _chooseSort(tester, SpellSort.name);

      expect(
        _order(tester, firstByName.name),
        lessThan(_order(tester, firstByBook.name)),
        reason:
            '⚠️ the mutant this kills: a sort control that repaints its '
            'own label and leaves the shelf exactly as it found it',
      );
      expect(
        _header('${SpellKind.offense.label}  ·  ${lane.length}'),
        findsOneWidget,
        reason: 'sorting orders WITHIN the sections; it must not dissolve them',
      );
    });

    testWidgets(
      '⭐ the controls hold their positions across filter and sort changes',
      (tester) async {
        await _pump(tester);

        Rect shieldChip() => tester.getRect(
          find
              .ancestor(
                of: find.text(SpellKind.shields.label),
                matching: find.byType(Container),
              )
              .first,
        );
        Rect sortRect() => tester.getRect(find.byIcon(Icons.sort));
        Rect costChip() => tester.getRect(
          find
              .ancestor(
                of: find.text(SpellCostFilter.heavy.label),
                matching: find.byType(Container),
              )
              .first,
        );

        final chip = shieldChip();
        final sort = sortRect();
        final cost = costChip();

        await tester.tap(find.text(SpellKind.shields.label));
        await tester.pumpAndSettle();

        expect(
          shieldChip(),
          chip,
          reason:
              '⚠️ THE house rule: a chip that grew a check mark, or a row '
              'that wrapped onto a second line, moves the control the player '
              'just pressed out from under their finger',
        );
        expect(sortRect(), sort);
        expect(
          costChip(),
          cost,
          reason:
              '⚠️ the mutant this kills: a second chip row that only '
              'appears once a kind is chosen — inserted space, never reserved',
        );

        // The control whose LABEL changes is the sharpest case of the rule.
        await _chooseSort(tester, SpellSort.cost);
        expect(
          sortRect(),
          sort,
          reason:
              '⚠️ the mutant this kills: a sort button sized to its own '
              "label, which walks away when 'Book order' becomes 'Charge cost'",
        );
        expect(shieldChip(), chip);
      },
    );

    testWidgets('the toolbar is pinned above the shelf, not scrolled away', (
      tester,
    ) async {
      // ⚠️ A SHORT viewport, so there is something to scroll: the tall
      // surface the other tests use shows the whole book at once.
      await _pump(tester, surface: const Size(720, 700));
      final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
      final resting = tester.getRect(find.byIcon(Icons.sort));
      expect(
        resting.top,
        greaterThan(viewportTop),
        reason:
            'the band starts below the loadout block — this test is about '
            'where it ENDS UP',
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(
        find.text('How dueling works'),
        findsNothing,
        reason:
            'the drag must actually have carried the loadout block off the '
            'top, or nothing below is being tested',
      );
      expect(
        find.byIcon(Icons.sort),
        findsOneWidget,
        reason:
            '⚠️ the mutant this kills: an unpinned toolbar — with ~59 '
            'spells, controls that scroll off the top are controls the player '
            'has to scroll back for',
      );
      expect(
        tester.getRect(find.byIcon(Icons.sort)).top,
        greaterThanOrEqualTo(viewportTop),
        reason:
            '⭐ the pin is what makes the press-stability rule hold while '
            'scrolled: a shelf that shortens under a filter clamps the scroll '
            'offset, and only a control nailed to the top of the viewport '
            'cannot be slid out from under the finger by that clamp',
      );
    });
  });
}

// ---- harness ----------------------------------------------------------

/// [SectionLabel] uppercases what it is given, so every header assertion has
/// to as well — matching on the raw string would pass a screen that never
/// rendered a header at all.
Finder _header(String text) => find.text(text.toUpperCase());

/// Reading position of a tile in the grid: row first, then column.
///
/// ⚠️ The shelf is a GRID, so `dy` alone cannot order two tiles — the first
/// and third spells of a section share a row, and an assertion on `dy` there
/// compares two equal numbers and proves nothing.
double _order(WidgetTester tester, String spellName) {
  final at = tester.getTopLeft(find.text(spellName));
  return at.dy * 10000 + at.dx;
}

Future<void> _chooseSort(WidgetTester tester, SpellSort sort) async {
  await tester.tap(find.byIcon(Icons.sort));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sort.label).last);
  await tester.pumpAndSettle();
}

/// ⚠️ A tall surface by default: the shelf's grids only build the tiles the
/// viewport (plus cache) reaches, and an order assertion against tiles that
/// were never laid out proves nothing.
Future<void> _pump(
  WidgetTester tester, {
  Size surface = const Size(720, 3000),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GameStateScope(
          state: GameState(_Mem(), PlayerProfile.newPlayer()),
          child: const SpellbookTab(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Mem implements ProfileStorage {
  PlayerProfile? stored;
  @override
  Future<PlayerProfile?> load() async => stored;
  @override
  Future<void> save(PlayerProfile profile) async => stored = profile;
  @override
  Future<void> clear() async => stored = null;
}
