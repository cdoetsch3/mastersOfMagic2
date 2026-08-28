/// The charge-cost pips on a spell tab (designer's ask, 2026-08-28): "a small
/// number of dots in the top right corner".
///
/// ⭐ Mutation-verified: every assertion below names the wrong implementation
/// it kills — the off-by-one dot, the widget that collapses to nothing when a
/// spell is free, the tab that grows a pixel because Cataclysm costs more than
/// Flick, the X-cost spell that tells a flat lie about its price, and the
/// corner that is silent to a screen reader.
///
/// ⚠️ The **reserved-space** cases are the ones with teeth. The house rule is
/// that a button never moves under the finger that pressed it and appearing
/// elements always hold their space, so "0 draws nothing" and "0 measures the
/// same as 5" are two different claims and a plausible implementation
/// (`if (cost == 0) return const SizedBox.shrink()`) satisfies only the first.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:masters_of_magic_2/ui/charge_dots.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  group('the dots count the charge', () {
    for (var cost = 0; cost <= 5; cost++) {
      testWidgets('cost $cost draws $cost dots', (tester) async {
        await _pumpDots(tester, cost: cost);
        expect(
          find.byType(ChargeDot),
          findsNWidgets(cost),
          reason:
              'cost $cost must draw exactly $cost pips — an off-by-one here '
              '(cost+1, or a always-five meter that fills instead of counts) '
              'misprices every spell in the loadout',
        );
      });
    }

    testWidgets('⚠️ a cost above the engine cap still draws only five', (
      tester,
    ) async {
      await _pumpDots(tester, cost: 9);
      expect(
        find.byType(ChargeDot),
        findsNWidgets(5),
        reason:
            'an unclamped loop would overflow the reserved box and repaint '
            'the corner over the spell name rather than throwing where a '
            'test can see it',
      );
    });

    testWidgets('the engine\'s whole shipped range renders without throwing', (
      tester,
    ) async {
      for (final spell in _everyShippedSpell) {
        await _pumpDots(tester, cost: spell.chargeCost);
        expect(
          find.byType(ChargeDot),
          findsNWidgets(spell.chargeCost),
          reason:
              '${spell.name} costs ${spell.chargeCost} — if the catalogue '
              'ever grows a cost the widget cannot draw, this is where it '
              'surfaces instead of in the arena',
        );
      }
    });
  });

  group('the space is reserved whether or not anything is drawn', () {
    testWidgets('⭐ every cost 0–5 measures identically', (tester) async {
      final sizes = <int, Size>{};
      for (var cost = 0; cost <= 5; cost++) {
        await _pumpDots(tester, cost: cost);
        sizes[cost] = tester.getSize(find.byType(ChargeDots));
      }
      for (var cost = 1; cost <= 5; cost++) {
        expect(
          sizes[cost],
          sizes[0],
          reason:
              'cost $cost must occupy exactly what cost 0 occupies — a widget '
              'that shrink-wraps its dots (or returns SizedBox.shrink when '
              'free) makes the corner breathe as the loadout changes',
        );
      }
      expect(
        sizes[0]!.width,
        greaterThan(0),
        reason:
            'reserving nothing is the same bug worn inside out: a zero-width '
            'box for every cost would pass the equality above',
      );
    });

    testWidgets('a free spell draws no dots but still holds the corner', (
      tester,
    ) async {
      await _pumpDots(tester, cost: 0);
      expect(
        find.byType(ChargeDot),
        findsNothing,
        reason:
            'five hollow placeholder pips on Flick would read as "costs 5, '
            'unpaid" — the opposite of free',
      );
      expect(
        tester.getSize(find.byType(ChargeDots)).height,
        greaterThan(0),
        reason: 'a zero-height reservation collapses the row it sits in',
      );
    });

    testWidgets('⭐ in a real duel, the free tab and the dearest tab are the '
        'same size', (tester) async {
      await _pumpArena(tester);
      final flick = tester.getSize(_tabOf('Flick'));
      final cataclysm = tester.getSize(_tabOf('Cataclysm'));
      expect(
        flick,
        cataclysm,
        reason:
            'Flick costs 0 and Cataclysm costs 5; if the dots are laid out in '
            'the tab\'s flow rather than positioned over it, the expensive '
            'tab grows and the whole action bar re-flows — the standing rule '
            'this overlay exists to respect',
      );
      expect(
        flick.height,
        46,
        reason:
            'the tab body is a fixed 46 — a Stack that took its height from '
            'the dots instead of the Container would still be self-consistent '
            'above while quietly resizing the action bar',
      );
    });

    testWidgets('⭐ the dots sit in the top-right corner, over the tab and '
        'not inside its row', (tester) async {
      await _pumpArena(tester);
      final tab = tester.getRect(_tabOf('Cataclysm'));
      final dots = tester.getRect(
        find.descendant(
          of: _tabOf('Cataclysm'),
          matching: find.byType(ChargeDots),
        ),
      );
      expect(
        dots.top - tab.top,
        lessThan(tab.height / 4),
        reason:
            'the ask was the TOP right corner; laying the dots out as another '
            'child of the tab\'s Row centres them vertically (top offset ~21 '
            'on a 46-high tab) and crowds the spell name instead of hovering '
            'clear of it',
      );
      expect(
        tab.right - dots.right,
        lessThan(tab.width / 4),
        reason:
            'and the RIGHT corner: pinned left, the pips would collide with '
            'the spell icon',
      );
      expect(
        dots.bottom,
        lessThan(tester.getRect(find.text('Cataclysm')).top),
        reason:
            'the corner must clear the name outright — overlapping glyphs is '
            'the failure mode an overlay invites, and it is invisible to '
            'every size assertion above',
      );
    });
  });

  group('the corner is not silent', () {
    testWidgets('the label says the price in words', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDots(tester, cost: 3);
      expect(
        find.bySemanticsLabel('costs 3 charge'),
        findsOneWidget,
        reason:
            'dots are a picture; without this label a screen reader gets the '
            'spell name and no price at all',
      );
      handle.dispose();
    });

    testWidgets('⚠️ a free spell is labelled too, not skipped', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDots(tester, cost: 0);
      expect(
        find.bySemanticsLabel('costs 0 charge'),
        findsOneWidget,
        reason:
            'guarding the Semantics behind "if there are dots" leaves Flick '
            'as the one tab that never states its cost',
      );
      handle.dispose();
    });

    testWidgets('the spell tabs carry the label into the arena', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpArena(tester);
      // ⚠️ A RegExp, not the bare string: the arena collapses into ONE merged
      // semantics node (name, bars, turn, every tab), so an equality match
      // would fail for a label that is present and correct. What is being
      // proved here is only that the words reach the semantics tree at all —
      // the per-tab attribution is the assertion below it.
      expect(
        find.bySemanticsLabel(RegExp('costs 5 charge')),
        findsOneWidget,
        reason:
            'a Semantics node that never makes it into the arena\'s merged '
            'label leaves the whole action bar unpriced to a screen reader',
      );
      final dots = tester.widget<ChargeDots>(
        find.descendant(
          of: _tabOf('Cataclysm'),
          matching: find.byType(ChargeDots),
        ),
      );
      expect(
        dots.cost,
        Spellbook.cataclysm.chargeCost,
        reason:
            'this is the wiring test: a ChargeDots built but never mounted in '
            '_spellButton — or mounted with the slot index, the priority, or '
            'a hard-coded number instead of the spell\'s chargeCost — passes '
            'every unit case above',
      );
      handle.dispose();
    });
  });

  group('X-cost spells do not claim a flat price', () {
    testWidgets('⭐ Barrage draws hollow pips, and says "or more"', (
      tester,
    ) async {
      await _pumpDots(
        tester,
        cost: Spellbook.barrage.chargeCost,
        variable: true,
      );
      final dots = tester
          .widgetList<ChargeDot>(find.byType(ChargeDot))
          .toList();
      expect(
        dots.every((d) => !d.filled),
        isTrue,
        reason:
            'Barrage spends ALL held charge and its chargeCost is only the '
            'minimum; a solid single dot promises a 1-charge cast that the '
            'engine will never perform',
      );
      expect(
        const ChargeDots(cost: 1, variable: true).semanticsLabel,
        'costs 1 or more charge',
        reason:
            'reusing the flat label would tell a screen reader the exact '
            'thing the hollow pips exist to deny',
      );
    });

    testWidgets('⚠️ hollow pips measure like filled ones', (tester) async {
      await _pumpDots(tester, cost: 3);
      final filled = tester.getSize(find.byType(ChargeDots));
      await _pumpDots(tester, cost: 3, variable: true);
      expect(
        tester.getSize(find.byType(ChargeDots)),
        filled,
        reason:
            'a border drawn outside the box would make the X-cost tab the one '
            'odd corner in the row',
      );
    });
  });
}

/// Every spell the engine ships, so the range cases track the catalogue rather
/// than a copy of it.
final _everyShippedSpell = Spellbook.all;

Future<void> _pumpDots(
  WidgetTester tester, {
  required int cost,
  bool variable = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ChargeDots(cost: cost, variable: variable),
        ),
      ),
    ),
  );
}

/// The innermost tappable box of the spell tab named [spell] — the thing the
/// standing rule says must not move.
Finder _tabOf(String spell) =>
    find.ancestor(of: find.text(spell), matching: find.byType(InkWell)).first;

/// ⚠️ Bounded pumps, never [WidgetTester.pumpAndSettle]: the arena animates
/// continuously and never settles (see `belt_in_duel_test.dart`).
Future<void> _pumpArena(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: DuelScreen(
        loadout: Loadout.starter,
        driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(2)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
