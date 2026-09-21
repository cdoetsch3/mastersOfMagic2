import 'package:flutter/material.dart';

import '../../game/ai_personas.dart';
import '../../game/duel_launcher.dart';
import '../../game/element_style.dart';
import '../../game/game_state.dart';
import '../../game/travel.dart';
import '../../game/adventure.dart';
import '../../game/adventure_launcher.dart';
import '../../game/economy/shop_catalogue.dart';
import '../../game/enemies/bestiary.dart';
import '../../game/world.dart';
import '../../ui/app_banner.dart';
import '../../ui/app_theme.dart';
import '../../ui/travel_progress_card.dart';
import '../home_shell.dart';
import '../shop_screen.dart';
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
                  travelLabel: Travel.labelBetween(here.id, id),
                  enabled: !game.isTravelling,
                  // ⭐ Still tappable while the gate is shut. The refusal
                  // names the proof you are short of, which is information;
                  // a dead tile is not.
                  gateRefusal: game.gateRefusal(id),
                  onTravel: () => _travel(context, game, id),
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
        // ⭐ The Phase-2 placeholder finally pays off: open towns go to the
        // real shop (ECONOMY_CONTRACT); closed towns say why they cannot
        // (§14b.2), which beats a coming-soon dialog that is no longer true.
        if (ShopCatalogue.isOpen(here.id))
          _ActionTile(
            icon: Icons.store,
            color: AppColors.gold,
            title: 'Merchant',
            subtitle: 'Buy and sell goods',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ShopScreen(townId: here.id),
              ),
            ),
          )
        else
          _ActionTile(
            icon: Icons.store,
            color: AppColors.gold,
            title: 'Merchant',
            subtitle: ShopCatalogue.closedFlavor,
            onTap: () => _shopClosed(context),
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

  /// ⭐ Banner: a tap on a closed shop's tile otherwise does nothing at all,
  /// which reads as a broken tile rather than a shut door.
  void _shopClosed(BuildContext context) =>
      showAppBanner(context, ShopCatalogue.closedFlavor);

  /// Travel, and say why not when the guard says no. Same reasoning as
  /// [_shopClosed]: a refused tap that reports nothing reads as a bug.
  Future<void> _travel(BuildContext context, GameState game, String id) async {
    final banner = appBannerOf(context);
    final refusal = await game.travelTo(id);
    if (refusal != null) banner.show(refusal, color: AppColors.ember);
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
  final String? travelLabel;
  final bool enabled;

  /// `GameState.gateRefusal` for this destination — null when the way is open
  /// (or when the gate is prose only). Passed in rather than read here so the
  /// card stays a pure function of what it is handed.
  final String? gateRefusal;
  const _TravelCard({
    required this.location,
    required this.onTravel,
    this.travelLabel,
    this.enabled = true,
    this.gateRefusal,
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
                              _GateTag(
                                open:
                                    location.gateItemIds.isNotEmpty &&
                                    gateRefusal == null,
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
                    travelLabel ?? 'Travel',
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

  static const double _iconSize = 12;
  static const double _gap = 4;
  static const double _fontSize = 11.5;

  /// How wide this tag would be if it sized itself to [text].
  ///
  /// ⚠️ **Measured, not a constant.** The obvious `width: 80` was right under
  /// Roboto and forty pixels short under the test font, where every glyph is
  /// a square — so the widget looked fine and every widget test overflowed.
  /// A number read off one font is a number that is wrong in another (and
  /// wrong again at 200% text scale).
  ///
  /// ⚠️ **Resolved through `DefaultTextStyle`, exactly as `Text` resolves its
  /// own.** Measuring a bare `TextStyle(fontSize: …)` drops the theme's font
  /// family and comes up about two pixels short — invisible by eye, an
  /// overflow assertion in a widget test.
  static double widthOf(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(
          context,
        ).style.merge(const TextStyle(fontSize: _fontSize)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    // The spare pixel keeps a rounded-up glyph run off the overflow stripes.
    return _iconSize + _gap + painter.width + 1;
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: _iconSize, color: color),
      const SizedBox(width: _gap),
      Text(
        text,
        style: TextStyle(color: color, fontSize: _fontSize),
      ),
    ],
  );
}

/// The lock on a travel card: shut, or opened for good.
///
/// ⭐ **One fixed-width cell for both states.** "Gate open" is wider than
/// "Gated", and this tag sits in a `Wrap` beside the station and element
/// glyphs — so letting it size itself would shuffle its neighbours the instant
/// the gate opened, under a finger that is already on its way down. The width
/// is set by the longer word and never changes (press-stability).
///
/// ⚠️ Only reached when `location.gate != null`. A gate with no items behind
/// it (the four still-unbuilt ones) is always [open] `false` — prose that
/// describes a lock nothing checks yet.
class _GateTag extends StatelessWidget {
  final bool open;
  const _GateTag({required this.open});

  /// The longer of the two labels, and therefore the one that sets the cell.
  static const String openLabel = 'Gate open';
  static const String shutLabel = 'Gated';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _MiniTag.widthOf(context, openLabel),
    child: _MiniTag(
      icon: open ? Icons.lock_open : Icons.lock_outline,
      text: open ? openLabel : shutLabel,
      color: open ? AppColors.teal : AppColors.gold,
    ),
  );
}

/// ⭐ Shows the run's length up front (GAME_DESIGN world structure) — the
/// player should know what they are committing to before they commit.
String _runSubtitle(GameLocation zone) {
  final perSection = commonsPerSectionFor(zone.tier);
  final total = perSection * 3 + 3;
  return '$total encounters · ${zone.enemyBandLabel}';
}
