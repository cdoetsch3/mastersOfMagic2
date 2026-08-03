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
/// Keeps the app a readable column on a laptop or tablet.
///
/// ⚠️ **The layout is phone-first** — tabs, a header, single-column lists — and
/// stretched to 2000px it reads as a broken website rather than a game. This
/// caps it and centres it, letting the background fill the rest.
///
/// ⭐ Applied once in `MaterialApp.builder`, **above the Navigator**, so every
/// pushed route (duel, adventure, account) inherits it. Doing it per-screen
/// would mean every new screen has to remember.
class MaxWidth extends StatelessWidget {
  /// Wide enough for a two-column inventory grid, narrow enough that a line of
  /// body text stays comfortable.
  ///
  /// ⚠️ Pushed routes only. The home shell uses [shellWidth], which is
  /// narrower — see there for why.
  static const double maxWidth = 900;

  /// The phone-ish column the tab shell lives in.
  ///
  /// ⭐ **Narrower than [maxWidth] on purpose**, and it must wrap the nav bar
  /// as well as the content — otherwise the bar is wider than what it
  /// navigates, which is what shipped.
  static const double shellWidth = 720;

  final Widget child;

  const MaxWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.bg,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  );
}

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

/// A fantasy gold coin (concentric disc with a small star), drawn rather than
/// using the dollar-sign coin icon.
class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _CoinPainter());
}

class _CoinPainter extends CustomPainter {
  static const _gold = Color(0xFFE8C547);
  static const _goldDark = Color(0xFFB0851E);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final fill = Paint()..color = _gold;
    canvas.drawCircle(c, r, fill);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..color = _goldDark;
    canvas.drawCircle(c, r * 0.72, ring);
    // A small 4-point sparkle in the middle.
    final star = Path();
    final s = r * 0.42;
    star.moveTo(c.dx, c.dy - s);
    star.quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy);
    star.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s);
    star.quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy);
    star.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s);
    canvas.drawPath(star, Paint()..color = _goldDark);
  }

  @override
  bool shouldRepaint(_CoinPainter old) => false;
}

/// A wizard hat silhouette icon (pointed hat, brim, and a sparkle), drawn so
/// it reads as fantasy rather than a generic wand emoji.
class WizardHatIcon extends StatelessWidget {
  final double size;
  final Color color;
  const WizardHatIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _WizardHatPainter(color));
}

class _WizardHatPainter extends CustomPainter {
  final Color color;
  _WizardHatPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24.0;
    final paint = Paint()..color = color;
    // Cone (apex bent slightly to the right).
    final cone = Path()
      ..moveTo(5.5 * k, 16.5 * k)
      ..lineTo(14 * k, 3 * k)
      ..lineTo(16.8 * k, 16.5 * k)
      ..close();
    canvas.drawPath(cone, paint);
    // Brim.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(11 * k, 17.2 * k),
        width: 17 * k,
        height: 4.4 * k,
      ),
      paint,
    );
    // Sparkle star, upper right.
    final sc = Offset(19.5 * k, 6.5 * k);
    final s = 2.6 * k;
    final star = Path()
      ..moveTo(sc.dx, sc.dy - s)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx + s, sc.dy)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx, sc.dy + s)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx - s, sc.dy)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx, sc.dy - s)
      ..close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(_WizardHatPainter old) => old.color != color;
}

/// Section label used above lists/grids.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textDim,
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
