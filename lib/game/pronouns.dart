/// Who the player is, grammatically.
///
/// ⭐ **The story talks about the player in the third person.** The mother
/// calls you her son or her daughter; the Library's record names you as
/// somebody's child. Narrative text therefore cannot be written as one fixed
/// string — every line that refers to the player has to bend.
///
/// ⚠️ **Verb agreement is the trap, not the pronouns.** "They is the child of"
/// is the failure mode, and it only shows up in the one case nobody tests.
/// [Pronouns] carries the verb forms alongside the pronouns for exactly that
/// reason.
library;

import 'package:flutter/foundation.dart';

/// What the player picked at character creation.
///
/// ⚠️ **[unspecified] is the migration default, not a third option in the UI.**
/// A save written before this field existed cannot be assumed either way, and
/// they/them is the only answer that is never wrong about a real person.
enum PlayerGender {
  boy(Pronouns.he),
  girl(Pronouns.she),
  unspecified(Pronouns.they);

  const PlayerGender(this.pronouns);

  final Pronouns pronouns;

  /// Parses a stored name. ⚠️ An unknown value reads as [unspecified] rather
  /// than throwing — a save from a newer build must not brick an older one.
  static PlayerGender byName(String? name) {
    for (final g in values) {
      if (g.name == name) return g;
    }
    return unspecified;
  }
}

/// One set of pronouns and the verb forms that have to agree with them.
@immutable
class Pronouns {
  /// they · he · she
  final String subject;

  /// them · him · her
  final String object;

  /// their · his · her
  final String possessive;

  /// theirs · his · hers
  final String possessivePronoun;

  /// themself · himself · herself
  final String reflexive;

  /// child · son · daughter — ⭐ what the mother calls you.
  final String child;

  /// True for they/them. ⚠️ **Grammatically plural even for one person**,
  /// which is the whole reason the verb forms below exist.
  final bool takesPluralVerb;

  const Pronouns({
    required this.subject,
    required this.object,
    required this.possessive,
    required this.possessivePronoun,
    required this.reflexive,
    required this.child,
    required this.takesPluralVerb,
  });

  static const they = Pronouns(
    subject: 'they',
    object: 'them',
    possessive: 'their',
    possessivePronoun: 'theirs',
    reflexive: 'themself',
    child: 'child',
    takesPluralVerb: true,
  );

  static const he = Pronouns(
    subject: 'he',
    object: 'him',
    possessive: 'his',
    possessivePronoun: 'his',
    reflexive: 'himself',
    child: 'son',
    takesPluralVerb: false,
  );

  static const she = Pronouns(
    subject: 'she',
    object: 'her',
    possessive: 'her',
    possessivePronoun: 'hers',
    reflexive: 'herself',
    child: 'daughter',
    takesPluralVerb: false,
  );

  /// Every token [apply] understands, lower-cased.
  ///
  /// ⭐ **Verbs are tokens too.** `{s}` is the third-person singular ending, so
  /// `'she walk{s}'` and `'they walk{s}'` are the same template — which covers
  /// most verbs without naming any of them.
  Map<String, String> get _tokens => {
    'they': subject,
    'them': object,
    'their': possessive,
    'theirs': possessivePronoun,
    'themself': reflexive,
    'child': child,
    'are': takesPluralVerb ? 'are' : 'is',
    'were': takesPluralVerb ? 'were' : 'was',
    'have': takesPluralVerb ? 'have' : 'has',
    'do': takesPluralVerb ? 'do' : 'does',
    's': takesPluralVerb ? '' : 's',
    'es': takesPluralVerb ? '' : 'es',
  };

  /// Fills `{token}` placeholders in [template].
  ///
  /// ⭐ **Capitalisation follows the token.** `{They}` yields "They", `{they}`
  /// yields "they" — so a sentence can start with one without the caller
  /// reaching for `substring`.
  ///
  /// ⚠️ **An unrecognised token is left alone**, loudly. It asserts in debug so
  /// a typo is caught in tests, and survives in release rather than throwing
  /// mid-cutscene — a stray `{thier}` on screen is bad; a crash is worse.
  String apply(String template) {
    final tokens = _tokens;
    return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
      final raw = m[1]!;
      final value = tokens[raw.toLowerCase()];
      if (value == null) {
        assert(false, 'unknown pronoun token {$raw} in: $template');
        return m[0]!;
      }
      // ⚠️ An empty replacement ({s} for they) has no first letter to raise,
      // so the capitalisation check must come after the null check and guard
      // against it.
      final wantsCapital =
          raw[0] == raw[0].toUpperCase() && raw[0] != raw[0].toLowerCase();
      if (!wantsCapital || value.isEmpty) return value;
      return value[0].toUpperCase() + value.substring(1);
    });
  }
}
