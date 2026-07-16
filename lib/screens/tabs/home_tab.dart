import 'package:flutter/material.dart';

import '../../game/duel_launcher.dart';
import '../../game/game_state.dart';
import '../../game/player_profile.dart';
import '../../ui/app_theme.dart';
import '../home_shell.dart';

/// Center dashboard: progress, quests, the PvP entry point, and shortcuts
/// into the rest of the app. The engagement hub.
class HomeTab extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  const HomeTab({super.key, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final p = game.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Home'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            children: [
              _XpCard(p: p),
              const SizedBox(height: 14),
              const SectionLabel('Today'),
              const _QuestCard(
                icon: Icons.wb_sunny,
                title: 'Win 3 duels',
                subtitle: 'Daily quest · reward 50 gold',
                progress: '0 / 3',
              ),
              const SizedBox(height: 8),
              const _QuestCard(
                icon: Icons.school,
                title: 'Reach level 3',
                subtitle: 'Weekly quest · unlocks a 2nd loadout',
                progress: 'in progress',
              ),
              const SizedBox(height: 14),
              const SectionLabel('Continue'),
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
                          Text('You are at ${p.location.name}',
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 14)),
                          const Text('Open the map to travel or adventure',
                              style: TextStyle(
                                  color: AppColors.textDim, fontSize: 12)),
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
                          Text('Active loadout: ${p.activePreset.name}',
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 14)),
                          const Text('Manage spells and presets',
                              style: TextStyle(
                                  color: AppColors.textDim, fontSize: 12)),
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
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: _FindDuelButton(),
        ),
      ],
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
              Text('Level ${p.level}',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${p.xpIntoLevel} / ${p.xpForThisLevel} XP',
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 12)),
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
          const SizedBox(height: 6),
          Text('${p.duelsWon}W · ${p.duelsLost}L',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Find a duel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        onPressed: () => _startPvpDuel(context),
      ),
    );
  }

  Future<void> _startPvpDuel(BuildContext context) async {
    final game = GameStateScope.read(context);
    final index = await showPresetPicker(context);
    if (index == null || !context.mounted) return;
    final preset = game.profile.presets[index];
    await launchDuel(
      context,
      loadout: preset.toLoadout(),
      campaign: false,
      enemyName: 'Procarius',
    );
  }
}

class _QuestCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String progress;
  const _QuestCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
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
          Text(progress,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
        ],
      ),
    );
  }
}

/// A bottom sheet that lets the player pick which loadout preset to duel with
/// (PvP rule: choose a loadout before each match). Returns the chosen index.
Future<int?> showPresetPicker(BuildContext context) {
  final game = GameStateScope.read(context);
  final p = game.profile;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your loadout',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (var i = 0; i < p.presets.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GamePanel(
                  onTap: () => Navigator.of(context).pop(i),
                  borderColor: i == p.activePresetIndex
                      ? AppColors.gold
                      : AppColors.border,
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book,
                          color: AppColors.sky, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.presets[i].name,
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 14)),
                            Text(
                                '${p.presets[i].elementIds.length} elements · '
                                '${p.presets[i].spellIds.length} spells',
                                style: const TextStyle(
                                    color: AppColors.textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (i == p.activePresetIndex)
                        const Text('active',
                            style: TextStyle(
                                color: AppColors.gold, fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
