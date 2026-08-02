import 'package:flutter/material.dart';

import '../screens/adventure_screen.dart';
import 'game_state.dart';
import 'world.dart';

/// Starts a run at [zone] and opens the adventure screen.
///
/// ⭐ **The run is rolled before the screen opens**, so the screen can show
/// "encounter 1 of 9" immediately rather than discovering its own length as it
/// goes (GAME_DESIGN world structure).
Future<void> launchAdventure(BuildContext context, GameLocation zone) async {
  final game = GameStateScope.read(context);
  game.beginAdventure(zone);
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => AdventureScreen(zone: zone)));
}
