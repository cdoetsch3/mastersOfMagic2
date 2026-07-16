import 'package:flutter/material.dart';

/// Shared palette + small building blocks so every screen reads as one game.
abstract final class AppColors {
  static const bg = Color(0xFF141021);
  static const panel = Color(0xFF1B1531);
  static const panelHi = Color(0xFF1E1836);
  static const border = Color(0xFF373060);
  static const borderDim = Color(0xFF2A2342);
  static const text = Color(0xFFECE7F8);
  static const textDim = Color(0xFF9C93C4);
  static const textFaint = Color(0xFF6E6A7A);
  static const gold = Color(0xFFE8C547);
  static const ember = Color(0xFFE25822);
  static const green = Color(0xFF58B368);
  static const teal = Color(0xFF5DCAA5);
  static const sky = Color(0xFF85B7EB);
  static const gem = Color(0xFF8B5CD6);
}

/// A rounded surface panel used across the menus.
class GamePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.panelHi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: panel,
    );
  }
}

/// Section label used above lists/grids.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600)),
      );
}
