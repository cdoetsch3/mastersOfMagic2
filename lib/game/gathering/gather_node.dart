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

  // ---- Old Quarry (Geo, band 15–19) --------------------------------------
  //
  // ✅ 2 nodes — a pure zone's 2-per-zone rule (KINETIC_CONTRACT §3.1/§6).
  // ⚠️ Tin and Jasper are the zone's only world-held materials; nothing here
  // is a hide or a mote, so both of the zone's materials get a node.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 14` = 37.

  static const oqTinSeam = GatherNodeDef(
    id: 'oq_tin_seam',
    zoneId: 'old_quarry',
    skill: GatherSkill.mining,
    yieldsDefId: 'tin_ore',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 3),
    xp: 37,
    flavor:
        'A seam in a terrace wall the diggers left because it was not what '
        'they came for.',
  );

  static const oqJasperFace = GatherNodeDef(
    id: 'oq_jasper_face',
    zoneId: 'old_quarry',
    skill: GatherSkill.mining,
    yieldsDefId: 'quarry_jasper',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'split', complexity: 2),
    xp: 37,
    flavor: 'Red banding in a cut face, squarer than anything nature makes.',
  );

  // ---- Windward Steppe (Aero, band 19–24, KINETIC_CONTRACT §6) ----------

  /// ⭐ The only trees on the steppe (see `windward_steppe_items.dart`'s
  /// `yewLog` lore) — the same wood ladder note the catalogue makes.
  static const yewBreak = GatherNodeDef(
    id: 'ws_yew_break',
    zoneId: 'windward_steppe',
    skill: GatherSkill.felling,
    yieldsDefId: 'yew_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 3),
    xp: 45,
    flavor:
        'The only trees on the steppe, and every one of them leaning the '
        'same way.',
  );

  static const tussockSwale = GatherNodeDef(
    id: 'ws_tussock_swale',
    zoneId: 'windward_steppe',
    skill: GatherSkill.foraging,
    yieldsDefId: 'tussock_flax',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.rateDrag, 'draw', reps: 2),
    xp: 45,
    flavor: 'A dip where the wind passes over rather than through.',
  );

  // ---- Stormcliff Coast (Electro, band 23–28) ----------------------------
  //
  // ⭐ Pure zone, two world-held materials (KINETIC_CONTRACT §3.1, §6):
  // Seawrack Fibre off the tideline, Saltwort off the spray-line. Neither is
  // a hide or a mote, so both get a node — unlike Old Quarry's Tuskhide.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 22` = 53 — it rose with
  // the band when the coast and Thunderspire swapped (ruling 2026-09-21).

  static const wrackline = GatherNodeDef(
    id: 'sc_wrackline',
    zoneId: 'stormcliff_coast',
    skill: GatherSkill.foraging,
    yieldsDefId: 'seawrack_fibre',
    min: 2,
    max: 4,
    // rateDrag: long fibre comes out at ONE speed or it snaps, same contract
    // as Thornmire's retting.
    step: GestureStep(GestureEngine.rateDrag, 'draw'),
    xp: 53,
    flavor:
        'The tideline\'s own rope, laid out and salt-cured by the weather. '
        'Draw it steadily and it comes free in lengths.',
  );

  static const saltwortLedge = GatherNodeDef(
    id: 'sc_saltwort_ledge',
    zoneId: 'stormcliff_coast',
    skill: GatherSkill.foraging,
    yieldsDefId: 'saltwort',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'pick', complexity: 2),
    xp: 53,
    flavor:
        'It grows where the spray reaches and nowhere the spray does not — a '
        'ledge you can find with your eyes shut, once you know the smell.',
  );

  // ---- Frostfell Pass (Aqua + Aero, band 21–26, KINETIC_CONTRACT §6) ----
  //
  // ⚠️ Two nodes, not three — a hybrid's 3-per-zone rule (§3.1/§9b.8 ruling
  // 7), but Rimepelt is a hide and kill-only (§9b.7b), so only Hoarlichen and
  // Everice are world-held and get a node.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 20` = 49.

  static const ffLichenShelf = GatherNodeDef(
    id: 'ff_lichen_shelf',
    zoneId: 'frostfell_pass',
    skill: GatherSkill.foraging,
    yieldsDefId: 'hoarlichen',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'peel', complexity: 2),
    xp: 49,
    flavor:
        'Grey-green scale on black rock, the only living colour in the '
        'pass.',
  );

  static const ffEvericeSeam = GatherNodeDef(
    id: 'ff_everice_seam',
    zoneId: 'frostfell_pass',
    skill: GatherSkill.mining,
    yieldsDefId: 'everice',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'pry', complexity: 3),
    xp: 49,
    flavor: 'Ice in the rock that the black walls have never warmed.',
  );

  // ---- Thunderspire Peaks (Electro + Aero, band 17–22) -------------------
  //
  // ⭐ Hybrid zone, three world-held materials (KINETIC_CONTRACT §3.1/§6):
  // Rowan Log, Iron Ore and Hum Quartz. Nothing here is a hide or a mote, so
  // all three get a node.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 16` = 41 — it fell with
  // the band when the peaks and Stormcliff swapped (ruling 2026-09-21).

  static const tpRowanStand = GatherNodeDef(
    id: 'tp_rowan_stand',
    zoneId: 'thunderspire_peaks',
    skill: GatherSkill.felling,
    yieldsDefId: 'rowan_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 4),
    xp: 41,
    flavor: 'Mountain ash above the treeline, which should not be possible.',
  );

  static const tpIronSeam = GatherNodeDef(
    id: 'tp_iron_seam',
    zoneId: 'thunderspire_peaks',
    skill: GatherSkill.mining,
    yieldsDefId: 'iron_ore',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 4),
    xp: 41,
    flavor:
        'Rust-red rock that the storm has been finding for a very long '
        'time.',
  );

  /// ⚠️ `bandKeeper`, which no gather node has used before — deliberate
  /// (§9b.9c's "more difficulty, not more vocabulary" is about tiers; this is
  /// a new material with a fiction that names its own engine).
  static const tpHummingFace = GatherNodeDef(
    id: 'tp_humming_face',
    zoneId: 'thunderspire_peaks',
    skill: GatherSkill.mining,
    yieldsDefId: 'hum_quartz',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.bandKeeper, 'ring'),
    xp: 41,
    flavor: 'Quartz with a note in it. Strike it wrong and the note stops.',
  );

  // ---- The Molten Deep (Pyro + Geo, band 25–29, KINETIC_CONTRACT §6) -----
  //
  // ⭐ Hybrid zone, three materials (§3.1's 3-per-hybrid rule): Obsidian and
  // Firesalt are world-held and each get a node; Emberhide is a hide and
  // stays kill-only, so this zone authors two, not three.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 24` = 57.

  static const mdObsidianFlow = GatherNodeDef(
    id: 'md_obsidian_flow',
    zoneId: 'the_molten_deep',
    skill: GatherSkill.mining,
    yieldsDefId: 'obsidian',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'flake', complexity: 3),
    xp: 57,
    flavor:
        'A glass front where the floor stopped being liquid, still sharp '
        'along every edge it broke on.',
  );

  static const mdFiresaltCrust = GatherNodeDef(
    id: 'md_firesalt_crust',
    zoneId: 'the_molten_deep',
    skill: GatherSkill.foraging,
    yieldsDefId: 'firesalt',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.rateDrag, 'scrape', reps: 2),
    xp: 57,
    flavor:
        'White crust at a vent\'s lip, where the heat leaves something '
        'behind on its way out.',
  );

  // ---- The Mirrormere (Lunar, band 32–37) --------------------------------
  //
  // ⭐ Two nodes, the pure-zone count (§9b.8 ruling 7): the wood and the
  // fibre. ⚠️ `lunar_essence` is a gate part and kill-only — a node for it
  // would turn the Celestial Totem into a gathering errand.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 31` = 71.

  static const mmBloodwoodGrove = GatherNodeDef(
    id: 'mm_bloodwood_grove',
    zoneId: 'the_mirrormere',
    skill: GatherSkill.felling,
    yieldsDefId: 'bloodwood_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
    xp: 71,
    flavor:
        'They lean out over the water and the water shows them leaning '
        'back.',
  );

  static const mmMirrorflaxShallows = GatherNodeDef(
    id: 'mm_mirrorflax_shallows',
    zoneId: 'the_mirrormere',
    skill: GatherSkill.foraging,
    yieldsDefId: 'mirrorflax',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.rateDrag, 'draw', reps: 3),
    xp: 71,
    flavor:
        'Retted where the lake does not move. Pull steadily or you pull it '
        'in two.',
  );

  // ---- The Shattered Orrery (Astral + Electro, band 40-44) ---------------
  //
  // ⭐ THREE nodes, and all three are salvage (CELESTIAL_CONTRACT §4.6): the
  // zone has no wood, no fibre and no hide, so §9b.8's 3-per-hybrid rule is
  // met entirely out of a broken machine. ⚠️ Nothing here "grows back" — the
  // next run's roll is simply the next piece of the mechanism.

  static const soScrapRing = GatherNodeDef(
    id: 'so_scrap_ring',
    zoneId: 'the_shattered_orrery',
    skill: GatherSkill.mining,
    yieldsDefId: 'orrery_scrap',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 5),
    xp: 87,
    flavor: 'A fallen ring, still turning, and shedding teeth as it goes.',
  );

  static const soArcsaltEarthing = GatherNodeDef(
    id: 'so_arcsalt_earthing',
    zoneId: 'the_shattered_orrery',
    skill: GatherSkill.foraging,
    yieldsDefId: 'arcsalt',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.rateDrag, 'scrape', reps: 3),
    xp: 87,
    flavor:
        'Where the machine has been putting its charge for four centuries. '
        'Scrape between the flashes.',
  );

  static const soLensShatter = GatherNodeDef(
    id: 'so_lens_shatter',
    zoneId: 'the_shattered_orrery',
    skill: GatherSkill.mining,
    yieldsDefId: 'sidereal_glass',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'lift', complexity: 4),
    xp: 87,
    flavor:
        'A ring came down here and most of what it was made of is still '
        'edge-up.',
  );

  // ---- The Kiln Desert (Solar, band 30–34) -------------------------------
  // ⭐ Two nodes, and for once both materials get one: the Kiln Desert has no
  // hide and no cloth at all (CELESTIAL_CONTRACT §4.1), so nothing here is
  // kill-only and the 2-per-pure-zone budget is spent entirely on the world.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 29` = 67.

  static const kdIronwoodStand = GatherNodeDef(
    id: 'kd_ironwood_stand',
    zoneId: 'the_kiln_desert',
    skill: GatherSkill.felling,
    yieldsDefId: 'ironwood_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
    xp: 67,
    flavor:
        'Four trees in eleven miles, and every one of them older than the '
        'road.',
  );

  static const kdGlasspanFlat = GatherNodeDef(
    id: 'kd_glasspan_flat',
    zoneId: 'the_kiln_desert',
    skill: GatherSkill.foraging,
    yieldsDefId: 'glasswort',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'pick', complexity: 3),
    xp: 67,
    flavor:
        'The only green thing out here grows in the one place with no water '
        'at all.',
  );

  // ---- Tidewrack Shoals (Lunar + Aqua, band 36–40, CELESTIAL_CONTRACT §6)
  //
  // ⭐ Hybrid zone, three materials (§3.1's 3-per-hybrid rule): Wrackcotton
  // and Nacre are world-held and each get a node; Drownling Hide is a hide
  // and stays kill-only, so this zone authors two, not three.
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 35` = 79.
  // ⭐ Nacre is a Jewelry material gathered by **Mining** — §6a.1's "gems are
  // Mining's half", the same mapping `amber` already ships with.

  static const tsWrackcottonFlat = GatherNodeDef(
    id: 'ts_wrackcotton_flat',
    zoneId: 'tidewrack_shoals',
    skill: GatherSkill.foraging,
    yieldsDefId: 'wrackcotton',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.rateDrag, 'draw', reps: 3),
    xp: 79,
    flavor:
        'Six hours of flat, and then it is not flat any more. Draw steadily '
        'along the grain or the whole bed comes up as mud.',
  );

  static const tsNacreBed = GatherNodeDef(
    id: 'ts_nacre_bed',
    zoneId: 'tidewrack_shoals',
    skill: GatherSkill.mining,
    yieldsDefId: 'nacre',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'prise', complexity: 3),
    xp: 79,
    flavor:
        'A shell bed the water uncovers twice a day and has never once '
        'uncovered empty.',
  );

  // ---- Starfall Basin · 34–39 · Astral (CELESTIAL_CONTRACT §6) ---------
  //
  // ⭐ **The only zone in the game with two Mining nodes and nothing else.**
  // Starfall has no cloth, no wood and no herb — everything here came down
  // and nothing grew — so both of its materials are prised out of craters.
  // ⚠️ `sb_fallstone_crater` is **Enchanting ← Mining**, the one mapping
  // §6a.1's table does not print. The precedent is already shipped: `amber`
  // is a Jewelry material gathered by Mining because gems are Mining's half,
  // and a fallstone comes out of a crater floor with the same tool.

  static const sbSkyironField = GatherNodeDef(
    id: 'sb_skyiron_field',
    zoneId: 'starfall_basin',
    skill: GatherSkill.mining,
    yieldsDefId: 'skyiron_ore',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 5),
    xp: 75,
    flavor:
        'The bottom of a shallow bowl, and the thing in it did not come '
        'from the bowl.',
  );

  static const sbFallstoneCrater = GatherNodeDef(
    id: 'sb_fallstone_crater',
    zoneId: 'starfall_basin',
    skill: GatherSkill.mining,
    yieldsDefId: 'fallstone',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'pry', complexity: 3),
    xp: 75,
    flavor:
        'Deeper than the others, with something at the bottom that weighs '
        'right and looks wrong.',
  );

  // ---- The Sunless Reach (Solar + Lunar, band 38–42, CELESTIAL §6) -------
  //
  // ⭐ Hybrid zone, three materials (§3.1's 3-per-hybrid rule) — and ⚠️ **all
  // three are world-held**, which makes this the first hybrid in the game to
  // author the full three nodes. Nothing here is a hide: the zone's `hide`
  // drop role resolves to Duskcap instead (ETHEREAL_CONTRACT §3.5.1).
  // ⭐ XP is `9 + 2 × (zone.minLevel − 1)` = `9 + 2 × 37` = 83.

  static const srEbonyStand = GatherNodeDef(
    id: 'sr_ebony_stand',
    zoneId: 'the_sunless_reach',
    skill: GatherSkill.felling,
    yieldsDefId: 'ebony_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
    xp: 83,
    flavor: 'Black trunks on black rock. You find them by walking into them.',
  );

  static const srDuskcapShelf = GatherNodeDef(
    id: 'sr_duskcap_shelf',
    zoneId: 'the_sunless_reach',
    skill: GatherSkill.foraging,
    yieldsDefId: 'duskcap',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'pick', complexity: 3),
    xp: 83,
    flavor:
        'They fruit along the line the light stops at, in a row, like '
        'something planted them.',
  );

  /// ⚠️ `complexity: 4` — the highest any node asks, and the fiction names
  /// why: the value is in the boundary, and the boundary is what a bad split
  /// destroys.
  static const srOpalSeam = GatherNodeDef(
    id: 'sr_opal_seam',
    zoneId: 'the_sunless_reach',
    skill: GatherSkill.mining,
    yieldsDefId: 'eclipse_opal',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'split', complexity: 4),
    xp: 83,
    flavor:
        'Split it wrong and you get two dull halves. Split it right and you '
        'get the line.',
  );

  // ---- The Glass Archive (Solar + Arcane, band 43–47) --------------------

  /// ⭐ The hybrid's **three** materials would normally be three nodes, but
  /// one of them — `palimpsest_vellum` — is a kill-only hide, so the Archive
  /// authors a node for the lichen and **two** for the glass. ⚠️ That second
  /// glass node is the one place CELESTIAL_CONTRACT §6 knowingly breaks its
  /// own one-node-per-material habit, and the fiction is what earns it:
  /// aetherglass can be annealed off a roof or chosen out of the noon
  /// writing, and those are two different acts. 📝 Cut [gaNoonShelf] if
  /// one-node-per-material is a rule rather than a habit — nothing else
  /// depends on it.
  static const gaShadelineLichen = GatherNodeDef(
    id: 'ga_shadeline_lichen',
    zoneId: 'the_glass_archive',
    skill: GatherSkill.foraging,
    yieldsDefId: 'sunbleach_lichen',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'peel', complexity: 3),
    xp: 93,
    flavor:
        'The one strip of hillside the lenses never sweep, and the only '
        'thing alive on it.',
  );

  /// ⭐ `bandKeeper` is glass-working's own engine — *"keep a value inside a
  /// drifting band"* is literally annealing.
  static const gaRoofSpoil = GatherNodeDef(
    id: 'ga_roof_spoil',
    zoneId: 'the_glass_archive',
    skill: GatherSkill.mining,
    yieldsDefId: 'aetherglass',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.bandKeeper, 'anneal'),
    xp: 93,
    flavor: 'Roof glass, off a roof. Let it cool too fast and you get sand.',
  );

  /// ⚠️ **The first gather node ever to use `placement`**, and the fiction
  /// names its own engine: *"Choose WHERE — judgment of spacing, not motor
  /// skill."* Choosing which plate of the archive to take is exactly that.
  /// 📝 Swap to `alignCommit` if a fourth gather engine is unwelcome.
  static const gaNoonShelf = GatherNodeDef(
    id: 'ga_noon_shelf',
    zoneId: 'the_glass_archive',
    skill: GatherSkill.mining,
    yieldsDefId: 'aetherglass',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.placement, 'choose', complexity: 4),
    xp: 93,
    flavor:
        'Around midday the whole shelf is writing. Take a plate from where '
        'the writing is not.',
  );

  // ---- The Buried Sky (Geo + Astral, band 46–50) ------------------------

  /// ⭐ The hybrid's **three** materials would normally be three nodes, but
  /// `corebiter_hide` is kill-only (ETHEREAL_CONTRACT §3.1) — so the zone
  /// authors two, one per gatherable material, both Mining. ⚠️ A third node
  /// yielding `deepstratum_ore` exists in **Hallowmarch** (`hm_causeway_quarry`
  /// — the only cross-zone node in the game), and it belongs to that lane.
  static const bsStratumSeam = GatherNodeDef(
    id: 'bs_stratum_seam',
    zoneId: 'the_buried_sky',
    skill: GatherSkill.mining,
    yieldsDefId: 'deepstratum_ore',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 5),
    xp: 99,
    flavor:
        'The lowest band the shaft reaches, and the shaft was going '
        'somewhere.',
  );

  /// ⭐ `alignCommit` is the gem-setter's own engine — *"line something up,
  /// commit once"* — and prying a pocket open is the one act you do not get
  /// to repeat.
  static const bsNadirPocket = GatherNodeDef(
    id: 'bs_nadir_pocket',
    zoneId: 'the_buried_sky',
    skill: GatherSkill.mining,
    yieldsDefId: 'nadir_garnet',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'pry', complexity: 4),
    xp: 99,
    flavor:
        'A pocket of red in the black. Held to a lamp the flecks make a '
        'shape.',
  );

  /// ⭐ **The last rung of the wood ladder, nine tiers after Oak** — and the
  /// only wood in the game that was never a tree (ETHEREAL §4.5). ⚠️ The
  /// flavour says *"take one; there will be another"* because that is the
  /// zone's whole premise — over-completion, not ruin — and not because the
  /// node replenishes differently from any other.
  static const caAetherwoodStair = GatherNodeDef(
    id: 'ca_aetherwood_stair',
    zoneId: 'the_collapsed_academy',
    skill: GatherSkill.felling,
    yieldsDefId: 'aetherwood_log',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.releaseTiming, 'chop', reps: 5),
    xp: 107,
    flavor:
        'A staircase with more treads than it has height. Take one; there '
        'will be another.',
  );

  /// ⭐ The zone's SECOND material, which is also what its `hide` drop role
  /// resolves to (§3.5 rule 1) — the Academy has no kill-only hide.
  /// ⚠️ Mining rather than Felling: skill follows the material's CONSUMING
  /// skill (§6a.1), and slag feeds Metalworking.
  static const caSlagVault = GatherNodeDef(
    id: 'ca_slag_vault',
    zoneId: 'the_collapsed_academy',
    skill: GatherSkill.mining,
    yieldsDefId: 'mana_slag',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.sweetSpot, 'strike', reps: 5),
    xp: 107,
    flavor:
        'What ran out of the floor when the school stopped, pooled in the '
        'vault below it.',
  );

  // ---- The Reliquary Deep (ETHEREAL_CONTRACT §6) ------------------------
  //
  // ⭐⭐ **Three nodes, and no hide anywhere in the zone** — §3.1's note: the
  // only hybrid in either quarter whose three materials are all gatherable.
  // A corridor someone made, in a mountain, with no animals in it. ⚠️ Adding
  // a fourth node or a hide here breaks the zone's own premise, not just a
  // count.

  /// ⭐ The `hide` drop role in this zone resolves to `reliquary_gold`
  /// (§3.5 ruling 1), so the gold is doubly load-bearing: a node yield AND a
  /// kill payout. That is allowed — the no-second-source rule is about hides,
  /// which this zone has none of.
  static const rdCenserRun = GatherNodeDef(
    id: 'rd_censer_run',
    zoneId: 'the_reliquary_deep',
    skill: GatherSkill.foraging,
    yieldsDefId: 'censer_resin',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.trace, 'scrape', complexity: 4),
    xp: 111,
    flavor:
        'The censers along the warm stretch. None of them has been lit and '
        'none is cold.',
  );

  static const rdGiltFitting = GatherNodeDef(
    id: 'rd_gilt_fitting',
    zoneId: 'the_reliquary_deep',
    skill: GatherSkill.mining,
    yieldsDefId: 'reliquary_gold',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'prise', complexity: 4),
    xp: 111,
    flavor:
        'Somebody had a great deal of gold to spare on a corridor nobody was '
        'meant to walk.',
  );

  /// ⚠️ **Linen, not a hide** — it was folded and left on an altar, so it is
  /// something the world holds still and a node is exactly right for it.
  static const rdAltarLinen = GatherNodeDef(
    id: 'rd_altar_linen',
    zoneId: 'the_reliquary_deep',
    skill: GatherSkill.foraging,
    yieldsDefId: 'unleft_linen',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.rateDrag, 'lift', reps: 3),
    xp: 111,
    flavor: 'Still folded, still square, still on the altar. Nobody took it.',
  );

  // ---- The Umbral Wastes · 47–51 · Umbra (ETHEREAL_CONTRACT §6) ---------
  //
  // ⭐ Three nodes for two materials. `uw_umbralweave_drift` and
  // `uw_shoulder_drift` both yield `umbralweave`, and ⚠️ **that is a
  // THROUGHPUT fix, not a second source** — §6: umbralweave is consumed by
  // four or more recipes and one node per run section cannot keep a
  // level-50 crafter supplied. The no-second-source rule in this library's
  // own comment is about the *fiction* (a hide must not have a node at all),
  // not about node count.
  // ✅ XP is `9 + 2 × (47 − 1)` = **101** for all three.

  /// ⭐ Foraging, because Umbralweave is Tailoring stock (§6a.1's mapping).
  static const uwUmbralweaveDrift = GatherNodeDef(
    id: 'uw_umbralweave_drift',
    zoneId: 'the_umbral_wastes',
    skill: GatherSkill.foraging,
    yieldsDefId: 'umbralweave',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.rateDrag, 'draw', reps: 3),
    xp: 101,
    flavor:
        'It lifts off the ice in sheets if you pull it in the dark and tears '
        'if you do not.',
  );

  /// ⭐ Mining, because Thoughtglass is Jewelry stock — and `alignCommit` is
  /// the engine the fiction asks for: you choose the line and then you are
  /// committed to it, which is what splitting a decided thing is.
  static const uwThoughtglassFace = GatherNodeDef(
    id: 'uw_thoughtglass_face',
    zoneId: 'the_umbral_wastes',
    skill: GatherSkill.mining,
    yieldsDefId: 'thoughtglass',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.alignCommit, 'split', complexity: 4),
    xp: 101,
    flavor:
        'Split it however you like. The new face comes out the same shape as '
        'the old one.',
  );

  /// ⭐ The second Umbralweave node (§6's throughput ruling). ⚠️ Same yield,
  /// deliberately — 📝 cut this one if one-node-per-material is a hard rule.
  static const uwShoulderDrift = GatherNodeDef(
    id: 'uw_shoulder_drift',
    zoneId: 'the_umbral_wastes',
    skill: GatherSkill.foraging,
    yieldsDefId: 'umbralweave',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.rateDrag, 'draw', reps: 4),
    xp: 101,
    flavor:
        'Round the shoulder, where the light stops and the sheets are '
        'thickest.',
  );

  // ---- The Unwritten Library (ETHEREAL_CONTRACT §6) ---------------------
  // ⭐ Two nodes, not three: the hybrid's third material — `blankspine_vellum`
  // — is a **hide**, and a hide never gets a node (§3.1, and this file's own
  // no-second-source rule).

  /// Potions ← Foraging (§6a.1). XP is `9 + 2 × (54 − 1)` = 115.
  static const ulNightinkWell = GatherNodeDef(
    id: 'ul_nightink_well',
    zoneId: 'the_unwritten_library',
    skill: GatherSkill.foraging,
    yieldsDefId: 'nightink',
    min: 2,
    max: 4,
    step: GestureStep(GestureEngine.rateDrag, 'draw', reps: 4),
    xp: 115,
    flavor:
        'The well is full and nothing fills it. Draw steadily; it does not '
        'like haste.',
  );

  /// ⚠️ **The second gather node in the game to use `placement`**, after the
  /// Glass Archive's `ga_noon_shelf` — and both are *"choose which one"*,
  /// which is precisely what the engine's own doc says it is for (§6).
  static const ulColophonShelf = GatherNodeDef(
    id: 'ul_colophon_shelf',
    zoneId: 'the_unwritten_library',
    skill: GatherSkill.mining,
    yieldsDefId: 'colophon_stone',
    min: 2,
    max: 3,
    step: GestureStep(GestureEngine.placement, 'choose', complexity: 4),
    xp: 115,
    flavor:
        'Every book\'s last page is cut from one of these, and every book is '
        'still being written.',
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
    oqTinSeam,
    oqJasperFace,
    yewBreak,
    tussockSwale,
    wrackline,
    saltwortLedge,
    ffLichenShelf,
    ffEvericeSeam,
    tpRowanStand,
    tpIronSeam,
    tpHummingFace,
    mdObsidianFlow,
    mdFiresaltCrust,
    mmBloodwoodGrove,
    mmMirrorflaxShallows,
    soScrapRing,
    soArcsaltEarthing,
    soLensShatter,
    kdIronwoodStand,
    kdGlasspanFlat,
    tsWrackcottonFlat,
    tsNacreBed,
    sbSkyironField,
    sbFallstoneCrater,
    srEbonyStand,
    srDuskcapShelf,
    srOpalSeam,
    gaShadelineLichen,
    gaRoofSpoil,
    gaNoonShelf,
    bsStratumSeam,
    bsNadirPocket,
    caAetherwoodStair,
    caSlagVault,
    rdCenserRun,
    rdGiltFitting,
    rdAltarLinen,
    uwUmbralweaveDrift,
    uwThoughtglassFace,
    uwShoulderDrift,
    ulNightinkWell,
    ulColophonShelf,
  ];

  static final Map<String, GatherNodeDef> _byId = {
    for (final n in all) n.id: n,
  };

  static GatherNodeDef? byId(String id) => _byId[id];

  static List<GatherNodeDef> forZone(String zoneId) => [
    for (final n in all)
      if (n.zoneId == zoneId) n,
  ];
}
