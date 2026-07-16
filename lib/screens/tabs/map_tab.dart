import 'package:flutter/material.dart';

import '../../game/duel_launcher.dart';
import '../../game/element_style.dart';
import '../../game/game_state.dart';
import '../../game/world.dart';
import '../../ui/app_theme.dart';
import '../home_shell.dart';

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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
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
          subtitle: 'Fight ${World.opponentNameFor(here)} '
              '(Lv ${here.minLevel}-${here.maxLevel})',
          onTap: () => launchDuel(
            context,
            loadout: game.profile.activePreset.toLoadout(),
            campaign: true,
            enemyName: World.opponentNameFor(here),
          ),
        ),
    ];
  }

  void _comingSoon(BuildContext context, String what) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('$what is coming soon',
            style: const TextStyle(color: AppColors.text, fontSize: 17)),
        content: const Text(
            'Shops arrive with the item and crafting update (Phase 2).',
            style: TextStyle(color: AppColors.textDim)),
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
              Text(location.name,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.borderDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_kindLabel(location.kind),
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(location.blurb,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
          if (location.elements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Text('Monsters: ',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
              for (final e in location.elements)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(e.style.icon, size: 15, color: e.style.color),
                ),
            ]),
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
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 12)),
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
    final subtitle = location.isTown
        ? 'Town'
        : 'Lv ${location.minLevel}-${location.maxLevel}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        onTap: onTravel,
        child: Row(
          children: [
            Icon(_kindIcon(location.kind),
                color: AppColors.teal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.name,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 12)),
                ],
              ),
            ),
            const Row(
              children: [
                Text('Travel',
                    style: TextStyle(color: AppColors.teal, fontSize: 12)),
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
