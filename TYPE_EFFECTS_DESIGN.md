# Masters of Magic 2 — Type Effects (Element Side-Effects)

Design spec + balance review for the nine-element side-effect system.
Companion to [GAME_DESIGN.md](GAME_DESIGN.md) — priorities, charge rules, and
Haste referenced here are defined there.

Legend: ✅ decided · 📝 draft (needs review) · ❓ open question · ⚠️ balance/abuse concern

Status: 📝 **draft — not implemented.** This document captures the proposed
mechanics, the balance review, and the open questions that block a final spec.

---

## 1. Definitions

📝 Proposed terms used by every effect below:

1. **Spell cast** — anything EXCEPT charge. Charging only counts when an
   effect explicitly says so.
2. **Offensive spell** — any spell that negatively impacts the opponent.
3. **Damaging spell** — any spell that deals damage to the opponent.
4. **Shield spell** — anything that creates a shield (including Barrier, a
   special shield).
5. **Aux spell** — any other spell that impacts the game and fits none of the
   above.

❓ **Definition edge cases to resolve:**
- Offensive-but-non-damaging spells (e.g. Discharge wipes charge but deals no
  damage) — see Blind (§4.1): a "missed" Discharge doing "no damage" is
  meaningless. Either Blind affects **damaging** spells only, or "miss" must be
  defined per effect type (e.g. a missed Discharge wipes nothing).
- Do effect *ticks* (Ignite burn) count as hits/damage for other triggers
  (lifesteal, Static Feedback, further Ignite procs)? **Recommended: no** —
  ticks are neither casts nor hits. Keeps trigger math sane.

---

## 2. Tier 1 — The Primal Forces

Tempo and sustain. Deterministic or high-frequency effects.

### 2.1 Aqua — Waterlogged
- 📝 **Trigger:** every 3rd consecutive Aqua cast.
- 📝 **Effect:** opponent's next planned action is dragged **+5 priority**
  (slower). Includes charges.

**Analysis (priority table: instant 1 · shield 3 · channel 4 · quick 5 ·
aux 7 · regular 9):**
- Shield 3 → 8: still beats regular spells (9) but now **loses to quick
  attacks (5)** — Waterlogged is secretly a shield-hoser for quick-attack
  loadouts. Intended?
- Charge 4 → 9: the slowed channel now resolves **after Discharge/Overload
  (7)** — waterlog one turn, Discharge the next, and their charge gain lands
  after the wipe. ✅ Keep this — it's a real, learnable tempo combo, not a
  gimmick.
- Attack 9 → 14: resolves last but still resolves — mild.

⚠️ **Concerns / solutions:**
- The shield interaction is much stronger than the flavor suggests. If it's
  too strong in playtests: reduce to +3, or clamp modified priority to a band
  (e.g. can't cross the shield/attack boundary).
- ❓ Can Waterlogged stack (+10) if two triggers land before the opponent
  acts? Recommend: does not stack; refreshes.
- ❓ Priority floor/ceiling — define what 14 means relative to end-of-turn
  effects.

### 2.2 Pyro — Ignite
- 📝 **Trigger:** 25% chance on hit.
- 📝 **Effect:** burns for **20% of the attack's damage** at the start of each
  of the opponent's next two turns (40% total).

**Analysis:** expected value ≈ +10% damage per hit — modest, fine as a
baseline.

⚠️ **Concerns / solutions:**
- ❓ **Pre- or post-shield damage?** 20% of *raw* damage burning through a
  shield is a different (and more interesting) effect than 20% of what got
  through. Burn ticks at start of turn presumably bypass shields either way —
  that makes Pyro the anti-turtle tool; worth stating explicitly.
- ❓ Repeat procs: stack, refresh, or extend? Recommend: refresh with the
  larger remaining total (no stacking) to cap burst.
- 💡 Flavor hook: an Aqua cast cleanses Ignite (and/or Ignite removes
  Photosynthesis stacks). Cheap cross-element counterplay if Pyro needs a
  valve.

### 2.3 Flora — Photosynthesis
- 📝 **Trigger:** every cast.
- 📝 **Effect:** stacking buff (max 5), heals **1% max HP per stack** at end
  of round.

⚠️ **BIGGEST CONCERN IN THE SET — stall meta.**
- 5 stacks = 5 HP/turn on a 100 HP pool. A Flora player turtling behind
  shields out-heals chip damage; **two Flora players are a mathematically
  unwinnable stalemate.**
- As written, stacks appear permanent: front-load 5 casts, then switch
  elements and keep the 5%/turn forever with zero ongoing commitment.

**Possible solutions (pick at least one):**
1. Stacks decay by 1 whenever you cast a non-Flora spell (ongoing
   commitment).
2. Healing only triggers on rounds you actually cast Flora.
3. **Sudden death (recommended regardless):** after turn N, both mages take
   escalating unblockable damage. Kills every stall strategy at once, gives
   duels a hard upper bound, and backstops the disconnect/forfeit system
   (a duel can no longer run forever on timeouts).

---

## 3. Tier 2 — The Kinetic Forces

Action-queue disruption. Counter-triangle: **Electro shocks Aero, Aero
weathers Geo, Geo grounds Electro.**

### 3.1 Electro — Static Feedback
- 📝 **Trigger:** 10% chance on hit.
- 📝 **Effect:** removes one charge from the opponent (no-op at 0 charge). If
  they committed a spell needing exactly their charge and the removal lands
  first, the spell **fizzles** — charge is still lost down to the new total,
  and the turn is effectively forfeited.

⚠️ **Concerns / solutions:**
- **Order-dependence:** the fizzle only exists when the Electro hit resolves
  *before* the opponent's committed spell. Cheap fast Electro attacks get full
  lottery value; slow casts get almost none. Expect the meta to tilt toward
  zero-cost Electro spam fishing for procs — arguably on-brand for a tempo
  element, but decide deliberately.
- **Feels-bad ceiling:** losing a committed 3-charge Cataclysm to a background
  10% roll is the most rage-inducing outcome in this design. Mitigations:
  - Telegraph: a visible "charged with static" status one turn before a
    fizzle is possible.
  - Or make the proc pseudo-random / "guaranteed every 10th hit" (§6).
- ❓ X-cost spells (Overload, Barrage) read charge live and adapt — confirm
  they **cannot fizzle**, they just cast smaller.
- ❓ Does a fizzled cast still count as a "cast" for streak counters (theirs
  and yours)? Recommend: yes — the action was committed.

### 3.2 Aero — Tailwind
- 📝 **Trigger:** every cast after the 3rd consecutive.
- 📝 **Effect:** grants Haste.

**Analysis:** Haste is a tie-breaker only, so this is the weakest Tier 2
effect — guaranteed tie-break dominance while the streak lives, but
situational. Probably fine as the "safe" pick; bump later if playtests agree.

❓ How does a *granted* Haste interact with the existing seize-by-casting-first
rule — does the opponent's normal seize override it next turn, or does
Tailwind re-grant every cast (as written, it re-grants — effectively permanent
while the streak holds)?

### 3.3 Geo — Stagger
- 📝 **Trigger:** every 4th consecutive Geo cast.
- 📝 **Effect:** concussion — opponent's currently queued **attack** is
  dropped and replaced with a basic, low-priority action.

✅ **Best counterplay design in the set — protect it.** The trigger is
countable, so the opponent can deliberately queue a shield/charge on the
Stagger turn and make it whiff. Make "Stagger only replaces attacks; it
whiffs on non-attacks" the explicit rule, not an accident — the mind-game
(do they burn my 4th cast on a bait?) is the whole point.

❓ **The replacement action is undefined.** Flick? A null action? A forced
charge? This blocks the spec.

---

## 4. Tier 3 — The Ethereal Forces

Rule-bending late-game mechanics. Counter-triangle: **Radiant banishes Umbra,
Umbra corrupts Arcane, Arcane unravels Radiant** (verb candidates:
*unravels* / *nullifies* / *unweaves*).

### 4.1 Radiant — Blind
- 📝 **Trigger:** 25% chance on attack.
- 📝 **Effect:** opponent has a 50% chance to miss each of their next 3
  offensive spells. Charge is still spent; the spell just does no damage.

⚠️ **Concerns / solutions:**
- **Double-layer RNG** (25% proc × 50% per spell × 3 spells) — games will
  occasionally be decided by four coin flips. Least-variance alternative with
  the same identity: Blind = flat damage reduction for N turns.
- **Turtle incentive:** because only *offensive* casts burn Blind charges, the
  blinded player's correct play is to shield/charge for 3 turns and wait it
  out — which drags the game (compounds the §2.3 stall concern). Fix: make it
  "next 2 turns" instead of "next 3 offensive spells" so it can't be waited
  out.
- ❓ "On attack" vs "on hit" — does a fully-shielded attack still roll the
  25%?
- ❓ Re-proc while blind: refresh to 3, stack, or immune-while-blind?
- ❓ Interaction with non-damaging offensive spells — see §1.

### 4.2 Umbra — Creeping Dark
- 📝 **Trigger:** 2nd cast → **Shadow**; 4th → **Dusk**; 6th → **Midnight**.
- 📝 **Effect:**
  - **Shadow:** enemy can't see what element the caster is charging.
  - **Dusk:** enemy can't see the caster's charge or health bar.
  - **Midnight:** enemy can't see *their own* charge or health bar.

**Analysis:** pure information warfare — the strongest fit with the game's
bluffing identity. Shadow alone is strong: element info drives shield
counter-picks. The engine already stubs a `concealed` flag for exactly this.

⚠️ **Concerns / solutions:**
- **Midnight will read as a bug.** A silently vanished health bar is
  indistinguishable from a rendering glitch (see the move-timer lesson: waits
  must never look like freezes). It needs loud visual language — shadow veil
  creeping over the UI, an unmistakable "MIDNIGHT" status banner — so it reads
  as a curse, not a defect.
- **Honest-client-only:** in the trustless commit-reveal model a modded client
  can read the revealed state, so Umbra only blinds honest clients. Acceptable
  for casual; revisit if/when ranked lands.
- ❓ Total casts or consecutive? Does the darkness persist all duel? Any
  cleanse (thematically: Radiant)? Permanent Midnight from cast 6 onward is
  dramatically stronger than streak-maintained darkness.

### 4.3 Arcane — Arcane Surge
- 📝 **Trigger:** every 5th spell cast.
- 📝 **Effect:** caster gains **Empower**.

❓ **Two blockers:**
1. **Empower is undefined.** This is Arcane's entire payoff.
2. Every 5th **Arcane** cast, or every 5th cast of *any* element? "Arcane as
   meta-magic that counts all casts" would be a distinctive identity — but the
   two readings differ hugely in power.

---

## 5. Cross-cutting rules

### 5.1 Effect precedence on a single committed action ⚠️
One action can simultaneously be Staggered, fizzled, Waterlogged, and Blinded.
Lockstep clients **must** apply effects in one fixed, documented order or
state diverges. 📝 Proposed resolution order:

1. **Replace** (Geo Stagger)
2. **Fizzle check** (Electro Static Feedback)
3. **Priority modification** (Aqua Waterlogged)
4. **Miss roll** (Radiant Blind)
5. Normal resolution → end-of-turn ticks (Ignite, Photosynthesis)

### 5.2 Streak bookkeeping 📝
Five of nine elements carry counters (Aqua 3, Aero 3+, Geo 4, Umbra 2/4/6,
Arcane 5). Adopt **one uniform rule** or players will never internalize it:

- Charging neither advances nor breaks a streak.
- Casting a different element **resets** the streak.
- Fizzled/missed casts still advance streaks (the action was committed).
- ❓ Confirm whether Umbra/Arcane count *totals* instead of streaks (see
  §4.2, §4.3).

**HUD cost:** counterplay (especially Geo's) requires both players to see both
sides' counters — up to ~4 visible counters per player. Plan streak pips on
the element icons early; this is a real UI project, not a footnote.

### 5.3 Determinism & netcode ✅
- All proc rolls (25% Ignite, 10% Static, 25%/50% Blind) draw from the shared
  per-turn seed — already supported by the lockstep engine. No netcode changes
  needed.
- Umbra is display-layer only; both clients keep identical state.
- The strict event ordering in §5.1 is what keeps the seeded rolls identical
  on both clients.

### 5.4 Element counter graph ❓
Current rule: element counters only matter vs **shields** (double damage).
Open questions:
- Do the Tier 2/3 triangles use the same shield-double rule, or a new
  relationship?
- Are there **cross-tier** counters (does Pyro beat Flora?), or are the three
  triangles closed? The full 9-element graph is needed for loadout building
  and the shield-counter UI.
- ❓ How do players access higher tiers — level gates? Are Tier 3 elements
  strictly stronger (power creep) or sidegrades? Level-gated matchmaking
  softens this either way.

### 5.5 RNG texture 💡
Three elements are pure-chance (Pyro, Electro, Radiant); six are
deterministic/countable. The deterministic ones create the best play —
counting, baiting, playing around known triggers. If playtests show coin
flips deciding games in a way that grates, convert procs to pseudo-random
distribution or "guaranteed every Nth hit" — same average rate, far less
variance. Keep in the back pocket; don't pre-optimize.

### 5.6 Loadout pressure 📝
Consecutive-cast triggers push mono-element play; loadouts hold 3 elements.
Tier 1 (every-cast / chance-on-hit) mixes freely; Tier 2/3 streak elements
punish switching. That's a real strategic axis (commitment vs flexibility) —
just confirm it's deliberate, and expect mono-element to dominate until
switching gets its own payoff.

---

## 6. Open questions (blocking a final spec)

| # | Question | Section |
|---|---|---|
| 1 | What does **Empower** do? | §4.3 |
| 2 | What is Stagger's **replacement action**? | §3.3 |
| 3 | Arcane: every 5th **Arcane** cast or 5th cast overall? | §4.3 |
| 4 | Ignite: pre- or post-shield damage? Stack/refresh/extend? | §2.2 |
| 5 | Blind vs non-damaging offensive spells (missed Discharge?) | §1, §4.1 |
| 6 | Counter triangles: shield-double rule? Cross-tier counters? | §5.4 |
| 7 | Waterlogged stacking + priority floor/ceiling | §2.1 |
| 8 | Umbra: totals or streak? Persistent? Cleansable? | §4.2 |
| 9 | Radiant: "on attack" incl. fully-shielded hits? Re-proc rule? | §4.1 |
| 10 | Tailwind vs the seize-Haste rule | §3.2 |
| 11 | Photosynthesis stack decay (or sudden death instead?) | §2.3 |
| 12 | Tier access/gating (level? unlock?) | §5.4 |
