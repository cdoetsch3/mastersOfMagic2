import 'package:flutter/material.dart';

import '../../game/ai_personas.dart';
import '../../game/duel_launcher.dart';
import '../../game/element_style.dart';
import '../../game/game_state.dart';
import '../../game/world.dart';
import '../../ui/app_theme.dart';
import '../home_shell.dart';
import '../world_map_screen.dart';

/// Where the player is in the world, what they can do here, and where they can
/// travel next. Adventures (a duel encounter in Phase 1) launch from here.
class MapTab extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  const MapTab({super.key, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final here = game.profile.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Map'),
        // ⚠️ The map lives ABOVE the list, not inside it. A pannable map inside
        // a ListView cannot be panned vertically at all: the list's drag
        // recognizer wins the gesture arena every time, so a drag south
        // scrolled the page and left the map exactly where it was. Measured —
        // the map's transform did not move by a single pixel.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Center(
            child: ConstrainedBox(
              // A square, unless that would eat the screen on a short window.
              constraints: const BoxConstraints(maxHeight: 340),
              child: WorldMapCard(
                game: game,
                onExpand: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorldMapScreen(game: game),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            children: [
              _CurrentLocationCard(location: here),
              const SizedBox(height: 12),
              const SectionLabel('Here you can'),
              ..._locationActions(context, game),
              const SizedBox(height: 14),
              const SectionLabel('Travel to'),
              for (final id in here.connections)
                _TravelCard(
                  location: World.byId(id),
                  onTravel: () => game.travelTo(id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _locationActions(BuildContext context, GameState game) {
    final here = game.profile.location;
    return [
      if (here.isTown) ...[
        _ActionTile(
          icon: Icons.store,
          color: AppColors.gold,
          title: 'Merchant',
          subtitle: 'Buy and sell goods',
          onTap: () => _comingSoon(context, 'The merchant'),
        ),
        _ActionTile(
          icon: Icons.auto_stories,
          color: AppColors.sky,
          title: 'Arcane Sanctum',
          subtitle: 'Change your spells and loadouts',
          onTap: () => onSelectTab(3),
        ),
      ],
      if (here.hasAdventure)
        _ActionTile(
          icon: Icons.local_fire_department,
          color: AppColors.ember,
          title: 'Begin adventure',
          subtitle:
              'Fight ${World.opponentNameFor(here)} '
              '(${here.enemyBandLabel})',
          onTap: () => launchAiDuel(
            context,
            loadout: game.profile.activePreset.toLoadout(),
            campaign: true,
            persona: AiRoster.campaignFoe(
              name: World.opponentNameFor(here),
              level: (here.minLevel + here.maxLevel) ~/ 2,
            ),
          ),
        ),
    ];
  }

  void _comingSoon(BuildContext context, String what) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(
          '$what is coming soon',
          style: const TextStyle(color: AppColors.text, fontSize: 17),
        ),
        content: const Text(
          'Shops arrive with the item and crafting update (Phase 2).',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  final GameLocation location;
  const _CurrentLocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      color: AppColors.panel,
      borderColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_kindIcon(location.kind), color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                location.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.borderDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _kindLabel(location.kind),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            location.blurb,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          if (location.hasAdventure) ...[
            const SizedBox(height: 6),
            Text(
              location.enemyBandLabel,
              style: const TextStyle(color: AppColors.ember, fontSize: 12),
            ),
          ],
          if (location.station != null ||
              location.plane == WorldPlane.empyrean) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (location.station != null)
                  _MiniTag(
                    icon: Icons.handyman,
                    text: location.station!,
                    color: AppColors.teal,
                  ),
                if (location.plane == WorldPlane.empyrean)
                  const _MiniTag(
                    icon: Icons.auto_awesome,
                    text: 'Beyond the Veil',
                    color: AppColors.gem,
                  ),
              ],
            ),
          ],
          if (location.gate != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location.gate!,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (location.elements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Monsters: ',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 12),
                ),
                for (final e in location.elements)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: elementGlyph(e, size: 15),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _TravelCard extends StatelessWidget {
  final GameLocation location;
  final VoidCallback onTravel;
  const _TravelCard({required this.location, required this.onTravel});

  @override
  Widget build(BuildContext context) {
    // ⚠️ Reads GameLocation.enemyBandLabel rather than assembling its own.
    // A bare "Lv 58-60" here contradicted the place sheet and reads as a
    // requirement — "come back at 58" — so players never return (§5).
    final subtitle = location.isTown ? 'Town' : location.enemyBandLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        onTap: onTravel,
        child: Row(
          children: [
            Icon(_kindIcon(location.kind), color: AppColors.teal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                  // What the new world model knows and this card used to hide:
                  // who you'll meet, what is taught here, and what bars the way.
                  if (location.elements.isNotEmpty ||
                      location.station != null ||
                      location.gate != null ||
                      location.plane == WorldPlane.empyrean)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final e in location.elements)
                            elementGlyph(e, size: 14),
                          if (location.station != null)
                            _MiniTag(
                              icon: Icons.handyman,
                              text: location.station!,
                              color: AppColors.teal,
                            ),
                          if (location.plane == WorldPlane.empyrean)
                            const _MiniTag(
                              icon: Icons.auto_awesome,
                              text: 'Beyond the Veil',
                              color: AppColors.gem,
                            ),
                          if (location.gate != null)
                            const _MiniTag(
                              icon: Icons.lock_outline,
                              text: 'Gated',
                              color: AppColors.gold,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Row(
              children: [
                Text(
                  'Travel',
                  style: TextStyle(color: AppColors.teal, fontSize: 12),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, color: AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _kindIcon(LocationKind kind) => switch (kind) {
  LocationKind.town => Icons.location_city,
  LocationKind.route => Icons.route,
  LocationKind.dungeon => Icons.dark_mode,
};

String _kindLabel(LocationKind kind) => switch (kind) {
  LocationKind.town => 'Town',
  LocationKind.route => 'Route',
  LocationKind.dungeon => 'Dungeon',
};

/// A small labelled fact on a location card — station, plane, gate.
class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MiniTag({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontSize: 11.5)),
    ],
  );
}
