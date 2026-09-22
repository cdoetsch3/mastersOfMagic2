import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

/// The shared destination for a row whose screen is not written yet.
///
/// ⭐ **One screen for every placeholder** (ruling 2026-09-21). The Profile's
/// rows exist so the shape of the profile is settled before the content
/// behind them is built; each unbuilt one lands here and says so plainly,
/// rather than growing a fake of its own that counts nothing.
///
/// ⚠️ Nothing here is per-feature — the [title] is the whole difference. A
/// placeholder that starts describing what its feature *will* do is a
/// feature, and belongs in its own screen.
class ComingSoonScreen extends StatelessWidget {
  /// The row that opened this — used verbatim as the AppBar title, so the
  /// player lands somewhere that names where they tapped.
  final String title;

  const ComingSoonScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.panel, title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Not built yet — it is on the list.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
