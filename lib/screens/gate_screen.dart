import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/gates.dart';
import '../game/items/item_catalogue.dart';
import '../game/world.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import '../ui/item_icon.dart';
import 'achievements_screen.dart';

/// ⭐ **The arrival seam of the gate ruling** (Christian, 2026-09-25, mockup
/// B): the gate screen in place of [child] while the player stands at a shut
/// gate (`PlayerProfile.shutGateHere`), and [child] the rest of the time.
///
/// Wraps the **whole home shell**, not the Map tab. Standing at the gate is
/// standing outside the town — its merchant, storeroom and station are the
/// other side of the wall, and every tab reads "where you are" — so the tabs
/// are not reachable until the player unlocks or turns back.
///
/// ⭐ **Derived, so there is nothing to surface.** Arriving (the travel
/// ticker's `tick`, or a launch after the trip finished while the app was
/// closed) changes the profile, the scope notifies, and this rebuilds. No
/// flag on the profile to set on arrival and remember to clear.
///
/// ⚠️ A player whose gate is already open (`openedGates`) never sees the
/// screen — including everyone who opened Pennycross under the 2026-09-21
/// rule.
class GateCheckpoint extends StatelessWidget {
  final Widget child;

  const GateCheckpoint({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    // ⚠️ `isTravelling` settles an arrival that is due — read it FIRST, or a
    // trip that finished while the app was closed would still read as a trip.
    if (game.isTravelling) return child;
    final gate = game.profile.shutGateHere;
    return gate == null ? child : GateScreen(locationId: gate);
  }
}

/// The gate itself: the guard's line, the items he wants, and the two ways
/// off this screen — back the way you came, or through.
///
/// ⭐ **Unlock spends the items** (ruling 2026-09-25) — *"the proofs stay with
/// the guard"* — opens the gate for good and earns any achievement it
/// carries, all in `GameState.openGateAt`'s one write; the checkpoint above
/// then shows the town.
///
/// ⭐ **Press-stability.** Both buttons sit in one fixed bar at the bottom,
/// and nothing above them can change while this screen is up: the pack
/// cannot be edited from here, so the tiles are fixed for as long as the
/// buttons are on screen.
class GateScreen extends StatelessWidget {
  final String locationId;

  const GateScreen({super.key, required this.locationId});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final location = World.byId(locationId);
    final copy = Gates.forLocation(locationId);
    final pack = game.profile.backpack;
    // ⭐ The guard's own check, not a second copy of it: Unlock is live
    // exactly when `openGateAt` would say yes.
    final canUnlock = game.gateRefusal(locationId) == null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                    children: [
                      const Center(child: _GateGlyph()),
                      const SizedBox(height: 16),
                      Text(
                        Gates.titleFor(location),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ⚠️ Quoted only when it IS the guard speaking. A gate
                      // with no ruled copy falls back to its prose, which is
                      // a description, not a line of dialogue.
                      Text(
                        copy != null
                            ? '"${copy.guardLine}"'
                            : (location.gate ?? ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final id in location.gateItemIds)
                        GateItemTile(itemId: id, carried: pack.countOf(id) > 0),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _turnBack(game),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: const Text('Turn back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: canUnlock
                              ? () => _unlock(context, game)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.bg,
                            disabledBackgroundColor: AppColors.borderDim,
                            disabledForegroundColor: AppColors.textFaint,
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: const Text('Unlock'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ⭐ Back the way you came — `PlayerProfile.gateTurnBackId`, which
  /// `passageRefusal` (c) never refuses: it IS the road just walked.
  Future<void> _turnBack(GameState game) =>
      game.beginTravel(game.profile.gateTurnBackId);

  Future<void> _unlock(BuildContext context, GameState game) async {
    // ⚠️ Captured before the await: a successful unlock replaces this whole
    // screen with the town, and this context goes with it.
    final banner = appBannerOf(context);
    final achievement = Gates.achievementFor(locationId);
    final hadIt =
        achievement != null &&
        game.profile.achievements.contains(achievement.id);
    final opened = await game.openGateAt(locationId);
    if (opened && achievement != null && !hadIt) {
      announceAchievement(banner, achievement);
    }
  }
}

/// The gate glyph — the travel card's lock, large, in a gold ring.
class _GateGlyph extends StatelessWidget {
  const _GateGlyph();

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.panel,
      border: Border.all(color: AppColors.gold, width: 2),
    ),
    child: const Icon(Icons.lock_outline, color: AppColors.gold, size: 34),
  );
}

/// One item the guard wants: its icon and name, then a green ✓ when it is in
/// the pack, or a dim line saying where it comes from when it is not.
///
/// ⚠️ **Carried means the backpack** — the guard's own rule
/// (`GameState.gateRefusal`); a proof in a storeroom is drawn as missing.
class GateItemTile extends StatelessWidget {
  final String itemId;
  final bool carried;

  const GateItemTile({super.key, required this.itemId, required this.carried});

  /// The dim line under a missing item. ⚠️ A gate item no boss drops (the
  /// crafted Celestial Totem) has no source to name, and says so plainly.
  static String missingLine(String itemId) =>
      Gates.sourceLineFor(itemId) ?? 'Not carried';

  @override
  Widget build(BuildContext context) {
    final def = ItemCatalogue.tryById(itemId);
    final name = def == null ? itemId : ItemCatalogue.displayName(def);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        color: AppColors.panel,
        borderColor: carried ? AppColors.green : AppColors.borderDim,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: ConstrainedBox(
          // ⭐ One height for both states, so three tiles in mixed states
          // still read as one column of equals.
          constraints: const BoxConstraints(minHeight: 36),
          child: Row(
            children: [
              ItemIcon(
                defId: itemId,
                size: 28,
                fallback: const SizedBox(
                  width: 28,
                  child: Icon(
                    Icons.workspace_premium,
                    size: 22,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: carried ? AppColors.text : AppColors.textDim,
                        fontSize: 14,
                      ),
                    ),
                    if (!carried)
                      Text(
                        missingLine(itemId),
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                child: carried
                    ? const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
