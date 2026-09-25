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
import '../../game/gates.dart';
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
        const PlayerHeader(),
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
              _CurrentLocationCard(
                location: here,
                gateOpen: game.profile.openedGates.contains(here.id),
              ),
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
                  // ⭐ A shut gate is walkable (ruling 2026-09-25, mockup B):
                  // the trip arrives at the gate screen, where the guard asks.
                  gateOpen: game.profile.openedGates.contains(id),
                  // ⚠️ The passage rule's answer is on the card already, so
                  // the card is dead rather than live-with-a-banner.
                  passageRefusal: game.passageRefusal(id),
                  cleared: game.profile.hasCleared(id),
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

  /// Travel, and say why not when the road says no. Same reasoning as
  /// [_shopClosed]: a refused tap that reports nothing reads as a bug.
  Future<void> _travel(BuildContext context, GameState game, String id) async {
    final banner = appBannerOf(context);
    final refusal = await game.travelTo(id);
    if (refusal != null) banner.show(refusal, color: AppColors.ember);
  }
}

class _CurrentLocationCard extends StatelessWidget {
  final GameLocation location;

  /// Whether this character has opened [location]'s gate — the lock line is
  /// dropped once it has: you are standing on the far side of it.
  final bool gateOpen;
  const _CurrentLocationCard({required this.location, this.gateOpen = false});

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
          if (location.gate != null && !gateOpen) ...[
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

  /// Whether this character has opened the destination's gate
  /// (`PlayerProfile.openedGates`). Passed in rather than read here so the
  /// card stays a pure function of what it is handed.
  ///
  /// ⭐ **Open means gone** (ruling 2026-09-25): an opened gate drops its tag
  /// entirely — the road is simply a road now.
  final bool gateOpen;

  /// `GameState.passageRefusal` for this destination — null when the road is
  /// walkable. Non-null **disables** the card and prints the sentence on it.
  final String? passageRefusal;

  /// Whether this character has beaten the destination's boss
  /// (`PlayerProfile.hasCleared`) — drawn as the green [_ClearedTag].
  final bool cleared;
  const _TravelCard({
    required this.location,
    required this.onTravel,
    this.travelLabel,
    this.enabled = true,
    this.gateOpen = false,
    this.passageRefusal,
    this.cleared = false,
  });

  /// Whether the card can be pressed: not mid-journey, and not walled off by
  /// the passage rule.
  bool get _live => enabled && passageRefusal == null;

  /// Whether the gate tag is drawn: a gate line, not yet opened.
  bool get _showGate => location.gate != null && !gateOpen;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Reads GameLocation.enemyBandLabel rather than assembling its own.
    // A bare "Lv 58-60" here contradicted the place sheet and reads as a
    // requirement — "come back at 58" — so players never return (§5).
    final subtitle = location.isTown ? 'Town' : location.enemyBandLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: _live ? 1 : 0.45,
        child: GamePanel(
          onTap: _live ? onTravel : null,
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
                    // 📝 Ruling 2026-09-25: a clearer 'Cleared' mark, ahead of
                    // the level band. ⭐ The cell is reserved on every zone
                    // card, cleared or not, so the band sits at one x and
                    // the card does not reflow the day the boss falls. A
                    // town is never cleared, so it keeps its plain 'Town'.
                    if (location.isTown)
                      Text(subtitle, style: _subtitleStyle)
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: _ClearedTag.widthOf(context),
                            child: cleared ? const _ClearedTag() : null,
                          ),
                          Flexible(
                            child: Text(subtitle, style: _subtitleStyle),
                          ),
                        ],
                      ),
                    // What the new world model knows and this card used to hide:
                    // who you'll meet, what is taught here, and what bars the way.
                    if (location.elements.isNotEmpty ||
                        location.station != null ||
                        _showGate ||
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
                            if (_showGate)
                              _GateTag(label: Gates.shutTagFor(location)),
                          ],
                        ),
                      ),
                    // ⭐ The reason, on the card, in full. The passage rule is
                    // the one refusal a player cannot work out by looking —
                    // "you have not cleared the Old Quarry" is a fact about
                    // the road BEHIND this tile, so a chip reading "Blocked"
                    // would be the question rather than the answer.
                    if (passageRefusal != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          passageRefusal!,
                          style: const TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    travelLabel ?? 'Travel',
                    style: TextStyle(
                      // ⚠️ Recoloured, not removed. The walk still costs what
                      // it costs, and dropping the label would make a blocked
                      // road look like a road with no length.
                      color: _live ? AppColors.teal : AppColors.textFaint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    color: _live ? AppColors.teal : AppColors.textFaint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const TextStyle _subtitleStyle = TextStyle(
  color: AppColors.textDim,
  fontSize: 12,
);

/// The green check on a travel card whose boss this character has beaten.
///
/// ⚠️ Its width is **measured, not a constant**: the obvious `width: 80`
/// was right under Roboto and forty pixels short under the test font, where
/// every glyph is a square. A number read off one font is wrong in another
/// (and wrong again at 200% text scale). ⚠️ Resolved through
/// `DefaultTextStyle`, exactly as `Text` resolves its own — a bare
/// `TextStyle` drops the theme's family and comes up about two pixels short.
class _ClearedTag extends StatelessWidget {
  const _ClearedTag();

  static const String label = 'Cleared';
  static const double _iconSize = 14;
  static const double _gap = 3;

  /// The space after the word, before the level band.
  static const double _trail = 8;
  static const TextStyle _style = TextStyle(
    color: AppColors.green,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// The cell's fixed width — the same whether or not the tag is drawn in it.
  static double widthOf(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(_style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return _iconSize + _gap + painter.width + _trail + 1;
  }

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle, size: _iconSize, color: AppColors.green),
      SizedBox(width: _gap),
      Text(label, style: _style),
    ],
  );
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

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: _iconSize, color: color),
      const SizedBox(width: _gap),
      // ⚠️ Flexible: the Pennycross gate tag is a sentence, and on a phone a
      // sentence in one unbreakable run overflows the card. Where the tag
      // fits (every other one) this changes nothing.
      Flexible(
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: _fontSize),
        ),
      ),
    ],
  );
}

/// The lock on a travel card whose gate is still shut.
///
/// ⭐ **Shut only, since 2026-09-25.** The 'Gate open' state is gone — an
/// opened gate drops the tag altogether (the road is just a road) — so the
/// cell no longer has two widths to reconcile, and the old fixed-width cell
/// went with it. ⚠️ Press-stability still holds: the tag only ever vanishes
/// on the gate screen, never under a finger on this card.
///
/// The words are the gate's own ([Gates.shutTagFor]): Pennycross's
/// 'Gated · show three proofs at the gate', and a bare 'Gated' for a gate
/// with no ruled copy or no items behind it yet.
class _GateTag extends StatelessWidget {
  final String label;
  const _GateTag({required this.label});

  @override
  Widget build(BuildContext context) =>
      _MiniTag(icon: Icons.lock_outline, text: label, color: AppColors.gold);
}

/// ⭐ Shows the run's length up front (GAME_DESIGN world structure) — the
/// player should know what they are committing to before they commit.
/// Exposed for the campaign-shape test; the map's own callers use the
/// private name.
@visibleForTesting
String mapRunSubtitleForTest(GameLocation zone) => _runSubtitle(zone);

String _runSubtitle(GameLocation zone) {
  // ⭐ The ruled shape (2026-09-25): 2 commons · mini · 2 · mini · 2 · boss —
  // nine fights — and the Citadel's boss slot is a SEQUENCE of two, so it is
  // the one zone at ten. Read from the same source the run rolls from.
  final bosses = Bestiary.bossSequenceFor(zone.id).length;
  final total = commonsPerSection * 3 + 2 + (bosses == 0 ? 1 : bosses);
  return '$total encounters · ${zone.enemyBandLabel}';
}
