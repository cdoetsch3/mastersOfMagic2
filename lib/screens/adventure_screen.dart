import 'package:flutter/material.dart';

import '../game/adventure.dart';
import '../game/duel_controller.dart';
import '../game/enemies/enemy_def.dart';
import '../game/game_state.dart';
import '../game/skills.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/items/item_instance.dart';
import '../game/opponent_driver.dart';
import '../game/world.dart';
import '../ui/app_theme.dart';
import 'duel_screen.dart';
import 'level_up_screen.dart';
import '../ui/item_display.dart' show rarityColour;
import '../ui/item_icon.dart';

/// One run through a zone: what is in front of you, how far in you are, and
/// the only question that matters — press on, or walk out with what you have.
class AdventureScreen extends StatefulWidget {
  final GameLocation zone;

  const AdventureScreen({super.key, required this.zone});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  bool _busy = false;

  /// How many backpack slots the last defeat emptied.
  ///
  /// ⚠️ Screen-local, and null after a resume: the wipe happens on the profile
  /// (`GameState.loseEncounter`) and leaves no count behind, so this is the one
  /// chance to say the number out loud. The death panel states the *rule*
  /// regardless — a penalty is never left to be inferred.
  int? _wiped;

  @override
  Widget build(BuildContext context) {
    final game = GameStateScope.of(context);
    final run = game.run;
    // ⭐ **The picker takes the screen.** Loot is offered the instant the fight
    // ends (ruling 2026-08-17), and until it is answered there is no next
    // fight, no gathering and no door out — one question at a time, and the
    // one where something can be lost goes first.
    final choosing = run != null && run.unclaimed.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: Text(widget.zone.name),
        automaticallyImplyLeading: false,
      ),
      body: run == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _Progress(run: run),
                  const SizedBox(height: 14),
                  if (choosing)
                    _VictoryLoot(
                      // ⚠️ Keyed on the batch, so the next fight's drops get a
                      // fresh selection instead of inheriting the last one's
                      // ticks from a reused State.
                      key: ValueKey('${run.index}:${run.unclaimed.length}'),
                      run: run,
                      free: game.profile.backpack.free,
                      initial: game.defaultVictoryChoice.toSet(),
                      busy: _busy,
                      onTake: (chosen) => _claim(game, chosen),
                    )
                  else ...[
                    if (!run.isOver && run.atSectionStart)
                      _Beat(zone: widget.zone, section: run.section),
                    if (run.isOver)
                      _Ending(
                        run: run,
                        zone: widget.zone,
                        wiped: _wiped,
                        onLeave: () => Navigator.pop(context),
                      )
                    else
                      _NextFight(
                        run: run,
                        busy: _busy,
                        onFight: () => _fight(game, run),
                        onLeave: () => _leave(game),
                      ),
                    if (!run.isOver && run.currentNode != null) ...[
                      const SizedBox(height: 14),
                      _GatherCard(
                        node: run.currentNode!,
                        busy: _busy,
                        onGather: () => _gather(game),
                      ),
                    ],
                    if (!run.isOver) ...[
                      const SizedBox(height: 14),
                      _Supplies(
                        game: game,
                        run: run,
                        busy: _busy,
                        onUse: (id) => _use(game, id),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _fight(GameState game, AdventureRun run) async {
    final encounter = run.current;
    if (encounter == null || _busy) return;
    setState(() => _busy = true);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuelScreen(
          loadout: game.profile.activePreset.toLoadout(),
          driver: LocalAiDriver(
            persona: encounter.toPersona(),
            enemy: encounter.def,
          ),
          campaign: true,
          playerLevel: game.profile.level,
          playerGear: game.equipmentTotals,
          // ⭐ The belt is what a run is for: potions loaded in town, spent in
          // the fight that needed them, and gone from the save the instant
          // they are drunk — a wipe later cannot give them back.
          belt: game.profile.belt.loaded,
          onItemConsumed: game.consumeBeltItem,
          // ⭐ HP carries between encounters — that is the whole tension of
          // pushing on. Charge and shields reset; only health persists.
          playerStartingHp: run.playerHp,
          // ⚠️ Settled here, awaited by the end screen, so the loot exists
          // before it is drawn.
          // ⚠️ Three endings, and the third is the reason this is a switch
          // rather than an `if (!won)`: an escape (2026-08-17 ruling) ends the
          // run the way walking out does — nothing recorded, backpack kept —
          // and must never fall into the defeat branch.
          onSettle: (outcome, remainingHp) async {
            switch (outcome) {
              case DuelOutcome.won:
                return game.winEncounter(remainingHp: remainingHp);
              case DuelOutcome.fled:
                await game.fleeEncounter(remainingHp: remainingHp);
                return const [];
              case DuelOutcome.lost:
                // ⚠️ The defeat penalty is paid here, on the profile, and
                // this is the only moment its size is knowable — see [_wiped].
                _wiped = await game.loseEncounter();
                return const [];
            }
          },
        ),
      ),
    );

    if (!mounted) return;
    // ⚠️ This path pushes DuelScreen directly rather than going through
    // launchDuel, so the level-up has to be surfaced here too — otherwise
    // levelling mid-run is silent, which is the most likely place to level.
    await _showLevelUpIfAny(game);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _showLevelUpIfAny(GameState game) async {
    final level = game.pendingLevelUp;
    final from = game.pendingLevelUpFrom;
    if (level == null || !mounted) return;
    game.acknowledgeLevelUp();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelUpScreen(from: from ?? level - 1, to: level),
      ),
    );
  }

  Future<void> _gather(GameState game) async {
    setState(() => _busy = true);
    final out = await game.gatherNode();
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context);
    if (!out.succeeded) {
      messenger.showSnackBar(SnackBar(content: Text(out.refusal!)));
      return;
    }
    final def = ItemCatalogue.tryById(out.defId!);
    final name = def == null ? out.defId! : ItemCatalogue.displayName(def);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          out.leveledTo != null
              ? 'Gathered ${out.amount} × $name — '
                    '${Skills.displayName(out.skillKey!)} is now '
                    'level ${out.leveledTo}!'
              : 'Gathered ${out.amount} × $name · +${out.xp} '
                    '${Skills.displayName(out.skillKey!)} XP',
        ),
      ),
    );
  }

  Future<void> _use(GameState game, String defId) async {
    final outcome = await game.useItem(defId);
    if (!mounted) return;
    // ⚠️ Refusals are shown too — "You are already at full health." must be
    // seen, because a silent no-op reads as the button being broken.
    _say(outcome.message);
    setState(() {});
  }

  Future<void> _leave(GameState game) async {
    // ⭐ Ends the run only — everything won on the way is already carried.
    await game.leaveAdventure();
    if (mounted) setState(() {});
  }

  Future<void> _claim(GameState game, Set<int> chosen) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await game.claimVictoryLoot(chosen);
    if (!mounted) return;
    setState(() => _busy = false);
    // ⚠️ The abandoned count is said out loud, and named. Losing things quietly
    // is the whole bug this picker replaced, and the panel that showed the
    // receipt is gone the moment the choice is made.
    final left = result.left;
    _say(
      left.isEmpty
          ? '${result.taken.length} into your pack.'
          : '${result.taken.length} into your pack — left behind: '
                '${left.map((s) => _lootName(s, null)).join(', ')}.',
    );
  }

  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.panel,
      content: Text(message, style: const TextStyle(color: AppColors.text)),
    ),
  );
}

class _Progress extends StatelessWidget {
  final AdventureRun run;

  const _Progress({required this.run});

  @override
  Widget build(BuildContext context) {
    // ⭐ "encounter 3 of 9" up front, and it is true — the whole run was rolled
    // before the first fight.
    final done = run.index;
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            run.isFinished
                ? 'Run complete'
                : 'Encounter ${run.encounterNumber} of ${run.encounterCount}',
            style: const TextStyle(color: AppColors.text, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < run.encounterCount; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.only(right: 3),
                    color: i < done
                        ? AppColors.teal
                        : (run.encounters[i].def.rank == EnemyRank.common
                              ? AppColors.borderDim
                              : AppColors.gold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Health carried in: ${run.playerHp}',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NextFight extends StatelessWidget {
  final AdventureRun run;
  final bool busy;
  final VoidCallback onFight;
  final VoidCallback onLeave;

  const _NextFight({
    required this.run,
    required this.busy,
    required this.onFight,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final next = run.current;
    if (next == null) return const SizedBox.shrink();
    final def = next.def;
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.name,
                  style: const TextStyle(color: AppColors.text, fontSize: 18),
                ),
              ),
              Text(
                'Lv ${next.level}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${def.rank.label} · ${def.archetype.name}',
            style: const TextStyle(color: AppColors.gold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // ⭐ The lore channel: readable by anyone who cares, ignorable by
          // everyone else.
          Text(
            def.lore,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onFight,
                  child: Text(run.atBoss ? 'Face it' : 'Fight'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onLeave,
                  child: const Text('Return to town'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            // ⚠️ The stake, stated before the choice rather than after it —
            // and restated for the 2026-08-17 ruling, because the thing at
            // risk is no longer the run's haul but the whole backpack.
            'Leaving costs nothing — what you took is already yours. '
            'Losing empties your backpack.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _Ending extends StatelessWidget {
  final AdventureRun run;
  final GameLocation zone;

  /// How many backpack slots the defeat emptied, when this screen watched it
  /// happen. Null on a resumed run — the rule is still stated, only the number
  /// is missing.
  final int? wiped;

  final VoidCallback onLeave;

  const _Ending({
    required this.run,
    required this.zone,
    required this.wiped,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final (title, body, colour) = switch (run.outcome) {
      RunOutcome.cleared => (
        'The zone is cleared',
        // ⭐ Arrival poses the question; the epilogue answers it. Falls back
        // rather than showing a blank — most zones have no epilogue yet.
        zone.epilogue ?? 'You beat what was waiting at the end of it.',
        AppColors.gold,
      ),
      RunOutcome.returned => (
        'You walk out',
        // ⭐ True by construction now: every fight's loot was chosen on the
        // spot, so walking out carries the pack you already had.
        'You leave with everything you chose to carry.',
        AppColors.teal,
      ),
      RunOutcome.died => (
        'You are carried out',
        // ⚠️ **The penalty, in plain words** (ruling 2026-08-17). The old copy
        // said "its loot is gone", which was about a run-long haul that no
        // longer exists — and a player who lost their whole pack must not have
        // to work out what happened from an empty inventory screen.
        _deathBody(wiped),
        AppColors.ember,
      ),
      RunOutcome.running => ('', '', AppColors.text),
    };
    return GamePanel(
      child: Column(
        children: [
          Text(title, style: TextStyle(color: colour, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onLeave,
            child: const Text('Back to the map'),
          ),
        ],
      ),
    );
  }
}

/// The defeat panel's body: the rule first, the number when it is known.
///
/// ⚠️ Names the exemptions explicitly. A player whose pack has just been
/// emptied will go looking for their gear next, and finding it intact should be
/// this panel's promise rather than a relief they stumble on two screens later.
String _deathBody(int? wiped) {
  final lost = switch (wiped) {
    null => 'Everything in your backpack is gone.',
    0 => 'Your backpack was empty; there was nothing left to lose.',
    _ =>
      'Your backpack is empty — $wiped ${wiped == 1 ? 'item' : 'items'} lost.',
  };
  return '$lost What you were wearing, and your belt with everything loaded '
      'on it, came back with you.';
}

/// The name to print for a dropped slot.
///
/// ⭐ Takes the [instance] so a rolled staff reads "Ornate Heartwood
/// Quarterstaff" rather than the bare form — the picker is where the player
/// decides whether that roll is worth a slot, so it has to say what the roll
/// was. ⚠️ Falls back to the raw id for an item the catalogue no longer knows,
/// rather than crashing on a save the content patched out from under.
String _lootName(InventorySlot slot, ItemInstance? instance) {
  final def = ItemCatalogue.tryById(slot.defId);
  return def == null ? slot.defId : ItemCatalogue.displayName(def, instance);
}

Color _lootColour(String defId) {
  final def = ItemCatalogue.tryById(defId);
  return def == null ? AppColors.textFaint : rarityColour(def.rarity);
}

/// The victory picker: what the fight just dropped, and which of it fits.
///
/// ⭐ **Every win, immediately** (designer's ruling, 2026-08-17). The loot is
/// the player's the moment they say so — there is no run-long haul to lose any
/// more, and no ending where a forgotten pile is silently thrown away.
///
/// ⭐ **Rarest on top, then alphabetical** (`lootDisplayOrder`). The eye lands
/// on the thing worth arguing about, and identical drops sit together instead
/// of scattering through the list in drop order.
///
/// ⚠️ **Everything left here is gone for good.** That is stated on the panel,
/// not just in the confirmation, because the behaviour it replaced — silently
/// dropping the overflow — cost a playtester a rare they never knew they had.
class _VictoryLoot extends StatefulWidget {
  final AdventureRun run;
  final int free;

  /// Rarity-first and pre-trimmed by `GameState.defaultVictoryChoice`, so
  /// tapping straight through never spends the last slot on a log.
  final Set<int> initial;
  final bool busy;
  final ValueChanged<Set<int>> onTake;

  const _VictoryLoot({
    super.key,
    required this.run,
    required this.free,
    required this.initial,
    required this.busy,
    required this.onTake,
  });

  @override
  State<_VictoryLoot> createState() => _VictoryLootState();
}

class _VictoryLootState extends State<_VictoryLoot> {
  late final Set<int> _picked = {...widget.initial};

  /// ⚠️ Computed once, not per build: the rows must not reorder under the
  /// player's finger while they are ticking them.
  late final List<int> _rows = lootDisplayOrder(
    widget.run.unclaimed,
    widget.run.unclaimedInstances,
  );

  @override
  Widget build(BuildContext context) {
    final loot = widget.run.unclaimed;
    final atCapacity = _picked.length >= widget.free;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Spoils'),
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ Live, because "why is that one greyed out" has to answer
              // itself.
              Text(
                'Taking ${_picked.length} of ${loot.length} — '
                '${widget.free} ${widget.free == 1 ? 'slot' : 'slots'} free',
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                'Whatever you leave is abandoned for good.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              for (final i in _rows)
                _LootChoiceRow(
                  slot: loot[i],
                  instance:
                      widget.run.unclaimedInstances[loot[i].instanceId ?? ''],
                  picked: _picked.contains(i),
                  // ⚠️ A full selection blocks *adding*, never removing —
                  // locking the rows outright would trap the player in a
                  // selection they cannot change.
                  onTap: widget.busy || (atCapacity && !_picked.contains(i))
                      ? null
                      : () => setState(
                          () => _picked.contains(i)
                              ? _picked.remove(i)
                              : _picked.add(i),
                        ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.busy ? null : () => widget.onTake(_picked),
                  child: Text(
                    _picked.isEmpty
                        ? 'Leave it all behind'
                        : 'Take ${_picked.length}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LootChoiceRow extends StatelessWidget {
  final InventorySlot slot;
  final ItemInstance? instance;
  final bool picked;
  final VoidCallback? onTap;

  const _LootChoiceRow({
    required this.slot,
    required this.instance,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = onTap == null && !picked;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              picked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: picked ? AppColors.teal : AppColors.borderDim,
            ),
            const SizedBox(width: 10),
            // ⭐ The picker is where the player decides what a slot is worth,
            // so it is the one list that most wants a picture. ⚠️ The gap
            // travels with the icon, so today the name still starts 10px
            // after the checkbox exactly as it did.
            ItemIcon(
              defId: slot.defId,
              size: 20,
              gap: 8,
              fallback: const SizedBox.shrink(),
            ),
            Expanded(
              child: Text(
                _lootName(slot, instance),
                style: TextStyle(
                  // ⭐ Rarity on sight (ITEMS §8) — the one cue that makes the
                  // choice quick.
                  color: dimmed ? AppColors.textFaint : _lootColour(slot.defId),
                  fontSize: 13,
                ),
              ),
            ),
            if (dimmed)
              const Text(
                'no room',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

/// A gathering spot on the road (ITEMS §9b.7): one harvest, then the run
/// moves on. ⭐ Ignoring it is free — starting the next fight walks past.
/// 📝 The gather button becomes the node's gesture act when the engines land.
class _GatherCard extends StatelessWidget {
  final ActiveGatherNode node;
  final bool busy;
  final VoidCallback onGather;

  const _GatherCard({
    required this.node,
    required this.busy,
    required this.onGather,
  });

  @override
  Widget build(BuildContext context) {
    final def = node.def;
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                def.skill == GatherSkill.felling
                    ? Icons.forest
                    : def.skill == GatherSkill.mining
                    ? Icons.terrain
                    : Icons.grass,
                color: AppColors.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Skills.displayName(def.skill.name),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            def.flavor,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: busy ? null : onGather,
              child: Text('Gather · +${def.xp} XP'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything carried that can be used right now.
///
/// ⭐ **Generic**: it lists anything [Usable] with a real effect and shows what
/// that effect is, so a new consumable appears here with no UI change at all.
///
/// ⭐ **It states the health it is healing against.** "Restores 25% health" is
/// only half an answer; a player at 118/120 needs to see the 118 to understand
/// why the ration will be refused (`GameState.maxHp` is the same pool the use
/// actually heals, so the two cannot disagree).
///
/// ⚠️ Between encounters only (ITEMS §6b.2). Using something here is free; the
/// belt is what costs a turn mid-duel.
class _Supplies extends StatelessWidget {
  final GameState game;
  final AdventureRun run;
  final bool busy;
  final ValueChanged<String> onUse;

  const _Supplies({
    required this.game,
    required this.run,
    required this.busy,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final slot in game.profile.backpack.contents) {
      final def = ItemCatalogue.tryById(slot.defId);
      if (def is Usable && !(def as Usable).effect.isNothing) {
        counts[slot.defId] = (counts[slot.defId] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final max = game.maxHp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Supplies'),
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health ${run.playerHp} / $max'
                '${run.playerHp >= max ? ' — nothing to heal' : ''}',
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              const SizedBox(height: 4),
              for (final e in counts.entries)
                _ConsumableRow(
                  def: ItemCatalogue.byId(e.key),
                  count: e.value,
                  onUse: busy ? null : () => onUse(e.key),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsumableRow extends StatelessWidget {
  final ItemDef def;
  final int count;
  final VoidCallback? onUse;

  const _ConsumableRow({required this.def, required this.count, this.onUse});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        // ⭐ The between-encounters twin of the duel's belt rail, and wired the
        // same way so a potion looks like the same object in both places.
        ItemIcon(
          defId: def.id,
          size: 22,
          gap: 8,
          fallback: const SizedBox.shrink(),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ItemCatalogue.displayName(def, null),
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              // ⭐ Built from the effect, so the number and its text cannot
              // disagree.
              Text(
                (def as Usable).effect.describe,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          '×$count',
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onUse, child: const Text('Use')),
      ],
    ),
  );
}

/// The narrative beat for the section the player has just entered.
///
/// ⭐ **Paced, not front-loaded.** Whispering Woods' story is slowly realising
/// something is wrong; delivering that in one arrival paragraph would give the
/// answer before the player had the question.
///
/// ⚠️ Renders nothing when a zone has no beat for this section — most zones
/// have none yet, and a run must not stall waiting for text.
class _Beat extends StatelessWidget {
  final GameLocation zone;
  final int section;

  const _Beat({required this.zone, required this.section});

  @override
  Widget build(BuildContext context) {
    if (section >= zone.beats.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GamePanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.forest, color: AppColors.teal, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                zone.beats[section],
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
