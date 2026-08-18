/// Gathering nodes: where the world hands you materials (ITEMS §9b.7).
///
/// ⭐ **A node is an encounter card, not a map pin** (the Workbench-sheet
/// ruling, 2026-08-10): it appears between fights on an adventure, offers
/// one harvest, and its yield rides the run's pending loot through the same
/// take-home picker as drops. One simultaneous harvest per node (§9b.7's
/// one-harvest ruling); replenishment is simply the next run's roll.
///
/// ⚠️ **The flavor line never says what grows where beyond THIS node** — the
/// node itself is how the world teaches (the no-second-source ruling).
///
/// ---
///
/// ⭐ **Which materials get a node** (ITEMS §9b.7's "region materials also drop
/// from that region's enemies" + §9b.8's 2-per-pure / 3-per-hybrid rule): the
/// node is for what the WORLD holds still — wood, fibre, herb, root, ore, gem.
/// ⚠️ **Hides and motes are kill-only** and deliberately have no node: a hide
/// comes off a creature and a mote is what a creature leaves, so a node for
/// either would be a second source that contradicts its own fiction. That is
/// why Glimmerbrook and Cinderpeak, both pure two-material zones, author ONE
/// node each — their second material is a hide.
///
/// ⭐ **Skill is read off the material's consuming skill**, per §6a.1's table
/// (the only place the doc maps the two ladders onto each other): Woodcarving
/// ← Felling, Tailoring/Potions ← Foraging, Jewelry (gems) + Metalworking
/// (ore) ← Mining.
///
/// ⭐ **XP is `9 + 2 × (zone.minLevel − 1)`** — the Woods' authored 9 at band
/// floor 1, extended by the only zone number the design actually publishes.
/// 📝 Why that slope: [Skills.xpToNext] climbs `20 + 5 × (level − 1)`, and a
/// player gathering in-band sits roughly one skill level above the band floor,
/// so the two curves cancel — **every zone costs about 2.6 harvests per skill
/// level**, from Oak at band 1 to Birch at band 10. A flat XP would make the
/// Woods the fastest place to level Foraging forever; a steeper one would make
/// the last zone the only place worth gathering.
library;

import '../crafting/gesture.dart';
import '../skills.dart';

class GatherNodeDef {
  final String id;
  final String zoneId;
  final GatherSkill skill;

  /// What one harvest yields: [min]–[max] of the fungible [yieldsDefId].
  final String yieldsDefId;
  final int min;
  final int max;

  /// The gathering act — same vocabulary as crafting steps, so the gesture
  /// engines are reused with a field skin (Felling IS the chop meter).
  /// 📝 Unused until the engines exist; the button harvests instantly.
  final GestureStep step;

  /// Skill XP for the harvest.
  final int xp;

  /// One or two sentences, in the zone's voice.
  final String flavor;

  const GatherNodeDef({
    required this.id,
    required this.zoneId,
    required this.skill,
    required this.yieldsDefId,
    required this.min,
    required this.max,
    required this.step,
    required this.xp,
    required this.flavor,
  });
}

abstract final class GatherNodes {
  /// ⭐ Whispering Woods yields exactly its two materials (ITEMS §9b.8's
  /// 2-per-pure-zone rule): the wood and the fibre.
  static const oakStand = GatherNodeDef(
    id: 'ww_oak_stand',
    zoneId: 'whispering_woods',
    skill: GatherSkill.felling,
    yieldsDefId: 'oak_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 2),
    xp: 9,
    flavor:
        'An old stand, wind-felled and seasoning where it lies. Good logs, '
        'if your arms are willing.',
  );

  static const bindweedTangle = GatherNodeDef(
    id: 'ww_bindweed_tangle',
    zoneId: 'whispering_woods',
    skill: GatherSkill.foraging,
    yieldsDefId: 'bindweed_fibre',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'pull', complexity: 1),
    xp: 9,
    flavor:
        'A tangle thick enough to trip a horse. The trick is cutting it '
        'before it notices.',
  );

  // ---- Glimmerbrook (Aqua, band 3–8) -------------------------------------

  /// ⭐ One node, not two: Fawnhide is the zone's other material and hides
  /// come off creatures (see the library note). The herb is the whole of what
  /// the brook holds still.
  static const sapwortShallows = GatherNodeDef(
    id: 'gb_sapwort_shallows',
    zoneId: 'glimmerbrook',
    skill: GatherSkill.foraging,
    yieldsDefId: 'sapwort',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.trace, 'pick', complexity: 1),
    xp: 13,
    flavor:
        'It crowds the shallows where the light comes back off the stones. '
        'Cut at the waterline and the roots carry on without you.',
  );

  // ---- Cinderpeak Foothills (Pyro, band 6–11) ----------------------------

  /// ⭐ **The first Mining node in the game.** Until this existed the skill had
  /// no way to leave level 1 — Copper is Q1's only mined ore, and §9b.8 rules
  /// it a ⏳ banking material, so the node IS the promise: gatherable at 6,
  /// spendable when Metalworking opens at 15.
  ///
  /// ⚠️ Tuskhide is the zone's other material and is kill-only, so Cinderpeak
  /// authors one node, exactly as Glimmerbrook does.
  static const copperSeam = GatherNodeDef(
    id: 'cp_copper_seam',
    zoneId: 'cinderpeak_foothills',
    skill: GatherSkill.mining,
    yieldsDefId: 'copper_ore',
    min: 2,
    max: 4,
    // sweetSpot rather than releaseTiming: a pick lands ON the beat, where an
    // axe is held and let go. Same category, different contract — the two
    // gathering skills should not feel like one skin apart.
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 3),
    xp: 19,
    flavor:
        'The grit gives out on a seam the slope has been keeping to itself, '
        'rust-green and warm to the back of the hand. It comes away in flakes.',
  );

  // ---- Thornmire (Flora ▸ Aqua, band 8–13) -------------------------------

  /// The hybrid's three materials are all world-held, so Thornmire is the
  /// first zone to author a node per material.
  static const bogflaxRetting = GatherNodeDef(
    id: 'tm_bogflax_retting',
    zoneId: 'thornmire',
    skill: GatherSkill.foraging,
    yieldsDefId: 'bogflax_fibre',
    min: 2,
    max: 3,
    // rateDrag: long fibre comes out at ONE speed or it snaps.
    step: GestureStep(GestureEngine.rateDrag, 'draw'),
    xp: 23,
    flavor:
        'The mire rets its own flax and leaves it hanging in the current like '
        'hair. Draw it steadily; it comes free in lengths, or not at all.',
  );

  static const fenrootHummock = GatherNodeDef(
    id: 'tm_fenroot_hummock',
    zoneId: 'thornmire',
    skill: GatherSkill.foraging,
    yieldsDefId: 'fenroot',
    min: 2,
    max: 3,
    // trace at complexity 2 — the same engine the Woods' tangle uses, one step
    // more intricate, per §9b.9c's "more difficulty, not more vocabulary".
    step: GestureStep(GestureEngine.trace, 'dig', complexity: 2),
    xp: 23,
    flavor:
        'It has been down there longer than the trees have. Follow it by feel; '
        'the water will not tell you where it stops.',
  );

  /// 📝 **Ruling call — Amber is gathered, and it is Mining.** The doc never
  /// names a dropper for it; what it does say is §9b.8's banking clause, which
  /// calls Copper, Charcoal, Fenroot and Amber alike *"gatherable now,
  /// spendable next quarter"* — that word is the whole answer. The skill then
  /// follows §6a.1, where gems are Mining's half of the Jewelry lane, and the
  /// catalogue's own "the classic fossil gem, found in bog oak" says where.
  static const amberBogOak = GatherNodeDef(
    id: 'tm_amber_bog_oak',
    zoneId: 'thornmire',
    skill: GatherSkill.mining,
    yieldsDefId: 'amber',
    min: 2,
    max: 3,
    // alignCommit: you get one pry before the split closes on the blade.
    step: GestureStep(GestureEngine.alignCommit, 'pry', complexity: 2),
    xp: 23,
    flavor:
        'A drowned trunk, black as tar, with something gold caught in the '
        'split of it. Whatever summer that was, the water kept it.',
  );

  // ---- Ashfall Vale (Pyro ▸ Flora, band 10–14) ---------------------------

  static const birchStand = GatherNodeDef(
    id: 'av_birch_stand',
    zoneId: 'ashfall_vale',
    skill: GatherSkill.felling,
    yieldsDefId: 'birch_log',
    min: 2,
    max: 4,
    // ⭐ Deliberately the Oak stand's engine and skin with one more rep — the
    // wood ladder's tier 2 raises difficulty, never exposure, exactly as the
    // Birch recipes do against the Oak ones (§9b.9c, lever 3).
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 3),
    xp: 27,
    flavor:
        'Pale trunks in ranks, every one of them the same age, straight enough '
        'to sight along. The vale grew them itself in the years since.',
  );

  static const brookmintRill = GatherNodeDef(
    id: 'av_brookmint_rill',
    zoneId: 'ashfall_vale',
    skill: GatherSkill.foraging,
    yieldsDefId: 'brookmint',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'pick', complexity: 2),
    xp: 27,
    flavor:
        'A green line drawn down the grey where a stream still runs. Cold in '
        'the hand, which is the first cold thing all day.',
  );

  /// 📝 **Ruling call — Charcoal is gathered, and it is Felling.** Gathered,
  /// because §9b.8 banks it beside Copper as *"gatherable now"* and the
  /// catalogue's lore uses the verb outright ("Gathering it is not burning
  /// anything that was not already burned"). Felling, because the skill blurbs
  /// in `skills.dart` are the tie-breaker and only one of them fits: Mining is
  /// "Ore and gems" and char is neither, Foraging is "Fibres, herbs and hides"
  /// and char is none of those — it is wood, taken standing, from snags that
  /// burned where they stood. ⚠️ Its *consuming* skill is Metalworking, which
  /// §6a.1 pairs with Mining; that pairing is about ORE, and reading it as a
  /// rule would put an axeman's job in a pickaxe's ladder.
  static const charcoalBurn = GatherNodeDef(
    id: 'av_charcoal_burn',
    zoneId: 'ashfall_vale',
    skill: GatherSkill.felling,
    yieldsDefId: 'charcoal',
    min: 2,
    max: 4,
    // rateDrag, not the stand's releaseTiming: burned wood will not take an
    // axe stroke, so this one is a steady saw through char.
    step: GestureStep(GestureEngine.rateDrag, 'saw', reps: 2),
    xp: 27,
    flavor:
        'Snags burned through and still standing, black the whole way in. '
        'Take the char and leave the ash — nothing here needs burning twice.',
  );

  /// ⚠️ Every zone list must be reachable from here — an unlisted node
  /// compiles fine and simply never spawns, the usual silent failure.
  static const all = <GatherNodeDef>[
    oakStand,
    bindweedTangle,
    sapwortShallows,
    copperSeam,
    bogflaxRetting,
    fenrootHummock,
    amberBogOak,
    birchStand,
    brookmintRill,
    charcoalBurn,
  ];

  static final Map<String, GatherNodeDef> _byId = {
    for (final n in all) n.id: n,
  };

  static GatherNodeDef? byId(String id) => _byId[id];

  static List<GatherNodeDef> forZone(String zoneId) =>
      [for (final n in all) if (n.zoneId == zoneId) n];
}
