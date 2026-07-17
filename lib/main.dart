import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'game/auth_service.dart';
import 'game/game_state.dart';
import 'game/profile_storage.dart';
import 'screens/home_shell.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
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
  late final AuthService? _auth =
      Firebase.apps.isNotEmpty ? AuthService() : null;
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
        return FutureBuilder<GameState>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ColoredBox(
                color: AppColors.bg,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold)),
              );
            }
            Widget scoped =
                GameStateScope(state: snapshot.data!, child: child!);
            final auth = _auth;
            if (auth != null) {
              scoped = AuthScope(service: auth, child: scoped);
            }
            return scoped;
          },
        );
      },
      home: const HomeShell(),
    );
  }
}
