# Masters of Magic 2 — Type Effects (Element Side-Effects)

Design spec + balance review for the nine-element side-effect system.
Companion to [GAME_DESIGN.md](GAME_DESIGN.md) — priorities, charge rules, and
Haste referenced here are defined there.

Legend: ✅ decided · 📝 draft (needs review) · 💡 idea bank · ❓ open question · ⚠️ balance/abuse concern

Status: ✅ **spec finalized — implementation-ready, not yet implemented.**
All rulings are in; §8 lists the balance risks to monitor during playtests.

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
- ✅ **The debuff lingers until consumed** by the next offensive spell — it
  never expires on its own. Consuming it with a non-damaging offensive spell
  (Discharge) is a legal, harmless "stagger-eater" — accepted as another
  outplay, at the price of a 3-cost spell and a turn.
- ✅ Derived from §5.4: a **missed** spell doesn't consume Stagger (a miss
  behaves like a charge — nothing triggers, nothing is lost).

---

## 4. Tier 3 — The Ethereal Forces

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
  Casting consumes ALL charge, so a cheap Arcane spell cast while holding 4
  charge qualifies. Same rule for Umbra's per-charge stacks (§4.2):
  **spent**, consistently.

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
   Knowledge +5%/stack), then multipliers (Empower ×2, Stagger ×0.5).
   Example: 5-stack AK + Empower + Staggered = 100% + 25% → ×2 → ×0.5 = 125%.
5. Normal resolution → end phase (§5.1).

*(Geo's old replace-the-action mechanic is gone, so there is no "replace"
step.)*

### 5.3 Cleanse & immunity web ✅
Consolidated in the per-tier tables (§2, §3, §4). Pattern: every tier's
effect-layer triangle IS its cleanse/immunity web. Surface these in tooltips.

### 5.4 Streaks, stacks & HUD 📝

**Consecutive-cast streaks** (reset when you cast any other element): Aqua
(every 3rd), Aero (after 3rd), Geo (every 4th). ✅ Arcane has **no streak**
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
Creeping Dark (0–15, ±per §4.2), Arcane Knowledge (0–5, permanent).

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
- ✅ Tiers are level-gated: **Tier 1 at L1, Tier 2 at L15, Tier 3 at L30,
  Tier 4 (future) at L45** — see
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
