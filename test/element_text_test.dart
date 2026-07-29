import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/element_style.dart';
import 'package:masters_of_magic_2/ui/element_text.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const base = TextStyle(color: Color(0xFFB9B2D6), fontSize: 12.5);

  Color? colourOf(String text, String fragment) {
    for (final s in elementSpans(text, base: base)) {
      if (s.text == fragment) return s.style?.color;
    }
    return null;
  }

  test('every element is written as a proper noun', () {
    for (final e in MagicElement.values) {
      expect(e.displayName[0], e.displayName[0].toUpperCase(), reason: e.name);
      expect(e.displayName.toLowerCase(), e.name);
    }
  });

  test('a spell name is coloured WITH its element', () {
    // ⭐ "casts Arcane Overload" tints the whole spell, not half of it.
    const line = 'You cast Arcane Overload';
    expect(
      colourOf(line, 'Arcane Overload'),
      elementStyles[MagicElement.arcane]!.color,
    );
  });

  test('a bare element name is still coloured', () {
    const line = 'You channel Flora (charge 3)';
    expect(colourOf(line, 'Flora'), elementStyles[MagicElement.flora]!.color);
  });

  test('prose around the element keeps the base colour', () {
    final spans = elementSpans('You cast Pyro Bolt', base: base);
    expect(spans.first.text, 'You cast ');
    expect(spans.first.style?.color, base.color);
  });

  test('two different elements in one line each get their own colour', () {
    const line = "Astral Bulwark meets Umbra Ruin";
    expect(
      colourOf(line, 'Astral Bulwark'),
      elementStyles[MagicElement.astral]!.color,
    );
    expect(
      colourOf(line, 'Umbra Ruin'),
      elementStyles[MagicElement.umbra]!.color,
    );
  });

  test('a word that merely contains an element name is left alone', () {
    // ⚠️ Word boundaries matter: "Floral" is not Flora, and a substring match
    // would tint half a word mid-sentence.
    final spans = elementSpans('The Floral arrangement', base: base);
    expect(spans.length, 1);
    expect(spans.single.style?.color, base.color);
  });

  test('text with no element is a single untouched span', () {
    final spans = elementSpans('— Turn 10', base: base);
    expect(spans.single.text, '— Turn 10');
  });
}
