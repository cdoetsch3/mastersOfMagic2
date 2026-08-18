import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  group('action encoding round-trips', () {
    final cases = <MageAction>[
      const ChargeAction(MagicElement.pyro),
      const ChargeAction(), // continuing a cycle — null element
      CastAction(Spellbook.blast, MagicElement.aqua),
      CastAction(Spellbook.flick, MagicElement.umbra),
      CastAction(Spellbook.barrage), // null element
      CastAction(Spellbook.overload, MagicElement.electro),
    ];

    for (final action in cases) {
      test('$action survives encode → decode', () {
        final decoded = decodeAction(encodeAction(action));
        expect(encodeAction(decoded), encodeAction(action));
      });
    }

    test('malformed wire throws', () {
      expect(() => decodeAction('X|nonsense'), throwsFormatException);
      expect(() => decodeAction('S|bolt'), throwsFormatException);
    });
  });

  group('belt items cross the wire as an ID, never as numbers', () {
    const draught =
        ConsumableEffect(name: 'Sapwort Draught', healNowPercent: 20);
    ConsumableEffect? lookup(String id) =>
        id == 'sapwort_draught' ? draught : null;

    test('a drink encodes to U|<defId> and nothing else', () {
      expect(
        encodeAction(const UseItemAction('sapwort_draught', draught)),
        'U|sapwort_draught',
        reason: '⚠️ the EFFECT must not ride along — a wire that carried the '
            'heal would let a doctored client drink a 900% potion, and the '
            'commitment hash would happily cover it',
      );
    });

    test('round-trips through the injected catalogue', () {
      final decoded = decodeAction(
        encodeAction(const UseItemAction('sapwort_draught', draught)),
        consumables: lookup,
      );
      expect(decoded, isA<UseItemAction>());
      final use = decoded as UseItemAction;
      expect(use.itemId, 'sapwort_draught');
      expect(
        use.effect.healNowPercent,
        20,
        reason: 'the receiving client resolves the numbers from its OWN '
            'catalogue — that resolution is the whole point of the id',
      );
      expect(encodeAction(decoded), 'U|sapwort_draught');
    });

    test('⚠️ an item this build cannot resolve throws rather than fizzling',
        () {
      expect(
        () => decodeAction('U|philosophers_stone', consumables: lookup),
        throwsFormatException,
        reason: 'a silent no-op potion would desync the two clients — one '
            'heals, the other does not, and both keep playing',
      );
    });

    test('a duel with no catalogue injected rejects item moves outright', () {
      expect(
        () => decodeAction('U|sapwort_draught'),
        throwsFormatException,
        reason: 'no resolver means no way to agree on the heal, which is a '
            'refusal, not a default',
      );
    });

    test('the commitment covers the item, so it cannot be swapped', () {
      final committed = encodeAction(
        const UseItemAction('sapwort_draught', draught),
      );
      final swapped = encodeAction(
        const UseItemAction('brookmint_tonic', draught),
      );
      final commit = commitmentOf(committed, 'nonce');
      expect(verifyCommitment(commit, swapped, 'nonce'), isFalse);
    });
  });

  group('commitments', () {
    test('a commitment verifies against its own move and nonce', () {
      final move = encodeAction(CastAction(Spellbook.blast, MagicElement.pyro));
      final commit = commitmentOf(move, 'secret-nonce-123');
      expect(verifyCommitment(commit, move, 'secret-nonce-123'), isTrue);
    });

    test('changing the move after committing fails verification', () {
      final committed =
          encodeAction(CastAction(Spellbook.ward, MagicElement.aqua));
      final swapped =
          encodeAction(CastAction(Spellbook.cataclysm, MagicElement.pyro));
      final commit = commitmentOf(committed, 'nonce');
      expect(verifyCommitment(commit, swapped, 'nonce'), isFalse);
    });

    test('the wrong nonce fails verification', () {
      final move = encodeAction(const ChargeAction(MagicElement.geo));
      final commit = commitmentOf(move, 'right');
      expect(verifyCommitment(commit, move, 'wrong'), isFalse);
    });

    test('commitments are deterministic', () {
      final move = encodeAction(CastAction(Spellbook.jolt, MagicElement.aero));
      expect(commitmentOf(move, 'n'), commitmentOf(move, 'n'));
    });
  });

  group('turn seed derivation', () {
    test('both sides derive the same seed regardless of move order', () {
      final a = encodeAction(CastAction(Spellbook.blast, MagicElement.pyro));
      final b = encodeAction(const ChargeAction(MagicElement.aqua));
      expect(deriveTurnSeed(42, 3, a, b), deriveTurnSeed(42, 3, b, a));
    });

    test('the seed changes with the moves and the turn', () {
      final a = encodeAction(CastAction(Spellbook.blast, MagicElement.pyro));
      final b = encodeAction(CastAction(Spellbook.bolt, MagicElement.pyro));
      expect(deriveTurnSeed(42, 3, a, a), isNot(deriveTurnSeed(42, 3, a, b)));
      expect(deriveTurnSeed(42, 3, a, b), isNot(deriveTurnSeed(42, 4, a, b)));
    });
  });
}
