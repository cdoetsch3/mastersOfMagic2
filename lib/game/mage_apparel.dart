import 'package:flutter/material.dart';

/// Colors for each visible apparel piece on the mage sprite. Later this is
/// derived from equipped items (equipment system); for now, presets.
class MageApparel {
  final Color hat;
  final Color hatTrim;
  final Color robe;
  final Color robeTrim;
  final Color gloves;
  final Color boots;

  const MageApparel({
    required this.hat,
    required this.hatTrim,
    required this.robe,
    required this.robeTrim,
    required this.gloves,
    required this.boots,
  });

  static const apprenticeBlue = MageApparel(
    hat: Color(0xFF2E5FA3),
    hatTrim: Color(0xFFE8C547),
    robe: Color(0xFF3A70B8),
    robeTrim: Color(0xFFE8C547),
    gloves: Color(0xFF8A6B4A),
    boots: Color(0xFF5C4632),
  );

  static const duskWitch = MageApparel(
    hat: Color(0xFF5B3FA8),
    hatTrim: Color(0xFFD4537E),
    robe: Color(0xFF4A3389),
    robeTrim: Color(0xFFD4537E),
    gloves: Color(0xFF3A2E37),
    boots: Color(0xFF2C2230),
  );
}
