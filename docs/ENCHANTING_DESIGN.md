# Masters of Magic 2 — Enchanting, Jewelry & the mote economy

Status: ✅ **ruled 2026-10-01, building.** Rulings (Christian, same day):
1. Enchants grant the element's **affinity stat at every tier, and at
   Greater the element's status as a gear proc too** ("both, by tier").
2. Scope: **all four verbs plus gems** in the first pass (three lanes, §8).
3. Re-enchanting costs the **full** price of the new enchant.
4. Transmute improves with Enchanting level: **4:1 → 2:1** (§3.2 curve).
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

| Element | Affinity stat | Lesser | Standard | Greater |
|---|---|---|---|---|
| Pyro, Umbra | crit damage | +4 | +8 | +14 |
| Electro, Astral | crit chance | +2 | +4 | +7 |
| Aero, Lunar | dodge | +2 | +4 | +7 |
| Geo, Arcane | deflect chance | +3 | +6 | +10 |
| Solar | accuracy | +3 | +6 | +10 |
| Aqua | shield strength % | +4 | +8 | +14 |
| Flora | healing received % | +4 | +8 | +14 |
| Sanctus | shield strength % **and** healing received % | +2 / +2 | +4 / +4 | +7 / +7 |

📝 Numbers are a first draft sized against the shipped rare jewelry (a rare
pendant carries roughly +5 to +10 of one stat). ⚠️ **Re-sim before Greater
is final**: nine Greater enchants on a full kit is +63 crit chance or +90 deflect
chance, which the §4.1a caps (deflect 50%) will clamp but the balance probe
has never seen. The honest expectation is that Greater lands around two
thirds of the draft.

✅ **Ruled: both, by tier.** Lesser and Standard grant the stat; **Greater
grants the stat AND the element's status as a gear proc** (§4.1a). ⚠️ ITEMS
§7.1 names proc stacking as the biggest balance risk, so the proc is one
flat roll per damaging hit, never a streak-threshold change, and the re-sim
gate (§8.4) runs before Greater numbers are final.

### 4.1a The Greater proc ✅
A Greater enchant on ANY slot gives the wearer one **gear proc**: on each
damaging hit the wearer lands, a flat **15%** roll applies that element's
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
| Lesser `<el>` | stone + 1 Crystal | 10 | affinity +2 | +15 max HP **or** +1 damage per cast |
| Standard `<el>` | stone + 1 Core | 25 | affinity +4 | +30 / +2 |
| Greater `<el>` | stone + 1 Heart | 40 | affinity +7 | +50 / +4 |

⭐ **Elemental gems are stronger than universal ones** (§6d.3's anti-meta fix
1), and ⭐ **a second identical gem on the same piece gives half** (fix 2).
Both, as SYSTEMS §3.5 allowed. ❓ Ship universal gems at all in the first
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
  piece of equipment") — the one new recipe shape.
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

1. **Model + overlay** (one lane): Core/Heart motes, `enchantId`/`socketed`
   read by `Equipping.modifiersOf`, the gem and enchant tables, aspected drop
   roll, tests at the caps. No UI.
2. **Recipes** (one lane): refine ×48, transmute ×3, salvage, cut ×36 (12
   elements × 3 tiers), the Jewelry ladder below L45. Value-conservation and
   §8.7 pricing re-pinned.
3. **Surfaces** (one lane): Enchant… and Socket… on the item dialog, salvage
   picker, stat lines. Christian verifies in the browser.
4. **Re-sim gate** before Greater enchant and Greater gem numbers are final
   (`tool/balance_probe_test.dart` with a full Greater kit).

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
