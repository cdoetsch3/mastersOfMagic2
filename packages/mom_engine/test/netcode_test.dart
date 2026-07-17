import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

void main() {
  group('action encoding round-trips', () {
    final cases = <MageAction>[
      const ChargeAction(MagicElement.fire),
      const ChargeAction(), // continuing a cycle — null element
      CastAction(Spellbook.blast, MagicElement.water),
      CastAction(Spellbook.flick, MagicElement.shadow),
      CastAction(Spellbook.barrage), // null element
      CastAction(Spellbook.overload, MagicElement.electric),
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

  group('commitments', () {
    test('a commitment verifies against its own move and nonce', () {
      final move = encodeAction(CastAction(Spellbook.blast, MagicElement.fire));
      final commit = commitmentOf(move, 'secret-nonce-123');
      expect(verifyCommitment(commit, move, 'secret-nonce-123'), isTrue);
    });

    test('changing the move after committing fails verification', () {
      final committed =
          encodeAction(CastAction(Spellbook.ward, MagicElement.water));
      final swapped =
          encodeAction(CastAction(Spellbook.cataclysm, MagicElement.fire));
      final commit = commitmentOf(committed, 'nonce');
      expect(verifyCommitment(commit, swapped, 'nonce'), isFalse);
    });

    test('the wrong nonce fails verification', () {
      final move = encodeAction(const ChargeAction(MagicElement.ice));
      final commit = commitmentOf(move, 'right');
      expect(verifyCommitment(commit, move, 'wrong'), isFalse);
    });

    test('commitments are deterministic', () {
      final move = encodeAction(CastAction(Spellbook.jolt, MagicElement.air));
      expect(commitmentOf(move, 'n'), commitmentOf(move, 'n'));
    });
  });

  group('turn seed derivation', () {
    test('both sides derive the same seed regardless of move order', () {
      final a = encodeAction(CastAction(Spellbook.blast, MagicElement.fire));
      final b = encodeAction(const ChargeAction(MagicElement.water));
      expect(deriveTurnSeed(42, 3, a, b), deriveTurnSeed(42, 3, b, a));
    });

    test('the seed changes with the moves and the turn', () {
      final a = encodeAction(CastAction(Spellbook.blast, MagicElement.fire));
      final b = encodeAction(CastAction(Spellbook.bolt, MagicElement.fire));
      expect(deriveTurnSeed(42, 3, a, a), isNot(deriveTurnSeed(42, 3, a, b)));
      expect(deriveTurnSeed(42, 3, a, b), isNot(deriveTurnSeed(42, 4, a, b)));
    });
  });
}
