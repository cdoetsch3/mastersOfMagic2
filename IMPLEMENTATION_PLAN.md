# Masters of Magic 2 — V2 Implementation Plan

**Audience:** an AI coding agent picking this up cold, plus the human
(Christian) who owns the design decisions and all UI verification.

**Scope:** everything designed across
[GAME_DESIGN.md](GAME_DESIGN.md) ·
[TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md) ·
[PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) ·
[ITEMS_DESIGN.md](ITEMS_DESIGN.md)
that is **not yet built** — the twelve-element V2 expansion, the items /
crafting / enchanting economy, and the content systems (enemies, loot) that
still need design before they can be built.

⚠️ **This is a large plan.** Phases 1–3b are a focused engine expansion.
Phases 6–12 are roughly "the rest of the game." Do not attempt to run them
concurrently, and do not start a phase whose gate hasn't cleared.

---

## 0. Rules of engagement — read before touching anything

These are project conventions learned the hard way. Violating them wastes
hours.

1. 🚫 **The agent does not do UI/browser verification.** Christian drives all
   UI testing himself. Write widget/unit tests for business logic, then hand
   over an explicit list of manual steps. Do not attempt to drive a browser
   to check a screen.
2. ⚠️ **Always `flutter clean` before a release build.** `flutter build web`
   has silently reused stale incremental artifacts and shipped a build with
   entire features missing. Verify a deploy with
   `curl -s <url>/main.dart.js | grep -o "X.Y.Z"`.
3. ✅ **Every new proc/roll draws from the shared per-turn seed.** The duel is
   lockstep with commit-reveal netcode; any client-local `Random()` in
   resolution code diverges the two clients instantly. This applies to
   Absolution's random purge, every new status, and every loot roll that
   happens inside a duel.
4. ✅ **Fizzled, missed, and fully-shielded casts behave like a charge** for
   every counter and trigger — they don't advance streaks, don't reset them,
   don't proc, don't grant stacks (TYPE_EFFECTS §5.4). New mechanics must
   follow this rule without being told.
5. ✅ **Deterministic ordering everywhere.** Resolution order is specified in
   TYPE_EFFECTS §5.1 (phase lanes) and §5.2 (precedence pipeline). If a new
   effect needs a spot in either, add it to the doc *and* the code in the
   same change.
6. 🚫 **Do not guess on an ❓ in a design doc.** Surface it and ask. The docs
   use ✅ decided · 📝 draft · 💡 idea bank · ❓ open · ⚠️ risk. Only ✅ and 📝
   are safe to build.
7. **Keep `pubspec.yaml` version and `lib/game/app_version.dart` in sync.**

### Where things live

| Area | Path |
|---|---|
| Pure-Dart engine (no Flutter) | `packages/mom_engine/lib/src/` |
| Engine tests (12 files) | `packages/mom_engine/test/` |
| Balance simulator | `packages/mom_engine/tool/balance_sim.dart` |
| App game logic | `lib/game/` |
| Screens | `lib/screens/`, `lib/screens/tabs/` |
| App tests | `test/` |

---

## Dependency graph

```
Phase 0  Rulings ✅ CLEARED — nothing blocks

Phase 1  12 elements ──► Phase 2  shield math ──► Phase 3  effects
                                                        │
                                              Phase 3b  combat stats
                                                        │
                                                  ⚠️ Phase 4  SIM GATE
                                                        │
                        Phase 5  progression + world map  🟡 map done, gating off
                                   │
                        Phase 5b travel + mounts + trade  🟡 travel done
                                   │
                        Phase 6  enemy design ──► build  ⚠️ 24+ designs
                                   │
                        Phase 7  item + loot catalogue (design)
                                   │
                        Phase 8  item data model + modifiers
                                   │
                   ┌───────────────┼───────────────┐
                   │               │               │
        Phase 9 economy   Phase 10 consumables   Phase 11 new statuses
                   │               │               │
                   └───────────────┼───────────────┘
                                   │
                        Phase 12  modes (adventure, PvP, Academy)
```

---

# Phase 0 — ✅ CLEARED. Every blocking ruling is made.

No design question blocks any phase. The rulings, with where each now lives:

| Ruling | Where it's specified |
|---|---|
| `Hallow` is **element-neutral** (like `Discharge`) | TYPE_EFFECTS §4c.4 |
| Absolution purges **one debuff, uniformly at random** | TYPE_EFFECTS §4c.1 |
| Enemy HP/damage are **per-monster**, not a global per-level constant | GAME_DESIGN §5 |
| Post-cap XP → motes: **10 XP = 1 Dust, 250 Dust/day** | ITEMS §6.1, PROGRESSION §4 |
| The 5 untaught counter edges are **accepted**; more zones can come later | GAME_DESIGN §5 |
| Charge retention is **high-level gear only**, and where it applies it **keeps the element cycle open** | ITEMS §5b.3 |
| Potions are **ordinary priority-3 actions**; Haste breaks ties | ITEMS §6b.3 |
| Sets are **Epic+**, on a **six-rarity** ladder (Legendary rarest); motes span Common→Epic only | ITEMS §8 |
| **Six new combat stats** — accuracy, dodge, crit chance/damage, deflection chance/amount | GAME_DESIGN §1, TYPE_EFFECTS §5.2, ITEMS §4.1a |

### Two things deliberately left TBD — neither blocks implementation

- **Tidebinder's 4-piece** (ITEMS #36) and **all three Voidcaller bonuses**
  (#37) are blank on purpose. Build the **set-bonus framework generically**
  so any bonus shape drops in later. ⚠️ Neither set can *ship* without them.

### Three constraints these rulings created — carry them forward

1. ⚠️ **Per-monster stats mean there is no automatic difficulty curve.**
   Phase 6 must define a **baseline statline per level** that archetypes
   deviate from (tank +HP/−damage, glass −HP/+damage, comparable totals), or
   "gear is worth ten levels" has nothing to be measured against and the
   L45–60 band can't be tuned or simmed.
2. ⚠️ **Every-cast procs are now an intended endgame outcome**, so §7.1's old
   blanket "never to every cast" rule is gone — replaced by a **per-effect
   allowlist** (ITEMS §7.1). Aero/Flora/Sanctus may reach every-cast;
   **Aqua's Waterlogged and Geo's Stagger must stay capped**, because firing
   those every turn makes the *opponent* passive rather than making you
   strong. ❓ That split is a recommendation awaiting Christian's ruling.
   The every-turn-proc build becomes the new balance ceiling — **sim it
   explicitly**, don't infer it.
3. ⚠️ **The six new combat stats add three seeded rolls per hit** (hit, crit,
   deflection) at fixed pipeline positions — TYPE_EFFECTS §5.2 steps 3, 4 and
   6. This is the **most likely source of a lockstep desync** in the whole V2
   effort. The hard rule: **one unified hit roll**, pure subtraction, Blind
   folded in as a flat −50 — never two miss systems.

---

# Phase 1 — ✅ DONE — Engine: twelve elements, four tiers

**Goal:** the roster change, and nothing else. No new behaviour.

**Files:** `element.dart`, plus every switch/map over `MagicElement` in
`duel.dart`, `element_status.dart`, `lib/game/element_style.dart`,
`lib/game/element_lore.dart`, `lib/game/duel_status_badges.dart`.

1. Add `MagicElement.solar`, `.lunar`, `.astral`; add `MagicTier.celestial`.
2. **Rename `radiant` → `sanctus`** throughout.
3. Extend `_counters` with the two new triangles:
   - Celestial: `solar → lunar → astral → solar`
   - Ethereal: `sanctus → umbra → arcane → sanctus` *(unchanged, renamed)*
4. Add the **macro-tier** relation (TYPE_EFFECTS §0.3): Kinetic beats Primal,
   Celestial beats Kinetic, Ethereal beats Celestial, **Primal beats
   Ethereal**; T1↔T3 and T2↔T4 are neutral.
5. Add lore/colour/icon entries for the three new elements so the UI compiles.

⚠️ **The `radiant → sanctus` rename touches persisted data.** Check
`profile_storage.dart` and `firestore_rest.dart` for stored loadouts and
element ids. The game is unreleased and presets were deleted once before, so
a wipe is acceptable — **but confirm with Christian rather than silently
dropping saves.**

**Done when:** `element_test.dart` proves all 12 elements have exactly one
counter and one counter-ed-by (volatility 1), all four triangles are closed,
the macro-tier map is a 4-cycle, and the full suite is green.

---

# Phase 2 — ✅ DONE — Engine: the new shield counter math

**Goal:** replace the boolean ×2 with the multiplier table. This is
**the largest balance change in the expansion** — isolate it in its own
commit so the sim can attribute movement to it.

**Files:** `duel.dart` (`_applyOneHit`), `shield_math_test.dart`.

Multiplier lookup (TYPE_EFFECTS §0.3) — the two layers **never stack**; same
tier uses the within-tier row, different tiers use the macro row:

| Relationship | vs that shield |
|---|---|
| Within-tier, you counter it | **200%** |
| Within-tier, it counters you | **50%** |
| Within-tier, same element | 100% |
| Macro-tier, your tier wins | **150%** |
| Macro-tier, their tier wins | **75%** |
| Macro-tier, opposite tier | 100% |

Preserve the existing overflow rule: damage that breaks a shield passes to
health at **1×**, converted back out of the multiplied space (GAME_DESIGN §3
worked example).

**Done when:** `shield_math_test.dart` covers all six rows plus overflow
across a tier boundary, and the previously-passing shield tests are updated
with an explicit note that their expectations changed *by design*.

---

# Phase 3 — ✅ DONE — Engine: three new effects + five rewired edges

**Reference:** TYPE_EFFECTS §4b (Celestial) and §4c (Ethereal repairs). Build
in this order; each is independently testable.

### 3a. Move Blind from Sanctus to Solar
Mechanically identical (10%/charge spent, 50% miss for 3 turns, refresh on
re-proc). Only the owning element changes, plus its two edges:
immunity moves Arcane → **Astral**; the Creeping-Dark clear moves to
**Absolution** (3d).

### 3b. Lunar — Phases of the Moon
- A **global clock**: `phase = turnNumber mod 4`, New Moon on turn 1.
  Derived, not stored — **no RNG, no state sync, no netcode changes.**
- Modifies **Lunar spells only**: New −25% + veiled cast · Waxing +25% ·
  Full +50% · Waning shields & heals +50%.
- **Solar → Lunar (eclipse):** a Blind proc **locks that mage's moon at New
  Moon** for the 3-turn window. Per-mage, not global.
- **Lunar → Astral:** a Lunar attack strips 1 Alignment stack; on Full Moon,
  all of them.

### 3c. Astral — Astral Alignment
- +1 stack per turn you cast Astral (any cost), max 5; −1 per turn you don't.
- **5% per stack of the attack's damage bypasses the shield to health; the
  remainder still hits the shield.** Implement **split-first** (Order A) —
  TYPE_EFFECTS §4b.4 proves it equals shield-first *only if* the pierce is
  applied afterwards, and the naive "did the shield absorb it all" reading
  silently deletes the mechanic against big shields.
- Pierced damage **ignores the §0.3 counter multipliers** — it lands on
  health at 100%.
- **Pierces Barrier too**; the Barrier still pops.
- The aux spell `Phase` short-circuits it (100% routing) — must not
  double-route.
- New step in the §5.2 precedence pipeline, after damage modifiers, before
  shield application.

### 3d. Sanctus — Absolution + Grace, and the `Hallow` spell
- **Streak element:** every **3rd consecutive** Sanctus cast fires Absolution;
  casting another element resets to 0; charging does neither.
- Absolution removes **one debuff, chosen uniformly at random** — **no
  healing**. Resolves in the **E1–E3 heal band**, before Ignite's E8.
  ⚠️ The roll **must** draw from the shared per-turn seed, or the clients
  disagree about which debuff vanished and lockstep diverges.
- If nothing to purge, bank **Grace**: blocks the next debuff outright.
  **Max 1, persists until consumed**, does not block Fatigue.
- **Sanctus → Umbra:** each Absolution strips **5 Creeping Dark stacks**
  (one threshold band), whether or not anything was purged.
- **Arcane → Sanctus:** an Arcane attack **resets the Sanctus streak to 0**.
  Un-gated is correct — charging isn't a cast, so a big-spell Arcane player
  rarely resets it; denying Sanctus means cheap attacks and no AK stacks.
- New spell **`Hallow`**: 2 charge, priority 7 (aux), **element-neutral**
  (like `Discharge`), grants Grace, unlocks at L25. Shares the max-1 Grace
  cap with Absolution.

**Done when:** a new `tier34_effects_test.dart` covers each effect, each of
the five edges, the eclipse lock, the Alignment split (including the
40-point-shield case and Barrier), Grace consumption and its cap, and
Absolution's streak reset by an Arcane attack. `precedence_test.dart` gains
the routing step.

---

# Phase 3b — ✅ DONE — Engine: the six combat stats

Implemented; sim byte-identical to Phase 3 (defaults inert). The hit roll is
per-cast (preserves Blind exactly), crit and deflection per-hit; every roll is
chance-guarded so default duels draw no RNG. Blind is now a flat −50 accuracy
term, not a separate miss system. `combat_stats_test.dart` covers it.

**Reference:** GAME_DESIGN §1 "Combat stats" · TYPE_EFFECTS §5.2 steps 3/4/6 ·
ITEMS §4.1a.

Do this **after** 3a–3d and **before** the sim gate, so the gate covers
everything. All six default to no-ops (accuracy 100%, everything else 0), so
⭐ **a correct implementation must not move the sim at all** — that is the
cleanest possible regression test for this phase.

1. **Per-mage stats** on `MageState`: dodge, critChance, critDamage
   (default +50%), deflectionChance, deflectionAmount. **Per-spell**
   accuracy on `Spell`, defaulting to 100% for all 25 shipped spells —
   🚫 **do not retrofit any existing spell below 100%.**
2. **Unify the hit roll** (§5.2 step 3):
   `spellAccuracy + gearAccuracy − targetDodge − blindPenalty`. Pure
   subtraction, **no clamp** — accuracy above 100% is meaningful against
   dodge. Blind becomes a flat **−50**. Astral's exemption drops the blind
   term.
3. **Crit roll** (step 4) → multiplier in step 5, alongside Empower/Stagger.
   **Per hit**, so Flurry rolls three times.
4. **Deflection roll** (step 6), **per hit**. Pure **damage reduction** —
   the defender takes `damage × (1 − deflectionAmount)` and the deflected
   portion is removed, not redirected. **Cap at 50% for players.** Resolves
   **before** Astral's pierce split.
   💡 The optional *reflection* rider (deflected portion dealt back to the
   attacker) is a separate late-game perk — if built, let the chain recurse:
   it decays geometrically. **Round down, integer arithmetic**, so both
   clients terminate on the identical step.

**Done when:** a new `combat_stats_test.dart` covers accuracy above 100%
against dodge (120 − 30 = 90), Blind-as-flat-−50 matching the old Blind
behaviour exactly, per-hit crit and deflection on a multi-hit spell, and the
50% deflection cap. ⭐ **And the balance sim produces statistically
indistinguishable results from the Phase 3 run** — if it moves, a default
isn't neutral.

---

# Phase 4 — 🟡 RUN, AWAITING RULING — ⚠️ SIM GATE

**File:** `packages/mom_engine/tool/balance_sim.dart`. Run: `dart run
tool/balance_sim.dart 600`.

✅ **The sim was rebuilt before this run, because the old one could not be
trusted.** Three changes, each of which moved the numbers:

1. ❌ **`GreedyAi` deleted.** Every brain is now a rung of the intelligence
   ladder (`LadderAi`). The old opponent was *effect-blind*, so it could not
   play Lunar timing, Astral stacking or Sanctus streaks at all.
2. ✅ **Realistic loadouts.** Every mage draws ~10 spells instead of holding all
   25. A full book means Cataclysm is always available, which rewards a
   charge-to-five pattern no real loadout can always run.
3. ✅ **The matrix runs at intelligence 4, 7 and 10**, because a matchup table is
   only true for the skill it was measured at.

### ⭐ Finding 1 — counter-edge decisiveness scales with intelligence

| Counter edge | i4 | i7 | i10 |
|---|---|---|---|
| pyro ▸ flora | 45% | 63% | 72% |
| flora ▸ aqua | 95% | 94% | 96% |
| aqua ▸ pyro | 65% | 73% | 78% |
| electro ▸ aero | 73% | 81% | 91% |
| aero ▸ geo | 61% | 73% | 78% |
| geo ▸ electro | 73% | 79% | 87% |
| solar ▸ lunar | 60% | 79% | 88% |
| lunar ▸ astral | 71% | 76% | 85% |
| astral ▸ solar | 69% | 78% | 89% |
| sanctus ▸ umbra | 71% | 75% | 84% |
| umbra ▸ arcane | 69% | 78% | 85% |
| arcane ▸ sanctus | 75% | 73% | 86% |

⚠️ **"Counter edges should sit at 65–77%" is not a well-formed target.** At
**i4** almost every edge lands in that band. At **i10** eleven of twelve are
above it. A smarter opponent exploits its type advantage harder, so the band
only means something once a skill level is attached to it.

❓ **Ruling needed: what intelligence is the balance target measured at?**
Recommendation: **i7** — competent, status-aware, and roughly what a real
opponent should feel like. At i7 the edges run 63–94%, so the band itself
probably wants widening to ~70–85% rather than the numbers being nerfed.

📝 **These are mono-element duels — the worst case.** Each side is locked to one
element for the whole duel and can never switch. A real mage brings five, so a
95% mono-element edge does *not* mean a 95% real matchup. The matrix isolates
the element variable; it does not predict play.

### ✅ Finding 2 — RESOLVED. Flora rebalanced; the whole roster is now in band

**Photosynthesis was rewritten as a streak gate** (TYPE_EFFECTS §2.3): from the
5th consecutive Flora cast, heal 1% max HP per turn. The first four casts do
nothing. Mirrors Aero's Tailwind.

| Flora overall | i4 | i7 | i10 |
|---|---|---|---|
| stacking (old) | 82.9% | 75.6% | 70.1% |
| ✅ streak-gated | **54.2%** | **51.1%** | **51.4%** |

✅ **All twelve elements are now inside 40–60% at every intelligence level**
(600 duels/pair). ⭐ **The fix was surgical** — of the twelve counter edges only
the two Flora edges moved; the other ten came back byte-identical at all three
levels. And `pyro ▸ flora` went **45% → 70%** at i4, so Pyro beats its own prey
at ordinary skill again.

⚠️ **Method note:** a first pass at 150 duels/pair put Geo at 62% and looked
like a new failure. At 600/pair it is 59.7%. Do not call a 2-point overshoot at
that sample size.

<details><summary>The original finding, for the record</summary>

### ⭐ Finding 2 (original) — eleven of twelve elements are fine; Flora alone is broken

Overall win rate, target 40–60%:

| | i4 | i7 | i10 |
|---|---|---|---|
| **flora** | **82.9%** | **75.6%** | **70.1%** |
| everything else | 44–59% | 44–54% | 43–53% |

⚠️ **Flora is over-tuned, and this is not an artifact of a weak AI** — it stays
outside the band at every intelligence, including 10. Better play *reduces* the
problem (82.9 → 70.1) without solving it.

⭐ **The clinching evidence: Pyro, which counters Flora, LOSES to it at i4
(45%).** An element whose own counter cannot beat it is over-tuned by
definition.

📝 **The likely cause is Photosynthesis**: every Flora cast adds a stack, with
no condition attached — no hit required, no target state, nothing to play
around. It is the only element effect that accrues for free, and it also blocks
Waterlogged.

❓ **Ruling needed on the Flora nerf.** Options, cheapest first: require the cast
to *hit* rather than merely be cast; cap stacks at 2; slow the decay; or reduce
the heal per stack.

### ✅ Finding 3 — Geo's old failure was an artifact

The previous baseline flagged Geo at 63.1%. Rebuilt, it measures **58.5 / 53.9 /
53.0**. The old number came from the full spellbook and the blind brain, not
from Geo.

</details>

**Gate:** ❓ **One question left — what intelligence is the balance target
measured at?** The Flora question is closed. Everything in the roster is in band
at every level, so the only open item is whether the 65–77% counter-edge band
should be restated against a stated skill (recommendation: i7, band widened to
~70–85%).

---

# Phase 5 — 🟡 PARTLY DONE — Progression and the world map

✅ **The map half is built** (2026-07-26). `world.dart` was rebuilt from
[WORLD_DESIGN.md](WORLD_DESIGN.md) and Plate I-b, and all three inconsistencies
this phase was opened to fix are resolved:

| Was | Now |
|---|---|
| `world.dart` held the old 18-region map | ✅ 32 places: 12 pure, 10 hybrid, 9 towns, the Citadel |
| A region was still named "Radiant Sanctum" | ✅ Gone with the rest of the old list |
| Solar, Lunar, Astral, Arcane appeared in **no** region | ✅ Every element has exactly one pure zone, guarded by test |

Also delivered beyond the original scope, because the design moved:
`WorldPlane` (world vs Empyrean), per-place elevation, tier, crafting station,
gate object, `opensAtLevel`, Zenith's teleport net, and the gazetteer's blurb +
arrival text — so `world.dart` is the single source of player-facing location
copy. `test/world_test.dart` covers this phase's whole "done when" list plus
graph symmetry, the two-door Veil crossing and the tree line.

⬜ **What is still open in this phase:**

1. ⬜ **Unlock gating is still off.** `Progression.isSpellUnlockedAt` and
   `isElementUnlockedAt` both `=> true`, and `enforceSlotLimits` is `false`.
   The schedules and the 5→15 slot curve are all *data* already; only the
   switches are unflipped. ⚠️ Deliberate — playtesting wants everything
   available — so **turning these on is a decision, not an oversight.**
2. ✅ **`map_tab.dart` now shows the model.** Travel cards and the current
   location card carry monster elements, the crafting station, Beyond the Veil
   and whether a place is gated. The "Lv X–Y" label that read as a requirement
   is gone: `GameLocation.enemyBandLabel` is the one owner of that string and
   every surface reads it, so the sheet and the cards cannot contradict each
   other about the most consequential number on screen (GAME_DESIGN §5).
3. 🟡 **Travel is still an instant graph hop in the UI**, but the model
   underneath it is built — see Phase 5b, steps 1–2. What remains here is
   wiring the clock into the game: a departure time on the profile, arrival
   while the app is closed, and the Map tab showing a trip in progress.

✅ **Map screen reviewed by Christian** (2026-07-28) across three rounds: the
map is interactive in both the tab card and full screen, opens filling the
window, and the Cinderlands were moved south-east to fill the empty quarter.

---

# Phase 5b — 🟡 PARTLY DONE — Travel, mounts and trade

📝 **Did not exist when this plan was written**; designed in WORLD_DESIGN §4b
after the geography pass. Sits here because it depends on the world graph
(Phase 5) and is depended on by the economy (Phase 9).

**Files:** `lib/game/world.dart`, `lib/game/travel.dart` (new),
`lib/game/player_profile.dart`, `lib/screens/tabs/map_tab.dart`.

1. ✅ **`TravelEdge`** — done. `connections` is now a *derived* getter over
   `edges`, so adjacency and duration cannot disagree. Each edge carries its
   own tunable `minutes` plus a `kind` (`road` / `sea` / `veil`), which finally
   distinguishes the Galehaven–Tidewrack crossing from an ordinary road
   (WORLD_DESIGN §2.5).
2. ✅ **Pathfinding** — done. `lib/game/travel.dart` solves the whole network
   once into a `{minutes, nextHop}` table (Floyd–Warshall over 32 nodes) and
   reads back in constant time. `TravelRoute` carries the stops, the legs, the
   summed minutes, `townStops` and `needsPassage`. **Derived from the edges,
   never authored** — a hand-written matrix would be ~500 numbers to revisit
   every time one of the 47 roads changed.
3. ⛔ **Travel vs Journey — BLOCKED ON PHASE 6.** Travel (the safe, fixed-price,
   point-to-point half) is what steps 1–2 built, and it is enough to move
   around the world on a clock. **Journey cannot be built yet**: it *is* the
   road's encounter table, and there are no enemies, no encounter tables and no
   spawn rules until Phase 6. Building it now would mean inventing the content
   it is made of.

   When Phase 6 lands, Journey needs: leg-by-leg movement stopping at each town
   to heal, encounter rolls per leg, a variable duration that rewards clearing
   quickly, and cargo at risk on defeat. ⚠️ **Cargo is at risk on a Journey and
   nothing is exempt** — that severity is the design, not an oversight.

   ❓ Still open, and answerable only once encounters exist: what "at risk"
   means (a fraction of cargo on defeat, or all of it), and whether Journey is
   offered on every edge or only ones with a designed encounter table.

   ⚠️ **Nothing in the shipped code implies Journey exists.** `TravelRoute`
   exposes `townStops` — the healing stages a Journey will use — and that is
   the only foothold; there is no half-built mode to find and no dead switch.
4. **Mounts** — speed multiplier + cargo slots, no terrain rules. Five price
   tiers; tier 5 is the Ethereal three-pack earned via the Citadel tack chain.
5. **Shops** — per-player stock, capped daily, restocking overnight. Static
   prices, in every town past Pennycross.
6. **The Concord Market** — one order book, two access points. ⚠️ Build it as
   *one table with two entry points*, never two markets; splitting liquidity is
   the failure mode called out in GAME_DESIGN §3b.

⚠️ **Supersedes idea bank #9** (10–15s legs scaling to hours). The scale is
minutes: ~5 min per leg.

📝 **Two tuning facts the built graph produced**, both worth a decision before
the travel UI ships:

- **Aldermere → Rimeholt costs 39 minutes, not the ~30** in WORLD_DESIGN
  §4b.1's worked example. The 5-minute baseline is honoured exactly — the real
  chain is **8 legs**, not the ~6 the example assumed. Either correct the
  example to 39 or shorten some legs; `test/travel_test.dart` pins 39 so the
  change shows up as a changed journey rather than a silent number.
- **The Pennycross → Concordance ferry does not exist in the graph.** §4b.1
  proposes it to fix "the worst early leg" — and that leg measures **28
  minutes**, so the instinct was right. Adding it is a new edge plus an unlock
  condition, i.e. design work rather than refactoring.

---

# Interlude — ✅ DONE — playtest response (not originally planned)

Christian playtested after Phase 3b and filed 26 notes; these were built in
response and are not part of the numbered plan:

- **Barrier as stacking points** (max 3, one spent per hit), and shields +
  barriers moved to a `CustomPainter`: stroke scales with the shield REMAINING,
  barriers are beaded rings, and shields above 100 split into stacked rings
- **Per-status animations** (twelve motions over 22 statuses), backed by a
  **status catalogue** in the engine that the HUD, log, animations and a new
  in-game player guide all read from — with tests that fail the build if a
  status ships undocumented or unanimated
- **Status pips advance with the animation** rather than all appearing when the
  turn resolves (the engine records a status frame per event)
- **Hand-drawn Sanctus halo and Umbra demon glyphs**
- **Password reset, password change, friend presence** (the green dot)
- **A tooltip audit** plus a consistency test that checks player-facing text
  against the data rather than against memory
- Balance: lifesteal → 50%, Discharge → 2 charge, Hallow → 1 charge, Volley →
  7–10, **Barrage → one hit per charge**, loadout caps → 5 elements / 10 spells
- Bug fixes: charge-drain display, battle-log grammar, the lagging streak pip,
  and cast FX scaling off the spell rather than the charge held

---

# Phase 6 — 📝 DESIGN THEN BUILD: enemies and enemy mechanics

⚠️ **Scope grew with the geography pass.** WORLD_DESIGN settled 22 zones plus
the Empyrean's three, each wanting a **pool of 3–5 mini-bosses and 1–2 bosses**
(GAME_DESIGN §3d) — roughly **24+ designs beyond what the bestiary lists
today**, and the single largest content task in this plan. Budget for it
honestly rather than discovering it mid-phase.

📝 Also now in scope: the **Thin Air** status for the Celestial shelf and the
**no-moon** rule above the Veil (WORLD_DESIGN §4.1–4.2) — both are enemy/zone
environment rules rather than item mechanics.

🚫 **Strictly after Phase 5.** The zones defined there are what enemies
populate — the roster is sized per zone, spawn tables key off zone ids, and
the stat curve reads the enemy-level bands the map assigns. Designing enemies
against a map still in flux means doing it twice.

⚠️ **This is a design session first.** GAME_DESIGN §5 currently has
**names only** — 12 elements × (3 mini-bosses + 1 final boss) plus "5–7
monster types per zone" that don't exist yet. None of it has stats,
behaviour, or mechanics.

**Design deliverable — a new `ENEMIES_DESIGN.md` covering:**

1. **The common monster roster** — ~5–7 types per zone × 21 zones. Almost
   certainly needs *archetypes* (bruiser / caster / turtle / swarm) reskinned
   per element rather than 100+ bespoke designs. Decide that first.
2. ⭐ **The baseline statline per level** — HP, damage, charge behaviour,
   shield usage — that archetypes deviate from (tank +HP/−damage, glass
   −HP/+damage, comparable totals). Enemy stats are per-monster by ruling,
   so **this baseline is the only thing making the curve tunable**; without
   it, "gear is worth ten levels" can't be measured and L45–60 can't be
   simmed.
3. **Enemy AI personas.** `lib/game/ai_personas.dart` and the engine's
   `ai.dart` already exist — extend rather than replace. ⚠️ The current AI is
   **effect-blind** (it doesn't understand statuses), which is both a
   difficulty ceiling and the sim's main limitation. Deciding whether to fix
   that here is a real fork in the road.
4. **Boss mechanics** — what makes a boss different from a big monster.
   Multi-phase? Unique statuses? Immunities?
   💡 Already banked: **Luna Plena fightable only on a Full Moon turn**
   (GAME_DESIGN §5) — the moon is public state, so it costs nothing.
5. **Mini-boss vs boss vs common** drop and difficulty distinctions, feeding
   Phase 7.

**Then build:** enemy definitions, spawn tables per zone, the encounter
model, and the adventure-loop hooks.

---

# Phase 7 — 📝 DESIGN THEN BUILD: the item and loot catalogue

⚠️ **Also a design session first.** No longer blocked — every architectural
ruling is made (Phase 0). ITEMS #36 (Tidebinder 4pc) and #37 (Voidcaller
bonuses) stay TBD, which is content to fill in, not architecture to settle.

**Design deliverables:**

1. **Item names** across 9 slots × 5 rarities × the level bands (ITEMS §9).
   The five armour slots (Hat, Robe Top, Robe Bottom, Boots, Gloves) carry
   sets; Neck, Ring, Main hand, Off hand are free.
2. **Set piece names** for all five archetypes × four tiers (L30/40/45/50) —
   Emberwright, Tidebinder, Thornwarden, Aegis Sovereign, Voidcaller.
3. **Rarity naming** is settled (Common/Uncommon/Rare/Epic/Legendary mapped
   1:1 to Dust/Shard/Crystal/Core/Heart) — but the **mote names per element**
   (12 now, not 9) are not.
4. **Loot tables** per monster / mini-boss / boss / zone: drop rates by
   rarity, mote drop rates by tier, and the **rare components** that only
   drop from difficult enemies (ITEMS §3.5's acquisition triangle).
5. **Recipe catalogue** with per-recipe conversion cooldowns (ITEMS watch
   item #27).

⚠️ **Two economy invariants to preserve while writing tables:** every mote
tier **below Heart drops directly** at escalating rarity — the 50/20/12/4
refinement ladder is an exchange between tiers of abundance, *not* a
48,000-dust grind — and **Hearts are craft-only** (ITEMS §6.0, §6.1).

---

# Phase 8 — Items: data model and the modifier vocabulary

📝 **Now also carries gem sockets** (ITEMS §6d): 0–3 slots rolled per drop, gems
cut from a stone + Crystal/Core/Heart, universal and per-element families. ⚠️ A
**third multiplicative power axis** on top of set bonuses and enchants — §2.1's
budget was not written to hold it, so re-sim before committing. The Concordant
Crown is the same system at twelve slots.

**Goal:** the engine can accept a bundle of equipment modifiers; the app can
represent, store, and equip items.

1. `Item`, `ItemSlot`, `Rarity`, `Equipment` (9 slots) in `lib/game/`.
2. A `LoadoutModifiers` bundle the engine consumes — the engine must stay
   **pure Dart with no Flutter dependency**, so items enter as plain data.
3. Implement the modifier vocabulary from ITEMS §4.1 (safe/linear) first;
   §4.2 (powerful, needs caps) second, **with the §7.1 caps enforced in code,
   not by convention**: streak thresholds drop by at most 1 and **never to
   every cast**.
4. Set-bonus evaluation at 3/4/5 pieces, supporting 5, 4+1, and 3+2 splits.
5. Replace the stub `inventory_tab.dart` (currently 105 lines).

**Done when:** modifier maths is unit-tested at the caps and one past them,
set-bonus counting is tested for all three splits, and a duel runs
identically with an empty modifier bundle (proving zero regression).

---

# Phase 9 — Economy: motes, skills, crafting, enchanting

Per ITEMS §6, §6a, §6b, §6c. Largely independent of Phases 10–11.

1. **Mote ladder:** Dust →50→ Shard →20→ Crystal →12→ Core →4→ Heart.
2. **Neutral → element conversion**, scaling 4:1 → 1:1 with Enchanting level,
   throttled by cooldown.
3. **Skills** outside player level: Gathering (Mining, Felling, Foraging) and
   Processing (Tailoring, Potions, Enchanting, Jewelry, Metalworking,
   Woodcarving). Verify every slot has a maker (ITEMS §6a.1).
4. **Crafting and enchanting** flows — the three verbs are already stubbed in
   the UI.
5. **Tradability tiers:** Tradeable / Untradeable-with-release / Bound, with
   Tier III–IV rare components **Bound** (this closes the buy-the-drops
   loophole — don't relax it for convenience).
6. **Backpack: 20 items**, with craftable expansion pouches (Tailoring).

⚠️ **Monetization invariant:** gems buy *shortcuts*, never *requirements*.
Buying better odds is acceptable; buying components is not (ITEMS §3.6).

---

# Phase 10 — Consumables, potions, alchemy

Per ITEMS §6b.

- Potions resolve at **P3**, are slowed by Waterlogged, and are **never
  fizzled or missed**.
- **Combat potions cost your turn** — this is the ruling that keeps them from
  being free value.
- Equipped consumable slots (baseline 2–4, expandable) drawn from the
  backpack.
- 🚫 **No consumables in Academy mode.**
- ⚠️ **Loot insurance is the highest-risk potion** — it defuses the
  adventure loop's core push-your-luck gamble. Build it last, behind a flag.

---

# Phase 11 — New statuses and the largest engine additions

Per ITEMS §5b. Each is independent; ordered by ascending risk.

1. **Endurance** (death save) — spell refreshes it, items break or recharge,
   saves against Fatigue harmlessly.
2. **The lockout family** (Silence / Bind / Sunder / Seal) — "can't do X for
   N turns," stacking allowed.
   🚫 **Prerequisite:** the **compelled-forfeit wire protocol**. A player
   locked out of every action must not march toward the 3-strike
   auto-surrender. Today the protocol has one forfeit token (`'F'`) and it's
   the *opponent's* client that counts forfeits, so compelled-vs-timeout must
   be distinguishable on the wire **and verifiable** — a cheater could
   otherwise claim "compelled" to dodge auto-surrender. Also fix
   `TunableAi`, which returns `ForfeitAction` when nothing is playable.
   (GAME_DESIGN §1, ITEMS §5b.1.)
3. **Charge retention** ⚠️ — the highest-impact proposal in the doc, because
   it edits the core "casting spends all charge" tension. ✅ Ruled: retention
   **keeps the element cycle open**, so streaks compound across casts.
   🚫 **Enforce §7.1's floor in code** — retention plus Tidebinder's −1 is
   the exact vector that pushes a streak proc to every cast. Re-sim after.
4. **Sustained spells + interrupts** ⚠️ — explicitly *"the largest engine
   addition"*: multi-turn actions **do not exist today**, so this changes the
   action model itself. Three variants (beam / channelled / prepared), with
   interrupts from a `Disrupt` aux spell, a damage-plus-interrupt spell, and
   **Stagger** gaining the interrupt property (making Geo the anti-sustained
   element). 💡 **Strong candidate to defer** past a first V2 release.

---

# Phase 12 — Modes

1. **Adventure loop** — the push-your-luck run structure (GAME_DESIGN §5),
   now that enemies (Phase 6) and loot (Phase 7) exist.
2. **Ranked PvP counting gear**, plus **Academy mode** with gear stripped and
   its own skills-only Elo. ⚠️ Gear power should feed **matchmaking**, not
   only Elo (ITEMS §7.4).
3. Re-run the sim against geared-vs-geared to check the §2.1 power budget:
   full best-in-slot vs naked ≈ **100%** win, vs average ≈ **80–90%**.
   ⭐ The L45–60 enemy band pins a second number to this: **gear must be worth
   about ten levels.** The two constraints should agree.

---

## Deferred / banked — do not build without an explicit ask

- **📝 Achievements + character progress — designed, not built.** See
  `ACHIEVEMENTS_DESIGN.md` (2026-07-28). ~140 achievements: three per zone
  (clear / purge every enemy / collect every drop), 5-tier charge-based
  mastery per element, wealth, duelling and world. Rewards are XP, gold, RP,
  and selectable prefix/suffix titles — never power. Points are public;
  individual achievements are private. Later mirror to Play Games / Game
  Center.
  ⛔ **Blocked on a character-progress subcollection that does not exist**:
  zone *clearing* is not recorded anywhere (`hasAdventure` says a zone has an
  encounter, not that you beat it), per-element **charge counts** are not
  tracked, and neither is lifetime gold earned. All are worth adding
  regardless of achievements.
  ⚠️ Also surfaces an unmade architectural decision — **character vs
  account**. `PlayerProfile` is currently both. Progress and achievements are
  ruled **character-level**, and the alternate modes in GAME_DESIGN §5
  (permadeath, no-trading) depend on the split. Cheapest to do before more
  things write to the profile document.

- **⛔ Third-party sign-in (Google / Apple / Facebook SSO).** Requested
  2026-07-28. Big, and deliberately later: each provider is its own OAuth
  setup, platform config (Apple needs an entitlement and its own "Sign in with
  Apple" button rules), and a Firebase Auth provider wiring, plus an
  account-linking story for guests who already have a local profile. The
  social tab now has separate **Create account** / **Sign in** buttons; SSO
  slots in beside them when built.
- **⛔ Loadout unlock schedule (level-gated elements & spells).** The pools are
  separate and capped (5 elements, 10 spells), and `Progression` now carries
  the intended schedule as data — elements at 10/20/30/40 (1→5), spells at
  8/16/24/32/40/48 (4→10) — but `enforceSlotLimits` is **false**. Turning it
  on is one of the LAST things before v1, alongside spell gating, because it
  cannot ship until the campaign can hand a taken-away spell back. The
  schedule itself is provisional and expected to be retuned against
  playtesting (the numbers were picked, not measured).
- **⛔ App-shell caching / no full re-download on relaunch — ✅ DONE 2026-07-28.**
  Kept here as the record: `firebase.json` was sending `no-cache` on every
  asset, so a cold start re-fetched all 41 MB — 37 MB of which is canvaskit,
  which had no cache header at all. Now canvaskit is `immutable` for a year
  (it is SDK-versioned, not ours), assets/icons cache for a day, and only the
  entry points (`index.html`, bootstrap, service worker, `main.dart.*`) stay
  `no-cache`. If a stale build is ever served after a deploy, the suspect is
  one of those entry points silently gaining a long cache lifetime.

- **TYPE_EFFECTS §7a** — 16 banked spell ideas.
- **Phase 7 of the original type-effects build** — making the AI aware of
  statuses. Overlaps Phase 6 item 3 above; decide there.
- **Shield duration types** (permanent vs decaying) and **2nd/3rd shield
  slots** (GAME_DESIGN §3).
- **Server-authoritative rework** for Umbra's information hiding. Today it is
  **honest-client-only** — a modded client can read the revealed lockstep
  state. Accepted for casual play; a blocker for competitive ranked
  (TYPE_EFFECTS §8).

---

## Suggested first session for the agent

1. Read this file, then TYPE_EFFECTS §0, §4b, §4c.
2. Do **Phase 1** end to end, including the persisted-data question, and stop
   for review. It is self-contained, fully testable, touches no balance, and
   proves the toolchain and test suite are healthy before anything risky.

**Nothing is blocked.** Every design ruling is made (Phase 0), so the agent
can run from Phase 1 through the sim gate and onward without waiting on
anybody. The next human checkpoints are judgement calls, not blockers: the
Phase 4 sim review, and Christian's UI verification at each visible change.
