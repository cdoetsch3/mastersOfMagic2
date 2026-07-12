import 'package:flutter/material.dart';

import 'screens/engine_demo_screen.dart';

void main() {
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
      home: const EngineDemoScreen(),
    );
  }
}
