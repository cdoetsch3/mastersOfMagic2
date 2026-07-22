# Masters of Magic 2 — Type Effects (Element Side-Effects)

Design spec + balance review for the nine-element side-effect system.
Companion to [GAME_DESIGN.md](GAME_DESIGN.md) — priorities, charge rules, and
Haste referenced here are defined there.

Legend: ✅ decided · 📝 draft (needs review) · 💡 idea bank · ❓ open question · ⚠️ balance/abuse concern

Status: ✅ **Tiers 1–3 shipped (v0.9.0).** ⚠️ **A V2 expansion is now planned —
see §0 — which adds a fourth tier, renames Radiant→Sanctus, and changes the
shield counter math. Everything below §0 describes the SHIPPED nine-element
system and remains the source of truth until the expansion lands.**

---

## 0. V2 expansion 📝 (planned — not implemented)

Reconciled from an external inspiration doc ("Fantasy Game Elements & Enemy
Bestiary Design V2"). **This document stays the source of truth**; the
inspiration doc contributed the fourth tier, the macro-tier counter idea, and
the bestiary (now in [GAME_DESIGN.md](GAME_DESIGN.md) §5). Its other
proposals — a "Void" element, and a rescaled Waterlogged (+1 priority
bracket) — were **rejected**: Ethereal stays three elements, and our
Waterlogged (+10 priority, "your next action goes last") is better.

### 0.1 The twelve elements, in four tiers

| Tier | Name | Elements | Status |
|---|---|---|---|
| 1 | **Primal** | Aqua · Pyro · Flora | ✅ shipped |
| 2 | **Kinetic** | Electro · Aero · Geo | ✅ shipped |
| 3 | **Celestial** ⭐ NEW | **Solar · Lunar · Astral** | 📝 new tier |
| 4 | **Ethereal** *(was Tier 3)* | **Sanctus** *(was Radiant)* · Umbra · Arcane | 📝 renumbered |

✅ **Solar inherits the old Radiant Blind mechanic** verbatim (10% per charge
spent, 50% miss for 3 turns). **Sanctus** keeps the Ethereal slot but gets a
**brand-new effect** — the rename exists because "Radiant" and "Solar" read
as the same concept.

✅ **All three new effects are designed — see §4b (Celestial) and §4c
(Ethereal repairs).**

✅ **Naming final:** **Umbra** (matches shipped code) and **Sanctus** (§0.5).

### 0.5 ✅ Holy is renamed **Sanctus**

Latin *sanctus*, "holy, consecrated." Final. Keeps the roster fully
Latin/Greek (Aqua · Flora · Umbra · Arcane · Solar · Lunar · Astral ·
Sanctus = Latin; Pyro · Aero · Geo · Electro = Greek), and reads as
*consecration* rather than *brightness* — which matters now that Solar owns
light. Rejected alternates: Numen, Theo, Hieros (considered); Empyrean
(contains "pyr"), Aether/Caelum (collide with the Ethereal and Celestial tier
names), Lux/Lumen (light belongs to Solar).

### 0.2 ⚠️ Consequence: both Tier 3 and Tier 4 effect-webs must be rebuilt

This is the part that isn't obvious from the roster change. Our shipped Tier 3
triangle wired three *effect-layer* interactions between Radiant, Umbra and
Arcane:

| Old edge | Interaction | Fate under V2 |
|---|---|---|
| Radiant → Umbra | Blind burns away Creeping Dark | 💥 **Breaks** — Blind moves to Solar (T3), Umbra stays T4, so this becomes cross-tier |
| Umbra → Arcane | Dusk blocks Arcane Knowledge | ✅ Survives — both still Ethereal |
| Arcane → Radiant | Arcane spells are immune to Blind | 💥 **Breaks** — same reason |

Because effect-layer interactions are **within-tier only** (§5.6), the
expansion needs **five new interactions**, not zero:

- **Celestial (new):** Solar→Lunar, Lunar→Astral, Astral→Solar — see **§4b**
- **Ethereal (repair):** Sanctus→Umbra and Arcane→Sanctus, replacing the two
  that Blind's departure broke — see **§4c**

✅ All five are now specified. Note that **Astral→Solar reuses the retired
Arcane→Radiant mechanic** ("these spells are exempt from Blind") — it follows
Blind into the Celestial tier rather than being thrown away, and Arcane gets
a genuinely new anti-Sanctus edge instead.

### 0.3 ⚠️ New shield counter math (a real balance change)

Two layers now apply to shield damage. **They never stack** — same tier uses
the within-tier row, different tiers use the macro row:

| Relationship | Multiplier vs that shield |
|---|---|
| **Within-tier**, you counter their shield | **200%** *(unchanged — today's ×2)* |
| **Within-tier**, their shield's element counters you | **50%** ⭐ new |
| **Within-tier**, same element | 100% |
| **Macro-tier**, your tier counters theirs | **150%** ⭐ new |
| **Macro-tier**, their tier counters yours | **75%** ⭐ new |
| **Macro-tier**, neither (the opposite tier) | 100% |

⚠️ **This is the largest balance change in the expansion.** Today every
non-countering attack hits a shield at 100%. Under V2, **half of all
within-tier matchups drop to 50%** — attacking into the shield that counters
you becomes genuinely punishing, which sharply raises the value of shield
counter-picking and of Umbra's element-hiding. Requires a full re-run of the
9×9 (soon 12×12) mono-element sim, and it likely shifts the Aegis Sovereign
archetype's power in [ITEMS_DESIGN.md](ITEMS_DESIGN.md).

✅ **Macro-tier loop direction** — stated explicitly to avoid arrow-notation
confusion. **The higher tier beats the one below it, and the starter tier
beats the endgame tier:**

| Matchup | Winner |
|---|---|
| Kinetic vs **Primal** | **Kinetic (T2)** beats Primal |
| Celestial vs **Kinetic** | **Celestial (T3)** beats Kinetic |
| Ethereal vs **Celestial** | **Ethereal (T4)** beats Celestial |
| Primal vs **Ethereal** | ⭐ **Primal (T1)** beats Ethereal |
| T1↔T3, T2↔T4 (opposite tiers) | neutral — 100% both ways |

⭐ **Primal beating Ethereal is the anti-power-creep valve**: the starter
elements are the designed answer to the endgame tier, so a level-50 mage can
never simply out-tier everyone. Every other edge rewards progression.

⚠️ *Note: an earlier draft of this section had the loop running the other way
(Primal beats Kinetic, …). The table above is authoritative.*

### 0.4 Ripple into the other docs (not yet applied)

- ✅ **PROGRESSION_DESIGN §4:** **Celestial unlocks at L30, Ethereal at L45**
  (confirmed). Charge caps and spell placements are unaffected — but see the
  warning below.
- ⚠️ **Umbra and Arcane slip from L30 → L45.** Creeping Dark and Arcane
  Knowledge are *shipped* mechanics that players currently meet at L30; under
  V2 they become max-level content, and **L30–44 has no info-war or
  damage-stacking element at all**. Two knock-ons: the whole L30–44 band now
  learns Tier 3 through Solar/Lunar/Astral only, and **ITEMS_DESIGN's
  Voidcaller archetype** — whose counter-loop role leaned on Umbra's
  element-hiding — has no Umbra until L45, despite set pieces starting at
  L30. ✅ **Resolved: Voidcaller gets its own info-war identity from its set
  bonuses**, independent of Umbra (per §2.2/Q37). Partial relief for the
  L30–44 hole also arrives via **Lunar's New Moon phase**, which veils the
  caster's element for one turn in four (§4b.2).
- **ITEMS_DESIGN:** element enchants go from 9 to 12 (5 archetypes × 12 =
  **60** endgame builds); mote types gain three elements; the Voidcaller
  archetype's info-war identity leans on Umbra, which is now a *later* tier.
- **Engine:** `MagicElement` gains three values and a fourth `MagicTier`;
  `_applyOneHit`'s counter math becomes a multiplier lookup instead of a
  boolean ×2.

---

---

## 1. Definitions

✅ Decided terms used by every effect below:

1. **Spell cast** — anything EXCEPT charge. Charging only counts when an
   effect explicitly says so (Umbra is the one current exception, §4.2).
2. **Offensive spell** — any spell that negatively impacts the opponent.
   ✅ Discharge is an Offensive spell that is **not** a Damaging spell.
3. **Damaging spell** — any spell that deals damage to the opponent.
4. **Shield spell** — anything that creates a shield (including Barrier, a
   special shield).
5. **Aux spell** — any other spell that impacts the game and fits none of the
   above.

✅ **Miss semantics:** a "missed" offensive spell has **no effect** — not just
zero damage. A missed Discharge wipes nothing.

⚠️ **Fizzle vs miss — charge (implemented 2026-07-20, confirm intent):** a
**fizzle** (Static Feedback pulled charge below cost) leaves the spell uncast
and you **keep your charge** ("you'd still have 3 charge"). A **miss** (Blind)
still **spends** your charge. Both are otherwise inert. This resolves a
conflict: §5.4's "behaves like a charge / nothing is lost" is now scoped to
**streaks/procs/stacks only**, not charge — a miss does cost the charge. Flag
if a miss should instead refund charge like a fizzle.

✅ **Effect ticks are not hits or casts.** Ignite burn, Photosynthesis heals,
etc. can never trigger on-hit or on-cast effects. All triggers trace back to
an actual spell cast — no on-hit → on-hit → on-hit chains.

⚠️ **"Charge spent" = the cast spell's COST** (revised 2026-07-21, see
[ITEMS_DESIGN.md](ITEMS_DESIGN.md) §5b.3a). Not "charge lost." The two are
identical today — casting consumes everything — but they diverge under the
proposed **charge retention**, and the spell's cost is the meaningful number.

**This changes three effects for all players** and is NOT yet implemented:

| Effect | Old behavior | New |
|---|---|---|
| **Blind** (§4.1) | charge to 5, cast 1-cost Bolt → 50% | → **10%** |
| **Creeping Dark** (§4.2) | same cast → +5 stacks | → **+1** |
| **Arcane Knowledge** (§4.3) | any cast at 4+ charge | only spells **costing** 4+ |

Rationale: triggers should scale with a spell's real investment, not reward
overcharging and dumping it into something cheap. ⚠️ Requires a **re-run of
the 9×9 mono-element sim** when implemented — Radiant and Umbra both get
quieter, and both already under-perform against effect-blind AI.

✅ **Every tier is a closed counter-triangle** with two layers:
- **Shield layer (all tiers):** attacks deal double damage to the countered
  element's shield — the existing rule, now explicit in Tier 1 as well.
- **Effect layer (per tier):** the tier-specific interactions listed in each
  tier's table below.

---

## 2. Tier 1 — The Primal Forces

Tempo and sustain. **Triangle: Pyro burns Flora, Aqua douses Pyro, Flora
shrugs off Aqua.**

| Counter | Shield layer | Effect layer |
|---|---|---|
| Pyro → Flora | Pyro attacks ×2 vs Flora shields | Ignite clears all Photosynthesis stacks |
| Aqua → Pyro | Aqua attacks ×2 vs Pyro shields | Casting any Aqua shield clears Ignite |
| Flora → Aqua | Flora attacks ×2 vs Aqua shields | ≥1 Photosynthesis stack blocks Waterlogged |

❓ Confirm the shield-layer direction matches the effect layer as tabled
(Pyro > Flora > Aqua > Pyro).

### 2.1 Aqua — Waterlogged
- 📝 **Trigger:** every 3rd consecutive Aqua cast.
- ✅ **Effect:** opponent's next planned action is dragged **+10 priority**
  (slower). Includes charges. ✅ Does **not stack** — a second trigger
  refreshes, never +20.
- ✅ **Blocked** entirely if the opponent holds ≥1 Photosynthesis stack.

**Analysis (priority table: instant 1 · shield 3 · channel 4 · quick 5 ·
aux 7 · regular 9):** at +10, every waterlogged action — even an instant
attack (1 → 11) — resolves after every unmodified action. Waterlogged is
effectively **"your next action goes last."**
- The charge combo stands: a slowed channel (4 → 14) resolves after
  Discharge/Overload (7) — waterlog one turn, Discharge the next, and their
  charge gain lands after the wipe. ✅ A real, learnable tempo combo.
- If both players are slowed, relative order among slowed actions follows
  (priority + 10), preserving the original ordering.

### 2.2 Pyro — Ignite
- 📝 **Trigger:** 25% chance on hit. ✅ A hit fully absorbed by a shield can
  still ignite — the shield doesn't block the proc.
- ✅ **Effect:** burns for **10% of the attack's total (raw) damage** at the
  end of the application turn and each of the **next 2 turns** — 3 ticks,
  30% total. (A proc on T2 burns through the end of T4.)
- ✅ **Re-proc refreshes** the window (new 3-tick clock from the new attack);
  never stacks, never adds.
- ✅ **Burn is regular damage: it hits the shield first.** Ticks in the
  end-of-turn damage band at **E8** (§5.1).
- ✅ **Cleansed by** casting any Aqua shield; **clears** all Photosynthesis
  stacks on application (§2 table). The short refresh-only window is
  deliberate — it keeps the Aqua-shield cleanse worth casting.

### 2.3 Flora — Photosynthesis
- ✅ **Trigger:** every Flora cast adds a stack (**max 3** — trimmed from 5
  after sims showed even 5-with-decay dominating; see §8).
- ✅ **Effect:** heals **1% max HP per stack** in the end-of-turn heal band
  (§5.1).
- ✅ **Decay:** each turn without Flora activity (a Flora cast **or charge**)
  sheds one stack — an ongoing commitment, mirroring Creeping Dark's activity
  rule. The shedding turn still heals at the pre-decay count (bookkeeping runs
  last). Per §5.4, a fizzled/missed Flora cast counts as activity (it behaves
  like a charge of the cycling element).
- ✅ **Cleared** (all stacks) when Ignite is applied; **grants** Waterlogged
  immunity while ≥1 stack.

⚠️ Stall risk — see **Mechanics to Watch (§8)** (largely defused by decay +
Fatigue).

---

## 3. Tier 2 — The Kinetic Forces

Action-queue disruption. **Triangle: Electro shocks Aero, Aero weathers Geo,
Geo grounds Electro.**

| Counter | Shield layer | Effect layer |
|---|---|---|
| Electro → Aero | Electro attacks ×2 vs Aero shields | Any Electro-type attack wipes the Tailwind streak (already-granted Haste is kept) |
| Aero → Geo | Aero attacks ×2 vs Geo shields | An active Tailwind streak of 3+ makes you immune to Stagger |
| Geo → Electro | Geo attacks ×2 vs Electro shields | While holding a Geo-type shield you cannot be hit by Static Feedback |

### 3.1 Electro — Static Feedback
- ✅ **Trigger:** **20%** chance on hit (raised from 10%).
- ✅ **Effect:** removes one charge from the opponent (no-op at 0 charge).
- ✅ **Fizzle, precisely:** if the opponent locked in a spell (not a charge),
  the Electro hit resolves **first**, and the proc drops their charge below
  the spell's cost — the spell **is simply not cast**. They keep their
  remaining charge (locked a 4-cost with 4 charge → static leaves them at 3
  charge, spell uncast, turn wasted). Most procs just strip a charge;
  the full fizzle needs first-strike AND proc AND a locked spell.
- ✅ Electro is deliberately the **fast-spells element** — flat on-hit chance
  favoring cheap quick attacks is its identity. Not converting to
  charge-scaled procs.
- ✅ Blocked entirely by an active Geo-type shield (§3 table).
- ⚠️ Frustration ceiling acknowledged — see **Mechanics to Watch (§8)**.
- ✅ No special case for charge-scaled spells: any locked spell fizzles if
  the proc drops remaining charge below its cost. (Correction from an earlier
  draft: **Overload is a 2-cost spell that detonates the ENEMY's charge** —
  ~10 damage per enemy charge — not a spend-your-own-charge spell.)

### 3.2 Aero — Tailwind
- ✅ **Trigger (as implemented):** every consecutive Aero cast **from the 3rd
  onward**; casting any non-Aero spell resets the counter. (One threshold — 3
  — for both the grant and the Stagger immunity; the earlier "after the 3rd"
  wording implied 4, flag if 4 was intended.)
- ✅ **Effect:** grabs **Haste** — Haste is a single token only one player
  can hold; while the streak lives, the Aero caster re-grabs it every cast.
- ✅ The streak is wiped by any Electro-type attack (already-held Haste is
  not removed — you keep the token until it's seized normally).
- ✅ At a streak of 3+, the caster is immune to Stagger (§3 table).
- ✅ Streaks get a **standardized consecutive-counter pip** in the HUD
  (§5.4).

### 3.3 Geo — Stagger
- ✅ **Trigger:** every 4th consecutive Geo cast.
- ✅ **Effect (reworked):** the opponent's **next offensive spell deals 50%
  damage**. No more replace-the-queued-action — simpler to read, and the
  outplay stays: when you can count that Stagger is coming, throw a cheap
  attack into it (lose 50% of an 8-damage Flick, not 50% of a 5-charge
  Cataclysm).
- ✅ Whiffs against a Tailwind streak of 3+ (§3 table).
- 📝 **Planned addition:** Stagger will **also interrupt sustained spells**
  (see [ITEMS_DESIGN.md](ITEMS_DESIGN.md) §5b.4), making Geo the anti-sustained
  element — a concussive blow breaking concentration. Not yet implemented;
  depends on sustained spells existing.
- ✅ **The debuff lingers until consumed** by the next offensive spell — it
  never expires on its own. Consuming it with a non-damaging offensive spell
  (Discharge) is a legal, harmless "stagger-eater" — accepted as another
  outplay, at the price of a 3-cost spell and a turn.
- ✅ Derived from §5.4: a **missed** spell doesn't consume Stagger (a miss
  behaves like a charge — nothing triggers, nothing is lost).

---

## 4. Tier 3 — The Ethereal Forces ✅ SHIPPED *(becomes Tier 4 under V2)*

⚠️ **Read this section as shipped-today truth.** Under the V2 expansion (§0)
this tier is renumbered **Tier 4**, **Radiant is renamed Sanctus and loses
Blind** (Blind moves to the new Tier 3 element **Solar**, §4b.1), and two of
the three effect-layer edges below are replaced — see **§4c**. Umbra and
Arcane are unchanged apart from their unlock level (L30 → L45).

Rule-bending late-game mechanics. **Triangle: Radiant banishes Umbra, Umbra
corrupts Arcane, Arcane unravels Radiant.**

| Counter | Shield layer | Effect layer |
|---|---|---|
| Radiant → Umbra | Radiant attacks ×2 vs Umbra shields | A Blind proc clears **all** Creeping Dark stacks |
| Umbra → Arcane | Umbra attacks ×2 vs Arcane shields | You cannot gain Arcane Knowledge stacks while under Dusk or Midnight |
| Arcane → Radiant | Arcane attacks ×2 vs Radiant shields | Arcane spells are exempt from Blind (they never miss) |

### 4.1 Radiant — Blind
- ✅ **Trigger (reworked):** **10% per charge spent** on the attack — the
  brighter the spell, the more blinding. (A 0-cost attack can't blind; a
  5-charge attack is 50%.) Adopts the charge-scaled proc idea: Radiant is
  now a big-spell element.
- ✅ **Effect (reworked):** for the opponent's **next 3 turns**, each
  offensive spell they cast has a 50% chance to miss (miss = no effect, §1;
  charge still spent). Time-boxed by turns — defensive casts and charging
  are deliberate counterplay, but they *spend* the window rather than
  preserving it.
- ✅ Arcane spells never miss (§4 table).
- ✅ Rolls **on attack**, including fully-shielded hits (mirrors Pyro).
- ✅ Re-proc while blinded **refreshes** the 3-turn window — same behavior as
  Ignite; never stacks.

### 4.2 Umbra — Creeping Dark
- ✅ **Stacks (reworked):** casting an Umbra spell grants **+1 stack per
  charge spent** (three 5-charge spells → Midnight). Decay: **−1 per
  turn** in which the caster neither charged Umbra nor cast an Umbra spell
  (charging pauses decay but grants nothing — the explicit exception to
  definition 1). A forfeited turn is neither, so it decays.
- ✅ **Thresholds:** 5+ → **Shadow**, 10+ → **Dusk**, 15 → **Midnight**.
  **Cap: 15** — no banking above it. (Equipment will eventually be able to
  modify the cap.)
  - **Shadow:** enemy can't see what element the caster is charging.
  - **Dusk:** enemy can't see the caster's charge or health bar.
  - **Midnight:** enemy can't see *their own* charge or health bar.
- ✅ A Blind proc clears all stacks (§4 table). While your opponent's
  darkness has you under Dusk or Midnight, you can't gain Arcane Knowledge
  stacks.
- ⚠️ **Midnight must not read as a bug** — needs loud visual language (shadow
  veil over the UI, an unmistakable "MIDNIGHT" banner), per the move-timer
  lesson: waits and hidden state must never look like freezes.
- ⚠️ **Honest-client-only for now** — a modded client can read the revealed
  lockstep state. Accepted for casual; see **Mechanics to Watch (§8)** for
  the server-authoritative rework.

### 4.3 Arcane — Arcane Knowledge
- ✅ **Trigger:** casting a **4+ charge Arcane spell** grants one
  **Arcane Knowledge** stack (max 5).
- ✅ **Effect:** **+5% damage per stack** (up to +25%), applying to **every
  spell type** — not just Arcane. Stacks are **permanent for the duel**:
  never cleared by casting other spells/elements, never consumed on use.
  (Reduced from +10%/stack when made permanent + universal.)
- ✅ **Blocked** while under the opponent's Dusk or Midnight (§4 table).
- ✅ **Role:** the big-spell element and the anti-turtle answer — 5 stacks is
  20+ charge of committed Arcane casting, and the payoff at full stacks is an
  Empowered spell hitting for **250%** (100% base + 25% AK = 125%, ×2 from
  Empower) — enough to crack heavy-shield strategies.
- ✅ **Empower** is an existing spell (not element-bound): it makes the next
  turn deal double damage. No further spec needed here.
- ✅ "4+ charge" means **charge spent ≥ 4** — spending is the commitment.
  ⚠️ **Revised 2026-07-21:** "charge spent" now means **the cast spell's
  cost**, not the charge consumed — see the definition note below.
  Casting consumes ALL charge, so a cheap Arcane spell cast while holding 4
  charge qualifies. Same rule for Umbra's per-charge stacks (§4.2):
  **spent**, consistently.

---

## 4b. Tier 3 — The Celestial Forces 📝 (V2, not implemented)

The sky tier. Where Primal is elemental matter and Kinetic is force,
Celestial is **timing and position**: a public clock, a rhythm to schedule
around, and a way to stop being where the shield is.

**Triangle: Solar eclipses Lunar, Lunar anchors Astral, Astral slips Solar.**

| Counter | Shield layer | Effect layer |
|---|---|---|
| Solar → Lunar | Solar attacks ×2 vs Lunar shields | A **Blind proc locks the moon at New Moon** for the 3-turn Blind window — a literal eclipse |
| Lunar → Astral | Lunar attacks ×2 vs Astral shields | A **Lunar attack strips 1 Alignment stack**; on **Full Moon it strips all** |
| Astral → Solar | Astral attacks ×2 vs Solar shields | **Astral spells are exempt from Blind** — they never miss |

*(Astral→Solar is the retired Arcane→Radiant mechanic, following Blind into
its new tier rather than being discarded — see §0.2.)*

### 4b.1 Solar — Blind ✅ *(inherited verbatim from Radiant)*

Spec unchanged from §4.1: **10% per charge spent**, opponent's next 3 turns
each carry a **50% miss chance on offensive spells**, re-proc refreshes,
rolls on attack including fully-shielded hits. Only two things change:

- The **immunity** edge moves from Arcane to **Astral** (§4b table).
- The **cleanse** edge moves from "clears Creeping Dark" to "**locks the
  moon**" (§4b.3), because Umbra is now a different tier.

⚠️ **A Blind proc no longer clears Creeping Dark.** That job passes to
Sanctus's Absolution (§4c.1) — otherwise Umbra would have gained a free
buff out of the renumbering.

### 4b.2 Lunar — Phases of the Moon 📝

**The only public, shared, fully-deterministic piece of state in the game.**

- ✅ **A single global clock, not a personal one.** The moon advances **every
  turn** regardless of what either player casts: `phase = turnNumber mod 4`,
  starting at **New Moon on turn 1**. It is **visible to both players at all
  times**, along with a preview of the next phase.
- **You do not control the moon — you schedule around it.** That is the whole
  identity. Every other element rewards *doing a thing*; Lunar rewards
  *doing the right thing on the right turn*. It's a planning element in a
  simultaneous-turn game, which is exactly where planning has teeth.
- ✅ **Phase effects modify Lunar spells only** — they never touch your other
  elements. Both players get the same moon, so a Lunar mirror is symmetric.

| Turn mod 4 | Phase | Effect on **your Lunar spells** |
|---|---|---|
| 1 | 🌑 **New Moon** | Attacks **−25%**. Your cast is **veiled**: the opponent cannot see which element you charged or cast this turn |
| 2 | 🌒 **Waxing** | Attacks **+25%** |
| 3 | 🌕 **Full Moon** | Attacks **+50%** |
| 0 | 🌘 **Waning** | Lunar **shields +50% strength** and Lunar **heals +50%**; attacks unmodified |

- **Rhythm: hide → build → strike → defend.** No dead beat, one clear peak,
  one clear trough. Average attack modifier across the cycle is **+12.5%**,
  paid for by a forced weak turn — cheap on paper, but the real cost is that
  a Lunar player's best turn is *public knowledge*, so the opponent can
  pre-shield Full Moon or bait the New Moon trough.
- ✅ **New Moon's veil partly fills the L30–44 info-war hole** left by Umbra
  moving to L45 (§0.4) — one veiled turn in four, no stacking, no
  accumulation. A taste of the mechanic, not a replacement.
- ✅ **Determinism:** derived from the turn counter, so it needs no RNG, no
  state sync, and no netcode work at all. Both clients compute it.
- ❓ **Fatigue interaction:** at turn 50+ the duel is on the sudden-death
  clock. The moon keeps turning; no special case. Confirm that's fine.
- ⚠️ **Watch:** a 4-turn cycle against duels that typically run 10–25 turns
  means 3–6 full cycles. If playtests show Lunar players simply passing on
  New Moon, the trough is too deep — soften to −15% before touching the peak.

### 4b.3 Solar's eclipse — the Solar → Lunar edge 📝

When a **Blind proc** lands on a mage, their moon is **locked at 🌑 New Moon**
for the same 3-turn window. Not "reset to New Moon" — *frozen* there.

- Destroys the Lunar player's entire rhythm rather than shaving a number off
  it, which is what an effect-layer counter should do.
- The lock is **per-mage**, not global: the Solar caster's own moon keeps
  turning. So the global clock stays global, and the eclipse is a personal
  affliction — consistent with how every other debuff works.
- Stacks naturally with Blind's own 50% miss chance; a blinded Lunar mage is
  missing half their casts *and* stuck at −25%. That's the intended weight of
  a within-tier counter.

### 4b.4 Astral — Astral Alignment 📝

- ✅ **Name: Astral Alignment** (stacks: *Alignment*). The working name "Phase
  Shift" was rejected because **`Phase` is already a shipped aux spell**
  ("next offensive spell ignores shields", GAME_DESIGN §3) — "Phase" and
  "Phase Shift" in the same battle log is a readability trap.
- ✅ **Trigger:** **+1 stack for each turn you cast an Astral spell**, at any
  cost. **Max 5.**
- ✅ **Decay:** **−1 per turn** in which you cast no Astral spell (same shape
  as Photosynthesis, §2.3). Charging neither grants nor decays.
- ✅ **Effect:** **5% of the attack's damage per stack bypasses the shield**
  and strikes health directly. **The remaining damage still hits the shield
  normally** — Alignment *splits* an attack, it does not shrink it.
- ✅ **Worked example** (4 stacks = 20%, a 25-damage spell into a 40-point
  shield): **5 damage goes straight to health**; the other **20 hits the
  shield**, leaving it at 20. Nothing is lost.
- ✅ **The pierced portion ignores the shield's counter math.** It never
  touches the shield, so it is never multiplied by the ×2 / ×0.5 / ×1.5 /
  ×0.75 shield table (§0.3) — it lands on health at **100%**. This is the
  point: Alignment is worth *most* exactly when the shield matchup is worst
  for you. In a 50%-into-their-shield matchup, your 25% pierce is the only
  full-value damage you have.
- ✅ **Role: the designed anti-turtle answer**, and a deliberately *sharp*
  one — against an **unshielded** opponent Alignment does **literally
  nothing**, since all damage was hitting health anyway. That's not a flaw to
  patch; it's what keeps a 25% unconditional-sounding number honest.
- **Contrast with the other stackers, on purpose:** Arcane rewards *big*
  casts (cost 4+), Umbra rewards *charge dumped*, Astral rewards
  **consistency** — cast it every turn or watch it drain.

#### Resolution order — ✅ split first; it is provably equivalent

The intuition that we should hit the shield first (so a broken shield lets
the rest through) is right to check, and the answer is that **the two orders
give identical results**, so we take the simpler one.

Order A — split first: pierce → health; remainder → shield; overflow →
health.
Order B — shield first: whole attack → shield; overflow → health; then
pierce.

They agree because **both the pierced portion and the shield's overflow land
on health at 100%**, so it doesn't matter which arrives first.

| Case | Order A | Order B |
|---|---|---|
| 25 dmg, 20% pierce, **10-pt** shield | 5 → hp; 20 vs 10 breaks it, 10 overflow → hp = **15 hp** | 25 breaks 10, 15 overflow → hp = **15 hp** ✅ |
| 25 dmg, 20% pierce, 10-pt shield, **×2 counter** | 5 → hp; 5 raw ×2 breaks the shield, 15 raw overflow → hp = **20 hp** | 5 raw ×2 breaks it, 20 raw → hp = **20 hp** ✅ |
| 25 dmg, 20% pierce, **40-pt** shield | 5 → hp, shield 40→20 = **5 hp** | *(the shield absorbs everything — pierce never happens)* ❌ |

⚠️ **The third row is the one that matters.** "Shield first" only stays
equivalent if the pierce is still applied afterwards; if it's implemented as
"see whether the shield eats it all," the mechanic silently disappears
against exactly the shields it exists to beat. **Implement Order A.**

- ⚠️ **Precedence:** damage *routing* is a new step. Insert into §5.2 as
  step 5, after all damage modifiers and before shield application: compute
  final damage, split off `round(damage × 0.05 × stacks)` to health, run the
  remainder through normal shield math.
- ✅ **Barrier is pierced too.** Against a **Barrier** (2-charge, blocks 100%
  of all damage, dies to the first hit), the Alignment percentage still gets
  through **and the Barrier still pops**. A Barrier that hard-stopped the one
  mechanic built to beat shields would make Astral a dead pick into any
  Barrier deck.
- ⚠️ **Watch (stacking with Phase):** the aux spell `Phase` already grants
  100% shield bypass for one attack. 5 stacks + Phase is not additive past
  100% — Phase simply wins that turn. Make sure the engine can't double-route
  the same damage.
- ⚠️ **Watch (ITEMS):** this directly attacks the **Aegis Sovereign**
  archetype, on top of the §0.3 shield-math change already hitting it. Two
  nerfs from two directions in one expansion; sim before shipping either.

---

## 4c. Tier 4 repairs — Sanctus 📝 (V2, not implemented)

The two Ethereal edges that Blind's departure broke (§0.2), rebuilt around
Sanctus's own mechanic.

| Counter | Shield layer | Effect layer |
|---|---|---|
| Sanctus → Umbra | Sanctus attacks ×2 vs Umbra shields | **Absolution strips 5 Creeping Dark stacks** from the opponent — consecration burns off the dark |
| Umbra → Arcane | *(unchanged, §4)* | No Arcane Knowledge while under Dusk or Midnight |
| Arcane → Sanctus | Arcane attacks ×2 vs Sanctus shields | An **Arcane attack resets the target's Sanctus streak to 0** — Absolution is pushed 3 casts away again |

### 4c.1 Sanctus — Absolution 📝

⚠️ **Revised.** The first draft (purge + heal 10/20 on *every* Sanctus cast)
was **too strong** — a per-turn heal stapled to a per-turn cleanse. Sanctus
is now a **streak element with no healing at all**.

- ✅ **Trigger:** **every 3rd consecutive Sanctus spell** fires Absolution.
  Same shape as Aqua's every-3rd (§5.4), and Sanctus joins the streak-element
  group: **casting any other element resets the count to 0.** Charging
  neither advances nor breaks it (definition 1).
- ✅ **Effect:** **remove one debuff from yourself, at random.** No healing.
- ✅ **Resolves at end of turn in the heal band (E1–E3)** — before Ignite's E8
  tick, so a burn you just purged doesn't land one last hit. Survivability
  first (§5.1).
- ✅ **Purges debuffs only, never your own buffs** — it will not eat your
  Photosynthesis, Astral Alignment, or Arcane Knowledge stacks.
- ✅ **"At random" is netcode-safe** *provided* the roll draws from the
  **shared per-turn seed** (§5.5), exactly like Ignite and Blind procs. It
  must not use client-local RNG or the two clients will disagree about which
  debuff vanished and diverge immediately.
- 💡 **Alternative if the randomness grates:** a fixed severity order
  (**Blind → Ignite → Waterlogged → Stagger → Static**) is equally
  deterministic and makes Absolution a reliable answer to the *worst* thing
  on you. Random is the more interesting version — it means a Sanctus player
  can't count on stripping the Blind — but it also means the payoff for three
  committed casts can be "you removed Static Feedback." Cheap middle ground:
  random, but weighted toward severity.
- ❓ **Open — Fatigue:** recommend Absolution **cannot** purge it. Fatigue is
  the anti-stall sudden-death clock (§8); an element that switches it off
  rebuilds the exact stall meta it exists to kill.

✅ **Never a dead cast — Absolution banks Grace.** With healing removed,
Absolution would otherwise do nothing at all against the five elements that
apply no debuffs (Flora, Aero, Astral, Umbra, Arcane are self-buff
elements) — Sanctus's identity would be blank for whole duels through no
fault of the player. So:

> **If Absolution fires with no debuff to remove, you gain **Grace**
> instead.** The next debuff applied to you is blocked outright.

- ✅ **Grace: max 1, no stacking, persists until consumed.** It does not
  expire on its own — same shape as Empower's banked "next spell" (and the
  §7 ruling that Stagger lingers until consumed).
- ⚠️ **Naming:** the working name for this was "Ward," which **collides with
  the shipped `Ward` spell** (1-charge shield, priority 3,
  [spellbook.dart](packages/mom_engine/lib/src/spellbook.dart)). **Grace** is
  the name; alternates considered and free: Benediction, Reprieve, Sanctity.
- ✅ Grace does **not** block Fatigue, for the same reason Absolution can't
  purge it.
- ✅ **`Hallow`** (§4c.4) is the element-agnostic spell that grants the same
  buff. Both sources share the max-1 cap.

### 4c.2 Sanctus → Umbra — consecration burns the dark 📝

Each Absolution strips **5 Creeping Dark stacks** from the opponent — exactly
one threshold band (§4.2: 5 = Shadow, 10 = Dusk, 15 = Midnight).

- **Softer and more interesting than the old Radiant edge**, which cleared
  *all* stacks in one proc. Sustained Sanctus play now holds an Umbra mage
  down a tier of darkness per cast rather than deleting their resource on a
  coin flip — a grind, not a light switch.
- The strip is **not** conditional on hitting; casting Sanctus is enough.

### 4c.3 Arcane → Sanctus — the seal 📝

An **Arcane attack resets the target's Sanctus streak to 0.** Absolution
goes back to being three committed casts away.

- Thematically exact: Arcane *unravels*, and what it unravels here is the
  accumulated ritual rather than the effect itself.
- ✅ Consistent with §5.4 — the Sanctus streak is an ordinary consecutive
  counter, and this is simply another thing that resets it.

✅ **Un-gated is correct — the gate is Arcane's own economy.** A concern was
raised that an Arcane player attacking every turn would hold the Sanctus
counter at 1 forever and Absolution would never fire. It doesn't hold,
because **Arcane is the big-spell element**: its whole identity is cost-4+
casts, which means spending most turns **charging**, and charging is not a
cast and therefore **resets nothing** (definition 1). A big-Arcane player
naturally attacks roughly once every five turns — easily slow enough for a
Sanctus player to string three together.

To *deny* Sanctus, the Arcane player must throw **cheap attacks every
turn** — and every cheap attack is a turn that earns **no Arcane Knowledge
stack**. That is exactly the shape a good counter should have: available,
effective, and paid for in the counter-er's own currency. The Arcane player
chooses between building damage and suppressing the cleanse; they don't get
both.

- ✅ Fizzled, missed, and fully-shielded attacks follow the §5.4 rule and
  **do not** reset the streak (nothing triggers, nothing is penalized).

### 4c.4 New spell — `Hallow` 📝

An **element-agnostic aux spell** that grants **Grace** (§4c.1) directly, so
status defence isn't locked behind playing Sanctus. Sanctus earns Grace as a
consolation prize; `Hallow` lets any loadout buy it deliberately.

| Field | Value |
|---|---|
| **Name** | **Hallow** ✅ *(checked against all 25 shipped spell ids — no collision)* |
| **Charge cost** | **2** |
| **Priority** | **7** (aux) |
| **Effect** | Gain **Grace**: the next debuff applied to you is blocked outright |
| **Unlock** | 📝 **L25**, alongside Overload / Empower / Rampart |

- ✅ **Name checked.** The shipped roster is Aegis · Barrage · Barrier ·
  Blast · Bolt · Bulwark · Cataclysm · Discharge · Drain · Empower · Flick ·
  Flurry · Hasty · Jolt · Leech · Overload · Phase · Quicken · Rampart ·
  Ruin · Sanctuary · Sap · Surge · Volley · **Ward**. "Hallow" is free, is a
  terse verb like Ruin/Phase/Surge/Jolt, and echoes **Hallowmarch**, the
  Sanctus region (GAME_DESIGN §5). Alternates also free: *Anoint*,
  *Consecrate*, *Benediction*, *Vigil*.
- ✅ **Shares the max-1 Grace cap with Absolution** — casting `Hallow` while
  already holding Grace is a wasted turn, exactly like re-casting Empower.
- ⚠️ **Priority 7 means quick attacks beat it.** A priority-5 Jolt or Flick
  lands its proc *before* Grace exists, so `Hallow` is a **pre-emptive** tool,
  not a reaction to an attack you can see coming. Deliberate: shields already
  occupy the fast defensive slot at priority 3, and a reactive
  status-immunity at that speed would be strictly better than they are.
- ❓ **Open:** does `Hallow` belong to a single element or stay neutral like
  Empower/Quicken/Phase? Recommend **neutral** — it's the counterplay to
  every status element, and binding it to one element would hand that element
  a monopoly on status defence.
- 💡 Later: a 4-charge upgrade that grants **2** Grace, if playtests show one
  isn't worth a turn.

---

## 5. Cross-cutting rules

### 5.1 Turn phases — start / main / end resolution ✅

Three phases, three separate priority lanes that **never mix** — an E-lane
effect can never race a main-phase spell.

| Phase | Lane | Band order |
|---|---|---|
| **Start** | S1–S10 | heals S1–S3 · damage S4–S8 · bookkeeping S9–S10 *(empty for now — reserved)* |
| **Main** | 1–10 | existing spell priority, unchanged |
| **End** | E1–E10 | **heals E1–E3** (Photosynthesis ~E2) · **damage E4–E8** (Ignite E8) · **bookkeeping/expiry E9–E10** |

✅ Decided rules:
1. **Survivability first:** in the start and end lanes, heals always resolve
   before damage — a Photosynthesis player with a burning DoT heals, *then*
   burns. Bookkeeping/expiry always last. Same band order in both lanes.
2. **Deaths are instant.** No phase-boundary grace: the priority system plus
   Haste means ties are impossible, so the first effect that drops a player
   to 0 ends the duel.
3. **Haste breaks ties in every lane** — start, main, and end. Explicit,
   accepted downside: if both players carry symmetric end-of-turn damage at
   lethal HP, the Haste holder's tick resolves first and **they die first**.
   Haste is *current* Haste at resolution time — nobody remembers who held
   it when an effect was applied.
4. Same numbering convention (1 = earliest) in every lane, prefixed S/E in
   docs and code so a bare number always means main-phase.

### 5.2 Effect precedence on a single committed action ✅
Fixed, documented order (lockstep clients must agree or state diverges):

1. **Fizzle check** (Electro Static Feedback)
2. **Priority modification** (Aqua Waterlogged)
3. **Miss roll** (Radiant Blind)
4. **Damage modifiers** at resolution: additive bonuses first (Arcane
   Knowledge +5%/stack, 📝 V2: Lunar phase modifier), then multipliers
   (Empower ×2, Stagger ×0.5).
   Example: 5-stack AK + Empower + Staggered = 100% + 25% → ×2 → ×0.5 = 125%.
5. 📝 **V2 — damage routing** (Astral Alignment, §4b.4): split
   `round(damage × 0.05 × stacks)` off the final figure and send it straight
   to health; the remainder proceeds to shield math. The aux spell `Phase`
   short-circuits this — it routes 100% and Alignment adds nothing.
6. **Shield application** — the §0.3 counter multipliers apply here, to the
   non-pierced remainder only.
7. Normal resolution → end phase (§5.1).

*(Geo's old replace-the-action mechanic is gone, so there is no "replace"
step.)*

### 5.3 Cleanse & immunity web ✅
Consolidated in the per-tier tables (§2, §3, §4). Pattern: every tier's
effect-layer triangle IS its cleanse/immunity web. Surface these in tooltips.

### 5.4 Streaks, stacks & HUD 📝

**Consecutive-cast streaks** (reset when you cast any other element): Aqua
(every 3rd), Aero (after 3rd), Geo (every 4th), 📝 V2: **Sanctus** (every 3rd
→ Absolution; also reset by an Arcane attack, §4c.3). ✅ Arcane has **no
streak**
(Arcane Knowledge persists regardless of what else is cast).
- ✅ Charging neither advances nor breaks a streak (definition 1). Confirmed
  edge: a Tailwind streak of 3+ keeps its Stagger immunity through charging
  turns — intended.
- ✅ **Fizzled and missed casts behave exactly like a charge** for every
  counter and trigger: they don't advance streaks, don't reset them, don't
  proc on-cast/on-hit effects, and don't grant stacks (no AK from a missed
  4+ Arcane cast, no Umbra stacks from a fizzled Umbra spell). Nothing
  triggers, nothing is penalized.

**Persistent stacks** (survive element switching): Photosynthesis (0–5),
Creeping Dark (0–15, ±per §4.2), Arcane Knowledge (0–5, permanent),
📝 V2: Astral Alignment (0–5, −1/turn without an Astral cast).

📝 **V2 HUD additions:** the **moon phase** (§4b.2) is not a per-mage badge —
it is **shared, always-visible chrome** with a next-phase preview, since both
players plan around it. An **eclipse lock** on a mage, by contrast, is a
normal debuff badge.

✅ **HUD rules:**
- One **standardized consecutive-counter pip** design, reused for every
  streak element.
- Visually separate **"my buffs / streak counters"** from **"debuffs
  afflicting me"** — two distinct zones or styles, so a player never has to
  parse which side an icon belongs to.

### 5.5 Determinism & netcode ✅
- All proc rolls (Ignite, Static, Blind) draw from the shared per-turn seed —
  already supported by the lockstep engine. No netcode changes needed.
- Umbra is display-layer only; both clients keep identical state.
- The strict orderings in §5.1–§5.2 keep the seeded rolls identical on both
  clients.

### 5.6 Tier access ✅
- ✅ The three triangles are fully closed: effect interactions and the
  shield-double rule both follow the same within-tier triangles; there are
  no cross-tier effect interactions.
- ✅ Tiers are level-gated: **Primal L1, Kinetic L15, Celestial L30,
  Ethereal L45** — see
  [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) for the full unlock
  schedule, slots, and XP curve.

### 5.7 Loadout pressure 📝
Consecutive-cast triggers push mono-element play; loadouts hold 3 elements.
Streak elements (Aqua/Aero/Geo) punish switching; persistent-stack elements
(Flora/Umbra/Arcane) tolerate it. That's a real strategic axis — confirm
deliberate, and watch whether mono-element dominates.

---

## 6. RNG texture 💡

Post-rework: Radiant is charge-scaled (variance shrinks as spells grow),
Electro is deliberately flat-and-fast, Pyro is flat with scaling damage. If
playtests show coin flips deciding games in a way that grates, the remaining
levers are pseudo-random distribution or "guaranteed every Nth hit" — same
average rate, far less variance. Back pocket; don't pre-optimize.

---

## 7. Big-spell play — adopted & shelved 💡

⚠️ The concern: cast-counting and flat on-hit triggers reward cheap fast
actions over the charged-nuke drama the game is built around.

**Adopted:**
- **Radiant** → 10% per charge spent (§4.1) — the marquee charge-scaled proc.
- **Arcane** → Arcane Knowledge on 4+ charge casts (§4.3) — the deterministic
  big-spell threshold, and the designated anti-shield finisher.
- **Electro** stays fast **on purpose** — it is the tempo element; the system
  needs one.

**Shelved until playtests demand them:**
- Charge-held triggers ("at end of turn holding 4+ charge, gain X").
- Streaks counting **charge spent** instead of casts (global lever; heavier
  HUD).
- Charge-scaling Pyro's proc chance (its damage already scales).

---

## 8. Mechanics to Watch ⚠️

Suspected-but-unproven risks. Not blockers — playtest, then act.
Quantitative checks: `dart run tool/balance_sim.dart 500` in
`packages/mom_engine` (AI duel batches with length/outcome stats).

✅ **Long duels are a feature, not a fault (human playtest, 2026-07-20).** A
27-turn Flora-vs-Arcane attrition duel — both mages low, trading heals and
chip damage — was reported as *fun*, not draggy. So **duration alone is not a
problem signal**: the thing to guard against is a duel that can't *end*
(unwinnable sustain), not one that runs long. Fatigue at turn 51 is confirmed
comfortable — it should stay a backstop that most real duels never meet, not
a pacing tool. Don't shorten it to chase a turn-count target.

**Sim results (2026-07-20, ALL NINE elements live, Photosynthesis cap 3):**
- Stall stays fixed: 0% unfinished anywhere; worst duel 59 turns.
- Effects still barely perturb normal play (greedy avg ~16 turns either way).
- ✅ **Tier 2 and Tier 3 triangles verified in the 9×9 mono-element matrix**:
  Electro>Aero 73%, Aero>Geo 67%, Geo>Electro 77%; Radiant>Umbra 71%,
  Umbra>Arcane 68%, Arcane>Radiant 65%.
- ⚠️ **The Flora tripwire FIRED at cap 3**: Flora beats its counter Pyro
  56/44 and everything else 64–95%. A/B at **cap 2** flips the counter
  (Pyro beats Flora 57/43) and softens cross-tier dominance to 64–88% —
  recommended, pending Christian's call. (Caveat: sim AIs are effect-blind —
  they can't exploit Umbra's info-hiding or play around Blind, so Umbra and
  Radiant under-perform in sims by construction; human playtests are the
  real test for Tier 3.)
- ⚠️ Aqua is the weakest Tier 1 row (its tempo effect is invisible to
  effect-blind AIs); watch in human play before buffing.

| Mechanic | Risk | Trigger for action | Candidate fixes |
|---|---|---|---|
| **Photosynthesis stall meta** | 5 stacks = 5 HP/turn on a 100 HP pool; shields + heals may out-sustain chip damage; two-Flora mirrors could be unwinnable. Ignite's stack-clear is the built-in answer but requires bringing Pyro. **Confirmed real during implementation (2026-07-20): with Flora effects live, 80% of random-AI duels blew past a 200-turn cap.** | ~~Duels regularly exceeding ~25 turns~~ Confirmed | ✅ **Implemented: Fatigue sudden death** — from turn 51, both mages take escalating unblockable end-of-turn damage (+3/turn: 3, 6, 9…), applied after the heal band; Haste holder ticks first (never a fatigue draw). Constants: `fatigueThreshold` 50 (raised from 30 per review), `fatiguePerTurn` 3. ✅ **Also implemented: stack decay** — Photosynthesis sheds a stack each turn without Flora activity (§2.3), converting the buff into an ongoing commitment. |
| **Umbra client-side trust** | Creeping Dark only hides info in the *UI*; the lockstep model reveals full state to a modded client, so cheaters see through all three darkness levels. | Ranked/Elo launch, or evidence of cheating in casual | Server-authoritative state (Cloud Function arbiter) that withholds hidden fields from the disadvantaged client — a significant architecture change from trustless P2P; scope before ranked |
| **Static Feedback frustration** | A background 20% roll can void a fully-committed spell (first-strike + proc + locked spell). Accepted for now as Electro's identity. | Playtesters reporting fizzles as "unfair" rather than "tense"; Electro over-represented in quick-attack metas | Telegraph ("charged with static" warning turn) · pseudo-random distribution · deterministic threshold trigger |

---

## 9. Open questions

✅ **None — the spec is implementation-ready.** (Progression-side questions
live in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) §5; the balance
unknowns worth monitoring are in §8.)

---

## Changelog

**Rev 9 (rulings)** — Astral Alignment **pierces Barrier** too (the Barrier
still pops). Arcane→Sanctus stays **un-gated**: the earlier lockout worry
doesn't hold, because Arcane is the big-spell element and spends most turns
*charging*, which resets nothing — denying Sanctus costs the Arcane player
their Arcane Knowledge stacks, which is exactly the right price. Sanctus's
no-debuff consolation prize adopted and renamed **Grace** (the working name
"Ward" **collides with the shipped `Ward` spell**). New element-neutral aux
spell **`Hallow`** (2 charge, priority 7, L25) grants Grace directly, so
status defence isn't locked behind one element; name checked against all 25
shipped spell ids.

**Rev 8 (effect revisions)** — Astral's effect renamed **Astral Alignment**
(final). Clarified that the pierce **splits** an attack — the non-pierced
remainder still hits the shield — with a worked example, and proved
split-first and shield-first are equivalent *provided the pierce is still
applied after* (the third table row is the trap). **Sanctus rebuilt:** the
heal is gone entirely (purge + 10/20 heal every cast was too strong);
Absolution now fires on **every 3rd consecutive Sanctus cast** and removes
**one random debuff**, making Sanctus a streak element. Arcane→Sanctus
changed from sealing the purge to **resetting the Sanctus streak**. Flagged
two consequences: an un-gated reset means Absolution can *never* fire against
an attacking Arcane player, and with healing removed Sanctus does nothing at
all against the five elements that apply no debuffs — a Ward-on-empty-purge
is proposed for the latter. Barrier-vs-pierce raised as open.

**Rev 7 (Celestial & Sanctus effects)** — All three outstanding V2 effects
designed and all five broken effect-layer edges rewired. **Holy → Sanctus**
(final). **§4b Celestial:** Solar keeps Blind; **Lunar — Phases of the Moon**,
a *global, public, deterministic* 4-turn clock (New/Waxing/Full/Waning) that
modifies Lunar spells only — the game's first pure timing element; **Astral —
Displacement**, 5 stacks × 5% shield-piercing damage routed straight to
health, ignoring the shield counter table. Renamed from "Phase Shift" to
avoid colliding with the shipped `Phase` aux spell. **§4c Ethereal repairs:**
**Sanctus — Absolution**, purge-one-debuff + heal (10 clean / 20 on a purge)
so it is never a dead cast; Sanctus→Umbra strips 5 Creeping Dark stacks;
Arcane→Sanctus seals the purge behind the cost-4+ AK threshold. Celestial
triangle closed as Solar eclipses Lunar (Blind locks the moon at New) → Lunar
anchors Astral (strips Drift) → Astral slips Solar (exempt from Blind, the
retired Arcane→Radiant mechanic rehomed). §5.2 gained a **damage-routing**
step; §5.4 gained the moon as shared HUD chrome. Voidcaller's info-war
identity moved to its own set bonuses.

**Rev 6 (V2 reconciliation)** — Added §0: a planned **four-tier, twelve-
element** expansion reconciled from an external inspiration doc. New
**Celestial** tier (Solar/Lunar/Astral) inserted as Tier 3; the old Tier 3
becomes **Ethereal** (Tier 4) with **Radiant renamed Holy**; **Solar inherits
Blind**. Rejected from the source: the Void element and its rescaled
Waterlogged. New **shield counter math** (within-tier 200%/50%, macro-tier
150%/75%). Flagged the non-obvious consequence that **five effect-layer edges
must be rewired**, not zero, plus the naming (Holy/Divine, Umbra/Shadow) and
macro-loop-direction confirmations.

**Rev 5 (this revision)** — Final rulings; zero open questions remain.
Stagger lingers until consumed by the next offensive spell (Discharge as a
harmless stagger-eater accepted as an outplay). Blind re-proc refreshes the
window, same as Ignite. "N-charge" = charge **spent**, uniformly (AK, Umbra).
Creeping Dark capped at 15 (equipment may later modify). Fizzled/missed casts
behave like charges everywhere: no streak advance/reset, no procs, no stack
gains, no penalty. Status: **implementation-ready.**

**Rev 4** — Arcane Knowledge finalized: +5%/stack (max 5 =
+25%), applies to every spell type, permanent for the duel; Empower confirmed
as an existing non-elemental spell (next turn deals double damage); payoff
example now 250%. Creeping Dark rescaled: +1 stack per charge of Umbra spells
cast, −1/turn without Umbra activity, thresholds 5/10/15 (three 5-charge
spells → Midnight); forfeit turns decay. Blind: rolls on attack incl.
fully-shielded ✅. Overload corrected (2-cost, detonates enemy charge) — no
charge-scaled fizzle special case. Triangles confirmed closed + identical for
effects and shields in every tier. Tier access now level-gated (1/15/30/45)
per PROGRESSION_DESIGN.md. Arcane confirmed streak-less; Tailwind immunity
through charge turns confirmed intended.

**Rev 3** — Tier triangles completed (shield layer explicit in
T1; effect layers tabled per tier). Arcane Knowledge defined (stacking +10%,
4+ charge Arcane casts, persists, max 5). Death-at-phase-boundary **rejected**
— replaced with survivability-first band order (heals → damage → bookkeeping)
in start/end lanes; deaths instant; Haste breaks ties in all lanes (current
holder; explicit die-first downside accepted). Blind reworked: 10%/charge
proc, 50% miss on offensive spells for 3 **turns**. Ignite finalized: 10% ×
3 ticks (incl. application turn), refresh-only, E8. Static Feedback raised to
20%; fizzle clarified (spell uncast, only the 1 charge lost); Electro stays
fast on purpose. Tailwind: consecutive, Haste-as-token, standardized pip.
Stagger reworked: −50% damage on next offensive spell (replace mechanic
deleted). Creeping Dark reworked: ±1/turn stacks, cap 7, charging counts.
Waterlogged: refresh, no stacking. Mechanics to Watch grew Umbra client-trust
and Static-frustration entries. HUD: buffs vs debuffs visually separated.

**Rev 2** — Definitions hardened (Discharge offensive-not-damaging; miss = no
effect; ticks aren't hits). Waterlogged +5 → +10. Turn phases introduced.
Ignite moved to end-of-turn, shield-first. Cleanse web added. Mechanics to
Watch section added.

**Rev 1** — Initial spec + balance review.
