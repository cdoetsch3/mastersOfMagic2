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
                        Phase 5  progression + world map
                                   │
                        Phase 6  enemy design ──► build
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

# Phase 1 — Engine: twelve elements, four tiers

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

# Phase 2 — Engine: the new shield counter math

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

# Phase 3 — Engine: three new effects + five rewired edges

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

# Phase 3b — Engine: the six combat stats

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

# Phase 4 — ⚠️ SIM GATE (do not skip, do not proceed on a fail)

**File:** `packages/mom_engine/tool/balance_sim.dart` — extend the existing
9×9 mono-element round-robin to **12×12**.

Report and hand to Christian:

1. **Per-element overall win rate.** Investigate anything outside 40–60%.
2. **Every counter edge** (12 within-tier + 4 macro-tier). Shipped Tier 2/3
   edges previously landed at **65–77%**; new edges should sit in that band.
3. **Duel length distribution** and the share of duels ending in Fatigue.
   Long duels are *not* by themselves a problem — human playtesting confirmed
   they're fun — but a spike in Fatigue finishes means a stall meta.
4. **Aegis Sovereign exposure:** the shield-math change and Astral Alignment
   both nerf shield play from different directions. Quantify shield-heavy
   strategy win rates before *and* after.

⚠️ **Known simulator limitation:** the AI is effect-blind, so it
under-represents strategic archetypes (ITEMS §2.2). Treat the sim as a
smoke detector for the extremes, not as proof a build is fine.

**Gate:** Christian reviews and rules before Phase 5+. Expect tuning
iterations here — that is the point of the gate.

---

# Phase 5 — Progression and the world map

**Files:** `lib/game/progression.dart`, `lib/game/world.dart`,
`lib/screens/tabs/map_tab.dart`, `PROGRESSION_DESIGN.md` §4.

1. Unlock schedule: **Celestial L30**, **Ethereal L45**, `Hallow` at L25.
   Level cap stays **50**.
2. Rebuild `world.dart` from GAME_DESIGN §5's map: **12 pure zones + 9
   hybrids + 6 towns**, replacing the old 8-element region list. Note the old
   list used `Ice`, which is not an element — it is **Aqua + Aero**.
3. **Ethereal zones carry enemy levels up to 60** while the player caps at 50.
   The level shown on a zone is the **enemy** level, not a requirement.
   ⚠️ The UI must make that unmistakable, or players read "58–60" as "come
   back at 58" and never return — same legibility lesson as the move timer
   and Midnight.
4. ⚠️ **No enemy stat curve is implemented here.** Enemy HP/damage are
   per-monster (Phase 0), so the baseline statline is a **Phase 6**
   deliverable. Phase 5 only assigns each zone its enemy-level *band*.

**Done when:** a world test asserts every element has exactly one pure zone,
every hybrid names two real elements, level bands don't overlap tiers
incorrectly, and the connection graph has no unreachable nodes.
**Hand the map screen to Christian for visual review.**

---

# Phase 6 — 📝 DESIGN THEN BUILD: enemies and enemy mechanics

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
