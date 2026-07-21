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

- **Nine slots** ✅ (naming settled):

  | Group | Slots |
  |---|---|
  | **Set slots** (the primary robe set, §3.2) | Hat · Robe Top · Robe Bottom · Boots · **Gloves** |
  | **Jewelry** | Neck · Ring |
  | **Held** | **Main hand** · **Off hand** |

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
- **Gold** (earned) and **gems** (premium) already exist on the profile.
- Crafting and enchanting are **time-gated**, skippable with premium currency.
- Creative north star: **RuneScape 3** equipment/skilling/economy feel.
- Existing stub: the Inventory tab already previews three verbs —
  **Transmute** (refine raw materials), **Craft** (combine into equipment),
  **Salvage** (break equipment into components).
- `mage_apparel.dart` already colors six visible pieces (hat, hatTrim, robe,
  robeTrim, gloves, boots) and is commented "later derived from equipped
  items" — the cosmetic hook is pre-wired.

❓ Inherited open questions: rarity tiers; whether held items are
slot-restricted (wand = right only?) or freely assignable.

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
| **Tidebinder** → Voidcaller | | Creeping Dark needs sustained consecutive Umbra casts; fizzles and tempo disruption break the streak before Dusk |
| **Voidcaller** → Aegis | | Shield counter-picking needs to see the enemy's element — Shadow hides it, so the ×2 math can't be played |

Each archetype beats one, loses to one, and is even with two. No apex.

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

- **Axis 1 — Archetype (3–5 armor sets):** *how* you fight. Burst, sustained,
  tempo, tank, attrition.
- **Axis 2 — Element enchant (9 elements):** *which* element's signature
  effect gets sharpened.

**Why this is the right call:** 4 sets × 9 elements = **36 distinct endgame
builds from only 4 art sets**. It sidesteps the alternative (nine bespoke
element sets), which would be 9 sets of art for *less* build variety and
would hard-lock every player into mono-element.

### 3.1 Draft archetypes 📝

| Set | Fantasy | 3-piece | 4-piece | 5-piece (build-defining) |
|---|---|---|---|---|
| **Emberwright** | Burst — big charged nukes | +flat damage | +damage per charge spent | Your first 4+ charge spell each duel can't be Blinded or Staggered |
| **Tidebinder** | Tempo — disruption, speed | +priority utility | Streak thresholds −1 | Your streak effects fire one cast sooner |
| **Thornwarden** | Attrition — DoT/HoT | +HoT per turn | DoTs on you tick 25% weaker | Your damage-over-time effects last +1 turn |
| **Aegis Sovereign** | Tank — shields, survivability | +max HP | Shields +15% | Your shields keep 25% strength instead of shattering |
| 💡 **Voidcaller** | Trickster — info war, anti-magic | ? | ? | ? (reserve slot if a 5th is wanted) |

⚠️ Note the deliberate tension: **Emberwright pushes big spells** (aligning
with TYPE_EFFECTS §7's big-spell goal) while **on-hit weapons push multi-hit
spam**. That's healthy — equipment becomes the lever that keeps *both*
archetypes viable, rather than the meta collapsing to one.

### 3.2 Which slots carry a set? ✅

The **five armor slots** — **Hat, Robe Top, Robe Bottom, Boots, Gloves** — are
the set ("primary robe set") slots. **Neck, Ring, and both hands** are always
free for weapons and tech.

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

> **Premium currency ("purple gems") only ever buys a shortcut. There must
> never be anything you *have* to pay gems to do.**

- ✅ **Allowed:** skipping/reducing crafting, enchanting and conversion
  **cooldowns**; "time crystals"; extra potion yield; buying better *odds*
  (Luck/drop-rate boosts).
- 🚫 **Never:** substituting for the **rare Tier III/IV components**, for
  **skill levels**, or for any step of the process itself. Every path must be
  completable — if slowly — without spending.

✅ Buying better *odds* at rare components is explicitly fine; buying the
components is not. The line is **acceleration, not access**.

✅ Rare Tier III/IV components are **Bound** (§6c), which is what keeps a
player-to-player market from quietly reselling what drops were meant to gate.

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
- ✅ **Motes also drop from gathering** in certain areas — a Pyro-attuned vein
  yields Pyro Dust alongside its ore. This gives gatherers their own path to
  motes, so the top of the crafting tree isn't gated behind combat alone.
- Mote **tier scales with monster (or node) level**, not player level — so
  farming low-level zones yields low-tier motes (mirrors the
  PROGRESSION_DESIGN rule that crafting XP scales with material tier, not
  player level).
- ✅ **Concrete rates live in per-monster / per-level loot tables**, decided
  alongside the monster catalogue rather than as a global curve.

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
- **Motes come from combat, not gathering** (§6.1) — so high-tier crafting
  requires *both* fighting and skilling. That interplay is a feature: neither
  a pure duelist nor a pure crafter can reach the ceiling alone.

### 6a.1 Skill → slot coverage ✅

Every slot now has a maker, and every gathering skill has a sink:

| Gathered from | Processed by | Produces | Slots |
|---|---|---|---|
| Foraging (fibers/cloth) | **Tailoring** | robes & armor | Hat, Robe Top, Robe Bottom, Boots, Gloves |
| Foraging (herbs) | **Potions** | consumables | — |
| Mining (gems) + other reagents | **Jewelry** | rings & amulets | Neck, Ring |
| Felling (wood) | **Woodcarving** | staves & wands | Main hand, Off hand |
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
meant to gate, quietly undoing "money buys time, never access."

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

### 6b.2 Consumable slots ⭐ ✅

> *"a limit of four item slots that potentially could raise up to eight or
> ten… those item slots could also be added with equipment."*

A deliberately **bounded** consumable inventory, so a stack of 100 potions
can't stall the game out. Baseline **4 slots**, growing to **8–10** through
progression and **equipment bonuses**.

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

✅ **Confirmed caps:**
- Proc-rate boosts are **additive percentage points, never multipliers** —
  e.g. `+10pp` (25% → 35%), with a **hard ceiling around +15pp** across all
  gear.
- Streak thresholds may drop by **at most 1** (3rd → 2nd cast). **Never to
  "every cast."**
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

## 8. Rarity ladder 📝 (answers GAME_DESIGN open question #4)

Proposal: **five rarities mapped 1:1 to the five mote tiers**, so the economy
reads consistently everywhere.

| Rarity | Mote tier | Rough shape |
|---|---|---|
| Common | Lesser | flat stats only |
| Uncommon | Minor | flat stats, small % |
| Rare | Major | a modifier + set membership |
| Epic | Greater | strong modifier, enchantable |
| Legendary | Master | build-defining; full set bonuses |

❓ Are set pieces exclusively Epic+? (Proposal: yes — sets are an endgame
pursuit; Common/Uncommon are the ladder up to them.)

---

## 9. Scaling down from the ceiling 📝

Having defined BiS, the ladder back down:

| Band | Level | What gear does |
|---|---|---|
| **Tutorial** | 1–9 | Flat HP only. Teaches "gear = survivability" with zero complexity |
| **Foundations** | 10–19 | Flat damage and shield %; first Uncommons; crafting unlocks |
| **Specialization** | 20–34 | First set pieces (3-piece bonuses); enchanting unlocks; Luck matters |
| **Mastery** | 35–44 | 4-piece bonuses; Epic drops; element enchants become the build |
| **Endgame** | 45–50 | 5-piece bonuses; Legendary/Master motes; the §2 ceiling |

📝 Rationale: modifiers arrive *after* the player understands the element
effects they modify. A level-12 player boosting Ignite rates before they've
felt a burn is noise, not depth.

---

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
| 8 | Set pieces Epic+ only? *(likely — deferred)* | §8 |

✅ Everything else in this document is decided. The design is ready to move to
a catalogue pass (concrete items, recipes, drop tables) whenever you are.

### Watch items (not blockers)

| # | Item | § |
|---|---|---|
| 11 | Element-enchant parity — if Arcane dominates, reduce its %/stack | §2.2 |
| 28 | Concrete drop rates land in per-monster loot tables | §6.1 |
| 27 | Per-recipe cooldown values land with the recipe catalogue | §6.0b |

---

## Changelog

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
