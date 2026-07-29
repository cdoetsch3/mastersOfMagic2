import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/element_style.dart';

/// Renders prose with every element name in that element's own colour.
///
/// ⭐ Elements are the game's vocabulary — "Arcane Overload" should read as
/// *Arcane* everywhere it appears, not only on the pips and buttons. This is
/// shared rather than living in the battle log because narration, quest text
/// and encounter descriptions will all want the same treatment, and three
/// copies of a colouring rule is three chances to disagree.
///
/// ⚠️ A spell name **immediately after** an element is coloured with it, so
/// "casts Arcane Overload" tints the whole spell rather than half of it. The
/// test for this is in `element_text_test.dart`.
List<TextSpan> elementSpans(String text, {required TextStyle base}) {
  if (text.isEmpty) return [TextSpan(text: text, style: base)];

  // Longest first, so "Astral" is never matched as a prefix of something else
  // and short names cannot shadow longer ones.
  final names = <String, MagicElement>{
    for (final e in MagicElement.values) e.displayName: e,
  };
  final ordered = names.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final pattern = RegExp(r'\b(' + ordered.join('|') + r')\b(\s+[A-Z][a-z]+)?');

  final spans = <TextSpan>[];
  var at = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > at) {
      spans.add(TextSpan(text: text.substring(at, m.start), style: base));
    }
    final element = names[m.group(1)]!;
    spans.add(
      TextSpan(
        text: m.group(0),
        style: base.copyWith(
          color: elementStyles[element]!.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    at = m.end;
  }
  if (at < text.length) {
    spans.add(TextSpan(text: text.substring(at), style: base));
  }
  return spans;
}

/// [elementSpans] as a ready-to-drop widget.
class ElementRichText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const ElementRichText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(children: elementSpans(text, base: style)));
}
