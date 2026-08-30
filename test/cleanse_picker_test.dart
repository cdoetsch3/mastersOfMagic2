import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/ui/cleanse_picker.dart';

/// The Cleanse picker (TYPE_EFFECTS §7a): "one debuff of your CHOICE" needs a
/// UI to ask the choice, and the three-way answer contract is the part worth
/// pinning — a dismissal must never become a cast.
void main() {
  Future<CleanseChoice?> pump(
    WidgetTester tester,
    List<({String id, int turnsLeft})> debuffs,
  ) async {
    CleanseChoice? result;
    var settled = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showDialog<CleanseChoice>(
              context: context,
              builder: (_) => CleansePickerDialog(debuffs: debuffs),
            );
            settled = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(settled, isFalse, reason: 'the dialog should be waiting');
    return result;
  }

  const twoDebuffs = [
    (id: 'torment', turnsLeft: 7),
    (id: 'blight', turnsLeft: 20),
  ];

  testWidgets('every debuff is a row, named from the catalogue', (t) async {
    await pump(t, twoDebuffs);
    expect(find.text('Torment'), findsOneWidget,
        reason: 'rows carry catalogue names, not raw ids — the mutant this '
            'kills shows the player "torment" the identifier');
    expect(find.text('Blight'), findsOneWidget);
    expect(find.text('7 turns'), findsOneWidget,
        reason: 'a timed debuff shows its clock');
  });

  testWidgets('an untimed debuff shows no zero-turn clock', (t) async {
    await pump(t, const [
      (id: 'stagger', turnsLeft: 0),
      (id: 'torment', turnsLeft: 7),
    ]);
    expect(find.text('0 turns'), findsNothing,
        reason: 'Waterlogged and Stagger have no clock — "0 turns" would '
            'read as expiring, which is the opposite of untimed');
  });

  testWidgets('the three-way contract: pick, auto, and dismissal', (t) async {
    // Pick a specific debuff → CleanseChoice with its id.
    CleanseChoice? picked;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showDialog<CleanseChoice>(
              context: context,
              builder: (_) => const CleansePickerDialog(debuffs: twoDebuffs),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Torment'));
    await t.pumpAndSettle();
    expect(picked?.statusId, 'torment',
        reason: 'the chosen row travels as the action payload');

    // The auto row → CleanseChoice(null): cast, engine default.
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Whichever runs longest'));
    await t.pumpAndSettle();
    expect(picked, isNotNull,
        reason: 'auto is an ANSWER, not a dismissal');
    expect(picked!.statusId, isNull,
        reason: 'null id = the engine\'s documented default pick');

    // Tapping outside → plain null: the cast is CANCELLED, charge unspent.
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(picked, isNull,
        reason: '⚠️ the mutant this kills: a dismissal defaulting to auto '
            'would spend 2 charge on a mis-tap');
  });
}
