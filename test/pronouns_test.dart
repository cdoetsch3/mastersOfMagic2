import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/pronouns.dart';

void main() {
  group('pronouns bend a line three ways', () {
    const line = '{They} {are} the {child} she {have} been waiting for.';

    test('boy', () {
      expect(
        Pronouns.he.apply(line),
        'He is the son she has been waiting for.',
      );
    });

    test('girl', () {
      expect(
        Pronouns.she.apply(line),
        'She is the daughter she has been waiting for.',
      );
    });

    test('⭐ they/them keeps the PLURAL verb', () {
      // ⚠️ The bug this guards: "They is the child". It is the only case that
      // needs the verb to move, and the only one a hand-written string gets
      // wrong.
      expect(
        Pronouns.they.apply(line),
        'They are the child she have been waiting for.',
      );
    });
  });

  group('the verb-ending token', () {
    test('{s} appears for singular and vanishes for plural', () {
      const t = '{They} walk{s} north.';
      expect(Pronouns.he.apply(t), 'He walks north.');
      expect(Pronouns.they.apply(t), 'They walk north.');
    });

    test('{es} does the same for verbs that need it', () {
      const t = 'She watch{es} the road.';
      expect(Pronouns.she.apply(t), 'She watches the road.');
      expect(Pronouns.they.apply(t), 'She watch the road.');
    });

    test('⚠️ an empty replacement does not crash the capitaliser', () {
      // {S} is pathological but reachable via a typo, and value[0] on '' is
      // the crash it would cause.
      expect(Pronouns.they.apply('walk{S}'), 'walk');
    });
  });

  group('capitalisation follows the token', () {
    test('every pronoun token can start a sentence', () {
      expect(
        Pronouns.she.apply('{They}. {Them}. {Their}. {Theirs}. {Themself}.'),
        'She. Her. Her. Hers. Herself.',
      );
    });

    test('the lower-case form stays lower', () {
      expect(Pronouns.he.apply('for {them}'), 'for him');
    });
  });

  group('unknown tokens', () {
    test('⚠️ a typo asserts in debug rather than shipping silently', () {
      expect(
        () => Pronouns.they.apply('{thier} road'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the profile carries a gender', () {
    test('a new character is they/them until it picks', () {
      // ⭐ Not a UI option — the safe default for a save that has not answered.
      expect(PlayerProfile.newPlayer().gender, PlayerGender.unspecified);
      expect(PlayerProfile.newPlayer().pronouns.child, 'child');
    });

    test('boy and girl reach the right words', () {
      expect(
        PlayerProfile.newPlayer(gender: PlayerGender.boy).pronouns.child,
        'son',
      );
      expect(
        PlayerProfile.newPlayer(gender: PlayerGender.girl).pronouns.child,
        'daughter',
      );
    });

    test('it survives a save/load round trip', () {
      final saved = PlayerProfile.newPlayer(
        name: 'Wren',
        gender: PlayerGender.girl,
      ).toJson();
      expect(PlayerProfile.fromJson(saved).gender, PlayerGender.girl);
    });

    test('⚠️ a save from before the field reads as unspecified', () {
      final old = PlayerProfile.newPlayer(gender: PlayerGender.boy).toJson()
        ..remove('gender');
      expect(PlayerProfile.fromJson(old).gender, PlayerGender.unspecified);
    });

    test('⚠️ an unknown gender from a newer build does not brick the load', () {
      final future = PlayerProfile.newPlayer().toJson()
        ..['gender'] = 'something_new';
      expect(PlayerProfile.fromJson(future).gender, PlayerGender.unspecified);
    });
  });
}
