# Celestial Quarter — Content Contract (items & economy)

Status: 📝 **draft, for red-pen.** Written 2026-09-22 against `ae9743c`.
⚠️ **Nothing here is built.** This document is the item/economy half of the
Celestial quarter; a parallel lane owns the **rosters** (creature names,
archetypes, moves). The two join by **zone + drop role**, never by creature id
— see §0.4.

**Scope:** the seven Celestial zones, Lv 30–47 — **76 item definitions**,
**28 recipes**, **17 gather nodes**, one tier gate (Rimeholt).

> ### How to read this
>
> | Mark | Meaning |
> |---|---|
> | 📝 | **A number the designer is expected to want to tune.** Every 📝 is a knob; nothing structural hangs on its exact value |
> | ⭐ | The reasoning worth preserving through a rewrite |
> | ⚠️ | A trap, an invariant, or a place a builder will get it wrong |
> | ✅ | Canon — taken from a doc or from shipped code, not invented here |
> | ⏳ | A **banking** material: gatherable in this quarter, spendable in the next |
>
> ⚠️ **Every id in this document is final and unique** (§7.2 proves it against
> the 610 ids shipped today). A builder who invents an id has broken the
> contract; a builder who renames one has broken a save.
>
> ⚠️ **This is a KINETIC_CONTRACT-shaped document and mirrors its section
> numbering exactly.** Where a section here says "unchanged", read the Kinetic
> section of the same number — it is still the standard.

---

## 0. What is canon and what is proposed

### 0.1 Canon — do not change without changing the source doc

| Fact | Source |
|---|---|
| Seven zones, ids, bands, kinds and elements | `lib/game/world.dart` — `the_kiln_desert` 30–34 Solar · `the_mirrormere` 32–37 Lunar · `starfall_basin` 34–39 Astral · `tidewrack_shoals` 36–40 Lunar+Aqua · `the_sunless_reach` 38–42 Solar+Lunar · `the_shattered_orrery` 40–44 Astral+Electro 🏰 · `the_glass_archive` 43–47 Solar+Arcane 🏰 |
| Zone themes and the quote each was recovered from | ENEMIES §2e |
| Creature names, archetypes, boss pools | ENEMIES §2e/§2g — ⚠️ **the roster lane's**, not this document's |
| The HP curve | `MageState.scaledMaxHp` = `round(100 × 1.04^(L−1))` |
| Raw move damage stays in the Whispering Woods band | CONTENT_CHECKLIST; re-verified in §1.3 |
| **Ironwood 30 (Kiln Desert) · Bloodwood 35 (Mirrormere) · Ebony 40 (Sunless Reach)**, with their gem-slot ranges | ITEMS §9b.6 — the wood ladder names these three zones by name |
| **Enchanting's station is Meridian, L36** | `world.dart`; ITEMS §6a.1 |
| **Jewelry's station and its learning stay at Rimeholt, L45** | `world.dart`; ITEMS §9b.8 ruling 9; KINETIC §8.1 |
| Rimeholt's gate is *"A Celestial Totem charged with the Solar, Lunar and Astral essences"* | `world.dart` — the gate prose |
| Gates are **shown, not spent**; `GameLocation.gateItemIds` + `PlayerProfile.openedGates` | `world.dart`, `GameState.gateRefusal` (ruling, Christian 2026-09-21) |
| Craft XP = `Σ input counts × (4 + 2 × gate)` | `Skills.xpForRecipe` |
| Node XP = `9 + 2 × (zone.minLevel − 1)` | `GatherNodes`, ITEMS §9b.7b |
| Hides and motes are **kill-only**, never a node | ITEMS §9b.7b |
| Materials: 2 per pure zone, 3 per hybrid | ITEMS §9b.8 ruling 7 |
| Potion grammar `{Ingredient} {Form}`; **Draught = flat heal, Tonic = over-time, Rations are not usable in a fight** | ITEMS §9b.8 ruling 6 |
| **Heals are FLAT** — `ItemEffect.heal` is a number, not a percentage | ruling 2026-09-21, `item_def.dart` |
| Mote vendor values: Dust 2 · Shard 25 · Crystal 150, uniform across elements | ECONOMY §14c |
| Quarterstaff is `twoHanded`; a two-hander and an off-hand cannot be worn together | ruling 2026-09-21, `EquipmentDef.twoHanded` |
| Deflect amount hard cap **50%** for players | ITEMS §4.1a |
| Hit chance floors at 10 and **caps at 100** | `CombatClamps` — ⚠️ see §2.1a |

### 0.2 The standing rulings this contract encodes (Christian, 2026-09-22)

1. **Full catalogues for all fifteen remaining zones, gear included**, on the
   Kinetic pattern extrapolated — **provisional under Phase 8**. §§3–6.
2. **Gear rarities stay inside common / rare / epic.** Uncommon, Mythic and
   Legendary stay absent from equipment; `uncommon` survives only where it
   already lives, on Crystal motes and on gem-grade materials (§8 of ITEMS).
   ⚠️ **No sets and no enchants are invented here** — SYSTEMS §3 has not
   ruled Phase 8. Every zone carries a 📝 *Phase 8 may add…* hook instead.
3. **The potion vocabulary is settled** — §3.5 and §5.4. Three forms, no new
   `ItemEffect` field, consistent with the shipped five.
4. **Sockets follow ITEMS §9b.6's per-wood range, taking the bottom of the
   range floored at the previous tier's count** (§4.1a). Gems themselves are
   Phase 8 and are **not** in this quarter.
5. **The tier gate is a charged Totem, not a collection.** §3.4 — and that is
   why it does not re-open KINETIC §8.6.

### 0.3 What this contract deliberately does NOT specify

- **Creature names, archetypes, moves, move ids, lore and art.** The roster
  lane owns all of it. This document names **drop roles** (§0.4).
- **Set bonuses, enchants, gems, gem sockets' contents.** Phase 8, SYSTEMS §3.
- **Arrival / beat / epilogue copy** — `world.dart`'s and WORLD_DESIGN's.
- **Shop stock and per-town price modifiers** — ECONOMY_CONTRACT §2/§4. This
  document authors `ItemDef.value` (the base) and nothing downstream of it.
- **Dungeon structure.** 🏰 on two zones is `LocationKind.dungeon` and nothing
  in this quarter's data may assume a descending run (KINETIC ruling 4).

### 0.4 ⭐ The join with the roster lane — by zone and role, never by creature

The two lanes are being written at the same time and must not block each
other. **This document never names a creature.** Every drop table below is
written against the five **roles** the shipped bestiaries already use:

| Role | What the roster lane must supply | What this document supplies |
|---|---|---|
| `hide` | the one or two commons that are big enough to skin | the hide's id, its Tailoring tier, its value |
| `mote` | every common (all of them drop the zone's dust) | the mote ids, per §3.2 |
| `material` | the commons that carry the zone's gatherable materials | the material ids, counts and weights |
| `key` | the **boss pool**, guaranteed | the essence / totem ids, §3.4 |
| `unique` | the **mini pool** (rare) and **boss pool** (epic) | the item ids and their stats |

⚠️ **A zone's `_commonAlways`, `_miniDrops` and `_bossDrops` are shared
tables** (the shipped shape). The roster lane attaches them; this document
defines what is in them. Neither lane needs the other's file to compile.

---

## 1. The baseline statline

### 1.1 The formula — read off the shipped engine, not invented

Unchanged from KINETIC §1.1, and it is still the single most important thing
a builder can get wrong:

```
maxHp(archetype, L)  = round( round(100 × 1.04^(L−1)) × archetype.hpScale )
damage(archetype, L) = round( rawRoll × 1.04^(L−1) × archetype.damageScale )
```

⭐ **The extrapolation to L30–47 is, again, to do nothing.** A zone's higher
band arrives through the **encounter level**, never through bigger raws.

### 1.2 Worked HP table — the Celestial band

`scaledMaxHp` at the three sample levels: **L30 = 312 · L38 = 427 · L47 = 607.**
(`1.04^29 = 3.1187`, `1.04^37 = 4.2681`, `1.04^46 = 6.0748`.)

| Archetype | Tier | HP× | DMG× | **HP @30** | **HP @38** | **HP @47** |
|---|---|---|---|---|---|---|
| Drudge | common | 0.80 | 0.70 | 250 | 342 | 486 |
| Skirmisher | common | 0.70 | 1.15 | 218 | 299 | 425 |
| Lasher | common | 0.85 | 1.00 | 265 | 363 | 516 |
| Glasswing | common | 0.50 | 1.70 | 156 | 214 | 304 |
| Adept | common | 1.00 | 0.90 | 312 | 427 | 607 |
| Sentinel | common | 1.25 | 0.70 | 390 | 534 | 759 |
| Bruiser | common | 1.15 | 1.10 | 359 | 491 | 698 |
| Blighter | common | 1.00 | 0.60 | 312 | 427 | 607 |
| **Siphon** ⭐ | common | 0.95 | 0.85 | 296 | 406 | 577 |
| Champion | mini | 1.70 | 1.20 | 530 | 726 | 1032 |
| Redoubt | mini | 2.20 | 0.85 | 686 | 939 | **1335** |
| Executioner | mini | 1.20 | 1.90 | 374 | 512 | 728 |
| Hexer | mini | 1.60 | 0.75 | 499 | 683 | 971 |
| Juggernaut | boss | 3.60 | 1.40 | 1123 | 1537 | **2185** |
| Tyrant | boss | 2.60 | 1.70 | 811 | 1110 | 1578 |
| Aspect | boss | 2.60 | 1.50 | 811 | 1110 | 1578 |

⭐ **The Siphon returns, and it was held back for exactly this.** ENEMIES §2f
pulled it out of half the game *"so a shock that happens in half the zones is
not a shock"*; ENEMIES §2e then fields one in The Mirrormere (Undershine),
Tidewrack Shoals (Lowwater Thing) and The Glass Archive (Palimpsest). Its row
is new to a contract and is computed here from the shipped constants.

📝 **The number most worth a second look is 2185** — a Juggernaut at the top of
this quarter. KINETIC §1.2 already flagged 1080 at L29; the same coefficient at
L47 is 3.6× a level-47 player's whole bar, met with a best-in-slot loadout that
adds 23% health (§2.6). 📝 The lever is the same one KINETIC named: either the
coefficient or the zone the Juggernaut is placed in.

### 1.3 The raw-damage authoring table 📝 — ⚠️ unchanged, and that is the point

⚠️ **This table is byte-for-byte KINETIC §1.3.** It does not grow. Reproduced
here because a builder authoring a level-47 boss will want to believe it does.

| Cost | Shape | **Common** | **Mini** | **Boss** |
|---|---|---|---|---|
| 1 | single | 5–8 📝 | 6–9 📝 | 6–9 📝 |
| 1 | multi | 3–5 ×2 | — | — |
| 1 | shield | — | — | 12–18 / 20–26 |
| 2 | single | 11–15 📝 | 12–17 📝 | 13–19 📝 |
| 2 | multi | 4–6 ×3 | 4–6 ×3 | — |
| 2 | shield | 16–22 | 18–24 | — |
| 3 | single | 18–23 📝 | 25–33 📝 | 24–31 📝 |
| 3 | multi | 4–6 ×4 | — | — |
| 3 | shield | — | 30–40 | 40–52 |
| 4 | single | — | 26–34 📝 | 30–38 📝 |
| 4 | shield | 28–36 | — | 44–56 |
| 5 | single | 30–40 📝 | 46–60 📝 | 42–54 📝 |

⚠️ **Hard ceiling: ≤ 60 raw on any one move, ≤ 12 raw per charge.**
⚠️ **The Executioner's cost cap stays at 4, as KINETIC §1.3 lowered it.** At
L47 the mini five-charge raw would land 884–1153 against a 607 HP bar — not a
two-cast kill, a one-shot with change. At cost 4 it lands 300–392, which is the
ratio the archetype is supposed to have.
⭐ **The Siphon's row:** 2 moves at cost 1–3, table numbers, ⚠️ **both carrying
lifesteal** — that is the archetype, and ENEMIES §2.5's *"it takes what is
yours"*. At L47 its dear move lands 93–119 and returns a fraction of it.

### 1.4 Effective damage — what the player actually takes

Raw × `1.04^(L−1)` × `damageScale`, dearest affordable move only.

| Archetype | dear | @30 | @38 | @47 |
|---|---|---|---|---|
| Siphon | c3 | 48–61 | 65–83 | 93–119 |
| Bruiser | c5 | 103–137 | 141–188 | 200–267 |
| Glasswing | c3 (−35%) | 117–151 | 161–207 | 228–295 |
| Executioner | c4 | 154–201 | 211–276 | **300–392** |
| Juggernaut | c5 | 183–236 | 251–323 | 357–459 |
| Tyrant | c5 | 223–286 | 305–392 | **434–558** |

Player HP at the same levels: **312 · 427 · 607**, plus a best-in-slot gear
budget of **+141 HP at L47** (§2.6).

📝 **Tyrant c5 at L47 = 434–558 into a 607 HP bar** — 72–92% of a naked bar,
58–75% of a geared one. That is the same proportion KINETIC flagged at L29 and
it has not got worse; the gear budget grew with it, which is §2.6 working.

### 1.5 Move naming and voice ✅

Unchanged: **moves are verbs.** ENEMIES §3.3/§3.3a. The roster lane's problem,
noted here only so the two lanes do not disagree about whose it is.

### 1.6 Adventure shape ✅

`commonsPerSectionFor(MagicTier.celestial)` governs; ⚠️ **read it, do not
assume it equals the Kinetic 3.** Nothing in this document depends on the
answer — gather nodes are one per section and the node counts in §6 are per
zone, not per section.

---

## 2. Combat stats — the quarter's own lane, on both sides

✅ Crit, dodge and deflection arrived in the Kinetic quarter (KINETIC §2). This
quarter does not introduce a seventh stat. What it introduces is **six more
elements with a stat lean**, and the discovery that **one of the six stats has
a ceiling the Kinetic ladder had almost reached** (§2.1a).

### 2.1 The mechanics, as shipped — unchanged

```
hitChance = clamp( 80 + attackerAccuracy − defenderDodge − blind , 10 , 100 )
on crit   : perHit × (100 + 50 + critDamage) / 100
on deflect: taken = damage × (1 − deflectAmount/100)   (player design cap 50; engine clamps 90)
```

⚠️ **The three inert-stat traps of KINETIC §2.1 all still apply**, and every
line in §4 pairs `critChance` with `critDamage` and `deflectChance` with
`deflectAmount`.

### 2.1a ⚠️ NEW FINDING — accuracy has a hard ceiling, and Kinetic nearly hit it

`CombatClamps.hitChanceCapPercent == 100`. Against a **0-dodge** defender —
which the Adept yardstick is, deliberately (§2.3) — the base is 80, so
**+20 accuracy is a guaranteed hit and every point above 20 does nothing.**
ENEMIES §2.5 caps *enemy* dodge at 10, so the absolute useful ceiling against
any enemy in the game is **+30**, and that is before Blind.

Measured against the shipped catalogues:

| Loadout | Accuracy total | Wasted vs a 0-dodge enemy |
|---|---|---|
| Q1 best-in-slot @14 | 9 | 0 |
| Q2 crafted-only @29 (Rowan staff + Tussock hood) | 12 | 0 |
| **Q2 best-in-slot @29** | **18** | 0, with **2 points of headroom left** |

⭐ **So the accuracy ladder cannot keep climbing at one point per material
tier, and this contract stops it.** §4.1a holds the weapon ladder's accuracy at
9 → 12 across five more wood tiers instead of 9 → 13, hoods at 5 → 6 instead of
5 → 8, and **budgets a full best-in-slot loadout to ≤ 30 accuracy** (§7.5).
📝 The alternative — let enemy dodge climb above ENEMIES §2.5's cap of 10 in
the Celestial and Ethereal bands so accuracy keeps paying — is a **roster**
change and a bigger one; it is named here so the designer can choose it
instead.

⚠️ **Consequence for the §2.6 measurement:** every loadout in this band reaches
the clamp, so accuracy stops being a *differentiator* between crafted and
best-in-slot. It raises the floor rather than the ceiling, which is the
opposite of what the four Kinetic weapon tiers were doing.

### 2.1b ⚠️ NEW FINDING — deflect amount sums, and three pieces breach the design cap

`ItemModifiers.operator+` sums every field. Three deflect pieces at the Kinetic
epics' magnitudes (25 + 25 + 28) put a player at **78% deflect amount**, past
ITEMS §4.1a's *"hard cap 50% for players"* and stopped only by the engine's
90% clamp — which is a different number for a different reason.

⭐ **The rule this contract adopts, stated once so forty items obey it:**

> **Deflection lives on the crafted armour set's gloves, and on exactly ONE
> drop piece per quarter.** Chance may climb; amount may not. The assembled
> best-in-slot total must satisfy `Σ deflectAmount ≤ 50`.

Celestial's one deflect drop is **`the_noon_hour`** (The Glass Archive — Arcane
is the deflection element, §2.5a), and its amount is **14**. ⚠️ **That 14 is not
a free number: it is chosen against the Ethereal quarter's pieces**, because a
level-60 player may wear a Celestial hat. The worst legal assembly across both
quarters is Unleft gloves 26 + a deflect hat 14 + `bedrock_greaves` 10 = **50
exactly** (ETHEREAL §2.1b runs the same arithmetic from the other side). Within
this quarter alone the total is 12/14 alone, or 26/38 with the Wrackcotton
gloves — EV 9.9% at the top (§2.6).

### 2.2 Where the enemy stat block lives — unchanged ✅

KINETIC §2.2's ruling stands: the block is on `EnemyDef`, reaching the duel
through `OpponentDriver.opponentCombatStats`, and `RemoteDuelDriver` returns
`none`. ⚠️ If the Kinetic build has not landed that seam yet, **this quarter
depends on it** and should say so in its plan row rather than duplicate it.

### 2.3 Enemy combat stats by archetype 📝 — continuing KINETIC §2.3

The Kinetic rows are unchanged. **One row is added** — the Siphon, which no
Kinetic zone fielded.

| Archetype | acc | dodge | crit % | crit dmg | defl % | defl amt | EV defl | Reads as |
|---|---|---|---|---|---|---|---|---|
| Drudge | −10 | 0 | 0 | 0 | 0 | 0 | — | unchanged |
| Skirmisher | +5 | 8 | 0 | 0 | 0 | 0 | — | unchanged |
| Lasher | 0 | 0 | 15 | −20 | 0 | 0 | — | unchanged |
| Glasswing | 0 | 0 | 20 | +30 | 0 | 0 | — | unchanged |
| Adept | 0 | 0 | 0 | 0 | 0 | 0 | — | the yardstick, still blank |
| Sentinel | 0 | 0 | 0 | 0 | 25 | 20 | 5.0% | unchanged |
| Bruiser | −8 | 0 | 8 | +25 | 0 | 0 | — | unchanged |
| Blighter | +8 | 0 | 0 | 0 | 0 | 0 | — | unchanged |
| **Siphon** 📝 | **+6** | **6** | 0 | 0 | 0 | 0 | — | ⭐ *"it takes what is yours"* — it must **connect** to steal, so accuracy; it must **survive** to keep stealing, so a little dodge. ⚠️ **No crit**: a lifesteal crit heals it for the crit too, and a 0.95-HP body that can double-heal off one roll is the stalemate ENEMIES §2.2 already fears |
| Champion | +6 | 0 | 10 | 0 | 0 | 0 | — | unchanged |
| Redoubt | 0 | 0 | 0 | 0 | 35 | 30 | 10.5% | unchanged |
| Executioner | +8 | 0 | 12 | +40 | 0 | 0 | — | unchanged |
| Hexer | +8 | 10 | 0 | 0 | 0 | 0 | — | unchanged |
| Juggernaut | 0 | 0 | 0 | 0 | 25 | 35 | 8.8% | unchanged |
| Tyrant | +5 | 5 | 10 | +15 | 10 | 15 | 1.5% | unchanged |
| Aspect | per zone | | | | | | | §2.4 |

⚠️ **Enemy dodge stays capped at 10** (ENEMIES §2.5) — the Siphon's 6 sits
below the Skirmisher's 8 and the Hexer's 10, which is where it belongs.

### 2.4 The Aspects — element-dependent, per ENEMIES §2.5

Six of this quarter's ✨ bosses are Aspects (ENEMIES §2g). Each leans entirely
on its element's own passive, which is why each must be **single-element**.

| Boss (roster lane) | Zone | Element | Stat block 📝 | Why |
|---|---|---|---|---|
| **Solar Deity** ✨ | The Kiln Desert | solar | acc **+25**, crit 10 / +10 | ⭐ Solar's side-effect is **Blind**, and Solar's gear affinity is accuracy (§2.5a). An Aspect of the sun does not miss and takes your sight while it does not |
| **Luna Plena** ✨ | The Mirrormere | lunar | **dodge 10**, defl 20 / 20 (EV 4.0%), acc 0 | ⭐ Lunar is misdirection: the moon in the water is not where the moon is. Dodge at the ENEMIES §2.5 cap, and it is the one place the cap should be spent |
| **The Undertow** ✨ | Tidewrack Shoals | **aqua** | defl 30 / 30 (EV 9.0%), dodge 4 | ⚠️ **Single-element on the Aqua half**, deliberately — Tidewrack is Lunar+Aqua and Waterlogged is what "takes it back" means. ⭐ Deliberately the same shape as Frostfell's *The Road Under*, one tier up: two Aqua Aspects, one reading |
| **The Last Light** ✨ | The Sunless Reach | **solar** | acc +20, crit 20 / +25 | ⭐ ENEMIES §2f's one blessed doubling: the zone fields **two** Aspects and the pair *is* the theme. The Solar one is the bright, accurate, spiky half |
| **The First Dark** ✨ | The Sunless Reach | **lunar** | dodge 10, defl 25 / 25 (EV 6.3%) | …and the Lunar one is the half you cannot find or hurt. ⚠️ **They must not share a stat block** or the doubling says nothing |
| **What Is Left Of It** ✨ | The Glass Archive | **arcane** | defl 30 / 25 (EV 7.5%), acc +8 | ⭐ Arcane's gear affinity is deflection (§2.5a), and Arcane Knowledge is permanent and universal — what is left of a record is the part that would not come off |

⚠️ **`the_kiln_desert`, `the_mirrormere` and `starfall_basin` are the quarter's
three pure zones**, so the three Celestial elements each keep exactly one pure
region — the same audit KINETIC §4.5 ran and passed.

### 2.5 Player gear — where the lines live

⭐ **The distribution rule, restated with six more elements in it:**

| Line | Lives on | Because |
|---|---|---|
| **Flat HP** | Tailoring **robe / leggings**, with a token on boots and gloves; the HP epics | Q1's shape, unchanged through four quarters |
| **Accuracy** | Tailoring **hood**, every weapon, the Solar drops | ⚠️ and it now **stops climbing** — §2.1a |
| **Dodge** | Tailoring **boots**, the Aero and **Lunar** drops | §2.5a |
| **Deflect chance + amount** | Tailoring **gloves**, and ⚠️ **exactly one drop per quarter** | §2.1b |
| **Crit chance + damage** | every weapon from Rowan up, the Electro/Pyro and **Astral/Umbra** drops | §2.5a |
| **Shield strength % / healing received %** | the Aqua and **Sanctus** drops | §2.5a — ⭐ the support lane, which nothing else owns |

### 2.5a ⭐ NEW — the elemental affinity table, completed

ITEMS §4.1a names five affinities (*"Aero favours dodge, Geo deflection,
Electro crit chance, Pyro crit damage, Solar accuracy"*) and stops. Seven
elements had none, and this quarter ships gear for four of them. 📝 **Proposed,
and the whole table is one ruling:**

| Tier | Element | Affinity | Precedent / reading |
|---|---|---|---|
| Primal | Aqua | **shield strength %** | ✅ shipped: Brookstone Pendant 10, The Holdfast 15 |
| Primal | Pyro | crit damage | ✅ ITEMS §4.1a |
| Primal | Flora | **healing received % / regrow** | ✅ shipped: Wickerbound Ring 10, The Charlock regrow 2 |
| Kinetic | Electro | crit chance | ✅ ITEMS §4.1a |
| Kinetic | Aero | dodge | ✅ ITEMS §4.1a |
| Kinetic | Geo | deflection | ✅ ITEMS §4.1a |
| Celestial | Solar | accuracy | ✅ ITEMS §4.1a |
| Celestial | **Lunar** | **dodge** 📝 | ⭐ inherits **Aero**. The moon is where you are not looking; Lunar's own lock is Blind, so dodge is the one stat that is *not* its side-effect |
| Celestial | **Astral** | **crit chance** 📝 | ⭐ inherits **Electro**. Astral Alignment is the pierce; a crit is the same idea on the other axis — something arriving whole |
| Ethereal | **Sanctus** | **shield strength % + healing received %** 📝 | ⭐ inherits **Aqua and Flora at once** — the support pair, which no element owned alone |
| Ethereal | **Umbra** | **crit damage** 📝 | ⭐ inherits **Pyro**. Creeping Dark is growth toward one enormous consequence |
| Ethereal | **Arcane** | **deflection** 📝 | ⭐ inherits **Geo**. Knowing what is coming is how you take less of it |

⭐ **The structure is the point, and it is worth more than the individual
assignments: a higher-tier element does not invent a seventh stat — it takes a
lower element's lean and sharpens it.** That gives six new elements a gear
identity for free, keeps §4.1a's *"flavour, not mechanics"* promise, and makes
The Sealed Garden (Flora + Sanctus, ETHEREAL §4.4) the zone where the
inheritance is stated out loud.
⚠️ **Sanctus is the one element that gains two**, because Aqua's and Flora's
leans are the same lane read twice. 📝 If that is one too many, drop
`healingReceivedPercent` and leave Sanctus the shields.

### 2.6 ✅ "Gear ≈ ten levels" — re-anchored for 30–47

✅ **Ruling 8.2 (Christian, 2026-08-20) stands verbatim:** *"a fully geared L30
with best-in-slot should be similar in power to a naked L40, more or less."*
It is a **best-in-slot** target measured at a quarter's top, not a crafted-gear
target — KINETIC §2.6.

⚠️ **KINETIC §2.6's note 3 instructed exactly this:** *"Whoever re-measures
this at Q3's numbers should re-derive it fresh rather than extrapolate Q2's
ratios."* So the method below is stated in full rather than inherited.

**The method.** Ten levels is `1.04^10 = 1.480` on HP *and* on damage, so the
target is `Ghp × Gdmg = 1.04^20 = 2.191`, and
`levels = ln(Ghp × Gdmg) / (2 ln 1.04)`.

```
reference cast   Ruin, chargeCost 4, DamageEffect(44, 53)  → raw mid 48.5   ✅ a shipped player spell
base(L)          48.5 × 1.04^(L−1)
Gacc             min(100, 80 + Σaccuracy) / 80             ⚠️ CLAMPED — §2.1a
Gflat            (base + damagePerCast + 4 × damagePerCharge) / base
Gcrit            1 + Σcrit% /100 × (50 + ΣcritDmg) / 100
Gdmg             Gacc × Gflat × Gcrit
Ghp              (scaledMaxHp(L) + ΣmaxHpBonus) / scaledMaxHp(L)  ×  1 / (1 − Σdefl% × Σdeflamt)
Gdodge           80 / (80 − Σdodge)                        ⚠️ deliberately OUTSIDE the headline — see below
```

⭐ **The method is validated against the Kinetic contract's own published
number before it is used here.** Applied to the Kinetic best-in-slot loadout
(Uplight + Rowan Knot + The Long Cooling + The Long Lean + Tussock leggings and
boots + Groundfault Grips + The Given Weight + Firstmelt Loop), it returns
**10.71 levels** against KINETIC §2.6's published **10.7**. The reference cast
and the clamp are therefore the same ones that document used, whether or not it
said so.

| Loadout | Ghp | Gdmg | **≈ levels** | with dodge ⚠️ |
|---|---|---|---|---|
| Q2 crafted-only @29 (Rowan + Tussock) | 1.159 | 1.299 | 5.21 | 5.70 |
| **Q2 best-in-slot @29** ✅ published 10.7 | 1.476 | 1.570 | **10.71** | 12.60 |
| Q3 crafted-only @47 (Ebony staff + Wrackcotton) | 1.149 | 1.365 | **5.73** | 6.56 |
| **Q3 best-in-slot @47** (§4's drops + Ebony wand/knot + Wrackcotton leggings) | 1.253 | 1.729 | **9.86** | 12.12 |

⭐ **Three findings the designer should see together.**

1. ✅ **The invariant passes.** Celestial best-in-slot ≈ **9.9 levels** against
   a verbatim ten-level target, and crafted-only ≈ 5.7, which is §9b.4a's
   *crafted-is-the-floor* working as designed. The quarter is neither
   over- nor under-budgeted.
2. ⚠️ **Dodge is an uncounted third multiplier, and the published invariant has
   never included it.** A dodged attack deals zero, so `Gdodge = 80/(80−dodge)`
   belongs in effective health — and adding it moves Kinetic best-in-slot from
   10.7 to **12.6** and this quarter's from 9.9 to **12.2**. 📝 **This is a
   ruling, not a bug:** either the invariant's definition says dodge is
   excluded (and the real gear gap is ~12 levels, not 10), or dodge budgets
   must come down by about a third across all four quarters. This contract
   **holds best-in-slot dodge at 13** (Kinetic's was 11) so the two quarters
   are comparable either way, and does not decide the ruling.
3. 📝 **Accuracy has stopped contributing.** Both Celestial rows reach the
   `hitChance` clamp, so `Gacc = 1.25` for crafted *and* for best-in-slot;
   in Q2 it was 1.15 vs 1.225. Accuracy is now a **floor-raiser**, not a
   differentiator (§2.1a), and every point the quarter spends on it beyond
   +20 is spent on anti-dodge insurance.

---

## 3. Materials, motes, consumables and id conventions

### 3.1 The eighteen materials

✅ 2 per pure zone, 3 per hybrid (ITEMS §9b.8 ruling 7).

| id | Name | Zone | Consuming skill | Tier | Gathered by | Node? |
|---|---|---|---|---|---|---|
| `ironwood_log` | Ironwood Log | the_kiln_desert | Woodcarving | 5 | Felling | ✅ |
| `glasswort` | Glasswort | the_kiln_desert | Potions & Alchemy | 5 | Foraging | ✅ |
| `bloodwood_log` | Bloodwood Log | the_mirrormere | Woodcarving | 6 | Felling | ✅ |
| `mirrorflax` | Mirrorflax | the_mirrormere | Tailoring | 5 | Foraging | ✅ |
| `skyiron_ore` | Sky-Iron Ore | starfall_basin | Metalworking | 5 | Mining | ✅ |
| `fallstone` | Fallstone | starfall_basin | Enchanting | 5 | Mining | ✅ |
| `wrackcotton` | Wrackcotton | tidewrack_shoals | Tailoring | 6 | Foraging | ✅ |
| `nacre` ⏳ | Nacre | tidewrack_shoals | Jewelry | 6 | Mining | ✅ |
| `drownling_hide` | Drownling Hide | tidewrack_shoals | Tailoring | 6 | — | ⚠️ **kill-only** |
| `ebony_log` | Ebony Log | the_sunless_reach | Woodcarving | 7 | Felling | ✅ |
| `duskcap` | Duskcap | the_sunless_reach | Potions & Alchemy | 6 | Foraging | ✅ |
| `eclipse_opal` ⏳ | Eclipse Opal | the_sunless_reach | Jewelry | 7 | Mining | ✅ |
| `orrery_scrap` | Orrery Scrap | the_shattered_orrery | Metalworking | 7 | Mining | ✅ |
| `arcsalt` | Arcsalt | the_shattered_orrery | Potions & Alchemy | 7 | Foraging | ✅ |
| `sidereal_glass` ⏳ | Sidereal Glass | the_shattered_orrery | Jewelry | 7 | Mining | ✅ |
| `sunbleach_lichen` | Sunbleach Lichen | the_glass_archive | Potions & Alchemy | 8 | Foraging | ✅ |
| `aetherglass` ⏳ | Aetherglass | the_glass_archive | Jewelry | 8 | Mining | ✅ |
| `palimpsest_vellum` | Palimpsest Vellum | the_glass_archive | Tailoring | 7 | — | ⚠️ **kill-only** |

⏳ **Four materials bank, and all four bank for the same reason Kinetic's three
did: Jewelry's station and learning stay at Rimeholt, L45** (§8.1 of KINETIC,
re-confirmed). `nacre`, `eclipse_opal`, `sidereal_glass` and `aetherglass` are
gatherable across 36–47 and spendable from 45 — ⭐ the *shortest* banking window
any quarter has had, because Rimeholt is the very next town. **The Ethereal
contract's §5 spends all four, plus the Kinetic three** (`quarry_jasper`,
`everice`, `obsidian`), which is the payoff KINETIC §8.1 promised.

⭐ **`fallstone` is the first Enchanting material with a consumer in the same
quarter it drops in**, and it settles the older debt too: KINETIC §3.1 banked
`hum_quartz` *"purely on schedule — Enchanting's station is Meridian at L36."*
Meridian opens at 36, Starfall Basin (34–39) is one road away, and
`craft_celestial_totem` (§5.1 #28) spends Hum Quartz ×3 and Fallstone ×2. ⚠️
**That recipe is the only thing in the game that spends Hum Quartz.** If it
moves, the Kinetic banking clause breaks with it.

⚠️ **Two materials are kill-only and must have no node** (ITEMS §9b.7b):
`drownling_hide` and `palimpsest_vellum`. ⭐ **A palimpsest is a hide** — a page
scraped clean and written on again — so the vellum obeys the hide rule by
being one, not by exception.

⚠️ **The Kiln Desert has no Tailoring material and The Shattered Orrery has no
wood**, and both absences are deliberate: ITEMS §9b.6 assigns the three woods
of this band to Kiln Desert, Mirrormere and Sunless Reach by name, and a
machine that has been computing for centuries does not grow cloth.

### 3.2 The twelve new motes

Four new families × three tiers. ✅ Rarity from ITEMS §8: Dust and Shard are
Common, Crystal is Uncommon. ✅ Values from ECONOMY §14c: **2 / 25 / 150**,
uniform across elements.

| id | Name | Element | Tier | Rarity | Defined in |
|---|---|---|---|---|---|
| `solar_dust` / `solar_shard` / `solar_crystal` | Solar Dust · Shard · Crystal | solar | dust / shard / crystal | common · common · **uncommon** | the_kiln_desert |
| `lunar_dust` / `lunar_shard` / `lunar_crystal` | Lunar … | lunar | " | " | the_mirrormere |
| `astral_dust` / `astral_shard` / `astral_crystal` | Astral … | astral | " | " | starfall_basin |
| `arcane_dust` / `arcane_shard` / `arcane_crystal` | Arcane … | arcane | " | " | **the_glass_archive** |

⭐ **The mote lives with the zone that first yields it** — the shipped rule, and
it is why **Arcane's family is defined in a Celestial dungeon rather than in
the Ethereal quarter's pure Arcane zone.** The Glass Archive is 43–47; The
Collapsed Academy is 50–54. A player meets Arcane Dust seven levels before they
meet the school that lost it. ⚠️ **The Ethereal contract must not re-define
`arcane_*`**; it imports them, exactly as Frostfell imports `aqua_*`.

⭐ **Cross-quarter mote references, all deliberate:** Tidewrack Shoals pays in
`lunar_*` **and Q1's `aqua_*`**; The Shattered Orrery pays in `astral_*` and
**Q2's `electro_*`**. Two of the seven zones hand a player a reason to care
about a mote family they stopped seeing twenty levels ago.

✅ **No Core-tier motes in this quarter, and none in the Ethereal one either.**
⚠️ **This is a knowing departure from ITEMS §9's band table**, which puts Core
and Heart at 45–50, and it is flagged rather than hidden: Core's only consumers
are a Standard gem (ITEMS §6d, **Phase 8, unruled**) and the Concordant Crown
at Zenith (out of scope for both contracts). A Core that drops essentially
never and buys nothing is noise, not a ladder rung — the same reasoning KINETIC
§3.2 used. ❓ **Ruling wanted:** ship Core with Phase 8's gems, or ship it here
as a pure collectible?

### 3.3 The consumable ladder — ⚠️ THE KINETIC §9 DEBT, SETTLED

KINETIC §9 left the potion vocabulary as a fast-follow and SYSTEMS §3 decision
7 left it open. ✅ **Ruled (Christian, 2026-09-22): settle it now.**

⭐ **The vocabulary is three forms and no new engine field.** `ItemEffect`
already has exactly the two shapes the grammar needs, and the third is a kind,
not a field:

| Form | Kind | Effect shape | Usable | ITEMS §9b.8 ruling 6 |
|---|---|---|---|---|
| **Ration** | `ConsumableDef` | `heal: N` | between encounters only | ✅ *"Rations are not usable in a fight"* |
| **Draught** | `BeltableDef` | `heal: N` | in a duel, **costs the turn** | ✅ *"Draught is always a flat heal"* |
| **Tonic** | `BeltableDef` | `healPerTurn: N, healTurns: 3` | in a duel, ticks; out of combat applies in full | ✅ *"Tonic is always over-time"* |

⚠️ **Nothing else is invented.** The **Antidote** and the **offensive potion**
stay deferred — they need `ItemEffect` vocabulary the engine does not have, and
SYSTEMS §3.7 has not ruled what the offensive one does. `hoarlichen` and
`firesalt` keep banking. 📝 When Phase 8 lands them, the grammar above tells a
builder exactly what to call them: an *Antidote* is a fourth form and an
offensive potion is a fifth.

**The magnitudes.** Reading the shipped five against the player's health at
each one's home band gives the ladder's actual slope:

| Shipped | Form | Heal | Home band floor | HP there | **% of bar** |
|---|---|---|---|---|---|
| `foragers_ration` | Ration | 25 | L1 | 100 | 25% |
| `sapwort_draught` | Draught | 30 | L3 | 108 | 28% |
| `brookmint_tonic` | Tonic | 10×3 = 30 | L10 | 142 | 21% |
| `hardtack` | Ration | 60 | L15 | 173 | 35% |
| `saltwort_draught` | Draught | 75 | L17 ✳ | 187 | 40% |

✳ Stormcliff Coast was 17–22 when Saltwort was authored; the 2026-09-21 re-band
moved it to 23–28, where the same 75 is 30% of the bar. ⚠️ **That is a real
drift and it is this ladder's only inconsistency** — 📝 either re-price
`saltwort_draught` to ~100 or accept that the coast now sells an under-strength
draught. Not this contract's item to change.

⭐ **The ladder's rule, extracted and then applied:**

> **Ration = 35% of the band floor's health · Draught = 40% · Tonic = 24%
> total, paid 8% a turn for three turns.** 📝 All three percentages are knobs;
> the *ordering* is the ruling — a Draught beats a Ration because it costs your
> turn and the opponent committed blind, and a Tonic pays least because it
> pays late.

⚠️ **The ceiling check (ITEMS §6b.3):** *"healing must be worth less than an
equivalent-tier attack deals."* At L54 a Nightink Draught restores 320 against a
Tyrant's 722–929 and a player's own Ruin at ~490 — the biggest potion in the
game is two thirds of one cast. ✅ Holds at every rung.

**The Celestial rungs** (the Ethereal contract's §3.3 continues the same table):

| id | Name | Form | Kind | `ItemEffect` | Band | % of floor | Value | Source |
|---|---|---|---|---|---|---|---|---|
| `pilgrims_ration` | Pilgrim's Ration | Ration | `ConsumableDef` | `heal: 110` | 30 | 35.3% | 16 📝 | ⚠️ **drop-only**, all seven zones — the `hardtack` pattern |
| `glasswort_draught` | Glasswort Draught | Draught | `BeltableDef` | `heal: 125` | 30 | 40.1% | 55 📝 | crafted #24; drops in the Kiln Desert |
| `duskcap_tonic` | Duskcap Tonic | Tonic | `BeltableDef` | `healPerTurn: 34, healTurns: 3` | 38 | 23.9% | 70 📝 | crafted #25; drops in the Sunless Reach |
| `arcsalt_draught` | Arcsalt Draught | Draught | `BeltableDef` | `heal: 185` | 40 | 40.0% | 95 📝 | crafted #26; drops in the Orrery |
| `sunbleach_tonic` | Sunbleach Tonic | Tonic | `BeltableDef` | `healPerTurn: 42, healTurns: 3` | 43 | 24.3% | 110 📝 | crafted #27; drops in the Archive |

⚠️ **Values are not priced against the heal number** — the 2026-09-21 ruling on
`sapwort_draught` says so explicitly. They are priced against **§5.5's value
conservation**: each draught's value sits just under `Σ(inputs)` so
buy→craft→vendor cannot profit.
⭐ **Every zone's drop table carries a consumable** even though only five are
defined — `pilgrims_ration` appears on all seven, exactly as `hardtack` appears
on all six Kinetic zones.

### 3.4 The gate — the Celestial Totem ⚠️ read this before §8.6 of KINETIC

✅ **Canon:** `world.dart` gates **Rimeholt** on *"A Celestial Totem charged
with the Solar, Lunar and Astral essences, to pass the barrier above the
town."* ✅ **Canon:** the mechanism is `gateItemIds` — **shown, not spent** —
recorded once in `PlayerProfile.openedGates` (ruling, Christian 2026-09-21,
shipped and working at Pennycross).

⚠️ **KINETIC §8.6 rejected the Kinetic Sigil's *collect-three-keys* mechanism.
This is not that, and the difference is the whole design.** What the guard at
Rimeholt is shown is **one object** — a Totem — and the three essences are its
**recipe inputs**, consumed at Meridian by Enchanting. The player does not
carry three tokens to a gate; they make a thing and carry the thing.

> ✅ **RULED (Christian, 2026-09-22): the Rimeholt gate ships as a crafted,
> charged Totem.**
>
> | | |
> |---|---|
> | `gateItemIds` on `rimeholt` | `['celestial_totem']` — **one id** |
> | `celestial_totem` | `KeyDef`, `gates: 'rimeholt'`, Bound, rarity **rare**, equipLevel 1 |
> | Made by | `craft_celestial_totem` — **Enchanting**, gate 1, ⚠️ `stationRequired: true` |
> | Where | **Meridian** (L36) — the quarter's Enchanting station, and ⭐ the only place with a reason to exist otherwise |
> | Inputs | `solar_essence` ×1 · `lunar_essence` ×1 · `astral_essence` ×1 · `hum_quartz` ×3 ⏳ · `fallstone` ×2 |

⭐ **Three things this buys at once.** (1) The gate stops being a collection and
becomes a *craft*, which is what Christian's "explicitly NOT collection-based"
was asking for. (2) **Enchanting's debut has something to make** — otherwise
the skill opens at Meridian with an empty book. (3) It spends `hum_quartz`,
paying the only Kinetic banking promise that had no named consumer.

⚠️ **`stationRequired: true` is used here and nowhere else in this quarter.**
`RecipeDef`'s doc says every `true` should cite why: **a tier gate must not be
craftable in the field.** The Totem is charged at the observatory that can see
both Celestial elements' sky, or it is not charged.

**The three essences** are `MaterialDef`s, `skill: CraftSkill.enchanting`,
`rarity: rare`, `tradability: bound`, ⚠️ **kill-only, no node**, guaranteed on
their zone's **boss pool** `always` line:

| id | Name | Zone | Element | Dropped by |
|---|---|---|---|---|
| `solar_essence` | Solar Essence | the_kiln_desert | solar | boss pool, **guaranteed** |
| `lunar_essence` | Lunar Essence | the_mirrormere | lunar | boss pool, **guaranteed** |
| `astral_essence` | Astral Essence | starfall_basin | astral | boss pool, **guaranteed** |

⚠️ **The three essences do NOT count against ITEMS §9b.8 ruling 7's 2-per-pure
budget.** Precedent: `proof_of_the_woods`, `proof_of_the_brook` and
`proof_of_the_foothills` sit in Q1 catalogues and are not counted among Q1's
materials. **Gate parts are not crafting stock.**
📝 `ComponentDef` is the arguable truer kind — Bound, boss-sourced, never
gathered, and `RecipeInput`'s own doc lists components as legal inputs. It is
not used because ITEMS §3.5 defines components as *Tier III/IV set parts
(L45+)* and a level-30 gate essence is not one. **If Phase 8 broadens
`ComponentDef`, move these three.**

⚠️ **The Kinetic Sigil at Concordance is NOT this contract's.** `world.dart`
still gates Concordance on *"The Kinetic Sigil, in three parts"* with an empty
`gateItemIds`, and KINETIC §8.6 left the replacement to a fast-follow. Its
parts fall in **Kinetic** zones. 📝 The Totem shape above is the obvious
template for it — one crafted sigil at Forgeholm from three Kinetic
essences — and is offered as a proposal, not taken.

### 3.5 Id conventions ✅

| Kind | Convention | Example |
|---|---|---|
| Material / mote / consumable | plain noun | `mirrorflax`, `astral_shard`, `duskcap_tonic` |
| Crafted equipment | `<material>_<form>` | `ebony_quarterstaff`, `wrackcotton_gloves` |
| Named equipment (drops) | its own name, `properName` set | `the_noon_hour`, `sidereal_signet` |
| Recipe | `craft_<outputId>` | `craft_bloodwood_wand` |
| Gather node | `<zone prefix>_<place>` | `ts_wrackcotton_flat` |
| Zone prefixes (new, no collisions) | `kd_` `mm_` `sb_` `ts_` `sr_` `so_` `ga_` | — |

⚠️ **Crafted equipment must leave `properName` null** — the name composes from
`material + form` (ITEMS §9b.5a), and a test enforces it. **Drop-only jewelry
and boss uniques set it.**
⚠️ **Which catalogue file defines a cross-zone crafted output:** the file for
the zone supplying its **headline** material. That is why `skysteel_ingot`
lives in `starfall_basin_items.dart` and `ironwood_quarterstaff` in
`the_kiln_desert_items.dart` although it takes a Kinetic ferrule.
⚠️ **No builder edits a Q1 or Q2 catalogue file.**

### 3.6 📝 Phase 8 hooks — one per zone, and deliberately empty

SYSTEMS §3 has not ruled sets, enchants or sockets. Every zone section below
ends with a **📝 Phase 8 hook** naming what that zone would plausibly carry —
a set piece's home, an enchant's element, a gem's cut — **as a note, not a
definition.** ⚠️ **No `setId`, no `setTier`, no enchant field and no gem item
appears anywhere in this contract.** Sockets appear only as `socketCount`,
which is a shipped field with a shipped meaning (§4.1a).

---

## 4. The seven zones

Legend for every catalogue table: **Kind** is the `ItemDef` subclass · **Slot ·
Form / Material** are `EquipmentDef.slot`, `.form`, `.material` · **Equip** is
`equipLevel` · **Value** is `ItemDef.value` in gold. Every equipment row's
`salvage` returns 1–2 of its headline material unless the row says otherwise.

### 4.1 The Kiln Desert · `the_kiln_desert` · 30–34 · Solar · route

> ✅ *"The air is too thin to hold heat, so the sun burns while the wind bites…
> Your shadow is the hardest-edged thing you have ever seen."*
>
> ⭐ **Theme (ENEMIES §2e): burning and freezing at once.** The zone is a
> **contradiction**, not a heat.

⭐ **Why the items are what they are.** Ironwood is ITEMS §9b.6's wood for this
zone and it needs no reinterpretation — desert ironwood is a real Sonoran tree.
Glasswort is a real salt-flat succulent and it is the only wet thing for a
day's walk, which is exactly what a first-aid herb should be here. There is no
cloth in the Kiln Desert because nothing here is soft.

#### 4.1a ⭐ The Woodcarving ladder, and where sockets land — a ruling for all five woods

✅ ITEMS §9b.6 fixes the wood, the equip level and a **gem-slot range** for
every tier. ✅ KINETIC spent Rowan's `0–1` as **1**.

> ✅ **RULED: a crafted common takes the BOTTOM of its wood's range, floored at
> the previous tier's count.** Monotone, conservative, and it never promises
> more empty sockets than the tier before it.

| Wood | Equip | §9b.6 range | **`socketCount`** | Home zone |
|---|---|---|---|---|
| Rowan | 19 ✅ shipped | 0–1 | 1 | Thunderspire Peaks |
| **Ironwood** | **30** | 0–1 | **1** | The Kiln Desert |
| **Bloodwood** | **35** | 1–2 | **1** | The Mirrormere |
| **Ebony** | **40** | 1–2 | **1** | The Sunless Reach |
| Spiritwood | 45 | 2–3 | 2 | Hallowmarch — ETHEREAL §4.1 |
| Aetherwood | 50 | 3 | 3 | The Collapsed Academy — ETHEREAL §4.5 |

⚠️ **Gems are ITEMS §6d and Phase 8. An empty socket is still a promise.** This
quarter keeps Kinetic's promise-count flat at 1 for three more wood tiers
rather than raising it to 2, precisely because the promise has not been paid.
📝 If Phase 8 slips again, drop every `socketCount` in both contracts to 0 in
one edit — no other number depends on it.

**The five-tier weapon ladder, continuing the shipped Oak→Rowan numbers:**

| Wood | Staff `dmg/chg` · acc · crit | Wand `dmg/cast` · acc · crit | Knot acc · crit |
|---|---|---|---|
| Oak ✅ | 1 · 5 · — | 2 · 0 · — | 3 · — |
| Birch ✅ | 2 · 6 · — | 3 · 1 · — | 4 · — |
| Yew ✅ | 3 · 7 · — | 4 · 2 · — | 5 · — |
| Rowan ✅ | 4 · 8 · 3/+8 | 5 · 3 · 4/+6 | 6 · 2 |
| **Ironwood** | **5 · 9 · 4/+10** | **6 · 4 · 5/+8** | **5 · 3** |
| **Bloodwood** | **6 · 10 · 5/+12** | **7 · 4 · 6/+10** | **6 · 4** |
| **Ebony** | **7 · 11 · 6/+14** | **8 · 5 · 7/+12** | **6 · 5** |
| Spiritwood | 8 · 12 · 7/+16 | 9 · 5 · 8/+14 | 7 · 6 |
| Aetherwood | 9 · 12 · 8/+18 | 10 · 5 · 9/+16 | 7 · 7 |

⚠️ **The accuracy column stops climbing and the knot's column goes DOWN at
Ironwood** (Rowan 6 → Ironwood 5). Both are §2.1a: ✅ ITEMS §9b.8 ruling 2 says
*"the staff out-accurates wand + knot combined, on purpose"*, and the shipped
Rowan already broke it (8 vs 3+6=9). The table above restores it at every tier
— staff ≥ wand + knot, exactly — while holding the maximum crafted total to
**staff 12 + hood 6 = 18**, two points under the clamp.
⭐ **Damage and crit keep climbing** because neither is clamped. The weapon
lanes stay legible: the staff pays per charge and out-accurates, the wand pays
per cast and crits more often.

#### Drop table

```
_commonAlways = [ DropEntry('solar_dust', chance: 0.75, min: 1, max: 2) ]
```

| Role | main (weights sum 100) | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `ironwood_log` 55 (1–3) · `solar_shard` 7 · `solar_dust` 13 (1–2) | `pilgrims_ration` 2% |
| material-B common ×2 | nothing 35 · `glasswort` 45 · `solar_shard` 7 · `solar_dust` 13 (1–2) | — |
| the Drudge | nothing 40 · `glasswort` 45 · `pilgrims_ration` 15 | — |

```
_miniDrops  always: solar_shard ×1 · solar_dust 2–4 · solar_crystal chance 0.25
            main:   ironwood_log 40 (2–4) · glasswort 30 (2–4) · pilgrims_ration 25
                    · the_shadeless_band 5
_bossDrops  always: solar_essence ×1  ⭐ GUARANTEED — the gate part, §3.4
                    · solar_crystal 1–2 · solar_shard 1–2 · solar_dust 4–8
            main:   ironwood_log 45 (4–8) · glasswort 25 (3–6) · the_shadeless_band 20
                    · the_hardest_edge 10
```

⚠️ **`solar_crystal` appears on the mini and boss tables and nowhere else.**
⚠️ **The essence is on the `always` line, not the weighted one.** A tier gate
that needs a 10% roll three times is a grind, not a gate.

#### Catalogue — 13 defs (`lib/game/items/catalogue/the_kiln_desert_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `ironwood_log` | Material | common | Woodcarving t5 | 1 | — | 240 📝 |
| `glasswort` | Material | common | Potions t5 | 1 | — | 28 📝 |
| `solar_dust` | Mote | common | dust · solar | 1 | — | 2 ✅ |
| `solar_shard` | Mote | common | shard · solar | 1 | — | 25 ✅ |
| `solar_crystal` | Mote | **uncommon** | crystal · solar | 1 | — | 150 ✅ |
| `solar_essence` | Material | **rare** · **bound** | Enchanting t6 · ⚠️ kill-only, gate part | 1 | — | 0 |
| `pilgrims_ration` | **Consumable** ⚠️ not Beltable | common | `heal: 110` | 1 | — | 16 📝 |
| `glasswort_draught` | **Beltable** | common | `heal: 125` | 1 | — | 55 📝 |
| `ironwood_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Ironwood · **twoHanded** · **1 socket** | 30 | `damagePerCharge: 5, accuracyBonus: 9, critChance: 4, critDamage: 10` | 620 |
| `ironwood_wand` | Equipment | common | mainHand · Wand / Ironwood · **1 socket** | 30 | `damagePerCast: 6, accuracyBonus: 4, critChance: 5, critDamage: 8` | 530 |
| `ironwood_knot` | Equipment | common | offHand · Knot / Ironwood · **1 socket** | 30 | `accuracyBonus: 5, critChance: 3` | 440 |
| `the_shadeless_band` | Equipment | **rare** | ring · Band / Kilnglass · `properName` · untradeable | 32 | `accuracyBonus: 6, maxHpBonus: 18` 📝 | 620 |
| `the_hardest_edge` | Equipment | **epic** | mainHand · Quarterstaff / Ironwood · `properName` · untradeable · **twoHanded** · **1 socket** | 34 | `damagePerCharge: 7, accuracyBonus: 11, critChance: 8, critDamage: 18` 📝 | 1750 |

**Lore and icons**

- `ironwood_log` — *"It does not float, it turns a saw, and it has been standing
  here since before the water left."*
  **Icon:** a single short, squat log the length of a forearm, bark the colour
  of dried blood-grey and split away at one end to show pale dense heartwood
  with a near-invisible grain; one cut face is polished smooth by sand.
- `glasswort` — *"It holds one mouthful of water and gives it up bitter. Nobody
  who crosses here has ever said it tasted like anything but living."*
  **Icon:** a hand-sized sprig of jointed, leafless succulent stems, translucent
  pale green shading to a salt-crusted red at the tips, laid flat with a
  scatter of white salt grains around its base.
- `solar_dust` — *"Bright enough that you look at your hand and not at it."*
  **Icon:** a small loose heap of glittering pale-gold powder, the size of a
  coin pile, unlit and matte with one warm highlight.
- `solar_shard` — *"Dust that held its shape long enough to cast a shadow."*
  **Icon:** three angular slivers of pale-gold translucent stone the size of a
  thumbnail, fanned so one lies edge-on.
- `solar_crystal` — *"It is bright, and it does not stop being bright."*
  **Icon:** a single clear six-sided crystal a thumb long, colourless at the
  base and warming to pale gold at the tip, with one clean note of unlit
  gold — no glow spilling off it.
- `solar_essence` — *"What is left of the sun after something has finished being
  it."*
  **Icon:** a closed sphere of pale-gold light the size of a plum held inside a
  cage of three thin dark-iron bands; Rare, so the gold is a real light source
  and the iron is lit by it.
- `pilgrims_ration` — *"Salt, fat and flour, pressed into a brick and wrapped in
  cloth. It is not food so much as an argument that you are not dead."*
  **Icon:** a cloth-wrapped brick of pale pressed meal the size of a fist,
  twine-tied, one corner unwrapped to show the dry crumbling interior.
- `glasswort_draught` — *"Green, saline and shockingly cold in a place with no
  cold in it. Pilgrims drink it standing, because sitting down out here is how
  it starts."*
  **Icon:** a squat stoppered glass bottle the height of a hand, full of cloudy
  pale-green liquid, its cork sealed under a wrap of salt-stiffened cloth.
- `ironwood_quarterstaff` — *"Cut, cured and shod. It is heavier than it looks
  and it will be heavier still at the end of the day."*
  **Icon:** a two-handed staff as tall as a person, dark red-grey ironwood with
  a thick weighted butt and a dull bronze ferrule at each end; one small empty
  round socket sits in the grip, obviously unfilled.
- `ironwood_wand` — *"Short, light, and shaped to be pointed rather than
  swung."*
  **Icon:** a tapering one-handed wand the length of a forearm, dark ironwood
  polished to a low sheen with a fine hairline of ember-red inlay along the
  taper; one small empty socket at the base.
- `ironwood_knot` — *"A burl left whole, because the grain in a burl goes every
  way at once and that turns out to matter."*
  **Icon:** a fist-sized dark burl of ironwood, worn glass-smooth by handling,
  with one dead-flat filed facet across its face and a single empty socket in
  the middle of it.
- `the_shadeless_band` — *"Worn by people who walked this in daylight on
  purpose. The inside is polished; the outside never has been."*
  **Icon:** a plain heavy ring of pale sand-fused glass standing upright, its
  outer face rough and frosted, its inner face mirror-bright; Rare, so one thin
  line of hard gold light traces the polished inside and lights the rough
  outside from within.
- `the_hardest_edge` — *"Your shadow is the hardest-edged thing you have ever
  seen, and someone has put a handle on it."*
  **Icon:** a two-handed ironwood staff, near-black, with one side of its entire
  length cut dead flat and razor-straight while the other stays round; Epic, so
  a blade of hard white light runs along the flat face and *moves* — the edge is
  a shadow's edge and it is sweeping slowly as though the sun were going down.

📝 **Phase 8 hook.** The Kiln Desert is where a **Solar enchant** would first be
applied and the obvious home for the L30 Tier I **set** (ITEMS §3.4). Neither
is defined here. The two Ironwood sockets are the zone's only Phase 8 surface.

---

### 4.2 The Mirrormere · `the_mirrormere` · 32–37 · Lunar · route

> ✅ *"The surface gives you back the mountains, the stars, and the moon at a
> size the moon has no right to be. Walking the shore, you are careful not to
> look down for too long."*
>
> ⭐ **Theme (ENEMIES §2e): the reflection is bigger than the thing, and it is
> looking back.**

⭐ Bloodwood is ITEMS §9b.6's wood here — *"deep red heartwood under a blood
moon, mirrored in the lake."* Mirrorflax is the quarter's first armour fibre
and it is retted in the lake, which is the only way to get a flax that shows
you yourself.

#### Drop table

```
_commonAlways = [ DropEntry('lunar_dust', chance: 0.75, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `bloodwood_log` 55 (1–3) · `lunar_shard` 7 · `lunar_dust` 13 (1–2) | `pilgrims_ration` 2% |
| material-B common ×2 | nothing 30 · `mirrorflax` 50 (1–2) · `lunar_shard` 8 (1–2) · `lunar_dust` 12 (2–3) | — |
| the Siphon | nothing 40 · `mirrorflax` 45 · `glasswort_draught` 15 | — |

```
_miniDrops  always: lunar_shard ×1 · lunar_dust 2–4 · lunar_crystal chance 0.25
            main:   bloodwood_log 40 (2–4) · mirrorflax 30 (2–4) · pilgrims_ration 25
                    · the_waning_charm 5
_bossDrops  always: lunar_essence ×1  ⭐ GUARANTEED — §3.4
                    · lunar_crystal 1–2 · lunar_shard 1–2 · lunar_dust 4–8
            main:   bloodwood_log 45 (4–8) · mirrorflax 25 (3–6) · the_waning_charm 20
                    · the_larger_reflection 10
```

#### Catalogue — 16 defs (`the_mirrormere_items.dart`)

⭐ The quarter's largest catalogue, because this zone carries **both** a wood
tier and an armour set — the same shape Windward Steppe had (15 defs).

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `bloodwood_log` | Material | common | Woodcarving t6 | 1 | — | 450 📝 |
| `mirrorflax` | Material | common | Tailoring t5 | 1 | — | 88 📝 |
| `lunar_dust` / `lunar_shard` | Mote | common | dust / shard · lunar | 1 | — | 2 / 25 ✅ |
| `lunar_crystal` | Mote | **uncommon** | crystal · lunar | 1 | — | 150 ✅ |
| `lunar_essence` | Material | **rare** · **bound** | Enchanting t6 · ⚠️ kill-only, gate part | 1 | — | 0 |
| `bloodwood_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Bloodwood · **twoHanded** · **1 socket** | 35 | `damagePerCharge: 6, accuracyBonus: 10, critChance: 5, critDamage: 12` | 1150 |
| `bloodwood_wand` | Equipment | common | mainHand · Wand / Bloodwood · **1 socket** | 35 | `damagePerCast: 7, accuracyBonus: 4, critChance: 6, critDamage: 10` | 990 |
| `bloodwood_knot` | Equipment | common | offHand · Knot / Bloodwood · **1 socket** | 35 | `accuracyBonus: 6, critChance: 4` | 820 |
| `mirrorflax_hood` | Equipment | common | hat · Hood / Mirrorflax | 34 | `accuracyBonus: 5` | 265 |
| `mirrorflax_robe` | Equipment | common | robeTop · Robe / Mirrorflax | 34 | `maxHpBonus: 23` | 530 |
| `mirrorflax_leggings` | Equipment | common | robeBottom · Leggings / Mirrorflax | 34 | `maxHpBonus: 16` | 440 |
| `mirrorflax_boots` | Equipment | common | boots · Boots / Mirrorflax | 34 | `maxHpBonus: 5, dodge: 4` | 265 |
| `mirrorflax_gloves` | Equipment | common | gloves · Gloves / Mirrorflax | 34 | `maxHpBonus: 5, deflectChance: 10, deflectAmount: 20` (EV 2.0%) | 265 |
| `the_waning_charm` | Equipment | **rare** | ring · Charm / Merestone · `properName` · untradeable | 35 | `dodge: 9, maxHpBonus: 16` 📝 | 780 |
| `the_larger_reflection` | Equipment | **epic** | robeTop · Mantle / Mirrorflax · `properName` · untradeable | 37 | `maxHpBonus: 40, dodge: 6` 📝 | 2200 |

⭐ **Mirrorflax set total: 49 HP · 5 acc · 4 dodge · 10/20 deflect.** Against
the level-34 baseline (365 HP) that is **+13.4% health** — the same proportion
Seawrack held at 16 (+17%) and Tussock at 24 (+15%), continuing the slow decay
KINETIC §2.6 note 3 predicted for flat modifiers against a geometric curve.
⚠️ **`the_larger_reflection` and `mirrorflax_robe` fight for the same slot,
deliberately** — the epic is the reason to break your set, the shape Sporecap
Mantle established in Q1 and The Long Lean continued in Q2.
⭐ **Lunar's affinity is dodge (§2.5a) and both drops carry it**, which is how a
player learns the element's gear identity without reading a table.

**Lore and icons**

- `bloodwood_log` — *"Cut it at noon and it is brown. Cut it when the moon is on
  the water and it is not."*
  **Icon:** a short split log the length of a forearm, grey weathered bark
  outside and a deep wine-red heartwood face inside with darker rings; the red
  face is turned toward the viewer and is matte, not wet.
- `mirrorflax` — *"Retted in the lake and dried on the shore. Held up, a hank of
  it shows you the back of your own head."*
  **Icon:** a tied hank of long pale fibre the size of a forearm, silver-grey and
  faintly iridescent, with one strand catching a cold white highlight along its
  whole length.
- `lunar_dust` — *"Cold, and it lies flat however you pour it."*
  **Icon:** a small heap of fine silver-white powder, matte, with a single
  cool highlight.
- `lunar_shard` — *"You can see the room in it, slightly further away than the
  room is."*
  **Icon:** three flat slivers of silvered translucent stone, thumbnail-sized,
  one of them face-on and faintly mirroring.
- `lunar_crystal` — *"It is cold, and it does not stop being cold."*
  **Icon:** a single clear six-sided crystal a thumb long, colourless at the base
  and cooling to pale silver-blue at the tip, one unlit cold note.
- `lunar_essence` — *"Something down there finished being the moon and this
  stayed."*
  **Icon:** a sphere of pale silver light the size of a plum inside three thin
  dark bands; Rare, so the silver lights the bands from inside.
- `bloodwood_quarterstaff` — *"Heavy, dark, and warm to hold for no reason
  anyone has explained."*
  **Icon:** a two-handed staff as tall as a person, deep wine-red wood with
  near-black figuring, a weighted butt and plain steel ferrules; one empty
  round socket in the grip.
- `bloodwood_wand` — *"A finger's length of heartwood and nothing else."*
  **Icon:** a short tapering one-handed wand, deep red and polished, with a
  darker spiral of grain running its length; one empty socket at the base.
- `bloodwood_knot` — *"Where a branch tried to leave and the tree said no."*
  **Icon:** a fist-sized dark-red burl worn smooth, one flat filed facet, a
  single empty socket.
- `mirrorflax_hood` — *"Cut straight, sewn straight, and the brim is a dead
  level line on purpose."*
  **Icon:** a soft silver-grey hood laid flat, its brim stiffened into a
  perfectly straight horizontal edge, doubled seams visible at the shoulders.
- `mirrorflax_robe` — *"Layered four deep. In still air it hangs like water."*
  **Icon:** a long silver-grey robe on an invisible form, thick and visibly
  layered with doubled seams down both sides, the weave legible up close.
- `mirrorflax_leggings` — *"Quilted, because the shore is stone and the stone is
  cold."*
  **Icon:** silver-grey quilted leggings laid flat, the quilting lines running
  in visible parallel channels.
- `mirrorflax_boots` — *"Soft-soled. You will not hear yourself and neither will
  anything else."*
  **Icon:** a pair of low silver-grey boots with thick soft soles, one lifted
  slightly as though mid-step and barely touching its own shadow.
- `mirrorflax_gloves` — *"Palms doubled. The hand is the piece you put in the
  way."*
  **Icon:** a pair of silver-grey gloves, palms outward, the palm panels visibly
  doubled and quilted; one faint cool grey-white line traces each palm.
- `the_waning_charm` — *"It was a full ring once. Everyone who has owned it says
  so and none of them can say when it stopped."*
  **Icon:** a slim silver band standing upright, thinning smoothly from a broad
  arc at the top to almost nothing at the bottom so the circle looks incomplete;
  Rare, so a thread of pale blue light lifts very slightly off the thin end and
  does not quite touch it.
- `the_larger_reflection` — *"It fits. It has always fitted. In the water it is
  a size larger and it fits there too."*
  **Icon:** a long silver-grey mantle on an invisible form, the cloth reading
  correctly at the shoulders but subtly *too big* at the hem; Epic, so the hem
  is moving — a slow ripple travelling outward as though something below were
  wearing the other half.

📝 **Phase 8 hook.** The Lunar enchant's home, and the Tier I set's second
candidate. Bloodwood's §9b.6 range is 1–2 sockets; this contract spends 1.

---

### 4.3 Starfall Basin · `starfall_basin` · 34–39 · Astral · route

> ✅ *"Bowl after bowl in the pale ground, each with something at the bottom that
> is not from here… At night the sky is so clear it looks like a threat."*
>
> ⭐ **Theme (ENEMIES §2e): things fell here, and the sky is still aiming.**

⭐ **The zone with no cloth, no wood and no herb, and that is the design.**
Everything in Starfall Basin came down; nothing grew. Both materials are mined
out of craters, which is why this is the only zone in the game with **two
Mining nodes and nothing else**, and why its own consumable is imported.

#### Drop table

```
_commonAlways = [ DropEntry('astral_dust', chance: 0.75, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `skyiron_ore` 55 (1–3) · `astral_shard` 7 · `astral_dust` 13 (1–2) | `pilgrims_ration` 2% |
| material-B common ×2 | nothing 30 · `fallstone` 45 · `astral_shard` 8 (1–2) · `astral_dust` 17 (2–3) | — |
| the Sentinel | nothing 30 · `skyiron_ore` 40 (1–2) · `fallstone` 20 · `glasswort_draught` 10 | — |

```
_miniDrops  always: astral_shard ×1 · astral_dust 2–4 · astral_crystal chance 0.25
            main:   skyiron_ore 40 (2–4) · fallstone 30 (2–4) · pilgrims_ration 25
                    · zodiac_pendant 5
_bossDrops  always: astral_essence ×1  ⭐ GUARANTEED — §3.4
                    · astral_crystal 1–2 · astral_shard 1–2 · astral_dust 4–8
            main:   skyiron_ore 45 (4–8) · fallstone 25 (3–6) · zodiac_pendant 20
                    · the_aimed_sky 10
```

#### Catalogue — 9 defs (`starfall_basin_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `skyiron_ore` | Material | common | Metalworking t5 | 1 | — | 26 📝 |
| `fallstone` | Material | **uncommon** | Enchanting t5 ⭐ **spendable in-band, §3.1** | 1 | — | 60 📝 |
| `astral_dust` / `astral_shard` | Mote | common | dust / shard · astral | 1 | — | 2 / 25 ✅ |
| `astral_crystal` | Mote | **uncommon** | crystal · astral | 1 | — | 150 ✅ |
| `astral_essence` | Material | **rare** · **bound** | Enchanting t6 · ⚠️ kill-only, gate part | 1 | — | 0 |
| `skysteel_ingot` | Material | common | Metalworking t5 output ⭐ feeds 2 recipes | 1 | — | 110 📝 |
| `zodiac_pendant` | Equipment | **rare** | neck · Pendant / Sky-Iron · `properName` · untradeable | 37 | `critChance: 10, critDamage: 12` 📝 | 900 |
| `the_aimed_sky` | Equipment | **epic** | neck · Pendant / Sky-Iron · `properName` · untradeable | 39 | `damagePerCast: 9, critChance: 10, critDamage: 18` 📝 | 2600 |

⭐ **Both drops are Astral and both are crit (§2.5a).** Starfall Basin is where
a player learns that Astral is the crit element, and it teaches it twice — the
rare is pure crit, the epic adds the damage that makes a crit worth landing.
⚠️ **`zodiac_pendant` and `the_aimed_sky` are the same slot.** That is the
rare→epic upgrade path inside one zone, which no Kinetic zone offered; 📝 move
`zodiac_pendant` to `ring` if a sidegrade is wanted instead of a ladder.

**Lore and icons**

- `skyiron_ore` — *"Iron that arrived rather than formed. It rusts differently
  and nobody local will say how."*
  **Icon:** a fist-sized lump of dark pitted metal-bearing rock, its surface
  scabbed with a thin black fusion crust and broken open on one face to show
  bright grey metal flecked through the stone.
- `fallstone` — *"Whatever is at the bottom of each bowl. It weighs what it
  should and nothing else about it does."*
  **Icon:** a smooth ovoid stone the size of an egg, matte black-grey, with a
  faint indigo sheen across one curve and a shallow dimple where it struck;
  Uncommon, so the indigo is one clean unlit note.
- `astral_dust` — *"It scatters, and then it is in a pattern."*
  **Icon:** a small heap of blue-black powder shot with points of white,
  loosely spread rather than piled.
- `astral_shard` — *"Cold sparks with corners on them."*
  **Icon:** three angular slivers of deep indigo translucent stone with white
  flecks inside, thumbnail-sized, fanned.
- `astral_crystal` — *"It is far away, and holding it does not change that."*
  **Icon:** a clear six-sided crystal a thumb long, deep indigo at the base
  clearing to colourless, with a scatter of white points suspended inside it.
- `astral_essence` — *"The last of whatever was aiming."*
  **Icon:** a sphere of deep indigo light the size of a plum caged in three thin
  bands of sky-iron; Rare, so the indigo is a real light source.
- `skysteel_ingot` — *"Smelted with charcoal, because nothing else here burns.
  It takes an edge that should not be possible."*
  **Icon:** a single small rectangular ingot the length of a hand, cool
  blue-grey with a faint watered figure across its top face and one bevelled
  corner; matte, no glow.
- `zodiac_pendant` — *"Twelve marks around the rim, and the one at the top is
  not one of the twelve."*
  **Icon:** a flat disc of dark sky-iron the size of a coin on a fine chain,
  its rim punched with small marks; Rare, so a single point of hot white light
  sits at the top of the rim and lights the rest of the disc.
- `the_aimed_sky` — *"It is not a map of where things are. It is a map of where
  they are going."*
  **Icon:** a heavy dark sky-iron pendant, a flat disc with a single fine line
  scored across it from edge to edge; Epic, so a bead of hard white light
  travels slowly along that line, arrives at the rim, and starts again.

📝 **Phase 8 hook.** The Astral enchant's home. Starfall is also the obvious
source of a **Lesser Astral gem** when ITEMS §6d ships, since the crystals are
already here and nothing is competing for them.

---

### 4.4 Tidewrack Shoals · `tidewrack_shoals` · 36–40 · Lunar + Aqua ⭐ hybrid · route

> ✅ *"The water goes out further than seems survivable and comes back faster.
> What it uncovers has been down there a long time. Everything is timed to
> something overhead."*
>
> ⭐ **Theme (ENEMIES §2e): the sea is on a schedule it did not choose.** The
> fusion is **obedience** — Aqua doing what Lunar says.

⚠️ **Reached only by sea, from Galehaven** (`TravelEdgeKind.sea`, 12) **or from
The Mirrormere.** It is the one Celestial zone a player can arrive at without
passing Concordance, which is why its consumables are imported and its gear
starts a fresh armour tier rather than continuing one.

#### Drop table

```
_commonAlways = [ DropEntry('lunar_dust', chance: 0.5, min: 1, max: 2),
                  DropEntry('aqua_dust',  chance: 0.5, min: 1, max: 2) ]
```
⭐ The shipped hybrid shape — two dusts at half chance each, so a hybrid kill
pays about as much mote as a pure one but in two currencies. ⚠️ **`aqua_*`
resolve to `glimmerbrook_items.dart`, a Q1 file.** Nothing is redefined.

| Role | main | bonus |
|---|---|---|
| hide common ×2 | nothing 30 · `drownling_hide` 40 · `aqua_shard` 8 (1–2) · `aqua_dust` 17 (2–3) · `pilgrims_ration` 5 | — |
| material-A common ×2 | nothing 25 · `wrackcotton` 55 (1–3) · `lunar_shard` 7 · `lunar_dust` 13 (1–2) | `pilgrims_ration` 2% |
| the Siphon | nothing 40 · `nacre` 45 · `glasswort_draught` 15 | — |

```
_miniDrops  always: lunar_shard ×1 · aqua_shard ×1 · lunar_dust 2–4 · aqua_dust 2–4
                    · lunar_crystal chance 0.25 · aqua_crystal chance 0.25
            main:   drownling_hide 35 (2–4) · wrackcotton 30 (2–4) · nacre 30 (1–2)
                    · the_turning_tide 5
_bossDrops  always: lunar_crystal 1–2 · aqua_crystal 1–2 · lunar_shard 1–2 · aqua_shard 1–2
                    · lunar_dust 4–8 · aqua_dust 4–8     ⚠️ NO essence — hybrid
            main:   drownling_hide 35 (4–8) · wrackcotton 25 (3–6) · nacre 15 (2–4)
                    · the_turning_tide 15 · lowwater_tread 10
```

⚠️ **No essence.** The three gate parts are the three **pure** Celestial zones',
which is the same rule NARRATIVE used for the Kinetic Sigil and the reason the
three pure zones are the ones that must be cleared.

#### Catalogue — 11 defs (`tidewrack_shoals_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `wrackcotton` | Material | common | Tailoring t6 | 1 | — | 150 📝 |
| `nacre` ⏳ | Material | **uncommon** | Jewelry t6 · 📝 **banks until Rimeholt (L45)** | 1 | — | 95 📝 |
| `drownling_hide` | Material | common | Tailoring t6 · ⚠️ **kill-only, no node** | 1 | — | 300 📝 |
| `wrackcotton_hood` | Equipment | common | hat · Hood / Wrackcotton | 39 | `accuracyBonus: 5` | 450 |
| `wrackcotton_robe` | Equipment | common | robeTop · Robe / Wrackcotton | 39 | `maxHpBonus: 32` | 900 |
| `wrackcotton_leggings` | Equipment | common | robeBottom · Leggings / Wrackcotton | 39 | `maxHpBonus: 22` | 750 |
| `wrackcotton_boots` | Equipment | common | boots · Boots / Wrackcotton | 39 | `maxHpBonus: 6, dodge: 5` | 450 |
| `wrackcotton_gloves` | Equipment | common | gloves · Gloves / Wrackcotton | 39 | `maxHpBonus: 7, deflectChance: 14, deflectAmount: 24` (EV 3.4%) | 450 |
| `drownling_belt` | Equipment | common | belt · Belt / Drownling | 38 | `beltSlots: 5` ⚠️ capacity only | 750 |
| `the_turning_tide` | Equipment | **rare** | neck · Pendant / Nacre · `properName` · untradeable | 38 | `dodge: 6, shieldStrengthPercent: 12` 📝 | 1050 |
| `lowwater_tread` | Equipment | **epic** | boots · Tread / Drownling · `properName` · untradeable | 40 | `maxHpBonus: 24, dodge: 7, shieldStrengthPercent: 10` 📝 | 3000 |

⭐ **Wrackcotton set total: 67 HP · 5 acc · 5 dodge · 14/24 deflect.** Against
the level-39 baseline (444 HP) that is **+15.1%** — the proportion holds.
⭐ **Belt capacity ladder: Fawnhide 1 → Tuskhide 2 → Rimepelt 3 → Emberhide 4 →
Drownling 5 → Palimpsest 6.** `Carrying.maxBeltSlots` is 10.
⚠️ **Belts carry `beltSlots` and nothing else** — the Q1 ruling. Do not add
stats to a belt.
⭐ **Both drops mix Lunar's dodge with Aqua's shield strength (§2.5a)**, which
is the hybrid stated as a stat block: the tide obeys, and obedience is a
defence.

**Lore and icons**

- `wrackcotton` — *"It grows on the flats and is only there for six hours a day.
  Everything about harvesting it is the clock."*
  **Icon:** a tied bundle of pale fibrous strands the size of a forearm, sea-grey
  fading to bleached white, with a fine dusting of dried salt and one dark
  strand of weed still caught in it.
- `nacre` ⏳ — *"Shell-lining, prised off in whole plates. Nobody in Concordance
  knows what to do with it yet. Someone at Rimeholt will."*
  **Icon:** a single curved plate of mother-of-pearl the size of a palm, resting
  concave-up, pale cream with soft bands of pink and green iridescence across
  its inner face; Uncommon, so the iridescence is one clean note, unlit.
- `drownling_hide` — *"Off something the tide uncovered. It has never been dry
  and it is not wet."*
  **Icon:** a folded hide the size of a lap blanket, slate-grey and faintly
  translucent at the thin edges, with a fine pebbled grain; matte, no shine.
- `wrackcotton_hood` — *"Salt-stiffened and cut with a flat brim, the way
  everyone here cuts everything."*
  **Icon:** a pale grey hood laid flat, brim stiffened dead straight, the weave
  visibly coarse and doubled at the crown.
- `wrackcotton_robe` — *"Six layers. It is the warmest thing on the shoals and
  it still takes an hour to dry."*
  **Icon:** a long pale sea-grey robe on an invisible form, thick and
  unmistakably layered, doubled seams down both sides and at the hem.
- `wrackcotton_leggings` — *"Quilted to the knee and plain below it, because
  below the knee is underwater twice a day."*
  **Icon:** pale grey leggings laid flat, quilted in visible channels down to
  the knee and smooth from there.
- `wrackcotton_boots` — *"High, soft and laced at the back so you can get out of
  them fast."*
  **Icon:** a pair of tall pale-grey boots with soft soles and long rear laces,
  one caught mid-step and barely touching its shadow.
- `wrackcotton_gloves` — *"Palms tripled. You put your hands out here, or the
  shoals put them out for you."*
  **Icon:** pale grey gloves, palms outward, palm panels visibly tripled; a
  cool grey-white line traces each palm.
- `drownling_belt` — *"Five loops of hide that has never taken a dye."*
  **Icon:** a wide slate-grey hide belt laid in a loose open curve with a plain
  dark shell buckle and **five empty loops** stitched along it, each wide
  enough for a bottle and visibly holding nothing.
- `the_turning_tide` — *"It is heavy at the low and light at the high. Sailors
  swear that is the shell and not them."*
  **Icon:** a broad teardrop of mother-of-pearl on a plain cord, standing
  upright; Rare, so one soft cool light runs around the shell's outer rim and
  lights the iridescence from the edge inward.
- `lowwater_tread` — *"Made for the six hours. Whoever wore them out here came
  back, which is more than most."*
  **Icon:** a pair of tall grey drownling-hide boots, soles worn to nothing at
  the toe, standing in a shallow wet footprint; Epic, so the footprint is
  *filling* — a thin sheet of water creeping in around them and never quite
  reaching the sole.

📝 **Phase 8 hook.** An **Aqua** or **Lunar** enchant applies here, and
Wrackcotton is the obvious Tier I set base if the L30 set lands on this band's
fibre rather than the Kiln Desert's.

---

### 4.5 The Sunless Reach · `the_sunless_reach` · 38–42 · Solar + Lunar ⭐ hybrid · route

> ✅ *"You come over the crest out of glare into a valley that has never been
> lit. The rock is the same rock. The desert is a thousand feet away and on the
> other side of the world."*
>
> ⭐⭐ **Theme (ENEMIES §2e): identical ground, opposite worlds, one line between
> them.** The fusion is **a boundary, not a blend**.

⭐ Ebony is ITEMS §9b.6's wood here, and §9b.6 already resolved its retheme:
*"black wood grown where the sun does not reach. Sunless/lightless, not
void-touched"* — and the item is simply an **Ebony Quarterstaff**, no adjective,
because §9b.5a took adjectives out of base names.

#### Drop table

```
_commonAlways = [ DropEntry('solar_dust', chance: 0.5, min: 1, max: 2),
                  DropEntry('lunar_dust', chance: 0.5, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `ebony_log` 55 (1–3) · `lunar_shard` 7 · `lunar_dust` 13 (1–2) | `pilgrims_ration` 2% |
| material-B common ×2 | nothing 35 · `duskcap` 50 (1–2) · `solar_shard` 5 · `solar_dust` 10 (1–2) | — |
| the Sentinel | nothing 30 · `eclipse_opal` 40 · `solar_shard` 8 (1–2) · `solar_dust` 17 (2–3) · `duskcap_tonic` 5 | — |

```
_miniDrops  always: solar_shard ×1 · lunar_shard ×1 · solar_dust 2–4 · lunar_dust 2–4
                    · solar_crystal chance 0.25 · lunar_crystal chance 0.25
            main:   ebony_log 40 (2–4) · duskcap 30 (2–4) · eclipse_opal 25 (1–2)
                    · crestline_ring 5
_bossDrops  always: solar_crystal 1–2 · lunar_crystal 1–2 · solar_shard 1–2 · lunar_shard 1–2
                    · solar_dust 4–8 · lunar_dust 4–8    ⚠️ NO essence — hybrid
            main:   ebony_log 35 (4–8) · duskcap 20 (3–6) · eclipse_opal 15 (2–4)
                    · crestline_ring 20 · the_dividing_line 10
```

#### Catalogue — 9 defs (`the_sunless_reach_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `ebony_log` | Material | common | Woodcarving t7 | 1 | — | 810 📝 |
| `duskcap` | Material | common | Potions t6 | 1 | — | 36 📝 |
| `eclipse_opal` ⏳ | Material | **uncommon** | Jewelry t7 · 📝 **banks until Rimeholt (L45)** | 1 | — | 130 📝 |
| `duskcap_tonic` | **Beltable** | common | `healPerTurn: 34, healTurns: 3` | 1 | — | 70 📝 |
| `ebony_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Ebony · **twoHanded** · **1 socket** | 40 | `damagePerCharge: 7, accuracyBonus: 11, critChance: 6, critDamage: 14` | 2100 |
| `ebony_wand` | Equipment | common | mainHand · Wand / Ebony · **1 socket** | 40 | `damagePerCast: 8, accuracyBonus: 5, critChance: 7, critDamage: 12` | 1800 |
| `ebony_knot` | Equipment | common | offHand · Knot / Ebony · **1 socket** | 40 | `accuracyBonus: 6, critChance: 5` | 1500 |
| `crestline_ring` | Equipment | **rare** | ring · Ring / Eclipse Opal · `properName` · untradeable | 40 | `accuracyBonus: 5, dodge: 5, maxHpBonus: 20` 📝 | 1300 |
| `the_dividing_line` | Equipment | **epic** | mainHand · Wand / Ebony · `properName` · untradeable · **1 socket** | 42 | `damagePerCast: 12, accuracyBonus: 6, critChance: 10, critDamage: 20` 📝 | 3700 |

⭐ **`crestline_ring` is the zone in one item:** Solar's accuracy and Lunar's
dodge, equal and opposed, on a ring named for the line between them (§2.5a).
It is the only piece in either quarter that carries both sides of an affinity
pair, and it is the right zone for it — ENEMIES §2f calls the two-Aspect
doubling here *"the one place doubling says something."*
⭐ **`the_dividing_line` is the quarter's wand epic** and the best-in-slot main
hand at L47 (§2.6), which is the Uplight role one tier up.

**Lore and icons**

- `ebony_log` — *"Grown on the dark side. It sinks, it will not take a nail, and
  it polishes like stone."*
  **Icon:** a short split log the length of a forearm, near-black throughout
  with a fine straight grain, one end cut and polished to a dull sheen, the
  bark dark grey and papery.
- `duskcap` — *"It fruits along the line where the light stops and nowhere else.
  Boiled, it is the best thing in the valley."*
  **Icon:** a single mushroom the size of a fist, cap half bleached bone-white
  and half deep slate-grey with a hard straight division between the two, on a
  pale stem.
- `eclipse_opal` ⏳ — *"Light on one face, dark on the other, and the line
  between them does not move when you turn it."*
  **Icon:** an oval polished stone the size of a thumb, one half milk-white with
  soft fire, the other half matte black, split by a clean straight edge;
  Uncommon, so the fire is one unlit note.
- `duskcap_tonic` — *"Drink it and count to three. Each count is worth
  something."*
  **Icon:** a tall narrow stoppered bottle the height of a hand holding a
  layered liquid — pale grey above, near-black below — with a soft rounded
  shoulder and a wax-sealed cork.
- `ebony_quarterstaff` — *"It weighs what a bar of iron weighs and it is
  wood."*
  **Icon:** a two-handed near-black staff as tall as a person, polished to a
  stone-like sheen, with plain dark steel ferrules and a thick weighted butt;
  one empty round socket in the grip.
- `ebony_wand` — *"A short black line that the eye keeps sliding off."*
  **Icon:** a short tapering one-handed wand of near-black polished wood, its
  silhouette very clean against the white ground; one empty socket at the base.
- `ebony_knot` — *"The only pale thing on it is where it was cut."*
  **Icon:** a fist-sized near-black burl, glass-smooth, with one flat filed
  facet showing raw pale-grey end grain; a single empty socket.
- `crestline_ring` — *"Worn on the hand you reach with. Half the band has been
  in the sun and half has not, and they do not match."*
  **Icon:** a ring standing upright, one half of the band polished bright and
  the other half matte black, meeting at two hard seams; Rare, so a thin warm
  light traces the bright half and a thread of cool blue lifts just off the
  dark half.
- `the_dividing_line` — *"Hold it up along the crest and it disappears."*
  **Icon:** a slim black ebony wand held vertically; Epic, so one side of its
  entire length is lit hard white and the other is in total shadow, with no
  falloff between them — and the lit side is slowly *changing sides*.

📝 **Phase 8 hook.** The one place a **dual enchant** would make sense, if
Phase 8 ever allows one. Ebony's §9b.6 range is 1–2 sockets; this contract
spends 1.

---

### 4.6 The Shattered Orrery · `the_shattered_orrery` · 40–44 · Astral + Electro ⭐ hybrid · 🏰 dungeon

> ✅ *"Rings the size of bridges, half of them fallen, and the fallen half still
> turning. The arcing is not weather; it is the mechanism. Something is being
> calculated and has been for a very long time."*
>
> ⭐ **Theme (ENEMIES §2e): a broken machine still computing, and nobody knows
> what toward.** The fusion is **the heavens as mechanism** — Electro is the
> power, Astral is what it is modelling.

⚠️ **`LocationKind.dungeon` stands and changes nothing about this data.**
KINETIC ruling 4 applies: nothing here may assume a descending structure.
⭐ **The only zone in either quarter whose materials are all salvage.** Nothing
grew here and nothing fell here — it was *built*, and then it broke.

#### Drop table

```
_commonAlways = [ DropEntry('astral_dust',  chance: 0.5, min: 1, max: 2),
                  DropEntry('electro_dust', chance: 0.5, min: 1, max: 2) ]
```
⚠️ **`electro_*` resolve to `stormcliff_coast_items.dart`, a Q2 file.**

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `orrery_scrap` 55 (1–3) · `electro_shard` 7 · `electro_dust` 13 (1–2) | `pilgrims_ration` 2% |
| material-B common ×2 | nothing 35 · `arcsalt` 50 (1–2) · `astral_shard` 5 · `astral_dust` 10 (1–2) | — |
| the Sentinel | nothing 30 · `sidereal_glass` 40 · `astral_shard` 8 (1–2) · `astral_dust` 17 (2–3) · `arcsalt_draught` 5 | — |

```
_miniDrops  always: astral_shard ×1 · electro_shard ×1 · astral_dust 2–4 · electro_dust 2–4
                    · astral_crystal chance 0.25 · electro_crystal chance 0.25
            main:   orrery_scrap 40 (2–4) · arcsalt 30 (2–4) · sidereal_glass 25 (1–2)
                    · sidereal_signet 5
_bossDrops  always: astral_crystal 1–2 · electro_crystal 1–2 · astral_shard 1–2
                    · electro_shard 1–2 · astral_dust 4–8 · electro_dust 4–8
            main:   orrery_scrap 35 (4–8) · arcsalt 20 (3–6) · sidereal_glass 15 (2–4)
                    · sidereal_signet 20 · the_running_count 10
```

#### Catalogue — 7 defs (`the_shattered_orrery_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `orrery_scrap` | Material | common | Metalworking t7 | 1 | — | 48 📝 |
| `arcsalt` | Material | common | Potions t7 | 1 | — | 32 📝 |
| `sidereal_glass` ⏳ | Material | **uncommon** | Jewelry t7 · 📝 **banks until Rimeholt (L45)** | 1 | — | 160 📝 |
| `arcsalt_draught` | **Beltable** | common | `heal: 185` | 1 | — | 95 📝 |
| `starbrass_ingot` | Material | common | Metalworking t7 output ⭐ feeds 2 recipes | 1 | — | 200 📝 |
| `sidereal_signet` | Equipment | **rare** | ring · Signet / Starbrass · `properName` · untradeable | 42 | `critChance: 10, accuracyBonus: 4` 📝 | 1600 |
| `the_running_count` | Equipment | **epic** | gloves · Gauntlets / Starbrass · `properName` · untradeable | 44 | `accuracyBonus: 5, damagePerCast: 10, critChance: 8` 📝 | 4500 |

⚠️ **No mote family is defined here** — a hybrid never defines one (§3.2), and
both of this one's parents already have theirs.
⭐ **The quarter's smallest catalogue, at 7, and that is correct.** The Orrery
has no wood, no cloth and no hide; it is a machine being scavenged. Frostfell
Pass and The Molten Deep shipped 6 each for the same kind of reason.

**Lore and icons**

- `orrery_scrap` — *"A tooth off a gear the size of a door. Whatever it was
  counting, it is one short now."*
  **Icon:** a single broken gear tooth of dull yellow-brown brass the length of
  a hand, sheared at the root with a bright ragged break face, the rest
  tarnished and scored with fine wear lines.
- `arcsalt` — *"White crust where the machine has been earthing itself for four
  hundred years. It tastes like a held breath."*
  **Icon:** a broken slab of white crystalline crust the size of a palm, thin
  and plate-like, its underside stained a faint violet-black where it lifted
  off the metal.
- `sidereal_glass` ⏳ — *"A lens out of a fallen ring. It still focuses. On
  what, nobody has stood in front of long enough to say."*
  **Icon:** a thick round lens of pale blue-green glass the size of a palm,
  one edge chipped, lying at a slight angle so its curve catches a hard
  highlight; Uncommon, so that highlight is the only colour note.
- `arcsalt_draught` — *"Sharp, metallic, and it makes your teeth ring. Whatever
  it is doing, it does it fast."*
  **Icon:** a heavy squat bottle of thick blue-green glass, half the height of a
  hand, with a brass collar and stopper and a clear colourless liquid inside in
  which a few white crystals are still settling.
- `starbrass_ingot` — *"Remelted mechanism. It takes a finer thread than
  anything you could buy in Concordance."*
  **Icon:** a small rectangular ingot the length of a hand, warm yellow-brown
  brass with a faint blue tarnish bloom at one end and a bevelled corner;
  matte.
- `sidereal_signet` — *"A seal for something that has not needed sealing in a
  long time. The face is a date."*
  **Icon:** a broad flat-faced brass signet ring standing upright, its face cut
  with fine incised marks arranged in a ring; Rare, so one of the marks is a
  point of hot white light and the others are lit by it.
- `the_running_count` — *"Put them on and you know what number it is on. You do
  not know what it is counting."*
  **Icon:** a pair of brass-plated gauntlets, palms outward, with a row of small
  toothed wheels set along the back of each hand; Epic, so the wheels are
  *turning* — slowly, unevenly, and never stopping.

📝 **Phase 8 hook.** The Orrery is where a **socket** should first be something
other than a promise: the mechanism is already full of set stones. 📝 When ITEMS
§6d ships, the Orrery's mini pool is the natural first **Lesser gem** drop.

---

### 4.7 The Glass Archive · `the_glass_archive` · 43–47 · Solar + Arcane ⭐ hybrid · 🏰 dungeon

> ✅ *"Lenses on every roof, and all of them still aimed. Around midday the
> hillside fills with writing you can almost read… they recorded onto the one
> thing that will not hold still."*
>
> ⭐ **Theme (ENEMIES §2e): an archive readable only at noon, which the reading
> destroys.**

⭐ **Two firsts live here.** It is the game's **first Arcane zone** (43–47,
seven levels before The Collapsed Academy), so it defines the `arcane_*` mote
family (§3.2). And `world.dart` says in a comment that this is *"where a player
grinds out the Celestial Totem that gets them past"* the Rimeholt barrier — so
`celestial_totem` is defined in this catalogue even though it is charged at
Meridian.

#### Drop table

```
_commonAlways = [ DropEntry('solar_dust',  chance: 0.5, min: 1, max: 2),
                  DropEntry('arcane_dust', chance: 0.5, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| hide common ×2 | nothing 30 · `palimpsest_vellum` 40 · `arcane_shard` 8 (1–2) · `arcane_dust` 17 (2–3) · `sunbleach_tonic` 5 | — |
| material-A common ×2 | nothing 25 · `sunbleach_lichen` 55 (1–3) · `solar_shard` 7 · `solar_dust` 13 (1–2) | `pilgrims_ration` 2% |
| the Siphon | nothing 40 · `aetherglass` 45 · `arcsalt_draught` 15 | — |

```
_miniDrops  always: solar_shard ×1 · arcane_shard ×1 · solar_dust 2–4 · arcane_dust 2–4
                    · solar_crystal chance 0.25 · arcane_crystal chance 0.25
            main:   palimpsest_vellum 35 (2–4) · sunbleach_lichen 30 (2–4) · aetherglass 30 (1–2)
                    · the_last_reading 5
_bossDrops  always: solar_crystal 1–2 · arcane_crystal 1–2 · solar_shard 1–2
                    · arcane_shard 1–2 · solar_dust 4–8 · arcane_dust 4–8
            main:   palimpsest_vellum 35 (4–8) · sunbleach_lichen 20 (3–6) · aetherglass 15 (2–4)
                    · the_last_reading 20 · the_noon_hour 10
```

#### Catalogue — 11 defs (`the_glass_archive_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `sunbleach_lichen` | Material | common | Potions t8 | 1 | — | 37 📝 |
| `aetherglass` ⏳ | Material | **uncommon** | Jewelry t8 · 📝 **banks until Rimeholt (L45)** | 1 | — | 210 📝 |
| `palimpsest_vellum` | Material | common | Tailoring t7 · ⚠️ **kill-only, no node** | 1 | — | 480 📝 |
| `arcane_dust` / `arcane_shard` | Mote | common | dust / shard · arcane ⭐ **first Arcane zone** | 1 | — | 2 / 25 ✅ |
| `arcane_crystal` | Mote | **uncommon** | crystal · arcane | 1 | — | 150 ✅ |
| `sunbleach_tonic` | **Beltable** | common | `healPerTurn: 42, healTurns: 3` | 1 | — | 110 📝 |
| `celestial_totem` | **Key** | **rare** · **bound** | `gates: 'rimeholt'` ⭐ §3.4 | 1 | — | 0 ✅ (`KeyDef` forces 0) |
| `palimpsest_belt` | Equipment | common | belt · Belt / Palimpsest | 45 | `beltSlots: 6` ⚠️ capacity only | 1110 |
| `the_last_reading` | Equipment | **rare** | neck · Locket / Aetherglass · `properName` · untradeable | 45 | `maxHpBonus: 30, accuracyBonus: 5, critDamage: 20` 📝 | 2000 |
| `the_noon_hour` | Equipment | **epic** | hat · Circlet / Aetherglass · `properName` · untradeable | 47 | `maxHpBonus: 55, deflectChance: 12, deflectAmount: 14, critDamage: 20` (EV 1.7%) 📝 | 5600 |

⚠️ **`the_noon_hour` is the quarter's ONE deflect drop (§2.1b)**, and it is here
because Arcane's affinity is deflection (§2.5a). No other Celestial drop carries
`deflectAmount`. ⭐ With the Wrackcotton gloves it reaches 26/38 — EV 9.9% —
and the **14** is chosen so that the worst legal assembly a level-60 player can
make across both quarters lands on exactly 50 (§2.1b).
⚠️ **`palimpsest_belt`'s equip level is 45**, the top of this zone's band and
the floor of the Ethereal one. It is the last Celestial item a player equips and
the first thing Rimeholt sees them wearing.

**Lore and icons**

- `sunbleach_lichen` — *"It grows in the one strip the lenses never sweep. Dried
  and steeped, it is what the readers drank."*
  **Icon:** a flat scab of lichen the size of a hand, bone-white at the centre
  fading to pale ochre at its crinkled edge, peeled whole off pale stone, dry
  and faintly crystalline.
- `aetherglass` ⏳ — *"Archive glass, cut out of a roof. Held at the right angle
  it is still holding a word."*
  **Icon:** a thin square plate of colourless glass the size of a palm, one
  corner broken, standing on edge; Uncommon, so a single faint violet note runs
  along one internal flaw and nothing else is lit.
- `palimpsest_vellum` — *"Scraped clean and written on again, and again. The
  first thing on it is still there and still legible if you stop trying."*
  **Icon:** a single sheet of pale cream vellum the size of a book, lying flat
  with its edges curling, its surface scraped visibly thin in patches where
  older grey script shows faintly through the newer.
- `arcane_dust` — *"You are certain, afterwards, that you knew something."*
  **Icon:** a small heap of fine violet-grey powder, matte, with one cool
  highlight.
- `arcane_shard` — *"Dust that made up its mind."*
  **Icon:** three angular slivers of translucent violet stone, thumbnail-sized,
  fanned with one edge-on.
- `arcane_crystal` — *"It is known, and it does not stop being known."*
  **Icon:** a clear six-sided crystal a thumb long, colourless at the base
  deepening to violet at the tip, one clean unlit violet note.
- `sunbleach_tonic` — *"Pale, bitter, and it works on the way down rather than
  all at once. The readers took it at dawn and finished the day."*
  **Icon:** a tall narrow stoppered bottle the height of a hand holding a cloudy
  bone-white liquid, its shoulder soft and rounded, a strip of written vellum
  tied to its neck as a label with the writing faded out.
- `celestial_totem` — *"Three essences and a socket cut to hold all three. The
  guard above Rimeholt does not take it off you; he looks, and then he steps
  aside."*
  **Icon:** a hand-length rod of dark sky-iron with three small caged spheres
  set along it — gold, silver and indigo — and a fourth empty seat at the top;
  Rare, so all three spheres are real light sources and the iron between them
  is lit by all three at once.
- `palimpsest_belt` — *"Six loops of scraped hide. Someone's handwriting runs
  under the stitching and does not stop at the seam."*
  **Icon:** a wide pale-cream vellum belt laid in a loose open curve with a
  plain brass buckle and **six empty loops** stitched along it, faint grey
  script visible running beneath the stitches.
- `the_last_reading` — *"Whoever was here at the end took one page with them and
  it is this one."*
  **Icon:** a flat rectangular locket of pale glass on a fine chain, standing
  upright, a folded scrap of vellum visible inside it; Rare, so one hard white
  point of light sits at the locket's edge and throws a legible-looking line of
  shadow-writing across the glass.
- `the_noon_hour` — *"For about forty minutes a day it is the most useful object
  in the world. It is worn the other twenty-three hours anyway."*
  **Icon:** a broad circlet of pale archive glass, worn as a band, its front
  panel a flat lens; Epic, so a band of hard white light crosses the lens and
  *travels* — sweeping from one side to the other over several seconds, leaving
  a faint after-image of writing behind it that fades before it can be read.

📝 **Phase 8 hook.** The **Arcane enchant**'s home, and — ⚠️ ITEMS §2.2's watch
item — *"Arcane is the standout candidate"* for an over-strong enchant, since
Arcane Knowledge is permanent, universal and never decays. **Whoever writes the
Arcane enchant should read ITEMS §2.2's last paragraph first.**

---

## 5. The recipe ladder

✅ **28 recipes**, band-scoped and cross-zone, in one file:
`lib/game/items/recipes/celestial_recipes.dart`, registered in `RecipeBook.all`.

📝 **28 is above the ~20–26 guide, and the cause is canon, not sprawl:** ITEMS
§9b.6 puts **three** wood tiers in this band (Ironwood, Bloodwood, Ebony) where
the Kinetic quarter had two, which is nine Woodcarving recipes against six.
📝 The cheapest trim is Bloodwood's wand and knot (→ 26), since Bloodwood sits
only five levels above Ironwood and five below Ebony.

⚠️ **Skill level gates who can MAKE; `equipLevel` gates who can WEAR** (§9b.3).
The two never move together and conflating them kills the twink lane.

### 5.1 The table

XP is `Σ input counts × (4 + 2 × gate)`, computed, not guessed.

| # | Recipe id | Skill | Gate | Inputs (id × count) | Output | **XP** |
|---|---|---|---|---|---|---|
| 1 | `craft_skysteel_ingot` | Metalworking | 36 | `skyiron_ore` ×3, `charcoal` ×2 ⏳ | `skysteel_ingot` | **380** |
| 2 | `craft_starbrass_ingot` | Metalworking | 44 | `orrery_scrap` ×3, `charcoal` ×2 ⏳ | `starbrass_ingot` | **460** |
| 3 | `craft_ironwood_quarterstaff` | Woodcarving | 36 | `ironwood_log` ×3, `iron_ingot` ×1 ⭐ Q2 | `ironwood_quarterstaff` | **304** |
| 4 | `craft_ironwood_wand` | Woodcarving | 36 | `ironwood_log` ×2, `iron_ingot` ×1 | `ironwood_wand` | **228** |
| 5 | `craft_ironwood_knot` | Woodcarving | 36 | `ironwood_log` ×2 | `ironwood_knot` | **152** |
| 6 | `craft_bloodwood_quarterstaff` | Woodcarving | 40 | `bloodwood_log` ×3, `skysteel_ingot` ×1 | `bloodwood_quarterstaff` | **336** |
| 7 | `craft_bloodwood_wand` | Woodcarving | 40 | `bloodwood_log` ×2, `skysteel_ingot` ×1 | `bloodwood_wand` | **252** |
| 8 | `craft_bloodwood_knot` | Woodcarving | 40 | `bloodwood_log` ×2 | `bloodwood_knot` | **168** |
| 9 | `craft_ebony_quarterstaff` | Woodcarving | 44 | `ebony_log` ×3, `starbrass_ingot` ×1 | `ebony_quarterstaff` | **368** |
| 10 | `craft_ebony_wand` | Woodcarving | 44 | `ebony_log` ×2, `starbrass_ingot` ×1 | `ebony_wand` | **276** |
| 11 | `craft_ebony_knot` | Woodcarving | 44 | `ebony_log` ×2 | `ebony_knot` | **184** |
| 12 | `craft_mirrorflax_hood` | Tailoring | 36 | `mirrorflax` ×3 | `mirrorflax_hood` | **228** |
| 13 | `craft_mirrorflax_robe` | Tailoring | 36 | `mirrorflax` ×6 | `mirrorflax_robe` | **456** |
| 14 | `craft_mirrorflax_leggings` | Tailoring | 36 | `mirrorflax` ×5 | `mirrorflax_leggings` | **380** |
| 15 | `craft_mirrorflax_boots` | Tailoring | 36 | `mirrorflax` ×3 | `mirrorflax_boots` | **228** |
| 16 | `craft_mirrorflax_gloves` | Tailoring | 36 | `mirrorflax` ×3 | `mirrorflax_gloves` | **228** |
| 17 | `craft_drownling_belt` | Tailoring | 38 | `drownling_hide` ×2, `mirrorflax` ×1 | `drownling_belt` | **240** |
| 18 | `craft_wrackcotton_hood` | Tailoring | 40 | `wrackcotton` ×3 | `wrackcotton_hood` | **252** |
| 19 | `craft_wrackcotton_robe` | Tailoring | 40 | `wrackcotton` ×6 | `wrackcotton_robe` | **504** |
| 20 | `craft_wrackcotton_leggings` | Tailoring | 40 | `wrackcotton` ×5 | `wrackcotton_leggings` | **420** |
| 21 | `craft_wrackcotton_boots` | Tailoring | 40 | `wrackcotton` ×3 | `wrackcotton_boots` | **252** |
| 22 | `craft_wrackcotton_gloves` | Tailoring | 40 | `wrackcotton` ×3 | `wrackcotton_gloves` | **252** |
| 23 | `craft_palimpsest_belt` | Tailoring | 44 | `palimpsest_vellum` ×2, `wrackcotton` ×1 | `palimpsest_belt` | **276** |
| 24 | `craft_glasswort_draught` | Potions & Alchemy | 34 | `glasswort` ×2 | `glasswort_draught` | **144** |
| 25 | `craft_duskcap_tonic` | Potions & Alchemy | 38 | `duskcap` ×2 | `duskcap_tonic` | **160** |
| 26 | `craft_arcsalt_draught` | Potions & Alchemy | 42 | `arcsalt` ×3 | `arcsalt_draught` | **264** |
| 27 | `craft_sunbleach_tonic` | Potions & Alchemy | 44 | `sunbleach_lichen` ×3 | `sunbleach_tonic` | **276** |
| 28 | `craft_celestial_totem` ⭐ | **Enchanting** | **1** | `solar_essence` ×1, `lunar_essence` ×1, `astral_essence` ×1, `hum_quartz` ×3 ⏳, `fallstone` ×2 | `celestial_totem` | **48** |

⚠️ **#28 sets `stationRequired: true`** and is the only recipe in this contract
that does — see §3.4 for the citation `RecipeDef`'s doc asks for.
⭐ **#3 and #4 spend `iron_ingot`, a Kinetic intermediate.** Metalworking's Q2
feeder lane keeps feeding one quarter later, which is what §6a.1 means by
*"many of those outputs are inputs to other recipes."*
⭐ **#1 and #2 spend `charcoal`, banked in Ashfall Vale at L10.** ⚠️ That is now
the **third** quarter to spend Charcoal, which makes Ashfall Vale a zone a
level-44 player has a reason to walk back to — §9b.6's *"a concrete reason to
revisit old zones,"* achieved by the ore ladder rather than the wood one.

### 5.2 Gate progression — does the ladder actually climb?

`Skills.xpToNext(n) = 20 + 5(n−1)`, so reaching gate *g* costs
`20(g−1) + 5(g−1)(g−2)/2`.

| Gate | XP to reach | Cheapest in-band route | Crafts needed after the previous gate |
|---|---|---|---|
| Potions 34 | 3,300 | ⭐ **from Q2's Saltwort Draught (88)** | ~8 from gate 30, then Glasswort compounds |
| Woodcarving 36 | 3,675 | ⭐ from Q2's Rowan (128–256) | ~4 |
| Tailoring 36 | 3,675 | ⭐ from Q2's Tussock (192–384) | ~3 |
| Tailoring 38 | 4,070 | Mirrorflax Robe (456) | ~1 |
| Potions 38 | 4,070 | Glasswort Draught (144) | ~5 |
| Tailoring 40 | 4,485 | Mirrorflax Robe (456) | ~1 |
| Woodcarving 40 | 4,485 | Ironwood Quarterstaff (304) | ~3 |
| Potions 42 | 4,920 | Duskcap Tonic (160) | ~5 |
| Woodcarving 44 | 5,375 | Bloodwood Quarterstaff (336) | ~3 |
| Tailoring 44 | 5,375 | Wrackcotton Robe (504) | ~2 |
| Metalworking 36 | 3,675 | ⚠️ **from Q2's Iron Ingot (120) only** | **~28** |
| Metalworking 44 | 5,375 | Skysteel Ingot (380) | ~5 |
| **Enchanting 1** | 0 | ⭐ **the debut: nothing to climb** | — |

⭐ **Woodcarving, Tailoring and Potions all enter the quarter already
climbing.** A player who worked Q2's ladder arrives near 30–34.
⚠️ **Metalworking is the quarter's one grind, and it is inherited.** Q2 gave
it exactly two recipes and a gate at 10; reaching 36 off Iron Ingot alone is
~28 crafts of a thing nothing consumes except Rowan weapons. 📝 **The fix is one
recipe, not a curve change:** add `craft_skysteel_fitting` at gate 20 (the
`craft_bronze_fitting` KINETIC §5.1 already offered) and re-point #6, #7, #9 and
#10 at it. Named here rather than taken, because it also changes four recipes'
input lists.
⚠️ **Enchanting opens at Meridian with exactly one recipe and therefore does not
climb at all this quarter.** ⭐ That is deliberate and it is not a hole: the
skill's real ladder is ITEMS §6.2's **Transmute** verb (the Dust → Shard →
Crystal refinement of §6.0, which is not a `RecipeDef` and must not become
twenty-four of them) and Phase 8's enchants. 📝 **Ruling wanted:** does
Transmute pay Enchanting XP? If it does, Enchanting climbs on motes and needs
no recipes; if it does not, Enchanting is a skill nobody can level until
Phase 8, and the Totem's gate of 1 is the only thing keeping it usable.

### 5.3 §6a.1 slot coverage — what this quarter fills

| Slot | Q2 maker | **Q3 maker** | Change |
|---|---|---|---|
| Hat | Tailoring (Seawrack/Tussock) | Tailoring (Mirrorflax/Wrackcotton) | continues |
| Robe Top | Tailoring | Tailoring | continues |
| Robe Bottom | Tailoring | Tailoring | continues |
| Boots | Tailoring | Tailoring | continues |
| Gloves | Tailoring | Tailoring | continues |
| Belt | Tailoring (2 belts) | Tailoring (2 belts: Drownling 5, Palimpsest 6) | continues |
| Main hand | Woodcarving (Yew/Rowan) | Woodcarving (**Ironwood/Bloodwood/Ebony**) | ⭐ three tiers |
| Off hand | Woodcarving (Knot) | Woodcarving (Knot ×3) | continues |
| **Neck** | ⚠️ drop-only | ⚠️ **still drop-only** | unchanged — Jewelry is Rimeholt's |
| **Ring** | ⚠️ drop-only | ⚠️ **still drop-only** | unchanged |
| — | Metalworking feeds 4 | Metalworking feeds 4 (2 ingots → 4 weapons) | continues |
| — | ⚠️ Enchanting empty | ⭐ **Enchanting debuts — 1 recipe, the gate** | newly non-empty |
| — | ⚠️ Jewelry empty | ⚠️ **Jewelry still empty** | ETHEREAL §5.3 closes it |

⭐ **§6a.1's *"every slot has a maker"* is still not true, and this is the last
quarter it is false.** Neck and Ring stay drop-only — all four of this quarter's
jewel materials are ⏳ banking, and Jewelry's debut in the Ethereal quarter
spends **seven** banked gems across three quarters. That is the longest-running
promise in the design docs and it is about to be paid.

### 5.4 ⭐ The potion ladder as a ladder — what a player actually sees

| Band | id | Form | Heal | Beltable? | Where |
|---|---|---|---|---|---|
| 1–5 ✅ | `foragers_ration` | Ration | 25 | no | Whispering Woods |
| 3–8 ✅ | `sapwort_draught` | Draught | 30 | **yes** | Glimmerbrook |
| 10–14 ✅ | `brookmint_tonic` | Tonic | 10×3 | **yes** | Ashfall Vale |
| 15–19 ✅ | `hardtack` | Ration | 60 | no | Old Quarry |
| 23–28 ✅ | `saltwort_draught` | Draught | 75 | **yes** | Stormcliff Coast ⚠️ see §3.3 |
| **30–34** | `pilgrims_ration` | Ration | **110** | no | The Kiln Desert, drop-only |
| **30–34** | `glasswort_draught` | Draught | **125** | **yes** | The Kiln Desert |
| **38–42** | `duskcap_tonic` | Tonic | **34×3** | **yes** | The Sunless Reach |
| **40–44** | `arcsalt_draught` | Draught | **185** | **yes** | The Shattered Orrery |
| **43–47** | `sunbleach_tonic` | Tonic | **42×3** | **yes** | The Glass Archive |
| 45–60 | *five more* | — | — | — | **ETHEREAL §3.3** |

⚠️ **The Ration lane has exactly one rung per quarter and is always drop-only.**
It is the only consumable a player can find without a Potions skill, which is
what makes it the floor. ⭐ **The Tonic lane is the one a player will
under-rate**, because 24% paid over three turns looks worse than 40% paid now —
and in a duel where the opponent commits blind, a heal that lands *after* their
read is often the better one. 📝 That is worth a tooltip, not a number change.

### 5.5 Value conservation — the ECONOMY §8 audit, run in advance

⚠️ ECONOMY §8.2's rule: `Σ(inputs)` must land in **[Standard value, Ornate
value]** = `[v, 1.2v]`. **Falling under Standard is the exploitable direction**
(a risk-free buy→craft→vendor loop); falling over Ornate is merely bad crafting
EV. Every material value in §3.1 and §4 was back-solved from this.

| Recipe | Σ(inputs) | Output value | Window | Verdict |
|---|---|---|---|---|
| #1 skysteel_ingot | 3×26 + 2×7 = 92 | 110 | [110, 132] | ⚠️ **under by 16%** — see below |
| #2 starbrass_ingot | 3×48 + 2×7 = 158 | 200 | [200, 240] | ⚠️ under by 21% — same note |
| #3 ironwood_quarterstaff | 3×240 + 52 = 772 | 620 | [620, 744] | over Ornate 4% ✅ safe |
| #4 ironwood_wand | 2×240 + 52 = 532 | 530 | [530, 636] | ✅ |
| #5 ironwood_knot | 2×240 = 480 | 440 | [440, 528] | ✅ |
| #6 bloodwood_quarterstaff | 3×450 + 110 = 1460 | 1150 | [1150, 1380] | over 6% ✅ safe |
| #7 bloodwood_wand | 2×450 + 110 = 1010 | 990 | [990, 1188] | ✅ |
| #8 bloodwood_knot | 2×450 = 900 | 820 | [820, 984] | ✅ |
| #9 ebony_quarterstaff | 3×810 + 200 = 2630 | 2100 | [2100, 2520] | over 4% ✅ safe |
| #10 ebony_wand | 2×810 + 200 = 1820 | 1800 | [1800, 2160] | ✅ |
| #11 ebony_knot | 2×810 = 1620 | 1500 | [1500, 1800] | ✅ |
| #12–16 mirrorflax ×3/6/5/3/3 | 264 / 528 / 440 / 264 / 264 | 265 / 530 / 440 / 265 / 265 | — | ⭐ **Σ = output, zero margin** — ECONOMY §8.6's blessed boundary case, as `seawrack_hood` already ships |
| #17 drownling_belt | 2×300 + 88 = 688 | 750 | [750, 900] | ⚠️ under 8% |
| #18–22 wrackcotton ×3/6/5/3/3 | 450 / 900 / 750 / 450 / 450 | same | — | ⭐ Σ = output |
| #23 palimpsest_belt | 2×480 + 150 = 1110 | 1110 | [1110, 1332] | ⭐ Σ = output |
| #24 glasswort_draught | 2×28 = 56 | 55 | [55, 66] | ✅ |
| #25 duskcap_tonic | 2×36 = 72 | 70 | [70, 84] | ✅ |
| #26 arcsalt_draught | 3×32 = 96 | 95 | [95, 114] | ✅ |
| #27 sunbleach_tonic | 3×37 = 111 | 110 | [110, 132] | ✅ |
| #28 celestial_totem | essences 0, hum_quartz 3×20, fallstone 2×60 = 180 | **0** | — | ⚠️ **exempt** — `KeyDef` forces `value: 0`, Bound, and cannot be vendored |

⚠️ **Three rows fall under Standard and all three are the same shape: an
intermediate or a belt whose raw ore/hide is cheap.** ECONOMY §8.5 already met
this with `emberhide` and named it an outlier rather than a bug. 📝 **The fix,
if wanted, is one number each:** `skyiron_ore` 26 → 32, `orrery_scrap` 48 → 62,
`drownling_hide` 300 → 331. Each is inside the flat-material pattern ECONOMY
§8.2 describes and none of them breaks another recipe, because each ore and
hide feeds exactly one recipe. **Left unchanged here so the designer can see
the shape rather than a patched table.**
⚠️ **Motes are deliberately absent from every recipe.** ECONOMY §14c makes them
sell-only and lossy against the refinement ladder; putting one in a gear recipe
would make refine-and-craft a second, unaudited arbitrage.

---

## 6. Gather nodes

✅ **17 nodes.** ⚠️ **Two materials get none**, because hides are kill-only
(§9b.7b): `drownling_hide` and `palimpsest_vellum`.
✅ **Skill is read off the material's consuming skill** per §6a.1 — Woodcarving
← Felling, Tailoring/Potions ← Foraging, Jewelry (gems) + Metalworking (ore)
← Mining. ⭐ **Enchanting ← Mining for `fallstone`** is the one mapping §6a.1
does not print, and the precedent is already shipped: `amber` is a Jewelry
material gathered by Mining because *"gems are Mining's half"* — a fallstone is
prised out of a crater floor with the same tool.
✅ **XP is `9 + 2 × (zone.minLevel − 1)`.**

| id | Zone | Skill | Yields | min–max | **XP** | Gesture 📝 | Flavour hook |
|---|---|---|---|---|---|---|---|
| `kd_ironwood_stand` | the_kiln_desert | Felling | `ironwood_log` | 2–4 | **67** | `releaseTiming 'chop' reps 5` | Four trees in eleven miles, and every one of them older than the road |
| `kd_glasspan_flat` | the_kiln_desert | Foraging | `glasswort` | 2–3 | **67** | `trace 'pick' complexity 3` | The only green thing out here grows in the one place with no water at all |
| `mm_bloodwood_grove` | the_mirrormere | Felling | `bloodwood_log` | 2–4 | **71** | `releaseTiming 'chop' reps 5` | They lean out over the water and the water shows them leaning back |
| `mm_mirrorflax_shallows` | the_mirrormere | Foraging | `mirrorflax` | 2–3 | **71** | `rateDrag 'draw' reps 3` | Retted where the lake does not move. Pull steadily or you pull it in two |
| `sb_skyiron_field` | starfall_basin | Mining | `skyiron_ore` | 2–4 | **75** | `sweetSpot 'strike' reps 5` | The bottom of a shallow bowl, and the thing in it did not come from the bowl |
| `sb_fallstone_crater` | starfall_basin | Mining | `fallstone` | 2–3 | **75** | `alignCommit 'pry' complexity 3` | Deeper than the others, with something at the bottom that weighs right and looks wrong |
| `ts_wrackcotton_flat` | tidewrack_shoals | Foraging | `wrackcotton` | 2–4 | **79** | `rateDrag 'draw' reps 3` | Six hours of flat, and then it is not flat any more |
| `ts_nacre_bed` | tidewrack_shoals | Mining | `nacre` | 2–3 | **79** | `alignCommit 'prise' complexity 3` | A shell bed the water uncovers twice a day and has never once uncovered empty |
| `sr_ebony_stand` | the_sunless_reach | Felling | `ebony_log` | 2–4 | **83** | `releaseTiming 'chop' reps 5` | Black trunks on black rock. You find them by walking into them |
| `sr_duskcap_shelf` | the_sunless_reach | Foraging | `duskcap` | 2–3 | **83** | `trace 'pick' complexity 3` | They fruit along the line the light stops at, in a row, like something planted them |
| `sr_opal_seam` | the_sunless_reach | Mining | `eclipse_opal` | 2–3 | **83** | `alignCommit 'split' complexity 4` | Split it wrong and you get two dull halves. Split it right and you get the line |
| `so_scrap_ring` | the_shattered_orrery | Mining | `orrery_scrap` | 2–4 | **87** | `sweetSpot 'strike' reps 5` | A fallen ring, still turning, and shedding teeth as it goes |
| `so_arcsalt_earthing` | the_shattered_orrery | Foraging | `arcsalt` | 2–4 | **87** | `rateDrag 'scrape' reps 3` | Where the machine has been putting its charge for four centuries. Scrape between the flashes |
| `so_lens_shatter` | the_shattered_orrery | Mining | `sidereal_glass` | 2–3 | **87** | `alignCommit 'lift' complexity 4` | A ring came down here and most of what it was made of is still edge-up |
| `ga_shadeline_lichen` | the_glass_archive | Foraging | `sunbleach_lichen` | 2–3 | **93** | `trace 'peel' complexity 3` | The one strip of hillside the lenses never sweep, and the only thing alive on it |
| `ga_roof_spoil` | the_glass_archive | Mining | `aetherglass` | 2–3 | **93** | `bandKeeper 'anneal'` ⭐ | Roof glass, off a roof. Let it cool too fast and you get sand |
| `ga_noon_shelf` | the_glass_archive | Mining | `aetherglass` | 2–3 | **93** | `placement 'choose' complexity 4` ⭐ | Around midday the whole shelf is writing. Take a plate from where the writing is not |

⚠️ **The Glass Archive has two nodes on the same material** and that is the one
place this contract breaks its own shape. ⭐ The reason is the hybrid rule: a
hybrid may have three nodes, the Archive's third material is a kill-only hide,
and `aetherglass` is the material whose fiction supports being gathered two
ways — annealed off a roof, or chosen out of the noon writing. 📝 **Cut
`ga_noon_shelf` to 16 nodes if one-node-per-material is a rule rather than a
habit.** Nothing else depends on it.

⭐ **Every gathering skill stays levelable, and the balance has shifted:**
Felling 3 · Foraging 6 · Mining 8. Mining became a real ladder in the Kinetic
quarter and is now the quarter's dominant gather skill, which suits a band whose
zones are a crater field, a machine and an archive.
⚠️ **`ga_roof_spoil` uses `bandKeeper` and `ga_noon_shelf` uses `placement`** —
`placement` has never been used by a gather node. ⭐ Deliberate, and the fiction
names its own engine: *"Choose WHERE — judgment of spacing, not motor skill."*
Choosing which plate of the archive to take is exactly that. 📝 Swap to
`alignCommit` if a fourth gather engine is unwelcome.

---

## 7. Cross-checks appendix

### 7.1 Counts

| Thing | Count | Check |
|---|---|---|
| **Item definitions** | **76** | Kiln Desert 13 · Mirrormere 16 · Starfall 9 · Tidewrack 11 · Sunless Reach **9** · Orrery 7 · Glass Archive 11 |
| — materials | 18 | ✅ 2+2+2+3+3+3+3 (§9b.8 ruling 7) — four ⏳ bank to Rimeholt |
| — gate parts | 3 | `solar_essence`, `lunar_essence`, `astral_essence` — ⚠️ **not counted as materials**, §3.4 |
| — motes | 12 | 4 families × dust/shard/crystal. ⚠️ No Core, no Heart (§3.2) |
| — consumables | 5 | 1 Ration (drop-only) · 2 Draughts · 2 Tonics |
| — intermediate goods | 2 | `skysteel_ingot`, `starbrass_ingot` |
| — equipment | 35 | 21 crafted (9 weapons · 10 armour · 2 belts) + 7 rare + 7 epic |
| — keys | 1 | `celestial_totem` — ✅ one id on one gate |
| **Recipes** | **28** | Woodcarving 9 · Tailoring 12 · Potions 4 · Metalworking 2 · Enchanting 1 · Jewelry 0 |
| **Gather nodes** | **17** | 18 materials − 2 kill-only hides + 1 second Archive node |
| New files | **9** | 7 catalogues, 1 recipe file, 17 nodes appended to `GatherNodes` — plus registrations |

Equipment, broken out: **21 crafted** (3 staves, 3 wands, 3 knots, 10 armour
pieces, 2 belts) + **7 rare** + **7 epic** = **35**. ⚠️ The totem is a `KeyDef`,
not equipment, and the three essences are `MaterialDef`s. Sum: 18 materials + 3
gate parts + 12 motes + 5 consumables + 2 intermediates + 1 key + 35 equipment
= **76 defs, 35 of them `EquipmentDef`.**

⚠️ **Registration is where a silent failure lives.** Every catalogue must be
listed in `ItemCatalogue.byZone` keyed by its **real `world.dart` zone id**; the
recipe file in `RecipeBook.all`; every node in `GatherNodes.all`; and
⚠️ **`rimeholt.gateItemIds` must be set to `['celestial_totem']` in
`world.dart`** or the gate checks nothing and the whole §3.4 design is a lore
line.

### 7.2 Id uniqueness against the shipped game

Checked mechanically against the **610 ids** currently in
`lib/game/items/catalogue/`, `lib/game/items/recipes/`, `lib/game/gathering/`
and `lib/game/enemies/`:

> ✅ **76 item ids + 28 recipe ids + 17 node ids = 121 new ids.** Zero
> collisions with shipped ids, and zero duplicates among themselves.

Near-misses worth knowing about, all distinct and all deliberate:

| Pair | Why it is fine |
|---|---|
| ENEMIES' *Sky-Iron Husk* / material `skyiron_ore` | different namespaces; Q1 precedent creature `heartwood` / item `heartwood_stave` |
| ENEMIES' *Palimpsest* (a Siphon) / material `palimpsest_vellum` | ✅ exactly the `the_overseer` / `overseers_seal` pairing §9b.8 ruling 9 blessed |
| ENEMIES' *Glasspan Crawler* / node `kd_glasspan_flat` | node ids live in their own namespace |
| `the_shadeless_band` / ENEMIES' *Shadeless*, *The Shadeless Hour* | ⚠️ three "Shadeless" strings in one zone. Distinct ids; 📝 the **display** names may read as a set they are not |
| `eclipse_opal` / `the_eclipsed_citadel` / ITEMS §9b.5b's reserved *Eclipsed* | ⚠️ §9b.5b reserves **"Eclipsed"** as an aspect prefix collision and names the Citadel as the reason. `eclipse_opal` is a noun, not the prefix, and no aspect prefix is used in this contract at all |
| `arcane_dust` defined in a Celestial file | ⚠️ intentional (§3.2). A builder looking for it in the Ethereal quarter will not find it |
| node prefixes `kd_ mm_ sb_ ts_ sr_ so_ ga_` | none collide with `ww_ gb_ cp_ tm_ av_ oq_ sc_ ws_ ff_ tp_ md_` |

### 7.3 Every drop-table id resolves

| Zone | Ids referenced | All defined? |
|---|---|---|
| the_kiln_desert | `solar_*` `ironwood_log` `glasswort` `solar_essence` `pilgrims_ration` `the_shadeless_band` `the_hardest_edge` | ✅ all local |
| the_mirrormere | `lunar_*` `bloodwood_log` `mirrorflax` `lunar_essence` `pilgrims_ration` `glasswort_draught` `the_waning_charm` `the_larger_reflection` | ✅ consumables from the Kiln Desert, rest local |
| starfall_basin | `astral_*` `skyiron_ore` `fallstone` `astral_essence` `pilgrims_ration` `glasswort_draught` `zodiac_pendant` `the_aimed_sky` | ✅ |
| tidewrack_shoals | `lunar_*` `aqua_*` ✅ **Q1** `wrackcotton` `nacre` `drownling_hide` `pilgrims_ration` `glasswort_draught` `the_turning_tide` `lowwater_tread` | ✅ `aqua_*` resolve to `glimmerbrook_items.dart` |
| the_sunless_reach | `solar_*` `lunar_*` `ebony_log` `duskcap` `eclipse_opal` `pilgrims_ration` `duskcap_tonic` `crestline_ring` `the_dividing_line` | ✅ |
| the_shattered_orrery | `astral_*` `electro_*` ✅ **Q2** `orrery_scrap` `arcsalt` `sidereal_glass` `pilgrims_ration` `arcsalt_draught` `sidereal_signet` `the_running_count` | ✅ `electro_*` resolve to `stormcliff_coast_items.dart` |
| the_glass_archive | `solar_*` `arcane_*` `sunbleach_lichen` `aetherglass` `palimpsest_vellum` `pilgrims_ration` `arcsalt_draught` `sunbleach_tonic` `the_last_reading` `the_noon_hour` | ✅ |

⭐ **Two cross-quarter references, both deliberate:** `aqua_*` (Q1) at Tidewrack
and `electro_*` (Q2) at the Orrery — the hybrid rule working as designed, and
the only reason a level-40 player ever sees an Electro Dust again.

✅ **Every drop role has an item to resolve to.** The roster lane needs, per
zone: one or two `material` commons, one `hide` common where the zone has a
hide (Tidewrack, Glass Archive), and nothing else — motes ride
`_commonAlways`, uniques ride the mini and boss pools, and the gate parts ride
the boss pool's `always` line in the three pure zones.

### 7.4 Every recipe input is obtainable in-band

| Input | Source | In band? |
|---|---|---|
| `charcoal` ⏳ | `av_charcoal_burn`, Ashfall Vale 10–14 | ✅ banked, re-farmable |
| `iron_ingot` | crafted, Q2 #2 (`iron_ore` at `tp_iron_seam`) | ✅ re-farmable |
| `hum_quartz` ⏳ | `tp_humming_face`, Thunderspire 17–22 | ✅ banked since Q2 — ⭐ **spent at last** |
| `ironwood_log` | `kd_ironwood_stand` + Kiln Desert commons | ✅ |
| `glasswort` | `kd_glasspan_flat` + Kiln Desert commons | ✅ |
| `bloodwood_log` | `mm_bloodwood_grove` + Mirrormere commons | ✅ |
| `mirrorflax` | `mm_mirrorflax_shallows` + Mirrormere commons | ✅ |
| `skyiron_ore` / `skysteel_ingot` | `sb_skyiron_field` + Starfall commons / crafted #1 | ✅ |
| `fallstone` | `sb_fallstone_crater` + Starfall commons | ✅ |
| `wrackcotton` | `ts_wrackcotton_flat` + Tidewrack commons | ✅ |
| `drownling_hide` | ⚠️ Tidewrack **kills only** — the hide common, minis, boss | ✅ by design |
| `ebony_log` | `sr_ebony_stand` + Sunless Reach commons | ✅ |
| `duskcap` | `sr_duskcap_shelf` + Sunless Reach commons | ✅ |
| `orrery_scrap` / `starbrass_ingot` | `so_scrap_ring` + Orrery commons / crafted #2 | ✅ |
| `arcsalt` | `so_arcsalt_earthing` + Orrery commons | ✅ |
| `sunbleach_lichen` | `ga_shadeline_lichen` + Archive commons | ✅ |
| `palimpsest_vellum` | ⚠️ Archive **kills only** — the hide common, minis, boss | ✅ by design |
| `solar_essence` / `lunar_essence` / `astral_essence` | ⚠️ **boss pools only**, guaranteed | ✅ by design — §3.4 |

⚠️ **Four materials have no Celestial consumer, by design** (⏳ banking to
Rimeholt, L45): `nacre`, `eclipse_opal`, `sidereal_glass`, `aetherglass`.
⚠️ **A test must assert all four unconsumed**, exactly as Q1's suites had to for
Copper and Amber and Q2's for six. ⭐ Kinetic's six shrink to **two**
(`hoarlichen`, `firesalt` — still waiting on the Antidote) because this quarter
spends `hum_quartz` and the Ethereal one spends `quarry_jasper`, `everice` and
`obsidian`.

### 7.5 Economy and balance invariants

| Invariant | Where it is honoured |
|---|---|
| Dust drops routinely | Every `_commonAlways`, chance 0.75 (0.5 + 0.5 in hybrids) |
| Shard is occasional | Main tables, weight 5–8; one guaranteed per mini |
| Crystal is rare, mini/boss only | `_miniDrops` chance 0.25; `_bossDrops` guaranteed 1–2. ⚠️ **Never on a common** |
| Core never drops | ✅ none defined — §3.2, with the ITEMS §9 tension named |
| Hearts are craft-only | ✅ none defined |
| Motes are sell-only, lossy, uniform per tier | ✅ ECONOMY §14c values used verbatim; ⚠️ **no mote is a recipe input** (§5.5) |
| Rare components only off difficult enemies | ✅ no `ComponentDef` — §3.4 explains why the essences are not one |
| **Gear rarity stays common/rare/epic** | ✅ 21 crafted Commons, 7 Rares, 7 Epics. No Uncommon, Mythic or Legendary equipment |
| Common rarity = flat stats only (§8) | ✅ every crafted piece carries flat numbers or a paired chance/amount, per KINETIC §7.5 |
| Belts are capacity, never power (§6b.2) | ✅ both belts are `beltSlots` alone |
| Crafted is the floor, drops are the ceiling (§9b.4a) | §2.6: crafted-only ≈ 5.7 levels, best-in-slot ≈ 9.9 |
| **`Σ deflectAmount ≤ 50` across best-in-slot** | ✅ 38 at L47 (Wrackcotton gloves 24 + `the_noon_hour` 14); 50 exactly across both quarters — §2.1b |
| **`Σ accuracy ≤ 30` across best-in-slot** | ✅ 21 at L47 — §2.1a. Crafted-only 16 |
| **Enemy dodge ≤ 10** | ✅ §2.3 and §2.4; Luna Plena and The First Dark are at the cap and are the only two |
| Player deflect design cap 50 / engine clamp 90 | ✅ never approached |
| A potion heals less than a same-tier cast (§6b.3) | ✅ §3.3's ceiling check |
| No sets, no enchants, no gems (Phase 8) | ✅ zero `setId`, zero `setTier`; `socketCount` only, per §4.1a |

### 7.6 What the shipped test suites will need

One file per zone, mirroring `test/frostfell_pass_test.dart`:

- every def id resolves through `ItemCatalogue`, and every drop id resolves
- ⚠️ **no Crystal on any common table**
- ⚠️ **no Core or Heart mote exists**
- ⚠️ `nacre`, `eclipse_opal`, `sidereal_glass`, `aetherglass` asserted
  **unconsumed** (§7.4)
- ⚠️ `hum_quartz` asserted **consumed** — ⭐ the inverse assertion, and the one
  that proves the Kinetic banking clause was paid
- ⚠️ every `EquipmentDef.equipLevel` sits **inside its zone's band**; every
  `MaterialDef` and `KeyDef` sits at 1
- ⚠️ crafted equipment leaves `properName` null; every drop-only rare and epic
  sets it (a test already enforces the first half)
- ⚠️ `twoHanded` is true on every Quarterstaff and false on everything else
- ⚠️ **`World.byId('rimeholt').gateItemIds == ['celestial_totem']`**, and
  `celestial_totem.gates == 'rimeholt'` — the two halves of §3.4, asserted
  against each other
- ⚠️ every recipe's `Σ(inputs)` checked against `[value, 1.2 × value]` with the
  four §5.5 exceptions listed by id, so a fifth cannot appear silently
- ⚠️ **`Σ deflectAmount` over any legal loadout ≤ 50** (§2.1b) — the one
  invariant that cannot be checked per item
- node XP equals `9 + 2 × (minLevel − 1)`; recipe XP equals
  `Skills.xpForRecipe`
- ⚠️ **no zone defines a mote family a lower-band zone already defines** — the
  assertion that would have caught `arcane_*` being written twice

---

## 8. Decisions — open, for red-pen

⚠️ Unlike KINETIC §8, **these are not ruled.** They are the questions this
contract could not answer for itself.

### 8.1 ❓ Does dodge count toward "gear ≈ ten levels"?

§2.6 finding 2. Excluding it (the published reading) puts this quarter at 9.9
levels and Kinetic at 10.7; including it puts them at 12.2 and 12.6. **Either
answer is defensible and they imply different dodge budgets across four
quarters.** This contract holds dodge flat so the choice stays cheap.

### 8.2 ❓ Does Enchanting climb on Transmute?

§5.2. If mote refinement pays Enchanting XP, the skill needs no recipes and the
Totem's gate of 1 is merely convenient. If it does not, Enchanting is
unlevelable until Phase 8.

### 8.3 ❓ Core motes — here, with Phase 8's gems, or never?

§3.2. ITEMS §9's band table puts Core at 45–50; this contract and the Ethereal
one both omit it because nothing consumes it before Phase 8.

### 8.4 ❓ Is the affinity table right?

§2.5a. Seven elements had no gear affinity and four of them ship gear in this
quarter. The *structure* (a higher element inherits and sharpens a lower one's
lean) is the part worth ruling; the individual assignments are 📝.

### 8.5 ❓ Accuracy's ceiling — cap the ladder, or raise enemy dodge?

§2.1a. This contract caps the ladder because that is the smaller change. The
alternative is a **roster** change: let enemy dodge climb above ENEMIES §2.5's
value of 10 in the Celestial and Ethereal bands.

### 8.6 ❓ Does the Concordance gate take the Totem's shape?

§3.4. The Kinetic Sigil's mechanism is still unbuilt and `gateItemIds` on
`concordance` is still empty. One crafted sigil at Forgeholm, from three
Kinetic essences, is the obvious parallel — but it is the Kinetic lane's to
take.

### 8.7 📝 Four recipes fall under their conservation window

§5.5. Three ore/hide values and one belt. The fix is three numbers; the
alternative is to accept them as ECONOMY §8.5 outliers.

---

## 9. Fast-follow

- **Antidote + offensive potion** — unchanged from KINETIC §9: needs
  `ItemEffect` vocabulary the engine lacks and a ruling on what the offensive
  one *does* (SYSTEMS §3.7). Materials still banked (`hoarlichen`, `firesalt`).
  ⭐ **The grammar is now settled** (§3.3), so when they land they are a fourth
  and fifth **form**, not a redesign.
- **Sets, enchants, sockets** — SYSTEMS §3, Phase 8. Every zone's 📝 hook says
  what it would carry.
- **Core motes and gems** — §8.3.
- **The Concordance gate** — §8.6, the Kinetic lane's.

---

## Appendix A — file manifest for builders

| File | Contents | Registered in |
|---|---|---|
| `lib/game/items/catalogue/the_kiln_desert_items.dart` | 13 defs | `ItemCatalogue.byZone['the_kiln_desert']` |
| `lib/game/items/catalogue/the_mirrormere_items.dart` | 16 defs | `…['the_mirrormere']` |
| `lib/game/items/catalogue/starfall_basin_items.dart` | 9 defs | `…['starfall_basin']` |
| `lib/game/items/catalogue/tidewrack_shoals_items.dart` | 11 defs | `…['tidewrack_shoals']` |
| `lib/game/items/catalogue/the_sunless_reach_items.dart` | 9 defs | `…['the_sunless_reach']` |
| `lib/game/items/catalogue/the_shattered_orrery_items.dart` | 7 defs | `…['the_shattered_orrery']` |
| `lib/game/items/catalogue/the_glass_archive_items.dart` | 11 defs | `…['the_glass_archive']` |
| `lib/game/items/recipes/celestial_recipes.dart` | 28 `RecipeDef` | `RecipeBook.all` |
| `lib/game/gathering/gather_node.dart` | +17 `GatherNodeDef` | `GatherNodes.all` |
| `lib/game/world.dart` | ⚠️ **+`gateItemIds: ['celestial_totem']` on `rimeholt`** | — |
| `docs/ITEM_ART.md` | +7 zone sections, 76 entries | `tool/artgen.py` parses it |
| `test/<zone>_test.dart` × 7 | §7.6 | — |

⚠️ **The shared seams:** `celestial_recipes.dart`, `gather_node.dart`,
`ItemCatalogue.byZone`, `world.dart` and `ITEM_ART.md` are **shared**. Assign
each one owner, or the merge is seven conflicting edits to the same list.
⚠️ **This quarter depends on KINETIC §2.2's engine seam** (`EnemyDef`'s combat
stat block and `OpponentDriver.opponentCombatStats`). If it has not landed, it
is a prerequisite, not a parallel lane.

---

## Changelog

**2026-09-22 — first draft.** Written against `ae9743c` on Christian's
2026-09-22 rulings. Mirrors KINETIC_CONTRACT's structure section for section.
Numbers computed from the shipped engine, not estimated: the §2.6 method is
validated against KINETIC §2.6's own published best-in-slot figure (10.71 vs
10.7) before being applied here. Id uniqueness verified mechanically against
610 shipped ids. Three findings are new to any contract — accuracy's hard
ceiling (§2.1a), deflect amount's summing breach of the 50% design cap (§2.1b),
and dodge as the uncounted third multiplier in the gear-levels invariant
(§2.6). The potion vocabulary (KINETIC §9's debt) is settled in §3.3, and the
Rimeholt gate ships as a crafted Totem rather than a collection (§3.4).
