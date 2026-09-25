/// The one rating style (Christian, 2026-09-25): [RatingText] and its
/// [RatingText.span].
///
/// ⭐ Mutation-verified: every `expect` names the wrong implementation it
/// kills.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';
import 'package:masters_of_magic_2/ui/rating_text.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget w) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: w)),
    ),
  );

  testWidgets('null renders an em dash', (tester) async {
    await show(tester, const RatingText(null));
    expect(
      find.text('—'),
      findsOneWidget,
      reason:
          'no rating yet reads as a dash — a mutant printing "null", "0" '
          'or an empty string would fail this',
    );
  });

  testWidgets('a rating renders as its bare number', (tester) async {
    await show(tester, const RatingText(1432));
    expect(
      find.text('1432'),
      findsOneWidget,
      reason: 'the number alone — no label, no separator baked in',
    );
  });

  test('a present rating is sky, w600, tabular', () {
    final style = RatingText.span(1432, size: 14).style!;
    expect(
      style.color,
      AppColors.sky,
      reason:
          'sky is the ruled rating colour — gold is currency, teal/green '
          'a gain; a mutant using either would collide with them',
    );
    expect(
      style.fontWeight,
      FontWeight.w600,
      reason: 'the ruled weight — a mutant at w400 reads as body text',
    );
    expect(
      style.fontFeatures,
      contains(const FontFeature.tabularFigures()),
      reason:
          'tabular figures keep 1199 → 1203 from shuffling the fixed-width '
          'Ranking cell — a mutant dropping them fails this',
    );
    expect(
      style.fontSize,
      14,
      reason: 'the size parameter is honoured, not hard-coded to 13',
    );
  });

  test('the dash is dim, not the rating colour', () {
    expect(
      RatingText.span(null).style?.color,
      AppColors.textDim,
      reason:
          'the absence of a rating must not look like a value — a mutant '
          'that paints "—" sky would make "unrated" read as a number',
    );
  });

  test('the default size is 13', () {
    expect(
      RatingText.span(1200).style?.fontSize,
      13,
      reason: 'the ruled default — a mutant changing it moves every caller',
    );
  });
}
