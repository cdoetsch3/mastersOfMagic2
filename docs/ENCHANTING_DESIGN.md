# Masters of Magic 2 — Enchanting, Jewelry & the mote economy

Status: ✅ **ruled 2026-10-01, building.** Rulings (Christian, same day):
1. Enchants grant the element's **affinity stat at every tier, and at
   Greater the element's status as a gear proc too** ("both, by tier").
2. Scope: **all four verbs plus gems** in the first pass (three lanes, §8).
3. Re-enchanting costs the **full** price of the new enchant.
4. Transmute improves with Enchanting level: **4:1 → 2:1** (§3.2 curve).
⚠️ **Ruling 2 reverses an older one**: KINETIC §8.1 / ITEMS §9b.8 ruling 9
   kept Jewelry's learning at Rimeholt (L45). The §5.3 ladder below L45
   (twelve recipes, Thornmire to the Orrery) was in the scope Christian
   accepted, so that older ruling is superseded here; nothing in code gates
   learning a skill, and the Primal rungs open with Bronze (Old Quarry tin),
   so their job is Jewelry XP before Rimeholt, not Primal-band gear.
❓ **Lesser gem value (300) exceeds Crystal (150) + its stone**, so cutting
   a dropped Crystal vendors for more than the Crystal would. Not a shelf
   exploit (motes are never stock, and the conservation test guards that),
   but if cutting must never out-sell its mote, Lesser ≤ 150 + the cheapest
   stone. Christian's call.
5–9. Taken as recommended unless Christian says otherwise: Core drops from
   bosses at 2% `bonus`; elemental gems only; unsocket = one Shard, gem
   survives; aspected drops at 10% of rare+ drops; the Enchanting station's
   town is pinned in §4.2 at build.
Christian's ask: *"what should we do with enchanting? That needs a design, and
we need something to do with all of the elemental motes. Same is true for
jewelry."*

This doc does not invent a system. It gathers the pieces that already exist —
in the design docs and in shipped code — into one buildable shape, and marks
every decision still open with ❓. Design it supersedes nothing; it **cites**:

| Already decided (do not re-argue) | Where |
|---|---|
| The mote ladder Dust → Shard → Crystal → Core → Heart, and the refinement ratios 50 / 20 / 12 / 4 | ITEMS §6.0 |
| Enchanting = the element axis laid onto gear, **rewritable at a cost** | ITEMS §6.3, SYSTEMS §1 |
| Enchanting also owns conversion rates and the unbinding enchant | ITEMS §6.0b, §6c |
| Gems are cut by **Jewelry at Rimeholt** from a stone + Crystal / Core / Heart; Lesser / Standard / Greater; element-bound by their mote; 0–3 sockets is a **drop property**, never craftable | ITEMS §6d, SYSTEMS §1 |
| "Gem" means a socketed stone only; the currency is Resonance Prisms | ITEMS §6d.1 |
| One affinity stat per element, the full twelve | CELESTIAL §2.5a |
| Twelve aspect prefixes (Charred, Tidewashed, …), reserved for element-marked gear | ITEMS §9b.5b |
| Rewards never grant power; sets (archetype × enchant) are a separate Phase 8 lane | ITEMS §3, SYSTEMS §4 lane A |

⭐ **Sets are out of scope here.** The two-axis endgame needs five set
families designed and simmed; that is SYSTEMS lane A and its own red-pen. This
doc is the other axis — the element — and the mote sinks, which stand on their
own and which the sets will later lean on.

---

## 1. The problem, measured

Motes are the one material every kill pays and nothing spends:

| Fact (2026-10-01) | Number |
|---|---|
| Mote item defs shipped | 36 (12 elements × Dust / Shard / Crystal) + 3 Celestial essences |
| Recipes that consume a mote | **1** (the Celestial Totem, three essences) |
| Core / Heart items | 0 — `MoteTier.core` and `.heart` exist in the enum only |
| Expected motes per common kill (after the 2026-09-30 lean) | ~1.5 units, mostly Dust |
| Mote values | Dust 2g · Shard 25g · Crystal 150g (vendor pays 60%) |
| Jewelry recipes | 7, all Ethereal (L45+); the skill has no ladder below that |
| Jewelry gear in the catalogue | 37 (7 common, 24 rare, 6 epic) — nearly all drops |
| Enchanting recipes | 1 (the Totem) |
| Gear with sockets | 23 pieces (15 × 1, 4 × 2, 4 × 3); gems in the catalogue: **0** |

And the code already holds the seams, unused:

| Seam | Shipped as | Today |
|---|---|---|
| `ItemInstance.enchantId` | the applied enchant, "includes the unbinding enchant" | never set |
| `ItemInstance.aspect` | the element prefix a drop carries (§9b.5b) | never rolled; the name grammar already prints it |
| `ItemInstance.socketed` | gem def ids, positional, ≤ `socketCount` | always empty |
| `EquipmentDef.socketCount` | 0–3 per piece | 23 pieces carry one or more |
| `GemDef(element, modifiers)` | a socketable stone | no instances |
| `CraftSkill.enchanting`, `.jewelry` | skills with XP, levels, station copy | one recipe each side |

So the build is mostly **content plus two item-dialog verbs**, not a new
engine. The engine's part is one overlay in `Equipping.modifiersOf`: an
instance's enchant and gems add their modifiers to the def's.

---

## 2. The shape: four verbs on motes

```
            Refine (Enchanting)            Enchant (Enchanting, station)
 Dust ──▶ Shard ──▶ Crystal ──▶ Core ──▶ Heart        gear + motes ──▶ aspected gear
   ▲                                                     ▲
   │  Salvage (Enchanting)                               │  Socket (Jewelry, Rimeholt)
 equipment ──▶ motes of its element            cut stone + Crystal/Core/Heart ──▶ gem ──▶ socketed gear
```

| Verb | Skill | Where | Spends | Makes |
|---|---|---|---|---|
| **Refine** | Enchanting | anywhere (field-craftable, like ingots) | motes of one element | the next tier of the same element |
| **Transmute** ❓ | Enchanting | anywhere | motes of one element | motes of another, at a loss |
| **Enchant** | Enchanting | an Enchanting station | Shards / Crystals / a Core | the element axis on one piece: its affinity stat, its aspect prefix |
| **Salvage** | Enchanting | anywhere | one piece of equipment | motes of its element, by rarity |
| **Cut** | Jewelry | Rimeholt | a cut stone + Crystal / Core / Heart | a gem |
| **Socket** | Jewelry | Rimeholt | a gem | the gem seated in a piece's socket |

Everything above is a `RecipeDef` except Enchant, Socket and Salvage, which
act on an **instance** rather than making a new item — they are item-dialog
actions, the way Equip and Drop are today.

---

## 3. Refine and Transmute — the ladder gets its top

### 3.1 Core and Heart exist
Twenty-four new `MoteDef`s: `<element>_core` (rarity rare) and
`<element>_heart` (rarity epic), with the §6.0 ratios as recipes:

| Recipe | Inputs | Output | Enchanting level | Value of output |
|---|---|---|---|---|
| `refine_<el>_shard` | 50 Dust | 1 Shard | 1 | 25 |
| `refine_<el>_crystal` | 20 Shards | 1 Crystal | 10 | 150 |
| `refine_<el>_core` | 12 Crystals | 1 Core | 25 | **900** ❓ |
| `refine_<el>_heart` | 4 Cores | 1 Heart | 40 | **3,600** ❓ |

⭐ **Refining destroys value on purpose** (50 Dust = 100g in, 25g out). It is
a sink, and the vendor price of the output is never the point; the point is
reaching a tier that drops rarely (Crystal) or never (Core, Heart). The §6.0
table already says this.

📝 Core and Heart never drop (§6.0: *"Heart — crafting only"*; Core *"possibly
never"*). ❓ **Should Core drop at all?** Proposal: bosses only, as a `bonus`
entry at 2% — rare enough to be a story when it happens, not a plan.

### 3.2 Transmute ✅ (skill curve)
ITEMS §6.0b designed neutral → element conversion, but **no neutral motes
exist** and no zone drops them. The equivalent need is real, though: a Pyro
player farming the Sunless Reach banks Solar and Lunar Dust they will never
spend. Proposal: **element → element at 3 : 1, Enchanting level 20**, same
tier in and out (`transmute_dust`, `transmute_shard`, `transmute_crystal` as
recipes that take any element and name the target). ⚠️ The §6.0b rate
improvement with skill (4:1 → 1:1) was for *neutral* motes; cross-element
should stay lossy at every level or farming the easiest zone becomes the
best source of every element. ✅ **Ruled: a skill curve, never better than
2:1** — Enchanting 1: 4:1 · 15: 3:1 · 30: 5:2 · 45: 2:1. The recipe reads
the crafter's level at craft time (one recipe per tier, variable input count).

### 3.3 XP
Refining pays Enchanting XP by the §9b.9 formula (inputs × (4 + 2 × level)),
so a player who only ever refines still climbs to the enchant tiers. This is
the ladder the skill lacked.

---

## 4. Enchant — the element axis on a piece

### 4.1 What an enchant is
One per piece, any equipment slot. It **sets the instance's aspect** (so
the piece is named by its prefix: *Charred Oak Staff*, *Moonlit Nacre
Pendant*) and **sets `enchantId`** to `<element>_<tier>`. Its effect is that
element's affinity stat from CELESTIAL §2.5a, as an overlay on the def's
modifiers:

✅ **Retuned 2026-10-01 after the §8.4 re-sim** (Christian: "the measured
retune"): dodge 1/1/2, crit chance 1/2/3, Sanctus 2/4/5, every other Greater
row two thirds of the draft; gems grant the same amounts (§5.1); the gear
proc is 10%.

| Element | Affinity stat | Lesser | Standard | Greater |
|---|---|---|---|---|
| Pyro, Umbra | crit damage | +4 | +8 | +9 |
| Electro, Astral | crit chance | +1 | +2 | +3 |
| Aero, Lunar | dodge | +1 | +1 | +2 |
| Geo, Arcane | deflect chance | +3 | +6 | +7 |
| Solar | accuracy | +3 | +6 | +7 |
| Aqua | shield strength % | +4 | +8 | +9 |
| Flora | healing received % | +4 | +8 | +9 |
| Sanctus | shield strength % **and** healing received % | +2 / +2 | +4 / +4 | +5 / +5 |

📝 Numbers are a first draft sized against the shipped rare jewelry (a rare
pendant carries roughly +5 to +10 of one stat). ⚠️ **Re-sim before Greater
is final**: nine Greater enchants on a full kit is +63 crit chance or +90 deflect
chance, which the §7a output clamps (deflect activation **90%**, not 50% —
`CombatClamps.deflectActivationCapPercent`; crit chance is unclamped and
saturates at 100) will clamp but the balance probe has never seen. The
honest expectation is that Greater lands around two thirds of the draft.
⚠️ **Measured 2026-10-01 (§8.4): over budget.** The dodge row (Aero, Lunar)
is worth ~19 levels at Greater ×9 and ~9 at Standard ×9; crit chance
(Electro, Astral) ~9 at Greater; Mixed Greater ~12. ❓ Proposed retune in
§8.4 (dodge 1 / 1 / 2, crit chance 1 / 2 / 3, the rest of Greater to two
thirds) — the table above is still the shipped draft.

✅ **Ruled: both, by tier.** Lesser and Standard grant the stat; **Greater
grants the stat AND the element's status as a gear proc** (§4.1a). ⚠️ ITEMS
§7.1 names proc stacking as the biggest balance risk, so the proc is one
flat roll per damaging hit, never a streak-threshold change, and the re-sim
gate (§8.4) runs before Greater numbers are final.

### 4.1a The Greater proc ✅
A Greater enchant on ANY slot gives the wearer one **gear proc**: on each
damaging hit the wearer lands, a flat **10%** roll (✅ retuned from 15, §8.4) applies that element's
signature effect at base magnitude, as if a spell of that element had done
it — ⚠️ one roll per hit per element, never stacking across pieces (two
Greater Pyro enchants are still one 15% Ignite roll; a Pyro and an Electro
are two separate rolls). Streak-based effects map to their base unit:

| Element | Gear proc on hit |
|---|---|
| Pyro | Ignite (base tick, 3 turns) |
| Aqua | Waterlogged on them |
| Flora | +1 Photosynthesis stack on you |
| Electro | Static Feedback (strip 1 charge) |
| Aero | Tailwind: you gain Haste |
| Geo | Stagger: their next offensive ×0.5 |
| Solar | Blind, 1 turn |
| Lunar | Blind, 1 turn (Lunar's lock is Blind) |
| Astral | Astral Alignment on your next cast |
| Sanctus | Grace on you |
| Umbra | +1 Creeping Dark stack on them |
| Arcane | +1 Arcane Knowledge stack on you |

📝 Each proc uses the engine's existing status with its existing id, in the
GEAR lane (§7a lanes law), so it sums with spell stances and never replaces
them. Immunities and the §5.2 cleanse web apply unchanged.

### 4.2 Cost and tier

| Tier | Spends | Enchanting level | Station |
|---|---|---|---|
| Lesser | 5 Shards of the element | 1 | yes |
| Standard | 3 Crystals | 15 | yes |
| Greater | 1 Core | 30 | yes |

⭐ **Station-bound, unlike Refine.** A tier gate must not be craftable in the
field (the Totem's own rule); an enchant is a tier gate on a piece. ✅ The
Enchanting station is already pinned in `world.dart`: **Meridian**
(Jewelry's is Rimeholt, and Zenith has every station). ⚠️ `RecipeDef.
stationRequired` is a shipped field that NOTHING enforces today — the
Enchant and Socket actions (lane 3) are the first real station gates, and
they gate on `World.byId(location).station`, not on that flag.

### 4.3 Re-enchanting (the rewritable rule)
Enchanting an enchanted piece **replaces** the enchant. ✅ **Ruled: full cost.** (SYSTEMS §3.6
had proposed half; declined.) Half price makes the second enchant
cheaper than the first for no reason the player can see, and the whole cost
is already small next to the piece. What makes two axes freeing is that
re-attunement is *possible*, not that it is discounted.

### 4.4 Aspected drops (§9b.5b) — switch them on, weaker
A drop in an element's zone may roll an aspect at mint: ❓ **10% of
rare-or-better drops** carry a Lesser-strength affinity of the zone's lead
element and the prefix, as the doc already says (*"pre-enchanted sidegrades,
weaker than a real enchant"*). An aspected drop can still be enchanted; the
enchant replaces the aspect. This is the cheapest content in the doc (one
roll in `_materialise`) and it teaches the prefix before the player can make
one.

### 4.5 Unbinding ❓ deferred
The unbinding enchant (§6c) converts Untradeable to Tradeable. **Nothing in
the game trades yet**, so it would be a recipe with no effect. Keep the id
reserved (`unbind`), build it with trading.

---

## 5. Jewelry — gems, sockets, and a ladder below level 45

### 5.1 Gems
`GemDef` instances, cut at Rimeholt from a **cut stone** the catalogue already
has (quarry jasper, amber, hum quartz, everice, fallstone, nacre, eclipse
opal, sidereal glass, nadir garnet, orchard amber, aetherglass, …) plus a
mote tier:

| Gem | Spends | Jewelry level | Grants (elemental) | Grants (universal) ❓ |
|---|---|---|---|---|
| Lesser `<el>` | stone + 1 Crystal | 10 | the element's Lesser enchant amount | +15 max HP **or** +1 damage per cast |
| Standard `<el>` | stone + 1 Core | 25 | the Standard enchant amount | +30 / +2 |
| Greater `<el>` | stone + 1 Heart | 40 | the Greater enchant amount | +50 / +4 |

⭐ **Elemental gems are stronger than universal ones** (§6d.3's anti-meta fix
1), and ⭐ **a second identical gem on the same piece gives half** (fix 2).
Both, as SYSTEMS §3.5 allowed.
⚠️ **Measured (§8.4):** flat +2 / +4 / +7 across elements over-pays the
per-point-strong stats — three Greater Aero gems (+7, +3, +3 = +13 dodge) are
worth ~3 levels, and the one-hand route's six sockets (+26) ~5.4, a whole
late-game budget from gems alone; the same +13 as Pyro crit damage is 0.5.
❓ Proposed: a gem grants its element's ENCHANT amount at the same tier (so a
retuned Greater dodge gem is +2), keeping repeats-halved. ❓ Ship universal gems at all in the first
pass? Recommendation: elemental only; add universal later if sockets feel
too narrow.

### 5.2 Sockets
- Socket at Rimeholt (Jewelry, any level once you hold a gem). The gem's id
  goes into `socketed`; the overlay adds its modifiers.
- ❓ **Removal**: SYSTEMS §3.4 proposed reusing the unbinding enchant.
  Recommendation, simpler: **unsocketing costs one Shard of the gem's
  element and the gem survives**; done at Rimeholt. Gems are not currency
  because sockets are scarce, not because gems are stuck.
- Sockets are **never added** (confirming §6d.5); the 23 shipped pieces and
  future drops are the supply. ❓ Rarity floor: sockets only on rare-or-better
  drops going forward (the shipped commons with sockets — Spiritwood,
  Aetherwood — keep theirs; they were designed as the exception).
- The Concordant Crown is this system at twelve slots (§6d.1). Nothing here
  changes that; it only becomes buildable.

### 5.3 A Jewelry ladder from level 1
Today Jewelry has seven recipes, all at L45+. Proposal: **one ring and one
pendant recipe per quarter below Ethereal**, using Metalworking settings
(bronze → iron → skyiron) and the quarter's stone, at the quarter's common
and rare tiers, so a player can level Jewelry from Pennycross onward and
arrive at Rimeholt able to cut. Roughly 12 recipes plus 12 catalogue entries
(or re-pointing existing drop-only rings to recipes where one exists). This
is a content lane, not a design question; the numbers follow ECONOMY §8.

---

## 6. Salvage — the exit for bad drops

Any equipment instance → motes of **its zone's lead element**, by rarity:

| Rarity | Returns |
|---|---|
| common | 3 Dust |
| uncommon | 8 Dust |
| rare | 1 Shard + 10 Dust |
| epic | 1 Crystal |
| mythic / legendary | 1 Crystal + 1 Shard (❓) |

Enchanting XP as a 1-input recipe. ⚠️ A salvage must always return **less
than the piece's vendor price** in mote value, or the vendor becomes
pointless — at the values above, a rare returns 45g of motes against a
vendor price in the hundreds. The point is *progress* (a Shard toward a
Crystal), not money. ❓ Should salvage return the gems socketed in the piece?
Recommendation: yes, gems come out whole (otherwise salvaging a socketed
piece is a trap).

---

## 7. Surfaces

- **Craft screen**: Enchanting's Refine / Transmute / Salvage and Jewelry's
  Cut are ordinary recipes, so they use the existing screen with no new UI.
  Salvage needs a picker for *which* instance (a recipe whose input is "one
  piece of equipment") — the one new recipe shape. ⚠️ As built, Salvage is
  an **item-dialog action** instead (§8.3): the dialog is the picker.
- **Item dialog**: two new actions on equipment, shown greyed with a reason
  away from the station: **Enchant…** (element and tier picker with the
  cost and the stat it grants, in the words of the §2.5a table) and
  **Socket…** (choose a gem from the pack; shows the piece's sockets as cells,
  filled or empty). Both are press-stable and show what changes before
  committing, like the shop's basket.
- **Stat lines**: an enchanted or socketed piece's dialog prints the def's
  stats, then `Enchant: Charred (Standard) · +8 crit damage`, then one line
  per socket. The "From equipment" panel sums overlays into the totals it
  already shows.
- **Names**: the aspect prefix comes free from the shipped grammar.

---

## 8. Budget and order of work

1. ✅ **Model + overlay** (one lane, built 2026-10-01): Core/Heart motes,
   `enchantId`/`socketed` read by `Equipping.modifiersOf`, the gem and enchant
   tables, aspected drop roll, tests at the caps. No UI.
   - Motes: `lib/game/items/catalogue/refined_motes.dart` (24; Core rare 900,
     ⚠️ Heart epic **0g and Bound** per ECONOMY §14c — the 3,600 above stays ❓).
   - Gems: `lib/game/items/catalogue/gems.dart` (36, +2/+4/+7, 300/1,500/Bound at 0 — a Greater gem inherits the Heart's ECONOMY §14c rule).
     Both registered under `ItemCatalogue.byWorkshop` (`refined`, `gems`) —
     made, never found, so no zone owns them; icons under
     `assets/items/refined|gems/`, described in `docs/ITEM_ART.md`.
   - Enchants: `lib/game/items/enchants.dart` (`EnchantDef`, `EnchantTier`,
     `Affinity`, `Enchants` — 36, the §4.1 table; Greater's
     `procElement`).
   - Overlay + stat lines: `lib/game/items/equipping.dart`
     (`modifiersOf` = def × quality + `enchantOverlay` + `socketOverlays`,
     repeats halved; `describeInstance`); instance verbs `withEnchant` /
     `withSocket` / `withoutSocket` in `item_instance.dart`.
   - Gear procs: `ItemModifiers.gearProcs` (rides the PvP handshake) →
     `DuelController._buildMage` → `MageState.gearProcs` → the engine's
     `_rollGearProcs` at `ElementTuning.gearProcPercent` (15), element-enum
     order, no draw for an empty set.
   - Aspected drops: `aspectedDropPercent` (10) / `rollDropAspect` in
     `lib/game/enemies/loot.dart`, threaded from `rollKill`'s zone.
   - Tests: `test/enchanting_model_test.dart`,
     `packages/mom_engine/test/gear_proc_test.dart`.
2. ✅ **Recipes** (one lane, built 2026-10-01): **refine ×48, transmute ×36,
   cut ×36, the Jewelry ladder ×12** — 132 recipes in `RecipeBook.all`
   (now `final`: the tables are generated) — plus **six salvage markers**
   and `SalvageTable`, held OUT of the book until the crafter can match them.
   - Files: `lib/game/items/recipes/enchanting_recipes.dart` (Refine,
     Transmute, Salvage markers, `moteOf`), `jewelry_recipes.dart` (Cut,
     `stoneFor`, the ladder), `salvage_table.dart`; the input shape and the
     pure matcher in `recipe_def.dart`; the curve in `skills.dart`.
   - **Refine**: `refine_<element>_<tier made>`, 50 / 20 / 12 / 4 at
     Enchanting 1 / 10 / 25 / 40, field-craftable. The Heart rung makes a 0g
     Bound item. ⭐ A sink: `value_conservation_test` holds all 84 refines and
     transmutes in a dated bucket that asserts `Σ inputs > output` (the
     transmute at its best rung) instead of the clean window.
   - **Transmute** (§3.2, ruling 4): one recipe per **(target element, tier)**,
     `transmute_<target>_<tier>`, Dust / Shard / Crystal only (never Core or
     Heart), Enchanting 1, field-craftable. Its single input carries
     `RecipeInput.anyElement`: any element's mote of that tier **except the
     target's**, mixable in one craft, drawn largest-stack first (ties in
     enum order). ⭐ **The count is the curve at craft time, rounded UP —
     never better than the curve: L1 4 · L15 3 · L30 3 · L45 2** (5 : 2
     becomes 3 : 1 because the recipe makes one mote; honouring 5 : 2
     exactly would need a two-out recipe). `Skills.transmuteRatioAt` /
     `transmuteInputsAt`. The line's own `count` holds the L1 rung (4) so a
     reader that ignores the flag sees the worst case, and its exemplar id is
     the NEXT element's mote, so an unwired crafter performs a legal
     fixed-source transmute rather than a 4 : 1 self-loss.
   - **Salvage** (§6): `salvage_<rarity>` markers, Enchanting 1, 6 XP, input
     `RecipeInput.anyEquipmentOfRarity` (exact rarity). The yield is
     `SalvageTable.yieldOfInstance`: §6's table in the **first element of the
     zone whose catalogue defines the piece**, plus every socketed gem whole.
     Every shipped piece has a zone with elements, so **no piece salvages to
     nothing today**; a def no zone owns (a workshop def) would. Every shipped
     piece returns less mote value than its own vendor value (tested).
     📝 The Eclipsed Citadel lists all twelve elements, so its pieces salvage
     to **Aqua** — mechanical, flagged for a ruling.
   - **Cut** (§5.1): `cut_<element>_<lesser|standard|greater>`, stone + 1
     Crystal / Core / Heart at Jewelry 10 / 25 / 40, `stationRequired: true`
     (Rimeholt; enforced by lane 3's station gate, not the flag). The stone
     per element — each from a zone carrying the element, all twelve
     distinct:

     | Element | Stone | Zone (elements) | Stone value |
     |---|---|---|---|
     | Aqua | `nacre` | Tidewrack Shoals (Lunar + Aqua) | 95 |
     | Pyro | `obsidian` | The Molten Deep (Pyro + Geo) | 20 |
     | Flora | `amber` | Thornmire (Flora + Aqua) | 14 |
     | Electro | `hum_quartz` | Thunderspire Peaks (Electro + Aero) | 20 |
     | Aero | `everice` | Frostfell Pass (Aqua + Aero) | 26 |
     | Geo | `quarry_jasper` | Old Quarry (Geo) | 15 |
     | Solar | `aetherglass` | The Glass Archive (Solar + Arcane) | 210 |
     | Lunar | `eclipse_opal` | The Sunless Reach (Solar + Lunar) | 130 |
     | Astral | `sidereal_glass` | The Shattered Orrery (Astral + Electro) | 160 |
     | Sanctus | `reliquary_gold` | The Reliquary Deep (Sanctus + Umbra) | 340 |
     | Umbra | `thoughtglass` | The Umbral Wastes (Umbra) | 200 |
     | Arcane | `colophon_stone` | The Unwritten Library (Umbra + Arcane) | 480 |

     ⚠️ Aero has no stone in an Aero-led zone, so it takes Frostfell's
     everice and Aqua takes nacre; no Arcane-led zone yields a stone.
     `hum_quartz` is tagged Enchanting, not Jewelry — it is Thunderspire's
     only stone. ❓ **The gem values cannot sit in ECONOMY §8's window**:
     gems are flat (300 / 1,500 / 0) while stones span 14–480g, so the 36
     cuts are held in a dated ❓ bucket whose guard is that **their mote can
     never be bought**. A Lesser gem cut from a dropped Crystal (150) and a
     cheap stone vendors for more than the Crystal would — a real uplift,
     not a shelf-fed mint.
   - **The Jewelry ladder below Rimeholt** (§5.3): Jewelry 1 / 5 / 12 / 18 /
     24 / 30, a ring and a pendant at each; §5.3's metals verbatim (**bronze
     → iron → skysteel**); the ring carries flat HP, the pendant the stone's
     affinity. All common, all clean-passing ECONOMY §8 (§8.8 there):

     | Id | Zone | Slot | Stats | Equip | Jewelry | Inputs | Value |
     |---|---|---|---|---|---|---|---|
     | `amber_band` | thornmire | ring | +4 max HP | 8 | 1 | bronze + amber | 42 |
     | `amber_drop` | thornmire | neck | +3% healing received | 8 | 1 | bronze + amber ×2 | 54 |
     | `amber_ring` | thornmire | ring | +6 max HP | 12 | 5 | bronze + amber ×3 | 66 |
     | `amber_pendant` | thornmire | neck | +5% healing received | 12 | 5 | bronze + amber ×4 | 80 |
     | `jasper_ring` | old_quarry | ring | +7 max HP | 17 | 12 | iron + jasper ×2 | 74 |
     | `jasper_pendant` | old_quarry | neck | +2 accuracy | 17 | 12 | iron + jasper ×3 | 88 |
     | `obsidian_ring` | the_molten_deep | ring | +10 max HP | 27 | 18 | iron + obsidian ×2 | 84 |
     | `obsidian_pendant` | the_molten_deep | neck | +8 crit damage | 27 | 18 | iron + obsidian ×3 | 100 |
     | `opal_ring` | the_sunless_reach | ring | +14 max HP | 39 | 24 | skysteel + eclipse opal ×2 | 330 |
     | `opal_pendant` | the_sunless_reach | neck | +3 accuracy | 39 | 24 | skysteel + eclipse opal ×3 | 450 |
     | `sidereal_ring` | the_shattered_orrery | ring | +16 max HP | 42 | 30 | skysteel + sidereal glass ×2 | 390 |
     | `sidereal_pendant` | the_shattered_orrery | neck | 4% crit | 42 | 30 | skysteel + sidereal glass ×3 | 530 |

     ⚠️ **This reverses KINETIC §8.1 / ITEMS §9b.8 ruling 9** ("Jewelry's
     station and learning stay at Rimeholt"), on the strength of scope
     ruling 2; `amber_ring`, `jasper_pendant` and `obsidian_ring` are the ids
     that cut removed, returned. ⚠️ **Not raw copper for Primal**: copper is
     banked for exactly one maker, the Bronze Ingot (`cinderpeak_test`), so
     the Primal rungs take bronze and open once a player smelts it (~L15) —
     the ladder's job is Jewelry XP before Rimeholt, not Primal-band gear.
     ⚠️ The Geo pendant takes **accuracy, not deflection**: CELESTIAL §2.1b
     fences deflection to crafted gloves plus one drop per quarter. 📝 The
     ladder's Jewelry gates interleave with the Ethereal jewelry's own
     (1 / 10 / 20 / 30 / 35) — they were always skill levels, not zone ones.
   - ⭐ **What `GameState.craft` must do at merge** (lane 3's file, so not
     done here): when any input is not `isExact`, gate on
     `recipe.satisfiedBy(counts, skillLevel: level, piece: chosen)` and
     consume exactly `recipe.drawFrom(counts, skillLevel: level)` instead of
     each line's `defId × count`. ~~For a salvage marker, remove the chosen
     instance and add `SalvageTable.yieldOfInstance(instance)`, then add the
     salvage markers to `RecipeBook.all`.~~ ⚠️ Superseded: Salvage shipped as
     an item-dialog action (§8.3 below), so the markers stay OUT of the book
     and `craft` refuses one. 📝 `Skills.xpForRecipe` reads the
     static `count` (4) for a transmute at every level — a ruling whether a
     master's cheaper transmute should pay less.
   - Tests: `test/enchanting_recipes_test.dart`; the sink and cut buckets in
     `test/value_conservation_test.dart`.
3. ✅ **Surfaces** (one lane, built 2026-10-01 — Christian verifies in the
   browser): Enchant… and Socket… on the item dialog, stat lines; then
   Salvage… (below), which replaced the §7 salvage picker.
   - Mutations: `GameState.enchantItem` / `socketGem` / `unsocketGem`, each
     with a PURE refusal (`enchantRefusal` / `socketRefusal` /
     `unsocketRefusal`) the sheets grey their buttons with. Instance
     mutations, not recipes: motes and gems are spent through `_spend`, the
     same pack-first-then-Storeroom door `craft` now uses. One `_mutate`
     each, `_earnLive` after.
   - Station gate: `GameState.stationRefusal(skill)` reads
     `World.byId(locationId).station` (Zenith's "Every station …" matches by
     prefix) and names the town: 'Needs the Meridian station.' /
     'Needs the Rimeholt station.'.
   - Costs and XP: `EnchantingCosts` (`game_state.dart`) — 5 Shards / 3
     Crystals / 1 Core, Enchanting 1 / 15 / 30, full price on a re-enchant;
     ❓ XP a flat **40 / 120 / 400** (proposed, not ruled — the §9b.9 recipe
     formula would pay Greater 64, less than Standard's 102).
   - Unsocket: one Shard of the gem's element, the gem back to the PACK
     (refused 'No room in your pack for the gem.' when it cannot land —
     room asked after the Shard is paid).
   - Refused re-enchant: the SAME enchant again ('It already carries
     Charred (Lesser).') — it would spend motes to change nothing.
   - UI: `lib/screens/gear_work_actions.dart` (the dialog entries, greyed
     with the station reason away from it; `ReservedActionRow`, the shared
     press-stable button cell), `enchant_sheet.dart`, `socket_sheet.dart`;
     the item dialog prints `Equipping.describeInstance` for an owned piece.
   - Tests: `test/enchanting_surfaces_test.dart`.
   - ✅ **Salvage… on the item dialog** (built 2026-10-01 — Christian
     verifies in the browser). ⭐ **An item action, not a bench recipe**: the
     dialog already names the piece, so §7's "picker for which instance" is
     the dialog itself, and the six markers stay out of `RecipeBook.all`.
     - Mutation: `GameState.salvageItem(instanceId)` with the pure
       `salvageRefusal`, whose first half `salvageWhereRefusal` is what the
       dialog greys with. **Field-craftable — no station** (§6). In order:
       'That item is gone.' · 'Only gear can be salvaged.' · 'Take it off
       first.' (worn) · 'Bring it from the storeroom first.' (in any town's
       Storeroom) · 'No room in your pack for what comes out.'. ⭐ Room is
       asked with **the piece's own slot already empty**, then every yield
       line through `Backpack.withAdded` (Dust tops up stacks at 25, Shards
       at 5, Crystals and gems 1 a slot), all-or-nothing — a gem never drops
       on the floor. ONE `_mutate`: the pack swapped, the instance removed
       from `itemInstances` (the one-pool rule), the XP paid; `_earnLive`
       after.
     - Yield: `SalvageTable.yieldOfInstance`, read through
       `GameState.salvageYieldOf` — the sheet and the write print and add the
       same list.
     - XP: ⭐ shipped as the §9b.9 recipe formula on the matching
       `salvage_<rarity>` marker (`GameState.salvageXpFor` →
       `Skills.xpForRecipe`): Enchanting 1, one input ⇒ **6 XP at every
       rarity** (common 6 · uncommon 6 · rare 6 · epic 6 · mythic 6 ·
       legendary 6). ✅ applied at merge (manager, 2026-10-01) **Too little above common**: 6 XP is what refining
       ONE Dust pays (a 50-Dust Shard refine pays 300), and it says an epic
       teaches as much as an oak wand. Proposed instead, a flat table by
       rarity — **common 6 · uncommon 12 · rare 25 · epic 50 ·
       mythic/legendary 80** — doubling with rarity and keeping epic under a
       Standard enchant's 120. Not shipped; a ruling.
     - UI: `lib/screens/gear_work_actions.dart` (`salvageActionLabel`
       'Salvage…', last of the gear actions — the one that destroys the
       piece; greyed 'Salvage…: Take it off first.' on the paper doll),
       `lib/screens/salvage_sheet.dart`: the piece's name; the yield on one
       line — '3 Flora Dust', '1 Pyro Shard · 10 Pyro Dust', '3 Sanctus Dust
       · Lesser Pyro Gem ×2' (a repeated gem once, with the Socket sheet's
       count mark); the warning 'The piece is destroyed.', or on an
       enchanted piece 'The piece is destroyed. Its Charred enchant goes
       with it.' (⚠️ an aspected drop with no enchant gets the plain line —
       an aspect is not an enchant); then `ReservedActionRow` 'Salvage',
       greyed with the refusal, otherwise noting '+6 Enchanting XP.'. The
       yield and warning sit in fixed two-line boxes, so nothing above the
       button can move it. A press that lands closes the sheet with no
       banner — the pack shows the motes arriving.
     - Tests: `test/salvage_test.dart`.
4. ⚠️ **Re-sim gate — measured 2026-10-01: the draft is OVER budget.**
   Greater enchant and Greater gem numbers are NOT final; the retune below
   is ❓ for Christian. Nothing in `enchants.dart`, `gems.dart` or
   `ElementTuning` was changed — only the probe and its fence landed.
   - **Probe:** `tool/enchant_probe_test.dart` (`flutter test tool/
     enchant_probe_test.dart`, ~10 s, N = 300 on the six gate elements;
     `ENCHANT_PROBE_DEEP=1` runs all twelve, N = 1,200, kit-vs-kit and the
     WHAT-IF retune rows, ~90 s). The balance probe's seam and brain (i7
     both sides, starter loadout, 200-turn cap); every mage built by
     `DuelController._buildMage`, every kit read through `Equipping.totals`
     over real `withEnchant` / `withSocket` instances.
   - **Kit (L50):** the best SHIPPED piece per slot by the balance probe's
     stat-total proxy, main hand restricted to a two-hander → nine pieces:
     The Noon Hour, The Larger Reflection, Bedrock Greaves, Lowwater Tread,
     Umbralweave Gloves, The Maintained Road, Stonefall Signet, **Aetherwood
     Quarterstaff (3 sockets — the kit's only sockets)**, Corebiter Belt.
     No shipped piece has a `setId`, so "non-set" filters nothing. 📝 The
     one-hand route (Aetherwood Wand + Knot) is ten pieces and **six**
     sockets — one more enchant and double the gems; not run.
   - **Opponents:** every bestiary creature from a zone whose band holds 50
     (20 commons, 16 minis, 8 bosses), fought AT 50; "elite" = minis +
     bosses (commons are 100% for every kit, Bare included). **vsBare** is
     the kit-vs-Bare mirror (sides alternate). **lv** = levels the Bare kit
     must gain to tie, bisected on `levelScale` (4%/level on HP and damage):
     PvP = mirror at 50%, elite = Bare's elite win rate matching the kit's.
   - **Bare itself is worth 15.2 levels over a naked mage** (mirror) — the
     shipped L50 kit already sits past the "gear ≈ ten levels" line before
     any enchant. Greater ×9 Electro on top: 22.1 levels over naked; Mixed
     Greater: 25.4.

   **Measured (deep, N = 1,200 per kit per group):**

   | Kit | Key totals (base + gear) | Caps hit | Boss | Elite | vsBare | lv PvP | lv elite |
   |---|---|---|---|---|---|---|---|
   | Bare | crit 19% ×238, dodge 13, deflect 56/46, acc +12 | — | 47.0% | 69.8% | 49.4% | 0 | 0 |
   | Standard ×9 Pyro | crit dmg ×310 | — | 52.6% | 72.8% | 54.2% | 1.3 | 0.9 |
   | Greater ×9 Pyro | crit dmg ×364 | — | 60.8% | 76.3% | 60.1% | 2.6 | 2.2 |
   | Standard ×9 Electro | crit 55% | — | 65.7% | 79.9% | 69.9% | 5.6 | 3.6 |
   | Greater ×9 Electro | crit 82% | — | 79.0% | 87.8% | 81.7% | **9.1** | 7.3 |
   | Standard ×9 Aero | dodge 49 | — | 79.0% | 88.1% | 79.1% | **8.7** | 7.4 |
   | Greater ×9 Aero | dodge 76 (attacker hits ~16%) | near the 10% hit floor | 87.6% | 93.6% | 94.2% | **18.8** | 10.4 |
   | Standard ×9 Geo | deflect 110 | deflect >90 | 64.7% | 80.5% | 66.8% | 3.5 | 3.9 |
   | Greater ×9 Geo | deflect 146 | deflect >90 (+56 wasted) | 72.6% | 84.8% | 72.0% | 5.0 | 5.8 |
   | Standard ×9 Solar | acc +66 | hit 100 (+46 wasted) | 56.4% | 74.6% | 67.4% | 3.6 | 1.7 |
   | Greater ×9 Solar | acc +102 | hit 100 (+82 wasted) | 55.8% | 75.1% | 68.3% | 3.9 | 1.9 |
   | Standard ×9 Aqua | shield +102% | — | 59.8% | 77.4% | 59.3% | 1.9 | 2.6 |
   | Greater ×9 Aqua | shield +156% | — | 65.8% | 81.0% | 64.8% | 3.9 | 4.1 |
   | Greater ×9 Flora / Sanctus / Umbra | heal +141 / sh+93 heal+78 / crit dmg ×364 | — | 51–61% | 71–78% | 52–60% | 0.6 / 2.4 / 2.1 | ≤ 2.7 |
   | Greater ×9 Lunar / Astral / Arcane | = Aero / Electro / Geo | as their twins | | | 95.0 / 80.0 / 68.9% | 18.8 / 8.4 / 4.2 | 10.1 / 7.0 / 4.9 |
   | Mixed Standard ×9 | acc +18, crit 27%, dodge 17, deflect 68 | — | 67.7% | 81.7% | 69.9% | 5.4 | 4.4 |
   | **Mixed Greater ×9** (9 procs) | acc +22, crit 33% ×266, dodge 20, deflect 76 | hit 100 (+2) | 88.7% | 93.8% | 88.8% | **11.6** | 10.6 |
   | Greater ×9 + 3 gems, Electro | crit 95% | — | 81.4% | 89.0% | 84.4% | **10.3** | 7.8 |
   | Greater ×9 + 3 gems, Aero | dodge 89 | hit floor | 87.6% | 93.6% | 97.2% | **21.6** | 10.4 |
   | Greater ×9 + 3 gems, Pyro / Geo / Solar / Aqua | +13 of the stat | Geo, Solar: all wasted | | | 60.6 / 72.0 / 68.3 / 66.7% | 2.7 / 5.0 / 3.9 / 4.0 | |

   (Mixed = Aqua, Pyro, Electro, Aero, Geo, Solar, Astral, Umbra, Arcane:
   the twelve minus Lunar — its proc is Solar's Blind — Flora, the weakest,
   and Sanctus, whose Grace only blocks; Sanctus measured 2.4 levels to
   Umbra's 2.1, so the nine is "strongest" within noise.)

   **Procs observed** (Greater minus Standard effect landings per duel, the
   mirror vs Bare): Ignite +0.82, Waterlogged +0.99, Stagger +1.03, Blind
   +0.90 / +1.04 (Solar / Lunar), Photosynthesis +0.88, Creeping Dark +0.81,
   Arcane Knowledge +0.98, Astral Alignment +0.57, Grace +0.67, Static
   Feedback +0.44, Tailwind +0.28 — on ~5–7 damaging hits per duel, i.e.
   **13.6–15.7% per hit** where the effect can always land (the 15% roll,
   one per element — pinned). Electro (no charge to strip), Grace (max 1)
   and Tailwind (Haste often already held) land less for board reasons.
   ⚠️ **Stagger is applied ~7× as often and Waterlogged ~12× as often** as
   the Standard kit's own spells manage — the two effects ITEMS §7.1 puts on
   its "not modifiable" / "cap at −1" list.

   **What the WHAT-IF rows say** (deep run; hypothetical totals):
   - **The stat is the risk, not the proc.** Greater with its proc stripped:
     Electro 9.0 levels (proc adds ~0), Aero 18.8 (~0), Geo 3.5 (the proc is
     all of Geo's +1.5 — its Greater stat is entirely past the deflect cap),
     Pyro 1.9 (+0.7), Aqua 3.1 (+0.8), Mixed 9.1 (+2.5 for nine procs).
   - **Procs are sub-additive:** on the same mixed stats, one proc (Geo) adds
     ~1.5 levels, eight add ~1.3–2.5. Proc COUNT is not the lever.
   - **`gearProcPercent` is a weak lever:** 15 → 10 → 7 moved a mixed kit
     8.2 → 6.9 → 6.9 levels and single elements ≤ 0.7.
   - **Per point, dodge and crit chance are the strongest stats in the
     duel.** Dodge subtracts straight off the attacker's hit roll and nothing
     but the 10% hit floor stops it; crit chance compounds with the kit's own
     +38 crit damage. Deflect and accuracy self-limit at their caps; crit
     damage, shield and healing are cheap per point.
   - **Kit vs kit** (row's score): Aero beats every Greater kit 86–94%
     except **Solar, which beats Aero 68.6%** (accuracy is dodge's counter —
     the triangle works, the magnitude does not); Mixed beats everything but
     Aero (24.6%).

   **Conclusion.** Read against ITEMS §9b.4a's ten-level ceiling **as the
   enchant layer's own allowance**: single-element Greater ×9 is inside for
   ten of twelve elements (≤ 9.1), but **Aero/Lunar (18.8) and Mixed
   Greater (11.6) are outside**, as are Electro + gems (10.3) and Aero +
   gems (21.6); even **Standard ×9 Aero is 8.7**. Read **as a total** (the
   honest reading — the Bare kit already spends 15.2), nothing has room, and
   §9b.4a's own late-game figure (one quality tier ≈ **~5 levels** at L50)
   is the defensible ceiling for the enchant layer. On ITEMS §7.1: nine 15%
   procs are within the letter (+15pp per effect, never a threshold change)
   and measured cheap, but Stagger and Waterlogged procs contradict §7.1's
   allowlist outright.

   ❓ **Proposed retune (Christian's call — not applied).** Target: every
   single-element Greater ×9 ≤ ~5 levels, Mixed ≤ ~6.
   1. **Dodge (Aero, Lunar): 2 / 4 / 7 → 1 / 1 / 2.** Measured: Greater ×9
      → **4.5** levels (from 18.8), Standard ×9 at 1 → 2.5 (from 8.7). The
      first priority — the Standard tier is already over.
   2. **Crit chance (Electro, Astral): 2 / 4 / 7 → 1 / 2 / 3.** Greater ×9
      → **5.0** (from 9.1); Standard at 2 → 2.7 (from 5.6).
   3. **Every other Greater row to two thirds** (§4.1's own expectation):
      crit damage / shield / healing 14 → **9**, deflect / accuracy 10 →
      **7**, Sanctus 7 → **5**. Measured: Pyro 2.0, Aqua 2.7, Geo 5.0 (all
      cap + Stagger), Solar 3.9, Umbra 1.5, Sanctus 1.8, Flora 0.5, Arcane
      4.2. 📝 Geo/Arcane's deflect is past the 90 cap at ANY amount ≥ 4 on
      this kit, so their Greater number only matters on a deflect-less kit.
   4. With 1–3, **Mixed Greater ×9 = 7.6** (PvP) / 7.7 (elite); adding
      **`gearProcPercent` 15 → 10** brings it to **6.1** / 7.1. Without the
      proc cut Mixed stays the one build over ~6.
   5. **Gems follow the element's enchant row, not a flat +2 / +4 / +7.**
      Three Greater Aero gems alone (+13 dodge) are worth 2.9 levels; the
      one-hand route's six (+26) are worth **5.4 — a full budget from gems
      alone**. A Greater gem at the element's Greater enchant amount (dodge
      2, crit chance 3) closes it; ⭐ repeats-halved already keeps the rest
      small (Pyro +13 crit damage = 0.5 levels).
   6. **Stagger and Waterlogged as gear procs** need a ruling against ITEMS
      §7.1 (Stagger "explicitly not modifiable"): keep at 15%, drop them
      (Geo's Greater then grants only its capped stat), or swap in a
      non-lockout rider.
   After a retune lands: re-run deep, tighten `_measured` in the probe to
   the new numbers, and drop the ⚠️ above.

   ⚠️ **The fence (landed):** the probe pins the CI run's measured numbers
   + a margin (mirror score +5pp, levels +1.5, elite +5pp) for Greater ×9
   Pyro / Electro / Aero / Geo / Solar / Aqua, Mixed Greater and Greater +
   gems Electro / Aero; the proc rate per hit (10–20%) on Pyro, Geo, Solar,
   Aqua; the kit's composition; and that the WHAT-IF path equals the
   shipped overlay. Mutation-checked: Electro/Aero row 7 → 9 fails the
   fence (Aero 21.2 levels > 19.9), `gearProcPercent` 40 fails both the
   per-hit pin (0.41) and the fence.
   📝 Found in passing: `craftedGearAt` in `tool/balance_probe_test.dart`
   sums a two-handed main hand AND an off hand (at L50 the Aetherwood
   Quarterstaff + Knot) — a kit no player can wear.

---

## 9. ❓ Decisions for Christian, in order of consequence

1. Enchants grant the element's **affinity stat** (recommended) or its
   **status**?
2. Scope of the first pass: all four verbs plus gems (recommended), or
   Enchanting first (refine, enchant, salvage) and Jewelry after?
3. Re-enchant at **full cost** (recommended) or SYSTEMS §3.6's half?
4. **Transmute** element → element at a flat 3:1 (recommended), a skill
   curve, or not at all?
5. Core drops from bosses at ~2%, or crafting-only like Heart?
6. Universal gems in the first pass, or elemental only (recommended)?
7. Unsocket: one Shard, gem survives (recommended), or the unbinding enchant?
8. Aspected drops on at 10% of rare+ drops?
9. ~~Which town holds the Enchanting station?~~ ✅ Meridian (already in code).
