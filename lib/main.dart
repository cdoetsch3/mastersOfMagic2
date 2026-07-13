import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/loadout_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The duel arena is a landscape experience (no-op on web).
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MastersOfMagicApp());
}

class MastersOfMagicApp extends StatelessWidget {
  const MastersOfMagicApp({super.key});

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
        useMaterial3: true,
      ),
      home: const LoadoutScreen(),
    );
  }
}
