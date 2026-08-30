# SYSTEMS CONTRACT — the Phase 8 interlude (sets · enchants · sockets · potion vocabulary · quarter gate)

Status: 📝 **DRAFT for red-pen** (written 2026-08-29, against `018013e`).
Ruled sequencing: **this interlude ships before the Celestial quarter**
(2026-08-20). The design substance lives in ITEMS_DESIGN §3/§6.3/§6d and
KINETIC_CONTRACT §9; this contract distills it into rulings-needed and
build lanes, the same way KINETIC_CONTRACT did for content.

⭐ **The headline discovery, written before anything else: the §7a spell-bank
build already poured most of this interlude's foundations.** Phase 8 was
scoped when statuses were nine bespoke element effects; it lands on an
engine that now has polarity on every status, a `StatModifier` seam feeding
six derived combat stats, `TurnTimed` clocks, a `DamageOverTime` interface,
a shared removable-debuff pool, and replace-by-status-id stance law. Half
of what this contract once had to invent is now a wiring job.

---

## 1. Imported rulings (settled — build against, never re-argue)

- **Two-axis endgame** (ITEMS §3): 5 archetype armor sets × 9 element
  enchants = 45 builds from 5 art sets. Archetypes: Emberwright (burst),
  Tidebinder (tempo), Thornwarden (attrition), Aegis Sovereign (tank),
  Voidcaller (trickster/info-war).
- **Set slots** (§3.2): Hat, Robe Top, Robe Bottom, Boots, Gloves. Bonuses
  at 3/4/5 pieces. **The Belt never carries a set piece.**
- **Tiers** (§3.4): L30 / L40 / L45 / L50, each a felt jump. Tier III/IV
  need the **acquisition triangle** (§3.5): Bound rare drops + Enchanting
  skill + Crafting skill.
- **Monetization interlock** (§3.6): Bound components are what caps RP's
  reach; unbinding anything is a monetization decision.
- **Enchants are rewritable at a cost** (§6.3) — re-attunement is what
  makes two axes freeing.
- **Gems** (§6d): the word means socketed stones only (currency = RP,
  resolved). Ladder: Lesser (Crystal) / Standard (Core) / Greater (Heart),
  element-bound by their mote, cut by **Jewelry at Rimeholt**. 0–3 sockets
  as a *drop property*. The Concordant Crown is this system at 12 slots.
- **Kinetic debts** (KINETIC §9): Antidote + offensive potion (materials
  already banked: hoarlichen, firesalt); a quarter-progression gate that is
  explicitly **not collection-based**.

## 2. What the bank already built for us (the wiring inventory)

| Phase 8 need | Now exists as | Consequence |
|---|---|---|
| Set bonuses granting stats | `StatModifier` → `statusContributionTo` → `effective*` | A set bonus is a permanent gear-lane status, same seam as Murk — no new math |
| Thornwarden "your DoTs last +1 turn" | `DamageOverTime.addTicks` / `TurnTimed.extendTurns` | Apply at DoT-application time; Fester proved the seam |
| Antidote potion | polarity + `debuffsOn` pool (what Cleanse drinks from) | ⭐ The potion is a consumable Cleanse — the "missing ItemEffect vocabulary" mostly shipped in §7a |
| Enchant statuses coexisting with spell stances | §7a lanes law: different lanes sum, same lane replaces by id | An enchant's status needs its own id, NEVER a spell status's id (a gear 'lightfoot' would replace the spell's by law — correct but must be chosen, not stumbled into) |
| Dispel/strip safety for gear effects | `TurnStatus.strippable` + the Regrow precedent | Each set/gem status declares strippability explicitly |
| Aegis Sovereign shield bonuses | `effectiveShieldStrengthPercent` (Steadfast's line) | Gear % and spell % already sum on one seam |

## 3. Decisions needed before builders launch (the red-pen list)

1. **Tidebinder 4pc/5pc contradiction** (ITEMS §3.1 flag): the two tiers
   are one bonus twice and would stack past §7.1's hard cap. Candidates on
   file: 4pc → "streaks survive one fizzle/miss", or 5pc → "Tailwind's
   Haste grab also blocks the next steal". **Pick one.**
2. **Voidcaller's three bonuses** — must carry the info-war identity
   natively (post-Rev-7 ruling). Proposal to react to: 3pc +1 Creeping
   Dark stack on Umbra casts · 4pc your charge reads as "?" one threshold
   earlier · 5pc once per duel, the first Dispel/strip against you fizzles.
3. **Sets × the bank, the budget question**: set bonuses now stack with 34
   player-castable stances on the same seams (by design — lanes sum). The
   §2.1 power budget predates both. **Ruling: re-sim gate before Tier II+
   numbers are final** — accept/deny.
4. **Sockets, five open rulings** (§6d.5): removability (proposal: reuse
   the unbinding enchant — removal possible, costs an unbind, gem
   survives); slot-count distribution; rarity floor for sockets; confirm
   sockets can never be *added*; confirm the Crown uses these gems.
5. **Universal-gem anti-meta fix** (§6d.3): element-lock the strong
   bonuses vs diminishing returns per repeated gem. **Pick one** (or both).
6. **Enchant re-attunement price** (§6.3): proposal — motes of the NEW
   element at half the original enchant cost, no gold, no cooldown (RP may
   skip nothing here; there is nothing to skip).
7. **Potion vocabulary** (§9 debt): Antidote = drink-to-Cleanse (one
   chosen/auto debuff — reuses the picker); offensive potion = ?
   (candidates: a thrown Murk, a one-tick Agony splash, a charge of
   on-next-hit bonus damage). **Name the offensive potion's effect.**
8. **The quarter gate** (§9 debt, not-collection ruled): candidates —
   (a) defeat a zone-anchor duel (a named gatekeeper fight per quarter),
   (b) a skill-threshold writ (any one skill at N), (c) a crafted "toll"
   item consuming quarter materials. **Pick a direction**; detail follows.
9. **Set-status ids and names**: each bonus that grants a status needs a
   flavor name under the §7a naming law (never the mechanic). Builders
   propose; Christian approves the batch.

## 4. Build lanes (once §3 is ruled — shaped for the worktree pattern)

- **Lane A — set engine**: SetDef + worn-piece counting + bonus statuses
  through the seams; the five sets at ruled numbers; mutation-verified
  tests per bonus (the 5pc specials especially).
- **Lane B — enchant engine**: element axis on gear, re-attunement flow,
  enchant statuses with lane-correct ids; Enchanting skill hookup.
- **Lane C — sockets & gems**: socket rolls on drops (rarity-floored),
  gem ItemDefs on the mote ladder, socket/unsocket flow, gem bonuses
  through the same seams; Jewelry recipes at Rimeholt.
- **Lane D — potions + gate**: the two Kinetic potions on the ruled
  vocabulary; the quarter gate mechanism.
- **Lane E — UI**: set-bonus panel (3/4/5 pips), enchant + socket surfaces
  on item display, gem inventory affordances. Christian verifies visuals.
- **Manager gates**: budget re-sim (decision 3), both suites, plan-doc
  matrix rows, SOURCE-OF-TRUTH updates (the "what grants % shield" index).

## 5. Explicitly out of scope

Celestial quarter content (needs this interlude first, by ruling); the
full potion system rework beyond the two §9 debts; Academy mode; unlock
enforcement switch-on; dungeon structure (its own fast-follow).
