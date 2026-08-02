# Masters of Magic 2 — Items, Crafting & Enchanting

Design for equipment, the crafting economy, and how gear hooks into the
element-effect system. Companion to [GAME_DESIGN.md](GAME_DESIGN.md) (§4
Progression & Meta), [TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md) (the
nine elements), and [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) (levels,
slots, XP).

Legend: ✅ decided · 📝 draft (needs review) · 💡 idea bank · ❓ open question · ⚠️ balance/abuse concern

Status: 📝 **design session in progress — nothing implemented.** Approach:
define the endgame ceiling first, then scale the ladder down to it.

---

## 1. Inherited decisions (from GAME_DESIGN.md)

✅ Already settled before this session:

- **Ten slots** ✅ (naming settled):

  | Group | Slots |
  |---|---|
  | **Set slots** (the primary robe set, §3.2) | Hat · Robe Top · Robe Bottom · Boots · **Gloves** |
  | **Jewelry** | Neck · Ring |
  | **Held** | **Main hand** · **Off hand** |
  | **Utility** | ⭐ **Belt** (added 2026-08-02, §10.3c) |

  ✅ Held items are **Main hand / Off hand**, never "left/right" — this keeps
  them clearly distinct from the worn **Gloves** slot (gloves/bracers), which
  was previously called "Hands" and caused exactly that confusion.
- **Held items**: a one-handed weapon (wand) in the main hand pairs with an
  off-hand (orb, book, shield); **two-handed staves occupy both**.
- Items modify stats **including max HP**; the engine already carries a
  per-mage `maxHp`, so the hook exists.
- Items drop as **loot** from the campaign; a run's loot is lost on defeat,
  banked on "return to town".
- **Luck** is a real stat (from items/enchants): more gold, better rare drops.
- **Gold** (earned) and **Resonance Prisms** ("RP", premium) already exist on
  the profile. ⚠️ *Gem* means a socketed stone (§6d), never the currency.
- Crafting and enchanting are **time-gated**, skippable with premium currency.
- Creative north star: **RuneScape 3** equipment/skilling/economy feel.
- Existing stub: the Inventory tab already previews three verbs —
  **Transmute** (refine raw materials), **Craft** (combine into equipment),
  **Salvage** (break equipment into components).
- `mage_apparel.dart` already colors six visible pieces (hat, hatTrim, robe,
  robeTrim, gloves, boots) and is commented "later derived from equipped
  items" — the cosmetic hook is pre-wired.

✅ Both formerly-inherited open questions are now answered in this doc:
rarity tiers (§8) and held-item slots (Main/Off hand defined, §1 above).

---

## 2. The endgame ceiling — what BiS looks like

Working backwards, as intended. A fully-geared level-50 mage should feel
*transformed*, not merely bigger. Proposed shape of a best-in-slot loadout:

| Source | Contribution |
|---|---|
| **5-piece armor set** (archetype) | The build's identity — a rule-bending set bonus at 5 pieces |
| **Element enchant** on that armor | Sharpens one element's signature effect |
| **Weapon + off-hand** (or staff) | The damage engine: flat damage, on-hit, crit-like procs |
| **Neck + Ring** | Situational tech (counter-picks, Luck, utility) |
| **Flat stats across everything** | ~+50 max HP, modest damage % |

### 2.1 The power budget ✅

Measured against **average** gear, not nakedness — nobody reaches 50 unequipped.

| Matchup (both level 50) | Target |
|---|---|
| **BiS vs. completely naked** | ~**100%** — gear is not optional |
| **BiS vs. average gear** | **80–90%** |

✅ Scaling between levels 1–49 is explicitly **not a concern** — that gear is
transitional and gets replaced. **The endgame ceiling is what matters.**

✅ **The real goal is not a power number — it's that no single build wins.**
See §2.2; that is the acceptance criterion this whole document serves.

### 2.2 The anti-meta guarantee ✅⚠️ (the primary design constraint)

> *"I want to make sure that there doesn't just become one single unbeatable
> meta at level 50 that everybody rushes for."*

Three mechanisms, in order of importance:

**1. Archetypes counter each other in a loop, not a power ladder.** 📝
The game's identity is already counter-triangles (three of them, one per
element tier). Extending that to archetypes makes dominance *structurally*
impossible: every build has a predator. Proposed 5-cycle — and every link is
grounded in mechanics we've already built:

| Beats | Loses to | Why (real engine behavior) |
|---|---|---|
| **Aegis** → Emberwright | | Shields resolve at priority 3, nukes at 9 — the shield is up before the big hit lands |
| **Emberwright** → Thornwarden | | Burst kills before 3-tick burns and 1%/turn heals accumulate |
| **Thornwarden** → Tidebinder | | DoTs tick in the **end phase**, which priority manipulation can't touch — Waterlogged does nothing to damage that never rolls initiative |
| **Tidebinder** → Voidcaller | | Charge strips and tempo disruption slow Creeping Dark's growth — Dark stacks scale with charge spent, and a mage kept poor never reaches Dusk |
| **Voidcaller** → Aegis | | Shield counter-picking needs to see the enemy's element — hidden info means the ×2 math can't be played |

Each archetype beats one, loses to one, and is even with two. No apex.

⚠️ **Two caveats from the design review (2026-07-21):**

1. **The loop's justifications lean on archetype↔element pairings the
   two-axis system doesn't guarantee.** "Voidcaller beats Aegis because
   Shadow hides the element" only holds if the Voidcaller runs an Umbra
   enchant — under two-axis it could carry Pyro and hide nothing. ❓ Ruling
   needed: either the counter-guarantees come from the **set bonuses
   themselves** (e.g. Voidcaller's 5-piece natively grants an info-hiding
   effect, whatever its enchant), or §2.2's "structurally impossible to
   dominate" claim must be softened to "holds for the canonical pairings."
   The set-bonus route is recommended — it keeps the guarantee real.
2. **Precision fix (applied above):** the old Tidebinder→Voidcaller line
   claimed fizzles "break the streak" — but per §5.4's ruling, fizzled casts
   behave like charges: they don't advance streaks *or reset them*, and a
   fizzled Umbra cast still counts as Umbra activity (no Dark decay that
   turn). Electro *slows* Dark's growth; it doesn't reverse it. The edge
   exists, but it's thinner than first stated — worth watching in sims.

**2. Tech slots are the adaptation layer.** Neck, Ring, and the off-hand
carry situational counters (anti-DoT, anti-burst, shield-piercing,
anti-lifesteal). This is what stops any meta from being *unanswerable* — you
can always counter-pick without abandoning your 5-piece commitment.

**3. It's measurable — reuse the sim.** ✅ We already produced a 9×9
mono-element win-rate matrix that verified all six counter edges. The same
tool can run an **archetype round-robin at BiS**. Proposed acceptance
criterion:

> **No archetype may average above ~60% across the matrix, and none may beat
> every other archetype.** A row that beats all four is a meta; ship-blocking.

⚠️ **Caveat on reading sim numbers.** Today's AIs are effect-blind and play
close to randomly — they don't set up combos, bait triggers, or counter-pick.
So the matrix measures *raw stat interaction*, not strategy, and it will
under-represent any archetype whose strength is in decision-making
(Voidcaller's info war, Tidebinder's disruption). The criterion above only
becomes meaningful once the AI can actually play the archetypes (Phase 7 of
the type-effects work). **Until then, human playtest outranks the sim** — as
it already did for the "long duels are fun" finding.

📝 **Watch item: element-enchant parity.** If one *element enchant* is clearly
best, diversity dies on the second axis even with five balanced archetypes.
Arcane is the standout candidate — Arcane Knowledge is permanent, universal,
and never decays. ✅ Not treated as a blocker: **if it proves to be a
persistent problem, the fix is simply to reduce its % per stack.** Revisit
after playtest, not before.

---

## 3. The two-axis system 📝 (core proposal)

Christian's instinct — *"3 to 5 armor sets that can be enchanted to a specific
element"* — is the right architecture, and it's worth naming why:

> **The base set defines the ARCHETYPE. The element enchant defines the
> FLAVOR.**

- **Axis 1 — Archetype (5 armor sets):** *how* you fight. Burst, tempo,
  attrition, tank, trickster.
- **Axis 2 — Element enchant (9 elements):** *which* element's signature
  effect gets sharpened.

**Why this is the right call:** 5 sets × 9 elements = **45 distinct endgame
builds from only 5 art sets**. It sidesteps the alternative (nine bespoke
element sets), which would be 9 sets of art for *less* build variety and
would hard-lock every player into mono-element.

### 3.1 Archetypes ✅ (all five accepted; per-tier bonuses still draft 📝)

| Set | Fantasy | 3-piece | 4-piece | 5-piece (build-defining) |
|---|---|---|---|---|
| **Emberwright** | Burst — big charged nukes | +flat damage | +damage per charge spent | Your first 4+ charge spell each duel can't be Blinded or Staggered |
| **Tidebinder** | Tempo — disruption, speed | +priority utility | ⚠️ Streak thresholds −1 | ⚠️ Your streak effects fire one cast sooner |
| **Thornwarden** | Attrition — DoT/HoT | +HoT per turn | DoTs on you tick 25% weaker | Your damage-over-time effects last +1 turn |
| **Aegis Sovereign** | Tank — shields, survivability | +max HP | Shields +15% | Your shields keep 25% strength instead of shattering |
| **Voidcaller** ✅ | Trickster — info war, anti-magic | ? | ? | ? (bonuses TBD — see the A2 flag below: they must carry the info-war identity natively) |

⚠️ **CONTRADICTION TO FIX (review 2026-07-21): Tidebinder's 4-piece and
5-piece are the same bonus twice.** "Streak thresholds −1" and "streak
effects fire one cast sooner" are two wordings of one effect; a full set
would stack to −2 — Waterlog on **every** Aqua cast — directly violating
§7.1's hard cap ("thresholds drop by at most 1, never to every cast").
❓ One of the two tiers needs a different bonus (candidates: 4-piece becomes
"your streaks survive one fizzle/miss without resetting", or 5-piece becomes
"Tailwind's Haste grab also blocks the next Haste steal").

⚠️ Note the deliberate tension: **Emberwright pushes big spells** (aligning
with TYPE_EFFECTS §7's big-spell goal) while **on-hit weapons push multi-hit
spam**. That's healthy — equipment becomes the lever that keeps *both*
archetypes viable, rather than the meta collapsing to one.

### 3.2 Which slots carry a set? ✅

The **five armor slots** — **Hat, Robe Top, Robe Bottom, Boots, Gloves** — are
the set ("primary robe set") slots. **Neck, Ring, both hands and the Belt** are
always free for weapons, tech and utility.

⚠️ **The Belt never carries a set piece.** It is the one slot whose value is
not combat power, and folding it into a set would undo that.

This makes mix-and-match exactly as described: 5 armor slots with bonuses at
3/4/5 means you can run a full 5-piece, or **3+2** (one 3-piece bonus, the
other two pieces contribute only their raw stats), or **4+1**. Committing to
five is a real sacrifice — good tension.

---

## 3.4 Set tiers & how they're earned ✅

The five primary robe-set pieces unlock in **four tiers**, at levels **30,
40, 45, and 50**. Other gear fills the intermediate levels; the primary sets
follow this ladder alone.

| Tier | Level | Feel | Acquisition |
|---|---|---|---|
| I | **30** | First real set identity — 3-piece bonuses come online | Craft + standard materials |
| II | **40** | Solid mid-endgame power | Craft + enchant; higher-tier motes |
| III | **45** | ⭐ Noticeable jump | **Rare components from difficult enemies** + enchant + craft |
| IV | **50** | The ceiling (§2) | **Rarest components**, deepest skill requirement |

✅ **Each threshold must feel like a distinct jump in power**, not a smooth
ramp — these are the milestones the endgame is paced around.

### 3.5 The acquisition triangle ✅

Tier III and IV sets require **all three** of:

1. **Rare component drops** — obtainable *only* from difficult enemies. Not
   purchasable, not craftable from bulk materials.
2. **Enchanting skill** — at sufficient level to apply the element axis.
3. **Crafting skill** — at sufficient level to assemble the piece.

### 3.6 Monetization principle ✅ (the governing rule)

⚠️ **This rule is about REAL money — i.e. Resonance Prisms (RP), the premium
currency bought with cash. It is NOT about gold.** (Clarified 2026-08-02; the
earlier shorthand "money buys time, never access" was ambiguous and read as if
it constrained gold too.)

> ### The rule
> **Nothing purchasable with RP may be unobtainable with gold.**
>
> RP may buy **time** (shortcuts) and may even buy **gold** itself. There are
> **no RP-only functional items.** Cosmetics are the one exception and may be
> RP-exclusive.

✅ **Gold may absolutely buy access.** A rich player can buy Master-tier gear
at every tier from the Concord Market, and that is intended — gold is *earned
in-game*, so spending it is a legitimate route to power. The constraint is
purely on what **cash** can reach that gold cannot.

- ✅ **Allowed for RP:** skipping/reducing crafting, enchanting and conversion
  **cooldowns**; Time Crystals; faster node-charge replenishment; extra potion
  yield; better *odds* (Luck/drop-rate boosts); **buying gold**; cosmetics.
- 🚫 **Never for RP:** anything gold cannot also buy. In particular, **rare
  Tier III/IV components**, **skill levels**, or any step of a process. Every
  path must be completable — if slowly — without spending cash.

⭐ **What actually enforces the ceiling: tradability, not currency.** Since RP
converts to gold, RP effectively buys anything the *market* sells — so the
guardrail cannot be the price tag, it has to be **what is sellable at all**.
Rare Tier III/IV components are **Bound** (§6c) and can never be traded, so no
amount of cash reaches them. This is the same interlock as §9b.6a's *"the
market sells the floor, never the ceiling"* — and it is why that rule is
load-bearing for monetization, not just for loot design.

⚠️ **Therefore: any future decision to make a Bound item tradeable is a
monetization decision, not an economy decision.** It moves that item from
"earned" to "purchasable with cash" in one step.

---

## 4. What equipment can grant — the modifier vocabulary

Rated by how safely each can scale. ⚠️ flags need caps.

### 4.1 Safe / linear
- **Flat max HP** — the baseline stat (already engine-supported).
- **Flat damage** (per cast) — encourages committing to a hit.
- **Flat damage per hit** ⭐ — the multi-hit differentiator Christian wanted:
  +2/hit gives 4-hit Volley +8 but 1-hit Cataclysm +2. Cleanly makes Flurry
  and Volley *feel different* from a same-charge single spell. The engine
  already loops per hit and emits a `DamageEvent` each time, so this is a
  natural hook.
- **Shield strength %**, **heal %**, **Luck**.

#### 4.1a 📝 NEW — the six combat stats

Specified in GAME_DESIGN §1 "Combat stats"; these are their gear hooks. ⭐
**This is the main reason the stats exist** — equipment needed numbers to move
that weren't just flat damage, and defensive builds needed an axis other than
shields.

| Stat | Safety | Notes |
|---|---|---|
| **Accuracy** | ✅ safe | Stacks past 100% and stays useful — it's the **counter-pick to dodge builds** (a §2.2 tech-slot role) |
| **Dodge** | ⚠️ tune by content | No engine floor; 0% enemy hit chance is reachable by an all-in build. Keep it **temporary and unlikely** through item/spell design — see the GAME_DESIGN §1 warning about permanent lockout states |
| **Crit Chance** | ✅ build axis | See the note below — deliberately *not* jointly capped with crit damage |
| **Crit Damage** | ✅ build axis | Inert without crit chance, which is a natural brake |
| **Deflection Chance** | ✅ safe | Pure damage reduction, no attacker punishment (unless the reflection rider is equipped) |
| **Deflection Amount** | ⚠️ **hard cap 50%** for players | Enemies and bosses may be tuned past it |

✅ **Crit Chance × Crit Damage is a build axis, not a trap.** A
**low-chance / high-crit-damage** glass cannon chasing big hits should be
just as viable as a **high-accuracy / consistent** build. So budget the
**expected value** (chance × damage) across builds rather than capping either
stat — the goal is that both strategies land in the same power band by
different routes, which is exactly the archetype diversity §2.2 is protecting.

💡 The **reflection** rider (sending the deflected portion back at the
attacker) is the one piece here that *does* punish attacking, so it's the one
to watch for a passivity spiral — price it as a late-game perk, not a
baseline roll.

💡 **Elemental affinity for flavour, not mechanics:** let gear *roll* these
with an element lean — Aero favours dodge, Geo deflection, Electro crit
chance, Pyro crit damage, Solar accuracy — without giving any element a
second side-effect.

### 4.2 Powerful, needs caps ⚠️
- **Proc-chance modifiers** (e.g. Ignite 25% → higher) — see §7.1. **The
  single most dangerous lever in this design.**
- **Streak-threshold reduction** (Waterlog every 3rd → every 2nd) — see §7.1.
- **Shield piercing %** ("always phases through X% of shields") — see §7.2.
- **Set-linked DoT/HoT** — e.g. "your attacks apply a small burn." Fine, but
  it must route through the existing `TurnStatus` framework so lane ordering
  and the survivability-first rule hold.

### 4.3 Situational tech (belongs on swappable slots) 💡
- **Venom blood** — punishes an opponent's lifesteal (real targets exist:
  Sap, Leech, Drain).
- Anti-DoT, anti-Blind, anti-charge-strip counters.

📝 **Design principle:** *committed slots (the 5-piece set) get universal
value; swappable slots (Neck, Ring, off-hand) carry situational counters.* A
dead stat is acceptable on a ring you can swap; it's miserable on a set you
built toward for weeks.

---

## 5. Catalogue of every status & effect in the system

The definitive "what equipment can hook into" reference, as requested. All of
this exists in the engine today.

### 5.1 Element effects (the nine)

| Element | Effect | Trigger | Key numbers |
|---|---|---|---|
| Pyro | **Ignite** | 25% on hit (even if fully shielded) | 10% of raw damage, 3 ticks, lane E8 |
| Aqua | **Waterlogged** | every 3rd consecutive Aqua cast | +10 priority to their next action |
| Flora | **Photosynthesis** | every Flora cast | max 3 stacks, 1% max HP/stack, lane E2, decays without Flora activity |
| Electro | **Static Feedback** | 20% on hit | strips 1 charge (can fizzle their spell) |
| Aero | **Tailwind** | 3rd+ consecutive Aero cast | seizes Haste; 3+ streak = Stagger immunity |
| Geo | **Stagger** | every 4th consecutive Geo cast | their next offensive spell ×0.5 |
| Radiant | **Blind** | 10% per charge spent, on attack | 50% miss for 3 turns; clears Creeping Dark |
| Umbra | **Creeping Dark** | +1 stack per charge spent | cap 15; 5/10/15 = Shadow/Dusk/Midnight; decays |
| Arcane | **Arcane Knowledge** | 4+ charge Arcane cast | +5%/stack (max 5), permanent |

### 5.2 Cleanse / immunity web
Pyro's Ignite clears Photosynthesis · Aqua shields cleanse Ignite ·
Photosynthesis blocks Waterlogged · Geo shield grounds Static Feedback ·
Electro attacks scatter Tailwind · Tailwind 3+ shrugs off Stagger · Blind
burns away Creeping Dark · Dusk blocks Arcane Knowledge · Arcane spells are
immune to Blind.

### 5.3 Per-mage state equipment could touch

| Field | Meaning |
|---|---|
| `maxHp` / `hp` | health (already gear-modifiable by design) |
| `charge` (0–5) | charge; cap is level-gated |
| `shield` | one slot: elemental (strength) or Barrier |
| `empowerMultiplier` | pending ×N damage on next offensive spell |
| `quickenPriority` | pending priority override |
| `phaseNext` | next offensive spell ignores shields |
| `hasHaste` | the initiative token (breaks same-priority ties) |
| `concealed` | charging element hidden (Umbra Shadow) |
| `priorityPenalty` | +priority to next action (Waterlogged) |
| `nextOffensiveDamageScale` | ×N on next offensive spell (Stagger) |
| `bonusDamagePercent` | additive damage % (Arcane Knowledge) |
| `streakElement` / `streakCount` | consecutive-cast streak |
| `activeElementThisTurn` | drives activity-based stack decay |
| `statuses[]` | active `TurnStatus` list (DoTs/HoTs/stacks) |

### 5.4 Spell effect types (what a spell can do)
`DamageEffect` (min, max, **hits**, lifesteal, ignoresShields) ·
`BarrageEffect` (per charge spent) · `OverloadEffect` (per *enemy* charge) ·
`ShieldEffect` · `BarrierEffect` · `EmpowerEffect` · `QuickenEffect` ·
`PhaseEffect` · `HasteEffect` · `DischargeEffect`

### 5.5 Timing structure (where an effect can live)
- **Phases:** Start (S1–S10) → Main (1–10) → End (E1–E10). Lanes never mix.
- **Main-phase priority:** instant 1 · shield 3 · channel 4 · quick 5 · aux 7
  · regular 9. Haste breaks same-priority ties.
- **End-phase bands:** heals E1–E3 → damage E4–E8 → bookkeeping E9–E10
  (survivability-first: heals land before burns).
- **Precedence on a committed action:** fizzle → priority mod → miss →
  damage mods (additive, then multiplicative).
- **Fatigue:** from turn 51, escalating unblockable damage (+3/turn).

### 5.6 Statuses currently implemented
`IgniteStatus` (DoT) · `PhotosynthesisStatus` (HoT + stacks) ·
`BlindStatus` (miss chance) · `CreepingDarkStatus` (info-hiding stacks) ·
`ArcaneKnowledgeStatus` (permanent damage stacks)

---

## 5b. Proposed new statuses & mechanics 📝

Not yet implemented. Grouped by what they'd cost to build, since some are
data and some are real engine work.

### 5b.1 The lockout family — "can't do X for N turns"

| Lockout | Blocks | Naturally counters |
|---|---|---|
| **Silence** | offensive spells | Emberwright (burst) |
| **Bind** | charging | anything building toward a big spell (Emberwright, Arcane) |
| **Sunder** | shields | Aegis Sovereign (tank) |
| **Seal** | consumables | potion-reliant play |

⭐ **These are counter-picks, not raw power** — each one shuts down a specific
archetype. That makes them the ideal contents of the **tech slots** (Neck,
Ring, off-hand), which §2.2 identifies as the adaptation layer that keeps any
meta answerable. Per §4.3's principle, they'd be miserable as 5-piece set
bonuses (dead weight against the wrong opponent) and excellent as swappable
counters.

✅ **Cheap to build:** the engine already fizzles a committed spell it can no
longer legally cast (§5.5 precedence: fizzle → priority → miss). A lockout is
just "this *category* of action fizzles for N turns," slotting into the
existing gate.

✅ **Stacking: designed around one, but multiples are allowed.** The *system*
assumes a single lockout at a time — that's the balance baseline. But if a
player manipulates turns and mechanics well enough to land two or three, that
is a **legitimate, earned outcome**, not something to block. It should be
very difficult to pull off; it should not be impossible.

📝 Consequence: **do not cap lockouts artificially.** Keep durations short
(1–2 turns) and make application costly, so stacking requires real setup
rather than falling out by accident.

✅ **This makes the compelled-forfeit rule load-bearing, not a safety net.**
Because full lockout is now *reachable by design*, the engine must
distinguish **two kinds of forfeited turn** — see
[GAME_DESIGN.md](GAME_DESIGN.md) §1:

- **Timeout forfeit** (too slow / disconnected) → counts toward the 3-strike
  auto-surrender.
- **Compelled forfeit** (no legal action existed) → **does not count.**

Being locked out is not the same as being asleep. A fully-locked player still
takes damage and can still lose the duel outright — which is the *correct*
payoff for a hard-earned lockout chain — but they must never be marched
toward an auto-surrender for a turn they were never allowed to take.

📝 `DuelController.forfeitLimit` counts every `ForfeitAction` today; this
distinction is a **hard prerequisite** before any lockout ships.

⚠️ **Netcode prerequisite (review 2026-07-21):** the wire protocol encodes
exactly one forfeit token (`'F'`), and in commit-reveal it is the
**opponent's client** that counts your forfeits. So compelled-vs-timeout must
be distinguishable on the wire (a second token or a flag) — *and* the claim
must be **verifiable**: a cheater could mark every timeout "compelled" to
dodge the auto-surrender, so the receiving client must check the claim
against visible state (the opponent's statuses and loadout are known;
"I had no legal action" is computable). Also applies to `TunableAi`, which
returns `ForfeitAction` when nothing is playable — that is a compelled
forfeit and currently counts toward the streak.

### 5b.2 Endurance (death save) 📝

*If a hit would kill you, survive at 1 HP instead.*

- Hooks cleanly into damage application — the engine funnels all damage
  through one place (`_applyOneHit` → `takeHpDamage`), so this is a single
  guarded branch.
- ✅ **As a spell (Endure):** freely recastable, and re-casting **refreshes —
  never stacks.** Same semantics as Ignite and Blind, so it needs no special
  rules.
- ✅ **As an item:** some gear may grant a "life save," but such items either
  **break on use** or must be **recharged**. Consumed resources, not a
  permanent property — so nothing needs hard-coding into the base rules.
- ✅ Saves against any lethal damage, **Fatigue included** — and since Fatigue
  escalates every turn, that only ever buys one more turn. Self-balancing; no
  special case required.
- ✅ Interacts fine with our instant-death rule and with DoTs: an Ignite tick
  that would kill leaves you at 1, and the next tick finishes the job.
- 💡 Great PvP moment — surviving a lethal Cataclysm at 1 HP is exactly the
  kind of beat that makes a duel memorable.

### 5b.3 Charge retention ⚠️ (highest-impact item on the list)

*Cast a spell costing less than your charge and keep the remainder — e.g.
cast a 1-cost spell at 4 charge, keep 3.*

✅ **"Charge spent" is always the cast spell's actual cost.** Charge to 5, cast
a 2-cost spell → 2 was spent; with retention you keep 3.

✅ **No bounds.** Charging to 5 and casting Flick repeatedly *is* allowed with
retention. The counterplay is already in the game and it is sharp:

- **Overload** deals 8–12 **per point of the enemy's charge** — a mage parked
  at 5 charge is offering a 40–60 damage target, on a 2-cost spell.
- **Discharge** wipes the whole reserve outright.
- Flick is 4–6 damage; chipping at that rate takes 20+ turns against 100 HP,
  well inside Fatigue's reach at turn 51.

Sitting on a full reserve is loud and punishable, so the "abuse" case is
really a **standoff the opponent has strong tools against** — it doesn't need
a rule to forbid it.

🚫 **Retention is NOT the default rule.** The base game keeps "casting
consumes ALL charge" (GAME_DESIGN §1 rule 3) exactly as it is. Retention is a
**special case granted by high-level equipment only** — a late-game modifier,
not a change to core combat. Nothing before the endgame should retain charge.

✅ **Where retention does apply, it keeps the element cycle OPEN.** Retained
charge means the element stays locked and the cycle continues; you do not
re-pick. This is the coherent reading (the engine's invariant is
charge > 0 ⇒ element locked).

⚠️ **So the item grants two powers, and must be priced for both.** Keeping
the cycle open means **you never re-pick your element and streaks compound
across casts** — retention gear is quietly also a mono-element subsidy. Every
streak mechanic gets easier to sustain:

| Mechanic | Effect of a never-breaking cycle |
|---|---|
| Aqua — Waterlogged (every 3rd) | Proc rate approaches its ceiling |
| Aero — Tailwind (3rd onward) | Haste grab + Stagger immunity become permanent |
| Geo — Stagger (every 4th) | Sustained |
| 📝 Sanctus — Absolution (every 3rd) | Sustained |

✅ **Every-cast procs are an intended endgame outcome** — retention gear plus
Tidebinder's −1 threshold is *meant* to get some streaks firing every turn
for a player who commits their whole build to it. See the revised §7.1, which
replaces the old blanket "never to every cast" rule with a **per-effect
allowlist**: some streaks may reach every-cast, and a named few may not.

⚠️ **Needs a sim re-run when implemented**, alongside the §5b.3a
"charge spent = cost" change, which is the other half of this mechanic. The
every-turn-proc build becomes the **new balance ceiling** and must be simmed
explicitly, not inferred.

### 5b.3a ✅ Adopted: "charge spent" = the spell's cost, engine-wide

Defining spent-charge as **the spell's cost** is not only a retention rule —
it changes three shipped Tier 3 effects for *all* players, retention or not:

| Effect | Today (spent = all charge consumed) | Under the new definition (spent = cost) |
|---|---|---|
| **Radiant — Blind** (10%/charge) | Charge to 5, cast 1-cost Bolt → **50%** blind chance | → **10%** |
| **Umbra — Creeping Dark** (+1/charge) | Same cast → **+5** stacks | → **+1** |
| **Arcane — Arcane Knowledge** (4+ charge) | Any cast at 4+ charge qualifies | Only spells **costing** 4+ qualify |

✅ **Adopted as a general engine rule.** "Charge spent" is the **cost of the
spell cast**, never "charge lost." The two are usually identical — casting
consumes everything — but they diverge under charge retention, and the cost
is the meaningful number.

Consequences, accepted deliberately:
- It **nerfs overcharging** as a way to farm Blind procs and Dark stacks.
- It **tightens Arcane Knowledge** to genuinely expensive spells (Ruin,
  Cataclysm, Sanctuary, Drain), which fits its "big-spell element" identity.
- ⚠️ **Needs a re-run of the balance sim** (the 9×9 mono-element matrix) when
  implemented — Radiant and Umbra both get quieter, and both were already
  under-performing against effect-blind AI.

📝 Implementation note: `_triggerElementEffects` currently receives
`chargeSpent = caster.charge` captured at cast time. It becomes the spell's
cost (with xCost spells still reading the charge they actually consume).

### 5b.4 Sustained spells & the interrupt mechanic 📝 (largest engine addition)

*2–3 attacks (or defenses) that grow stronger each turn but can be
interrupted.*

⚠️ This is a **new action type**, not a status — the engine currently assumes
every turn's action resolves and completes within that turn. Actions today
are charge / cast / forfeit; sustaining adds a multi-turn commitment.

✅ **All three variants are wanted** — they're distinct mechanics, not
alternatives, and each should eventually become spells:

| Variant | Shape | Interrupt costs you |
|---|---|---|
| **Beam** | Damages each turn, **growing ~50% per turn**; **discharges 1 charge per turn** to sustain | Only the remaining escalation — partial payoff already banked |
| **Channelled** | Costs ~4 charge up front, runs ~4 turns | The rest of the channel |
| **Prepared** | ~3 charge, spends one turn **preparing**, lands the following turn | Everything — nothing has landed yet |

💡 Nice property: they sit at different risk/reward points, so they're not
redundant. **Beam** is a resource drain that pays continuously, **Channelled**
is a commitment with a duration, and **Prepared** is the high-stakes
telegraphed haymaker — the most interruptible, and so the biggest mind-game.

📝 The **Beam's per-turn charge cost** is a neat self-limiter: it can't run
forever, and it visibly drains the reserve the opponent can see — which also
plays into Overload/Discharge counterplay.

**The interrupt** is the necessary counterpart, and note it's the same family
as §5b.1: an interrupt is a **targeted, instant lockout**. ✅ Three sources:

| Source | Shape |
|---|---|
| **Disrupt** | A dedicated **aux** spell — pure interrupt, cheap |
| 💡 A damaging interrupter | A spell that deals damage **and** interrupts — costlier, two jobs in one |
| ⭐ **Stagger** (Geo) | The existing Tier 2 effect **also interrupts** |

📝 Giving Stagger the interrupt property makes **Geo the anti-sustained
element** — thematically perfect (a concussive blow breaks concentration) and
a free identity win, since it reuses an effect that already exists.

⚠️ Balance note: this is a real buff to Geo, which was already among the
stronger rows in the mono-element matrix (beating Aqua 81%, Electro 77%,
Umbra 78%). It's *situational* — worth nothing unless the opponent is
sustaining — so it likely doesn't move the matrix much, but re-check Geo's row
once sustained spells and the new charge-spent rule are both in.

💡 **Why this fits the game well:** sustaining is *visible* to the opponent,
exactly like charging is. That telegraph creates the mind-game — do I race
them down, or spend my turn interrupting? — which is the same simultaneous-
commit tension the duel is built on, applied to a new axis.

⚠️ Netcode note: commit-reveal handles this fine (a sustaining player just
commits "continue"), but multi-turn actions touch the turn resolver, the move
timer, and the forfeit/disconnect rules — the most invasive change proposed
in this document.

---

## 6. Elemental motes & the crafting economy 📝

Christian's Skyrim-soul-gem model, adopted.

- **Motes** are the crafting currency for high-tier gear. Each is either
  **element-bound** (Pyro, Aqua, …) or **neutral/unattuned**.
- ✅ **Five tiers — the Crystallization ladder:**

  > **Dust → Shard → Crystal → Core → Heart**

  Element-neutral (works for all nine), unambiguous ordering, and reads well
  in an item name: *"Pyro Dust", "Aqua Crystal", "Umbra Heart."* "Mote"
  remains the category term; items are named `<Element> <Tier>`.

### 6.0 The refinement ladder ✅

| Conversion | Cost |
|---|---|
| Dust → **Shard** | **50** dust |
| Shard → **Crystal** | **20** shards |
| Crystal → **Core** | **12** crystals |
| Core → **Heart** | **4** cores |

Cumulative cost of one Heart, refined from the bottom:

| Tier | In Dust | In Shards | In Crystals |
|---|---|---|---|
| Shard | 50 | — | — |
| Crystal | 1,000 | 20 | — |
| Core | 12,000 | 240 | 12 |
| **Heart** | **48,000** | **960** | **48** |

✅ **The steepness is deliberate, and it works because every tier below Heart
drops directly** — at escalating rarity:

| Tier | How you get it |
|---|---|
| **Dust** | Fairly common — the baseline drop |
| **Shard** | Occasionally found |
| **Crystal** | Rare |
| **Core** | Incredibly rare; possibly never drops |
| **Heart** | ⭐ **Crafting only** — never drops |

So the ladder isn't a 48,000-dust grind: it's an **exchange between tiers of
abundance**. A player farms plentiful Dust and occasional Shards, and the
ratios convert that abundance into the scarcity a Core demands. Drops of the
higher tiers shortcut the climb; refinement tops up whatever luck didn't
provide.

📝 Consequence worth designing around: **a Heart is a guaranteed, planned
achievement, not a lucky one.** No amount of good fortune hands you a Tier IV
set — every Heart is assembled deliberately. That makes the level-50 set feel
earned rather than rolled, and it means Heart-tier progress can be shown to
the player as a **visible progress bar** (48 crystals of 48), which is far
more motivating than an invisible drop chance.

### 6.0b Neutral → element conversion ✅

Neutral motes are the flexible currency: usable in any recipe, but at a
conversion penalty — so no drop is ever dead loot. **The rate improves with
Enchanting level**, which gives the skill value well beyond just applying
enchants:

| Enchanting level | Neutral : Element |
|---|---|
| default | **4 : 1** |
| 20 | 3 : 1 |
| 30 | 2 : 1 |
| 40 | 3 : 2 |
| **50** | **1 : 1** |

✅ **Conversions are rate-limited by cooldown, not by a wait timer** — you get
the motes *now*, but can't convert again for a while. (Chosen deliberately
over a build-timer: instant gratification, with the throttle on repetition.)

✅ **Cooldown length is a per-recipe property**, scaling with the **tier** of
the crafting being performed — so a Dust→Shard conversion is quick and a
Core→Heart is a serious commitment. Set per recipe in data, not globally.

### 6.1 Where motes come from ⭐
`world.dart` **already assigns elements to regions** (e.g. Geo+Aero, Aqua+
Radiant). So mote drops fall out of existing data for free:

- A region's monsters drop motes of **that region's elements**; neutral motes
  drop everywhere.
- ✅ **Motes come from BOTH combat and gathering** (ruling, 2026-07-25).
  Combat is the steady, predictable source — a region's monsters drop motes of
  that region's elements. Gathering is the *irregular* one: motes appear as
  **random drops and random events** while working a node, not as a guaranteed
  yield per swing. A Pyro-attuned vein sometimes gives up Pyro Dust alongside
  its ore.
  ⭐ The asymmetry is deliberate: a fighter can *plan* their mote income, a
  gatherer *stumbles into* it. Neither path is closed, and neither is a
  reliable substitute for the other, so the top of the crafting tree still
  rewards doing both without demanding it.
- Mote **tier scales with monster (or node) level**, not player level — so
  farming low-level zones yields low-tier motes (mirrors the
  PROGRESSION_DESIGN rule that crafting XP scales with material tier, not
  player level).
- ✅ **Concrete rates live in per-monster / per-level loot tables**, decided
  alongside the monster catalogue rather than as a global curve.
- ✅ **Post-cap XP converts to motes** — the daily-play hook. At **level 50**,
  excess XP converts at **10 XP → 1 Dust**, capped at **250 Dust per day**
  (= 2,500 XP/day). Presumed **neutral** Dust, since XP carries no element;
  players route it through the §6.0b neutral→element conversion.

  📝 **What that cap is actually worth**, against the §6.0 ladder — useful
  because the number reads generous but isn't:

  | From dailies alone | Time at the cap |
  |---|---|
  | 1 Shard (50 Dust) | ~5 per day |
  | 1 Crystal (1,000) | 4 days |
  | 1 Core (12,000) | ~7 weeks |
  | 1 Heart (48,000) | **~6 months** |

  ⭐ **Read that table as a floor, not a rate.** It's XP conversion **alone**;
  monsters still drop motes as ordinary loot the entire time, and that
  remains the main line. The daily conversion is a *supplement* that
  guarantees a maxed player always banks something, however they spend the
  session — consistent with §6.1's rule that every tier below Heart drops
  directly and Hearts are craft-only.
  📝 **2,500 XP/day is fine as a starting number**; expect heavy tuning once
  the XP curve and the drop tables both exist and can be measured together.

### 6.2 The three verbs (already stubbed in the UI)
- **Transmute** — refine raw materials up a tier (and 💡 convert neutral →
  element-bound, or combine lesser motes into greater ones).
- **Craft** — materials + motes → equipment.
- **Salvage** — equipment → components (proposal: returns motes at a loss,
  making bad drops into progress rather than vendor trash).

### 6.3 Enchanting
Applies the **element axis** to a base item: consumes element-bound motes of
the target element. Proposal: enchants are **rewritable at a cost**, so a
player can re-attune a hard-won 5-piece set as their build evolves — this is
what makes the two-axis system feel freeing rather than punishing.

---

## 6a. Skills ✅ (structure settled, detail tabled)

Skills live **outside player level**, in two types:

| Type | Skills | Produces |
|---|---|---|
| **Gathering** (3) | **Mining** · **Felling** · **Foraging** | Raw materials |
| **Processing** (6) | **Tailoring** · **Potions** · **Enchanting** · **Jewelry** · **Metalworking** · **Woodcarving** | Finished goods |

✅ Detailed design (XP curves, level caps, unlock tables) is **tabled** — the
structure above is what the item system is built against for now.

📝 Notes:
- **"Tailoring"** rather than a generic "crafting" is apt: this is a game of
  robes, hats and gloves. It also frees the name space for other makers.
- **Motes come from combat *and* gathering** (§6.1) — steadily from the first,
  as random drops and events from the second. High-tier crafting still wants
  both fighting and skilling, since gathering alone will not supply motes at a
  rate you can plan around.

### 6a.1 Skill → slot coverage ✅

Every slot now has a maker, and every gathering skill has a sink:

| Gathered from | Processed by | Produces | Slots |
|---|---|---|---|
| Foraging (fibers/cloth) | **Tailoring** | robes & armor | Hat, Robe Top, Robe Bottom, Boots, Gloves |
| Foraging (herbs) | **Potions** | consumables | — |
| Mining (gems) + other reagents | **Jewelry** | rings & amulets | Neck, Ring |
| Felling (wood) | **Woodcarving** | staves & wands | Main hand, Off hand |
| Foraging (hides/leather) 📝 | **Tailoring** | ⭐ **belts** | Belt |
| Mining (ore) | **Metalworking** | refined metal — ingots, fittings, settings | ✅ feeds other recipes |
| Combat + gathering (motes) | **Enchanting** | the element axis | applies to any gear |

✅ **Metalworking is the refinement lane for Mining** — it turns ore and other
mined goods into refined outputs, and **many of those outputs are inputs to
other recipes** (a staff needs a ferrule; a ring needs a band).

This makes the skill tree an **interdependent economy rather than six
parallel silos**: Mining feeds both Jewelry (gems) and Metalworking (ore),
and Metalworking in turn feeds Woodcarving and Jewelry. 💡 It also gives the
tree a natural trading hub — refined metal is the obvious commodity for
player-to-player trade, since it's an input everyone needs and nobody's
build depends on hoarding.

---

## 6c. Tradability ✅

Three tiers, applying to every item and material:

| Tier | Meaning | Typical use |
|---|---|---|
| **Tradeable** (default) | Freely bought, sold, given | Raw materials, common/uncommon gear, low-tier motes |
| **Untradeable** | Not tradeable *as-is*, but a mechanism exists to release it | Crafted gear, mid/high-tier motes |
| **Bound** | Permanently untradeable | ⭐ Tier III/IV rare set components |

✅ Putting the **Tier III/IV rare components in "Bound"** closes the loophole
flagged in §3.5: if those were tradeable, gold could buy what rare drops were
meant to gate, quietly undoing §3.6's rule that nothing bought with RP may be
unobtainable with gold.

✅ **Release mechanism: an "unbinding" enchant.** Untradeable items are freed
by applying a dedicated enchant — putting the mechanism in the **Enchanting
skill** rather than behind a paywall.

⭐ Two benefits: it's **skill-gated, not premium-gated**, so the
pay-for-access hole stays shut (§3.6); and it gives Enchanting a third job
alongside applying the element axis and improving mote conversion — making it
the most load-bearing processing skill, which suits its endgame role.

---

## 6b. Alchemy, potions & consumable slots ✅📝

A **third skill** alongside Crafting and Enchanting: **Alchemy** — brewing
potions from ingredients.

### 6b.1 What potions do

| Category | Use | Where |
|---|---|---|
| **Long real-time boosts** | +Luck, +drop rate, for a real-world duration | Out of combat |
| **Restoration** | Heal between encounters | Campaign runs |
| **Loot insurance** ⚠️ | Preserve loot on death | Campaign runs |
| **Combat utility** | Healing, removing buffs/debuffs mid-duel | In a duel |

#### 📝 TODO — timed buffs and *hidden* statuses (playtest note, 2026-07-23)

Two related mechanics to design here, not yet specified:

1. **Real-time durations, in minutes.** Out-of-combat buffs measured in
   wall-clock time rather than turns — lasting **X minutes and stacking up to
   a ceiling** (an early figure was 60 minutes; ⚠️ some may run as long as a
   **week**). ❓ Open: does the clock run while logged out? A week-long buff
   almost certainly must, or it becomes a login-timer chore.
2. **Hidden statuses.** Effects the opponent cannot see until they trigger —
   the example being **Venom Blood**: the enemy doesn't know you have it until
   they lifesteal off you and get punished. ⚠️ Note this is the *inverse* of
   Umbra's info-war, which hides **your** state from them; this hides a
   **trap** in yours. It needs its own reveal rule (revealed on proc? on
   inspect? never?) and a HUD treatment that doesn't leak its existence.
3. **Three magnitudes: Minor / Major / Extreme.** A shared tier vocabulary for
   both of the above — presumably mapping onto the rarity ladder (§8) and the
   Alchemy skill level that can brew each.

⚠️ **Engine gap:** every status today is *turn*-scoped and duel-scoped
([TurnStatus]). Real-time, cross-duel, persisted-to-profile buffs are a new
category — they belong on the **player profile**, not `MageState`, and need
their own expiry sweep on load. Budget that before promising week-long buffs.

### 6b.2 Consumable slots ⭐ ✅

> *"a limit of four item slots that potentially could raise up to eight or
> ten… those item slots could also be added with equipment."*

A deliberately **bounded** consumable inventory, so a stack of 100 potions
can't stall the game out. Baseline **2–4 slots** (per the later backpack
ruling — an earlier draft said 4), growing to **8–10** through progression
and **equipment bonuses**.

Why this is the right call:
- It's the upstream fix for potion-spam — Fatigue (turn 51) bounds a stalled
  duel, but slot limits stop it from starting.
- "Which four do I bring?" is a genuine loadout decision, mirroring the
  element/spell slot pool players already reason about.
- ⭐ It gives equipment a **non-combat-power axis**: +1 consumable slot is
  meaningful build value that doesn't inflate damage or HP, which is exactly
  what a system worried about power creep (§2.2) wants more of.

✅ **Two layers: backpack + equipped slots.**

- Your **backpack** is the general inventory — carry as many potions as you
  like on an adventure.
- Your **consumable slots** (starting at ~2–4) are what you can actually
  *use* in a duel. You load them from the backpack **before the duel starts**.
- On a run, you **replenish the slots from the backpack between duels** — so
  packing deep still matters, but no single fight can be potion-spammed.

⭐ This is the best of both readings: the *duel* is tactically bounded, while
the *run* stays a strategic resource-management problem (how much do I carry,
and how fast am I burning it?).

✅ **Backpack capacity: 20 items**, expandable with **craftable expansion
pouches** for particular item types — another job for **Tailoring**, which
now makes robes *and* the bags that carry everything else. The cap is what
makes a long expedition a real planning exercise: potions competing with loot
for space is exactly the "bank it or push deeper?" pressure the campaign is
built on.

### 6b.3 Combat potions — the critical ruling ✅

✅ **A potion costs your action for the turn.** Using one is your move,
resolving at a priority like any other action — so every potion is a real
decision (heal or attack?), never a freebie.

✅ Potions come in three scopes: **in-combat**, **out-of-combat**, and some
that **only make sense in single-player** (e.g. loot insurance, between-
encounter healing). ✅ **No consumables at all in Academy mode** (§7.6).

✅ **Potions resolve at priority 3** (the shield band). So a healing potion
*usually* lands before an incoming attack — but an **instant move (priority
1) still beats it**, which keeps a read-and-punish window open.

✅ **Status-pipeline interactions:** potions **can be slowed by Waterlogged**
(+10 priority, like any action) but **cannot be fizzled** (they cost no
charge) and **cannot miss from Blind** (they aren't spells).

✅ **RESOLVED — a potion is an ordinary action.** No special simultaneity
group, no bespoke sort rule: a potion competes at **priority 3** against
every other action at that priority, and **Haste breaks ties** exactly as it
does for two spells. Nothing new to specify, which is the point — the
existing ordering already covers it, and the fewer special cases the
resolution pipeline has, the fewer places a lockstep desync can hide.

⚠️ **Healing must be worth less than an equivalent-tier attack deals**, or
turtling behind potions becomes a dominant, duel-lengthening strategy.

### 6b.4 Loot insurance ⚠️ (highest-risk potion)

A potion that saves loot on death directly defuses the campaign's core
tension — the designed "bank it or push deeper?" gamble, where defeat costs
the whole run. If a cheap potion removes that risk, the decision stops
mattering.

✅ **Partial protection, not blanket immunity** — the potion preserves either
a **percentage of your loot** or a **fixed number of items** (e.g. "keep 3").
Either shape keeps the "bank it or push deeper?" gamble intact: you're
hedging the loss, never erasing it.

💡 "Keep X items" is the more interesting of the two, since it forces a second
decision — *which* items are worth the slot — and it scales gracefully:
low-tier insurance keeps 1, endgame insurance keeps several.

---

## 6d. Gem sockets 📝 (needs refinement)

Status: 📝 **draft — the idea captured, the shape sketched, the numbers open.**

> High-level weapons and equipment roll **0–3 gem slots**. Gems are cut by
> **Jewelry** from a stone plus a **Crystal / Core / Heart**, and socketing one
> grants a bonus — `+health`, `+% damage`, `+flat damage`, and possibly **one
> status per element**, piggybacking on the enchanting system.

⭐ **Why this earns its place: it adds a BiS axis that is about the *item*, not
the stat roll.** Today best-in-slot is "the right piece with the right enchant."
Sockets make it "the right piece with **three** slots" — a genuinely different
hunt, because slot count is a property of the drop and cannot be crafted onto it.
A 3-slot blue can beat a 1-slot purple, which is exactly the kind of inversion
that keeps loot interesting long after the level cap.

### 6d.1 ⚠️ Naming collision — resolve this first

**"Gem" meant three different things. ✅ Resolved by renaming the currency:**

| Meaning | Where | Status |
|---|---|---|
| ~~Premium currency~~ | ~~`PlayerProfile.gems`~~ → ✅ renamed **Resonance Prisms** (`resonancePrisms`) | resolved |
| **Socketed elemental stone** | The Concordant Crown's *"twelve empty gem slots"* and *"twelve elemental gems"* (GAME_DESIGN §3a) | in design |
| **Socketed equipment stone** | this section | proposed |

The second and third agree with each other — ⭐ **the Crown is simply the
capstone of this system**, a twelve-slot item at the end of a game that taught
you sockets on ordinary gear. That unification is worth having.

The collision is with the **premium currency**, and ✅ **the ruling is to rename
that**, not the stones — the socket meaning is used in two places already and is
central to play, while the premium currency is one `int` and a label.

✅ **The premium currency is RESONANCE PRISMS ("RP").**

- It is a **raw material**: Time Crystals are *crafted from* RP. RP is not
  itself a Time Crystal, and the two are not interchangeable.
- ✅ **The art does not change** — same purple diamond, same colour
  (`AppColors.gem`, `0xFF8B5CD6`). Only the name moves.
- ✅ Renamed in code: `PlayerProfile.gems` → `PlayerProfile.resonancePrisms`,
  and the persisted JSON key with it.
- ⭐ *Resonance* is doing real work in the name — it reads as a property of magic
  rather than a mineral, which keeps it clear of the twelve elements, the mote
  ladder, and equipment gems all at once. "RP" is short enough for a currency
  chip in the HUD.

✅ **This closes GAME_DESIGN open question #10.** The word *gem* now means one
thing everywhere: a socketed stone.

### 6d.2 📝 How a gem is made

Follows the mote ladder already settled in §6.0, so it needs no new economy:

| Gem tier | Costs | Rarity it fits |
|---|---|---|
| **Lesser** | cut stone + **Crystal** (uncommon) | Green / Blue gear |
| **Standard** | cut stone + **Core** (rare) | Purple |
| **Greater** | cut stone + **Heart** (epic) | Orange / Iridescent |

- **Jewelry** is the skill, which is already sited at **Rimeholt** ("the deep
  stone is where gems come from") — so the crafting geography needs no change.
- A gem is **element-bound** by the mote that made it, which is what lets it
  carry that element's status.

### 6d.3 📝 What a gem can grant

Two families, and the split matters for §2.2:

| Family | Examples | Note |
|---|---|---|
| **Universal** | +health, +flat damage, +% damage | Safe, linear, boring on purpose |
| **Elemental** | one signature status per element, per §5.1 | ⚠️ The interesting half, and the dangerous one |

⚠️ **Universal gems are an anti-meta hazard.** If `+% damage` is sluttable by
anyone into anything, every player socks the same three gems and sockets become
a stat tax rather than a decision. The §2.2 anti-meta guarantee wants the
opposite. Two candidate fixes, both need testing:

1. **Element-lock the strong ones** — the biggest bonuses only come on elemental
   gems, so socketing commits you to elements you actually run.
2. **Diminishing returns per repeated gem** — a second identical gem gives less,
   pushing toward mixed sockets.

### 6d.4 ⚠️ Risks this must be tested against

- **The power budget (§2.1).** This is a **third** multiplicative axis on top of
  set bonuses and enchants. Three Greater gems on every one of nine slots is 27
  sources of bonus. The budget was not written with that in it — ⚠️ **re-sim
  before committing.**
- **Proc rates (§7.1).** Element statuses on gems multiply the number of proc
  sources on a single mage. §7.1 already names proc stacking as the biggest
  balance risk in the document; this makes it bigger.
- **PvP gear gap (§7.4).** Socket count is unbounded loot luck, which widens the
  gap the two-ladder rule exists to manage.

### 6d.5 ❓ Open questions

| Question | Why it matters |
|---|---|
| Are gems **removable**? | If not, a 3-slot BiS piece with wrong gems is ruined and the chase feels punishing. If freely, gems become currency. ⭐ The **unbinding enchant (§6c)** already exists as machinery — reuse it: removal is possible, costs an unbind, and destroys either the gem or nothing depending on the ruling. |
| Slot-count distribution | What fraction of drops roll 3 slots decides whether it is a chase or a wall |
| Do sockets appear below a rarity floor? | Sockets on White gear would flood the market with cheap fodder |
| Can sockets be **added** to an item? | A "socketing" recipe would make slot count craftable — which destroys the point of it being a drop property |
| Does the Concordant Crown use the same gems? | ⭐ It should. Twelve elemental gems, one per element, is the same system at maximum scale |

---

## 7. Balance guardrails ⚠️

### 7.1 Proc rates and streak thresholds — the biggest risk

Christian's examples: *Pyro robe → 50% Ignite instead of 25%*, and
*"waterlogs every turn instead of every third Aqua cast."*

**Why this needs a hard cap:** the nine element effects are balanced against
each other in three counter-triangles, and the sims already showed how
sensitive that is (Flora dominating at 3 stacks until decay + a cap tamed
it). Doubling a proc rate doesn't just improve one matchup — it inflates that
element against *all eight others*, breaking the triangle math.

The Waterlog example is the sharpest case: Waterlogged means *"your next
action resolves dead last."* Every third cast, that's a tempo swing. **Every
turn, it's a permanent lock — the opponent never acts first again.** That's
not a buff, it's a different (and unfun) game.

⚠️ **REVISED 2026-07-22 — "never to every cast" is no longer absolute.**
Christian's ruling: *some* streaks **may** become proccable every turn with
the right high-level gear. Every-cast procs are now an **earned endgame
outcome**, not a forbidden state — the payoff for committing an entire build
(full set + retention gear) and giving up every other bonus to get it.

📝 **But the Waterlog reasoning above still stands for a subset**, so the
blanket rule is replaced by a **per-effect allowlist**. The test is simple:
*does firing every turn create a state where the opponent no longer
meaningfully gets to play?*

| Effect | Every-cast at endgame? | Why |
|---|---|---|
| **Aero — Tailwind** | ✅ allow | Permanent Haste + Stagger immunity is strong, but the opponent still acts |
| **Flora — Photosynthesis** | ✅ allow | It's a stacking heal with a cap; no lockout |
| 📝 **Sanctus — Absolution** | ✅ allow | Permanent cleanse is a hard counter to status decks, not to *playing* |
| **Aqua — Waterlogged** | 🚫 **cap at −1** | *"Your next action resolves dead last"* every turn = **the opponent never acts first again.** The original argument holds: this isn't a buff, it's a different and unfun game |
| **Geo — Stagger** | 🚫 **cap at −1** | Permanent −50% enemy damage. §7.1 already lists Stagger as explicitly non-modifiable |

❓ **Needs Christian's ruling** — this split is a recommendation, not a
decision. The principle offered: allow every-cast where it makes you strong,
forbid it where it makes the *opponent* passive.

✅ **Caps that remain unchanged:**
- Proc-rate boosts are **additive percentage points, never multipliers** —
  e.g. `+10pp` (25% → 35%), with a **hard ceiling around +15pp** across all
  gear.
- Streak thresholds may drop by **at most 1 per source**; reaching every-cast
  requires stacking an allowlisted effect with retention gear, never a single
  item.
- Some effects are **explicitly not modifiable** — above all **Geo's
  Stagger**, whose countable 4th-cast trigger our own design doc calls "the
  best counterplay in the set." Making it every-other-cast destroys the
  bait-and-whiff mind game it exists for.

### 7.1b Three levers, in order of safety ✅

Rate is the *riskiest* way to buff an element effect. Two safer levers:

| Lever | Example | Risk | Notes |
|---|---|---|---|
| ⭐ **Magnitude** — how hard it hits *when* it procs | Ignite burns **15%** of the attack instead of 10% | **Low** | Doesn't change how *often* the counter-triangle interactions fire, only how much they hurt. Tunable in fine increments. **Preferred lever.** |
| **Duration / stacks** | Ignite ticks 4 turns instead of 3; Photosynthesis cap 3 → 4 | Medium | Watch sustain (Flora's cap is already a balance dial) |
| **Rate / threshold** | Ignite 25% → 35% | **High** | Inflates that element against all eight others — capped per above |

✅ **Equipment may also introduce entirely new statuses**, not just amplify
the nine element effects — e.g. a set that applies its own DoT, a chill that
raises charge costs, a thorns effect. Guardrails:
- Must be built on the existing `TurnStatus` framework so lane ordering and
  the survivability-first rule (heals before burns) hold automatically.
- Must not duplicate or obsolete an element's signature effect — a gear DoT
  that outclasses Ignite would make Pyro pointless.
- Must be **visible in the HUD** via the existing buff/debuff pip system, and
  legible in the battle log. A hidden status is a bug report waiting to
  happen.

### 7.2 Shield piercing ⚠️
"Always phases through X% of shields" directly devalues the entire shield
ladder (Ward → Sanctuary) *and* the counter-element ×2 math — why counter-pick
a shield element if a third of the damage ignores it? 📝 Cap at **10–25% at
BiS**, never stackable toward 100%. 💡 A bounded alternative with the same
fantasy: *"your first attack each duel ignores shields."*

### 7.3 On-hit effects and multi-hit spells ⚠️
Letting on-hit effects trigger **per hit** is exactly the Volley-vs-Surge
differentiation Christian wants, and the engine supports it cleanly. The trap:
a 4-hit Volley becomes a proc-fishing machine. 📝 Guidance: **flat damage per
hit is safe**; **proc-per-hit is fine only if the base rate is low**; never
put a high-impact proc (charge strip, Blind) on a per-hit trigger.

### 7.4 PvP and the gear gap ✅ (two ladders)

- ✅ **Ranked counts gear.** A better-geared mage will hold a higher Elo than
  an equally skilled mage with worse gear. Gear is part of the competitive
  investment, not noise to be filtered out.
- ✅ **Academy (contest) mode** — a separate queue that **strips all gear**,
  with its own **skills-only Elo**. Pure play, no loot chase.

This is the best of both: the geared ladder rewards the full RPG investment,
while Academy answers "who is actually better at the game?" — and it doubles
as the honest venue for tournaments and for players who don't want to grind.

📝 Implementation notes / consequences:
- **Two Elo numbers per player.** Decide which is "primary" for display and
  whether both show on the profile. (Recommendation: show both; they measure
  different things and neither should be hidden.)
- ⚠️ **Gear power should still feed matchmaking, not just Elo.** With an
  80–90% BiS-vs-average gap (§2.1), a new-to-endgame player entering the
  geared queue eats a run of stomps before Elo settles them. Seeding matches
  on *gear power + Elo* smooths that; letting Elo sort it alone is slow and
  discouraging.
- 💡 Academy mode is also the **cleanest balance-testing venue** — it isolates
  element/spell balance from gear entirely, which is exactly what the sim
  measures today.

### 7.6 Consumables in PvP ❓⚠️
Potions are grindable, so allowing them in ranked recreates the gear problem
with a treadmill attached — the better-stocked player wins, and every match
costs materials. 📝 Recommendation:
- **Academy mode: no consumables.** It strips gear to measure skill; potions
  are gear by another name.
- **Geared ranked:** allowing them is consistent with "ranked counts gear" —
  but expect longer matches and a consumption grind. A middle path is a
  **small fixed allotment** (e.g. 2 slots) so they stay tactical rather than
  attritional.

### 7.5 Element-locked gear vs. the shared slot pool ⚠️
Loadouts share one pool between elements and spells (up to ~14 slots at L45),
so many players will run 3–5 elements. Gear that only pays off for one
element punishes that. 📝 **Every element-enchanted piece should still carry
universal stats** (HP, flat damage) so it's never dead weight when you cast a
different element — the enchant sharpens one element, it doesn't gate the
item.

---

## 8. Rarity ladder ✅ (answers GAME_DESIGN open question #4)

✅ **Six rarities**, standard conventions, with colours. The ladder labels
**both** item rarity and how rare a **mote** of each tier is to obtain:

| Rarity | Colour | Motes at this rarity | Items at this rarity |
|---|---|---|---|
| **Common** | White | **Dust · Shard** | flat stats only |
| **Uncommon** | Green | **Crystal** | flat stats, small % |
| **Rare** | Blue | **Core** | a modifier |
| **Epic** | Purple | **Heart** | strong modifier, enchantable · ⭐ **sets start here** |
| **Mythic** | Orange | — | top-tier; rarely obtained |
| **Legendary** | Iridescent (gold ⇄ teal ⇄ purple) | — | ⭐ **the rarest tier** — e.g. assembled from combinations of incredibly rare high-level boss drops |

✅ **Legendary is strictly rarer than Mythic.** It's a straight ladder to the
top, not two parallel endgames.

✅ **Both Mythic and Legendary include crafted *and* dropped items.** Neither
tier is acquisition-locked — "crafted from rare boss components" is an
*example* of a Legendary, not a definition of the rarity.

✅ **The mote ladder tops out at Epic.** The five motes span Common→Epic; the
two highest rarities (Mythic, Legendary) have no mote tier. **The two most
abundant motes — Dust and Shard — both sit at Common**, so the bottom of the
crafting economy is squarely "common floor-drop" material; Crystal (Uncommon),
Core (Rare) and Heart (Epic) then climb one rarity per tier.

⚠️ **Heart's "Epic" label describes standing, not a drop rate** — Hearts are
**craft-only** (§6.1), so nothing at that rarity actually drops. Every tier
*below* Heart does drop directly, at the escalating rarity shown above.

📝 **Set tiers vs rarity** — four set tiers (L30/40/45/50, §3.4) mapped onto
the top three rarities:

| Set tier | Level | Rarity |
|---|---|---|
| I | 30 | Epic |
| II | 40 | Epic |
| III | 45 | **Mythic** |
| IV | 50 | **Legendary** |

The rarity step lands on Tier III, which §3.4 already calls out as the ⭐
*noticeable jump* — the two ladders reinforce each other instead of drifting.

✅ **The colour set is now the standard ARPG ladder** — White · Green · Blue ·
Purple · Orange · Iridescent — so players read it on sight (White = Common,
Green = Uncommon, and so on). This also retires the old Light-Gray-vs-White
contrast problem.

⚠️ **One UI risk remains:** **Iridescent needs an animated or gradient
treatment**, not a flat colour — it can't be a single hex value in a theme
map. Budget for it as a small custom widget, and make sure it degrades to
solid gold if animations are reduced or disabled.

---

## 9. Scaling down from the ceiling 📝

Having defined BiS, the ladder back down:

| Band | Level | What gear does |
|---|---|---|
| **Tutorial** | 1–9 | Flat HP only. Teaches "gear = survivability" with zero complexity |
| **Foundations** | 10–19 | Flat damage and shield %; first Uncommons; crafting unlocks |
| **Specialization** | 20–34 | Non-set gear deepens (modifiers, Luck); enchanting unlocks; **primary sets begin at L30** (§3.4 Tier I) |
| **Mastery** | 35–44 | 4-piece bonuses; Epic drops; element enchants become the build; set Tier II at L40 |
| **Endgame** | 45–50 | 5-piece bonuses; Heart-tier motes; set Tiers III–IV; the §2 ceiling |

📝 Rationale: modifiers arrive *after* the player understands the element
effects they modify. A level-12 player boosting Ignite rates before they've
felt a burn is noise, not depth.

---

## 9b. The crafting model & the Primal quarter (session 2026-08-01)

Rulings from the Primal-quarter design session (Christian + external
brainstorm, reviewed here). These supersede the older assumption that a
station is *required* to craft.

### 9b.1 Shops & stations ✅

1. ✅ **Trade is not gated.** Shops work from the first town; no tutorial lock.
2. ✅ **Every shop's stock is regional** — Aldermere sells Primal-band goods.
3. ✅ **Aldermere keeps Woodcarving** — the first craftable is a staff/wand.
4. ✅ **Pennycross becomes the Tailoring town.** The player gathers fibres all
   quarter and ends it with a crafted robe set + a decent staff. ⚠️ Pending
   code/doc edits when coding resumes: `world.dart` (`station:` on
   `pennycross`, currently on `galehaven`) and the WORLD_DESIGN §gazetteer
   entries for both towns.
5. ✅ **Galehaven takes Potions & Alchemy** (moved from Vespergate, L50 → L22).
   Consumables arriving at level 50 was comically late; herbs bank up from
   level 1, and a port town trading remedies reads naturally. Vespergate goes
   stationless, which suits a gate/pilgrimage town. ⚠️ Pending code edit:
   `station:` on `galehaven` and `vespergate` in `world.dart`, plus both
   WORLD_DESIGN gazetteer entries.

**Final station map:** Aldermere Woodcarving (L1) · Pennycross Tailoring (L8)
· Forgeholm Metalworking (L15) · Galehaven Potions & Alchemy (L22) · Meridian
Enchanting (L36) · Rimeholt Jewelry (L45) · Zenith all six (L60). Concordance
and Vespergate are stationless by design.

### 9b.2 Hand-crafting vs stations ✅ (the load-bearing ruling)

6. ✅ **Most items can be hand-crafted anywhere.** Stations are *required* only
   for certain high-tier recipes.
7. ✅ **Stations craft faster.** One-off items are fine by hand; past a fairly
   low quantity threshold, travelling to the station wins.
8. ✅ **Stations may craft passively** — leave materials for 10 staves
   overnight, collect finished goods later. 📝 Recommendation, needs ruling:
   **passive output caps at Standard quality** (§9b.4); quality rolls
   (Ornate/Master) require attended crafting. Otherwise overnight bulk +
   salvage becomes unattended quality-fishing, and the crafting *moment*
   disappears.

⭐ **This ruling quietly dissolves the station-coverage blocker** that opened
the session (only Woodcarving existing before L15). Every slot has a maker
from the moment the player has skill + recipe + materials; the station map is
now *convenience geography* — where bulk and quality happen — not a gate. The
region-by-region catalogue can assume all nine slots are craftable in-band.

### 9b.3 Equip requirements ✅

9. ✅ **Every item has a minimum equip level.**
10. ✅ **Items you cannot yet equip can still be acquired** (drops, trade).
11. ❓ **Does quality (§9b.4) raise the equip level?** 📝 Recommendation: no —
    a Master Oak wand stays a level-1 item even though it rivals a Rough Yew.
    That creates the "fine gear for low levels" market crafters live on, and
    is a deliberate twink lane, not an accident. Needs ruling.

### 9b.4 Quality tiers 📝 (structure accepted, numbers TBD)

Within a material tier, crafted output rolls a quality:
**Rough → Standard → Ornate → Master**, with better odds at higher skill.
The pattern (or an analog) applies to every processing skill.

- ✅ **Salvage** (recommended term — genre-standard; "Unbind"/"Unmake" collide
  with the Bound tradability vocabulary): break a crafted item back to ~50%
  of its components to reroll for higher quality. Rerolling costs ~2× the
  materials per attempt — a healthy sink.
- ✅ **Anchor: Master of tier N ≈ Rough of tier N+1.** With 4%/level
  compounding, this fixes the quality step size per band:
  `step = (1.04 ^ level-gap-to-next-tier) ^ (1/3)` — three steps spanning the
  gap. Early tiers (9–10 level gaps) need ~12% per quality step; late tiers
  (5-level gaps) ~7%. The quality ladder is therefore *wider* early, exactly
  when gear is otherwise transitional.
- ⚠️ **One term, not two:** the top quality is **Master** everywhere; retire
  "Masterwork" from earlier drafts.
- ✅ **Quality never raises the equip level.** A Master Oak wand is still a
  level-1 item. This is a deliberate twink lane: it creates the "fine gear for
  a new character" market that crafters live on.

### 9b.4a Gear advantage vs level advantage ⭐ (the governing ratio)

Christian's two concerns — *a well-geared low level must not trivialise a
high level*, and *a hard-won Master item must not be outclassed minutes
later* — are the same question, and the anchor answers both.

**Gear advantage caps at roughly one material tier.** Rough→Master spans the
gap to the next tier by construction, so a fully-Master character sits about
one tier ahead: **~10 levels early, ~5 levels late.** ⭐ That lands exactly on
the "gear is worth ten levels" line already in the docs — the quality ladder
and the gear budget agree without being forced to.

⭐ **Character level is unbounded; gear advantage is not.** At 4%/level
compounding, level keeps paying forever while gear tops out at one tier. A
level-20 in full Master gear fights like a level-30's *equipment*, but still
carries a level-20's base HP and damage. They punch up; they do not dominate.

**Why a Master item stays relevant:** it is matched only by the *next tier's
Rough*, which by definition needs the next equip level. So a Master item holds
its slot for the whole tier gap — 10 levels early, 5 late. It is never
outclassed "minutes later" unless a drop breaks the rule below.

⚠️ **Therefore: aspected monster drops must be SIDEGRADES, not upgrades.** An
aspected drop of tier N should carry roughly *Standard*-quality raw stats plus
an element rider. A Master crafted item beats it on raw power; the drop offers
a different axis. Break this and crafting becomes pointless — the single
biggest risk to the whole economy. **Boss uniques are the deliberate
exception**: they are the chase, and they are rare enough to stay exciting.

### 9b.4b The three crafting modes ✅

| Mode | Speed | Quality | Skill XP | Notes |
|---|---|---|---|---|
| **Active, at a station** | fastest | best odds; the only route to top quality-roll rates | **bonus** | Some recipes require a station outright |
| **Active, anywhere** | slower | standard odds — ⭐ **can still reach Master** | standard | Keeps stations *convenience*, not gates (§9b.2) |
| **Passive, at a station** | overnight | ⚠️ **capped at Standard** | **reduced** | Bulk lane; no quality fishing |

✅ **Salvage follows the same shape**: better component yield at the matching
station than by hand.

⭐ **Why the passive cap matters:** without it, overnight bulk + salvage
becomes unattended quality-fishing, and the Ornate/Master roll — the best
moment in crafting — happens while nobody is watching. The cap keeps the
exciting roll attended and leaves passive crafting as what it should be:
volume, not luck.

### 9b.5 Provenance naming grammar 📝

Three name shapes, so an item's origin is readable from its name alone:

| Provenance | Grammar | Example |
|---|---|---|
| **Crafted** | `[Quality] [Material] [Form]` | *Ornate Oak Quarterstaff* |
| **Monster drop** | `[Element aspect] [Material] [Form]` | *Charred Yew Baton* |
| **Boss drop** | Unique name | *Ebony Spire of the Grave* |

- ⚠️ **Base names must not contain quality-like adjectives.** "Rough Oak
  Quarterstaff" as a *base* name breaks the grammar ("Master Rough Oak…").
  Bases are plain: *Oak Quarterstaff*, *Yew Battle-Staff*, *Birch Spire*.
### 9b.5a Form names are FIXED vocabulary ✅

❓ Christian asked whether the form word should escalate with tier
(*Quarterstaff → Battle-Staff → Spire → Monolith*) or stay constant.

✅ **Fixed.** Every name component carries exactly one fact:

| Component | Encodes | Example |
|---|---|---|
| Quality adjective | the crafting roll | *Ornate* |
| **Material** | **tier / level** | *Bloodwood* |
| **Form** | **mechanical role** | *Quarterstaff* |
| Aspect prefix | element (drops only) | *Charred* |

⭐ **Escalating form words would make rank unreadable.** Is a *Spire* better
than a *Crozier*? The player would have to memorise an arbitrary order
*on top of* the material order. With fixed forms, "Bloodwood Quarterstaff
beats Yew Quarterstaff" needs no lookup — and the material name is already
doing the escalation work (*Oak* → *Aetherwood* escalates by itself).

⭐ **The lost sense of grandeur is recovered where it belongs:** boss uniques
have bespoke names (§9b.5), so *Ebony Spire of the Grave* still exists — it is
just a *unique*, which is exactly what should sound grand.

💡 **Form is free to encode mechanics later.** Since form no longer means
rank, a second two-hander (say a slower, heavier *Warstaff*) can exist at any
tier as a genuine build variant rather than a rename.

### 9b.5b The twelve aspect prefixes 📝

Applied to monster drops. Every one avoids the element's own status name and
existing reserved vocabulary.

| Tier | Element | Aspect | Avoids |
|---|---|---|---|
| Primal | Pyro | **Charred** | Ignite |
| Primal | Aqua | **Tidewashed** | Waterlogged |
| Primal | Flora | **Overgrown** | Photosynthesis |
| Kinetic | Electro | **Galvanized** | Static Feedback |
| Kinetic | Aero | **Windworn** | Tailwind |
| Kinetic | Geo | **Stoneclad** | Stagger |
| Celestial | Solar | **Sunbleached** | Blind |
| Celestial | Lunar | **Moonlit** | ⚠️ *Eclipsed* is taken (Lunar's Blind lock **and** the Eclipsed Citadel) |
| Celestial | Astral | **Starfallen** | Astral Alignment |
| Ethereal | Sanctus | **Consecrated** | Absolution, Grace, Hallow |
| Ethereal | Umbra | **Gloomtouched** | Creeping Dark; its Shadow/Dusk/Midnight tiers |
| Ethereal | Arcane | **Sigilmarked** | Arcane Knowledge |

⚠️ **"Bound" remains reserved** (tradability, §6c) — no *-bound* aspects.
✅ *Starfallen* deliberately echoes **Starfall Basin**; both are Astral, so the
shared word-space is flavour rather than collision.
- ⚠️ **"Bound" is reserved** (tradability, §6c): rename the level-1 book from
  *Novice's Bound Primer* to e.g. *Novice's Stitched Primer*.
- 📝 Aspected drops are effectively **pre-enchanted sidegrades** — keep their
  element bonuses *weaker* than a real enchant so Enchanting keeps its
  identity. Boss uniques are the chase tier; crafted is the reliable floor.

### 9b.6 Woodcarving ladder 📝 (Christian's draft, with review flags)

Mechanical identity ✅: **staves** (two-handed) lean heavy — total damage,
big-spell payoffs; **wand + off-hand** leans fast — per-hit damage, on-hit
effects. This lands exactly on the existing big-spell vs multi-hit tension
(§3.1's Emberwright-vs-on-hit note): the weapon choice *is* the build choice.

| Equip lvl | Wood | Gem slots | 🏠 Home zone | Why there |
|---|---|---|---|---|
| 1 | **Oak** | 0 | Whispering Woods (1–5, Flora) | The archetypal starter hardwood of a deciduous wood |
| 10 | **Birch** ⭐ | 0 | Ashfall Vale (10–14, Pyro+Flora) | ⭐ Birch is a **fire-successional pioneer — literally what regrows after a burn.** Tier-2 wood sits exactly where a level-10 player fights |
| 20 | **Yew** | 0 | Windward Steppe (19–24, Aero) | Yew is the classic windbreak — famously wind-hardy, and a longbow wood |
| 25 | **Rowan** 💡 NEW | 0–1 | Thunderspire Peaks (23–28, Electro+Aero) | ⭐ Rowan is the **folkloric lightning-ward tree**, and grows at altitude ("mountain ash") |
| 30 | **Ironwood** | 0–1 | The Kiln Desert (30–34, Solar) | ⭐ Desert ironwood is a **real Sonoran desert tree** — needs no reinterpretation at all |
| 35 | **Bloodwood** | 1–2 | The Mirrormere (32–37, Lunar) | Deep red heartwood under a blood moon, mirrored in the lake |
| 40 | **Ebony** | 1–2 | The Sunless Reach (38–42, Solar+Lunar) | ⭐ **The retheme:** black wood grown where the sun does not reach. *Sunless/lightless*, not "void-touched" |
| 45 | **Spiritwood** | 2–3 | Hallowmarch (45–49, Sanctus) | Hallowed ground, hallowed wood |
| 50 | **Aetherwood** | 3 | The Collapsed Academy (50–54, Arcane) | Aether is arcane; the Academy is the Arcane zone |

⭐ **Every wood now has a home, and the map does the teaching.** The gathering
map *is* the world map: you learn where trees grow by playing. With ~5-minute
travel legs this also makes regional wood a genuine trade lane, and gives
**Discordant** characters (no market) a concrete reason to revisit old zones.

💡 **Rowan at 25 fills a real hole.** Levels 21–29 previously spanned three
zones (Frostfell Pass, Thunderspire, Molten Deep) with no new wood.

📝 **On the uneven gaps** (9/10/5/5/5/5/5/5 — early tiers last twice as long in
*levels*): leave them. XP per level grows linearly (`100 + 50×(level−1)`), so
early levels pass fast and late ones slowly — in *time*, a 10-level early tier
and a 5-level late tier are closer than they look. ⚠️ But note this feeds
§9b.4a: the quality ladder is ~12% per step early and ~7% late.

✅ **Level 40's retheme resolves itself.** "Void-Touched" was a flavour
adjective, and §9b.5a's grammar removes adjectives from base names entirely —
the item is simply an **Ebony Quarterstaff**. Sunless/lightless language moves
to the item description and to that band's boss uniques; void/soul/aether
vocabulary stays reserved for 45+.

- ✅ **Durability does not exist**, and no item described in this document has
  it. ⚠️ Equipment *degradation* is intended as a **very late endgame** system;
  it is undesigned, and nothing here may assume or imply it. Do not let it
  re-enter via adjectives ("weathered", "lower durability").
- 💡 Off-hand families (Book / Orb / Scroll / Relic) could carry light
  mechanical identities (e.g. books → status/utility, orbs → damage) so the
  off-hand choice is a build decision rather than a skin. And the tank lane
  (Aegis Sovereign) may eventually want a **ward/shield** off-hand family —
  maker TBD (Metalworking?).

### 9b.6a What makes a rare drop worth fighting for ⭐ (supersedes the flat "sidegrade" rule)

⚠️ **The problem Christian raised:** once the Concord Market matures, a player
can simply **buy Master-tier gear at every level**. Crafted Master therefore
stops being an achievement and becomes *the purchasable floor* — so "aspected
drops are sidegrades" cannot be the whole story, or drops become pointless to
anyone with gold.

⭐ **The resolution: quality and rarity are two orthogonal ladders doing
different jobs.**

| Ladder | Scales | Applies to |
|---|---|---|
| **Quality** (Rough→Master) | **raw stat magnitude** | crafted items |
| **Rarity** (Common→Legendary) | **which kinds of properties can exist at all** (§8) | everything |

Per §8, Common is *flat stats only* and Rare *has a modifier*. So a Master
crafted Common has **maxed flat stats and structurally cannot carry a
modifier**. The gap between it and a Rare drop is **categorical, not
numerical** — which is a far more durable distinction than "slightly bigger
numbers."

**The power lattice, within one material tier** (📝 numbers provisional):

| Item | Raw stats | Properties |
|---|---|---|
| Rough crafted | 1.00 | — |
| Standard crafted | ~1.12 | — |
| **Aspected drop** (Uncommon) | ~1.12 | small element rider |
| Ornate crafted | ~1.25 | — |
| **Master crafted** | **~1.40** (≈ next tier's Rough) | — |
| **Rare drop** (mini-boss) | **~1.40** | ⭐ **a modifier** |
| **Epic drop / craft** (boss) | **~1.50** | ⭐ strong modifier · **enchantable** · set piece |

✅ This matches Christian's instinct exactly — Rare ≈ Master, Epic marginally
stronger — but now it is *justified* rather than asserted: the rarest drops are
better because rarity buys **capability**, and only secondarily power.

⭐ **The governing rule: the market sells the FLOOR, never the CEILING.**

- **Master crafted** is the best thing you can **buy**.
- **Rare / Epic** are the best things you can **earn**.

The existing tradability tiers (§6c) already enforce this and need no change:
crafted gear is *Untradeable* until freed by an unbinding enchant (skill-gated,
so a market forms but with friction), while **Tier III/IV rare set components
are Bound and can never be sold at all**. Gold buys the baseline; it cannot buy
the top.

⭐ **And crafting is not sidelined at the top** — §3.5's acquisition triangle
means Epic set pieces are *crafted from Bound rare drops*. Drops supply the
components, crafting assembles them, Enchanting adds the element axis. The two
systems are complementary, not competing.

⚠️ **The load-bearing consequence: Rare modifiers must be genuinely good.** If
a mini-boss Rare carries "+2% crit", it is strictly worse than a Master anyone
can buy, and the whole mini-boss tier becomes skippable. **The modifier is the
entire reason to fight the thing** — treat weak modifiers as a balance bug, not
flavour.

⚠️ **This makes gold powerful early**, since buying a Master at each tier is a
real shortcut. That is acceptable and even good — it gives gold a purpose and
makes the wealth achievements meaningful — but it does mean **Discordant
characters are meaningfully behind on gear**, which is the mode working as
intended, not a bug to compensate for.

### 9b.7 Gathering nodes — charges & replenishment 📝

✅ **Resource nodes are regional and charge-based.** Christian's model:

- A node holds up to **~6 charges**; gathering spends one.
- Charges replenish **1 per ~4 hours**, capping at 6.
- ✅ **Time Crystals accelerate replenishment** — consistent with the
  monetization rule (§3.6): acceleration, never access.

⭐ **Six charges at four hours is a full refill in 24h**, which is the right
shape: a player who logs in once a day loses nothing, and one who logs in
twice gets no *extra* — only earlier. That is engagement without punishment.

✅ **Node charges are PER-CHARACTER, and accrue offline.** A shared world node
would strip zones bare for later players and turn gathering into a race.
Offline accrual is derived from a timestamp — the same "never schedule, always
compute" pattern travel already uses.

✅ **In-game shop stock is also per-character**, with the same reasoning. ⭐
**The Concord Market is the sole exception — it is truly global**, which is
precisely what makes it a market rather than a vendor.

✅ **The real purpose of charges is supply control, not engagement.** They exist
so the market cannot be flooded by bots gathering unbounded resources. Worth
stating plainly, because it means the right tuning question is *"what supply
does the economy want?"* rather than *"how often should players log in?"*

✅ **Region materials also drop from that region's enemies**, in smaller
quantities than a node yields ("or near that region", if a zone's table needs
flexibility). ⭐ This is what keeps **Discordant** mode viable: a no-market
character is no longer hard-capped by node throughput, because fighting is a
second, uncapped supply line. It also means a player who prefers combat to
gathering can still craft — just more slowly.

### 9b.7a Gathering tools 💡 (Christian, 2026-08-02)

Gathering a node is an **active wait of ~45–90s**, reducible with a better
tool: craftable **hatchets** (Felling), **rakes** (Foraging), **pickaxes**
(Mining).

⭐ **This is a genuinely good early loop** — gather by hand, craft a hatchet,
gather faster — and it gives Woodcarving and Metalworking a *sink that matters
from level 1*, which the skill tree otherwise lacks before gear does.

📝 Shape, to settle:

- **Tool tiers should track the material ladder** (Oak hatchet → Ironwood
  hatchet → …), so tools ride the same progression as everything else.
- ❓ **Do tools occupy a slot?** 📝 Recommend **no** — owning the best tool
  simply applies its speed. A gear slot spent on a hatchet is a tax, and a
  "tool slot" is inventory management nobody asked for.
- ⚠️ **Tools are the classic home for durability**, and §9b.6 rules durability
  out. If equipment degradation ever ships as the late-game system, *tools are
  where it should start* — far lower stakes than gear. Until then, tools do
  not wear out.

⚠️ **Model the total wait before tuning any single lever.** Crafting throughput
is now gated by node charges **and** gather time **and** skill level **and**
recipe unlocks **and** ~5-minute travel legs. Each is individually reasonable;
compounded they can be far longer than any one number suggests.

✅ **A gather harvests the node's charges SIMULTANEOUSLY, not serially.**
Whether the node holds 1 charge or 6, it is **one wait**. Six charges is one
timer, not six.

⭐ This is the right call and worth stating why: it removes the perverse
incentive to visit a node early and often (which would punish the very
players charges are meant to bring back), and it makes a full node the
*efficient* play — you are rewarded for letting it fill, which is exactly the
behaviour the replenishment curve wants.

✅ **Gather time scales with material tier** — short early, longer for harder
materials. A level-1 player pulling oak waits briefly; Aetherwood is a
commitment. This also keeps the early game snappy, where a long timer would do
the most damage to first impressions.

📝 Still worth deciding: whether the timer runs **while the player does
something else** (travel, a duel) or holds the screen. Given travel already has
a real clock, a gather that ticks in the background would compose well — but it
is an interaction decision, not a tuning one.

📝 **Still open:** does a node yield **material by zone** (Ashfall Vale always
gives birch) or roll a small table? Flat-by-zone is more legible and makes the
map teach itself (§9b.6); a small roll adds variance cheaply.

## 10. Open questions

✅ **Resolved:** power budget · five archetypes · counter-loop · sim criterion
(with the AI caveat) · set slots · set tiers & acquisition · PvP gear policy +
Academy · proc levers & caps · mote ladder & drop model · neutral conversion ·
conversion cooldowns · skills & crafter mapping · tradability + unbinding
enchant · monetization line · lockout stacking · Endurance · charge retention ·
sustained variants · potion priority, slots, PvP legality and pipeline
interactions · loot insurance · premium Luck potions · enchant-parity stance.

### Still open

| # | Question | §|
|---|---|---|
| 36 | 📝 **TBD, deliberately deferred** — Tidebinder's 4pc and 5pc are the same bonus twice (stacks to −2, violating §7.1). Not a blocker: implementation can proceed with the 5pc as written and the 4pc left blank. ⚠️ **Must be fixed before Tidebinder ships**, and the §7.1 floor must be enforced in code regardless | §3.1 |
| 37 | 📝 **TBD, deliberately deferred** — Voidcaller's 3/4/5-piece bonuses are all blank. Not a blocker: build the set-bonus framework generically so any bonus shape slots in. ⚠️ **Voidcaller cannot ship without them**, and per the resolved ruling they must carry the **info-war identity natively** rather than borrowing it from an assumed Umbra enchant (Umbra moves L30 → L45 under V2, TYPE_EFFECTS §0.4) | §2.2, §3.1 |

✅ **Resolved since the last pass:** set pieces are **Epic+** with a
**six-rarity** ladder (#8, §8) · charge retention **keeps the element cycle
open** (#38, §5b.3) · potions are **ordinary priority-3 actions with Haste
tiebreaks** (#39, §6b.3) · **post-cap XP → 10 XP per Dust, 250/day** (§6.1).

✅ Everything else in this document is decided. The design is ready for the
catalogue pass (concrete items, recipes, drop tables); #36 and #37 are the
only gaps, and both are content to fill in rather than architecture to
settle.

### Watch items (not blockers)

| # | Item | § |
|---|---|---|
| 11 | Element-enchant parity — if Arcane dominates, reduce its %/stack | §2.2 |
| 28 | Concrete drop rates land in per-monster loot tables | §6.1 |
| 27 | Per-recipe cooldown values land with the recipe catalogue | §6.0b |

---

## Changelog

**Rev — 2026-08-02b.** §3.6 monetization rule rewritten for precision: it
governs **RP (real money) only, never gold** — nothing bought with RP may be
unobtainable with gold; RP may buy time *and gold*; no RP-only functional
items, cosmetics excepted. Noted that tradability (Bound), not price, is what
actually enforces the ceiling once RP converts to gold. Node gathering
confirmed as one simultaneous harvest with tier-scaled timers.

**Rev — 2026-08-02 (Primal-quarter, session 2).** Galehaven confirmed for
Potions & Alchemy (station map finalised); form names fixed as vocabulary
(material carries rank, uniques carry grandeur); twelve element aspect
prefixes named; wood ladder given a home zone per tier plus Rowan at 25;
gear-vs-level ratio derived (gear caps at ~1 tier, level unbounded); three
crafting modes tabled; **quality and rarity separated as orthogonal ladders**,
resolving how rare drops stay desirable against a market selling Master
("the market sells the floor, never the ceiling"); per-character nodes and
shops with a global Concord Market; region materials also drop from enemies
(unblocking Discordant); craftable gathering tools.

**Rev — 2026-08-01 (Primal-quarter session).** Shops ungated with regional
stock; Pennycross takes Tailoring (Galehaven identity now ❓, Potions
proposed); hand-crafting anywhere with stations as speed/bulk/quality layer
(+ passive overnight crafting 📝); min-equip levels; quality tiers
Rough/Standard/Ornate/Master with Salvage rerolls and the Master(N)≈Rough(N+1)
anchor; provenance naming grammar (crafted/aspected/unique); Woodcarving
material ladder drafted with review flags (Oak→Birch→Yew reorder, celestial
retheme at 40, durability flagged as undesigned).


**Rev 11 (cross-doc review)** — Findings from a four-doc consistency review
noted in place. Fixed: rarity ladder renamed to Dust→Heart; 5×9=45 builds;
archetypes marked accepted; consumable baseline aligned to 2–4; §9 bands
aligned to the L30 set start; stale "inherited open questions" cleared.
Flagged for ruling: **Tidebinder 4pc/5pc duplicate bonus** (#36),
**counter-loop guarantees must live in set bonuses vs canonical pairings**
(#37, incl. corrected Tidebinder→Voidcaller rationale — fizzles don't reset
streaks/stacks), **charge retention vs the element cycle** (#38), **potion
ordering in the P3 group** (#39), and the **compelled-forfeit wire-protocol/
anti-cheat prerequisite** (§5b.1). GAME_DESIGN and PROGRESSION_DESIGN
updated in the same pass (elements section marked shipped, storage split and
premium currency renamed to Resonance Prisms, two-ladder Elo, §3 skills reconciliation, cost-based
§4.1 reasoning).

**Rev 10** — Final rulings; only "set pieces Epic+?" remains open.
**"Charge spent" = the spell's cost** adopted engine-wide (TYPE_EFFECTS_DESIGN
§1 updated to match; needs a sim re-run when built). **Interrupts** come from
three sources: a **Disrupt** aux spell, a damage-plus-interrupt spell, and
**Stagger** gaining the property — making Geo the anti-sustained element.
Skill names settled: **Jewelry, Metalworking, Woodcarving**. **Backpack = 20
items** with craftable expansion pouches (a second job for Tailoring).

**Rev 9** — Answered nearly every outstanding question. Lockouts: **stacking
allowed** as an earned outcome (so the compelled-forfeit rule becomes
load-bearing, not a safety net). Endurance: spell refreshes, items break or
recharge, saves against Fatigue harmlessly. **Charge retention: no bounds**,
with "charge spent" defined as the spell's cost — flagged in new §5b.3a as a
knock-on that changes Blind, Creeping Dark and Arcane Knowledge for *all*
players and needs a sim re-run. Sustained spells: **all three variants**
(beam / channelled / prepared). Potions resolve at **P3**, slowed by
Waterlogged, never fizzled or missed; **backpack + equipped consumable slots**
model; loot insurance as % or keep-X. Untradeable released via an
**unbinding enchant** (skill-gated, not premium). Sim criterion accepted with
the caveat that effect-blind AI under-represents strategic archetypes.

**Rev 8** — Added §5b, a proposed-mechanics catalogue: the **lockout family**
(Silence/Bind/Sunder/Seal, positioned as tech-slot counter-picks, with the
always-a-legal-action invariant), **Endurance** death save, **charge
retention** (flagged as the highest-impact proposal — it edits the core
"casting spends all charge" tension), and **sustained spells + interrupts**
(flagged as the largest engine addition, since multi-turn actions don't exist
today).

**Rev 7** — Mote economy clarified: **every tier below Heart drops directly**
at escalating rarity (Dust common → Core near-never), **Hearts are
craft-only** — so the steep ladder is an exchange between tiers of abundance,
not a 48,000-dust grind. Noted the consequence: a Heart is always a *planned*
achievement, which supports showing Tier IV progress as a visible bar.
**Metalworking** confirmed as Mining's refinement lane, its outputs feeding
other recipes (making the skill tree an interdependent economy).

**Rev 6** — **Crystallization** adopted (Dust→Shard→Crystal→Core→Heart) with
the refinement ladder (50/20/12/4) and the warning that 48,000 dust per Heart
only works if Hearts also drop directly. Neutral→element conversion now
**scales with Enchanting level** (4:1 → 1:1 at 50), throttled by **cooldown**
rather than a build timer. Skill list completed with **Jewelry**,
**Metalworking** and **Woodworking** — every slot now has a maker (Metalworking's
output still open). Motes also drop from **gathering** in attuned areas.
Monetization principle formalized: **gems buy shortcuts, never requirements**;
buying better odds is fine, buying components is not. Combat potions confirmed
to cost your turn; three potion scopes; no consumables in Academy.

**Rev 5** — **Skills** structured as two types outside player level:
Gathering (Mining/Felling/Foraging) and Processing (Tailoring/Potions/
Enchanting); detail tabled. Flagged the gap that Mining and Felling have no
processing skill — weapons and jewelry (4 of 9 slots) currently have no
maker. **Tradability** set at three tiers (Tradeable / Untradeable-with-
release / Bound), with Tier III–IV rare components as **Bound**, closing the
buy-the-drops loophole. Arcane enchant parity explicitly tabled.

**Rev 4** — Slot naming settled (**Main hand / Off hand** vs the worn
**Gloves** slot). Added **Alchemy** as a third skill, with potion categories
(long real-time boosts, restoration, loot insurance, combat utility) and the
**bounded consumable-slot** mechanic (4 → 8–10, expandable by equipment).
Flagged the three rulings that matter most: potions must cost your action,
loot insurance defuses the campaign's core gamble, and consumables should be
banned in Academy mode.

**Rev 3** — PvP settled: ranked counts gear, plus an **Academy (contest)
mode** with gear stripped and its own skills-only Elo (flagged: gear power
should feed matchmaking, not only Elo). Proc levers ranked by safety —
**magnitude** preferred over rate; equipment may also introduce **entirely
new statuses**, with framework/visibility/no-obsoleting guardrails. Mote tier
naming reopened with three element-neutral candidate systems.

**Rev 2** — Power budget settled (100% vs naked, 80–90% vs average; 1–49
scaling explicitly not a concern). Anti-meta guarantee promoted to the
primary design constraint, with a proposed archetype counter-loop, tech-slot
adaptation layer, and a measurable sim criterion. All five archetypes
accepted. Set slots confirmed as the five primary robe pieces. Added set
tiers (30/40/45/50), the acquisition triangle (rare drops + enchanting skill
+ crafting skill), and the "money buys time, never access" monetization line.
New questions on enchant parity, skills-as-tracks, and component tradability.

**Rev 1** — Initial design session: inherited decisions catalogued; endgame
ceiling and power budget proposed; two-axis (archetype set × element enchant)
architecture; modifier vocabulary with risk ratings; complete catalogue of
existing statuses/effects/hooks; mote economy tied to existing region
elements; balance guardrails on proc rates, shield piercing, on-hit, and PvP
gear; rarity ladder; level-band scaling.

---

## 10. The Item model — code shape (session 2026-08-02)

### 10.1 ⚠️ Definitions and instances are two different things

⚠️ **The single most important distinction in this section, and the one that
will cause the most damage if it is blurred.** Christian's framing was "an
Items collection in the DB with info about the item". That is right for **half**
of it:

| | What it is | Where it lives | Why |
|---|---|---|---|
| **Definition** | *What a Bloodwood Quarterstaff IS* — base stats, slot, rarity, tradability, equip level | ⭐ **CODE** | ⚠️ **The duel resolves against it.** Lockstep commit-reveal means both clients must agree exactly; server data adds a second way to disagree, timed by whenever each last refreshed (ENEMIES §1.2) |
| **Instance** | *That YOU own three, that this one rolled Ornate, has a Core socketed and a Sunbleached enchant* | ✅ **DB** | Exactly Christian's reason — start on one machine, continue on another |

⭐ **The version gate Christian proposed is what makes definitions-in-code
safe, and it is a better answer than the one the plan had.** The server holds a
current content version; a client whose version differs at login is forced to
refresh. ⭐ **Then every live client provably shares identical definitions** —
which is precisely the guarantee lockstep needs, achieved once at login instead
of negotiated per match.

✅ **This supersedes the matchmaking-ticket handshake** logged in
IMPLEMENTATION_PLAN. A ticket compare only stops a *mismatched pairing*; a
login gate stops a mismatched client existing at all, and also covers PvE,
crafting and prices.

⚠️ **What still must be in the DB regardless:** inventory, bank, equipped
loadout, `dropsSeen`, and anything a player can lose or gain. Those are
instances, and they sync.

⭐ **`dropsSeen` therefore costs almost nothing** — a `Set<String>` of
definition ids. The names, icons and rarities it renders come from code.

### 10.2 What an item can carry — the full property list

Gathered from every ruling already made in this document.

**Every item**
| Property | Notes |
|---|---|
| `id` | Stable, never displayed. Save files and `dropsSeen` key on it |
| `rarity` | Six-tier ladder (§8) |
| `tradability` | Tradeable · Untradeable · Bound (§6c) |
| `equipLevel` | ✅ Every item has one (§9b.3). ✅ Quality never raises it |
| `value` | Gold. ⚠️ A **tuning knob** — may be server-side (ENEMIES §1.2) |
| `lore` | ⭐ Christian's "players who care can learn more" channel |
| `painter` | ⚠️ A recipe, **never a bitmap** — this project has no image assets |

⭐ **`name` is COMPUTED, not stored.** §9b.5a fixes the grammar: aspect prefix +
quality adjective + material + form, each component carrying exactly one fact.
⚠️ **Storing the string lets it drift from the facts it is supposed to encode**
— an item could be renamed without being changed, or changed without being
renamed. One composer function, and a drift-guard test.
⚠️ Uniques are the exception: boss drops have bespoke names (§9b.5) and need a
`displayNameOverride`.

**Equipment** — slot · setId/setTier (five armour slots only, §3.2) ·
modifiers (§4 vocabulary) · sockets (§6d) · enchant · quality
(Rough→Master, §9b.4) · material tier · form · aspect (drops only, §9b.5b)

**Consumable** — effect · ⭐ `usableInDuel` (§6b.3 makes this a real ruling,
not a flag) · stack size

**Mote** — element (or neutral) · mote tier (Dust→Heart, §6.0)

**Material** — which of the six skills consumes it · tier

**Component** — ⚠️ **not** a Material. Tier III/IV set parts (§3.5): Bound,
never gathered, never bulk. Modelling them as Materials would let bulk-crafting
logic touch them, which is the exact loophole §6c closed

**Tool** — gathering (§9b.7a) · which skill · tier

**Gem** — socketable (§6d)

**Key** — ⭐ **These already exist and are unmodelled.** `world.dart` names
four gate items in prose: *Three ordinary proofs*, *The Kinetic Sigil, in three
parts*, *A Celestial Totem charged with Solar, Lunar and Astral essences*,
*Three Ethereal key fragments*, and the **Concordant Crown** itself. ⚠️ Every
tier gate in the game is currently a **string with no item behind it**

### 10.3 📝 Proposed shape — sealed kinds, mixin traits

⚠️ **A deep hierarchy is the wrong instinct here** (`Item → Equipment → Weapon
→ Staff`). It breaks immediately, because several things are two things at
once: a crafted staff is Equipment **and** Salvageable; a mote is a Material
**and** stackable **and** a crafting reagent; a Tool is Equipment-like but
occupies no combat slot.

⭐ **Sealed kinds for what a thing IS, mixins for what it CAN DO.**

```dart
sealed class ItemDef {
  final String id;
  final Rarity rarity;
  final Tradability tradability;
  final int equipLevel;
  final String lore;
}

class EquipmentDef  extends ItemDef with Salvageable, Enchantable, Socketed
class ConsumableDef extends ItemDef with Stackable
class MaterialDef   extends ItemDef with Stackable, Salvageable
class MoteDef       extends ItemDef with Stackable
class ComponentDef  extends ItemDef             // Bound, never bulk
class ToolDef       extends ItemDef with Salvageable
class GemDef        extends ItemDef with Stackable
class KeyDef        extends ItemDef             // gate items; never traded
```

⭐ **Sealed buys exhaustiveness.** Dart's switch is exhaustive over a sealed
type, so adding a kind becomes a **compile error everywhere it matters** rather
than a silent fallthrough. That is the same reasoning `LocationKind` already
uses — "the UI switches exhaustively on this enum, so widening it is a breaking
change rather than an additive one".

**Instances, the DB half:**

```dart
class ItemStack    { String defId; int count; }        // stackables collapse
class ItemInstance {                                    // things with identity
  String instanceId, defId;
  Quality? quality;          // rolled at craft time
  MagicElement? aspect;      // drops only
  Enchant? enchant;
  List<String> socketed;     // gem defIds
}
```

### 10.3a ✅ Inventory is one item per slot; storage collapses (Christian)

✅ **Ruling:** the two containers behave differently, and the axis that decides
everything is **fungibility**, not stacking.

| Container | Shape | Example |
|---|---|---|
| **Inventory** (the backpack you carry) | ⭐ **One item per slot** — 20 Oak Logs occupy **20 slots** | `[oak_log, oak_log, …]` |
| **Storage** (bank) | Collapses to counts | `{oak_log: 1000}` |

⭐ **This makes inventory capacity a real resource**, the way a gathering trip
should feel — you come back when you are full, not when you are bored. It is
also a natural gold sink (bigger packs) that costs no combat power, which §2.2
explicitly wants more of.

✅ **Fungible items need no identity; everything else needs a UUID.**

- **Fungible** — two are interchangeable because the *definition* fully
  determines the item: materials, motes, gems, consumables, components, keys.
  A slot holding one stores only a `defId`.
- **Non-fungible** — carries per-instance rolls (quality, aspect, enchant,
  sockets): equipment and tools. Each needs its own **UUID**, generated at
  craft or drop time.

⭐ **This retires the `Stackable` trait entirely.** "Can it stack" is not an
independent property — it is a *consequence* of fungibility, and modelling both
would let them disagree. One axis, one field: `ItemDef.isFungible`.

### 10.3b ✅ The four containers (Christian, 2026-08-02)

✅ **This supersedes §6b.2's "carry as many potions as you like".** The backpack
is bounded like everything else; there is simply no *separate* potion cap.

| # | Container | Shape | Where | Notes |
|---|---|---|---|---|
| 1 | **Stash** 📝 *name TBD* | Unlimited | One city, unlocked or purchased | The long-term hoard |
| 2 | **Backpack** | ✅ **20 slots**, one item each | Carried everywhere | ⚠️ **Defined in exactly one place** — 25 is a plausible balance change |
| 3 | **Belt** | A few slots | Carried | ⭐ The only container reachable **during** combat |
| 4 | **Mount / companion** | +35 → +100 cargo (WORLD_DESIGN §4b.3) | Travel only | ⚠️ **Does not enter a zone** |

⭐ **The mount not entering zones is what gives the backpack teeth.** Cargo
capacity is a *travel and trade* stat; on an adventure you have 20 slots and
nothing else, so a gathering run ends when you are full. ✅ That is already
consistent with §4b.3 making mounts a speed-vs-bulk fork for the road, and with
Journey risking everything you carry.

#### ✅ The belt, and why using it costs a turn

✅ **Beltable consumables are loaded from the backpack before or at the start of
combat**, and using one **spends your turn**.

⭐ **That single ruling is what makes potions a decision instead of a tax.** In
a simultaneous-turn duel, a turn spent drinking is a turn not casting — and the
opponent committed their move blind, so a heal can be *baited*. ⭐ **Potions
become mind-games rather than a resource check**, which is the same axis the
whole game already runs on.

✅ **Between encounters on an adventure**, a player may consume from the
**backpack** and rearrange the **belt**. ⭐ So out-of-combat recovery is a
backpack job and the belt is purely a combat loadout — two containers with two
jobs, rather than one container with a mode.

✅ **Both the backpack and the belt can grow**, within reason — progression and
equipment bonuses (§6b.2's `+1 slot` modifier axis, now `beltSlots`).

### 10.3c ✅ The Storeroom is PER CITY (Christian, 2026-08-02)

✅ **Named the Storeroom.** ✅ **Every city has its own, bought or unlocked
separately.**
⚠️ **They are not a shared pool.** What you leave in Aldermere is in Aldermere.
Moving it means **carrying it there yourself**.

⭐ **This is the decision that makes the rest of the world's systems load
bearing**, and it is worth being explicit about how much it changes:

| System | Was | Becomes |
|---|---|---|
| **Mount cargo** (+35 → +100, WORLD_DESIGN §4b.3) | A trade convenience | ⭐ The reason mounts exist. Relocating a hoard is a *logistics* problem |
| **Journey risking cargo** (§4b.2) | A gamble on loot | ⭐ A gamble on **everything you own that is in transit** |
| **Decentralised crafting stations** (§9b.1) | Flavour — one skill per town | ⭐ Genuinely structural: your wood is in Aldermere and your cloth is in Pennycross |
| **Concordance, the trade capital** | A market | ⭐ The natural hub, because it is where routes meet |

⚠️ **The friction risk, stated plainly.** Per-city storage *plus* decentralised
stations *plus* per-city shops can compound into busywork rather than strategy
— three separate reasons to travel before you can make one item. ⭐ **Watch for
the moment a player's plan is "spend ten minutes moving things"**, and if it
arrives, the release valve is a paid courier or a per-city stash upgrade, not
making storage global.

✅ **Name: the Storeroom.** *Coffer* was rejected — it reads as money only —
and ⚠️ **"Vault" was never available**, since WORLD_DESIGN §2.3 gives it to the
massif the whole Ethereal quarter climbs.

### 10.3d ✅ The Belt is an equipment slot

✅ **Belt joins the nine, making ten** (§1). It is the one slot whose value is
deliberately **not** combat power.

✅ **What a belt grants today: `beltSlots`** — how many consumables reach a duel
at all.

📝 **More belt modifiers are expected**, shaping what those consumables *do*
rather than how many fit. ⚠️ Not designed yet; *"potions from this belt heal 20%
more"* was an illustration, not a spec, and is **not** implemented.

⭐ **The reason to want a second axis eventually:** with only capacity, belts
are a strictly-better ladder — more slots always wins. A second axis makes
wide-and-weak against narrow-and-strong a genuine build choice. ⚠️ Whatever it
turns out to be, it should **trade against capacity**, not stack with it.

✅ **Belts are a Tailoring product** (leather), which gives §6a.1's Tailoring a
second product line and gives the new slot a maker.

✅ **"Beltable" survives as the trait name** — it now reads as "goes on the
belt", which is literal rather than metaphorical.

### 10.4 ❓ Open questions

- ❓ **Do Tomes (GAME_DESIGN §5, Tier-2 lore books) become an item kind?** As
  items they are lootable and Concord-tradeable, which interacts with
  **Discordant** mode; as a separate collection that question disappears.
- ❓ **Where do instances live** — a list on the character document, or a
  subcollection? ⚠️ Bank + inventory is unbounded over a playthrough, which
  argues subcollection, but every duel needs the equipped set, which argues
  for keeping *equipped* on the character.
- ❓ **Is `value` (gold price) server-side?** ENEMIES §1.2 already carves out
  prices as a legitimate tuning knob; the login version gate may make that
  unnecessary.
- ❓ **Recipes: a field on the item, or their own data?** ⭐ Recommend their own
  — a recipe has inputs, a skill, a level, a station requirement and an output,
  and hanging all of that off the output item makes "what can I make from Oak?"
  a scan of every item in the game.

