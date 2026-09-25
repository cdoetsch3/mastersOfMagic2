/// One way to print a ladder rating, everywhere (Christian, 2026-09-25: one
/// rating style across the home card, the Profile chips, the duel header and
/// the result card's Ranking row).
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A ladder rating: [AppColors.sky], tabular figures, `w600`.
///
/// ⭐ **Why sky.** Every other candidate already means something: gold is
/// currency, teal/green is a gain, ember is a loss, gem is the Academy
/// itself. A rating sits right beside a green '+12' on the result card and a
/// gold purse on the home card, and must read as neither. Sky's other uses
/// (Quicken, shields) never share a line with a rating.
///
/// ⭐ Tabular figures so '1199' → '1203' does not shuffle whatever sits to
/// its right — the Ranking cell is fixed-width on purpose, and the duel
/// nameplate shares a row with a name that ellipsizes.
///
/// ⚠️ **Mostly used as a span, not a widget.** Every existing rating line is
/// one [Text] ('Ladder 1420', '+12 · 1432') that tests and layouts treat as a
/// unit; nesting a widget would split it. So [span] is the primitive, and
/// this widget is just `Text.rich(span(...))` for a rating that stands
/// alone. Either way the style comes from one place.
class RatingText extends StatelessWidget {
  /// The rating, or null for "no rating on this ladder yet".
  final int? rating;
  final double size;

  const RatingText(this.rating, {super.key, this.size = 13});

  /// What a missing rating prints as. 📝 An em dash, matching the '—' the
  /// home card and the Profile chips already used before this widget.
  static const String none = '—';

  /// The rating colour. ⭐ The one knob — change it here and every rating in
  /// the game follows.
  static const Color colour = AppColors.sky;

  /// The style a PRESENT rating is printed in.
  static TextStyle style({double size = 13}) => TextStyle(
    color: colour,
    fontSize: size,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// The rating as an inline span, for a line that says more than the
  /// number ('Ladder ', '+12 · ').
  ///
  /// ⚠️ A null rating prints [none] in [AppColors.textDim], NOT the rating
  /// colour: '—' is the absence of a rating, and painting it sky would make
  /// "unrated" look like a value.
  static TextSpan span(int? rating, {double size = 13}) => rating == null
      ? TextSpan(
          text: none,
          style: style(size: size).copyWith(color: AppColors.textDim),
        )
      : TextSpan(
          text: '$rating',
          style: style(size: size),
        );

  @override
  Widget build(BuildContext context) =>
      Text.rich(span(rating, size: size), maxLines: 1, softWrap: false);
}
