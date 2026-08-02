import 'package:flutter/material.dart';

import '../../game/ai_personas.dart';
import '../../game/duel_launcher.dart';
import '../../game/element_style.dart';
import '../../game/game_state.dart';
import '../../game/travel.dart';
import '../../game/adventure.dart';
import '../../game/adventure_launcher.dart';
import '../../game/enemies/bestiary.dart';
import '../../game/world.dart';
import '../../ui/app_theme.dart';
import '../../ui/travel_progress_card.dart';
import '../home_shell.dart';
import '../world_map_screen.dart';

/// Where the player is in the world, what they can do here, and where they can
/// travel next. Adventures (a duel encounter in Phase 1) launch from here.
class MapTab extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  const MapTab({super.key, required this.onSelectTab});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
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
              // ⭐ The map scrolls with the page, and still pans under your
              // finger — see InteractiveWorldMap.insideScrollable.
              LayoutBuilder(
                builder: (context, c) => SizedBox(
                  // ⚠️ Capped by the screen, not just square. A full-width
                  // square map ate over half a phone screen and pushed every
                  // travel option below the fold.
                  height: c.maxWidth.clamp(0.0, 320.0),
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
              const SizedBox(height: 12),
              // The journey in progress, when there is one.
              if (game.isTravelling) TravelProgressCard(game: game),
              _CurrentLocationCard(location: here),
              const SizedBox(height: 12),
              const SectionLabel('Here you can'),
              ..._locationActions(context, game),
              const SizedBox(height: 14),
              const SectionLabel('Travel to'),
              for (final id in here.connections)
                _TravelCard(
                  location: World.byId(id),
                  // ⚠️ One journey at a time. While travelling the cards stay
                  // visible but inert, so the map still reads as a map rather
                  // than emptying out mid-trip.
                  minutes: Travel.minutesBetween(here.id, id),
                  enabled: !game.isTravelling,
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
          onTap: () => widget.onSelectTab(3),
        ),
      ],
      if (here.hasAdventure)
        // ⭐ A real run through the zone's roster, not a single stand-in duel.
        // ⚠️ Only Whispering Woods has a bestiary; everywhere else still falls
        // back to the one-off fight until its roster is built.
        if (Bestiary.forZone(here.id).isNotEmpty)
          _ActionTile(
            icon: Icons.local_fire_department,
            color: AppColors.ember,
            title: 'Begin adventure',
            subtitle: _runSubtitle(here),
            onTap: () => launchAdventure(context, here),
          )
        else
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
              // ⚠️ Flexible: a long place name beside its kind chip overflowed
              // the row on a narrow phone. "The Collapsed Academy" is 21
              // characters and there are three more like it.
              Flexible(
                child: Text(
                  location.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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

  /// How long the walk takes, shown so the cost of a trip is visible before
  /// committing to it rather than discovered afterwards.
  final int? minutes;
  final bool enabled;
  const _TravelCard({
    required this.location,
    required this.onTravel,
    this.minutes,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // ⚠️ Reads GameLocation.enemyBandLabel rather than assembling its own.
    // A bare "Lv 58-60" here contradicted the place sheet and reads as a
    // requirement — "come back at 58" — so players never return (§5).
    final subtitle = location.isTown ? 'Town' : location.enemyBandLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GamePanel(
          onTap: enabled ? onTravel : null,
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
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                      ),
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
              Row(
                children: [
                  Text(
                    minutes == null ? 'Travel' : '$minutes min',
                    style: const TextStyle(color: AppColors.teal, fontSize: 12),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, color: AppColors.teal),
                ],
              ),
            ],
          ),
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

/// ⭐ Shows the run's length up front (GAME_DESIGN world structure) — the
/// player should know what they are committing to before they commit.
String _runSubtitle(GameLocation zone) {
  final perSection = commonsPerSectionFor(zone.tier);
  final total = perSection * 3 + 3;
  return '$total encounters · ${zone.enemyBandLabel}';
}
