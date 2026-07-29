import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../ui/app_theme.dart';
import '../ui/interactive_world_map.dart';

/// The world map with the whole window to itself.
///
/// ⭐ Deliberately thin. Expanding the map gives it **room and the geography
/// labels** — it is not where the map becomes usable, because the card on the
/// Map tab is the same [InteractiveWorldMap] and can already pan, zoom, and
/// open any place.
class WorldMapScreen extends StatelessWidget {
  final GameState game;
  const WorldMapScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.panel,
          foregroundColor: AppColors.text,
          title: Text(game.profile.location.name),
        ),
        // Opens filling the window and framed on the player. "Whole world" is
        // one tap away in the controls; opening *at* the whole world left
        // nothing to pan and shrank the map to a strip on a wide screen.
        body: InteractiveWorldMap(game: game, focusOnPlayer: true),
      ),
    );
  }
}

/// The map as it sits at the top of the Map tab: a square, fully interactive,
/// framed on the player.
class WorldMapCard extends StatelessWidget {
  final GameState game;
  final VoidCallback onExpand;
  const WorldMapCard({super.key, required this.game, required this.onExpand});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: AspectRatio(
      aspectRatio: 1,
      child: InteractiveWorldMap(
        game: game,
        onExpand: onExpand,
        compact: true,
        // A square has room for terrain, not for thirty-two more names.
        showFeatureLabels: false,
        // ⭐ Opens looking at your own surroundings: a little tighter than
        // filling the square, so the neighbours you can actually travel to are
        // the pins under your thumb.
        focusOnPlayer: true,
        initialZoom: 1.6,
        // The tab card sits in a scrolling list; see the flag's doc.
        insideScrollable: true,
      ),
    ),
  );
}
