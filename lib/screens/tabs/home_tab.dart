import 'package:flutter/material.dart';

import '../../game/adventure.dart';
import '../../game/game_state.dart';
import '../../game/player_profile.dart';
import '../../game/world.dart';
import '../../ui/app_theme.dart';
import '../adventure_screen.dart';
import '../home_shell.dart';
import '../matchmaking_screen.dart';

/// Center dashboard: progress, the PvP entry point, and shortcuts into the
/// rest of the app. The engagement hub.
///
/// 📝 **No daily/weekly goals here** (ruling 2026-09-21). The 'Today' section
/// and its two placeholder cards ('Win 3 duels', 'Reach level 3') were
/// static props — nothing counted, nothing paid out — and the real feature
/// "will be implemented at a much later date". Removed rather than left
/// showing 0 / 3 forever; when goals return they return as a system, not as
/// two `const` widgets.
///
/// 📝 **No Skills card either** (ruling 2026-09-21). Skills moved into the
/// new Profile screen, which every tab reaches from the header's name pill —
/// a shortcut on one tab to a screen that belongs to the character was the
/// duplicate. 'Continue' keeps its label: the map and loadout cards (and a
/// resumable run) still sit under it.
class HomeTab extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  const HomeTab({super.key, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final p = game.profile;
    // ⭐ Only a run the player is still inside. A finished one lingers on the
    // profile until the next adventure overwrites it, and offering to "resume"
    // a corpse is worse than offering nothing.
    //
    // ⚠️ **A run holding an unanswered victory picker counts as inside**, even
    // when the boss is already down: force-quitting on the picker is the one
    // way loot can still be stranded (ruling 2026-08-17), and this is the door
    // back to it. Not a second kind of card — the same "you are mid-adventure"
    // fact, reached from a different second.
    final run = game.run;
    // ⭐ …and a cleared run whose boss node is still standing (ruled
    // 2026-09-25: the last node comes after the boss) — force-quitting on
    // that screen must not lose the harvest.
    final resumable =
        run != null &&
            ((!run.isOver && !run.isFinished) ||
                run.unclaimed.isNotEmpty ||
                run.currentNode != null)
        ? run
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            children: [
              _XpCard(p: p),
              const SizedBox(height: 14),
              const SectionLabel('Continue'),
              if (resumable != null) ...[
                _ResumeAdventureCard(run: resumable),
                const SizedBox(height: 8),
              ],
              GamePanel(
                onTap: () => onSelectTab(0),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are at ${p.location.name}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Open the map to travel or adventure',
                            style: TextStyle(
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
              const SizedBox(height: 8),
              GamePanel(
                onTap: () => onSelectTab(3),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppColors.sky),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active loadout: ${p.activePreset.name}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Manage spells and presets',
                            style: TextStyle(
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: _FindDuelButton(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: _AcademyButton(),
        ),
      ],
    );
  }
}

/// The Academy (academy.dart): the level playing field, open to guests. No
/// preset picker — the Academy has exactly one loadout, edited in the
/// Spellbook under its own chip.
class _AcademyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gem,
          side: const BorderSide(color: AppColors.gem),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.school, size: 20),
        label: const Text(
          'The Academy — level 50, no gear, open to all',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          final game = GameStateScope.read(context);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MatchmakingScreen(
                loadout: game.profile.academyPreset.toLoadout(),
                academy: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The way back into a run left half-finished.
///
/// ⚠️ Pushes the **existing** [AdventureScreen], which reads `game.run` for
/// itself — there is no second path into an adventure, and adding one is how
/// the two would drift. 📝 Deliberately plain; a human restyles this later.
class _ResumeAdventureCard extends StatelessWidget {
  final AdventureRun run;
  const _ResumeAdventureCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final zone = World.byId(run.zoneId);
    return GamePanel(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => AdventureScreen(zone: zone)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: AppColors.ember),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume adventure — ${zone.name}',
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                ),
                Text(
                  // ⚠️ A run whose line is walked out has no "encounter 10 of
                  // 9" to report — it is standing on its unanswered spoils, and
                  // saying so is the only honest subtitle.
                  run.isFinished || run.isOver
                      ? '${run.unclaimed.length} still to choose'
                      : 'Encounter ${run.encounterNumber} of '
                            '${run.encounterCount}',
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
    );
  }
}

class _XpCard extends StatelessWidget {
  final PlayerProfile p;
  const _XpCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final frac = p.xpForThisLevel == 0
        ? 0.0
        : (p.xpIntoLevel / p.xpForThisLevel).clamp(0.0, 1.0);
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Level ${p.level}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${p.xpIntoLevel} / ${p.xpForThisLevel} XP',
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.borderDim),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(height: 8, color: AppColors.gold),
                ),
              ],
            ),
          ),
          // 📝 Ruling 2026-09-25: no W/L line here — the record lives on the
          // Profile screen (its 'Record W–L' chip), one tap away on the pill.
          const SizedBox(height: 6),
          // ⭐ LADDER_DESIGN §8 item 6: a player's rating shows on the home
          // tab, not just the profile. ⚠️ Always rendered — even before this
          // character has a rating — so the card's height never shifts the
          // instant a first rated match lands (press-stability: nothing here
          // is a control, but the row above it still shouldn't jump).
          Text(
            'Ladder ${p.ratingGeared ?? '—'} · Academy ${p.ratingAcademy ?? '—'}',
            style: const TextStyle(
              color: AppColors.textFaint,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FindDuelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const WizardHatIcon(size: 22, color: AppColors.bg),
        label: const Text(
          'Find a duel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _startPvpDuel(context),
      ),
    );
  }

  Future<void> _startPvpDuel(BuildContext context) async {
    final game = GameStateScope.read(context);
    // PvP rule: pick your loadout before each match.
    final index = await showPresetPicker(context);
    if (index == null || !context.mounted) return;
    final preset = game.profile.presets[index];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchmakingScreen(loadout: preset.toLoadout()),
      ),
    );
  }
}

/// A centred dialog that lets the player pick which loadout preset to duel
/// with (PvP rule: choose a loadout before each match). Returns the chosen
/// index, or null when dismissed.
///
/// 📝 Ruling 2026-09-25: a dialog, not a bottom sheet. The sheet grew up from
/// the bottom edge, and in landscape its later presets were cut off below the
/// screen with nothing to say there were more. ⭐ The list scrolls inside a
/// box capped at 70% of the screen height, so every preset is reachable at
/// any size.
Future<int?> showPresetPicker(BuildContext context) {
  final game = GameStateScope.read(context);
  final p = game.profile;
  return showDialog<int>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.gold),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Choose your loadout',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // ⚠️ Flexible + shrinkWrap: a short list sizes the dialog to its
            // content, a long one fills the capped height and scrolls.
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: p.presets.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PresetRow(
                    preset: p.presets[i],
                    active: i == p.activePresetIndex,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One row of [showPresetPicker].
class _PresetRow extends StatelessWidget {
  final LoadoutPreset preset;
  final bool active;
  final VoidCallback onTap;
  const _PresetRow({
    required this.preset,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      onTap: onTap,
      borderColor: active ? AppColors.gold : AppColors.border,
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: AppColors.sky, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                ),
                Text(
                  '${preset.elementIds.length} elements · '
                  '${preset.spellIds.length} spells',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            const Text(
              'active',
              style: TextStyle(color: AppColors.gold, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
