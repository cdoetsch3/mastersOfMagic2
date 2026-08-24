# Kinetic Quarter — Content Contract

Status: 📝 **draft, for red-pen.** Written 2026-08-24 against the shipped Q1
implementation. ⚠️ **Nothing here is built.** This document is the single
source four parallel builders implement from, and the merge coordinator
verifies code against.

**Scope:** the six Kinetic zones, Lv 15–29 — 66 creatures, 64 item
definitions, 26 recipes, 13 gather nodes.

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
> the shipped catalogues). A builder who invents an id has broken the
> contract; a builder who renames one has broken a save.

---

## 0. What is canon and what is proposed

### 0.1 Canon — do not change without changing the source doc

| Fact | Source |
|---|---|
| Six zones, ids and bands | `lib/game/world.dart` — `old_quarry` 15–19 · `stormcliff_coast` 17–22 · `windward_steppe` 19–24 · `frostfell_pass` 21–26 · `thunderspire_peaks` 23–28 · `the_molten_deep` 25–29 |
| Zone themes and the quote each was recovered from | ENEMIES §2e |
| All 66 creature **names**, and each common's archetype | ENEMIES §2e |
| Every mini's and boss's archetype | ENEMIES §2g |
| Anchor names (✅ below) | `World.opponentNameFor` |
| Re-homed element-roster names (✅✅ below) | GAME_DESIGN §5, re-homed in ENEMIES §2c |
| Archetype coefficients | `lib/game/enemies/enemy_archetype.dart` |
| The HP curve | `MageState.scaledMaxHp` = `round(100 × 1.04^(L−1))` |
| Raw move damage stays in the Whispering Woods band | CONTENT_CHECKLIST, "the one rule that governs every future zone's numbers" |
| Yew at equip 20 (Windward Steppe), Rowan at 25 (Thunderspire) | ITEMS §9b.6 |
| Craft XP = `Σ input counts × (4 + 2 × gate)` | `Skills.xpForRecipe` |
| Node XP = `9 + 2 × (zone.minLevel − 1)` | `GatherNodes`, ITEMS §9b.7b |
| Hides and motes are **kill-only**, never a node | ITEMS §9b.7b |
| Materials: 2 per pure zone, 3 per hybrid | ITEMS §9b.8 ruling 7 |
| Every mote tier below Heart drops; Hearts are craft-only | ITEMS §6.0, §8 |
| The Overseer's Seal is Q2's, dropped by its namesake in the Old Quarry | ITEMS §9b.8 ruling 9 |
| The Kinetic Sigil is three essences, one per Kinetic **pure** zone | NARRATIVE §4b.1/§4b.2 |

### 0.2 The four standing rulings this contract encodes (Christian, 2026-08-19)

1. **Stat curve L15–29 = the shipped Q1 curve, extrapolated.** §1.
2. **Crit / dodge / deflect come online this quarter, from both sides.** §2.
3. **Recipe density matches Q1 (~20–26); Metalworking and Jewelry debut on
   Q1's banked materials plus this quarter's.** §5.
4. **The Molten Deep ships as a standard 3-section adventure.** The
   descending-dungeon structure is a later feature; the roster below is
   written to fit `Adventure`'s existing shape.

### 0.3 What this contract deliberately does NOT specify

- ⚠️ **Move names, move ids and per-move numbers**, beyond the raw-damage band
  table in §1.3 and the per-archetype move *shape* already in
  `EnemyArchetype` (`moveCount`, `minMoveCost`, `maxMoveCost`). Writing 160
  spells here would duplicate the archetype layer. Builders author them
  against §1.3 and the §1.5 naming rule, using the id prefixes in §7.1.
- **Lore strings**, beyond the voice note in §1.5.
- **Arrival / beat / epilogue copy** — that is `world.dart`'s and
  WORLD_DESIGN's, not the bestiary's.
- **Art briefs** — BESTIARY_ART and ITEM_ART own those.

---

## 1. The baseline statline

### 1.1 The formula — read off the shipped engine, not invented

There is **no second curve**. An enemy is the level baseline times its
archetype (ENEMIES §1.1), and both halves already exist in code:

```
maxHp(archetype, L)    = round( round(100 × 1.04^(L−1)) × archetype.hpScale )
                         ─ MageState.scaledMaxHp × EnemyDef.maxHpAt

damage(archetype, L)   = round( rawRoll × 1.04^(L−1) × archetype.damageScale )
                         ─ DuelEngine: caster.levelScale × caster.powerScale
```

⭐ **The extrapolation to L15–29 is therefore: do nothing.** `1.04^(L−1)` is
already defined for every level; the archetype coefficients are already
constants; `EnemyDef.maxHpAt` already composes them. **Kinetic content
extends the curve by supplying levels, not numbers.**

⚠️ **This is the single most important thing a builder can get wrong.**
CONTENT_CHECKLIST states it as the governing rule for every future zone:

> *"Raw damage stays in the Whispering Woods band (worst case ≤ 60, ≤ 11 per
> charge)… a zone's higher band arrives through the **encounter level**, never
> through bigger raws. Ashfall Vale at 10–14 uses the same numbers as the
> Woods at 1–5."*

Verified against the shipped rosters: the Ashfall Vale Bruiser's opener is
`DamageEffect(11, 15)` at levels 10–14, and the Whispering Woods Bruiser's is
`DamageEffect(11, 15)` at levels 1–5. **Kinetic uses the same table again.**
📝 There is ±8% drift inside Q1 (the Champion opener is 12–16 in the Woods and
13–17 in three later zones); treat that as noise to be cleaned, not a slope to
continue.

### 1.2 Worked HP table — the numbers to red-pen

`scaledMaxHp` at the three sample levels: **L15 = 173 · L22 = 228 · L29 = 300.**
(`1.04^14 = 1.7317`, `1.04^21 = 2.2788`, `1.04^28 = 2.9987`.)

| Archetype | Tier | HP× | DMG× | **HP @15** | **HP @22** | **HP @29** |
|---|---|---|---|---|---|---|
| Drudge | common | 0.80 | 0.70 | 138 | 182 | 240 |
| Skirmisher | common | 0.70 | 1.15 | 121 | 160 | 210 |
| Lasher | common | 0.85 | 1.00 | 147 | 194 | 255 |
| Glasswing | common | 0.50 | 1.70 | 86 | 114 | 150 |
| Adept | common | 1.00 | 0.90 | 173 | 228 | 300 |
| Sentinel | common | 1.25 | 0.70 | 216 | 285 | 375 |
| Bruiser | common | 1.15 | 1.10 | 199 | 262 | 345 |
| Blighter | common | 1.00 | 0.60 | 173 | 228 | 300 |
| Champion | mini | 1.70 | 1.20 | 294 | 388 | 510 |
| Redoubt | mini | 2.20 | 0.85 | 381 | 502 | 660 |
| Executioner | mini | 1.20 | 1.90 | 208 | 274 | 360 |
| Hexer | mini | 1.60 | 0.75 | 277 | 365 | 480 |
| Juggernaut | boss | 3.60 | 1.40 | 623 | 821 | **1080** |
| Tyrant | boss | 2.60 | 1.70 | 450 | 593 | 780 |
| Aspect | boss | 2.60 | 1.50 | 450 | 593 | 780 |

⚠️ **Siphon (0.95/0.85) is absent from the Kinetic quarter on purpose** —
ENEMIES §2f: *"the Siphon is in 12 of 25 zones and that dilutes it… a shock
that happens in half the zones is not a shock."* No §2e Kinetic roster fields
one, and none should be added.

📝 **The number most worth a second look is 1080** — The Slow Stone at L29.
That is 3.6× a level-29 player's whole health bar, met with a player who has
no gear scaling in kind (§2.6). Juggernaut's 3.60 was set for the Primal band,
where the same coefficient produces 623 at L15 and 601 for Heartwood at L5.
It has never been fought at the top of a fifteen-level quarter.

### 1.3 The raw-damage authoring table 📝 — ⚠️ tier-aware

⭐ **This is the whole of what a builder authors.** Level scaling and the
archetype multiplier are applied by the engine; these are the numbers that go
in the `DamageEffect`.

⚠️ **A common and a boss do NOT use the same raw at the same charge cost.**
Read off the shipped Q1 rosters: the common Bruiser's five-charge move is
`DamageEffect(30, 38)` and the boss Juggernaut's is `DamageEffect(44, 54)`.
Ignoring this row-split is the easiest way to ship a common that hits like a
boss.

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

⚠️ **Hard ceiling: ≤ 60 raw on any one move, ≤ 12 raw per charge** — every
cell above obeys it, and the Kinetic suites must pin it as the Q1 suites do.

Per-archetype adjustments, continuing Q1's practice. **Cost band comes from
`EnemyArchetype`'s `minMoveCost`/`maxMoveCost` and is not a choice.**

| Archetype | Moves × cost band ✅ | Raw treatment |
|---|---|---|
| Drudge | 1 × cost 1 | **−20%** (4–7) — its incompetence is in the number too |
| Skirmisher | 2 × cost 1–2 | table |
| Lasher | 2 × cost 1–3 | ⚠️ **multi-hit only**, both moves |
| Glasswing | 2 × cost 1–3 | **−35%** (3–5 / 11–16) — 1.70 damage is doing the work |
| Adept | 3 × cost 1–3 | table, plus one shield ⭐ the honest three-move kit |
| Sentinel | 2 × cost 2–4 | one attack, one **shield** at cost 4 |
| Bruiser | 2 × cost 2–5 | table |
| Blighter | 2 × cost 1–2 | ⚠️ **multi-hit only**, both moves |
| Champion | 3 × cost 1–4 | table, plus one shield |
| Redoubt | 3 × cost 2–4 | one attack, one shield, one **lifesteal** |
| Executioner | 2 × cost 3–**4** | ⚠️ **cap lowered from 5** — see below |
| Hexer | 3 × cost 1–3 | table, one `ignoresShields` |
| Juggernaut | 3 × cost 3–5 | table, one shield |
| Tyrant | 3 × cost 1–5 | table, one **cheap** shield |
| Aspect | 3 × cost 1–4 | table, all three lean on the element's passive |

⚠️ **The Executioner's cost cap is lowered from 5 to 4 for this quarter.** At
the mini five-charge raw of 46–60 × 1.90 × `1.04^28`, a level-29 Pyroclast
hits for **251–308** into a 300 HP bar with a ~+42 HP gear budget — a
literal one-shot. ENEMIES §2.2 promises *"kills you in three turns if you misplay
one"*, not one. At cost 4 it lands 148–194, which is two casts — exactly the
ratio Q1's Hollow Stag has at level 5. 📝 The alternative is dropping the
mini `c5` raw to ~34–42; the cap is the smaller change.

### 1.4 Effective damage — what the player actually takes

Raw × `1.04^(L−1)` × `damageScale`, for each archetype's **cheapest** and
**dearest** affordable move. ⭐ The cheapest column is what it can do on turn
one; the dearest is what it telegraphs.

| Archetype | cheap | @15 | @22 | @29 | dear | @15 | @22 | @29 |
|---|---|---|---|---|---|---|---|---|
| **Drudge** | c1 | 5–8 | 6–10 | 8–13 | c1 | 5–8 | 6–10 | 8–13 |
| **Skirmisher** | c1 | 10–16 | 13–21 | 17–28 | c2 | 22–30 | 29–39 | 38–52 |
| **Lasher** | c1 | 3–5 ×3 (9–15) | 5–7 ×3 (15–21) | 6–9 ×3 (18–27) | c3 | 7–10 ×4 (28–40) | 9–14 ×4 (36–56) | 12–18 ×4 (48–72) |
| **Glasswing** | c1 | 10–15 | 13–20 | 17–27 | c3 | 34–44 | 45–58 | **60–76** |
| **Adept** | c1 | 8–12 | 10–16 | 13–22 | c3 | 28–36 | 37–47 | 49–62 |
| **Sentinel** | c2 | 13–18 | 18–24 | 23–31 | c4 | *shield* | *shield* | *shield* |
| **Bruiser** | c2 | 21–29 | 28–38 | 36–49 | c5 | 57–76 | 75–100 | **99–132** |
| **Blighter** | c1 | 3–5 ×2 (6–10) | 4–7 ×2 (8–14) | 5–9 ×2 (10–18) | c2 | 4–6 ×3 (12–18) | 5–8 ×3 (15–24) | 7–11 ×3 (21–33) |
| **Champion** | c1 | 12–19 | 16–25 | 22–32 | c4 | 54–71 | 71–93 | 94–122 |
| **Redoubt** | c2 | 18–25 | 23–33 | 31–43 | c4 | 38–50 | 50–66 | 66–87 |
| **Executioner** | c3 | 82–109 | 108–143 | 142–188 | c4 | 86–112 | 113–147 | **148–194** |
| **Hexer** | c1 | 8–12 | 10–15 | 13–20 | c3 | 32–43 | 43–56 | 56–74 |
| **Juggernaut** | c3 | 58–75 | 77–99 | 101–130 | c5 | 102–131 | 134–172 | **176–227** |
| **Tyrant** | c1 | 18–26 | 23–35 | 31–46 | c5 | 124–159 | 163–209 | **214–275** |
| **Aspect** | c1 | 16–23 | 21–31 | 27–40 | c4 | 78–99 | 103–130 | 135–171 |

Player HP at the same levels, for comparison: **173 · 228 · 300** (plus a
gear budget of roughly +31 at L16 rising to +42 at L24 — §2.5).

📝 **Three numbers to red-pen:**

- **Tyrant c5 at L29 = 214–275 into a 300 HP bar.** Efreet's biggest swing is
  ~80% of the player's health. It is a five-charge telegraph, so it is
  survivable by playing correctly, but there is no room left for a mistake.
- **Executioner c3 already reads as a two-cast kill at every level** — that is
  Q1's ratio held, not a Kinetic escalation, and it is the archetype's job.
- **Glasswing c3 at 60–76 off an 86–150 HP body** is the race the archetype
  exists to teach, unchanged from Q1.

### 1.5 Move naming and voice — ✅ the Primal standard holds

ENEMIES §3.3 / §3.3a: **moves are verbs, narrated as things a creature does.**
*"Bear Down"*, *"Throw It Back"*, *"Turn As One"* — never a Pokémon noun.
Lore is a field-note observation, never a stat line in prose.
⚠️ The shipped zone suites assert this; the Kinetic ones must too.

### 1.6 Adventure shape ✅

`commonsPerSectionFor(MagicTier.kinetic) == 3`, so a Kinetic run is
**3 commons → mini → 3 commons → mini → 3 commons → boss** = 12 encounters,
three sections, one gather node per section. ✅ Ruling 4: The Molten Deep uses
exactly this, no dungeon structure.

`_rampedLevel` puts commons on a ramp and elevated ranks at `zone.maxLevel`:

| Zone | Common levels, in run order | Minis & boss |
|---|---|---|
| Old Quarry | 15 15 16 · 16 17 17 · 18 18 19 | 19 |
| Stormcliff Coast | 17 17 18 · 19 19 20 · 21 21 22 | 22 |
| Windward Steppe | 19 19 20 · 21 21 22 · 23 23 24 | 24 |
| Frostfell Pass | 21 21 22 · 23 23 24 · 25 25 26 | 26 |
| Thunderspire Peaks | 23 23 24 · 25 25 26 · 27 27 28 | 28 |
| The Molten Deep | 25 25 26 · 26 27 27 · 28 28 29 | 29 |

---

## 2. Crit, dodge and deflection — the quarter's new mechanic, from both sides

✅ **Ruling 2.** ITEMS §9b.8 ruling 5 reserved dodge, deflection and
crit-as-a-lane for Q2 precisely so this quarter had something to introduce.
It arrives on **enemies and gear at once**, which is what makes it read as a
change in the world rather than a change in the shop.

### 2.1 The mechanics, as shipped

```
hitChance = 80 + attackerAccuracy − defenderDodge − blind      (base 80, ElementTuning.baseMissPercent = 20)
on crit   : perHit × (100 + critDamage) / 100                  (engine base critDamage = 50, gear ADDS)
on deflect: taken = damage × (1 − deflectAmount/100)           (player cap 50; enemies may exceed)
```

⚠️ **Three inert-stat traps, and every one of them is easy to ship:**

| Trap | Why |
|---|---|
| `critDamage` with `critChance == 0` | The engine guards on `critChance > 0`. A Bruiser given +25 crit damage and no chance crits never. ✅ ITEMS §4.1a says so; this contract pairs them everywhere |
| `deflectChance` with `deflectAmount == 0` | `taken = damage × (1 − 0)`. A deflect that reduces nothing is a proc message. **The same pairing rule applies** |
| `deflectAmount` with `deflectChance == 0` | Never procs |

📝 **Deflection's real value is `chance × amount`, and it is small at readable
numbers.** Every deflect line below is printed with its expected reduction so
the designer can see what is actually being bought:

| chance × amount | EV damage reduction |
|---|---|
| 6% × 15% | 0.9% |
| 8% × 20% | 1.6% |
| 12% × 25% | 3.0% |
| 20% × 25% | 5.0% |
| 25% × 35% | 8.8% |
| 35% × 30% | 10.5% |

📝 **Dodge, likewise:** each point of dodge is one point off the attacker's 80,
i.e. **1.25% of their throughput**. Dodge 8 = −10%.

### 2.2 ⚠️ Where the enemy stat block lives — a ruling this contract has to make

`EnemyArchetype` has **no** combat-stat fields today, and `LocalAiDriver`
explicitly returns `ItemModifiers.none` for `opponentGear` with the comment
*"Never gear… a bestiary entry's [difficulty] is its archetype."*

> ✅ **Ruling: the stat block goes on `EnemyDef`, not on `EnemyArchetype`, and
> reaches the duel through a new `OpponentDriver.opponentCombatStats`, not
> through `opponentGear`.**
>
> ⭐ **Two reasons, both load-bearing.** (1) Putting it on the sixteen shared
> archetype constants would retroactively give every Q1 creature crit and
> deflection, breaking ITEMS §9b.8 ruling 5 — Rootknuckle would start critting
> in the tutorial zone. A per-`EnemyDef` field defaulting to `none` leaves
> Q1 untouched by construction. (2) Routing it through `opponentGear` would
> contradict that field's documented contract in exactly the way its ⚠️ warns
> against — *"an archetype and a wardrobe stacked on the same body."*
>
> ⚠️ **Builder note:** `DuelController._buildMage` is where it lands, beside
> the gear application, and `RemoteDuelDriver` must return `none` — archetype
> stats must never touch PvP, same rule as `opponentHpScale`.

The table below is therefore the **authoring standard**: each Kinetic
`EnemyDef` copies its archetype's row unless the zone section says otherwise.

### 2.3 Enemy combat stats by archetype 📝

Derived from ENEMIES §2.5's stat leans. Every 📝.

| Archetype | acc | dodge | crit % | crit dmg | defl % | defl amt | EV defl | Reads as (ENEMIES §2.5) |
|---|---|---|---|---|---|---|---|---|
| **Drudge** | **−10** | 0 | 0 | 0 | 0 | 0 | — | "Flails and misses. Its incompetence is visible" |
| **Skirmisher** | +5 | **8** | 0 | 0 | 0 | 0 | — | "Hard to pin, always first" |
| **Lasher** | 0 | 0 | **15** | **−20** | 0 | 0 | — | "Lots of small bites, one occasionally stings" ⭐ and it rolls per hit |
| **Glasswing** | 0 | 0 | **20** | **+30** | 0 | 0 | — | "Spiky. Some turns are catastrophic" |
| **Adept** | 0 | 0 | 0 | 0 | 0 | 0 | — | The yardstick. ⭐ **Deliberately blank** |
| **Sentinel** | 0 | 0 | 0 | 0 | **25** | **20** | 5.0% | "Everything you throw lands softer" |
| **Bruiser** | **−8** | 0 | 8 | **+25** | 0 | 0 | — | "Hits like a truck, sometimes whiffs entirely" |
| **Blighter** | +8 | 0 | 0 | 0 | 0 | 0 | — | "Its statuses always land" |
| **Champion** | +6 | 0 | 10 | 0 | 0 | 0 | — | "Simply good at everything" |
| **Redoubt** | 0 | 0 | 0 | 0 | **35** | **30** | 10.5% | "A wall that erodes you" |
| **Executioner** | +8 | 0 | 12 | **+40** | 0 | 0 | — | "One mistake ends you" |
| **Hexer** | +8 | **10** | 0 | 0 | 0 | 0 | — | "Slippery and always connecting" |
| **Juggernaut** | 0 | 0 | 0 | 0 | 25 | **35** | 8.8% | "Unstoppable, unsubtle" |
| **Tyrant** | +5 | 5 | 10 | +15 | 10 | 15 | 1.5% | "No weakness to exploit" — everything, modestly |
| **Aspect** | per zone | | | | | | | "Whatever its element wants" — ENEMIES §2.5 |

⚠️ **Enemy dodge is capped at 10 and that cap is a rule, not a value.**
ENEMIES §2.5: *"Cap enemy dodge low — it should read as 'slippery', never as
'unhittable'."* Ten points takes an 80% hit chance to 70%. The Hexer at 10 and
the Skirmisher at 8 are the only two allowed near it.

⚠️ **The Redoubt at 10.5% EV reduction on top of 2.20 HP is the stalemate risk
ENEMIES §2.2 already flagged.** 📝 If the fatigue clock is not in by build time, drop
Redoubt's deflect chance to 20 (EV 6%).

### 2.4 The three Aspects — element-dependent, per ENEMIES §2.5

Only three Kinetic bosses are Aspects. Each leans entirely on one element's
passive, which is why each is single-element (§4).

| Boss | Zone | Element | Stat block | Why |
|---|---|---|---|---|
| **The Return Stroke** | Stormcliff Coast | Electro | crit 25 / critDmg +45, acc +5 | ⭐ ITEMS §4.1a's affinity: Electro is crit chance. A return stroke is one enormous flash |
| **The Road Under** | Frostfell Pass | Aqua | defl 30 / amt 30 (EV 9.0%), acc 0 | ⭐ Waterlogged taken to an extreme. *"Everything that moves through here gets held"* — and nothing you do reaches it |
| **The Strike That Lands** | Thunderspire Peaks | Electro | crit 30 / critDmg +50, acc +10 | The zone's premise is the countdown; the Aspect is the arrival |

### 2.5 Player gear — the three lines' first homes

⭐ **The distribution rule, stated once so twenty items obey it:**

| Line | Lives on | Because |
|---|---|---|
| **Deflect chance + amount** | Tailoring **gloves**, the Geo jewelry, the Geo/Pyro epics | ITEMS §4.1a's affinity puts deflection on Geo; a glove is the piece you put in the way |
| **Dodge** | Tailoring **boots**, the Aero jewelry, the Aero epic | Aero's affinity; boots are the slot the fantasy asks for |
| **Crit chance + damage** | **Rowan** weapons (the first *crafted* crit), the Electro and Pyro jewelry, the Electro/Pyro epics | Electro = chance, Pyro = damage, per ITEMS §4.1a |
| **Accuracy** | Tailoring **hood** and every weapon, exactly as Q1 | ⭐ Continuity — accuracy is the stat Q1 taught, and it is the counter-pick to dodge |
| **Flat HP** | Tailoring **robe / leggings**, with a token on boots and gloves | Q1's shape, unchanged |

⚠️ **Crit stays off the crafted tier-3 (Yew / Seawrack) entirely.** Q1 gave
crit to exactly one ring and one boss unique; the quarter should open by
letting the player *meet* crit on an enemy before it can be bought. Rowan
(equip 25) is where crafting gets it.

### 2.6 ⚠️ "Gear ≈ ten levels" — where the invariant binds

The standing invariant (ITEMS §9b.4a, GAME_DESIGN) says a fully-geared
character fights about ten levels above their own. Measured against the
shipped curve, **ten levels is +48% on HP *and* +48% on damage** — the
compounding makes the ratio constant, so this is a percentage target at every
level, not an absolute one.

Expressing a loadout as `Ghp × Gdmg = 1.04^(2L)` and solving for L:

| Loadout | Ghp | Gdmg | **≈ levels of gear** |
|---|---|---|---|
| Q1 crafted-only @ L14 (Birch quarterstaff + Bogflax set) | 1.126 | 1.293 | **4.8** |
| Q1 best-in-slot @ L14 (Heartwood Staff + Bogflax + Cinder Loop) | 1.126 | 1.497 | **6.7** |
| Q2 crafted-only @ L20 (Yew + Seawrack + Amber Ring) | 1.185 | 1.359 | **6.1** |
| Q2 crafted-only @ L29 (Rowan + Tussock + Obsidian Ring) | 1.167 | 1.468 | **6.9** |
| **Q2 best-in-slot @ L29** (§4 epics + Rowan + Tussock) | 1.393 | 1.657 | **10.7** |

⭐ **Three findings the designer should see together.**

1. ✅ **The invariant is satisfiable, and this budget satisfies it — but only
   at the very top, and only with drops.** That is arguably the correct shape:
   §9b.4a says a Master crafted item is the *floor* and boss uniques are the
   deliberate exception. Crafted-only tops out near 7 levels all quarter.
2. ⚠️ **Q1 never reached ten levels either** — its best-in-slot is 6.7. So the
   line in the docs has never been true of shipped content. This is the first
   quarter where it can be, because crit and deflection are multiplicative and
   flat HP is not.
3. ⚠️ **Flat modifiers decay against a geometric curve.** The Tussock robe's
   +20 HP is 8% of the baseline at its equip level 24 and 6.7% at L29. Any
   "gear = N levels" target must therefore be re-stated **per material tier at
   that tier's equip level**, which is exactly what §9b.4a's *"gear advantage
   caps at roughly one material tier"* already means. 📝 See Decisions §8.2.

---

## 3. Materials, motes and id conventions

### 3.1 The fifteen materials

✅ 2 per pure zone, 3 per hybrid (ITEMS §9b.8 ruling 7).

| id | Name | Zone | Consuming skill | Tier | Gathered by | Node? |
|---|---|---|---|---|---|---|
| `tin_ore` | Tin Ore | old_quarry | Metalworking | 3 | Mining | ✅ |
| `quarry_jasper` | Quarry Jasper | old_quarry | Jewelry | 3 | Mining | ✅ |
| `seawrack_fibre` | Seawrack Fibre | stormcliff_coast | Tailoring | 3 | Foraging | ✅ |
| `saltwort` | Saltwort | stormcliff_coast | Potions & Alchemy | 3 | Foraging | ✅ |
| `yew_log` | Yew Log | windward_steppe | Woodcarving | 3 | Felling | ✅ |
| `tussock_flax` | Tussock Flax | windward_steppe | Tailoring | 4 | Foraging | ✅ |
| `rimepelt` | Rimepelt | frostfell_pass | Tailoring | 4 | — | ⚠️ **kill-only** |
| `hoarlichen` | Hoarlichen | frostfell_pass | Potions & Alchemy | 4 | Foraging | ✅ |
| `everice` ⏳ | Everice | frostfell_pass | Jewelry | 5 | Mining | ✅ |
| `rowan_log` | Rowan Log | thunderspire_peaks | Woodcarving | 4 | Felling | ✅ |
| `iron_ore` | Iron Ore | thunderspire_peaks | Metalworking | 4 | Mining | ✅ |
| `hum_quartz` ⏳ | Hum Quartz | thunderspire_peaks | Enchanting | 4 | Mining | ✅ |
| `obsidian` | Obsidian | the_molten_deep | Jewelry | 4 | Mining | ✅ |
| `firesalt` | Firesalt | the_molten_deep | Potions & Alchemy | 5 | Foraging | ✅ |
| `emberhide` | Emberhide | the_molten_deep | Tailoring | 5 | — | ⚠️ **kill-only** |

⭐ **The economy's spine is Bronze, and it is why Copper banked.** ITEMS §9b.8
banked `copper_ore` from Cinderpeak and `charcoal` from Ashfall Vale as
*"gatherable now, spendable next quarter."* Tin is the missing half:
**copper + tin + charcoal → Bronze** at Forgeholm, level 15, the moment
Metalworking opens. ⚠️ That is the payoff the banking clause promised, and it
is the first recipe a Kinetic player should meet.

⭐ **The Kinetic hybrids bank forward in turn, but only twice.** `everice`
(Jewelry tier 5) and `hum_quartz` (Enchanting) have no Kinetic consumer;
Enchanting's station is Meridian at L36, so Hum Quartz is Q2 seeding Q3
exactly as §9b.8 says the pattern should be. 📝 The other four hybrid
materials are spendable in-band — the banking clause existed because Q1 had
*no* maker for two skills, and Q2 opens both.

⚠️ **Two materials are kill-only and must have no node** (ITEMS §9b.7b):
`rimepelt` and `emberhide` are hides. Node count is 13, not 15, for exactly
the reason Glimmerbrook has one node and two materials.

### 3.2 The nine new motes

Three new families × three tiers. ✅ Rarity from ITEMS §8: Dust and Shard are
Common, Crystal is Uncommon.

| id | Name | Element | Tier | Rarity | Defined in |
|---|---|---|---|---|---|
| `geo_dust` | Geo Dust | geo | dust | common | old_quarry |
| `geo_shard` | Geo Shard | geo | shard | common | old_quarry |
| `geo_crystal` | Geo Crystal | geo | crystal | **uncommon** | old_quarry |
| `electro_dust` | Electro Dust | electro | dust | common | stormcliff_coast |
| `electro_shard` | Electro Shard | electro | shard | common | stormcliff_coast |
| `electro_crystal` | Electro Crystal | electro | crystal | **uncommon** | stormcliff_coast |
| `aero_dust` | Aero Dust | aero | dust | common | windward_steppe |
| `aero_shard` | Aero Shard | aero | shard | common | windward_steppe |
| `aero_crystal` | Aero Crystal | aero | crystal | **uncommon** | windward_steppe |

⭐ **The mote lives with the zone that first yields it** — the shipped rule,
which is why the three pure zones own the three new families and the three
hybrids define none. Frostfell drops `aqua_*` and `aero_*`; Thunderspire drops
`electro_*` and `aero_*`; The Molten Deep drops `pyro_*` and `geo_*`. ⭐ **Two
of the six Kinetic zones pay entirely in Q1's motes**, which is the first time
old material has had a new reason to matter.

⚠️ **Crystal lore must close the set.** Flora Crystal is *"warm, and it does
not stop being warm"*; Aqua's is cold; Pyro's is hot. The three new ones are
one sentence of the same shape each, or the ladder stops reading as one object
in nine elements.

✅ **No Core-tier motes in this quarter.** ITEMS §8 calls Core *"incredibly
rare; possibly never drops"* and ITEMS §9's band table puts Core and Heart at
45–50. The *"every tier below Heart drops directly"* invariant is honoured
within the quarter by Dust → Shard → Crystal at escalating rarity; introducing
a Kinetic Core that essentially never falls would be noise, not a ladder rung.

### 3.3 The gate — the Kinetic Sigil, in three parts ✅

`world.dart` gates Concordance on *"The Kinetic Sigil, in three parts, shown
at the gate."* NARRATIVE §4b.1: the three parts are **three essences from the
three Kinetic pure zones** — Geo at the Old Quarry, Electro at Stormcliff,
Aero on the Steppe — and they are Forgeholm's failed containment ward, not a
permission slip.

| id | Name | Zone | `gates` |
|---|---|---|---|
| `geo_essence` | Geo Essence | old_quarry | `concordance` |
| `electro_essence` | Electro Essence | stormcliff_coast | `concordance` |
| `aero_essence` | Aero Essence | windward_steppe | `concordance` |

⚠️ **Both bosses of each pure zone guarantee their essence on `always`**,
exactly as the three proofs do. Progression must never sit behind a main-table
roll. ⚠️ **The three hybrids drop none** — a fourth part would let a player
skip one of the three zones the gate exists to route them through, which is
the same reason Thornmire and Ashfall Vale drop no proof.

📝 Naming: *"Geo Essence"* matches the Celestial Totem's *"charged with Solar,
Lunar and Astral"* and NARRATIVE's own word. It does **not** match Q1's
evocative *"Proof of the Woods"*. See Decisions §8.6.

### 3.4 Id conventions ✅

| Kind | Convention | Example |
|---|---|---|
| Creature | `snake_case` of the display name, articles kept | `the_empty_course` |
| Move | `<zone prefix>_<verbnospaces>` | `oq_bearup`, `sc_earththrough` |
| Zone prefixes (new, no collisions) | `oq_` `sc_` `ws_` `ff_` `tp_` `md_` | — |
| Material / mote / consumable | plain noun | `tussock_flax`, `aero_shard` |
| Crafted equipment | `<material>_<form>` | `rowan_quarterstaff` |
| Named equipment (drops) | its own name, `properName` set | `overseers_seal` |
| Recipe | `craft_<outputId>` | `craft_rowan_wand` |
| Gather node | `<zone prefix>_<place>` | `ws_tussock_swale` |

⚠️ **Crafted equipment must leave `properName` null** — the name is composed
from `material + form` (§9b.5a). **Drop-only jewelry and boss uniques set it.**
A test already enforces this.

⚠️ **Which catalogue file defines a cross-zone crafted output:** the file for
the zone that supplies its **headline** material; where the headline material
is a banked Q1 material, it goes to the Q2 zone supplying the recipe's other
half. That is why `bronze_ingot` and `amber_ring` live in
`old_quarry_items.dart`. ⚠️ **No builder edits a Q1 catalogue file.**

---

## 4. The six zones

Each section gives the roster, the element assignment, the drop tables and the
catalogue. Statlines are the §1.2 numbers; commons show the band's floor→ceiling
because `_rampedLevel` puts them on a ramp.

Legend: ✅ = name already exists in `World.opponentNameFor`;
✅✅ = re-homed from a GAME_DESIGN §5 element roster.

---

### 4.1 Old Quarry · `old_quarry` · 15–19 · Geo

> ✅ *"Whatever was quarried out of here left a shape, and the shape has
> started to move."*
>
> ⭐ **Theme: the hole remembers what filled it.** The threat is the
> **absence**, not the stone — negative space gone solid.

⚠️ **The deliberate rhyme with The Umbral Wastes (47–51) is not duplication**
and must not be "fixed": here something was **removed** and the hole is
animate; there dark was **imposed** and given a shape (ENEMIES §2e).

⭐ **Story load** (NARRATIVE §4b.1, CONTENT_CHECKLIST): this is the only road
into the range, the place the player first sees Forgeholm's ward failing, and
the source of the Sigil's Geo essence. **The quarter opens and closes in the
same place.**

#### Roster — 11

| id | Name | Rank | Archetype | Element | Level | HP |
|---|---|---|---|---|---|---|
| `quarry_golem` ✅ | Quarry Golem | Common | Bruiser | geo | 15–19 | 199–233 |
| `tailings_drudge` | Tailings Drudge | Common | Drudge | geo | 15–19 | 138–162 |
| `chiselback` | Chiselback | Common | Skirmisher | geo | 15–19 | 121–142 |
| `gravelswarm` | Gravelswarm | Common | Lasher | geo | 15–19 | 147–173 |
| `plumbline_sentry` | Plumbline Sentry | Common | Sentinel | geo | 15–19 | 216–254 |
| `obsidian_golem` ✅✅ | Obsidian Golem | Mini | Champion | geo | 19 | 345 |
| `earth_titan` ✅✅ | Earth Titan | Mini | Redoubt | geo | 19 | 447 |
| `deadweight` | Deadweight | Mini | Executioner | geo | 19 | 244 |
| `the_overseer` | The Overseer | Mini | Hexer | geo | 19 | 325 |
| `mountain_heart` ✅✅ | Mountain Heart | **Boss** | Juggernaut | geo | 19 | 731 |
| `the_empty_course` | The Empty Course | **Boss** | Tyrant | geo | 19 | 528 |

⭐ **The boss pair is the premise's two sides:** *Mountain Heart* is **what was
taken** (a mass — Juggernaut), *The Empty Course* is **the shape of what is
gone, walking** (a thing that decided — Tyrant).

⚠️ **`obsidian_golem` was a name collision with The Molten Deep and is already
resolved** — the Deep took *Pyroclast* (ENEMIES §2f). Keep it resolved.

#### Drop table

⭐ Shape follows the shipped zones exactly: one shared `_commonAlways`, one
`_miniDrops`, one `_bossDrops` per zone.

```
_commonAlways = [ DropEntry('geo_dust', chance: 0.75, min: 1, max: 2) ]
```

| Creature | main (weights sum 100) | bonus |
|---|---|---|
| Quarry Golem | nothing 25 · `tin_ore` 55 (1–3) · `geo_shard` 7 · `geo_dust` 13 (1–2) | `hardtack` 2% |
| Tailings Drudge | nothing 40 · `tin_ore` 45 · `hardtack` 15 | — |
| Chiselback | nothing 35 · `quarry_jasper` 45 · `geo_shard` 7 · `geo_dust` 13 (1–2) | — |
| Gravelswarm | nothing 35 · `tin_ore` 50 (1–2) · `geo_shard` 5 · `geo_dust` 10 (1–2) | — |
| Plumbline Sentry | nothing 30 · `quarry_jasper` 40 · `geo_shard` 8 (1–2) · `geo_dust` 17 (2–3) · `hardtack` 5 | — |

```
_miniDrops  always: geo_shard ×1 · geo_dust 2–4 · geo_crystal chance 0.25
            main:   tin_ore 40 (2–4) · quarry_jasper 30 (2–4) · hardtack 25 · overseers_seal 5
_bossDrops  always: geo_crystal 1–2 · geo_shard 1–2 · geo_dust 4–8 · geo_essence ✅ guaranteed
            main:   tin_ore 45 (4–8) · quarry_jasper 25 (3–6) · overseers_seal 20 · the_given_weight 10
```

⚠️ **`geo_crystal` appears on the mini and boss tables and nowhere else** —
Crystal is a mini-boss reward, the ladder's first felt step (ITEMS §8).
⚠️ **`the_given_weight` (Epic) is the boss table only.** 📝 10 weight = one in
ten clears.

#### Catalogue — 12 defs (`lib/game/items/catalogue/old_quarry_items.dart`)

| id | Kind | Rarity | Slot / detail | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `tin_ore` | Material | common | Metalworking t3 | 1 | — | 6 📝 |
| `quarry_jasper` | Material | uncommon | Jewelry t3 | 1 | — | 14 📝 |
| `geo_dust` / `geo_shard` | Mote | common | dust / shard | 1 | — | 2 / 12 📝 |
| `geo_crystal` | Mote | uncommon | crystal | 1 | — | 60 📝 |
| `hardtack` | **Consumable** ⚠️ not Beltable | common | between encounters | 1 | `healPercent: 35` 📝 | 9 |
| `bronze_ingot` | Material | common | Metalworking t3 output ⭐ feeds 6 recipes | 1 | — | 30 📝 |
| `amber_ring` | Equipment | uncommon | ring · Ring / Amber | 15 | `maxHpBonus: 8, healingReceivedPercent: 6` 📝 | 120 |
| `jasper_pendant` | Equipment | uncommon | neck · Pendant / Jasper | 18 | `deflectChance: 8, deflectAmount: 15` (EV 1.2%) 📝 | 150 |
| `overseers_seal` | Equipment ✅ *owed by §9b.8* | **rare** | ring · Signet / Bronze · `properName` · untradeable | 18 | `deflectChance: 12, deflectAmount: 20` (EV 2.4%) 📝 | 260 |
| `the_given_weight` | Equipment | **epic** | neck · Locket / Quarrystone · `properName` · untradeable | 19 | `maxHpBonus: 30, deflectChance: 10, deflectAmount: 25` (EV 2.5%) 📝 | 720 |
| `geo_essence` | **Key** | rare | `gates: 'concordance'` · bound | 1 | — | 0 |

⭐ **The Overseer's Seal is the item ITEMS §9b.8 ruling 9 explicitly deferred
to this quarter, dropped by its namesake.** It is also the game's first
deflection source, which is the right hand-off: the player meets deflection on
the Plumbline Sentry and then gets to wear it.

⭐ **`the_given_weight` is the quarter's HP epic** — 30 flat HP is 15% of a
level-19 player's bar, and its lore is the whole zone: the hole knows exactly
what came out of it.

---

### 4.2 Stormcliff Coast · `stormcliff_coast` · 17–22 · Electro

> ✅ *"The cliffs take the whole weight of it… the rock is scorched in long
> vertical lines."*
>
> ⭐ **Theme: everything here is a path to the ground, including you.** The
> coast is not a target, it is a **conductor**. Things are charged in passing
> rather than struck.

⚠️ **Stormcliff is *where* the lightning goes; Thunderspire is *when* it
comes** (ENEMIES §2e's 2026-08-02 retheme). §2f calls the pair *"the real
one"* among thematic collisions. **Builders of both zones must read both
sections** — the split is space vs time and it lives in the moves and the
lore, not in the statlines.

#### Roster — 11

| id | Name | Rank | Archetype | Element | Level | HP |
|---|---|---|---|---|---|---|
| `stormcliff_tidecaller` ✅ | Stormcliff Tidecaller | Common | **Adept** | electro | 17–22 | 187–228 |
| `fulgurite_crawler` | Fulgurite Crawler | Common | Sentinel | electro | 17–22 | 234–285 |
| `sparkwing` | Sparkwing | Common | Glasswing | electro | 17–22 | 94–114 |
| `static_shoal` | Static Shoal | Common | Lasher | electro | 17–22 | 159–194 |
| `groundling` | Groundling | Common | Skirmisher | electro | 17–22 | 131–160 |
| `brinecharge` | Brinecharge | Mini | Champion | electro | 22 | 388 |
| `the_long_line` | The Long Line | Mini | Redoubt | electro | 22 | 502 |
| `voltgeist` ✅✅ | Voltgeist | Mini | Executioner | electro | 22 | 274 |
| `storm_shaman` ✅✅ | Storm Shaman | Mini | Hexer | electro | 22 | 365 |
| `storm_lord` ✅✅ | Storm Lord | **Boss** | Tyrant | electro | 22 | 593 |
| `the_return_stroke` | The Return Stroke | **Boss** | **Aspect** | electro | 22 | 593 |

⭐ **The only Kinetic zone with an Adept**, and it is the anchor name. See
§8.4 — five of six zones have no yardstick.
⭐ *Fulgurite is the glass left where lightning passed through sand* — the
Sentinel is armoured by having been struck, which is the theme in one creature.
⭐⭐ **The boss pair:** *Storm Lord* is **what comes down** (a mind — Tyrant);
*The Return Stroke* is **what goes back up** — the bright half of a real bolt
travels **upward**, the ground answering the sky (the element itself — Aspect).

#### Drop table

```
_commonAlways = [ DropEntry('electro_dust', chance: 0.75, min: 1, max: 2) ]
```

| Creature | main | bonus |
|---|---|---|
| Stormcliff Tidecaller | nothing 40 · `saltwort` 45 · `hardtack` 15 | — |
| Fulgurite Crawler | nothing 30 · `seawrack_fibre` 40 · `electro_shard` 8 (1–2) · `electro_dust` 17 (2–3) · `saltwort_draught` 5 | — |
| Sparkwing | nothing 35 · `saltwort` 45 · `electro_shard` 7 · `electro_dust` 13 (1–2) | — |
| Static Shoal | nothing 35 · `seawrack_fibre` 50 (1–2) · `electro_shard` 5 · `electro_dust` 10 (1–2) | — |
| Groundling | nothing 25 · `seawrack_fibre` 55 (1–3) · `electro_shard` 7 · `electro_dust` 13 (1–2) | `hardtack` 2% |

```
_miniDrops  always: electro_shard ×1 · electro_dust 2–4 · electro_crystal chance 0.25
            main:   seawrack_fibre 40 (2–4) · saltwort 30 (2–4) · saltwort_draught 25 · fulgurite_pendant 5
_bossDrops  always: electro_crystal 1–2 · electro_shard 1–2 · electro_dust 4–8 · electro_essence ✅ guaranteed
            main:   seawrack_fibre 45 (4–8) · saltwort 25 (3–6) · fulgurite_pendant 20 · uplight 10
```

#### Catalogue — 14 defs (`stormcliff_coast_items.dart`)

| id | Kind | Rarity | Slot / detail | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `seawrack_fibre` | Material | common | Tailoring t3 | 1 | — | 7 📝 |
| `saltwort` | Material | common | Potions t3 | 1 | — | 7 📝 |
| `electro_dust` / `electro_shard` | Mote | common | | 1 | — | 2 / 12 📝 |
| `electro_crystal` | Mote | uncommon | | 1 | — | 60 📝 |
| `saltwort_draught` | **Beltable** | common | flat heal ⭐ the Draught form | 1 | `healPercent: 30` 📝 | 30 |
| `seawrack_hood` | Equipment | common | hat · Hood / Seawrack | 16 | `accuracyBonus: 3` | 60 |
| `seawrack_robe` | Equipment | common | robeTop · Robe / Seawrack | 16 | `maxHpBonus: 15` | 95 |
| `seawrack_leggings` | Equipment | common | robeBottom · Leggings / Seawrack | 16 | `maxHpBonus: 10` | 78 |
| `seawrack_boots` | Equipment | common | boots · Boots / Seawrack | 16 | `maxHpBonus: 3, dodge: 2` ⭐ **first dodge in the game** | 55 |
| `seawrack_gloves` | Equipment | common | gloves · Gloves / Seawrack | 16 | `maxHpBonus: 3, deflectChance: 6, deflectAmount: 15` ⭐ **first crafted deflect** (EV 0.9%) | 55 |
| `fulgurite_pendant` | Equipment | **rare** | neck · Pendant / Fulgurite · `properName` · untradeable | 20 | `critChance: 8, critDamage: 10` 📝 | 280 |
| `uplight` | Equipment | **epic** | mainHand · Wand / Fulgurite · `properName` · untradeable · **1 socket** | 22 | `damagePerCast: 6, accuracyBonus: 4, critChance: 12, critDamage: 15` 📝 | 760 |
| `electro_essence` | **Key** | rare | `gates: 'concordance'` · bound | 1 | — | 0 |

⭐ **Seawrack set total: 31 HP · 3 acc · 2 dodge · 6/15 deflect.** Against the
level-16 baseline (180 HP) that is +17% health, the same proportion Q1's
Bogflax set held at its own equip level. The two new lines are deliberately
**small enough to be a lesson rather than a build** — the player's first dodge
is two points, which is 2.5% of an attacker's throughput. They exist to be
noticed, and the drop-only jewelry is where they become a choice.

⭐ **`uplight` is the quarter's wand epic and its name is the mechanic** — the
return stroke travels upward. It is the wand lane's answer to Q1's Heartwood
Staff, and the crit pair on it is the first time a weapon has carried both.

---

### 4.3 Windward Steppe · `windward_steppe` · 19–24 · Aero

> ✅ *"The wind does not gust; it simply blows, and has been blowing since
> before there was anyone to notice."*
>
> ⭐ **Theme: one direction, forever — everything here has stopped resisting.**
> Not violence. **Relentlessness**, which no other Aero zone claims.

#### Roster — 11

| id | Name | Rank | Archetype | Element | Level | HP |
|---|---|---|---|---|---|---|
| `steppe_harrier` ✅ | Steppe Harrier | Common | Skirmisher | aero | 19–24 | 142–172 |
| `leanstone` | Leanstone | Common | Sentinel | aero | 19–24 | 254–308 |
| `chaff` | Chaff | Common | Lasher | aero | 19–24 | 173–209 |
| `tumblehusk` | Tumblehusk | Common | Drudge | aero | 19–24 | 162–197 |
| `kitewing` | Kitewing | Common | Glasswing | aero | 19–24 | 102–123 |
| `old_lean` | Old Lean | Mini | Champion | aero | 24 | 418 |
| `sky_titan` ✅✅ | Sky Titan | Mini | Redoubt | aero | 24 | 541 |
| `gale_serpent` ✅✅ | Gale Serpent | Mini | Executioner | aero | 24 | 295 |
| `wind_wraith` ✅✅ | Wind Wraith | Mini | Hexer | aero | 24 | 394 |
| `the_unbroken_blow` | The Unbroken Blow | **Boss** | Juggernaut | aero | 24 | 886 |
| `tempest_monarch` ✅✅ | Tempest Monarch | **Boss** | Tyrant | aero | 24 | 640 |

⭐ **The boss pair:** *Tempest Monarch* is **the gust — the exception** (a
will, so Tyrant); *The Unbroken Blow* is **the constant** (a force, so
Juggernaut). ⚠️ ENEMIES §2f floats a third option for this zone — *the empty
arena*, one draw where nothing is there at all. **This contract ships two real
bosses**; see Decisions §8.3.

⚠️ **A Drudge at level 19–24 needs watching.** §2f flags Drudges at 45–54 as
wasted encounter slots; Tumblehusk at 0.80/0.70 is nearer the edge than
anything in Q1. It survives here because *"everything has stopped resisting"*
is the zone's actual thesis and a husk that barely fights **is** that thesis —
⭐ the ENEMIES §2b rule cuts the right way for once. 📝 Watch it in the sim.

#### Drop table

```
_commonAlways = [ DropEntry('aero_dust', chance: 0.75, min: 1, max: 2) ]
```

| Creature | main | bonus |
|---|---|---|
| Steppe Harrier | nothing 35 · `tussock_flax` 45 · `aero_shard` 7 · `aero_dust` 13 (1–2) | — |
| Leanstone | nothing 30 · `yew_log` 40 · `aero_shard` 8 (1–2) · `aero_dust` 17 (2–3) · `hardtack` 5 | — |
| Chaff | nothing 35 · `tussock_flax` 50 (1–2) · `aero_shard` 5 · `aero_dust` 10 (1–2) | — |
| Tumblehusk | nothing 40 · `tussock_flax` 45 · `hardtack` 15 | — |
| Kitewing | nothing 25 · `yew_log` 55 (1–3) · `aero_shard` 7 · `aero_dust` 13 (1–2) | `hardtack` 2% |

```
_miniDrops  always: aero_shard ×1 · aero_dust 2–4 · aero_crystal chance 0.25
            main:   yew_log 40 (2–4) · tussock_flax 30 (2–4) · hardtack 25 · leanstone_charm 5
_bossDrops  always: aero_crystal 1–2 · aero_shard 1–2 · aero_dust 4–8 · aero_essence ✅ guaranteed
            main:   yew_log 45 (4–8) · tussock_flax 25 (3–6) · leanstone_charm 20 · the_long_lean 10
```

#### Catalogue — 16 defs (`windward_steppe_items.dart`)

| id | Kind | Rarity | Slot / detail | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `yew_log` | Material | common | Woodcarving t3 ✅ §9b.6 | 1 | — | 8 📝 |
| `tussock_flax` | Material | common | Tailoring t4 | 1 | — | 10 📝 |
| `aero_dust` / `aero_shard` | Mote | common | | 1 | — | 2 / 12 📝 |
| `aero_crystal` | Mote | uncommon | | 1 | — | 60 📝 |
| `yew_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Yew | 20 | `damagePerCharge: 3, accuracyBonus: 7` | 160 |
| `yew_wand` | Equipment | common | mainHand · Wand / Yew | 20 | `damagePerCast: 4, accuracyBonus: 2` | 135 |
| `yew_knot` | Equipment | common | offHand · Knot / Yew | 20 | `accuracyBonus: 5` | 110 |
| `tussock_hood` | Equipment | common | hat · Hood / Tussock | 24 | `accuracyBonus: 4` | 110 |
| `tussock_robe` | Equipment | common | robeTop · Robe / Tussock | 24 | `maxHpBonus: 20` | 170 |
| `tussock_leggings` | Equipment | common | robeBottom · Leggings / Tussock | 24 | `maxHpBonus: 14` | 140 |
| `tussock_boots` | Equipment | common | boots · Boots / Tussock | 24 | `maxHpBonus: 4, dodge: 3` | 100 |
| `tussock_gloves` | Equipment | common | gloves · Gloves / Tussock | 24 | `maxHpBonus: 4, deflectChance: 8, deflectAmount: 20` (EV 1.6%) | 100 |
| `leanstone_charm` | Equipment | **rare** | ring · Ring / Leanstone · `properName` · untradeable | 22 | `dodge: 6, accuracyBonus: 2` 📝 | 270 |
| `the_long_lean` | Equipment | **epic** | robeTop · Mantle / Windgrass · `properName` · untradeable | 24 | `maxHpBonus: 24, dodge: 8, accuracyBonus: 3` 📝 | 740 |
| `aero_essence` | **Key** | rare | `gates: 'concordance'` · bound | 1 | — | 0 |

⭐ **Yew continues the Q1 weapon ladder exactly** (Oak 1/5, Birch 2/6, Yew 3/7
on the staff; 2/0, 3/1, 4/2 on the wand; knot accuracy 3, 4, 5). No crit —
crit arrives on Rowan.
⭐ **Tussock set total: 42 HP · 4 acc · 3 dodge · 8/20 deflect.**
⚠️ **`the_long_lean` and `tussock_robe` fight for the same slot**, deliberately
— the epic is the reason to break your set, which is the shape Sporecap Mantle
established in Q1.
⚠️ **Dodge across a full Aero build: boots 3 + charm 6 + mantle 8 = 17**, which
takes an attacker to 63%. That is the single largest dodge total the game can
reach this quarter and it is well short of ITEMS §4.1a's lockout worry — 📝 but it is
the number to re-check the moment a second dodge source is added.

---

### 4.4 Frostfell Pass · `frostfell_pass` · 21–26 · Aqua + Aero ⭐ hybrid

> ✅ *"Your breath goes up and does not come down. The road is under here
> somewhere, and other people have been sure of that too."*
>
> ⭐ **Theme: everything that moves through here gets held.** The fusion is
> **breath frozen mid-air** — Aero stopped by Aqua — and the second sentence
> is the threat: the confident dead are still here.

#### Roster — 11

| id | Name | Rank | Archetype | Element(s) | Level | HP |
|---|---|---|---|---|---|---|
| `rime_stalker` ✅ | Rime Stalker | Common | Skirmisher | aqua + aero | 21–26 | 153–187 |
| `hoarbound` | Hoarbound | Common | Sentinel | **aqua** | 21–26 | 274–334 |
| `breathfrost` | Breathfrost | Common | Glasswing | **aero** | 21–26 | 110–134 |
| `cairnwight` | Cairnwight | Common | Blighter | aqua + aero | 21–26 | 219–267 |
| `snowblind_wanderer` | Snowblind Wanderer | Common | Drudge | **aero** | 21–26 | 175–214 |
| `the_last_cairn` | The Last Cairn | Mini | Champion | aqua + aero | 26 | 454 |
| `hoarking` | Hoarking | Mini | Redoubt | **aqua** | 26 | 587 |
| `coldsnap` | Coldsnap | Mini | Executioner | **aqua** | 26 | 320 |
| `the_certain_road` | The Certain Road | Mini | Hexer | aqua + aero | 26 | 427 |
| `the_white_corridor` | The White Corridor | **Boss** | Juggernaut | aqua + aero | 26 | 961 |
| `the_road_under` | The Road Under | **Boss** | **Aspect** | **aqua** | 26 | 694 |

⭐⭐ **This boss pool is NOT a mirror — it is a boss and its cause** (ENEMIES
§2f's deliberate break). *The Road Under* is **what is buried**; *The White
Corridor* is **what buried it**. ⚠️ **Killing the Corridor does not free the
Road** — nothing you do down here digs anyone out. The pool reads as
**futility**, which suits a pass whose arrival text is about people who were
also sure. ⚠️ Do not "fix" this into a symmetry.

⚠️ **The Aspect must be single-element** (ENEMIES §2.5: it *is* one element's passive
taken to an extreme). Aqua's Waterlogged — the thing that slows you and holds
you — is the only reading of *The Road Under* that works.

#### Drop table

```
_commonAlways = [ DropEntry('aqua_dust', chance: 0.5, min: 1, max: 2),
                  DropEntry('aero_dust', chance: 0.5, min: 1, max: 2) ]
```
⭐ The shipped hybrid shape (Thornmire) — two dusts at half chance each, so a
hybrid kill pays about as much mote as a pure one but in two currencies.

| Creature | main | bonus |
|---|---|---|
| Rime Stalker | nothing 35 · `rimepelt` 45 · `aqua_shard` 7 · `aqua_dust` 13 (1–2) | — |
| Hoarbound | nothing 30 · `rimepelt` 40 · `aqua_shard` 8 (1–2) · `aqua_dust` 17 (2–3) · `hardtack` 5 | — |
| Breathfrost | nothing 35 · `hoarlichen` 50 (1–2) · `aero_shard` 5 · `aero_dust` 10 (1–2) | — |
| Cairnwight | nothing 40 · `hoarlichen` 45 · `everice` 15 | — |
| Snowblind Wanderer | nothing 25 · `everice` 55 (1–3) · `aero_shard` 7 · `aero_dust` 13 (1–2) | `hardtack` 2% |

```
_miniDrops  always: aqua_shard ×1 · aero_shard ×1 · aqua_dust 2–4 · aero_dust 2–4
                    · aqua_crystal chance 0.25 · aero_crystal chance 0.25
            main:   rimepelt 40 (2–4) · hoarlichen 30 (2–4) · everice 25 (1–2) · rimebound_ring 5
_bossDrops  always: aqua_crystal 1–2 · aero_crystal 1–2 · aqua_shard 1–2 · aero_shard 1–2
                    · aqua_dust 4–8 · aero_dust 4–8      ⚠️ NO essence — hybrid
            main:   rimepelt 40 (4–8) · hoarlichen 25 (3–6) · everice 20 (2–4) · rimebound_ring 15
```

⚠️ **No epic here, and no essence.** ⭐ The reason is stated so nobody
"balances" it back in: the four Kinetic epics sit on the four boss pools that
carry canon element-roster names (Mountain Heart, Storm Lord, Tempest Monarch,
Efreet). Frostfell and Thunderspire pay in **doubled crystals** instead — a
hybrid boss hands over both parents' Crystal on `always`, which is the richest
mote payout in the quarter and the concrete reason to run a hybrid.
📝 This is a real tuning call; see Decisions §8.7.

#### Catalogue — 6 defs (`frostfell_pass_items.dart`)

| id | Kind | Rarity | Slot / detail | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `rimepelt` | Material | common | Tailoring t4 · ⚠️ **kill-only, no node** | 1 | — | 12 📝 |
| `hoarlichen` | Material | common | Potions t4 | 1 | — | 11 📝 |
| `everice` ⏳ | Material | uncommon | Jewelry t5 · **banks for Q3** | 1 | — | 26 📝 |
| `rimepelt_belt` | Equipment | common | belt · Belt / Rimepelt | 23 | `beltSlots: 3` ⚠️ capacity only, per Q1 | 220 |
| `hoarlichen_antidote` | **Beltable** | uncommon | ⚠️ **needs new `ItemEffect` vocabulary** — see §8.5 | 1 | cleanse 📝 | 55 |
| `rimebound_ring` | Equipment | **rare** | ring · Ring / Everice · `properName` · untradeable | 24 | `deflectChance: 10, deflectAmount: 20, dodge: 3` (EV 2.0%) 📝 | 290 |

⭐ **Belt capacity ladder: Fawnhide 1 → Tuskhide 2 → Rimepelt 3 → Emberhide 4.**
`Carrying.maxBeltSlots` is 10, so there is room for the whole game.
⚠️ **Belts carry `beltSlots` and nothing else** — Q1's ruling, and §6b.2's
whole point is that this is the one axis that is *not* combat power. Do not add
stats to a belt.

---

### 4.5 Thunderspire Peaks · `thunderspire_peaks` · 23–28 · Electro + Aero ⭐ hybrid

> ✅ *"The cloud is lit from within at intervals, and the intervals are getting
> shorter."*
>
> ⭐ **Theme: you are inside the storm, and it is building to something.** The
> fusion is a storm as a **single accelerating event** rather than weather.

⚠️ **Deliberately distinct from Stormcliff** — that zone is one strike's
warning, this one is a **countdown**. See §4.2's warning; both builders read
both.

#### Roster — 11

| id | Name | Rank | Archetype | Element(s) | Level | HP |
|---|---|---|---|---|---|---|
| `stormcrest_roc` ✅ | Stormcrest Roc | Common | Bruiser | **aero** | 23–28 | 273–331 |
| `humming_ore` | Humming Ore | Common | Sentinel | **electro** | 23–28 | 296–360 |
| `flashcount` | Flashcount | Common | Lasher | **electro** | 23–28 | 201–245 |
| `updraft_wisp` | Updraft Wisp | Common | Glasswing | **aero** | 23–28 | 118–144 |
| `ionwake` | Ionwake | Common | Skirmisher | electro + aero | 23–28 | 166–202 |
| `crown_fire` | Crown Fire | Mini | Champion | **electro** | 28 | 490 |
| `anvilhead` | Anvilhead | Mini | Redoubt | electro + aero | 28 | 634 |
| `thunder_roc` ✅✅ | Thunder Roc | Mini | Executioner | **aero** | 28 | 346 |
| `the_shortening` | The Shortening | Mini | Hexer | **electro** | 28 | 461 |
| `the_storm_that_passes` | The Storm That Passes | **Boss** | Juggernaut | electro + aero | 28 | 1037 |
| `the_strike_that_lands` | The Strike That Lands | **Boss** | **Aspect** | **electro** | 28 | 749 |

⭐ **`the_shortening` is the Hexer and that assignment is load-bearing**
(ENEMIES §2g's "assignments worth keeping"): the zone's premise is intervals
getting shorter, and **a stacking status IS that premise**. Write its moves so
the stack is visibly accelerating.
⭐ **The boss pair:** *The Strike That Lands* is the arrival (Aspect — Electro
taken to an extreme); *The Storm That Passes* is the one that does not (a mass
that simply keeps going — Juggernaut).
⚠️ **`stormcrest_roc` and `thunder_roc` are two rocs in one zone** — the
anchor and a re-homed Electro mini. Kept; they are different sizes and
different elements (Aero vs Aero — ⚠️ see below).

⚠️ **Thunder Roc is a GAME_DESIGN §5 *Electro* name assigned Aero here.** The
reason is that it is the zone's Executioner and its sibling common is the
Bruiser roc — two rocs sharing an element would make the pair read as the same
creature at two sizes, which §2f explicitly says is a *different* pattern
(Starfall Basin's). 📝 Flip it to Electro if the designer prefers the roster
name to keep its roster element.

#### Drop table

```
_commonAlways = [ DropEntry('electro_dust', chance: 0.5, min: 1, max: 2),
                  DropEntry('aero_dust', chance: 0.5, min: 1, max: 2) ]
```

| Creature | main | bonus |
|---|---|---|
| Stormcrest Roc | nothing 25 · `rowan_log` 55 (1–3) · `electro_shard` 7 · `electro_dust` 13 (1–2) | `hardtack` 2% |
| Humming Ore | nothing 30 · `hum_quartz` 40 · `electro_shard` 8 (1–2) · `electro_dust` 17 (2–3) · `hardtack` 5 | — |
| Flashcount | nothing 35 · `iron_ore` 50 (1–2) · `electro_shard` 5 · `electro_dust` 10 (1–2) | — |
| Updraft Wisp | nothing 35 · `rowan_log` 45 · `aero_shard` 7 · `aero_dust` 13 (1–2) | — |
| Ionwake | nothing 40 · `iron_ore` 45 · `hum_quartz` 15 | — |

```
_miniDrops  always: electro_shard ×1 · aero_shard ×1 · electro_dust 2–4 · aero_dust 2–4
                    · electro_crystal chance 0.25 · aero_crystal chance 0.25
            main:   iron_ore 40 (2–4) · rowan_log 30 (2–4) · hum_quartz 25 (1–2) · countstone_pendant 5
_bossDrops  always: electro_crystal 1–2 · aero_crystal 1–2 · electro_shard 1–2 · aero_shard 1–2
                    · electro_dust 4–8 · aero_dust 4–8     ⚠️ NO essence — hybrid
            main:   iron_ore 40 (4–8) · rowan_log 25 (3–6) · hum_quartz 20 (2–4) · countstone_pendant 15
```

#### Catalogue — 8 defs (`thunderspire_peaks_items.dart`)

| id | Kind | Rarity | Slot / detail | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `rowan_log` | Material | common | Woodcarving t4 ✅ §9b.6 | 1 | — | 13 📝 |
| `iron_ore` | Material | common | Metalworking t4 | 1 | — | 13 📝 |
| `hum_quartz` ⏳ | Material | uncommon | Enchanting t4 · **banks for Meridian, L36** | 1 | — | 28 📝 |
| `iron_ingot` | Material | common | Metalworking t4 output | 1 | — | 70 📝 |
| `rowan_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Rowan · **1 socket** ✅ §9b.6 | 25 | `damagePerCharge: 4, accuracyBonus: 8, critChance: 3, critDamage: 8` | 330 |
| `rowan_wand` | Equipment | common | mainHand · Wand / Rowan · **1 socket** | 25 | `damagePerCast: 5, accuracyBonus: 3, critChance: 4, critDamage: 6` | 280 |
| `rowan_knot` | Equipment | common | offHand · Knot / Rowan · **1 socket** | 25 | `accuracyBonus: 6, critChance: 2` | 230 |
| `countstone_pendant` | Equipment | **rare** | neck · Pendant / Hum Quartz · `properName` · untradeable | 26 | `critChance: 10, critDamage: 12` 📝 | 300 |

⭐ **Rowan is where crafting gets crit, and where sockets arrive** — §9b.6
gives Rowan "0–1 gem slots" and this contract spends the 1. ⚠️ Gems themselves
are ITEMS §6d and are **not** in this quarter; an empty socket is a promise the
Celestial quarter keeps. 📝 If that reads badly, drop `socketCount` to 0 and
move sockets to Ironwood (L30).
⭐ **`countstone_pendant`'s name is the zone** — it counts the intervals, and
the intervals are getting shorter.

---

### 4.6 The Molten Deep · `the_molten_deep` · 25–29 · Pyro + Geo ⭐ hybrid · 🏰

> ✅ *"There is a floor down here that moves like water because it is not
> water."*
>
> ⭐ **Theme: the stone is a liquid and has been the whole time.** The fusion
> is Geo revealed as Pyro's slow state — the ground you trusted was only cool.

✅ **Ruling 4: this ships as a standard three-section adventure.** ⚠️ The 🏰
marker in ENEMIES §2e and `LocationKind.dungeon` in `world.dart` both stand;
they simply do not change the roster or the run shape yet. **Nothing in this
zone's data may assume a descending structure.**

#### Roster — 11

| id | Name | Rank | Archetype | Element(s) | Level | HP |
|---|---|---|---|---|---|---|
| `molten_warden` ✅ | Molten Warden | Common | Sentinel | pyro + geo | 25–29 | 320–375 |
| `slagswimmer` | Slagswimmer | Common | Skirmisher | **pyro** | 25–29 | 179–210 |
| `crustwalker` | Crustwalker | Common | Bruiser | **geo** | 25–29 | 294–345 |
| `ember_vent` | Ember Vent | Common | Blighter | **pyro** | 25–29 | 256–300 |
| `cooling_thing` | Cooling Thing | Common | Glasswing | **geo** | 25–29 | 128–150 |
| `the_floor` | The Floor | Mini | Champion | pyro + geo | 29 | 510 |
| `magma_behemoth` ✅✅ | Magma Behemoth | Mini | Redoubt | **pyro** | 29 | 660 |
| `pyroclast` | Pyroclast | Mini | Executioner | **pyro** | 29 | 360 |
| `firstmelt` | Firstmelt | Mini | Hexer | pyro + geo | 29 | 480 |
| `the_slow_stone` | The Slow Stone | **Boss** | Juggernaut | **geo** | 29 | **1080** |
| `efreet` ✅✅ | Efreet | **Boss** | Tyrant | **pyro** | 29 | 780 |

⭐ **The boss pair:** *Efreet* is **what burns** (a will — Tyrant); *The Slow
Stone* is **what has not melted yet** (a mass — Juggernaut). ⭐ Both re-homed
Pyro roster names finally land at a scale that fits (ENEMIES §2c) — an Efreet
wants a volcano, not foothills.
⚠️ **1080 HP is the largest number in the quarter by 4%.** See §1.2's 📝.
⭐ **`cooling_thing` as the Glasswing is the theme's sharpest edge** — the only
thing down here that has stopped moving is the one thing that shatters.

#### Drop table

```
_commonAlways = [ DropEntry('pyro_dust', chance: 0.5, min: 1, max: 2),
                  DropEntry('geo_dust', chance: 0.5, min: 1, max: 2) ]
```
⭐ Both are **Q1 mote families** — this zone and Frostfell are the first places
old motes get a new source.

| Creature | main | bonus |
|---|---|---|
| Molten Warden | nothing 30 · `emberhide` 40 · `pyro_shard` 8 (1–2) · `pyro_dust` 17 (2–3) · `hardtack` 5 | — |
| Slagswimmer | nothing 35 · `firesalt` 45 · `pyro_shard` 7 · `pyro_dust` 13 (1–2) | — |
| Crustwalker | nothing 25 · `emberhide` 55 (1–3) · `geo_shard` 7 · `geo_dust` 13 (1–2) | `hardtack` 2% |
| Ember Vent | nothing 40 · `firesalt` 45 · `obsidian` 15 | — |
| Cooling Thing | nothing 35 · `obsidian` 50 (1–2) · `geo_shard` 5 · `geo_dust` 10 (1–2) | — |

```
_miniDrops  always: pyro_shard ×1 · geo_shard ×1 · pyro_dust 2–4 · geo_dust 2–4
                    · pyro_crystal chance 0.25 · geo_crystal chance 0.25
            main:   emberhide 35 (2–4) · obsidian 30 (2–4) · firesalt 30 (2–4) · firstmelt_loop 5
_bossDrops  always: pyro_crystal 1–2 · geo_crystal 1–2 · pyro_shard 1–2 · geo_shard 1–2
                    · pyro_dust 4–8 · geo_dust 4–8        ⚠️ NO essence — hybrid
            main:   emberhide 35 (4–8) · obsidian 25 (3–6) · firstmelt_loop 25 · the_long_cooling 15
```

📝 **The Molten Deep's boss table pays the quarter's best epic at 15 weight**,
one clear in seven, against Old Quarry's 10. The Deep is the last zone and the
hardest fight; 📝 flatten both to 12 if that reads as favouritism.

#### Catalogue — 8 defs (`the_molten_deep_items.dart`)

| id | Kind | Rarity | Slot / detail | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `obsidian` | Material | uncommon | Jewelry t4 | 1 | — | 22 📝 |
| `firesalt` | Material | common | Potions t5 | 1 | — | 16 📝 |
| `emberhide` | Material | common | Tailoring t5 · ⚠️ **kill-only, no node** | 1 | — | 18 📝 |
| `obsidian_ring` | Equipment | **rare** | ring · Ring / Obsidian | 26 | `critChance: 8, critDamage: 12` 📝 | 340 |
| `emberhide_belt` | Equipment | common | belt · Belt / Emberhide | 27 | `beltSlots: 4` | 380 |
| `firesalt_flask` | **Beltable** | uncommon | ⚠️ **needs new `ItemEffect` vocabulary** — the quarter's offensive potion, §8.5 | 1 | direct damage 📝 | 70 |
| `firstmelt_loop` | Equipment | **rare** | ring · Loop / Firstmelt · `properName` · untradeable | 28 | `critChance: 5, critDamage: 25` 📝 | 360 |
| `the_long_cooling` | Equipment | **epic** | hat · Circlet / Obsidian · `properName` · untradeable | 29 | `maxHpBonus: 22, deflectChance: 12, deflectAmount: 25, critDamage: 15` (EV 3.0%) 📝 | 820 |

⚠️ **`obsidian_ring` (crafted Rare) and `firstmelt_loop` (dropped Rare) share a
slot on purpose, and they must stay sidegrades** (§9b.4a): 8/12 is consistent
damage, 5/25 is the gambler. ⭐ That is ITEMS §4.1a's *"low-chance/high-crit-damage
glass cannon vs high-accuracy consistent"* build axis, expressed as two rings
you choose between. Neither is strictly better.
⚠️ **`the_long_cooling` competes with `tussock_hood`** — the same
break-your-set decision as `the_long_lean`, at the other end of the quarter.

---

## 5. The recipe ladder

✅ **Ruling 3.** 26 recipes, band-scoped and cross-zone, in one file:
`lib/game/items/recipes/kinetic_recipes.dart`, registered in `RecipeBook.all`.
⭐ Q1 shipped 20 across three skills; Q2 ships 26 across **five**, because
Metalworking and Jewelry both debut.

⚠️ **Skill level gates who can MAKE; `equipLevel` gates who can WEAR** (§9b.3).
The two never move together and conflating them kills the twink lane.

### 5.1 The table

XP is `Σ input counts × (4 + 2 × gate)`, computed, not guessed.

| # | Recipe id | Skill | Gate | Inputs (id × count) | Output | **XP** |
|---|---|---|---|---|---|---|
| 1 | `craft_bronze_ingot` | Metalworking | 1 | `copper_ore` ×2 ⏳, `tin_ore` ×1, `charcoal` ×1 ⏳ | `bronze_ingot` | **24** |
| 2 | `craft_iron_ingot` | Metalworking | 10 | `iron_ore` ×3, `charcoal` ×2 ⏳ | `iron_ingot` | **120** |
| 3 | `craft_amber_ring` | Jewelry | 1 | `amber` ×2 ⏳, `bronze_ingot` ×1 | `amber_ring` | **18** |
| 4 | `craft_jasper_pendant` | Jewelry | 5 | `quarry_jasper` ×2, `bronze_ingot` ×1 | `jasper_pendant` | **42** |
| 5 | `craft_obsidian_ring` | Jewelry | 12 | `obsidian` ×2, `iron_ingot` ×1 | `obsidian_ring` | **84** |
| 6 | `craft_yew_quarterstaff` | Woodcarving | 20 | `yew_log` ×3, `bronze_ingot` ×1 | `yew_quarterstaff` | **176** |
| 7 | `craft_yew_wand` | Woodcarving | 20 | `yew_log` ×2, `bronze_ingot` ×1 | `yew_wand` | **132** |
| 8 | `craft_yew_knot` | Woodcarving | 20 | `yew_log` ×2 | `yew_knot` | **88** |
| 9 | `craft_rowan_quarterstaff` | Woodcarving | 30 | `rowan_log` ×3, `iron_ingot` ×1 | `rowan_quarterstaff` | **256** |
| 10 | `craft_rowan_wand` | Woodcarving | 30 | `rowan_log` ×2, `iron_ingot` ×1 | `rowan_wand` | **192** |
| 11 | `craft_rowan_knot` | Woodcarving | 30 | `rowan_log` ×2 | `rowan_knot` | **128** |
| 12 | `craft_seawrack_hood` | Tailoring | 20 | `seawrack_fibre` ×2 | `seawrack_hood` | **88** |
| 13 | `craft_seawrack_robe` | Tailoring | 20 | `seawrack_fibre` ×5 | `seawrack_robe` | **220** |
| 14 | `craft_seawrack_leggings` | Tailoring | 20 | `seawrack_fibre` ×4 | `seawrack_leggings` | **176** |
| 15 | `craft_seawrack_boots` | Tailoring | 20 | `seawrack_fibre` ×2 | `seawrack_boots` | **88** |
| 16 | `craft_seawrack_gloves` | Tailoring | 20 | `seawrack_fibre` ×2 | `seawrack_gloves` | **88** |
| 17 | `craft_rimepelt_belt` | Tailoring | 24 | `rimepelt` ×2, `tussock_flax` ×1 | `rimepelt_belt` | **156** |
| 18 | `craft_tussock_hood` | Tailoring | 30 | `tussock_flax` ×3 | `tussock_hood` | **192** |
| 19 | `craft_tussock_robe` | Tailoring | 30 | `tussock_flax` ×6 | `tussock_robe` | **384** |
| 20 | `craft_tussock_leggings` | Tailoring | 30 | `tussock_flax` ×5 | `tussock_leggings` | **320** |
| 21 | `craft_tussock_boots` | Tailoring | 30 | `tussock_flax` ×3 | `tussock_boots` | **192** |
| 22 | `craft_tussock_gloves` | Tailoring | 30 | `tussock_flax` ×3 | `tussock_gloves` | **192** |
| 23 | `craft_emberhide_belt` | Tailoring | 34 | `emberhide` ×2, `tussock_flax` ×1 | `emberhide_belt` | **216** |
| 24 | `craft_saltwort_draught` | Potions & Alchemy | 20 | `saltwort` ×2 | `saltwort_draught` | **88** |
| 25 | `craft_hoarlichen_antidote` | Potions & Alchemy | 25 | `hoarlichen` ×2, `fenroot` ×1 ⏳ | `hoarlichen_antidote` | **162** |
| 26 | `craft_firesalt_flask` | Potions & Alchemy | 30 | `firesalt` ×2, `pyro_dust` ×1 | `firesalt_flask` | **192** |

⭐ **Every one of Q1's four banked materials is spent, and each by the recipe
its banking clause named:** Copper and Charcoal into Bronze at Forgeholm,
Fenroot into the Antidote, Amber into Jewelry's first ring. ⚠️ **That is the
promise §9b.8 made and it must not be quietly dropped** — a builder who
substitutes a Kinetic material for one of these has broken a fifteen-level
setup.

⭐ **Metalworking is a pure feeder lane, and that is §6a.1's design, not an
oversight.** It has two recipes and **nine downstream consumers** (six
Woodcarving, three Jewelry). *"Metalworking is the refinement lane for Mining
— many of those outputs are inputs to other recipes (a staff needs a ferrule;
a ring needs a band)."* 📝 If the designer wants the fittings spelled out as
their own step, add `craft_bronze_fitting` and `craft_iron_fitting` (→ 28
recipes) and re-point recipes 6, 7, 9, 10, 3, 4, 5 at them.

### 5.2 Gate progression — does the ladder actually climb?

`Skills.xpToNext(n) = 20 + 5(n−1)`, so reaching a gate costs:

| Gate | XP to reach | Cheapest route | Crafts needed |
|---|---|---|---|
| Metalworking 10 | 360 | Bronze Ingot (24) | 15 |
| Jewelry 5 | 110 | Amber Ring (18) | 7 |
| Jewelry 12 | 495 | Jasper Pendant (42) | ~10 |
| Woodcarving 20 | 1235 | ⭐ **from Q1's Birch** | continuous |
| Tailoring 20 | 1235 | ⭐ from Q1's Bogflax | continuous |
| Tailoring 30 | 2610 | Seawrack Robe (220) | ~7 after gate 20 |
| Potions 30 | 2610 | Saltwort Draught (88) | ~16 after gate 20 |

⭐ **Woodcarving and Tailoring enter the quarter already climbing** — a player
who worked Q1's ladder arrives near 15–18 and the tier-3 gate at 20 is a short
push. **Metalworking and Jewelry start at 1**, which is the correct feel for a
skill you just learned, and their first gates are cheap so the debut is not a
wall.
⚠️ **Potions' Q2 gates (20/25/30) are the steepest climb in the quarter**
because Q1 gave the skill only two recipes. 📝 Consider dropping the Antidote
to gate 22.

### 5.3 §6a.1 slot coverage — what this quarter fills

| Slot | Q1 maker | Q2 maker | Change |
|---|---|---|---|
| Hat | Tailoring (Bindweed/Bogflax) | Tailoring (Seawrack/Tussock) | continues |
| Robe Top | Tailoring | Tailoring | continues |
| Robe Bottom | Tailoring | Tailoring | continues |
| Boots | Tailoring | Tailoring | continues |
| Gloves | Tailoring | Tailoring | continues |
| Belt | Tailoring (2 belts) | Tailoring (2 belts) | continues |
| Main hand | Woodcarving (Oak/Birch) | Woodcarving (Yew/Rowan) | continues |
| Off hand | Woodcarving (Knot) | Woodcarving (Knot) | continues |
| **Neck** | ⚠️ **drop-only** | ✅ **Jewelry — Jasper Pendant** | ⭐ **newly filled** |
| **Ring** | ⚠️ **drop-only** | ✅ **Jewelry — Amber Ring, Obsidian Ring** | ⭐ **newly filled** |
| — | — | Metalworking → feeds 9 recipes | ⭐ newly filled |
| — | — | ⚠️ **Enchanting: still empty** | Meridian, L36 |

⭐ **§6a.1's *"every slot has a maker"* becomes true for the first time in this
quarter.** Q1 satisfied it on paper only — Neck and Ring were drop-only by
ruling because no maker existed.

---

## 6. Gather nodes

✅ 13 nodes. ⚠️ **Two materials get none**, because hides are kill-only
(§9b.7b): `rimepelt` and `emberhide`.
✅ **Skill is read off the material's consuming skill** per §6a.1 — Woodcarving
← Felling, Tailoring/Potions ← Foraging, Jewelry (gems) + Metalworking (ore)
← Mining. ⭐ **No Charcoal-style exception is needed this quarter**: every
Kinetic material's consumer maps cleanly.
✅ **XP is `9 + 2 × (zone.minLevel − 1)`**, so a harvest is worth the same
~2.6-harvests-per-skill-level everywhere.

| id | Zone | Skill | Yields | min–max | **XP** | Gesture 📝 | Flavour hook |
|---|---|---|---|---|---|---|---|
| `oq_tin_seam` | old_quarry | Mining | `tin_ore` | 2–4 | **37** | `sweetSpot 'strike' reps 3` | A seam in a terrace wall the diggers left because it was not what they came for |
| `oq_jasper_face` | old_quarry | Mining | `quarry_jasper` | 2–3 | **37** | `alignCommit 'split' complexity 2` | Red banding in a cut face, squarer than anything nature makes |
| `sc_wrackline` | stormcliff_coast | Foraging | `seawrack_fibre` | 2–4 | **41** | `rateDrag 'draw'` | The tideline's own rope, laid out and salt-cured by the weather |
| `sc_saltwort_ledge` | stormcliff_coast | Foraging | `saltwort` | 2–3 | **41** | `trace 'pick' complexity 2` | It grows where the spray reaches and nowhere the spray does not |
| `ws_yew_break` | windward_steppe | Felling | `yew_log` | 2–4 | **45** | `releaseTiming 'chop' reps 3` | The only trees on the steppe, and every one of them leaning the same way |
| `ws_tussock_swale` | windward_steppe | Foraging | `tussock_flax` | 2–3 | **45** | `rateDrag 'draw' reps 2` | A dip where the wind passes over rather than through |
| `ff_lichen_shelf` | frostfell_pass | Foraging | `hoarlichen` | 2–3 | **49** | `trace 'peel' complexity 2` | Grey-green scale on black rock, the only living colour in the pass |
| `ff_everice_seam` | frostfell_pass | Mining | `everice` | 2–3 | **49** | `alignCommit 'pry' complexity 3` | Ice in the rock that the black walls have never warmed |
| `tp_rowan_stand` | thunderspire_peaks | Felling | `rowan_log` | 2–4 | **53** | `releaseTiming 'chop' reps 4` | Mountain ash above the treeline, which should not be possible |
| `tp_iron_seam` | thunderspire_peaks | Mining | `iron_ore` | 2–4 | **53** | `sweetSpot 'strike' reps 4` | Rust-red rock that the storm has been finding for a very long time |
| `tp_humming_face` | thunderspire_peaks | Mining | `hum_quartz` | 2–3 | **53** | `bandKeeper 'ring'` ⭐ | Quartz with a note in it. Strike it wrong and the note stops |
| `md_obsidian_flow` | the_molten_deep | Mining | `obsidian` | 2–3 | **57** | `alignCommit 'flake' complexity 3` | A glass front where the floor stopped being liquid, still sharp |
| `md_firesalt_crust` | the_molten_deep | Foraging | `firesalt` | 2–4 | **57** | `rateDrag 'scrape' reps 2` | White crust at a vent's lip, where the heat leaves something behind |

⭐ **Every gathering skill stays levelable, and Mining stops being the poor
relation.** Felling 2 nodes · Foraging 5 · Mining 6. Q1 gave Mining exactly
two nodes in the whole game; the Kinetic quarter is where a pickaxe becomes a
real ladder.

⚠️ **`tp_humming_face` uses `bandKeeper`, which no gather node has used
before.** ⭐ Deliberate: §9b.9c's "more difficulty, not more vocabulary" is
about *tiers*, and this is a new *material* with a fiction that names its own
engine — quartz that rings, held in a band or it stops. 📝 Swap to `sweetSpot`
if a third mining engine is unwelcome.

---

## 7. Cross-checks appendix

### 7.1 Counts

| Thing | Count | Check |
|---|---|---|
| Creatures | **66** | ✅ 6 zones × (5 commons + 4 minis + 2 bosses) |
| — commons | 30 | ✅ 5 per zone; ⚠️ no zone repeats an archetype inside its five |
| — minis | 24 | ✅ one Champion, one Redoubt, one Executioner, one Hexer per zone (§2g) |
| — bosses | 12 | ✅ 5 Juggernaut · 4 Tyrant · 3 Aspect |
| Item definitions | **64** | Old Quarry 12 · Stormcliff 14 · Windward 16 · Frostfell 6 · Thunderspire 8 · Molten Deep 8 |
| — materials | 15 | ✅ 2+2+2+3+3+3 (§9b.8 ruling 7) |
| — motes | 9 | 3 families × dust/shard/crystal |
| — consumables | 4 | `hardtack` (drop-only) + 3 crafted |
| — intermediate goods | 2 | `bronze_ingot`, `iron_ingot` |
| — equipment | 31 | 21 crafted + 10 drop-only |
| — keys | 3 | the Sigil's three parts |
| Recipes | **26** | ✅ Ruling 3's "~20–26"; Woodcarving 6 · Metalworking 2 · Tailoring 12 · Potions 3 · Jewelry 3 |
| Gather nodes | **13** | 15 materials − 2 kill-only hides |
| New files | **10** | 6 bestiaries, 6 catalogues, 1 recipe file, 13 nodes appended to `GatherNodes` — plus registrations |

⚠️ **Registration is where a silent failure lives.** Every new bestiary must be
listed in `Bestiary.all`; every catalogue in `ItemCatalogue.byZone` keyed by
its **real `world.dart` zone id**; the recipe file in `RecipeBook.all`; every
node in `GatherNodes.all`. An unlisted one compiles fine and never appears.

### 7.2 Id uniqueness against the shipped game

Checked mechanically against all 289 ids currently in
`lib/game/items/catalogue/`, `lib/game/items/recipes/`, `lib/game/gathering/`
and `lib/game/enemies/`:

> ✅ **66 creature ids + 64 item ids + 26 recipe ids + 13 node ids = 169 new
> ids. Zero collisions with shipped ids, and zero duplicates among themselves.**

Near-misses worth knowing about, all distinct and all deliberate:

| Pair | Why it is fine |
|---|---|
| creature `leanstone` / item `leanstone_charm` | Q1 precedent: creature `heartwood` / item `heartwood_stave` |
| creature `fulgurite_crawler` / item `fulgurite_pendant` | different namespaces, different strings |
| creature `firstmelt` / item `firstmelt_loop` | as above |
| creature `obsidian_golem` / material `obsidian` / item `obsidian_ring` | ⚠️ the Golem is Old Quarry's, the material is the Deep's — a Geo name in a Geo zone and a Pyro+Geo material |
| creature `the_overseer` / item `overseers_seal` | ✅ exactly the pairing §9b.8 ruling 9 asked for |
| mini `the_long_line` / epic `the_long_lean` / epic `the_long_cooling` | ⚠️ three "The Long …" names in one quarter. Distinct ids, but 📝 the *display* names may read as a set they are not |
| move prefixes `oq_ sc_ ws_ ff_ tp_ md_` | none collide with `ww_ gb_ cp_ tm_ av_` |

### 7.3 Every drop-table id resolves

| Zone | Ids referenced | All defined? |
|---|---|---|
| old_quarry | `geo_dust` `geo_shard` `geo_crystal` `tin_ore` `quarry_jasper` `hardtack` `overseers_seal` `the_given_weight` `geo_essence` | ✅ all in `old_quarry_items.dart` |
| stormcliff_coast | `electro_*` `seawrack_fibre` `saltwort` `saltwort_draught` `hardtack` `fulgurite_pendant` `uplight` `electro_essence` | ✅ `hardtack` from Old Quarry, rest local |
| windward_steppe | `aero_*` `yew_log` `tussock_flax` `hardtack` `leanstone_charm` `the_long_lean` `aero_essence` | ✅ |
| frostfell_pass | `aqua_*` ✅ **Q1** `aero_*` `rimepelt` `hoarlichen` `everice` `hardtack` `rimebound_ring` | ✅ `aqua_*` resolve to `glimmerbrook_items.dart` |
| thunderspire_peaks | `electro_*` `aero_*` `rowan_log` `iron_ore` `hum_quartz` `hardtack` `countstone_pendant` | ✅ |
| the_molten_deep | `pyro_*` ✅ **Q1** `geo_*` `emberhide` `obsidian` `firesalt` `hardtack` `firstmelt_loop` `the_long_cooling` | ✅ `pyro_*` resolve to `cinderpeak_items.dart` |

⭐ **Four cross-quarter references, all deliberate:** `aqua_*` and `pyro_*`
resolving to Q1 catalogues is the hybrid rule working as designed — *"a hybrid
drops both its parents' motes"*, and here one parent is a Primal element.

### 7.4 Every recipe input is obtainable in-band

| Input | Source | In band? |
|---|---|---|
| `copper_ore` ⏳ | `cp_copper_seam`, Cinderpeak 6–11 | ✅ banked, re-farmable |
| `charcoal` ⏳ | `av_charcoal_burn`, Ashfall 10–14 | ✅ banked, re-farmable |
| `amber` ⏳ | `tm_amber_bog_oak`, Thornmire 8–13 | ✅ banked, re-farmable |
| `fenroot` ⏳ | `tm_fenroot_hummock`, Thornmire 8–13 | ✅ banked, re-farmable |
| `tin_ore` | `oq_tin_seam` + Old Quarry commons | ✅ |
| `quarry_jasper` | `oq_jasper_face` + Old Quarry commons | ✅ |
| `bronze_ingot` | crafted (#1) | ✅ |
| `iron_ore` / `iron_ingot` | `tp_iron_seam` + Thunderspire commons / crafted (#2) | ✅ |
| `seawrack_fibre` | `sc_wrackline` + Stormcliff commons | ✅ |
| `saltwort` | `sc_saltwort_ledge` + Stormcliff commons | ✅ |
| `yew_log` | `ws_yew_break` + Windward commons | ✅ |
| `tussock_flax` | `ws_tussock_swale` + Windward commons | ✅ |
| `rimepelt` | ⚠️ Frostfell **kills only** — Rime Stalker, Hoarbound, minis, bosses | ✅ by design |
| `hoarlichen` | `ff_lichen_shelf` + Frostfell commons | ✅ |
| `rowan_log` | `tp_rowan_stand` + Thunderspire commons | ✅ |
| `emberhide` | ⚠️ Molten Deep **kills only** — Molten Warden, Crustwalker, minis, bosses | ✅ by design |
| `obsidian` | `md_obsidian_flow` + Molten Deep commons | ✅ |
| `firesalt` | `md_firesalt_crust` + Molten Deep commons | ✅ |
| `pyro_dust` | ✅ Q1 + The Molten Deep's `always` bucket | ✅ |

⚠️ **`everice` and `hum_quartz` have no Kinetic consumer, by design** (⏳
banking, §3.1). ⚠️ **A test must assert that**, or the "every material is
consumed" check will flag them as orphans forever — exactly as Q1's suites had
to for Copper and Amber.

### 7.5 Economy invariants

| Invariant | Where it is honoured |
|---|---|
| Dust drops routinely | Every `_commonAlways` bucket, chance 0.75 (0.5 + 0.5 in hybrids) |
| Shard is occasional | Main tables only, weight 5–8; and one guaranteed per mini |
| Crystal is rare, mini/boss only | `_miniDrops` at chance 0.25; `_bossDrops` guaranteed 1–2. ⚠️ **Never on a common** |
| Core never drops | ✅ no Core defined this quarter (§3.2) |
| Hearts are craft-only | ✅ no Heart defined |
| Rare components only off difficult enemies (§3.5) | ✅ no `ComponentDef` this quarter — components are Tier III/IV set parts (L45+). The equivalent, drop-only Rare and Epic gear, appears **only** on `_miniDrops` and `_bossDrops` |
| Gate items never behind a dice roll | Three essences on `always`, both bosses of each pure zone |
| Hybrids drop no gate item | ✅ Frostfell, Thunderspire, Molten Deep |
| Crafted is the floor, drops are the ceiling (§9b.4a) | §2.6's table: crafted-only ≈ 6.9 levels, best-in-slot ≈ 10.7 |
| Common rarity = flat stats only (§8) | ✅ every crafted set piece and weapon is Common and carries only flat numbers or a paired chance/amount |
| Belts are capacity, never power (§6b.2) | ✅ both belts are `beltSlots` alone |

### 7.6 What the shipped test suites will need

One file per zone, mirroring `test/glimmerbrook_test.dart`:

- 11 creatures, ranks 5/4/2, one of each mini archetype
- ⚠️ `maxHpAt` equals `scaledMaxHp(L) × hpScale` for one common and one boss
- ⚠️ **raw damage ≤ 60 and ≤ 12 per charge on every move** (§1.3)
- every drop id resolves through `ItemCatalogue`
- pure zones: **both** bosses guarantee the essence; hybrids: **no** essence anywhere
- no Crystal on any common table
- move names pass the §3.3 voice check
- ⚠️ `everice` and `hum_quartz` are asserted **unconsumed** (§7.4)
- ⚠️ Q1 regression: no Q1 `EnemyDef` carries a combat-stat block (§2.2)

---

## 8. Decisions needed

⚠️ **Eight items. Each blocks or reshapes something a builder will otherwise
guess at.**

### 8.1 Where is Jewelry learned?

Ruling 3 says Jewelry debuts this quarter on banked Amber. But `world.dart`
sites Jewelry at **Rimeholt, `opensAtLevel: 45`**, ITEMS §9b.1's final station
map agrees, and §9b.8 ruling 9 says *"Jewelry is drop-only all quarter (no
maker until Rimeholt)"* — a statement about Q1 that gave a Q4 reason.
`world.dart`'s own comment is *"each town is the only place its skill can be
learned, until Zenith."*

**A level-15 player cannot reach Rimeholt.** So: where do they learn Jewelry?

| Option | Cost |
|---|---|
| **(a)** Move Jewelry's *learning* to Forgeholm and leave the *station* at Rimeholt | Splits "learn" from "station" — a new concept, but §9b.2 already says stations are convenience not gates, so the split is half-made already |
| **(b)** Give Forgeholm two skills (Metalworking + Jewelry) | ⚠️ Breaks the one-skill-per-town shape that makes the map teach |
| **(c)** Cut the three Jewelry recipes; Amber keeps banking to L45 | ⚠️ Contradicts Ruling 3 and leaves Neck/Ring drop-only for another thirty levels |
| **(d)** Galehaven (L22) takes Jewelry as a second skill | Coastal trade town, "nothing here is made locally except the ships" — ⚠️ the arrival text argues against it |

📝 **Recommendation: (a).** It is the smallest change, it fits §9b.2, and the
three recipes are a clean excision if the answer turns out to be (c) —
removing them leaves **23 recipes**, still in the ruled range.

### 8.2 Is "gear ≈ ten levels" a target, a ceiling, or retired?

§2.6 measures it: Q1's best-in-slot is **6.7 levels**; this budget reaches
**10.7** at the very top, and **6.9** on crafted gear alone. Three readings,
and the answer changes twenty numbers:

- **(a) Ten levels is the best-in-slot target.** ✅ This contract's budget
  already lands there. Q1 is then simply under-budgeted, which is fine.
- **(b) Ten levels is what *crafted* gear should reach.** Every Q2 crafted
  stat roughly doubles. ⚠️ That makes crafted gear beat Q1's boss uniques,
  which §9b.4a forbids.
- **(c) The invariant is retired** and replaced by §9b.4a's *"gear advantage
  caps at roughly one material tier"*, measured per tier at that tier's equip
  level.

⚠️ **Whichever is chosen, note that flat modifiers decay against a 4%/level
geometric curve** — a +20 HP robe is 8% of the bar at equip 24 and 6.7% at 29.
Any invariant stated in *levels* has to be re-anchored per tier or it drifts
by construction.

### 8.3 Windward Steppe's empty arena

ENEMIES §2f proposes, 📝, that one of the Steppe's two boss draws be **nothing
at all** — *"you reach the end and it just keeps blowing"* — and immediately
flags it as *"mechanically awkward."* This contract ships two real bosses
(*The Unbroken Blow*, *Tempest Monarch*), which is what §2g's table says.

**Is the empty arena dead, deferred, or should *The Unbroken Blow* be written
as a deliberately very short encounter?** ⚠️ If it is deferred, say so here,
because a later "add the empty draw" is a change to `Adventure`'s line builder
and to the zone-clear path, not to the bestiary.

### 8.4 The Adept is missing from five of six Kinetic zones

ENEMIES §2f: *"Adept appears in only 10 of 25 zones, and it is the yardstick…
in the 15 zones without one, the player has no baseline — every fight is an
exception to a rule they never met. Adept should arguably be mandatory in
every zone."*

Only **Stormcliff Coast** has one (the Tidecaller). §2e's rosters are canon,
so this contract encodes them as written. If the designer wants the yardstick
everywhere, here is the smallest swap per zone:

| Zone | Change | Cost |
|---|---|---|
| Old Quarry | `gravelswarm` Lasher → **Adept** | ⚠️ loses the swarm's multi-hit lesson; a gravel swarm is a poor Adept |
| Old Quarry (alt) | `quarry_golem` Bruiser → **Adept** | ⚠️ it is the anchor name and a golem is a Bruiser |
| Windward Steppe | `chaff` Lasher → **Adept** | ⚠️ chaff is by definition many small pieces |
| Frostfell Pass | `rime_stalker` Skirmisher → **Adept** | ⭐ **cheapest** — a stalker that fights honestly is believable, and it is the anchor |
| Thunderspire Peaks | `ionwake` Skirmisher → **Adept** | ⭐ cheap |
| The Molten Deep | `slagswimmer` Skirmisher → **Adept** | 🟡 workable |

📝 **Recommendation: yes for Frostfell, Thunderspire and the Deep** (three
cheap Skirmisher→Adept swaps), **no for Old Quarry and Windward Steppe**,
where every candidate fights the ENEMIES §2b rule. That gives the quarter four
yardsticks in six zones without inventing a creature nobody believes in.

### 8.5 The Antidote and the offensive potion need engine vocabulary

ITEMS §9b.8 ruling 5 makes both this quarter's job. But `ItemEffect` has
exactly three fields — `healPercent`, `healPerTurnPercent`, `healTurns` — and
its own doc says it is *"deliberately small. Only healing exists because only
healing is designed."*

So `hoarlichen_antidote` (#25) and `firesalt_flask` (#26) cannot be written
against the shipped type. **What vocabulary do they get?**

- **Antidote:** cleanse *which* statuses? All? A named list (Burn, Waterlog,
  Blind)? One, chosen by the ingredient, per §9b.8's *"form = mechanic,
  ingredient = magnitude"* grammar? ⚠️ And *"Antidote"* is a **form** name in
  that grammar, so whatever it does defines every future Antidote.
- **Offensive potion:** flat damage, or element-typed? ⚠️ If it is typed it
  interacts with the counter wheel and with shields, which is a much larger
  change than a number.
- ⚠️ **`HealOverTimeStatus` exists but has no in-duel trigger** (§9b.8) —
  using a belt item as a turn action is unbuilt. Both new potions are Beltable
  and land on the same missing feature.

📝 **This is the only place in the contract that names an output nothing can
represent.** If the vocabulary is not ruled, recipes 25 and 26 must be cut
(→ **24 recipes**) and `hoarlichen` and `firesalt` re-banked ⏳ for Q3.

### 8.6 Sigil part naming

The three gate items are written **Geo Essence / Electro Essence / Aero
Essence** — matching NARRATIVE's own word and the Celestial Totem's *"charged
with Solar, Lunar and Astral"*. ⚠️ It does **not** match Q1's voice, where the
same object was *Proof of the Woods*, *Proof of the Brook*, *Proof of the
Foothills* — evocative, place-named, and much better lore.

📝 The place-named alternative, if wanted: **The Quarry's Weight** ·
**The Standing Charge** · **The Long Blow**. Ids would become
`the_quarrys_weight`, `the_standing_charge`, `the_long_blow` — ⚠️ and the last
of those collides in *reading* with `the_long_line` / `the_long_lean` /
`the_long_cooling` (§7.2's flagged near-miss).

### 8.7 Two of the six zones get no Epic

Frostfell Pass and Thunderspire Peaks have a Rare mini drop and no Epic; the
other four have both. §4.4 gives the reason — the four Epics sit on the four
boss pools carrying canon element-roster names — and pays the two hybrids in
**doubled Crystals** instead.

📝 **Confirm or reject.** The alternative is six Epics (one per zone), which
is three times Q1's density across only slightly more content. ⚠️ Whichever
way, the reason should be written into the zone files, because "why does the
White Corridor drop nothing special" is a question a player will ask.

### 8.8 Thunder Roc's element

`thunder_roc` is a GAME_DESIGN §5 **Electro** roster name, assigned **Aero**
in §4.5 so that it does not read as the same creature as `stormcrest_roc` at
two sizes. 📝 One-line ruling either way; it changes one field and one move
set's element.

---

## Appendix A — file manifest for builders

| File | Contents | Registered in |
|---|---|---|
| `lib/game/enemies/old_quarry.dart` | 11 `EnemyDef` + 3 shared drop tables | `Bestiary.all` |
| `lib/game/enemies/stormcliff_coast.dart` | 11 + 3 | `Bestiary.all` |
| `lib/game/enemies/windward_steppe.dart` | 11 + 3 | `Bestiary.all` |
| `lib/game/enemies/frostfell_pass.dart` | 11 + 3 | `Bestiary.all` |
| `lib/game/enemies/thunderspire_peaks.dart` | 11 + 3 | `Bestiary.all` |
| `lib/game/enemies/the_molten_deep.dart` | 11 + 3 | `Bestiary.all` |
| `lib/game/items/catalogue/old_quarry_items.dart` | 12 defs | `ItemCatalogue.byZone['old_quarry']` |
| `lib/game/items/catalogue/stormcliff_coast_items.dart` | 14 defs | `…['stormcliff_coast']` |
| `lib/game/items/catalogue/windward_steppe_items.dart` | 16 defs | `…['windward_steppe']` |
| `lib/game/items/catalogue/frostfell_pass_items.dart` | 6 defs | `…['frostfell_pass']` |
| `lib/game/items/catalogue/thunderspire_peaks_items.dart` | 8 defs | `…['thunderspire_peaks']` |
| `lib/game/items/catalogue/the_molten_deep_items.dart` | 8 defs | `…['the_molten_deep']` |
| `lib/game/items/recipes/kinetic_recipes.dart` | 26 `RecipeDef` | `RecipeBook.all` |
| `lib/game/gathering/gather_node.dart` | +13 `GatherNodeDef` | `GatherNodes.all` |
| `lib/game/enemies/enemy_def.dart` | ⚠️ +1 field, §2.2 | — |
| `lib/game/opponent_driver.dart` | ⚠️ +`opponentCombatStats`, §2.2 | — |
| `lib/game/duel_controller.dart` | ⚠️ apply it in `_buildMage`, §2.2 | — |
| `test/<zone>_test.dart` × 6 | §7.6 | — |

⚠️ **The four builders' seams:** the six bestiaries and six catalogues split
cleanly two zones apiece, but `kinetic_recipes.dart`, `gather_node.dart`,
`Bestiary.all`, `ItemCatalogue.byZone` and the three engine files in §2.2 are
**shared**. Assign each shared file one owner, or the merge is four
conflicting edits to the same list.

---

## Changelog

**2026-08-24 — first draft.** Written against `100dc7f`. Encodes Christian's
four rulings of 2026-08-19. Numbers computed from the shipped engine, not
estimated; id uniqueness verified mechanically against 289 shipped ids.
