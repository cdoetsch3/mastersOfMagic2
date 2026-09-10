import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../../game/academy.dart';
import '../../game/element_style.dart';
import '../../game/game_state.dart';
import '../../game/player_profile.dart';
import '../../game/progression.dart';
import '../../game/spell_browser.dart';
import '../../ui/app_theme.dart';
import '../../ui/charge_dots.dart';
import '../../ui/hover_card.dart';
import '../element_detail_dialog.dart';
import '../gameplay_guide_screen.dart';
import '../home_shell.dart';
import '../spell_detail_dialog.dart';

const _spellKeyLabels = 'QWERTASDFG';

/// Manage the spell collection and loadout presets. Editing is gated to towns
/// (1-player design rule); presets and spells unlock as the player levels.
///
/// ⭐ **The spell half is a browsable shelf, not a wall.** At rest the book
/// is grouped under its four lane headers (see [SpellKind]); the toolbar
/// sorts within those groups, and either filter flattens the sections into
/// one list. All of that reasoning lives in `game/spell_browser.dart` — this
/// file only paints it.
class SpellbookTab extends StatefulWidget {
  const SpellbookTab({super.key});

  @override
  State<SpellbookTab> createState() => _SpellbookTabState();
}

class _SpellbookTabState extends State<SpellbookTab> {
  /// ⚠️ Per-visit, plain fields, never persisted — the Shop's ruling for its
  /// own shelf controls. A filter that outlives the visit is a filter the
  /// player has to remember setting.
  SpellKind? _kind; // null = All
  var _cost = SpellCostFilter.any;
  // [H] Grouping is the PRIMARY axis (designer, 2026-08-29: "it's the
  // GROUPING that's important"); sort orders within each section.
  var _grouping = SpellGrouping.kind;
  var _sort = SpellSort.unlock;
  // [F] Name search. [C] Whether spells beyond the player's level show
  // (dimmed) or hide. Both per-visit, like the chips.
  var _query = '';
  var _showLocked = true;

  /// Editing the Academy loadout (academy.dart) instead of a preset: every
  /// spell and element is open whatever the player's level, editing is
  /// allowed anywhere, and the caps are the Academy's own. Per-visit.
  var _academy = false;

  int _level(PlayerProfile p) => _academy ? Academy.level : p.level;
  bool _spellUnlocked(PlayerProfile p, Spell s) =>
      _academy || p.isSpellUnlocked(s);
  bool _elementUnlocked(PlayerProfile p, MagicElement e) =>
      _academy || p.isElementUnlocked(e);
  int _spellBudget(PlayerProfile p) =>
      _academy ? Academy.spellSlots : Progression.usableSpellsAtLevel(p.level);
  int _elementBudget(PlayerProfile p) => _academy
      ? Academy.elementSlots
      : Progression.usableElementsAtLevel(p.level);

  bool get _filtering =>
      spellFilterActive(kind: _kind, cost: _cost, query: _query);

  /// [C] The book the shelf draws from: every spell, or only what the ruled
  /// schedule has unlocked by now. Gates DISPLAY only — equipping is still
  /// ungated while the schedule is in preview.
  List<Spell> _book(PlayerProfile p) => _showLocked
      ? Spellbook.all
      : Spellbook.all
            .where((s) => Progression.plannedUnlockLevelOf(s) <= _level(p))
            .toList();

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final p = game.profile;
    // The Academy loadout is not the campaign's: the town rule does not
    // gate it, and it is never the active preset.
    final canEdit = _academy || game.canEditLoadoutHere;
    final preset = _academy ? p.academyPreset : p.activePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlayerHeader(title: 'Spellbook'),
        if (!canEdit) _lockBanner(),
        Expanded(
          // ⭐ **Slivers, so the toolbar can PIN.** The press-stability rule
          // has a scrolling edge case a plain ListView cannot answer: filter
          // the shelf while scrolled near the bottom and the list gets
          // shorter, the scroll offset clamps, and every widget on screen —
          // the chip just pressed included — slides. A pinned header can only
          // be reached by scrolling past it, and once past it, it is nailed
          // to the top of the viewport where clamping cannot move it.
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _presetChips(context, game, p),
                      const SizedBox(height: 12),
                      if (_academy)
                        const _AcademyHeader()
                      else
                        _EditableName(
                          preset: preset,
                          canEdit: canEdit,
                          game: game,
                        ),
                      const SizedBox(height: 10),
                      _guideLink(context),
                      const SizedBox(height: 12),
                      // Two separate pools, each shown against its own cap.
                      SectionLabel(
                        'Elements  ·  ${preset.elementIds.length}/'
                        '${_elementBudget(p)}'
                        '   (tap ⓘ for details)',
                      ),
                      _elementGrid(context, game, p, preset, canEdit),
                      const SizedBox(height: 14),
                      SectionLabel(
                        'Spells  ·  ${preset.spellIds.length}/'
                        '${_spellBudget(p)}'
                        '   (tap ⓘ for details)',
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedToolbar(
                  child: _SpellToolbar(
                    kind: _kind,
                    onKind: (k) => setState(() => _kind = k),
                    cost: _cost,
                    onCost: (c) => setState(() => _cost = c),
                    // [H]
                    grouping: _grouping,
                    onGrouping: (g) => setState(() => _grouping = g),
                    sort: _sort,
                    onSort: (s) => setState(() => _sort = s),
                    // [F]
                    query: _query,
                    onQuery: (q) => setState(() => _query = q),
                    counts: spellKindCounts(
                      _book(p),
                      cost: _cost,
                      query: _query,
                    ),
                    // [C]
                    showLocked: _showLocked,
                    onShowLocked: (v) => setState(() => _showLocked = v),
                    // [E]
                    equipped: [
                      for (final id in preset.spellIds) Spellbook.byId(id),
                    ],
                    onUnequip: canEdit
                        ? (spell) => _setSpells(
                            game,
                            p,
                            preset,
                            List.of(preset.spellIds)..remove(spell.id),
                          )
                        : null,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                sliver: SliverToBoxAdapter(
                  child: _spellShelf(context, game, p, preset, canEdit),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Writes a new spell list into the active preset (shared by tile toggles
  /// and the [E] tray's unequip).
  void _setSpells(
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    List<String> ids,
  ) {
    if (ids.isEmpty) return;
    final next = LoadoutPreset(
      name: preset.name,
      elementIds: preset.elementIds,
      spellIds: ids,
    );
    if (_academy) {
      game.saveAcademyPreset(next);
    } else {
      game.savePreset(p.activePresetIndex, next);
    }
  }

  /// The element twin of [_setSpells], routed the same way.
  void _setElements(
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    List<String> ids,
  ) {
    final next = LoadoutPreset(
      name: preset.name,
      elementIds: ids,
      spellIds: preset.spellIds,
    );
    if (_academy) {
      game.saveAcademyPreset(next);
    } else {
      game.savePreset(p.activePresetIndex, next);
    }
  }

  /// The shelf below the toolbar, sectioned by [_grouping] after every
  /// filter has narrowed the book, each section ordered by [_sort].
  ///
  /// [B] A cost or search filter narrows each section IN PLACE. The shelf
  /// flattens only when there is nothing to section: grouping is None, or a
  /// kind chip has already named the single lane a Spell-Type grouping would
  /// show — one header over one lane says nothing the chip has not.
  Widget _spellShelf(
    BuildContext context,
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    bool canEdit,
  ) {
    final book = _book(p);
    final flat =
        _grouping == SpellGrouping.none ||
        (_kind != null && _grouping == SpellGrouping.kind);
    final sections = sectionSpells(
      book,
      grouping: flat ? SpellGrouping.none : _grouping,
      sort: _sort,
      kind: _kind,
      cost: _cost,
      query: _query,
    );
    if (sections.isEmpty) return const _NoMatches();
    final shownCount = sections.fold(0, (n, g) => n + g.spells.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ A narrowed shelf says how much of the book it is showing. With
        // 60 spells, "12 spells" without the total is a number the player
        // cannot read anything into.
        if (_filtering)
          SectionLabel('Showing $shownCount of ${Spellbook.all.length} spells'),
        for (final section in sections) ...[
          if (section.label.isNotEmpty)
            SectionLabel('${section.label}  ·  ${section.spells.length}'),
          _spellGrid(context, game, p, preset, section.spells, canEdit),
          const SizedBox(height: 12),
        ],
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
              child: Text(
                'How dueling works',
                style: TextStyle(color: AppColors.text, fontSize: 14),
              ),
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
              style: TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChips(BuildContext context, GameState game, PlayerProfile p) {
    final chips = <Widget>[];
    // ⭐ The Academy chip leads the row: always there, never locked, its own
    // colour — a different game, not a sixth preset — and FIRST, because a
    // chip parked behind four locked slots is a chip nobody scrolls to.
    chips.add(
      GestureDetector(
        onTap: () => setState(() => _academy = true),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _academy
                ? AppColors.gem.withValues(alpha: 0.18)
                : AppColors.panelHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _academy ? AppColors.gem : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school,
                size: 14,
                color: _academy ? AppColors.gem : AppColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                Academy.presetName,
                style: TextStyle(
                  color: _academy ? AppColors.text : AppColors.textDim,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < p.presets.length; i++) {
      final active = !_academy && i == p.activePresetIndex;
      chips.add(
        GestureDetector(
          onTap: () {
            setState(() => _academy = false);
            game.selectPreset(i);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : AppColors.panelHi,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.gold : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 14,
                  color: active ? AppColors.gold : AppColors.textDim,
                ),
                const SizedBox(width: 6),
                Text(
                  p.presets[i].name,
                  style: TextStyle(
                    color: active ? AppColors.text : AppColors.textDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Locked future preset slots.
    final total = Progression.presetSlotUnlockLevels.length;
    for (var i = p.presets.length; i < total; i++) {
      final unlockLevel = Progression.presetSlotUnlockLevels[i];
      final unlocked = p.level >= unlockLevel;
      chips.add(
        GestureDetector(
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
                Icon(
                  unlocked ? Icons.add : Icons.lock,
                  size: 14,
                  color: AppColors.textFaint,
                ),
                const SizedBox(width: 6),
                Text(
                  unlocked ? 'Add loadout' : 'Lv $unlockLevel',
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 40,
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
    );
  }

  Widget _elementGrid(
    BuildContext context,
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    bool canEdit,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final element in MagicElement.values)
          _elementTile(context, game, p, preset, element, canEdit),
      ],
    );
  }

  Widget _elementTile(
    BuildContext context,
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    MagicElement element,
    bool canEdit,
  ) {
    final style = element.style;
    final slot = preset.elementIds.indexOf(element.name);
    final selected = slot >= 0;
    final unlocked = _elementUnlocked(p, element);
    void toggle() {
      if (!canEdit || !unlocked) return;
      final ids = List.of(preset.elementIds);
      if (selected) {
        if (ids.length <= 1) return; // keep at least one
        ids.remove(element.name);
      } else if (ids.length < _elementBudget(p)) {
        ids.add(element.name);
      }
      _setElements(game, p, preset, ids);
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
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      elementGlyph(element, size: 18),
                      const SizedBox(width: 6),
                      // ⚠️ Flexible, not bare: the tile is a fixed 104 wide,
                      // so a long element name (or a player's larger system
                      // text) overflowed the row rather than shortening.
                      Flexible(
                        child: Text(
                          style.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.text
                                : AppColors.textDim,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selected ? 'Slot ${slot + 1}' : '—',
                    style: TextStyle(
                      color: selected ? style.color : AppColors.textFaint,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

  Widget _spellGrid(
    BuildContext context,
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    List<Spell> spells,
    bool canEdit,
  ) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Fixed tile height and a max width per tile: tiles stay compact on
      // any screen instead of scaling with viewport width.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        // One line, a bigger icon and bigger dots: 60 tall.
        mainAxisExtent: 60,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      children: [
        for (final spell in spells)
          _spellTile(context, game, p, preset, spell, canEdit),
      ],
    );
  }

  Widget _spellTile(
    BuildContext context,
    GameState game,
    PlayerProfile p,
    LoadoutPreset preset,
    Spell spell,
    bool canEdit,
  ) {
    final slot = preset.spellIds.indexOf(spell.id);
    final selected = slot >= 0;
    final unlocked = _spellUnlocked(p, spell);
    final unlockLevel = Progression.unlockLevelOf(spell);
    // [C] The ruled schedule's verdict, shown but not enforced: a spell the
    // player has not reached yet is dimmed and wears its level.
    final plannedLevel = Progression.plannedUnlockLevelOf(spell);
    final ahead = plannedLevel > _level(p);
    final kind = spellKindOf(spell);
    void toggle() {
      if (!canEdit || !unlocked) return;
      final ids = List.of(preset.spellIds);
      if (selected) {
        if (ids.length <= 1) return;
        ids.remove(spell.id);
      } else if (ids.length < _spellBudget(p)) {
        ids.add(spell.id);
      }
      _setSpells(game, p, preset, ids);
    }

    final nameColor = !unlocked ? AppColors.textFaint : AppColors.text;
    // Hover shows the same card the ⓘ opens — never a second, plainer text.
    final note = !unlocked
        ? 'Unlocks at level $unlockLevel'
        : ahead
        ? 'Unlocks at level $plannedLevel'
        : null;
    return HoverCard(
      card: (_) => SpellDetailCard(spell: spell, showDone: false, note: note),
      child: Opacity(
        opacity: !unlocked
            ? 0.4
            : ahead
            ? 0.45
            : (canEdit || selected ? 1 : 0.75),
        child: GestureDetector(
          onTap: toggle,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2B2150) : AppColors.panelHi,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            // [B] The kind stripe is an INNER clipped child, never a
            // one-sided border — a rounded box refuses non-uniform borders
            // (the rarity-stripe lesson), so the stripe sits inside the clip.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // [D] The cost dots are an OVERLAY in the top-right corner —
              // the same corner they hold on the duel tabs — so the two
              // screens read one language. Nothing in the Row reserves space
              // for them; the corner is empty by construction (the name and
              // effect lines are vertically centred, the trailing controls
              // too), so the overlay collides with nothing at any cost.
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    right: 8,
                    child: ChargeDots(
                      cost: spell.chargeCost,
                      variable: spell.xCost,
                      dotSize: 6.5,
                      gap: 3.5,
                      color: selected ? AppColors.gold : AppColors.textDim,
                    ),
                  ),
                  Row(
                    children: [
                      Container(width: 3, color: _kindColor(kind)),
                      const SizedBox(width: 7),
                      Icon(
                        unlocked
                            ? (spellIcons[spell.id] ?? Icons.auto_fix_high)
                            : Icons.lock,
                        size: 24,
                        color: selected ? AppColors.gold : AppColors.textDim,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        // The name alone: the effect line was dropped by ruling
                        // (2026-08-29) — the tooltip carries it, and a tile that
                        // repeats its hover text spends its space twice.
                        child: Text(
                          spell.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: nameColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // The key chip's cell is ALWAYS reserved (press-stability
                      // corollary): its box exists whether or not the spell is
                      // equipped, so equipping never shifts the info dot.
                      SizedBox(
                        width: 22,
                        height: 16,
                        child: selected
                            ? Container(
                                alignment: Alignment.center,
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (unlocked)
                        _infoDot(() => showSpellDetail(context, spell))
                      else
                        const SizedBox(width: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [B] The lane colours — the same five the dueling guide's resolution
/// ladder uses, so a stripe here and a rung there mean one thing.
Color _kindColor(SpellKind kind) => switch (kind) {
  SpellKind.shields => AppColors.sky,
  SpellKind.quick => AppColors.teal,
  SpellKind.auxSelf => AppColors.gold,
  SpellKind.auxOffense => AppColors.gem,
  SpellKind.offense => AppColors.ember,
};

/// The Academy loadout's header — a fixed name and the rules in a line,
/// where a preset would show its editable name.
class _AcademyHeader extends StatelessWidget {
  const _AcademyHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.school, color: AppColors.gem, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Academy loadout',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Every spell and element, at level 50. Edit it anywhere.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class _EditableName extends StatelessWidget {
  final LoadoutPreset preset;
  final bool canEdit;
  final GameState game;
  const _EditableName({
    required this.preset,
    required this.canEdit,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            preset.name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        title: const Text(
          'Rename loadout',
          style: TextStyle(color: AppColors.text, fontSize: 16),
        ),
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
          spellIds: preset.spellIds,
        ),
      );
    }
  }
}

/// The sort/filter band above the spell shelf — the Shop's toolbar
/// conventions (`shop_screen.dart`'s `_ShopToolbar`) applied to a book:
/// filter chips on the left, a fixed-width sort control on the right.
///
/// ⚠️ **Nothing here may move when it is pressed** (the standing law). Three
/// separate things are doing that work:
///  - the band is a FIXED [height], so a chip row can never grow one;
///  - every chip is the same shape lit or unlit (see [_Chip]), so lighting
///    one cannot shove its neighbours;
///  - the sort control is a fixed [_sortWidth] wide enough for its LONGEST
///    label, so choosing 'Charge cost' cannot slide the button out from under
///    the finger that just chose it.
///
/// ⚠️ The chip rows scroll HORIZONTALLY rather than wrapping. A [Wrap] with
/// two lines' worth of chips on a narrow phone is exactly the "inserted
/// space" the law forbids — and the kind row grows a chip every time the
/// engine grows a lane.
class _SpellToolbar extends StatelessWidget {
  // [E] Four rows: the equipped tray, the kind chips, the cost chips, and
  // [H] the group-by / sort-by row.
  static const double height = 144;
  static const double _rowHeight = 30;
  static const double _searchWidth = 150;

  final SpellKind? kind;
  final ValueChanged<SpellKind?> onKind;
  final SpellCostFilter cost;
  final ValueChanged<SpellCostFilter> onCost;
  // [H]
  final SpellGrouping grouping;
  final ValueChanged<SpellGrouping> onGrouping;
  final SpellSort sort;
  final ValueChanged<SpellSort> onSort;
  // [F]
  final String query;
  final ValueChanged<String> onQuery;
  final Map<SpellKind?, int> counts;
  // [C]
  final bool showLocked;
  final ValueChanged<bool> onShowLocked;
  // [E]
  final List<Spell> equipped;
  final ValueChanged<Spell>? onUnequip;

  const _SpellToolbar({
    required this.kind,
    required this.onKind,
    required this.cost,
    required this.onCost,
    required this.grouping,
    required this.onGrouping,
    required this.sort,
    required this.onSort,
    required this.query,
    required this.onQuery,
    required this.counts,
    required this.showLocked,
    required this.onShowLocked,
    required this.equipped,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    // ⚠️ Opaque, and the same ground the tab stands on: a pinned header the
    // shelf scrolls THROUGH is unreadable.
    color: AppColors.bg,
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
    child: Column(
      // [G] Stretch, so a row narrower than the toolbar starts at the left
      // edge like its siblings — the default centre alignment is what floated
      // the cost chips into the middle of the screen.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [E] The tray: what is in the loadout, with its key, always in view.
        SizedBox(height: _rowHeight, child: _tray()),
        const SizedBox(height: 4),
        SizedBox(
          height: _rowHeight,
          child: _chipRow([
            for (final k in <SpellKind?>[null, ...SpellKind.values])
              _Chip(
                // [F] The count is what tapping would show. ⚠️ Padded to
                // two figure-spaces and set in tabular numerals, so "60"
                // and "5" occupy the same width — the Locked toggle and the
                // cost chips CHANGE these counts, and a chip that shrank
                // with its number would slide every chip beside it (the
                // press-stability rule, caught by its own test).
                label:
                    '${spellKindFilterLabel(k)} · '
                    '${(counts[k] ?? 0).toString().padLeft(2, ' ')}',
                on: kind == k,
                onTap: () => onKind(k),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              Expanded(
                child: _chipRow([
                  for (final c in SpellCostFilter.values)
                    _Chip(
                      label: c.label,
                      on: cost == c,
                      onTap: () => onCost(c),
                    ),
                  // [C] Fixed width either way: the label changes, the
                  // chip's footprint must not.
                  SizedBox(
                    width: 112,
                    child: _Chip(
                      label: showLocked ? 'Locked: shown' : 'Locked: hidden',
                      on: !showLocked,
                      onTap: () => onShowLocked(!showLocked),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              // [F] Name search.
              SizedBox(width: _searchWidth, child: _searchBox()),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // [H] Group by (primary) and sort by (secondary), one scrolling row.
        SizedBox(
          height: _rowHeight,
          child: _chipRow([
            _rowLabel('GROUP'),
            for (final g in SpellGrouping.values)
              _Chip(
                label: g.label,
                on: grouping == g,
                onTap: () => onGrouping(g),
              ),
            const SizedBox(width: 10),
            _rowLabel('SORT'),
            for (final o in SpellSort.values)
              _Chip(label: o.label, on: sort == o, onTap: () => onSort(o)),
          ]),
        ),
      ],
    ),
  );

  Widget _rowLabel(String text) => Padding(
    padding: const EdgeInsets.only(right: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textFaint,
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _tray() {
    if (equipped.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Nothing equipped yet',
          style: TextStyle(color: AppColors.textFaint, fontSize: 11),
        ),
      );
    }
    return _chipRow([
      _rowLabel('IN LOADOUT'),
      for (var i = 0; i < equipped.length; i++)
        Tooltip(
          message: onUnequip == null
              ? equipped[i].name
              : 'Tap to remove ${equipped[i].name}',
          child: InkWell(
            onTap: onUnequip == null ? null : () => onUnequip!(equipped[i]),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2150),
                border: Border.all(color: AppColors.gold),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    i < _spellKeyLabels.length ? _spellKeyLabels[i] : '•',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    equipped[i].name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _searchBox() => TextField(
    // ⚠️ Rebuilt on every setState with the same text: a controller-less
    // field would reset its cursor each keystroke, so the text is seeded
    // through a fresh controller with the cursor pinned to the end.
    controller: TextEditingController.fromValue(
      TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      ),
    ),
    onChanged: onQuery,
    style: const TextStyle(color: AppColors.text, fontSize: 12),
    cursorColor: AppColors.gold,
    decoration: InputDecoration(
      isDense: true,
      hintText: 'Search spells',
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
      prefixIcon: const Icon(Icons.search, size: 15, color: AppColors.textDim),
      prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      filled: true,
      fillColor: AppColors.panelHi,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    ),
  );

  Widget _chipRow(List<Widget> chips) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final chip in chips) ...[chip, const SizedBox(width: 6)],
      ],
    ),
  );
}

/// Pins [child] at its own fixed height. Min and max extent are equal by
/// construction — this header never collapses, it only sticks.
class _PinnedToolbar extends SliverPersistentHeaderDelegate {
  final _SpellToolbar child;
  const _PinnedToolbar({required this.child});

  @override
  double get minExtent => _SpellToolbar.height;

  @override
  double get maxExtent => _SpellToolbar.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;

  @override
  bool shouldRebuild(_PinnedToolbar oldDelegate) =>
      oldDelegate.child.kind != child.kind ||
      oldDelegate.child.cost != child.cost ||
      oldDelegate.child.grouping != child.grouping ||
      oldDelegate.child.sort != child.sort ||
      oldDelegate.child.query != child.query ||
      oldDelegate.child.showLocked != child.showLocked ||
      oldDelegate.child.equipped.length != child.equipped.length ||
      !_sameIds(oldDelegate.child.equipped, child.equipped);

  static bool _sameIds(List<Spell> a, List<Spell> b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

/// ⚠️ Hand-rolled rather than [FilterChip], and deliberately the SAME shape
/// lit or unlit — the Shop's `_Chip`, kept identical so the two screens'
/// controls read as one game. A chip that grew a check mark when selected
/// would move the chip beside it, which is the press-stability rule broken by
/// decoration.
class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = on ? AppColors.bg : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? AppColors.gold : Colors.transparent,
          border: Border.all(color: on ? AppColors.gold : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11.5,
            // Digits share one width, so a label's count can change without
            // its chip changing size.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// The quiet one-liner a filter that matches nothing owes the player.
///
/// ⚠️ It must confess the FILTER is why — the same words the Shop uses.
/// Silence here reads as "the book has no shields", which is a different and
/// wrong fact.
class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Center(
      child: Text(
        'No spells match these filters.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textDim, fontSize: 13),
      ),
    ),
  );
}
