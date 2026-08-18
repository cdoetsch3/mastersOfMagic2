import 'package:flutter/material.dart';

import '../game/app_reload.dart';
import '../ui/app_theme.dart';

/// The blocking screen shown when this build's [ContentVersion.current]
/// disagrees with the server's.
///
/// ⭐ **There is deliberately no way past it** — no Back, no "continue
/// anyway", no dismissal. A client that disagrees about what a staff does
/// desyncs the lockstep commit-reveal duel, and the failure presents as a
/// netcode bug rather than a data bug (IMPLEMENTATION_PLAN, "LOGIN
/// content-version gate"). Refusing to run is the whole feature.
///
/// 📝 The copy says *refresh*, not *update*: on web the fix really is a page
/// reload, and telling a player to visit a store they cannot find is worse
/// than telling them nothing.
class ContentGateScreen extends StatelessWidget {
  /// Overridable so the widget test can press the button without asking the
  /// test harness to reload a page it does not have. Defaults to the real
  /// browser reload.
  final VoidCallback onRefresh;

  const ContentGateScreen({super.key, this.onRefresh = reloadApp});

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // ⚠️ Android back / browser back must not slip underneath the gate.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GamePanel(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.system_update_alt,
                        color: AppColors.gold,
                        size: 44,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'A new version is out',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This copy of Masters of Magic is running older '
                        'content than the server. Refresh to load the current '
                        'version — duels, loot and prices all have to agree '
                        'before you can play.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gem,
                          foregroundColor: AppColors.text,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
