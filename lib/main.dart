import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'game/auth_service.dart';
import 'game/content_version.dart';
import 'game/game_state.dart';
import 'game/profile_storage.dart';
import 'screens/content_gate_screen.dart';
import 'screens/home_shell.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (running without accounts): $e');
  }
  runApp(const MastersOfMagicApp());
}

class MastersOfMagicApp extends StatefulWidget {
  const MastersOfMagicApp({super.key});

  @override
  State<MastersOfMagicApp> createState() => _MastersOfMagicAppState();
}

class _MastersOfMagicAppState extends State<MastersOfMagicApp> {
  late final Future<GameState> _future = GameState.boot(LocalProfileStorage());

  /// ⭐ The content-version gate. Started at boot, **beside** the profile load
  /// rather than after it: `config/content` is public-read (firestore.rules),
  /// so this needs neither Firebase Auth nor a signed-in user, and a guest on
  /// a stale build desyncs a duel exactly like an account does.
  ///
  /// ⚠️ Fires once per app launch, not once per sign-in — a refresh is the
  /// only cure, so re-checking later would only annoy someone mid-duel.
  late final Future<ContentGateDecision> _gate = checkContentVersion();

  /// A room code from a scanned QR link (?join=CODE). Read once at boot —
  /// ⭐ the friend scans the host's QR with their phone camera, the browser
  /// opens this URL, and HomeShell walks them straight into the duel.
  final String? _pendingJoinCode = () {
    final code = Uri.base.queryParameters['join'];
    return (code == null || code.trim().isEmpty)
        ? null
        : code.trim().toUpperCase();
  }();
  late final AuthService? _auth = Firebase.apps.isNotEmpty
      ? AuthService()
      : null;
  GameState? _gameState;

  @override
  void initState() {
    super.initState();
    // Once the profile is loaded, keep its storage backend in sync with the
    // signed-in user (local while a guest, Firestore once authenticated).
    _future.then((gs) {
      _gameState = gs;
      final auth = _auth;
      if (auth != null) {
        auth.addListener(_onAuthChanged);
        _onAuthChanged();
      }
    });
  }

  void _onAuthChanged() => _gameState?.syncWithAuth(_auth?.user?.uid);

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masters of Magic 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B3FA8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        useMaterial3: true,
      ),
      // Provide the game-state and auth scopes ABOVE the Navigator so every
      // route (including pushed ones like the account screen) can read them.
      builder: (context, child) {
        return FutureBuilder<ContentGateDecision>(
          future: _gate,
          builder: (context, gate) {
            if (!gate.hasData) return const _Booting();
            // ⭐ The gate sits ABOVE the game-state scope and the Navigator:
            // a gated client never builds the shell at all, so there is
            // nothing behind the screen to reach.
            if (gate.data!.blocks) return const ContentGateScreen();
            return _buildGame(child!);
          },
        );
      },
      home: HomeShell(pendingJoinCode: _pendingJoinCode),
    );
  }

  /// The scoped game, once the gate has let the player through.
  Widget _buildGame(Widget child) {
    return FutureBuilder<GameState>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _Booting();
        Widget scoped = GameStateScope(
          state: snapshot.data!,
          // ⚠️ Above the Navigator, so every pushed route is constrained
          // too — not just the tabs.
          child: MaxWidth(child: child),
        );
        final auth = _auth;
        if (auth != null) {
          scoped = AuthScope(service: auth, child: scoped);
        }
        return scoped;
      },
    );
  }
}

/// The boot spinner, shown while the profile loads and while the
/// content-version check is in flight.
class _Booting extends StatelessWidget {
  const _Booting();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.bg,
    child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
  );
}
