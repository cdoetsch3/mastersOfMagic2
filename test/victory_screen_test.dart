import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/progression.dart';

void main() {
  test('⚠️ the XP a win is worth is NOT the flat base', () {
    // The victory screen used to display Progression.winXp while GameState
    // banked xpForDuel — so beating a level-5 foe said "+60 XP" and paid 110.
    expect(
      Progression.xpForDuel(won: true, opponentLevel: 5),
      isNot(Progression.winXp),
    );
    expect(
      Progression.xpForDuel(won: true, opponentLevel: 5),
      greaterThan(Progression.xpForDuel(won: true, opponentLevel: 1)),
    );
  });

  test('a loss is flat, whoever beat you', () {
    expect(
      Progression.xpForDuel(won: false, opponentLevel: 1),
      Progression.xpForDuel(won: false, opponentLevel: 60),
    );
  });
}
