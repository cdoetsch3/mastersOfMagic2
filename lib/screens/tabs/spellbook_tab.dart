import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../../game/element_style.dart';
import '../../game/game_state.dart';
import '../../game/player_profile.dart';
import '../../game/progression.dart';
import '../../ui/app_theme.dart';
import '../element_detail_dialog.dart';
import '../gameplay_guide_screen.dart';
import '../home_shell.dart';
import '../spell_detail_dialog.dart';

const _spellKeyLabels = 'QWERTASDFG';

/// Manage the spell collection and loadout presets. Editing is gated to towns
/// (1-player design rule); presets and spells unlock as the player levels.
class SpellbookTab extends StatelessWidget {
  const SpellbookTab({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final p = game.profile;
    final canEdit = game.canEditLoadoutHere;
    final preset = p.activePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Spellbook'),
        if (!canEdit) _lockBanner(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            children: [
              _presetChips(context, game, p),
              const SizedBox(height: 12),
              _EditableName(preset: preset, canEdit: canEdit, game: game),
              const SizedBox(height: 10),
              _guideLink(context),
              const SizedBox(height: 12),
              SectionLabel('Elements  ·  ${preset.elementIds.length}/'
                  '${Progression.startingElementSlots}   (tap ⓘ for details)'),
              _elementGrid(context, game, p, preset, canEdit),
              const SizedBox(height: 14),
              SectionLabel('Spells  ·  ${preset.spellIds.length}/'
                  '${Progression.startingSpellSlots}   (tap ⓘ for details)'),
              _spellGrid(context, game, p, preset, canEdit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guideLink(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GameplayGuideScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.panelHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.school, size: 18, color: AppColors.gold),
            SizedBox(width: 10),
            Expanded(
              child: Text('How dueling works',
                  style: TextStyle(color: AppColors.text, fontSize: 14)),
            ),
            Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }

  Widget _lockBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ember),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock, color: AppColors.ember, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
                'Travel to a town and visit the Arcane Sanctum to edit '
                'your loadout.',
                style: TextStyle(color: AppColors.text, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _presetChips(BuildContext context, GameState game, PlayerProfile p) {
    final chips = <Widget>[];
    for (var i = 0; i < p.presets.length; i++) {
      final active = i == p.activePresetIndex;
      chips.add(GestureDetector(
        onTap: () => game.selectPreset(i),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.gold.withValues(alpha: 0.16) : AppColors.panelHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? AppColors.gold : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book,
                  size: 14,
                  color: active ? AppColors.gold : AppColors.textDim),
              const SizedBox(width: 6),
              Text(p.presets[i].name,
                  style: TextStyle(
                      color: active ? AppColors.text : AppColors.textDim,
                      fontSize: 13)),
            ],
          ),
        ),
      ));
    }
    // Locked future preset slots.
    final total = Progression.presetSlotUnlockLevels.length;
    for (var i = p.presets.length; i < total; i++) {
      final unlockLevel = Progression.presetSlotUnlockLevels[i];
      final unlocked = p.level >= unlockLevel;
      chips.add(GestureDetector(
        onTap: unlocked ? game.addPresetSlot : null,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.panelHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDim),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(unlocked ? Icons.add : Icons.lock,
                  size: 14, color: AppColors.textFaint),
              const SizedBox(width: 6),
              Text(unlocked ? 'Add loadout' : 'Lv $unlockLevel',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 13)),
            ],
          ),
        ),
      ));
    }
    return SizedBox(
      height: 40,
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
    );
  }

  Widget _elementGrid(BuildContext context, GameState game, PlayerProfile p,
      LoadoutPreset preset, bool canEdit) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final element in MagicElement.values)
          _elementTile(context, game, p, preset, element, canEdit),
      ],
    );
  }

  Widget _elementTile(BuildContext context, GameState game, PlayerProfile p,
      LoadoutPreset preset, MagicElement element, bool canEdit) {
    final style = element.style;
    final slot = preset.elementIds.indexOf(element.name);
    final selected = slot >= 0;
    final unlocked = p.isElementUnlocked(element);
    void toggle() {
      if (!canEdit || !unlocked) return;
      final ids = List.of(preset.elementIds);
      if (selected) {
        if (ids.length <= 1) return; // keep at least one
        ids.remove(element.name);
      } else if (ids.length < Progression.startingElementSlots) {
        ids.add(element.name);
      }
      game.savePreset(p.activePresetIndex,
          LoadoutPreset(name: preset.name, elementIds: ids, spellIds: preset.spellIds));
    }

    return Opacity(
      opacity: unlocked ? (canEdit || selected ? 1 : 0.7) : 0.35,
      child: Stack(
        children: [
          GestureDetector(
            onTap: toggle,
            child: Container(
              width: 104,
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              decoration: BoxDecoration(
                color: selected
                    ? style.color.withValues(alpha: 0.18)
                    : AppColors.panelHi,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? style.color : AppColors.border,
                    width: selected ? 1.6 : 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(style.icon, size: 18, color: style.color),
                      const SizedBox(width: 6),
                      Text(style.label,
                          style: TextStyle(
                              color: selected
                                  ? AppColors.text
                                  : AppColors.textDim,
                              fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(selected ? 'Slot ${slot + 1}' : '—',
                      style: TextStyle(
                          color:
                              selected ? style.color : AppColors.textFaint,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _infoDot(() => showElementDetail(context, element)),
          ),
        ],
      ),
    );
  }

  /// A small tappable ⓘ affordance used on element and spell tiles.
  Widget _infoDot(VoidCallback onTap) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.info_outline, size: 15, color: AppColors.textFaint),
      ),
    );
  }

  Widget _spellGrid(BuildContext context, GameState game, PlayerProfile p,
      LoadoutPreset preset, bool canEdit) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Fixed tile height and a max width per tile: tiles stay compact on
      // any screen instead of scaling with viewport width.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 235,
        mainAxisExtent: 56,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      children: [
        for (final spell in Spellbook.all)
          _spellTile(context, game, p, preset, spell, canEdit),
      ],
    );
  }

  Widget _spellTile(BuildContext context, GameState game, PlayerProfile p,
      LoadoutPreset preset, Spell spell, bool canEdit) {
    final slot = preset.spellIds.indexOf(spell.id);
    final selected = slot >= 0;
    final unlocked = p.isSpellUnlocked(spell);
    final unlockLevel = Progression.unlockLevelOf(spell);
    void toggle() {
      if (!canEdit || !unlocked) return;
      final ids = List.of(preset.spellIds);
      if (selected) {
        if (ids.length <= 1) return;
        ids.remove(spell.id);
      } else if (ids.length < Progression.startingSpellSlots) {
        ids.add(spell.id);
      }
      game.savePreset(p.activePresetIndex,
          LoadoutPreset(name: preset.name, elementIds: preset.elementIds, spellIds: ids));
    }

    return Tooltip(
      message: unlocked
          ? spellTooltip(spell)
          : '${spell.name} — unlocks at level $unlockLevel',
      waitDuration: const Duration(milliseconds: 350),
      child: Opacity(
        opacity: unlocked ? (canEdit || selected ? 1 : 0.75) : 0.4,
        child: GestureDetector(
          onTap: toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF2B2150)
                  : AppColors.panelHi,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: selected ? AppColors.gold : AppColors.border,
                  width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                    unlocked
                        ? (spellIcons[spell.id] ?? Icons.auto_fix_high)
                        : Icons.lock,
                    size: 18,
                    color: selected ? AppColors.gold : AppColors.textDim),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spell.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: unlocked
                                  ? AppColors.text
                                  : AppColors.textFaint,
                              fontSize: 12.5)),
                      Text(
                          unlocked
                              ? (spell.xCost
                                  ? 'cost X'
                                  : 'cost ${spell.chargeCost}')
                              : 'Level $unlockLevel',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 10)),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                        slot < _spellKeyLabels.length
                            ? _spellKeyLabels[slot]
                            : '•',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                if (unlocked)
                  _infoDot(() => showSpellDetail(context, spell)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableName extends StatelessWidget {
  final LoadoutPreset preset;
  final bool canEdit;
  final GameState game;
  const _EditableName(
      {required this.preset, required this.canEdit, required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(preset.name,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.textDim),
            onPressed: () => _rename(context),
          ),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: preset.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Rename loadout',
            style: TextStyle(color: AppColors.text, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'Loadout name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      game.savePreset(
          game.profile.activePresetIndex,
          LoadoutPreset(
              name: name.trim(),
              elementIds: preset.elementIds,
              spellIds: preset.spellIds));
    }
  }
}
