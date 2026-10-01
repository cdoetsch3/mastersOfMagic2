# Ethereal Quarter — Content Contract (items & economy)

Status: 📝 **draft, for red-pen.** Written 2026-09-22 against `ae9743c`.
⚠️ **Nothing here is built.** This document is the item/economy half of the
Ethereal quarter — **the last content quarter in the game**. A parallel lane
owns the **rosters**; the two join by zone + drop role (CELESTIAL §0.4, which
applies here unchanged).

**Scope:** the eight Ethereal zones, Lv 45–60 — **79 item definitions**,
**32 recipes**, **18 gather nodes**, one tier gate (The Eclipsed Citadel), and
the game's top pre-Phase-8 items.

> ### How to read this
>
> | Mark | Meaning |
> |---|---|
> | 📝 | **A number the designer is expected to want to tune** |
> | ⭐ | The reasoning worth preserving through a rewrite |
> | ⚠️ | A trap, an invariant, or a place a builder will get it wrong |
> | ✅ | Canon — taken from a doc or from shipped code, not invented here |
> | ⏳ | A **banking** material — ⚠️ **nothing banks out of this quarter** (§0.2) |
>
> ⚠️ **Every id in this document is final and unique** (§7.2).
> ⚠️ **Read CELESTIAL_CONTRACT first.** This document continues its tables, its
> ladders and its rulings; where a section says "continues", the Celestial
> section of the same number holds the reasoning.

---

## 0. What is canon and what is proposed

### 0.1 Canon — do not change without changing the source doc

| Fact | Source |
|---|---|
| Eight zones, ids, bands, kinds, planes and elements | `lib/game/world.dart` — `hallowmarch` 45–49 Sanctus · `the_buried_sky` 46–50 Geo+Astral 🏰 · `the_umbral_wastes` 47–51 Umbra · `the_sealed_garden` 49–53 Flora+Sanctus · `the_collapsed_academy` 50–54 Arcane 🏰 Empyrean · `the_reliquary_deep` 52–56 Sanctus+Umbra 🏰 · `the_unwritten_library` 54–58 Umbra+Arcane 🏰 Empyrean · `the_eclipsed_citadel` 58–60 **all twelve** 🏰 Empyrean |
| Zone themes and quotes | ENEMIES §2e; WORLD_DESIGN §4c.1a/§4c.1b for the two reach-back hybrids |
| Creature names, archetypes, boss pools | ENEMIES §2e/§2g — ⚠️ the roster lane's |
| **Spiritwood 45 (Hallowmarch) · Aetherwood 50 (The Collapsed Academy)**, with gem-slot ranges 2–3 and 3 | ITEMS §9b.6 — named by zone |
| **Jewelry's station and learning are at Rimeholt, L45** | `world.dart`; ITEMS §9b.8 ruling 9; KINETIC §8.1 |
| The Eclipsed Citadel's gate is *"Three Ethereal key fragments"* | `world.dart` |
| Zenith's gate is *"The Concordant Crown: twelve elemental gems and twelve Cores, bound with a purchased binding spell"* | `world.dart` — ⚠️ **out of scope**, §3.4a |
| Gates are **shown, not spent** | `world.dart`, `GameState.gateRefusal` (ruling 2026-09-21) |
| *"Enemies out-level you by up to ten; gear closes the gap, not XP"* | `world.dart`, the Ethereal band comment — ⚠️ §2.6a |
| The Eclipsed Citadel *"should NOT use the 5-commons / 4-minis / 2-bosses template"* | ENEMIES §2e — ⚠️ roster lane's, but it shapes §4.8 |
| The Unwritten Library's third boss *Your Entry* exists only on a repeat clear | ENEMIES §2e — ❓ unruled, §4.7 |
| Everything else this contract inherits | CELESTIAL §0.1 |

### 0.2 The standing rulings this contract encodes (Christian, 2026-09-22)

Identical to CELESTIAL §0.2, plus one that only this quarter can carry:

> ⭐ **RULED: nothing banks out of the Ethereal quarter, because there is no
> next quarter.** Every one of this contract's twenty materials has a consumer
> inside it (§7.4), and **the seven gems banked across three quarters are all
> spent here** (§5.1 #26–#32). KINETIC §8.1's *"Q2's role is to start finding
> jewel materials that bank until Jewelry unlocks"* is paid in full.
> ⚠️ **The only exceptions are `hoarlichen` and `firesalt`**, which still wait
> on the Antidote and the offensive potion — a Phase 8 debt, not a banking
> one (§9).

### 0.3 What this contract deliberately does NOT specify

As CELESTIAL §0.3, plus:

- **The Eclipsed Citadel's roster.** ENEMIES §2e proposes it is *"the game
  replaying itself"* — echoes of bosses the player has already beaten — and
  leaves the boss pool ❓ open. ⭐ **Nothing in §4.8 depends on the answer**: the
  Citadel's drops are attached to *the boss* and *the echo pool*, whatever
  those turn out to be.
- **The Concordant Crown, and Zenith.** §3.4a.
- **Set tiers III and IV** (ITEMS §3.4 puts them at L45 and L50, Mythic and
  Legendary). ⚠️ **They are Phase 8 and they are why this quarter ships no
  Mythic or Legendary equipment** — see §2.7.

### 0.4 The join with the roster lane

Unchanged from CELESTIAL §0.4. ⚠️ **One addition:** The Eclipsed Citadel has
**no `material` role and no gather node** (§4.8, §6). Its two materials are
kill-only and come off the boss and the echo pool, so the roster lane owes this
zone nothing but a boss and a pool to hang `always` lines on.

---

## 1. The baseline statline

### 1.1 The formula — unchanged

```
maxHp(archetype, L)  = round( round(100 × 1.04^(L−1)) × archetype.hpScale )
damage(archetype, L) = round( rawRoll × 1.04^(L−1) × archetype.damageScale )
```

⭐ **Still: the extrapolation is to do nothing.** CELESTIAL §1.1, KINETIC §1.1.

### 1.2 Worked HP table — the Ethereal band

`scaledMaxHp` at the three sample levels: **L45 = 562 · L52 = 739 · L60 = 1012.**
(`1.04^44 = 5.6165`, `1.04^51 = 7.3910`, `1.04^59 = 10.1150`.)

⭐ **L60 is the first time the player's own bar passes 1,000**, and it is worth
saying out loud: the whole game's numbers are 10.1× their level-1 values by the
end, and every one of them got there through the same `1.04^(L−1)`.

| Archetype | Tier | HP× | DMG× | **HP @45** | **HP @52** | **HP @60** |
|---|---|---|---|---|---|---|
| Drudge | common | 0.80 | 0.70 | 450 | 591 | 810 |
| Skirmisher | common | 0.70 | 1.15 | 393 | 517 | 708 |
| Lasher | common | 0.85 | 1.00 | 478 | 628 | 860 |
| Glasswing | common | 0.50 | 1.70 | 281 | 370 | 506 |
| Adept | common | 1.00 | 0.90 | 562 | 739 | 1012 |
| Sentinel | common | 1.25 | 0.70 | 702 | 924 | 1265 |
| Bruiser | common | 1.15 | 1.10 | 646 | 850 | 1164 |
| Blighter | common | 1.00 | 0.60 | 562 | 739 | 1012 |
| Siphon | common | 0.95 | 0.85 | 534 | 702 | 961 |
| Champion | mini | 1.70 | 1.20 | 955 | 1256 | 1720 |
| Redoubt | mini | 2.20 | 0.85 | 1236 | 1626 | **2226** |
| Executioner | mini | 1.20 | 1.90 | 674 | 887 | 1214 |
| Hexer | mini | 1.60 | 0.75 | 899 | 1182 | 1619 |
| Juggernaut | boss | 3.60 | 1.40 | 2023 | 2660 | **3643** |
| Tyrant | boss | 2.60 | 1.70 | 1461 | 1921 | **2631** |
| Aspect | boss | 2.60 | 1.50 | 1461 | 1921 | 2631 |

⚠️ **A Drudge appears at levels 45–54** — Pilgrim's Remnant in Hallowmarch and
Emeritus in The Collapsed Academy (ENEMIES §2e). ENEMIES §2f already flags
these as *"wasted encounter slots"*: a 0.80/0.70 body at L50 has 450 HP and
hits for 8–13 per cast against a 683 HP bar. ⚠️ **That is the roster lane's
call, not this one's**, but the drop tables in §4.1 and §4.5 put the zone's
**consumable** on the Drudge, so a slot that teaches nothing at least pays
something.

📝 **Three numbers to red-pen, and they are the game's largest:** the Juggernaut
at **3643**, the Tyrant at **2631**, and the Redoubt at **2226 with a 10.5% EV
deflection on top of it** (§2.3). ENEMIES §2.2 already named the Redoubt as the
stalemate risk; at L60 it is a 2,226 HP wall that erodes 10.5% of everything.
📝 The lever KINETIC §2.3 named is still the cheapest: drop Redoubt's deflect
chance to 20 (EV 6%) if the fatigue clock has not landed.

### 1.3 The raw-damage authoring table 📝 — ⚠️ still unchanged

⚠️ **Byte-for-byte KINETIC §1.3 and CELESTIAL §1.3.** It does not grow, and at
level 60 a builder will want to believe it does more than anywhere else.

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
⚠️ **The Executioner's cost cap stays at 4.** At L60 the mini five-charge raw
lands **884–1153** against a 1012 HP bar. There is no reading of *"kills you in
three turns if you misplay one"* that survives a one-shot; at cost 4 it lands
500–653, which is the two-cast kill the archetype is for.
⚠️ **The Eclipsed Citadel fields all twelve elements**, so its authors will be
tempted to give it bigger raws to feel final. ⭐ **It does not need them:** at
L60 the same table already produces a Tyrant swing of 722–929, which is 71–92%
of a naked bar. The Citadel is hard because it is level 60 and because no
five-slot loadout counters twelve elements — not because its numbers are
special.

### 1.4 Effective damage — what the player actually takes

| Archetype | dear | @45 | @52 | @60 |
|---|---|---|---|---|
| Siphon | c3 | 88–112 | 113–144 | 155–198 |
| Bruiser | c5 | 185–247 | 244–325 | 334–445 |
| Glasswing | c3 (−35%) | 211–272 | 277–359 | 380–492 |
| Executioner | c4 | 277–363 | 365–477 | **500–653** |
| Juggernaut | c5 | 330–424 | 435–559 | 595–765 |
| Tyrant | c5 | 401–515 | 528–678 | **722–929** |

Player HP: **562 · 739 · 1012**, plus **+252 HP** best-in-slot at L60 (§2.6) —
a 1,264 bar, with 6.2% of incoming deflected and 7.5% of attacks missed.

📝 **Tyrant c5 at L60 = 722–929 against a geared 1,264.** With deflection and
dodge that is an effective **628–808**, or 50–64% of the bar, from a
five-charge telegraph. ⭐ **That is the right shape for the last fight in the
game**: survivable by playing correctly, fatal twice.

### 1.5 Move naming and voice ✅ — unchanged

### 1.6 Adventure shape ✅

✅ **Superseded 2026-09-25:** every run is 9 fights in one shape at every tier
(KINETIC §1.6, GAME_DESIGN §3d) — the tier no longer scales it. ⚠️ **The
Eclipsed Citadel** fights its two-boss sequence in the one boss slot (ENEMIES
§2e) — 10 fights — and §6 gives it **zero** gather nodes, so no node
arithmetic applies to it.

---

## 2. Combat stats — the last three elements, and the last two ladders

### 2.1 The mechanics, as shipped — unchanged

```
hitChance = clamp( 80 + attackerAccuracy − defenderDodge − blind , 10 , 100 )
on crit   : perHit × (150 + critDamage) / 100
on deflect: taken = damage × (1 − deflectAmount/100)
```

> **✅ RULED 2026-09-30: base 5% / +100%** — the `150` above is now `200` (a crit doubles the
> hit), and crit chance starts at 5% before gear.

⚠️ **CELESTIAL §2.1a's accuracy ceiling and §2.1b's summing deflection both
bind hardest here**, because this is the quarter where a player can wear the
best of everything.

### 2.1a Accuracy — the ladder's last two rungs

Following CELESTIAL §2.1a, the weapon ladder's accuracy column stops climbing:

| Wood | Equip | Staff acc | Wand acc | Knot acc | staff ≥ wand + knot? |
|---|---|---|---|---|---|
| Ebony ✅ Q3 | 40 | 11 | 5 | 6 | 11 ≥ 11 ✅ |
| **Spiritwood** | **45** | **12** | **5** | **7** | 12 ≥ 12 ✅ |
| **Aetherwood** | **50** | **12** | **5** | **7** | 12 ≥ 12 ✅ |

⚠️ **Aetherwood's accuracy is identical to Spiritwood's, and that is the
ruling, not an oversight.** ✅ ITEMS §9b.8 ruling 2 (*"the staff out-accurates
wand + knot combined"*) holds at every rung, and the best crafted stack —
staff 12 + Unleft hood 6 = **18** — sits two points under the clamp. Everything
above 20 pays only against dodge and Blind.
⭐ **Aetherwood's tier is expressed in damage, crit and three sockets instead**,
which is the whole reason §4.1a's socket ladder exists.

### 2.1b Deflection — the arithmetic that fixes every number

⭐ **The rule (CELESTIAL §2.1b): deflection lives on the crafted armour set's
gloves and on exactly ONE drop per quarter; the assembled total must satisfy
`Σ deflectAmount ≤ 50`** (ITEMS §4.1a's player cap; the engine's own clamp is
90 and is a different number for a different reason).

⚠️ **At level 60 a player may wear anything from any quarter, so the check is
cross-quarter.** Every `deflectAmount` in the game, and the worst legal
assembly of them:

| Piece | Slot | `deflectAmount` | Quarter |
|---|---|---|---|
| `seawrack_gloves` | gloves | 15 | Q2 |
| `tussock_gloves` | gloves | 20 | Q2 |
| `overseers_seal` | ring | 20 | Q2 |
| `rimebound_ring` | ring | 20 | Q2 |
| `the_given_weight` | neck | 25 | Q2 |
| `the_long_cooling` | hat | 25 | Q2 |
| `mirrorflax_gloves` | gloves | 20 | Q3 |
| `wrackcotton_gloves` | gloves | 24 | Q3 |
| `the_noon_hour` | hat | **14** | Q3 |
| **`umbralweave_gloves`** | gloves | 22 | **Q4** |
| **`unleft_gloves`** | gloves | **26** | **Q4** |
| **`bedrock_greaves`** | robeBottom | **10** | **Q4** |
| **`the_corona`** | hat | **14** | **Q4** |

> ⚠️ **Worst legal assembly: `unleft_gloves` 26 + a deflect hat 14 +
> `bedrock_greaves` 10 = 50 — exactly the cap, and there is no fourth slot
> that carries any.**

⚠️ **This is only true because the Kinetic quarter's ring and neck deflect
pieces are out-classed by this quarter's crafted Jewelry** and nobody will wear
them at 60. 📝 **It is therefore a soft guarantee, and the test in §7.6 must
check the assembled maximum rather than any single item.** If a future item
adds `deflectAmount` to a fourth slot, the cap breaks and nothing per-item will
catch it.

### 2.2 Where the enemy stat block lives — unchanged ✅

KINETIC §2.2. `EnemyDef` + `OpponentDriver.opponentCombatStats`;
`RemoteDuelDriver` returns `none`.

### 2.3 Enemy combat stats by archetype 📝 — unchanged

CELESTIAL §2.3's table holds in full, Siphon row included. ⚠️ Enemy dodge stays
capped at 10.

⚠️ **One zone-local deviation is recommended, in the style of KINETIC §8b's
post-probe amendment:** **The Redoubt in The Buried Sky and The Reliquary Deep**
— *Bedrock Colossus* and *Reliquary Colossus* — are 2.20 HP bodies with 10.5%
EV deflection inside **dungeons**, where a player cannot retreat between
sections. 📝 Drop their deflect to **25/24 (EV 6.0%)** unless the fatigue clock
has shipped. Named here because the balance probe will find it and the fix is
cheaper before the build than after.

### 2.4 The Aspects — the last three elements

Three of this quarter's ✨ bosses are Aspects (ENEMIES §2g).

| Boss (roster lane) | Zone | Element | Stat block 📝 | Why |
|---|---|---|---|---|
| **The Buried Constellation** ✨ | The Buried Sky | **astral** | crit **25** / +45, acc +5 | ⚠️ **Single-element on the Astral half.** Geo is what buried it; Astral is what survived, and Astral's lean is crit chance (§2.5a of CELESTIAL). ⭐ A constellation in the rock is a pattern that was *already complete* — a crit is the same statement |
| **What Was Thought About** ✨ | The Umbral Wastes | umbra | crit **15** / **+70**, defl 20 / 18 (EV 3.6%) | ⭐ Umbra's lean is crit **damage**, and Creeping Dark is growth toward one enormous consequence. ⚠️ **+70 crit damage is the largest number on any stat block in the game** — a crit deals 220% — and it is deliberately paired with a *low* 15% chance. The zone's premise is *deliberate* dark: it does not happen often, and when it does it was decided |
| **The Last Three Items** ✨ | The Collapsed Academy | arcane | defl **35** / 28 (EV 9.8%), acc +10 | ⭐ Arcane's lean is deflection: knowing what is coming is how you take less of it. ⚠️ ITEMS §2.2's watch item — *"Arcane is the standout candidate"* for an over-strong element — applies to the Aspect too. 📝 9.8% EV is a hair under the Redoubt's 10.5 on purpose |

⚠️ **Hallowmarch, The Sealed Garden, The Reliquary Deep and The Unwritten
Library field no Aspect**, per ENEMIES §2g. ⭐ Sanctus therefore **never gets an
Aspect anywhere in the game** — its two bosses are *The Hierophant Eternal* (a
will) and *The Keeper of the Road* (a force). 📝 Worth a ruling: is that a hole,
or is it the right reading of an element whose whole identity is that someone
is still doing the upkeep?

### 2.5 Player gear — where the lines live

CELESTIAL §2.5's distribution table holds. ⭐ **Two lanes complete here:**

| Line | Completed by |
|---|---|
| **Shield strength % + healing received %** | Sanctus — Hallowmarch's `votive_pendant` and `the_maintained_road`, The Sealed Garden's `the_gardeners_loop`, The Reliquary Deep's `censer_pendant`. ⭐ **Four of the quarter's sixteen drops are support pieces, and no earlier quarter had more than one** |
| **Crit damage** | Umbra — `the_considered_ring` and `the_deliberate_dark`, both in The Umbral Wastes, and **both the largest crit-damage numbers a player can wear** |

### 2.5a The affinity table — unchanged, and stated here for the three that matter

CELESTIAL §2.5a proposes the full twelve. The three this quarter ships gear
for:

| Element | Affinity | Inherits |
|---|---|---|
| **Sanctus** | shield strength % + healing received % | **Aqua and Flora at once** |
| **Umbra** | crit damage | **Pyro** |
| **Arcane** | deflection | **Geo** |

⭐ **The Sealed Garden is where the inheritance is stated out loud.** It is
Flora + Sanctus — ✅ *"the game's FIRST element guarded by its LAST"*
(`world.dart`) — and both its drops carry healing, which is Flora's lean and
Sanctus's at the same time. ⚠️ **That zone is the proof of the §2.5a
structure**; if the structure is rejected, The Sealed Garden's gear has to be
rewritten and nothing else does.

### 2.6 ✅ "Gear ≈ ten levels" — measured at L60, the game's ceiling

Method exactly as CELESTIAL §2.6 (reference cast **Ruin**, raw mid 48.5;
`Gacc` clamped at 100; `Gdodge` reported separately). The method reproduces
KINETIC §2.6's published 10.7 before being used.

| Loadout | Ghp | Gdmg | **≈ levels** | with dodge ⚠️ |
|---|---|---|---|---|
| Q2 best-in-slot @29 ✅ published 10.7 | 1.476 | 1.570 | **10.71** | 12.60 |
| Q3 crafted-only @47 | 1.149 | 1.365 | 5.73 | 6.56 |
| Q3 best-in-slot @47 | 1.253 | 1.729 | **9.86** | 12.12 |
| **Q4 crafted-only @60** (Aetherwood staff + Unleft set + Corona Torc + Eclipse Ring) | 1.215 | 1.566 | **8.20** | 9.02 |
| **Q4 best-in-slot @60** (§4's epics + The Unbuilt Stair) | 1.332 | 1.717 | **10.55** | 11.53 |

⭐ **Four findings, and two of them are new.**

1. ✅ **The invariant passes at the ceiling.** Q4 best-in-slot ≈ **10.6 levels**
   against a verbatim ten-level target. The quarter is on budget.
2. ⚠️ **NEW — the crafted floor jumps 2.5 levels in one quarter, and Jewelry's
   debut is the entire cause.** Crafted-only goes 5.7 → **8.2** because
   `craft_corona_torc` and `craft_eclipse_ring` fill the last two slots
   §6a.1 had left drop-only since level 1. ⚠️ **The gap between crafted and
   best-in-slot collapses from 4.1 levels to 2.4.** ITEMS §9b.4a's
   *"crafted is the floor, drops are the ceiling"* is still **true** and still
   **categorical** (a Common crafted piece structurally cannot carry a
   modifier), but it is no longer very far. 📝 **This is a ruling, not a bug:**
   either accept that the last quarter's crafted gear is nearly best-in-slot —
   which is arguably correct, since §9b.4a also says *"the market sells the
   FLOOR, never the CEILING"* and the floor at level 60 should be high — or
   trim `corona_torc` and `eclipse_ring` and widen the gap. This contract
   already trimmed them once (§4.8) and did not trim further.
3. ⚠️ **Dodge is still the uncounted third multiplier** (CELESTIAL §2.6
   finding 2, unresolved). Best-in-slot dodge is held at **6** here — down from
   Kinetic's 11 and Celestial's 13 — deliberately, so that the last quarter
   does not decide the open question by accident.
4. 📝 **Accuracy contributes nothing at the margin.** Crafted-only reaches the
   clamp (21 accuracy) and best-in-slot sits just under it (19). ⭐ A
   best-in-slot loadout is *less* accurate than a crafted one and better in
   every other way, which is the clearest possible demonstration that the stat
   has stopped being a ladder (§2.1a).

### 2.6a ⚠️ "Enemies out-level you by up to ten; gear closes the gap, not XP"

✅ `world.dart`'s comment on the Ethereal band says exactly that. **Measured:**

| | |
|---|---|
| The gap the band promises | up to **10 levels** |
| What best-in-slot is worth | **10.55 levels** (§2.6) |
| What crafted-only is worth | **8.20 levels** |
| What a naked level-60 is worth | 0 |

⭐ **So the comment is literally true and this contract is what makes it true.**
A geared level-50 in Vespergate fights The Unwritten Library's level-58
encounters at rough parity; an ungeared one does not. ⚠️ **That also means the
band cannot be tuned without re-reading §2.6** — dropping the gear budget by
two levels makes the Ethereal band's design promise false.

### 2.7 ⭐ "BiS vs naked ≈ 100%" — what that means in numbers at level 60

ITEMS §2.1 sets the endgame power budget as **BiS vs completely naked ≈ 100%**
and **BiS vs average gear 80–90%**, measured *"both level 50"* — the game's cap
has since moved to 60, so it is measured here at 60.

**The level-60 best-in-slot loadout** (§4, one epic per zone plus the Citadel's
two; The Unbuilt Stair in the main hand, so no off-hand):

| Contribution | Number | Effect |
|---|---|---|
| Flat max HP | **+252** | a 1,012 bar becomes **1,264** — **+24.9% health** |
| Deflection | 26% chance × 24% amount | **6.2%** of all incoming damage erased — effective health **1,348** |
| Dodge | 6 | **7.5%** of incoming attacks miss outright — effective health **1,437** |
| Accuracy | +19 | hit chance 80 → **99%**, i.e. **+23.8% throughput** |
| Flat damage | +54 on a 4-charge cast | Ruin 491 → 545, **+11.0%** |
| Crit | 24% × (50+54) | expected damage **×1.250** *(✅ RULED 2026-09-30: base 5% / +100%: computed on the old base; not recomputed)* |
| **Outgoing total** | | **×1.717** |
| **Effective health total** | | **×1.420** |
| **Effective combat power** | | **×2.44** |

> ⭐ **A best-in-slot level 60 has 2.44× the combat power of a naked level 60.
> That is the same ratio as `1.04^23` — so BiS at 60 fights exactly like a
> naked level 83 would.**

⚠️ **Read it as "23 levels", not "10", and the two numbers are not in
conflict.** §2.6's 10.55 is `ln(Ghp × Gdmg) / (2 ln 1.04)` — the *level
equivalent*, which counts the gap **once** because the enemy's own level moves
both of a mage's halves together. §2.7's 23 is the raw power **ratio**, which
counts HP and damage as a product. ⭐ **The first answers "how many levels of
gear is this?"; the second answers "what happens when they fight?"** A
23-level-equivalent deficit is not a close match at any point on the `1.04`
curve — the naked mage takes 72% more damage per cast and has 42% less
effective health, which is three of their casts to four of the geared one's.
✅ **That is what ITEMS §2.1's "~100% — gear is not optional" means in
numbers.**

📝 **The second half of §2.1 — "BiS vs average gear 80–90%" — is NOT measured
here and cannot be**, because *"average gear"* has no definition yet. 📝 The
cheapest one: **the crafted-only loadout of §2.6**, which is 8.20 levels
against best-in-slot's 10.55, a 2.35-level gap = `1.04^4.7` = **×1.20 power**.
⚠️ **A ×1.20 power edge does not produce an 80–90% win rate** — it is much
nearer 60%. ❓ **Ruling wanted:** either "average gear" means something weaker
than Master-crafted (last quarter's set, say, or a mixed bag), or §2.1's
80–90% target is too high for a world where crafted gear is purchasable. §8.2.

---

## 3. Materials, motes, consumables and id conventions

### 3.1 The twenty materials

✅ 2 per pure zone, 3 per hybrid. ⚠️ **The Eclipsed Citadel gets 2, by ruling —
see the note below the table.**

| id | Name | Zone | Consuming skill | Tier | Gathered by | Node? |
|---|---|---|---|---|---|---|
| `spiritwood_log` | Spiritwood Log | hallowmarch | Woodcarving | 8 | Felling | ✅ |
| `goldenrood` | Goldenrood | hallowmarch | Potions & Alchemy | 8 | Foraging | ✅ |
| `deepstratum_ore` | Deepstratum Ore | the_buried_sky | Metalworking | 8 | Mining | ✅ |
| `nadir_garnet` | Nadir Garnet | the_buried_sky | Jewelry | 8 | Mining | ✅ |
| `corebiter_hide` | Corebiter Hide | the_buried_sky | Tailoring | 8 | — | ⚠️ **kill-only** |
| `umbralweave` | Umbralweave | the_umbral_wastes | Tailoring | 8 | Foraging | ✅ |
| `thoughtglass` | Thoughtglass | the_umbral_wastes | Jewelry | 8 | Mining | ✅ |
| `worldroot` | Worldroot | the_sealed_garden | Potions & Alchemy | 9 | Foraging | ✅ |
| `orchard_amber` | Orchard Amber | the_sealed_garden | Jewelry | 9 | Mining | ✅ |
| `thornpenitent_hide` | Thornpenitent Hide | the_sealed_garden | Tailoring | 9 | — | ⚠️ **kill-only** |
| `aetherwood_log` | Aetherwood Log | the_collapsed_academy | Woodcarving | 9 | Felling | ✅ |
| `mana_slag` | Mana Slag | the_collapsed_academy | Metalworking | 9 | Mining | ✅ |
| `censer_resin` | Censer Resin | the_reliquary_deep | Potions & Alchemy | 9 | Foraging | ✅ |
| `reliquary_gold` | Reliquary Gold | the_reliquary_deep | Jewelry | 9 | Mining | ✅ |
| `unleft_linen` | Unleft Linen | the_reliquary_deep | Tailoring | 9 | Foraging | ✅ |
| `nightink` | Nightink | the_unwritten_library | Potions & Alchemy | 10 | Foraging | ✅ |
| `colophon_stone` | Colophon Stone | the_unwritten_library | Jewelry | 10 | Mining | ✅ |
| `blankspine_vellum` | Blankspine Vellum | the_unwritten_library | Tailoring | 10 | — | ⚠️ **kill-only** |
| `eclipse_iron` | Eclipse Iron | the_eclipsed_citadel | Jewelry | 10 | — | ⚠️ **kill-only** |
| `corona_pearl` | Corona Pearl | the_eclipsed_citadel | Jewelry | 10 | — | ⚠️ **kill-only** |

> ⭐ **RULED: The Eclipsed Citadel yields two materials, both kill-only, and has
> no gather node.** It carries all twelve elements, so ruling 7 would read as
> "hybrid, three" — but ruling 7 counts **what the ground holds**, and the
> Citadel is not ground. ✅ ENEMIES §2e: *"Not a place — an **obstruction**."*
> ⭐ Nothing grows on an obstruction, nothing is mined out of it, and there is
> no seam to work; what it yields, it yields because you took it off the thing
> standing in the door. 📝 The knob is 2 vs 3, and the shape is the ruling.

⚠️ **The Reliquary Deep is the only hybrid in either quarter with three
gatherable materials and no hide** (§6 gives it three nodes). ⭐ Correct: it is
a corridor someone consecrated, and consecrated things are made rather than
skinned.
⭐ **Enchanting gets no material this quarter, and that is the ruling, not an
omission.** Its only Celestial consumer was the Totem (CELESTIAL §3.4) and its
next one is Phase 8's enchants. ⚠️ **Nothing may bank out of this quarter
(§0.2)**, so an Enchanting reagent here would be an orphan with no later
quarter to be spent in — the opposite of `hum_quartz`, which banked into a
quarter that existed.

⚠️ **Three materials are kill-only and must have no node**: `corebiter_hide`,
`thornpenitent_hide`, `blankspine_vellum` — plus the Citadel's two, which have
none for the reason above. ⭐ **A blankspine is a vellum is a hide**, the same
trick `palimpsest_vellum` used one quarter earlier, and the two are deliberately
a pair: the Archive's page had been written on and scraped; the Library's never
has, *yet*.

### 3.2 The six new motes — and the four families that do not need defining

Two new families × three tiers. ✅ Values from ECONOMY §14c: **2 / 25 / 150**.

| id | Name | Element | Tier | Rarity | Defined in |
|---|---|---|---|---|---|
| `sanctus_dust` / `sanctus_shard` / `sanctus_crystal` | Sanctus … | sanctus | dust / shard / crystal | common · common · **uncommon** | hallowmarch |
| `umbra_dust` / `umbra_shard` / `umbra_crystal` | Umbra … | umbra | " | " | the_umbral_wastes |

⚠️ **`arcane_*` is NOT defined here.** The Glass Archive (43–47) is the first
Arcane zone and owns the family (CELESTIAL §3.2). **The Collapsed Academy is
the game's only pure zone that defines no mote family**, and that is correct —
the school lost its subject to an archive seven levels downhill.

⭐ **This quarter's mote sourcing is the game's whole element list, once:**

| Zone | Pays in | Where those families live |
|---|---|---|
| Hallowmarch | `sanctus_*` | here |
| The Buried Sky | `geo_*` + `astral_*` | ⭐ **Q2** (Old Quarry) + **Q3** (Starfall Basin) |
| The Umbral Wastes | `umbra_*` | here |
| The Sealed Garden | `flora_*` + `sanctus_*` | ⭐⭐ **Q1** (Whispering Woods) + here |
| The Collapsed Academy | `arcane_*` | ⭐ **Q3** (The Glass Archive) |
| The Reliquary Deep | `sanctus_*` + `umbra_*` | here |
| The Unwritten Library | `umbra_*` + `arcane_*` | here + Q3 |
| **The Eclipsed Citadel** | ⭐ **all twelve** | everywhere |

⭐⭐ **The Sealed Garden pays in Flora Dust.** The player last saw one in the
Whispering Woods at level 5 and is now level 49. ✅ That is `world.dart`'s
*"the game's FIRST element guarded by its LAST"* expressed as loot, and it is
the single best argument the hybrid mote rule has ever had.

✅ **No Core-tier motes, and no Hearts** — CELESTIAL §3.2's reasoning, and the
same ❓ flagged there. ⚠️ **This is where it bites hardest**: `world.dart` gates
Zenith on *"twelve elemental gems and twelve Cores"*, so **the Concordant Crown
is unbuildable until Core ships** (§3.4a). That is a known, deliberate gap, not
an oversight.

### 3.3 The consumable ladder — the second half

CELESTIAL §3.3 settles the vocabulary: three forms — **Ration** (between
encounters, `ConsumableDef`), **Draught** (in-duel flat, `BeltableDef`),
**Tonic** (in-duel over-time, `BeltableDef`) — and no new `ItemEffect` field.
The magnitudes: **Ration 35% of the band floor's health · Draught 40% · Tonic
24% total at 8% a turn for three turns.**

| id | Name | Form | Kind | `ItemEffect` | Band | % of floor | Value | Source |
|---|---|---|---|---|---|---|---|---|
| `climbers_ration` | Climber's Ration | Ration | `ConsumableDef` | `heal: 195` | 45 | 34.7% | 30 📝 | ⚠️ **drop-only**, all eight zones |
| `goldenrood_draught` | Goldenrood Draught | Draught | `BeltableDef` | `heal: 225` | 45 | 40.0% | 140 📝 | crafted #22; Hallowmarch |
| `worldroot_tonic` | Worldroot Tonic | Tonic | `BeltableDef` | `healPerTurn: 53, healTurns: 3` | 49 | 24.2% | 165 📝 | crafted #23; The Sealed Garden |
| `censer_draught` | Censer Draught | Draught | `BeltableDef` | `heal: 295` | 52 | 39.9% | 210 📝 | crafted #24; The Reliquary Deep |
| `nightink_draught` | Nightink Draught | Draught | `BeltableDef` | `heal: 320` | 54 | 40.1% | 250 📝 | crafted #25; The Unwritten Library |

⭐ **The whole ladder, end to end**, so a designer can see the curve in one
place:

| Band | id | Form | Heal | Beltable? |
|---|---|---|---|---|
| 1–5 ✅ | `foragers_ration` | Ration | 25 | no |
| 3–8 ✅ | `sapwort_draught` | Draught | 30 | yes |
| 10–14 ✅ | `brookmint_tonic` | Tonic | 10×3 | yes |
| 15–19 ✅ | `hardtack` | Ration | 60 | no |
| 23–28 ✅ | `saltwort_draught` | Draught | 75 | yes ⚠️ CELESTIAL §3.3 |
| 30–34 | `pilgrims_ration` | Ration | 110 | no |
| 30–34 | `glasswort_draught` | Draught | 125 | yes |
| 38–42 | `duskcap_tonic` | Tonic | 34×3 | yes |
| 40–44 | `arcsalt_draught` | Draught | 185 | yes |
| 43–47 | `sunbleach_tonic` | Tonic | 42×3 | yes |
| **45–49** | `climbers_ration` | Ration | **195** | no |
| **45–49** | `goldenrood_draught` | Draught | **225** | yes |
| **49–53** | `worldroot_tonic` | Tonic | **53×3** | yes |
| **52–56** | `censer_draught` | Draught | **295** | yes |
| **54–58** | `nightink_draught` | Draught | **320** | yes |

⚠️ **The ceiling check (ITEMS §6b.3), at the top of the ladder:** Nightink
restores 320; a Tyrant's dear move at L54 deals 561–722 and the player's own
Ruin lands ~490 + 54 gear. ✅ **The biggest potion in the game is two thirds of
one cast**, and it costs the turn the cast would have used.
⚠️ **Four rungs, not five, in this quarter, and no Tonic above 49.** ⭐ The
Tonic is a *tempo* item — it pays after the opponent's read — and past level 52
a three-turn payout is often three turns the fight does not have. 📝 Add a
fifth rung (`colophon_tonic`, 62×3, band 54) if the Library should sell both
shapes; the herb is already there.

⭐ **The Ration's last rung is named for the mountain, not the herb.** Rimeholt
is basecamp — ✅ *"everyone you meet is either arriving or leaving; nobody is
from here"* — and Vespergate *"has been brewing their own everything for a long
time."* The Climber's Ration is what both towns sell and what everything on the
mountain is carrying when you kill it.

### 3.4 The gate — three fragments for the Eclipsed Citadel

✅ **Canon:** `world.dart` gates `the_eclipsed_citadel` on *"Three Ethereal key
fragments."* ✅ **Canon:** the mechanism is `gateItemIds` — **shown, not
spent** — shipped and working at Pennycross with three `proof_of_the_*` items.

> ✅ **RULED (build manager, 2026-09-22 — reconciled with ENEMIES §2e.1): three
> `KeyDef`s, one per PURE Ethereal zone.** The roster derives every tier gate
> the same way — Primal proofs from the Primal pure-zone bosses, the Celestial
> essences from Kiln / Mirrormere / Starfall — and the Ethereal fragments
> follow that rule rather than start a second one. ⚠️ The contract's first
> draft placed them on the three dead-end dungeons ("did you climb the
> mountain or only the road?"); that is a real design with a real cost — it
> makes three optional spurs mandatory for the finale — and it is recorded as
> ❓ §8.5 for Christian, not silently dropped.
>
> | | |
> |---|---|
> | `gateItemIds` on `the_eclipsed_citadel` | `['the_kept_third', 'the_dark_third', 'the_written_third']` |
> | Each | `KeyDef`, `gates: 'the_eclipsed_citadel'`, Bound, rarity **rare**, equipLevel 1 |
> | Each drops | **both** bosses of its zone, on the `always` line — ⚠️ never weighted (ENEMIES §2e.1: a mandatory part is never a coin flip) |

| id | Name | Zone | Why that zone |
|---|---|---|---|
| `the_kept_third` | The Kept Third | **Hallowmarch** (45–49, Sanctus) | ⭐ the vow, kept — the Keeper of the Road and the Hierophant Eternal both hold it |
| `the_dark_third` | The Dark Third | **The Umbral Wastes** (47–51, Umbra) | ⭐ dark given a shape — Nightbringer and What Was Thought About |
| `the_written_third` | The Written Third | **The Collapsed Academy** (50–54, Arcane) | ⭐ the last thing anyone wrote down — the Archmage and The Last Three Items |

❓ **§8.5 for Christian — the dead-end alternative.** Fragments from The Sealed
Garden / The Buried Sky / The Reliquary Deep instead, so the finale requires
the whole quarter. Cheap to switch: three ids move zone, nothing else.
⚠️ **This is a collection, and KINETIC §8.6 rejected one.** ⭐ The difference is
that the collection-of-three mechanism has since **shipped and been ruled**
(Christian, 2026-09-21): Pennycross wants three proofs, the guard looks and
does not keep them, and `PlayerProfile.openedGates` makes the opening
permanent. §8.6 rejected an *unbuilt* mechanism; this one is the one that
exists. 📝 If Christian still dislikes collection gates, the Celestial Totem's
shape (CELESTIAL §3.4) applies here unchanged — one crafted key from three
fragments, forged at Vespergate — and costs one recipe.

### 3.4a ⚠️ Zenith, the Concordant Crown, and what this contract cannot finish

✅ `world.dart` gates **Zenith** on *"The Concordant Crown: twelve elemental
gems and twelve Cores, bound with a purchased binding spell."* ⚠️ **Out of
scope, and it cannot be brought in scope by this contract**, because all three
of its halves are Phase 8 or later:

| The Crown needs | Status |
|---|---|
| **twelve elemental gems** | ITEMS §6d — Phase 8, SYSTEMS §3.4/§3.5 unruled |
| **twelve Cores** | ⚠️ **no Core mote exists** — §3.2, and this contract does not add one |
| **a purchased binding spell** | ⚠️ a **monetization** surface (ITEMS §3.6), undesigned |

⭐ **What this contract does do for it:** the Citadel's `corona_pearl` and
`eclipse_iron` are the two highest-tier Jewelry materials in the game and are
the obvious setting stock for a twelve-gem circlet, and `zenith` is the only
town with all six stations. 📝 **The Crown is the natural fast-follow to Phase
8, not to this quarter.**

### 3.5 Id conventions ✅

As CELESTIAL §3.5. **Zone prefixes (new, no collisions):**
`hm_` `bs_` `uw_` `sg_` `ca_` `rd_` `ul_` — and ⚠️ **no `ec_` prefix exists**,
because The Eclipsed Citadel has no gather node to name.

### 3.6 📝 Phase 8 hooks

Every zone section ends with one. ⚠️ **No `setId`, no `setTier`, no enchant
field and no gem item appears anywhere in this contract**, and that is worth
one extra sentence here: ITEMS §3.4 puts **set Tier III at L45 (Mythic)** and
**Tier IV at L50 (Legendary)**, both inside this quarter's band. ⭐ **So the two
rarities this contract is forbidden to use are exactly the two Phase 8 will
need**, and every armour piece below is deliberately a plain Common so that
Phase 8 can add sets *beside* them rather than *instead of* them.

---

### 3.5 Reconciliation with ENEMIES §2e (build manager, 2026-09-22)

The roster and this contract were written in parallel; the code lanes join
them by zone + role. Three rules close the gaps the join found:

1. ⭐ **`hide` where the zone defines no hide item** → the role resolves to
   the zone's SECOND gatherable material at the same weight a hide would
   carry. Only five zones have a true kill-only hide (`drownling_hide`,
   `palimpsest_vellum`, `corebiter_hide`, `thornpenitent_hide`,
   `blankspine_vellum`); everywhere else "something died" pays in the
   zone's stuff.
2. ⭐ **The Eclipsed Citadel**: `material` → `eclipse_iron`, `hide` →
   `corona_pearl` (both kill-only, no node). `mote` → **twelve rows**, one
   per family, `chance: 0.12` each (§8.4, chosen). Procarius's `key` is the
   Concordant Crown frame, which has **no item yet** (the Crown is blocked
   on Core/Heart motes — §3.2): the code lane drops nothing for it and
   leaves a 📝 on the boss.
3. ⭐ **Keys drop from BOTH bosses of a gate zone**, `always`, never
   weighted — the roster's ruling, adopted here.

## 4. The eight zones

Conventions as CELESTIAL §4.

### 4.1 Hallowmarch · `hallowmarch` · 45–49 · Sanctus · route

> ✅ *"A raised road, and someone built it… Every mile or so there is a marker,
> and every marker has been maintained."*
>
> ⭐ **Theme (ENEMIES §2e): someone is still doing the upkeep, and nobody has
> seen them.** ⚠️ **Load-bearing:** the causeway leads to The Sealed Garden and
> the same oath maintains both. Changing this theme breaks that zone too.

⭐ Spiritwood is ITEMS §9b.6's wood here — *"hallowed ground, hallowed wood"* —
and it is the first wood in the game with **two** sockets. Goldenrood grows in
the meltwater channel that runs beside the road the whole way, which is the one
detail of the arrival text that is about being looked after.

#### Drop table

```
_commonAlways = [ DropEntry('sanctus_dust', chance: 0.75, min: 1, max: 2) ]
```

| Role | main (weights sum 100) | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `spiritwood_log` 55 (1–3) · `sanctus_shard` 7 · `sanctus_dust` 13 (1–2) | `climbers_ration` 2% |
| material-B common ×2 | nothing 30 · `goldenrood` 50 (1–2) · `sanctus_shard` 8 (1–2) · `sanctus_dust` 12 (2–3) | — |
| the Drudge | nothing 40 · `goldenrood` 45 · `climbers_ration` 15 | — |

```
_miniDrops  always: sanctus_shard ×1 · sanctus_dust 2–4 · sanctus_crystal chance 0.25
            main:   spiritwood_log 40 (2–4) · goldenrood 30 (2–4) · climbers_ration 25
                    · votive_pendant 5
_bossDrops  always: sanctus_crystal 1–2 · sanctus_shard 1–2 · sanctus_dust 4–8
            main:   spiritwood_log 45 (4–8) · goldenrood 25 (3–6) · votive_pendant 20
                    · the_maintained_road 10
```

#### Catalogue — 12 defs (`lib/game/items/catalogue/hallowmarch_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `spiritwood_log` | Material | common | Woodcarving t8 | 1 | — | 1500 📝 |
| `goldenrood` | Material | common | Potions t8 | 1 | — | 47 📝 |
| `sanctus_dust` / `sanctus_shard` | Mote | common | dust / shard · sanctus | 1 | — | 2 / 25 ✅ |
| `sanctus_crystal` | Mote | **uncommon** | crystal · sanctus | 1 | — | 150 ✅ |
| `climbers_ration` | **Consumable** ⚠️ not Beltable | common | `heal: 195` | 1 | — | 30 📝 |
| `goldenrood_draught` | **Beltable** | common | `heal: 225` | 1 | — | 140 📝 |
| `spiritwood_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Spiritwood · **twoHanded** · **2 sockets** | 45 | `damagePerCharge: 8, accuracyBonus: 12, critChance: 7, critDamage: 16` | 3900 |
| `spiritwood_wand` | Equipment | common | mainHand · Wand / Spiritwood · **2 sockets** | 45 | `damagePerCast: 9, accuracyBonus: 5, critChance: 8, critDamage: 14` | 3350 |
| `spiritwood_knot` | Equipment | common | offHand · Knot / Spiritwood · **2 sockets** | 45 | `accuracyBonus: 7, critChance: 6` | 2800 |
| `votive_pendant` | Equipment | **rare** | neck · Pendant / Spiritwood · `properName` · untradeable | 47 | `shieldStrengthPercent: 18, healingReceivedPercent: 12` 📝 | 2400 |
| `the_maintained_road` | Equipment | **epic** | neck · Icon / Spiritwood · `properName` · untradeable | 49 | `maxHpBonus: 45, shieldStrengthPercent: 20, healingReceivedPercent: 15` 📝 | 6800 |

⭐ **Sanctus's affinity arrives complete and on the first two items a player
finds here** (§2.5a): shield strength and healing received, the support pair no
element owned alone. ⚠️ **`shieldStrengthPercent` now has three sources across
the game** — Brookstone Pendant 10, The Holdfast 15, and these at 18 and 20.
📝 A player wearing the neck epic *and* a shield-strength spell stance sums on
`effectiveShieldStrengthPercent`; SYSTEMS §2 says gear % and spell % already
share that seam. **Nobody has measured the top of it.**
⚠️ **`votive_pendant` and `the_maintained_road` are the same slot** — a rare→epic
ladder inside one zone, as Starfall Basin has. 📝 Move the rare to `ring` for a
sidegrade instead.
⭐ **Spiritwood is the first two-socket item in the game** (§4.1a of CELESTIAL).

**Lore and icons**

- `spiritwood_log` — *"It grew beside the road, which means someone planted it,
  which means someone expected to come back."*
  **Icon:** a short pale log the length of a forearm, bark silver-white and
  smooth, split at one end to show near-white heartwood with a faint gold
  figure running through it.
- `goldenrood` — *"Yellow, waist-high, and it grows in the channel and nowhere
  else on the mountain. Somebody cut that channel."*
  **Icon:** a cut stem the length of a forearm topped with a dense plume of
  small gold flowers, a few pale leaves along the stalk, laid flat with the
  cut end wet.
- `sanctus_dust` — *"Warm on the palm, and it stays where you put it."*
  **Icon:** a small heap of fine warm-white powder with a faint gold cast,
  matte, one soft highlight.
- `sanctus_shard` — *"Dust that was kept."*
  **Icon:** three flat slivers of translucent warm-white stone, thumbnail-sized,
  fanned, one edge-on.
- `sanctus_crystal` — *"It is looked after, and it does not stop being looked
  after."*
  **Icon:** a clear six-sided crystal a thumb long, colourless at the base
  warming to pale gold at the tip, one clean unlit warm note.
- `climbers_ration` — *"Hard cheese, harder bread, and a strip of something
  salted. Rimeholt sells it by the week and nobody argues about the price."*
  **Icon:** an oilcloth-wrapped bundle the size of two fists tied with cord,
  one fold open to show a wedge of pale hard cheese and a dark dried strip.
- `goldenrood_draught` — *"Gold, faintly sweet, and it works before you have
  finished swallowing. The markers on the road are the same colour."*
  **Icon:** a round-shouldered stoppered bottle the height of a hand full of
  clear gold liquid, a band of pale stamped tin around its neck.
- `spiritwood_quarterstaff` — *"Cut from beside the road and shod at Rimeholt.
  It is lighter than it should be for how hard it hits."*
  **Icon:** a two-handed pale staff as tall as a person, silver-white wood with
  gold figuring, a weighted butt and plain pale-metal ferrules; **two** small
  empty round sockets set in the grip, clearly unfilled.
- `spiritwood_wand` — *"Short, pale, and it does not warm to the hand the way
  wood does."*
  **Icon:** a tapering one-handed pale wand the length of a forearm with a fine
  gold vein down the taper; two empty sockets at the base.
- `spiritwood_knot` — *"A burl off a tree somebody was tending. It is the only
  part they did not straighten."*
  **Icon:** a fist-sized silver-white burl, worn smooth, one flat filed facet,
  **two** empty sockets side by side in the facet.
- `votive_pendant` — *"Left at a marker and taken by nobody for four hundred
  years, which is its own argument."*
  **Icon:** a small flat teardrop of pale spiritwood on a plain cord, standing
  upright, its face carved with a single smooth channel; Rare, so a soft warm
  light sits in the channel and lights the whole pendant from that one line.
- `the_maintained_road` — *"Whoever is doing the upkeep has not been seen, has
  not been thanked, and has not stopped."*
  **Icon:** a broad flat icon of pale wood and pale metal worn at the throat on
  a short cord, its face a smooth unbroken bar like a length of road; Epic, so
  a soft gold light travels slowly along that bar from one end to the other and
  begins again without pause.

📝 **Phase 8 hook.** Hallowmarch is where a **Sanctus enchant** and ITEMS
§3.4's **set Tier III (L45, Mythic)** would both land. Spiritwood's two sockets
are the zone's Phase 8 surface, and the first pair in the game.

---

### 4.2 The Buried Sky · `the_buried_sky` · 46–50 · Geo + Astral ⭐ hybrid · 🏰 dungeon

> ✅ *"You climb to the top of everything in order to go down. The shaft cuts
> through band after band of stone, and every band holds a scatter of light in
> it. None of the patterns match the sky you walked in under."*
>
> ⭐ **Theme (WORLD_DESIGN §4c.1b): the rock remembers a sky that no longer
> exists.** ⭐ ENEMIES §2f blesses the opposition with The Glass Archive:
> *"light that keeps nothing vs stone that keeps everything."*

⭐ **Jewelry's debut zone, and the arithmetic is deliberate.** The Buried Sky
opens at 46, one level after Rimeholt's station, and it is where
`craft_everice_band` and `craft_nacre_pendant` live — the two recipes that
spend the gems banked in Q2 and Q3. ⚠️ **Which means a player's first Jewelry
craft is made of things they picked up thirty levels ago.**

#### Drop table

```
_commonAlways = [ DropEntry('geo_dust',    chance: 0.5, min: 1, max: 2),
                  DropEntry('astral_dust', chance: 0.5, min: 1, max: 2) ]
```
⚠️ **`geo_*` resolve to `old_quarry_items.dart` (Q2) and `astral_*` to
`starfall_basin_items.dart` (Q3).** Nothing is redefined.

| Role | main | bonus |
|---|---|---|
| hide common ×2 | nothing 30 · `corebiter_hide` 40 · `geo_shard` 8 (1–2) · `geo_dust` 17 (2–3) · `climbers_ration` 5 | — |
| material-A common ×2 | nothing 25 · `deepstratum_ore` 55 (1–3) · `astral_shard` 7 · `astral_dust` 13 (1–2) | `climbers_ration` 2% |
| the Siphon | nothing 40 · `nadir_garnet` 45 · `goldenrood_draught` 15 | — |

```
_miniDrops  always: geo_shard ×1 · astral_shard ×1 · geo_dust 2–4 · astral_dust 2–4
                    · geo_crystal chance 0.25 · astral_crystal chance 0.25
            main:   corebiter_hide 35 (2–4) · deepstratum_ore 30 (2–4) · nadir_garnet 30 (1–2)
                    · stonefall_signet 5
_bossDrops  always: the_dark_third ×1  ⭐ GUARANTEED — the gate fragment, §3.4
                    · geo_crystal 1–2 · astral_crystal 1–2 · geo_shard 1–2
                    · astral_shard 1–2 · geo_dust 4–8 · astral_dust 4–8
            main:   corebiter_hide 35 (4–8) · deepstratum_ore 20 (3–6) · nadir_garnet 15 (2–4)
                    · stonefall_signet 20 · bedrock_greaves 10
```

#### Catalogue — 10 defs (`the_buried_sky_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `deepstratum_ore` | Material | common | Metalworking t8 | 1 | — | 120 📝 |
| `nadir_garnet` | Material | **uncommon** | Jewelry t8 ⭐ **spendable — the station is open** | 1 | — | 180 📝 |
| `corebiter_hide` | Material | common | Tailoring t8 · ⚠️ **kill-only, no node** | 1 | — | 700 📝 |
| `deepsteel_ingot` | Material | common | Metalworking t8 output ⭐ feeds 4 recipes | 1 | — | 360 📝 |
| ~~`the_dark_third`~~ | **Key** | — | ⚠️ moved to **The Umbral Wastes** (§3.4 reconciliation) | | | |
| `corebiter_belt` | Equipment | common | belt · Belt / Corebiter | 48 | `beltSlots: 7` ⚠️ capacity only | 1690 |
| `everice_band` ⭐ | Equipment | common | ring · Band / Everice | **45** | `shieldStrengthPercent: 12, maxHpBonus: 15, dodge: 3` | 260 |
| `nacre_pendant` ⭐ | Equipment | common | neck · Pendant / Nacre | 46 | `maxHpBonus: 25, dodge: 6, shieldStrengthPercent: 8` | 680 |
| `stonefall_signet` | Equipment | **rare** | ring · Signet / Nadir Garnet · `properName` · untradeable | 48 | `deflectChance: 18, maxHpBonus: 22, critChance: 6` 📝 | 2700 |
| `bedrock_greaves` | Equipment | **epic** | robeBottom · Greaves / Deepsteel · `properName` · untradeable | 50 | `maxHpBonus: 45, deflectChance: 10, deflectAmount: 10` (EV 1.0%) 📝 | 7600 |

⭐⭐ **`everice_band` is the most load-bearing item in either contract, and it
is a Common ring worth 260 gold.** It is made of `everice` and `quarry_jasper`,
both of which KINETIC §8.1 banked at levels 15–26 with the promise *"gatherable
now, spendable at Rimeholt."* **It is the first Jewelry recipe in the game, its
gate is 1, and it exists to close a promise made two quarters ago.** ⚠️ Its
equip level is **45**, one below this zone's band floor of 46, deliberately: a
player learns Jewelry at Rimeholt and should be able to wear the first thing
they make before they walk anywhere.
⚠️ **`stonefall_signet` carries `deflectChance` with NO `deflectAmount`** — and
that would normally be KINETIC §2.1's inert-stat trap. ⭐ **It is not, and this
is the one place the rule is deliberately bent:** §2.1b's cap means amount is
the scarce resource, so a chance-only piece is *real value to a player who
already has gloves* and dead weight to one who does not. 📝 **That is a
genuinely interesting ring and a genuinely risky precedent.** If it reads as a
bug rather than a build, give it `deflectAmount: 6` and drop `the_corona` to 8.
⭐ **Belt ladder: … Palimpsest 6 → Corebiter 7.**

**Lore and icons**

- `deepstratum_ore` — *"Out of the lowest band the shaft reaches. It is older
  than iron has any business being."*
  **Icon:** a fist-sized block of banded dark rock, near-black with two fine
  paler grey strata running through it, one face freshly broken to show a dull
  blue-grey metallic sheen.
- `nadir_garnet` — *"Cut out of the bottom band. Held up, the flecks in it are
  a constellation and it is not one of ours."*
  **Icon:** a deep red-black faceted stone the size of a thumb resting on one
  face, with a scatter of tiny pale points suspended inside it; Uncommon, so
  the red is one unlit note.
- `corebiter_hide` — *"Off the thing that eats downward. It has never seen
  light and it does not reflect any."*
  **Icon:** a folded hide the size of a lap blanket, matte charcoal-black with
  a fine pebbled grain and a paler grey underside showing at the fold.
- `deepsteel_ingot` — *"Smelted at Vespergate, because nowhere higher has
  fuel."*
  **Icon:** a rectangular ingot the length of a hand, dark blue-grey with a
  faint banded figure across its top face echoing the strata, one bevelled
  corner; matte.
- `the_dark_third` — *"One third of a door, and the rock kept it because the
  rock keeps everything."*
  **Icon:** a wedge-shaped plate of dark banded stone the size of a palm, two of
  its edges cut dead straight and one broken, with a scatter of pale points
  across its face; Rare, so those points are a real cold light and the stone is
  lit by them.
- `corebiter_belt` — *"Seven loops of a hide that takes no dye and needs
  none."*
  **Icon:** a wide charcoal-black hide belt laid in a loose open curve with a
  plain dark-steel buckle and **seven empty loops** stitched along it, each
  wide enough for a bottle and visibly holding nothing.
- `everice_band` — *"Ice that never warmed, set in a band by somebody who
  finally had the tools. It has been in a pack since Frostfell."*
  **Icon:** a plain ring standing upright, a clear colourless ice-like stone set
  flush into a dark band, with one hairline milky vein through the stone; no
  glow — it is Common, an honest working object.
- `nacre_pendant` — *"Shell off the Tidewrack flats, backed in black glass.
  Nobody at Concordance knew what it was for. Rimeholt did."*
  **Icon:** an oval plate of mother-of-pearl the size of a thumb set in a dark
  obsidian backing on a fine chain, its soft pink-green iridescence unlit.
- `stonefall_signet` — *"The face is blank. Whatever it sealed, the seal is what
  mattered."*
  **Icon:** a heavy dark ring with a broad flat garnet face, standing upright,
  the face entirely uncut and polished flat; Rare, so a single hard red point
  of light sits at the face's edge and throws the rest into relief.
- `bedrock_greaves` — *"Plated in the stuff that was under everything. They are
  not comfortable and they have never once given."*
  **Icon:** a pair of dark blue-grey plated greaves standing upright, layered in
  overlapping banded plates like strata; Epic, so a slow cool grey-white pulse
  travels up through the plates from the ankle and stops at the knee, over and
  over.

📝 **Phase 8 hook.** The **Geo or Astral enchant**, and — ⭐ the strongest
socket argument in the game — the Buried Sky is full of set stones nobody has
cut. When ITEMS §6d ships, this zone's mini pool is the natural **Lesser gem**
drop in the Ethereal band.

---

### 4.3 The Umbral Wastes · `the_umbral_wastes` · 47–51 · Umbra · route

> ✅ *"You round the shoulder and the light stops. Not dusk — an absence with an
> edge to it. The ice here has never melted and holds its shape like something
> that has been thought about."*
>
> ⭐ **Theme (ENEMIES §2e): the dark here is deliberate. Something decided its
> shape.** Not absence — **design**.

⚠️ **The deliberate rhyme with the Old Quarry (15–19) is not duplication and
must not be "fixed"** — ENEMIES §2f already logged it: there something was
**removed** and the hole is animate; here dark was **imposed** and given a
shape. 📝 §2f's note *"worth not making it a third time"* still stands.

#### Drop table

```
_commonAlways = [ DropEntry('umbra_dust', chance: 0.75, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `umbralweave` 55 (1–3) · `umbra_shard` 7 · `umbra_dust` 13 (1–2) | `climbers_ration` 2% |
| material-B common ×2 | nothing 30 · `thoughtglass` 50 (1–2) · `umbra_shard` 8 (1–2) · `umbra_dust` 12 (2–3) | — |
| the Siphon | nothing 40 · `umbralweave` 45 · `goldenrood_draught` 15 | — |

```
_miniDrops  always: umbra_shard ×1 · umbra_dust 2–4 · umbra_crystal chance 0.25
            main:   umbralweave 40 (2–4) · thoughtglass 30 (2–4) · climbers_ration 25
                    · the_considered_ring 5
_bossDrops  always: umbra_crystal 1–2 · umbra_shard 1–2 · umbra_dust 4–8
            main:   umbralweave 45 (4–8) · thoughtglass 25 (3–6) · the_considered_ring 20
                    · the_deliberate_dark 10
```

#### Catalogue — 12 defs (`the_umbral_wastes_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `umbralweave` | Material | common | Tailoring t8 | 1 | — | 290 📝 |
| `thoughtglass` | Material | **uncommon** | Jewelry t8 | 1 | — | 200 📝 |
| `umbra_dust` / `umbra_shard` | Mote | common | dust / shard · umbra | 1 | — | 2 / 25 ✅ |
| `umbra_crystal` | Mote | **uncommon** | crystal · umbra | 1 | — | 150 ✅ |
| `umbralweave_hood` | Equipment | common | hat · Hood / Umbralweave | 48 | `accuracyBonus: 6` | 870 |
| `umbralweave_robe` | Equipment | common | robeTop · Robe / Umbralweave | 48 | `maxHpBonus: 42` | 1740 |
| `umbralweave_leggings` | Equipment | common | robeBottom · Leggings / Umbralweave | 48 | `maxHpBonus: 29` | 1450 |
| `umbralweave_boots` | Equipment | common | boots · Boots / Umbralweave | 48 | `maxHpBonus: 8, dodge: 6` | 870 |
| `umbralweave_gloves` | Equipment | common | gloves · Gloves / Umbralweave | 48 | `maxHpBonus: 9, deflectChance: 16, deflectAmount: 22` (EV 3.5%) | 870 |
| `the_considered_ring` | Equipment | **rare** | ring · Ring / Thoughtglass · `properName` · untradeable | 49 | `critChance: 8, critDamage: 34` 📝 | 3100 |
| `the_deliberate_dark` | Equipment | **epic** | ring · Ring / Thoughtglass · `properName` · untradeable | 51 | `critChance: 6, critDamage: 28, maxHpBonus: 20` 📝 | 8800 |

⭐ **Umbralweave set total: 88 HP · 6 acc · 6 dodge · 16/22 deflect.** Against
the level-48 baseline (632 HP) that is **+13.9% health** — the flat-modifier
decay KINETIC §2.6 note 3 predicted, still running, still inside the ±2% band
the other three sets hold.
⭐ **Both drops are Umbra and both are crit damage (§2.5a), and they are
deliberately NOT a ladder.** `the_considered_ring` is 8/+34 and
`the_deliberate_dark` is 6/+28 with 20 HP — ⚠️ **the epic has strictly lower
crit than the rare.** ✅ That is ITEMS §4.1a's *"low-chance/high-crit-damage
glass cannon vs high-accuracy consistent"* axis with both ends finally
built: the rare is the gamble, the epic is the version you can survive wearing.
📝 **This is the most likely row in either contract to read as a bug.** It is
not; it is the one place the rarity ladder buys *safety* rather than power, and
ITEMS §9b.6a's lattice permits it because an Epic's advantage is
*capability* first.
⚠️ **They are both rings and cannot be worn together**, which is what makes the
choice a choice.

**Lore and icons**

- `umbralweave` — *"It comes off the ice in sheets, and it is not ice. Pull it
  in the dark or it comes apart in your hands."*
  **Icon:** a folded length of near-black cloth the size of a forearm, matte and
  swallowing light, its edges fraying into fine dark threads with one faint
  cold blue sheen along a single fold.
- `thoughtglass` — *"Ice that has held one shape for longer than ice can. Cut
  it and the new face is the same shape."*
  **Icon:** a faceted block of near-black translucent glass the size of a thumb,
  its facets unnaturally regular, with a faint indigo depth at the centre;
  Uncommon, so the indigo is one unlit note.
- `umbra_dust` — *"It does not settle so much as decide where to be."*
  **Icon:** a small heap of matte black powder that reads as a *shape* rather
  than a pile, with one cold edge highlight.
- `umbra_shard` — *"Dust with an opinion."*
  **Icon:** three angular slivers of near-black translucent stone, thumbnail-
  sized, fanned; one catches a cold blue edge.
- `umbra_crystal` — *"It is decided, and it does not stop being decided."*
  **Icon:** a clear six-sided crystal a thumb long, colourless at the base
  darkening to near-black at the tip, one unlit cold indigo note.
- `umbralweave_hood` — *"The brim is straight because a straight brim is a line
  you can aim along in no light at all."*
  **Icon:** a near-black hood laid flat, brim stiffened into a dead-level
  horizontal edge, doubled seams visible at the shoulders.
- `umbralweave_robe` — *"Six layers of a cloth that gives nothing back. It is
  the warmest thing on the north face."*
  **Icon:** a long near-black robe on an invisible form, thick and visibly
  layered with doubled seams, the weave legible only where the light catches
  an edge.
- `umbralweave_leggings` — *"Quilted through. Nothing on this face has melted in
  living memory and neither will you."*
  **Icon:** near-black quilted leggings laid flat, the quilting channels
  catching a faint cold rim light.
- `umbralweave_boots` — *"Soft, black, and the sole is cut so it does not print
  in the ice."*
  **Icon:** a pair of tall matte-black boots with thick soft soles, one lifted
  as though mid-step and casting almost no contact shadow.
- `umbralweave_gloves` — *"Palms tripled. Out here the thing you put in the way
  is your hand and then it is your whole arm."*
  **Icon:** near-black gloves, palms outward, panels visibly tripled; a cool
  grey-white line traces each palm.
- `the_considered_ring` — *"It was made to fit one finger and it fits every
  finger. Somebody thought about that."*
  **Icon:** a plain black band standing upright, its inner and outer surfaces
  both perfectly smooth and its proportions faintly, unsettlingly exact; Rare,
  so a single hot violet point sits on the band and lights the whole ring from
  that one place.
- `the_deliberate_dark` — *"Not an absence. A decision, worn on the hand of
  whoever agrees with it."*
  **Icon:** a heavy black ring with a deep faceted thoughtglass stone; Epic, so
  the stone is emissive and *working* — a slow violet glow gathering at its
  centre, reaching the facets, and going out, again and again.

📝 **Phase 8 hook.** The **Umbra enchant** — ⚠️ and the Voidcaller archetype's
natural home (SYSTEMS §3.2 is still choosing its three bonuses). Umbralweave is
the obvious Tier III set base.

---

### 4.4 The Sealed Garden · `the_sealed_garden` · 49–53 · Flora + Sanctus ⭐ hybrid · route

> ✅ *"The wall is low enough to see over and that is the whole cruelty of it.
> Inside, everything is in leaf and in season at once. The gate is shut, the
> guard is still at the gate, and the faith that posted him has been gone for
> centuries."*
>
> ⭐ **Theme (WORLD_DESIGN §4c.1a): still perfect, still guarded, still not
> allowed in.** ⭐⭐ **The game's FIRST element guarded by its LAST** — Flora is
> where the player started; Sanctus is where they are now.

⭐ **This zone is the proof of the §2.5a affinity structure.** Flora's lean is
healing and Sanctus's is healing plus shields, and both drops here carry
healing. If the structure is wrong, this is the zone that has to be rewritten;
if it is right, this is the zone that says so.
⚠️ **A dead-end off Hallowmarch, and it holds a gate fragment** (§3.4). It is
optional geography carrying mandatory progress, on purpose.

#### Drop table

```
_commonAlways = [ DropEntry('flora_dust',   chance: 0.5, min: 1, max: 2),
                  DropEntry('sanctus_dust', chance: 0.5, min: 1, max: 2) ]
```
⭐⭐ **`flora_*` resolve to `whispering_woods_items.dart` — the level 1–5
catalogue.** ⚠️ A builder will assume that is a mistake. It is not.

| Role | main | bonus |
|---|---|---|
| hide common ×2 | nothing 30 · `thornpenitent_hide` 40 · `flora_shard` 8 (1–2) · `flora_dust` 17 (2–3) · `climbers_ration` 5 | — |
| material-A common ×2 | nothing 25 · `worldroot` 55 (1–3) · `sanctus_shard` 7 · `sanctus_dust` 13 (1–2) | `climbers_ration` 2% |
| the Siphon | nothing 40 · `orchard_amber` 45 · `worldroot_tonic` 15 | — |

```
_miniDrops  always: flora_shard ×1 · sanctus_shard ×1 · flora_dust 2–4 · sanctus_dust 2–4
                    · flora_crystal chance 0.25 · sanctus_crystal chance 0.25
            main:   thornpenitent_hide 35 (2–4) · worldroot 30 (2–4) · orchard_amber 30 (1–2)
                    · the_gardeners_loop 5
_bossDrops  always: the_kept_third ×1  ⭐ GUARANTEED — the gate fragment, §3.4
                    · flora_crystal 1–2 · sanctus_crystal 1–2 · flora_shard 1–2
                    · sanctus_shard 1–2 · flora_dust 4–8 · sanctus_dust 4–8
            main:   thornpenitent_hide 35 (4–8) · worldroot 20 (3–6) · orchard_amber 15 (2–4)
                    · the_gardeners_loop 20 · the_season_at_once 10
```

#### Catalogue — 10 defs (`the_sealed_garden_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `worldroot` | Material | common | Potions t9 | 1 | — | 55 📝 |
| `orchard_amber` | Material | **uncommon** | Jewelry t9 | 1 | — | 260 📝 |
| `thornpenitent_hide` | Material | common | Tailoring t9 · ⚠️ **kill-only, no node** | 1 | — | 950 📝 |
| `worldroot_tonic` | **Beltable** | common | `healPerTurn: 53, healTurns: 3` | 1 | — | 165 📝 |
| ~~`the_kept_third`~~ | **Key** | — | ⚠️ moved to **Hallowmarch** (§3.4 reconciliation) | | | |
| `penitent_belt` | Equipment | common | belt · Belt / Thornpenitent | 52 | `beltSlots: 8` ⚠️ capacity only | 2190 |
| `eclipse_signet` ⭐ | Equipment | common | ring · Signet / Eclipse Opal | 50 | `accuracyBonus: 3, dodge: 3, critChance: 6, critDamage: 10` | 1100 |
| `orchard_loop` ⭐ | Equipment | common | ring · Loop / Orchard Amber | 54 | `maxHpBonus: 25, healingReceivedPercent: 15, regrowPercent: 1` | 1750 |
| `the_gardeners_loop` | Equipment | **rare** | ring · Loop / Orchard Amber · `properName` · untradeable | 51 | `healingReceivedPercent: 18, regrowPercent: 2, maxHpBonus: 25` 📝 | 3800 |
| `the_season_at_once` | Equipment | **epic** | robeTop · Vestment / Worldroot · `properName` · untradeable | 53 | `maxHpBonus: 60, regrowPercent: 3, healingReceivedPercent: 15` 📝 | 10500 |

⭐ **`regrowPercent` has exactly two sources in the shipped game — The Charlock
at 2 — and this zone doubles the count.** ⚠️ ITEMS §4.2 flags it as needing to
route through `TurnStatus`; SYSTEMS §2 says the seam exists. **`regrowPercent:
3` on a 1,264 HP bar is 38 HP a turn, every turn, forever** — 📝 that is the
single most tunable number in either contract, and it is the one a long duel
will find first.
⭐ **`orchard_loop` is the game's best craftable ring for a support build** and
`the_gardeners_loop` is the rare version of the same idea — ⚠️ **both are rings
and both are Loops**, so a player chooses between +15%/1% with 25 HP and
+18%/2% with 25 HP. That is a 3-point and 1-point step for a whole rarity tier,
which is ITEMS §9b.6a's *"Rare ≈ Master, Epic marginally stronger"* read
literally. 📝 If a rare should feel bigger than that, widen it.
⭐ **Belt ladder: … Corebiter 7 → Penitent 8.**

**Lore and icons**

- `worldroot` — *"Dug from under the wall, on the outside. Whatever is in there
  has been sending something out this whole time."*
  **Icon:** a thick pale root the length of a forearm, knuckled and forked, with
  fine gold hair-roots along it and a clean pale cut at one end still beaded
  with sap.
- `orchard_amber` — *"Sap off a tree nobody has pruned in four hundred years,
  and it is still the right shape."*
  **Icon:** a smooth lump of warm gold amber the size of a thumb with a single
  small green leaf suspended whole inside it; Uncommon, so the gold is one
  clean unlit note.
- `thornpenitent_hide` — *"Off something that was let in and did not leave. The
  thorns grew through it rather than into it."*
  **Icon:** a folded hide the size of a lap blanket, pale grey-green, with fine
  dark thorns emerging through its surface from the inside at regular
  intervals.
- `worldroot_tonic` — *"Earthy, sweet at the back, and it keeps working. Three
  mouthfuls in one bottle and the bottle knows the order."*
  **Icon:** a round-bellied stoppered bottle the height of a hand holding a
  thick green-gold liquid in three faintly visible settled layers, a length of
  pale root tied to its neck.
- `the_kept_third` — *"The vow was kept. Nobody was released from it and nobody
  was thanked for it, and here is a third of the proof."*
  **Icon:** a wedge-shaped plate of pale gold-veined wood the size of a palm,
  two edges cut dead straight and one broken, a single small green shoot
  growing from the broken edge; Rare, so a soft warm light comes from the joint
  where the shoot meets the wood.
- `penitent_belt` — *"Eight loops. The thorns are on the inside, which whoever
  made it will have meant."*
  **Icon:** a wide pale grey-green hide belt laid in a loose open curve with a
  dark thorn-wood buckle and **eight empty loops** stitched along it, with fine
  dark thorn points just visible along the inner face.
- `eclipse_signet` — *"Sunless Reach opal, cut at Rimeholt into the only shape
  that keeps the line."*
  **Icon:** a broad flat-faced ring standing upright, its face a single eclipse
  opal cut so the light and dark halves meet exactly at the centre line of the
  face; Common, so nothing is emissive — the stone's own halves do the work.
- `orchard_loop` — *"Garden amber in a plain band. It is warm, and it does not
  stop being warm."*
  **Icon:** a plain pale-gold band standing upright with a round amber cabochon
  set flush, the leaf inside it clearly visible; no glow.
- `the_gardeners_loop` — *"Whoever was last in there took nothing and left
  this on the gatepost."*
  **Icon:** a worn gold band with a large amber stone, standing upright, a fine
  green tendril grown around the band and into the setting; Rare, so a soft
  warm light comes from inside the amber and lights the tendril.
- `the_season_at_once` — *"Inside, everything is in leaf and in season at once.
  Somebody wove that."*
  **Icon:** a long vestment on an invisible form, its cloth carrying bud, leaf,
  blossom and fruit at the same time in embroidered bands down its length;
  Epic, so it is visibly *turning* — one band budding as the band beside it
  drops its fruit, endlessly, never settling on a season.

📝 **Phase 8 hook.** A **Flora** or **Sanctus enchant**, and — ⭐ the
Thornwarden archetype's natural home (SYSTEMS §3, ITEMS §3.1: attrition,
*"your DoTs last +1 turn"*). The zone already carries the only regrow stats in
the game.

---

### 4.5 The Collapsed Academy · `the_collapsed_academy` · 50–54 · Arcane · 🏰 dungeon · Empyrean

> ✅ *"It is not ruined so much as unfinished in the wrong direction.
> Staircases arrive at rooms that were never built. The syllabus is still on the
> wall and the last three items on it are not in any language you have."*
>
> ⭐ **Theme (ENEMIES §2e): it was not destroyed — it was continued past the
> point where building makes sense.** ⚠️ **Over-completion, not ruin**, and that
> distinction is the whole zone.

⭐ **Aetherwood is ITEMS §9b.6's wood here** — *"aether is arcane; the Academy
is the Arcane zone"* — and it is the only wood in the game that is not a tree.
⚠️ `world.dart` says the Ethereal band is *"above the tree line"* and the
Academy is beyond the Veil entirely. **Aetherwood is the timber of the
staircases that arrive at rooms nobody built**: it was cut to a plan that kept
going, and there is more of it than there was ever material for.

#### Drop table

```
_commonAlways = [ DropEntry('arcane_dust', chance: 0.75, min: 1, max: 2) ]
```
⚠️ **`arcane_*` resolve to `the_glass_archive_items.dart` (Q3).** ⭐ **This is
the only pure zone in the game that defines no mote family** — the Archive got
there seven levels earlier (§3.2). A builder will look for the definition here
and must not add one.

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `aetherwood_log` 55 (1–3) · `arcane_shard` 7 · `arcane_dust` 13 (1–2) | `climbers_ration` 2% |
| material-B common ×2 | nothing 30 · `mana_slag` 50 (1–2) · `arcane_shard` 8 (1–2) · `arcane_dust` 12 (2–3) | — |
| the Drudge | nothing 40 · `mana_slag` 45 · `climbers_ration` 15 | — |

```
_miniDrops  always: arcane_shard ×1 · arcane_dust 2–4 · arcane_crystal chance 0.25
            main:   aetherwood_log 40 (2–4) · mana_slag 30 (2–4) · climbers_ration 25
                    · chalkline_signet 5
_bossDrops  always: arcane_crystal 1–2 · arcane_shard 1–2 · arcane_dust 4–8
            main:   aetherwood_log 45 (4–8) · mana_slag 25 (3–6) · chalkline_signet 20
                    · the_unbuilt_stair 10
```

#### Catalogue — 8 defs (`the_collapsed_academy_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `aetherwood_log` | Material | common | Woodcarving t9 | 1 | — | 2780 📝 |
| `mana_slag` | Material | common | Metalworking t9 | 1 | — | 215 📝 |
| `aethersteel_ingot` | Material | common | Metalworking t9 output ⭐ feeds 4 recipes | 1 | — | 640 📝 |
| `aetherwood_quarterstaff` | Equipment | common | mainHand · Quarterstaff / Aetherwood · **twoHanded** · **3 sockets** | 50 | `damagePerCharge: 9, accuracyBonus: 12, critChance: 8, critDamage: 18` | 7200 |
| `aetherwood_wand` | Equipment | common | mainHand · Wand / Aetherwood · **3 sockets** | 50 | `damagePerCast: 10, accuracyBonus: 5, critChance: 9, critDamage: 16` | 6200 |
| `aetherwood_knot` | Equipment | common | offHand · Knot / Aetherwood · **3 sockets** | 50 | `accuracyBonus: 7, critChance: 7` | 5200 |
| `chalkline_signet` | Equipment | **rare** | ring · Signet / Aethersteel · `properName` · untradeable | 52 | `deflectChance: 18, deflectAmount: 8, critChance: 8` (EV 1.4%) 📝 | 4400 |
| `the_unbuilt_stair` | Equipment | **epic** | mainHand · Quarterstaff / Aetherwood · `properName` · untradeable · **twoHanded** · **3 sockets** | 54 | `damagePerCharge: 10, accuracyBonus: 13, critChance: 8, critDamage: 16` 📝 | 12000 |

⭐ **The end of the Woodcarving ladder, nine tiers after Oak.** Aetherwood is
the last wood ITEMS §9b.6 names, it carries the full 3 sockets its range
allows, and `the_unbuilt_stair` is the best main hand in the game.
⚠️ **`chalkline_signet`'s `deflectAmount: 8` looks tiny and is deliberate.**
§2.1b's cap means amount is the scarce resource and this ring is a
**chance-heavy** piece meant to be worn *with* the Unleft gloves, not instead of
them: gloves 26 + signet 8 = 34, leaving room for a hat. 📝 If it reads as a
weak modifier — ITEMS §9b.6a warns that *"weak Rare modifiers are a balance
bug, not flavour"* — swap the 8 for `critDamage: 20` and drop the deflection
entirely.
⚠️ **`the_unbuilt_stair` is only marginally better than the crafted Aetherwood
staff** (+1 dpc, +1 acc, −2 critDamage) and that is the sharpest form of §2.6
finding 2: at the top of the ladder a Master crafted Common is very nearly the
Epic. ⭐ **The Epic's real advantage is that it is the only main hand a player
can get without Woodcarving 50**, which is exactly what ITEMS §9b.6a means by
*"rarity buys capability, and only secondarily power."* 📝 Widen the gap if
that reads thin.

**Lore and icons**

- `aetherwood_log` — *"Cut for a staircase that arrives somewhere nobody built.
  There is more of it than there was ever material for."*
  **Icon:** a short squared beam the length of a forearm rather than a round
  log, pale grey-violet, its four sides planed dead flat and its end grain
  showing rings that do not quite close.
- `mana_slag` — *"What ran out of the floor when the school stopped. It is
  still warm at the centre of the heap."*
  **Icon:** a fist-sized lump of frozen glassy slag, dull grey-violet, bubbled
  and porous on top and flowed smooth underneath where it pooled.
- `aethersteel_ingot` — *"Smelted out of the spill. It rings for about four
  seconds longer than it should."*
  **Icon:** a rectangular ingot the length of a hand, pale grey with a violet
  sheen across its top face and one bevelled corner; matte.
- `aetherwood_quarterstaff` — *"The last wood. There is nothing after this and
  the carvers know it."*
  **Icon:** a two-handed staff as tall as a person, pale grey-violet, the shaft
  squared rather than round for its middle third, with pale metal ferrules and
  a weighted butt; **three** empty round sockets in a row along the grip.
- `aetherwood_wand` — *"Short, squared, and it does not taper so much as
  stop."*
  **Icon:** a one-handed pale grey-violet wand the length of a forearm, squared
  in section, ending in a flat cut rather than a point; three empty sockets
  along its base.
- `aetherwood_knot` — *"There should not be a burl in wood that was never a
  tree. There is."*
  **Icon:** a fist-sized pale grey-violet burl, its whorls unnaturally regular,
  one flat filed facet holding **three** empty sockets.
- `chalkline_signet` — *"The syllabus is still on the wall. This is the seal
  that approved it."*
  **Icon:** a heavy pale-grey ring with a broad flat face, standing upright, its
  face incised with three short parallel lines and a fourth that is only
  half-cut; Rare, so a cold violet light sits in the unfinished line and lights
  the three finished ones.
- `the_unbuilt_stair` — *"It arrives. What it arrives at was never built, and
  it arrives there anyway."*
  **Icon:** a two-handed pale grey-violet staff whose upper third steps upward
  in three squared offsets like a flight of stairs; Epic, so a band of cold
  violet light climbs those steps one at a time and, at the top step, simply
  keeps going into nothing before starting again at the bottom.

📝 **Phase 8 hook.** The **Arcane enchant** — ⚠️ ITEMS §2.2's watch item,
*"Arcane is the standout candidate"* for an over-strong enchant; read that
paragraph before writing this one. And ITEMS §3.4's **set Tier IV (L50,
Legendary)**: three Aetherwood sockets are the most Phase 8 surface any zone
in the game offers.

---

### 4.6 The Reliquary Deep · `the_reliquary_deep` · 52–56 · Sanctus + Umbra ⭐ hybrid · 🏰 dungeon

> ✅ *"The way in is a hole in the ice on the north face… A corridor that someone
> consecrated and someone else did not leave alone. It gets warmer the further
> you go, and the far door has been shut for longer than the order that shut it
> lasted."*
>
> ⭐ **Theme (ENEMIES §2e): two hands worked on this, and the second has not
> finished.** ⭐ **The warmth in the middle is the tell** — the corridor is not
> empty.

⚠️ **Entered from the ice, and only from the ice** (ruling, Christian
2026-09-21). It is a dead end off The Umbral Wastes, at the top of the climb
rather than partway up it, and it holds a gate fragment (§3.4).
⭐ **The only hybrid in either quarter whose three materials are all gatherable
and none is a hide** — a corridor someone made, in a mountain, with no animals
in it.

#### Drop table

```
_commonAlways = [ DropEntry('sanctus_dust', chance: 0.5, min: 1, max: 2),
                  DropEntry('umbra_dust',   chance: 0.5, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| material-A common ×2 | nothing 25 · `unleft_linen` 55 (1–3) · `sanctus_shard` 7 · `sanctus_dust` 13 (1–2) | `climbers_ration` 2% |
| material-B common ×2 | nothing 30 · `censer_resin` 50 (1–2) · `umbra_shard` 8 (1–2) · `umbra_dust` 12 (2–3) | — |
| the Siphon | nothing 40 · `reliquary_gold` 45 · `censer_draught` 15 | — |

```
_miniDrops  always: sanctus_shard ×1 · umbra_shard ×1 · sanctus_dust 2–4 · umbra_dust 2–4
                    · sanctus_crystal chance 0.25 · umbra_crystal chance 0.25
            main:   unleft_linen 35 (2–4) · censer_resin 30 (2–4) · reliquary_gold 30 (1–2)
                    · censer_pendant 5
_bossDrops  always: the_written_third ×1  ⭐ GUARANTEED — the gate fragment, §3.4
                    · sanctus_crystal 1–2 · umbra_crystal 1–2 · sanctus_shard 1–2
                    · umbra_shard 1–2 · sanctus_dust 4–8 · umbra_dust 4–8
            main:   unleft_linen 35 (4–8) · censer_resin 20 (3–6) · reliquary_gold 15 (2–4)
                    · censer_pendant 20 · the_unconsecrated 10
```

#### Catalogue — 13 defs (`the_reliquary_deep_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `censer_resin` | Material | common | Potions t9 | 1 | — | 53 📝 |
| `reliquary_gold` | Material | **uncommon** | Jewelry t9 | 1 | — | 340 📝 |
| `unleft_linen` | Material | common | Tailoring t9 | 1 | — | 520 📝 |
| `censer_draught` | **Beltable** | common | `heal: 295` | 1 | — | 210 📝 |
| ~~`the_written_third`~~ | **Key** | — | ⚠️ moved to **The Collapsed Academy** (§3.4 reconciliation) | | | |
| `unleft_hood` | Equipment | common | hat · Hood / Unleft Linen | 53 | `accuracyBonus: 6` | 1560 |
| `unleft_robe` | Equipment | common | robeTop · Robe / Unleft Linen | 53 | `maxHpBonus: 55` | 3120 |
| `unleft_leggings` | Equipment | common | robeBottom · Leggings / Unleft Linen | 53 | `maxHpBonus: 38` | 2600 |
| `unleft_boots` | Equipment | common | boots · Boots / Unleft Linen | 53 | `maxHpBonus: 10, dodge: 7` | 1560 |
| `unleft_gloves` | Equipment | common | gloves · Gloves / Unleft Linen | 53 | `maxHpBonus: 12, deflectChance: 18, deflectAmount: 26` (EV 4.7%) | 1560 |
| `aetherglass_locket` ⭐ | Equipment | common | neck · Locket / Aetherglass | 53 | `maxHpBonus: 45, shieldStrengthPercent: 12, healingReceivedPercent: 10` | 1300 |
| `censer_pendant` | Equipment | **rare** | neck · Pendant / Reliquary Gold · `properName` · untradeable | 54 | `healingReceivedPercent: 15, shieldStrengthPercent: 15, critDamage: 20` 📝 | 5200 |
| `the_unconsecrated` | Equipment | **epic** | boots · Tread / Reliquary Gold · `properName` · untradeable | 56 | `maxHpBonus: 32, dodge: 6, healingReceivedPercent: 10` 📝 | 14500 |

⭐ **Unleft Linen set total: 115 HP · 6 acc · 7 dodge · 18/26 deflect.** Against
the level-53 baseline (769 HP) that is **+15.0% health** — the same proportion
Seawrack held at level 16, thirty-seven levels and four material tiers later.
⭐ **It is the last armour set in the game**, and `unleft_gloves`'
`deflectAmount: 26` is the largest single deflect amount a player can wear —
§2.1b's whole budget is built around it.
⭐ **`censer_pendant` is the zone in one item:** Sanctus's healing and shields
from the hand that consecrated it, Umbra's crit damage from the hand that did
not leave it alone. ⚠️ **It is the only piece in either contract that carries
both halves of a hybrid's affinities and a third stat** — 📝 if that is one too
many, cut the `critDamage: 20`.
⚠️ **`aetherglass_locket` is crafted, Common, and spends the last Celestial
banked gem** (`aetherglass`, from The Glass Archive). ⭐ It deliberately carries
**no deflection**, although Arcane's affinity is deflection, because §2.1b's
cap has no room left for a fourth slot.

**Lore and icons**

- `censer_resin` — *"Scraped out of the censers along the warm stretch. They
  have not been lit in four hundred years and the resin is not cold."*
  **Icon:** a broken lump of translucent red-gold resin the size of a thumb,
  glossy where it fractured and dull grey with old smoke where it did not.
- `reliquary_gold` — *"Off the fittings. Soft, pure, and somebody had a great
  deal of it to spare on a corridor."*
  **Icon:** a small twisted length of soft yellow gold the size of a finger,
  clearly prised off a fitting, with a stamped pattern still legible along one
  flattened side; Uncommon, so the gold is one unlit note.
- `unleft_linen` — *"Altar cloth. Still folded, still square, still on the
  altar. Nobody took it and nobody came back for it."*
  **Icon:** a folded square of heavy cream linen the size of two hands, its
  creases sharp from long folding, one edge worked with a plain dark band.
- `censer_draught` — *"Red-gold, resinous, and it goes down warm. It is the only
  thing anyone has ever taken out of here that helped."*
  **Icon:** a squat round-shouldered bottle the height of a hand holding a thick
  red-gold liquid, a band of soft stamped gold around its neck and a wax seal
  over the stopper.
- `the_written_third` — *"It is warmer in the middle than at either end, and this
  is the middle."*
  **Icon:** a wedge-shaped plate of pale stone banded with gold the size of a
  palm, two edges cut dead straight and one broken; Rare, so a warm light comes
  from the *centre* of the plate rather than an edge, and fades outward.
- `unleft_hood` — *"Cut from altar cloth by somebody who needed a hood more than
  they needed the argument."*
  **Icon:** a heavy cream hood laid flat, brim stiffened dead straight, a plain
  dark band worked along the edge, doubled seams at the shoulders.
- `unleft_robe` — *"Six layers of a cloth that was folded and left. It has
  never once been worn out of doors before now."*
  **Icon:** a long heavy cream robe on an invisible form, thick and visibly
  layered, doubled seams down both sides, a dark band at the hem.
- `unleft_leggings` — *"Quilted through with the same cloth. It is warm, and
  nobody is coming to ask for it back."*
  **Icon:** cream quilted leggings laid flat, the quilting channels running in
  visible parallel lines with a dark band at each ankle.
- `unleft_boots` — *"Soft-soled, because the corridor is stone and the stone
  carries."*
  **Icon:** a pair of tall cream boots with thick soft soles and dark banding,
  one lifted as though mid-step and barely touching its shadow.
- `unleft_gloves` — *"Palms quadrupled. Whatever the second hand was doing down
  here, it did it with its hands."*
  **Icon:** heavy cream gloves, palms outward, the palm panels visibly built up
  in four layers; a cool grey-white line traces each palm.
- `aetherglass_locket` — *"Archive glass, carried up the mountain, and finally
  set by somebody who could."*
  **Icon:** a flat rectangular locket of pale archive glass in a soft gold
  bezel on a fine chain, standing upright, a faint suggestion of writing in the
  glass; Common, so nothing is emissive.
- `censer_pendant` — *"Two hands made it. You can see where they disagreed."*
  **Icon:** a small gold censer worn as a pendant on a short chain, one half of
  its pierced body bright and finely worked and the other half blackened and
  crudely reworked; Rare, so a warm light comes from inside the bright half and
  throws the reworked half into shadow.
- `the_unconsecrated` — *"Somebody walked the whole corridor in these and was
  not permitted, and walked it anyway."*
  **Icon:** a pair of tall boots of gold-banded dark leather, soles worn
  through at the ball of the foot, standing on bare stone; Epic, so a warm gold
  light runs up the banding from the sole and *stops* at the ankle every time,
  never reaching the top.

📝 **Phase 8 hook.** A **Sanctus** or **Umbra enchant**, and the Aegis
Sovereign archetype's home (SYSTEMS §2: *"gear % and spell % already sum on one
seam"* — this zone has the game's two largest shield-strength pieces).

---

### 4.7 The Unwritten Library · `the_unwritten_library` · 54–58 · Umbra + Arcane ⭐ hybrid · 🏰 dungeon · Empyrean

> ✅ *"Every book here is being written right now, by nobody. The shelves go up
> past where a ceiling would be. Something is taking dictation and it would like
> your name for the record."*
>
> ⭐ **Theme (ENEMIES §2e): it is still writing, and it wants you in it.** The
> fusion is **authorship with no author** — Arcane supplies the writing, Umbra
> supplies the nobody.

⚠️ **ENEMIES §2e gives this zone a third boss, *Your Entry*, available only on
a repeat clear** — gated on `PlayerProfile.hasCleared('the_unwritten_library')`,
and ❓ it has no archetype and no ruling. ⭐ **Nothing in this catalogue depends
on it.** 📝 **If it ships, it wants a drop of its own** — the obvious one is a
second, personalised epic, and the obvious name is already taken by the
encounter.

#### Drop table

```
_commonAlways = [ DropEntry('umbra_dust',  chance: 0.5, min: 1, max: 2),
                  DropEntry('arcane_dust', chance: 0.5, min: 1, max: 2) ]
```

| Role | main | bonus |
|---|---|---|
| hide common ×2 | nothing 30 · `blankspine_vellum` 40 · `arcane_shard` 8 (1–2) · `arcane_dust` 17 (2–3) · `nightink_draught` 5 | — |
| material-A common ×2 | nothing 25 · `nightink` 55 (1–3) · `umbra_shard` 7 · `umbra_dust` 13 (1–2) | `climbers_ration` 2% |
| the Siphon | nothing 40 · `colophon_stone` 45 · `censer_draught` 15 | — |

```
_miniDrops  always: umbra_shard ×1 · arcane_shard ×1 · umbra_dust 2–4 · arcane_dust 2–4
                    · umbra_crystal chance 0.25 · arcane_crystal chance 0.25
            main:   blankspine_vellum 35 (2–4) · nightink 30 (2–4) · colophon_stone 30 (1–2)
                    · colophon_signet 5
_bossDrops  always: umbra_crystal 1–2 · arcane_crystal 1–2 · umbra_shard 1–2
                    · arcane_shard 1–2 · umbra_dust 4–8 · arcane_dust 4–8
            main:   blankspine_vellum 35 (4–8) · nightink 20 (3–6) · colophon_stone 15 (2–4)
                    · colophon_signet 20 · the_open_colophon 10
```

#### Catalogue — 7 defs (`the_unwritten_library_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `nightink` | Material | common | Potions t10 | 1 | — | 63 📝 |
| `colophon_stone` | Material | **uncommon** | Jewelry t10 | 1 | — | 480 📝 |
| `blankspine_vellum` | Material | common | Tailoring t10 · ⚠️ **kill-only, no node** | 1 | — | 1400 📝 |
| `nightink_draught` | **Beltable** | common | `heal: 320` ⭐ **the largest heal in the game** | 1 | — | 250 📝 |
| `blankspine_belt` | Equipment | common | belt · Belt / Blankspine | 56 | `beltSlots: 9` ⚠️ capacity only | 3320 |
| `colophon_signet` | Equipment | **rare** | ring · Signet / Colophon Stone · `properName` · untradeable | 56 | `critChance: 12, critDamage: 30, accuracyBonus: 3` 📝 | 6400 |
| `the_open_colophon` | Equipment | **epic** | offHand · Codex / Blankspine · `properName` · untradeable | 58 | `accuracyBonus: 9, damagePerCast: 12, critChance: 8` 📝 | 17500 |

⭐ **`the_open_colophon` is the game's first and only off-hand that is not a
Knot**, and ITEMS §9b.6's own 💡 asked for it: *"off-hand families (Book / Orb /
Scroll / Relic) could carry light mechanical identities."* A **Codex** is the
book family's debut, and its identity is the wand lane's — per-cast damage and
the accuracy to land it — which is what makes wand + codex a real alternative
to `the_unbuilt_stair` at the top of the game. 📝 **The two lanes measured:**
the staff gives +40 flat on a 4-charge cast; wand + codex gives +22 flat,
+14 accuracy and +17 crit chance. **They are close, they are different, and
that is §9b.6's "the weapon choice is the build choice" finally being true at
the ceiling.**
⭐ **Belt ladder complete: … Penitent 8 → Blankspine 9.** `Carrying.maxBeltSlots`
is 10, so **one rung is left** — 📝 deliberately, for Zenith or for Phase 8.
⚠️ **`nightink_draught` at 320 is the ladder's top rung** and the check in §3.3
applies: it is two thirds of one cast and it costs the turn.

**Lore and icons**

- `nightink` — *"It is being made somewhere and it is arriving here. Nobody has
  found the somewhere."*
  **Icon:** a small stoppered pot of dense black liquid the size of a fist, the
  liquid sitting proud of the rim in a meniscus that should have spilled, with
  one cold blue sheen across its surface.
- `colophon_stone` — *"The stone a book's last page is cut from. There are a
  great many of them here and every book is still being written."*
  **Icon:** a flat polished tablet of dark grey-violet stone the size of a
  thumb, one face incised with a single small mark; Uncommon, so the mark holds
  one clean unlit violet note.
- `blankspine_vellum` — *"It has not been written on yet. That is the only
  difference between it and everything else here."*
  **Icon:** a single sheet of flawless pale vellum the size of a book, lying
  flat and perfectly clean with a hard straight edge, its corners uncurled.
- `nightink_draught` — *"Black, thick, and it tastes of nothing whatsoever.
  Vespergate brews it and will not say from what."*
  **Icon:** a tall narrow bottle of dark glass the height of a hand holding an
  opaque black liquid, a pale vellum label tied at the neck with nothing
  written on it.
- `blankspine_belt` — *"Nine loops of a vellum that has not been written on. You
  will want to keep it that way."*
  **Icon:** a wide pale-cream vellum belt laid in a loose open curve with a
  plain dark buckle and **nine empty loops** stitched along it, the vellum
  entirely unmarked.
- `colophon_signet` — *"It presses a mark that means 'ends here'. Nothing here
  ends."*
  **Icon:** a heavy dark ring with a flat stone face, standing upright, the face
  cut with one small deep mark; Rare, so a hot violet point burns in that mark
  and lights the whole face.
- `the_open_colophon` — *"Held open at the last page. The last page is being
  written and it is about you."*
  **Icon:** a thick codex bound in pale vellum, the size of two hands, held open
  in mid-air at its final page; Epic, so a line of cold violet script is
  *writing itself* across that page, one character at a time, reaching the
  margin and continuing on the next line without ever filling it.

📝 **Phase 8 hook.** The **Umbra + Arcane** pair, and 💡 **the off-hand family
identities** ITEMS §9b.6 sketched: if Codex is the book, Orb and Relic want
homes, and the Citadel is the only zone above this one.

---

### 4.8 The Eclipsed Citadel · `the_eclipsed_citadel` · 58–60 · **all twelve** · 🏰 dungeon · Empyrean

> ✅ *"Below it, through a gap in nothing, is the summit of the mountain you
> could not climb. The Citadel is between you and it. That is what the name has
> always meant."*
>
> ⭐ **Theme (ENEMIES §2e): the last thing in the way.** Not a place — an
> **obstruction**.

⚠️ **The final dungeon, and the only zone in the game gated behind items**
(§3.4: the three Thirds). ⚠️ **Its roster is ENEMIES §2e's open proposal** — the
game replaying itself, echoes of bosses already beaten — and ❓ whether the
two-boss pool applies is unruled. ⭐ **Nothing below depends on the answer.**

⭐ **Three rulings shape this catalogue, and they are all one idea: an
obstruction is not a landscape.**

1. **Two materials, both kill-only, no gather node** (§3.1). Nothing grows on a
   thing standing in a door.
2. **No mote family, and the drop tables pay in all twelve.** Every other zone
   pays in one or two; this one pays in everything, which is the only mechanical
   statement available for *"all twelve at once"* that does not require twelve
   new items.
3. **Two epics, not one.** ✅ Every other zone in four quarters gets exactly one.
   The Citadel gets two because it is the last content in the game and because
   its two materials are each the headline of one of them.

#### Drop table

```
_commonAlways = [ DropEntry.oneOf(                        📝 ⚠️ see the note
                    ['aqua_dust','pyro_dust','flora_dust','electro_dust',
                     'aero_dust','geo_dust','solar_dust','lunar_dust',
                     'astral_dust','sanctus_dust','umbra_dust','arcane_dust'],
                    chance: 1.0, min: 1, max: 2) ]
```

⚠️ **`DropEntry.oneOf` does not exist.** The shipped `DropEntry` is one id with
one chance. ⭐ **This is the one place this contract asks for a code change, and
it asks for the smallest one:** either add a `oneOf` constructor, or — 📝 the
zero-change alternative — list **twelve `DropEntry` rows at `chance: 0.12`
each**, which yields ~1.4 dusts per kill across a random spread of families.
**The second is recommended** because it needs nothing new and reads correctly
in the loot log; the first is cleaner data. ⚠️ **Whichever is chosen, it must be
chosen once — the mini and boss tables have the same shape.**

| Role | main | bonus |
|---|---|---|
| echo-pool encounter | nothing 30 · `eclipse_iron` 35 · `corona_pearl` 25 · `nightink_draught` 10 | `climbers_ration` 5% |

```
_miniDrops  always: any 2 of the twelve shards ×1 · the same 2 dusts 2–4
                    · a matching crystal chance 0.25
            main:   eclipse_iron 40 (2–4) · corona_pearl 35 (2–4) · nightink_draught 20
                    · the_eclipsed_band 5
_bossDrops  always: any 3 of the twelve crystals 1–2 · the same 3 shards 1–2
                    · the same 3 dusts 4–8         ⭐ the richest always-line in the game
            main:   eclipse_iron 35 (4–8) · corona_pearl 30 (4–8)
                    · the_eclipsed_band 15 · the_last_thing_in_the_way 10 · the_corona 10
```

📝 **The boss table pays an epic at 20 combined weight — one clear in five.**
KINETIC's best was 15 on a single epic. ⭐ Deliberate: it is the last fight and
there are two chases, so a player who beats Procarius five times sees roughly
one of each. 📝 Flatten both to 8 if that reads as too generous.
⚠️ **No gate item drops here.** The Citadel is the gate's *destination*; its own
exit leads to Zenith, whose gate is out of scope (§3.4a).

#### Catalogue — 7 defs (`the_eclipsed_citadel_items.dart`)

| id | Kind | Rarity | Slot · Form / Material | Equip | Modifiers | Value |
|---|---|---|---|---|---|---|
| `eclipse_iron` | Material | **uncommon** | Jewelry t10 · ⚠️ **kill-only, no node** | 1 | — | 1000 📝 |
| `corona_pearl` | Material | **uncommon** | Jewelry t10 · ⚠️ **kill-only, no node** | 1 | — | 900 📝 |
| `corona_torc` ⭐ | Equipment | common | neck · Torc / Corona Pearl | 58 | `maxHpBonus: 45, critChance: 5, accuracyBonus: 3` | 3400 |
| `eclipse_ring` ⭐ | Equipment | common | ring · Ring / Eclipse Iron | **60** | `damagePerCast: 7, critChance: 6, critDamage: 12` | 3950 |
| `the_eclipsed_band` | Equipment | **rare** | ring · Band / Eclipse Iron · `properName` · untradeable | 58 | `maxHpBonus: 60, dodge: 6, critChance: 8` 📝 | 7800 |
| `the_last_thing_in_the_way` | Equipment | **epic** | gloves · Gauntlets / Eclipse Iron · `properName` · untradeable | **60** | `damagePerCast: 14, accuracyBonus: 6, critChance: 10, critDamage: 10` 📝 | 22000 |
| `the_corona` | Equipment | **epic** | hat · Coronet / Corona Pearl · `properName` · untradeable | **60** | `maxHpBonus: 70, deflectChance: 16, deflectAmount: 14, shieldStrengthPercent: 12` (EV 2.2%) 📝 | 24000 |

⭐ **`eclipse_ring` and the two epics are the only equipLevel-60 items in the
game.** Everything else a level-60 mage wears was made or found lower down;
these three are the only things that require the cap itself.
⭐ **`corona_torc` and `eclipse_ring` are the end of the Jewelry ladder and they
are Commons**, which is ITEMS §9b.6a's lattice at its clearest: they have maxed
flat stats and **structurally cannot carry a modifier** (§8). The two epics
beside them are not much stronger in raw numbers — ⚠️ §2.6 finding 2 — and are
better because rarity buys capability.
⚠️ **`the_corona`'s `deflectAmount: 14` is not a free number.** §2.1b: the worst
legal assembly across all four quarters is `unleft_gloves` 26 + a deflect hat 14
+ `bedrock_greaves` 10 = **exactly 50**, ITEMS §4.1a's player cap. **Raising
this number by one breaks a design invariant thirty levels away.**
⭐ **The two epics are a real choice, not a ladder:** `the_last_thing_in_the_way`
is the whole offensive budget of the fight (+14 per cast, +10% crit) and
`the_corona` is the whole defensive one (+70 HP, deflection, shields). ⚠️ They
occupy different slots, so a player who clears the Citadel enough times wears
both — which is correct. The choice is **which one first**, and it will be the
last gear decision anyone makes.

**Lore and icons**

- `eclipse_iron` — *"Off the thing in the door. It is cold in a way iron is not
  and it does not take a shine."*
  **Icon:** a fist-sized block of dense black metal with one broken face, so
  matte it reads as a silhouette, with a single hairline of cold white along the
  break; Uncommon, so that hairline is the only note.
- `corona_pearl` — *"The ring of light around a thing that is in the way. It
  came off the same thing."*
  **Icon:** a large pale pearl the size of a plum resting on a flat face, its
  surface a soft cream-white with a faint ring of warm gold iridescence around
  its widest circumference; Uncommon, so that ring is one unlit note.
- `corona_torc` — *"A neck ring, open at the front, because a torc is a thing
  you are given rather than a thing you buy."*
  **Icon:** an open circular neck torc of dark metal with a pale pearl finial at
  each of its two open ends, standing upright; Common, so nothing is emissive —
  the pearls carry their own soft colour.
- `eclipse_ring` — *"Plain, black, and it is the last thing anybody in this
  world learned how to make."*
  **Icon:** a plain heavy band of matte black eclipse iron standing upright,
  utterly unornamented, its silhouette perfectly circular and its surface
  giving back no light at all except a single thin rim highlight.
- `the_eclipsed_band` — *"It has been between something and something else for
  a very long time."*
  **Icon:** a broad black band standing upright with a narrow slot cut clean
  through its front, so the ring is a circle with a gap in its face; Rare, so a
  hard white light shows *through* that slot from behind and lights nothing
  else.
- `the_last_thing_in_the_way` — *"It stopped everyone. Then it stopped."*
  **Icon:** a pair of heavy black gauntlets, palms outward and fingers spread in
  a flat halt, the plate scored with old impact marks; Epic, so a hard white
  light builds in both palms, reaching full brightness, and goes out — over and
  over, like something being refused and refusing again.
- `the_corona` — *"You see it from below, all the way up the mountain, and you
  take it off the thing that was wearing it."*
  **Icon:** a low coronet of dark metal set with a single large pale pearl at
  the brow, worn as a band; Epic, so a full ring of warm gold light stands off
  the coronet's whole circumference — a corona around a dark centre — and it
  *breathes*, widening and narrowing without ever closing.

📝 **Phase 8 hook.** ⭐ **Everything, and that is the point.** The Citadel is
where ITEMS §3.4's **set Tier IV (Legendary)** would be earned, where the
Concordant Crown's twelve gems would be set (§3.4a), and where a Mythic or
Legendary drop would first make sense. ⚠️ **This contract ships neither
rarity**, and the two epics above are written so that a Legendary can be added
*above* them without re-tuning anything below.

---

## 5. The recipe ladder

✅ **32 recipes**, in one file: `lib/game/items/recipes/ethereal_recipes.dart`,
registered in `RecipeBook.all`.

📝 **32 is above the ~20–26 guide, and Jewelry's debut is the cause:** seven of
the thirty-two are the first Jewelry recipes in the game, and they exist to
spend seven gems banked across three quarters. 📝 The cheapest trim is
`craft_nacre_pendant` and `craft_eclipse_signet` (→ 30), but ⚠️ **each cut
strands a banked material**, and §0.2 rules that nothing may be left unspent.

### 5.1 The table

XP is `Σ input counts × (4 + 2 × gate)`.

| # | Recipe id | Skill | Gate | Inputs (id × count) | Output | **XP** |
|---|---|---|---|---|---|---|
| 1 | `craft_deepsteel_ingot` | Metalworking | 46 | `deepstratum_ore` ×3, `charcoal` ×2 ⏳ | `deepsteel_ingot` | **480** |
| 2 | `craft_aethersteel_ingot` | Metalworking | 50 | `mana_slag` ×3, `charcoal` ×2 ⏳ | `aethersteel_ingot` | **520** |
| 3 | `craft_spiritwood_quarterstaff` | Woodcarving | 46 | `spiritwood_log` ×3, `deepsteel_ingot` ×1 | `spiritwood_quarterstaff` | **384** |
| 4 | `craft_spiritwood_wand` | Woodcarving | 46 | `spiritwood_log` ×2, `deepsteel_ingot` ×1 | `spiritwood_wand` | **288** |
| 5 | `craft_spiritwood_knot` | Woodcarving | 46 | `spiritwood_log` ×2 | `spiritwood_knot` | **192** |
| 6 | `craft_aetherwood_quarterstaff` | Woodcarving | 50 | `aetherwood_log` ×3, `aethersteel_ingot` ×1 | `aetherwood_quarterstaff` | **416** |
| 7 | `craft_aetherwood_wand` | Woodcarving | 50 | `aetherwood_log` ×2, `aethersteel_ingot` ×1 | `aetherwood_wand` | **312** |
| 8 | `craft_aetherwood_knot` | Woodcarving | 50 | `aetherwood_log` ×2 | `aetherwood_knot` | **208** |
| 9 | `craft_umbralweave_hood` | Tailoring | 44 | `umbralweave` ×3 | `umbralweave_hood` | **276** |
| 10 | `craft_umbralweave_robe` | Tailoring | 44 | `umbralweave` ×6 | `umbralweave_robe` | **552** |
| 11 | `craft_umbralweave_leggings` | Tailoring | 44 | `umbralweave` ×5 | `umbralweave_leggings` | **460** |
| 12 | `craft_umbralweave_boots` | Tailoring | 44 | `umbralweave` ×3 | `umbralweave_boots` | **276** |
| 13 | `craft_umbralweave_gloves` | Tailoring | 44 | `umbralweave` ×3 | `umbralweave_gloves` | **276** |
| 14 | `craft_corebiter_belt` | Tailoring | 46 | `corebiter_hide` ×2, `umbralweave` ×1 | `corebiter_belt` | **288** |
| 15 | `craft_unleft_hood` | Tailoring | 48 | `unleft_linen` ×3 | `unleft_hood` | **300** |
| 16 | `craft_unleft_robe` | Tailoring | 48 | `unleft_linen` ×6 | `unleft_robe` | **600** |
| 17 | `craft_unleft_leggings` | Tailoring | 48 | `unleft_linen` ×5 | `unleft_leggings` | **500** |
| 18 | `craft_unleft_boots` | Tailoring | 48 | `unleft_linen` ×3 | `unleft_boots` | **300** |
| 19 | `craft_unleft_gloves` | Tailoring | 48 | `unleft_linen` ×3 | `unleft_gloves` | **300** |
| 20 | `craft_penitent_belt` | Tailoring | 48 | `thornpenitent_hide` ×2, `umbralweave` ×1 | `penitent_belt` | **300** |
| 21 | `craft_blankspine_belt` | Tailoring | 50 | `blankspine_vellum` ×2, `unleft_linen` ×1 | `blankspine_belt` | **312** |
| 22 | `craft_goldenrood_draught` | Potions & Alchemy | 46 | `goldenrood` ×3 | `goldenrood_draught` | **288** |
| 23 | `craft_worldroot_tonic` | Potions & Alchemy | 48 | `worldroot` ×3 | `worldroot_tonic` | **300** |
| 24 | `craft_censer_draught` | Potions & Alchemy | 48 | `censer_resin` ×4 | `censer_draught` | **400** |
| 25 | `craft_nightink_draught` | Potions & Alchemy | 50 | `nightink` ×4 | `nightink_draught` | **416** |
| 26 ⭐ | `craft_everice_band` | **Jewelry** | **1** | `everice` ×2 ⏳**Q2**, `quarry_jasper` ×2 ⏳**Q2**, `nadir_garnet` ×1 | `everice_band` | **30** |
| 27 ⭐ | `craft_nacre_pendant` | **Jewelry** | 10 | `nacre` ×3 ⏳**Q3**, `obsidian` ×2 ⏳**Q2**, `deepsteel_ingot` ×1 | `nacre_pendant` | **144** |
| 28 ⭐ | `craft_eclipse_signet` | **Jewelry** | 20 | `eclipse_opal` ×3 ⏳**Q3**, `sidereal_glass` ×2 ⏳**Q3**, `thoughtglass` ×2 | `eclipse_signet` | **308** |
| 29 ⭐ | `craft_aetherglass_locket` | **Jewelry** | 30 | `aetherglass` ×3 ⏳**Q3**, `reliquary_gold` ×2 | `aetherglass_locket` | **320** |
| 30 | `craft_orchard_loop` | **Jewelry** | 35 | `orchard_amber` ×3, `reliquary_gold` ×1, `aethersteel_ingot` ×1 | `orchard_loop` | **370** |
| 31 | `craft_corona_torc` | **Jewelry** | 44 | `corona_pearl` ×2, `colophon_stone` ×2, `aethersteel_ingot` ×1 | `corona_torc` | **460** |
| 32 | `craft_eclipse_ring` | **Jewelry** | 50 | `eclipse_iron` ×3, `colophon_stone` ×2 | `eclipse_ring` | **520** |

⭐⭐ **#26 through #29 are the payoff of every banking clause in the design
docs.** Read them together:

| Banked | Where | When | Spent by |
|---|---|---|---|
| `quarry_jasper` | Old Quarry | Q2, L15–19 | #26 |
| `everice` | Frostfell Pass | Q2, L21–26 | #26 |
| `obsidian` | The Molten Deep | Q2, L25–29 | #27 |
| `nacre` | Tidewrack Shoals | Q3, L36–40 | #27 |
| `eclipse_opal` | The Sunless Reach | Q3, L38–42 | #28 |
| `sidereal_glass` | The Shattered Orrery | Q3, L40–44 | #28 |
| `aetherglass` | The Glass Archive | Q3, L43–47 | #29 |

⚠️ **All seven, nothing left.** ITEMS §9b.8 ruling 7 promised *"gatherable now,
spendable next quarter"*; KINETIC §8.1 extended three of them to Rimeholt;
CELESTIAL §3.1 added four more. **A player who ignored every jewel material
from level 15 onward arrives at Rimeholt with an empty bag and a maker they
cannot feed.** 📝 That is the intended lesson and it is a harsh one — ⚠️ **all
seven are still gatherable**, so it is a walk back, not a lockout.

⭐ **#1 and #2 spend `charcoal` — the fourth quarter to do so.** Ashfall Vale
(L10–14) is a zone a level-60 player still has a reason to visit.

### 5.2 Gate progression — does the ladder actually climb?

| Gate | XP to reach | Cheapest in-band route | Crafts after the previous gate |
|---|---|---|---|
| Tailoring 44 | 5,375 | ⭐ from Q3's Wrackcotton (252–504) | ~2 |
| Woodcarving 46 | 5,850 | ⭐ from Q3's Ebony (184–368) | ~2 |
| Metalworking 46 | 5,850 | Q3's Starbrass Ingot (460) | ~2 |
| Potions 46 | 5,850 | Q3's Sunbleach Tonic (276) | ~4 |
| Tailoring 46 | 5,850 | Umbralweave Robe (552) | ~1 |
| Tailoring 48 | 6,345 | Umbralweave Robe (552) | ~1 |
| Potions 48 | 6,345 | Goldenrood Draught (288) | ~2 |
| Woodcarving 50 | 6,860 | Spiritwood Quarterstaff (384) | ~3 |
| Metalworking 50 | 6,860 | Deepsteel Ingot (480) | ~2 |
| Potions 50 | 6,860 | Censer Draught (400) | ~2 |
| Tailoring 50 | 6,860 | Unleft Robe (600) | ~1 |
| **Jewelry 1** | 0 | ⭐ **the debut** | — |
| Jewelry 10 | 360 | Everice Band (30) | 12 |
| Jewelry 20 | 1,235 | Nacre Pendant (144) | ~7 |
| Jewelry 30 | 2,610 | Eclipse Signet (308) | ~5 |
| Jewelry 35 | 3,485 | Aetherglass Locket (320) | ~3 |
| Jewelry 44 | 5,375 | Orchard Loop (370) | ~6 |
| Jewelry 50 | 6,860 | Corona Torc (460) | ~4 |

⭐ **Jewelry is a complete seven-rung ladder from 1 to 50 inside one quarter**,
which no other skill has ever been given. ⚠️ **That is the right shape for a
skill debuting fifteen levels from the cap** — Metalworking debuted at L15 with
two recipes and a gate at 10, and CELESTIAL §5.2 already flagged the resulting
28-craft grind as the Celestial quarter's one inherited problem. Jewelry does
not repeat it.
⭐ **Everice Band at gate 1 and 30 XP is the debut recipe**, the same role
`craft_bronze_ingot` played for Metalworking — cheap, immediate, and made of
something the player already has.
⚠️ **Metalworking's inherited grind is still not fixed here.** CELESTIAL §5.2's
📝 (add `craft_skysteel_fitting` at gate 20) is the fix and it belongs in that
quarter.
⚠️ **Enchanting gets nothing this quarter** — CELESTIAL §8.2's ❓ is still open
and this contract cannot close it. If Transmute pays no XP, Enchanting reaches
level 60 having never left skill 1.

### 5.3 §6a.1 slot coverage — ⭐ the promise closes

| Slot | Q3 maker | **Q4 maker** | Change |
|---|---|---|---|
| Hat | Tailoring | Tailoring (Umbralweave/Unleft) | continues |
| Robe Top | Tailoring | Tailoring | continues |
| Robe Bottom | Tailoring | Tailoring | continues |
| Boots | Tailoring | Tailoring | continues |
| Gloves | Tailoring | Tailoring | continues |
| Belt | Tailoring (2) | Tailoring (3: Corebiter 7, Penitent 8, Blankspine 9) | continues |
| Main hand | Woodcarving (3 woods) | Woodcarving (Spiritwood/Aetherwood) | continues |
| Off hand | Woodcarving (Knot) | Woodcarving (Knot ×2) + ⭐ **Codex** (epic drop) | ⭐ a second family |
| **Neck** | ⚠️ drop-only since L1 | ⭐ **Jewelry** — Nacre Pendant, Aetherglass Locket, Corona Torc | ⭐⭐ **newly filled** |
| **Ring** | ⚠️ drop-only since L1 | ⭐ **Jewelry** — Everice Band, Eclipse Signet, Orchard Loop, Eclipse Ring | ⭐⭐ **newly filled** |
| — | Metalworking feeds 4 | Metalworking feeds 4 | continues |
| — | Enchanting: 1 recipe | ⚠️ **Enchanting: nothing new** | §5.2 |

> ⭐⭐ **§6a.1's *"every slot has a maker"* becomes true here, for the first
> time, sixty levels in.** Neck and Ring were drop-only from the Whispering
> Woods to The Glass Archive; **seven Jewelry recipes close both at once**, and
> they do it with materials the player has been carrying since level 15.

### 5.4 Value conservation — the ECONOMY §8 audit

Rule as CELESTIAL §5.5: `Σ(inputs) ∈ [value, 1.2 × value]`; under is
exploitable, over is merely bad EV.

| Recipe | Σ(inputs) | Output value | Window | Verdict |
|---|---|---|---|---|
| #1 deepsteel_ingot | 3×120 + 2×7 = 374 | 360 | [360, 432] | ✅ |
| #2 aethersteel_ingot | 3×215 + 2×7 = 659 | 640 | [640, 768] | ✅ |
| #3 spiritwood_quarterstaff | 3×1500 + 360 = 4860 | 3900 | [3900, 4680] | over 4% ✅ safe |
| #4 spiritwood_wand | 2×1500 + 360 = 3360 | 3350 | [3350, 4020] | ✅ |
| #5 spiritwood_knot | 2×1500 = 3000 | 2800 | [2800, 3360] | ✅ |
| #6 aetherwood_quarterstaff | 3×2780 + 640 = 8980 | 7200 | [7200, 8640] | over 4% ✅ safe |
| #7 aetherwood_wand | 2×2780 + 640 = 6200 | 6200 | [6200, 7440] | ⭐ Σ = output |
| #8 aetherwood_knot | 2×2780 = 5560 | 5200 | [5200, 6240] | ✅ |
| #9–13 umbralweave ×3/6/5/3/3 | 870 / 1740 / 1450 / 870 / 870 | same | — | ⭐ Σ = output |
| #14 corebiter_belt | 2×700 + 290 = 1690 | 1690 | [1690, 2028] | ⭐ Σ = output |
| #15–19 unleft ×3/6/5/3/3 | 1560 / 3120 / 2600 / 1560 / 1560 | same | — | ⭐ Σ = output |
| #20 penitent_belt | 2×950 + 290 = 2190 | 2190 | [2190, 2628] | ⭐ Σ = output |
| #21 blankspine_belt | 2×1400 + 520 = 3320 | 3320 | [3320, 3984] | ⭐ Σ = output |
| #22 goldenrood_draught | 3×47 = 141 | 140 | [140, 168] | ✅ |
| #23 worldroot_tonic | 3×55 = 165 | 165 | [165, 198] | ✅ |
| #24 censer_draught | 4×53 = 212 | 210 | [210, 252] | ✅ |
| #25 nightink_draught | 4×63 = 252 | 250 | [250, 300] | ✅ |
| #26 everice_band | 2×26 + 2×15 + 180 = 262 | 260 | [260, 312] | ✅ |
| #27 nacre_pendant | 3×95 + 2×20 + 360 = 685 | 680 | [680, 816] | ✅ |
| #28 eclipse_signet | 3×130 + 2×160 + 2×200 = 1110 | 1100 | [1100, 1320] | ✅ |
| #29 aetherglass_locket | 3×210 + 2×340 = 1310 | 1300 | [1300, 1560] | ✅ |
| #30 orchard_loop | 3×260 + 340 + 640 = 1760 | 1750 | [1750, 2100] | ✅ |
| #31 corona_torc | 2×900 + 2×480 + 640 = 3400 | 3400 | [3400, 4080] | ⭐ Σ = output |
| #32 eclipse_ring | 3×1000 + 2×480 = 3960 | 3950 | [3950, 4740] | ✅ |

⭐ **Every row is inside its window or safely over it. No row falls under
Standard**, which is the direction that matters — a cleaner audit than either
earlier quarter's, because every value here was back-solved rather than
inherited.
⚠️ **Two quarterstaves run 4% over Ornate**, the same shape Yew, Rowan,
Ironwood, Bloodwood and Ebony all have: a staff takes three logs where a wand
takes two, and the wand is what the log value is solved against. ✅ ECONOMY §8.2
blesses this direction explicitly.
⚠️ **Motes appear in no recipe** (ECONOMY §14c), so refine-and-craft is not an
arbitrage.

---

## 6. Gather nodes

✅ **18 nodes.** ⚠️ **Five materials get none:** three kill-only hides
(`corebiter_hide`, `thornpenitent_hide`, `blankspine_vellum`) and **the
Eclipsed Citadel's two, which have none because the Citadel has none** (§3.1).
✅ Skill from the consuming skill (§6a.1). ✅ XP is `9 + 2 × (minLevel − 1)`.

| id | Zone | Skill | Yields | min–max | **XP** | Gesture 📝 | Flavour hook |
|---|---|---|---|---|---|---|---|
| `hm_spiritwood_stand` | hallowmarch | Felling | `spiritwood_log` | 2–4 | **97** | `releaseTiming 'chop' reps 5` | Planted in a row beside the road, which means somebody expected to come back |
| `hm_goldenrood_verge` | hallowmarch | Foraging | `goldenrood` | 2–3 | **97** | `trace 'cut' complexity 4` | It only grows in the cut channel, and the channel did not cut itself |
| `bs_stratum_seam` | the_buried_sky | Mining | `deepstratum_ore` | 2–4 | **99** | `sweetSpot 'strike' reps 5` | The lowest band the shaft reaches, and the shaft was going somewhere |
| `bs_nadir_pocket` | the_buried_sky | Mining | `nadir_garnet` | 2–3 | **99** | `alignCommit 'pry' complexity 4` | A pocket of red in the black. Held to a lamp the flecks make a shape |
| `uw_umbralweave_drift` | the_umbral_wastes | Foraging | `umbralweave` | 2–4 | **101** | `rateDrag 'draw' reps 3` | It lifts off the ice in sheets if you pull it in the dark and tears if you do not |
| `uw_thoughtglass_face` | the_umbral_wastes | Mining | `thoughtglass` | 2–3 | **101** | `alignCommit 'split' complexity 4` | Split it however you like. The new face comes out the same shape as the old one |
| `sg_worldroot_undercut` | the_sealed_garden | Foraging | `worldroot` | 2–4 | **105** | `trace 'dig' complexity 4` | Dug from under the wall on the outside, where something inside has been reaching |
| `sg_amber_bough` | the_sealed_garden | Mining | `orchard_amber` | 2–3 | **105** | `alignCommit 'pry' complexity 4` | Sap on a bough nobody has pruned in four centuries, and the bough is still right |
| `ca_aetherwood_stair` | the_collapsed_academy | Felling | `aetherwood_log` | 2–4 | **107** | `releaseTiming 'chop' reps 5` | A staircase with more treads than it has height. Take one; there will be another |
| `ca_slag_vault` | the_collapsed_academy | Mining | `mana_slag` | 2–4 | **107** | `sweetSpot 'strike' reps 5` | What ran out of the floor when the school stopped, pooled in the vault below it |
| `rd_censer_run` | the_reliquary_deep | Foraging | `censer_resin` | 2–3 | **111** | `trace 'scrape' complexity 4` | The censers along the warm stretch. None of them has been lit and none is cold |
| `rd_gilt_fitting` | the_reliquary_deep | Mining | `reliquary_gold` | 2–3 | **111** | `alignCommit 'prise' complexity 4` | Somebody had a great deal of gold to spare on a corridor nobody was meant to walk |
| `rd_altar_linen` | the_reliquary_deep | Foraging | `unleft_linen` | 2–4 | **111** | `rateDrag 'lift' reps 3` | Still folded, still square, still on the altar. Nobody took it |
| `ul_nightink_well` | the_unwritten_library | Foraging | `nightink` | 2–4 | **115** | `rateDrag 'draw' reps 4` | The well is full and nothing fills it. Draw steadily; it does not like haste |
| `ul_colophon_shelf` | the_unwritten_library | Mining | `colophon_stone` | 2–3 | **115** | `placement 'choose' complexity 4` ⭐ | Every book's last page is cut from one of these, and every book is still being written |
| `hm_causeway_quarry` | hallowmarch | Mining | `deepstratum_ore` | 2–3 | **97** | `sweetSpot 'strike' reps 4` | Where they got the stone for the road. It came from further down than the road is |
| `uw_shoulder_drift` | the_umbral_wastes | Foraging | `umbralweave` | 2–3 | **101** | `rateDrag 'draw' reps 4` | Round the shoulder, where the light stops and the sheets are thickest |
| `sg_wallside_root` | the_sealed_garden | Foraging | `worldroot` | 2–3 | **105** | `trace 'dig' complexity 3` | Against the wall itself, where whatever is inside is pushing hardest |

⚠️ **The last three rows are SECOND nodes on materials that already have one**,
and they exist for a reason worth stating: `deepstratum_ore`, `umbralweave` and
`worldroot` are each consumed by **four or more** recipes, and one node per run
section cannot keep a level-50 crafter supplied. ⭐ **A second node is a
throughput fix, not a second source** — both yield the same id, and the
no-second-source rule in `gather_node.dart`'s library comment is about the
*fiction* (a hide must not have a node at all), not about node count.
📝 **Cut all three to 15 nodes if one-node-per-material is a hard rule.**
⚠️ `hm_causeway_quarry` yields a **Buried Sky** material from **Hallowmarch**,
which is the only cross-zone node in the game. ⭐ Deliberate and it is the one
that most earns itself: the causeway's stone came from below, and a player who
has not yet found the shaft can still start the Metalworking ladder. 📝 The
safest cut of the three.

⭐ **Gathering skill balance across the whole game, after this quarter:**
Felling 2+1+2+2 = 7 · Foraging 2+2+5+8 = 17 · Mining 2+6+8+7 = 23. ⚠️ **Felling
is the thinnest skill in the game at seven nodes** and always has been — one
per wood, which is exactly one per material tier. 📝 That is either correct (a
wood ladder is a ladder of nine rungs, and nine nodes is nine rungs) or it is
the reason nobody levels Felling. Worth a look in the probe.
⚠️ **`ul_colophon_shelf` uses `placement`**, the second gather node in the game
to do so after CELESTIAL's `ga_noon_shelf`. ⭐ Both are "choose which one",
which is precisely what the engine's doc says it is for.

---

## 7. Cross-checks appendix

### 7.1 Counts

| Thing | Count | Check |
|---|---|---|
| **Item definitions** | **79** | Hallowmarch 12 · Buried Sky 10 · Umbral Wastes 12 · Sealed Garden 10 · Collapsed Academy 8 · Reliquary Deep 13 · Unwritten Library 7 · Eclipsed Citadel 7 |
| — materials | 20 | ✅ 2+3+2+3+2+3+3+**2** — the Citadel's 2 by ruling (§3.1). ⏳ **none bank** |
| — motes | 6 | 2 families × dust/shard/crystal. ⚠️ No Arcane (Q3 owns it), no Core, no Heart |
| — consumables | 5 | 1 Ration (drop-only) · 3 Draughts · 1 Tonic |
| — intermediate goods | 2 | `deepsteel_ingot`, `aethersteel_ingot` |
| — equipment | 43 | 6 weapons + 10 armour + 3 belts + **7 crafted jewelry** + 8 rare + 9 epic |
| — keys | 3 | the three Thirds — ✅ three ids on one gate |
| **Recipes** | **32** | Tailoring 13 · Woodcarving 6 · **Jewelry 7** · Potions 4 · Metalworking 2 · Enchanting 0 |
| **Gather nodes** | **18** | 20 materials − 3 hides − 2 Citadel + 3 throughput duplicates |
| New files | **10** | 8 catalogues, 1 recipe file, 18 nodes appended to `GatherNodes` — plus registrations |

**Across both contracts:** 155 item definitions, 60 recipes, 35 gather nodes,
15 zones, 4 tier-gate items.

⚠️ **Registration:** every catalogue in `ItemCatalogue.byZone`; the recipe file
in `RecipeBook.all`; every node in `GatherNodes.all`; and ⚠️
**`the_eclipsed_citadel.gateItemIds` must be set to the three Thirds** in
`world.dart`, or the last door in the game is unlocked.

### 7.2 Id uniqueness against the shipped game

Checked mechanically against the **610 shipped ids**, and against
CELESTIAL_CONTRACT's 121:

> ✅ **79 item ids + 32 recipe ids + 18 node ids = 129 new ids.** Zero
> collisions with shipped ids, zero with the Celestial contract, and zero
> duplicates among themselves.

| Near-miss | Why it is fine |
|---|---|
| ENEMIES' *Corebiter* (a Siphon) / `corebiter_hide` | ✅ the `the_overseer` / `overseers_seal` pairing again |
| ENEMIES' *Thornpenitent* (a Bruiser) / `thornpenitent_hide` | as above |
| ENEMIES' *Blankspine* (a Sentinel) / `blankspine_vellum` | as above |
| ENEMIES' *The Unleft* (a Blighter) / `unleft_linen` | as above — ⭐ four hide/fibre-to-creature pairings in one quarter, which is the rule working, not a habit |
| ENEMIES' *Colophon* (a mini) / `colophon_stone`, `colophon_signet`, `the_open_colophon` | ⚠️ **four "colophon" strings in one zone.** Distinct ids; 📝 the **display** names may read as a set they are not |
| ENEMIES' *Nadir* (a mini) / `nadir_garnet` | distinct namespaces |
| ENEMIES' *Warm Middle* (a mini) / key `the_written_third` | ⭐ deliberately adjacent, deliberately not the same string |
| ENEMIES' *The Kept Vow* (a mini) / key `the_kept_third` | as above |
| `the_deliberate_dark` / KINETIC's `the_given_weight` | ⚠️ both are "the \<adjective\> \<noun\>" epics. Distinct; the quarter already has *The Last Three Items*, *What Was Thought About* and *The Kept Vow* in the same register — 📝 a **display**-name concern, not an id one |
| `eclipse_iron` / `eclipse_signet` / `eclipse_ring` / `the_eclipsed_band` / `the_eclipsed_citadel` | ⚠️ **five "eclipse" strings.** ✅ ITEMS §9b.5b already reserved *Eclipsed* as an aspect prefix **because of the Citadel**; no aspect prefix is used in either contract, so the reservation is intact |
| node prefixes `hm_ bs_ uw_ sg_ ca_ rd_ ul_` | none collide with the sixteen already in use |

### 7.3 Every drop-table id resolves

| Zone | Ids referenced | All defined? |
|---|---|---|
| hallowmarch | `sanctus_*` `spiritwood_log` `goldenrood` `climbers_ration` `votive_pendant` `the_maintained_road` | ✅ all local |
| the_buried_sky | `geo_*` ✅ **Q2** `astral_*` ✅ **Q3** `deepstratum_ore` `nadir_garnet` `corebiter_hide` `climbers_ration` `goldenrood_draught` `stonefall_signet` `bedrock_greaves` | ✅ `geo_*` → `old_quarry_items.dart`, `astral_*` → `starfall_basin_items.dart` |
| the_umbral_wastes | `umbra_*` `umbralweave` `thoughtglass` `climbers_ration` `goldenrood_draught` `the_considered_ring` `the_deliberate_dark` | ✅ |
| the_sealed_garden | `flora_*` ✅ **Q1** `sanctus_*` `worldroot` `orchard_amber` `thornpenitent_hide` `climbers_ration` `worldroot_tonic` `the_gardeners_loop` `the_season_at_once` | ✅ `flora_*` → `whispering_woods_items.dart` |
| the_collapsed_academy | `arcane_*` ✅ **Q3** `aetherwood_log` `mana_slag` `climbers_ration` `chalkline_signet` `the_unbuilt_stair` | ✅ `arcane_*` → `the_glass_archive_items.dart` |
| the_reliquary_deep | `sanctus_*` `umbra_*` `censer_resin` `reliquary_gold` `unleft_linen` `climbers_ration` `censer_draught` `censer_pendant` `the_unconsecrated` | ✅ |
| the_unwritten_library | `umbra_*` `arcane_*` `nightink` `colophon_stone` `blankspine_vellum` `climbers_ration` `nightink_draught` `censer_draught` `colophon_signet` `the_open_colophon` | ✅ |
| the_eclipsed_citadel | ⭐ **all twelve dust/shard/crystal families** `eclipse_iron` `corona_pearl` `climbers_ration` `nightink_draught` `the_eclipsed_band` `the_last_thing_in_the_way` `the_corona` | ✅ — ⚠️ resolves across **eleven catalogue files in four quarters**, which is the widest reference in the game |

⭐ **Three cross-quarter mote references, each further back than the last:**
`geo_*` (Q2), `arcane_*` (Q3) and — ⭐⭐ **`flora_*` (Q1, levels 1–5)** in The
Sealed Garden.

✅ **Every drop role has an item to resolve to.** The roster lane owes each zone
one or two `material` commons, one `hide` common where the zone has one (Buried
Sky, Sealed Garden, Unwritten Library), and — for the Citadel — a boss and an
echo pool to hang `always` lines on.

### 7.4 Every recipe input is obtainable in-band ✅ and nothing is left over

| Input | Source | In band? |
|---|---|---|
| `charcoal` ⏳ | `av_charcoal_burn`, Ashfall Vale 10–14 | ✅ banked, re-farmable |
| `quarry_jasper` ⏳ | `oq_jasper_face`, Old Quarry 15–19 | ⭐ **spent at last** — #26 |
| `everice` ⏳ | `ff_everice_seam`, Frostfell 21–26 | ⭐ **spent at last** — #26 |
| `obsidian` ⏳ | `md_obsidian_flow`, Molten Deep 25–29 | ⭐ **spent at last** — #27 |
| `nacre` ⏳ | `ts_nacre_bed`, Tidewrack 36–40 | ⭐ **spent** — #27 |
| `eclipse_opal` ⏳ | `sr_opal_seam`, Sunless Reach 38–42 | ⭐ **spent** — #28 |
| `sidereal_glass` ⏳ | `so_lens_shatter`, Orrery 40–44 | ⭐ **spent** — #28 |
| `aetherglass` ⏳ | `ga_roof_spoil` / `ga_noon_shelf`, Glass Archive 43–47 | ⭐ **spent** — #29 |
| `spiritwood_log` | `hm_spiritwood_stand` + Hallowmarch commons | ✅ |
| `goldenrood` | `hm_goldenrood_verge` + Hallowmarch commons | ✅ |
| `deepstratum_ore` / `deepsteel_ingot` | `bs_stratum_seam`, `hm_causeway_quarry` + Buried Sky commons / crafted #1 | ✅ |
| `nadir_garnet` | `bs_nadir_pocket` + Buried Sky commons | ✅ |
| `corebiter_hide` | ⚠️ Buried Sky **kills only** | ✅ by design |
| `umbralweave` | `uw_umbralweave_drift`, `uw_shoulder_drift` + Umbral commons | ✅ |
| `thoughtglass` | `uw_thoughtglass_face` + Umbral commons | ✅ |
| `worldroot` | `sg_worldroot_undercut`, `sg_wallside_root` + Garden commons | ✅ |
| `orchard_amber` | `sg_amber_bough` + Garden commons | ✅ |
| `thornpenitent_hide` | ⚠️ Sealed Garden **kills only** | ✅ by design |
| `aetherwood_log` | `ca_aetherwood_stair` + Academy commons | ✅ |
| `mana_slag` / `aethersteel_ingot` | `ca_slag_vault` + Academy commons / crafted #2 | ✅ |
| `censer_resin` | `rd_censer_run` + Reliquary commons | ✅ |
| `reliquary_gold` | `rd_gilt_fitting` + Reliquary commons | ✅ |
| `unleft_linen` | `rd_altar_linen` + Reliquary commons | ✅ |
| `nightink` | `ul_nightink_well` + Library commons | ✅ |
| `colophon_stone` | `ul_colophon_shelf` + Library commons | ✅ |
| `blankspine_vellum` | ⚠️ Unwritten Library **kills only** | ✅ by design |
| `eclipse_iron` / `corona_pearl` | ⚠️ Eclipsed Citadel **kills only, no node** | ✅ by design — §3.1 |

> ⭐ **Every one of this quarter's twenty materials has a consumer, and so does
> every gem banked since level 15.** §0.2's ruling, verified.
> ⚠️ **The whole game's unconsumed list is now exactly two: `hoarlichen` and
> `firesalt`** — the Antidote and the offensive potion, still waiting on
> `ItemEffect` vocabulary (KINETIC §8.5, SYSTEMS §3.7). ⚠️ **The test that
> asserts unconsumed materials must be updated to two, not six**, or it will
> pass on a stale list forever.

### 7.5 Economy and balance invariants

| Invariant | Where it is honoured |
|---|---|
| Dust drops routinely | Every `_commonAlways`; ⚠️ the Citadel's twelve-family shape needs §4.8's ruling |
| Shard is occasional | Main tables, weight 5–8; one guaranteed per mini |
| Crystal is rare, mini/boss only | `_miniDrops` 0.25; `_bossDrops` guaranteed. ⚠️ **Never on a common** |
| Core never drops · Hearts are craft-only | ✅ neither defined — §3.2; ⚠️ blocks the Concordant Crown, §3.4a |
| Motes sell-only, lossy, uniform per tier | ✅ ECONOMY §14c; ⚠️ no mote is a recipe input |
| **Gear rarity stays common/rare/epic** | ✅ 26 crafted Commons, 8 Rares, 9 Epics. ⚠️ **No Mythic and no Legendary, although ITEMS §3.4 puts set Tiers III and IV in this band** — §3.6 |
| Common = flat stats only (§8) | ✅ every crafted piece carries flat numbers or a paired chance/amount |
| Belts are capacity, never power | ✅ all three are `beltSlots` alone; ladder ends at 9 of a possible 10 |
| Crafted is the floor, drops the ceiling | ⚠️ §2.6 finding 2 — **8.20 vs 10.55 levels**, the narrowest gap in the game |
| **`Σ deflectAmount ≤ 50`** | ✅ **exactly 50** at the worst legal cross-quarter assembly — §2.1b. ⚠️ **Zero headroom** |
| **`Σ accuracy ≤ 30`** | ✅ 19 best-in-slot, 21 crafted-only — §2.1a |
| Enemy dodge ≤ 10 | ✅ §2.3–§2.4 |
| A potion heals less than a same-tier cast | ✅ §3.3 — Nightink 320 vs a ~545 player cast |
| Every material consumed in-band | ✅ **all 20, plus 7 banked gems** — §7.4 |
| No sets, no enchants, no gems | ✅ zero `setId`, zero `setTier`; `socketCount` only |
| **The gate is reachable** | ✅ three fragments, three guaranteed boss drops, three zones all below the Citadel's band |

### 7.6 What the shipped test suites will need

One file per zone, plus a cross-quarter file. Everything in CELESTIAL §7.6
applies, plus:

- ⚠️ **`World.byId('the_eclipsed_citadel').gateItemIds` equals the three
  Thirds**, and each Third's `gates` equals `'the_eclipsed_citadel'`
- ⚠️ **each Third's dropper zone is below the Citadel's band** — the assertion
  that catches somebody moving a fragment onto the Citadel itself
- ⚠️ **`Σ deflectAmount` over the maximum legal loadout ≤ 50** — ⚠️ **assembled
  across ALL FOUR quarters, not just this one** (§2.1b). It currently equals
  exactly 50, so this test fails on the next deflect item anyone adds, which is
  the point
- ⚠️ **the unconsumed-material list is exactly `{hoarlichen, firesalt}`** —
  §7.4. A test that still lists six will pass while being wrong
- ⚠️ **`the_collapsed_academy` defines no mote family**, and `arcane_*` resolve
  to the Glass Archive — the assertion that stops somebody "fixing" it
- ⚠️ **`the_eclipsed_citadel` has zero `GatherNodeDef`s** — §3.1's ruling, which
  a helpful builder will otherwise undo
- ⚠️ **no `EquipmentDef` in the game has `Rarity.uncommon`, `mythic` or
  `legendary`** — the Phase 8 guard
- ⚠️ **every `equipLevel` ≤ 60**, and the three level-60 items are exactly
  `eclipse_ring`, `the_last_thing_in_the_way`, `the_corona`
- ⚠️ **belt `beltSlots` form the strict ladder 1,2,3,4,5,6,7,8,9** and none
  exceeds `Carrying.maxBeltSlots`
- ⚠️ **`stonefall_signet` is the one item with `deflectChance` and no
  `deflectAmount`** — §4.2 bends KINETIC §2.1's inert-stat rule exactly once,
  and a test should say so out loud rather than let the next one in quietly

---

## 8. Decisions — open, for red-pen

CELESTIAL §8's six are all still open and all still apply. Four more are this
quarter's own.

### 8.1 ❓ Does the crafted floor being 2.4 levels under best-in-slot matter?

§2.6 finding 2. Jewelry's debut fills the last two slots and lifts crafted-only
from 5.7 to 8.2 levels while best-in-slot sits at 10.55. ITEMS §9b.4a's
*"crafted is the floor"* is still true and still categorical, but it is no
longer far. **Accept, or trim `corona_torc` and `eclipse_ring`?**

### 8.2 ❓ What is "average gear", and is 80–90% reachable?

§2.7. ITEMS §2.1's second target cannot be measured without a definition, and
the most natural one (Master crafted) produces a ×1.20 power edge — nearer 60%
than 85%.

### 8.3 ❓ Sanctus never gets an Aspect

§2.4. ENEMIES §2g gives Hallowmarch a Juggernaut and a Tyrant, so the only pure
Sanctus zone in the game fields no Aspect and Sanctus's passive is never taken
to an extreme by anything. **A hole, or the right reading of an element whose
identity is maintenance?**

### 8.4 ❓ The Citadel's twelve-element drop shape

§4.8. Either `DropEntry` gains a `oneOf` constructor, or twelve rows at
`chance: 0.12` each. **The second needs no code and is recommended; it should
still be chosen deliberately**, because the mini and boss tables need the same
answer.

### 8.5 📝 Three second nodes, one of them cross-zone

§6. `hm_causeway_quarry`, `uw_shoulder_drift` and `sg_wallside_root` are
throughput fixes for materials feeding four-plus recipes. Cut all three for
purity, or keep them for supply.

---

## 9. Fast-follow — ⚠️ what is left when this ships

With both contracts built, **every zone in the game has a catalogue** and the
remaining work is systems, not content:

- **Antidote + offensive potion** — KINETIC §9's debt, still open. ⭐ The
  grammar is settled (CELESTIAL §3.3): they are a fourth and fifth **form**,
  and `hoarlichen` and `firesalt` are the only two unconsumed materials left in
  the game (§7.4).
- **Phase 8 — sets, enchants, sockets, gems** — SYSTEMS §3. ⚠️ **Nineteen
  empty sockets are shipped across the two contracts** (Ironwood, Bloodwood and
  Ebony at 1; Spiritwood at 2; Aetherwood at 3, on three items each). They are
  a promise with a date on it now.
- **Core motes** — CELESTIAL §8.3. ⚠️ **Blocking the Concordant Crown.**
- **The Concordant Crown and Zenith** — §3.4a. Needs Core, needs gems, needs a
  purchased binding spell, which is a monetization design.
- **Mythic and Legendary** — ITEMS §3.4 puts set Tiers III and IV at L45 and
  L50, both inside this band. **The two rarities this contract may not use are
  exactly the two Phase 8 needs**, and every armour piece here is a plain
  Common so they can be added beside rather than instead (§3.6).
- **The Unwritten Library's *Your Entry*** — ENEMIES §2e, ❓ no archetype, no
  ruling, and 📝 it wants a drop (§4.7).

---

## Appendix A — file manifest for builders

| File | Contents | Registered in |
|---|---|---|
| `lib/game/items/catalogue/hallowmarch_items.dart` | 12 defs | `ItemCatalogue.byZone['hallowmarch']` |
| `…/the_buried_sky_items.dart` | 10 defs | `…['the_buried_sky']` |
| `…/the_umbral_wastes_items.dart` | 12 defs | `…['the_umbral_wastes']` |
| `…/the_sealed_garden_items.dart` | 10 defs | `…['the_sealed_garden']` |
| `…/the_collapsed_academy_items.dart` | 8 defs | `…['the_collapsed_academy']` |
| `…/the_reliquary_deep_items.dart` | 13 defs | `…['the_reliquary_deep']` |
| `…/the_unwritten_library_items.dart` | 7 defs | `…['the_unwritten_library']` |
| `…/the_eclipsed_citadel_items.dart` | 7 defs | `…['the_eclipsed_citadel']` |
| `lib/game/items/recipes/ethereal_recipes.dart` | 32 `RecipeDef` | `RecipeBook.all` |
| `lib/game/gathering/gather_node.dart` | +18 `GatherNodeDef` | `GatherNodes.all` |
| `lib/game/world.dart` | ⚠️ **+`gateItemIds` on `the_eclipsed_citadel`** | — |
| `lib/game/items/loot.dart` | 📝 **optional** `DropEntry.oneOf`, §4.8/§8.4 | — |
| `docs/ITEM_ART.md` | +8 zone sections, 79 entries | `tool/artgen.py` parses it |
| `test/<zone>_test.dart` × 8 | §7.6 | — |
| `test/deflect_budget_test.dart` | ⚠️ **cross-quarter**, §7.6 | — |

⚠️ **Shared seams:** `ethereal_recipes.dart`, `gather_node.dart`,
`ItemCatalogue.byZone`, `world.dart` and `ITEM_ART.md`. Assign each one owner.
⚠️ **This quarter depends on KINETIC §2.2's engine seam** and on the **Celestial
quarter's `arcane_*` motes** — it cannot compile without
`the_glass_archive_items.dart`.

---

## Changelog

**2026-09-22 — first draft.** Written against `ae9743c` on Christian's
2026-09-22 rulings, as the sibling of CELESTIAL_CONTRACT and in the same
structure. Closes three promises the design docs have been carrying: **§5.3**
makes ITEMS §6a.1's *"every slot has a maker"* true for the first time,
**§5.1 #26–#29** spend all seven gems banked across three quarters, and
**§3.3** completes the potion ladder KINETIC §9 left owing. Two findings are
new here: the crafted floor closing to 2.4 levels under best-in-slot once
Jewelry opens (**§2.6**), and the cross-quarter deflect budget landing on
exactly 50 with zero headroom (**§2.1b**). **§2.7** answers *"BiS vs naked ≈
100%"* in numbers at level 60: ×2.44 combat power, the same ratio as twenty-
three levels. Id uniqueness verified against 610 shipped ids and the Celestial
contract's 121.
