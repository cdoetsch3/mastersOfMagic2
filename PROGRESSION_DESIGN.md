# Masters of Magic 2 — Progression, Slots & XP

Leveling curve, loadout slots, and the unlock schedule. Companion to
[GAME_DESIGN.md](GAME_DESIGN.md) (§4 Progression & Meta) and
[TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md) (element tiers).

Legend: ✅ decided · 📝 draft (needs review) · 💡 idea bank · ❓ open question

Status: 📝 **draft — not implemented.**

---

## 1. Loadout slots ✅

- ✅ Players have a single pool of **slots shared between elements and
  spells** — 5 spells + 5 elements, 8 elements + 2 spells, anything in
  between. Buildcraft = how you split the pool.
- ✅ **Start: 5 total slots at Level 1.**
- ✅ **Preset validation:** a preset must contain **at least 1 element** and
  **at least 1 offensive spell**. (Guarantees every duelist can, in
  principle, win.)
- 📝 **Slot growth proposal:** +1 slot at each 5-level milestone
  (L5, 10, 15, … 45) → **14 slots at L45**. Keeps slot pressure real at max
  level: 9+ elements and a full spellbook will never all fit, so split
  decisions persist forever. ❓ Confirm rate (or provide a schedule).
- 💡 UI: slot count displayed as one bar with element/spell chips filling it,
  so the tradeoff is visible while editing.

---

## 2. Level curve (1–50) 📝

### 2.1 Requirements
Per-level XP requirement grows geometrically:

> **XP to advance from level L → L+1 = round(100 × 1.0675^(L−1))**

The ~6.75% growth rate is chosen precisely so that **Level 40 is the halfway
point**: cumulative XP to reach L40 ≈ 17,440; cumulative to L50 ≈ 34,860 —
the last 10 levels cost as much as the first 39. (Any base value works; 100
keeps numbers readable.)

| Level → next | XP needed | Cumulative |
|---|---|---|
| 1 → 2 | 100 | 100 |
| 5 → 6 | 130 | ~560 |
| 10 → 11 | 180 | ~1,340 |
| 15 → 16 | 250 | ~2,420 |
| 20 → 21 | 346 | ~3,920 |
| 25 → 26 | 479 | ~6,000 |
| 30 → 31 | 665 | ~8,870 |
| 35 → 36 | 921 | ~12,860 |
| 40 → 41 | 1,277 | ~17,440 *(half)* |
| 45 → 46 | 1,770 | ~25,100 |
| 49 → 50 | 2,298 | ~34,860 *(max)* |

### 2.2 Combat rewards
Rewards grow too — but at roughly **half** the requirement's rate, so
leveling slows even against level-matched opponents (as requested):

> **Even-match win = round(20 × 1.033^(L−1))**

| Level | Win XP | Wins to next level |
|---|---|---|
| 1 | 20 | 5 |
| 10 | 27 | ~7 |
| 20 | 37 | ~9 |
| 30 | 51 | ~13 |
| 40 | 71 | ~18 |
| 49 | 95 | ~24 |

Feel check: early levels clear in one short session; the final stretch is
~20+ wins per level. Combat-only path to 50 ≈ 600–700 even-match wins;
quests, campaign clears, and non-combat XP (§3) should realistically cut
that roughly in half.

### 2.3 Opponent-level modifier 📝
Fighting up rewards more — **but not 1:1 with the opponent's own XP value**:

> **XP = evenMatchWin(yourLevel) × (1 + 0.10 × (theirLevel − yourLevel))**,
> clamped to **[0.25×, 1.75×]**

- +5 levels → 1.5× (risky but rewarding); +8 or more → capped 1.75×.
- −5 levels → 0.5×; −8 or beyond → floor 0.25× (down-farming never quite
  dies, but stops being efficient).
- The modifier applies to campaign monsters and PvP alike.

### 2.4 Non-win outcomes 📝
- **Loss:** 25% of the win value (a lost duel still teaches).
- **Draw:** 40%.
- **Win by opponent surrender/abandonment:** full win XP (never punish the
  player who stayed).
- **Loss by your own 3-forfeit auto-surrender:** 0 XP (no AFK drip).
- **AI stand-in duels** (quick-match fallback, practice roster): 50% of PvP
  values — real but clearly secondary. Campaign fights pay full value
  (single-player remains the primary XP source, per GAME_DESIGN §4).

### 2.5 Anti-farm guards 📝
- Repeat-opponent decay in PvP: 100% / 75% / 50% / 25% XP for the 1st–4th+
  duel against the same player per day (resets daily). Kills win-trading
  without hurting friendly rematch sessions much.
- Campaign repeat-clear XP uses the existing repeatable-node rules; one-time
  first-clear bonuses are where the big campaign XP lives.

---

## 3. XP beyond combat 📝

⚠️ **Predates the skills decision — needs reconciliation (review
2026-07-21).** This section treats crafting/enchanting as *player*-XP sources
with daily caps. Since then, ITEMS_DESIGN §6a established **nine separate
skill tracks outside player level** (Mining, Felling, Foraging; Tailoring,
Potions, Enchanting, Jewelry, Metalworking, Woodcarving). ❓ Rulings needed:
do processing/gathering actions grant **both** skill XP and player XP (this
table), or skill XP only? And does the 30–40% ceiling below survive nine
skills' worth of activity, or does it need to be a shared pool across all of
them? Also unspecified: whether **Academy-mode** duels grant player XP.

Target: non-combat sources can contribute meaningfully but not carry you —
**cap their practical pace at ~30–40% of leveling**, so a pure crafter
plateaus and a duelist who also crafts feels accelerated, not obligated.

| Source | XP shape | Notes |
|---|---|---|
| **Daily quests** (exists) | ~1 even-match win each | "Win 3 duels" etc.; the daily session anchor |
| **Weekly quests** (exists) | ~5 wins | Bigger arc ("Reach level 3", "Win with 3 elements") |
| **Crafting** | small XP per craft, **daily cap** (~2 wins' worth) | Transmute/salvage loops; cap prevents mindless grinding |
| **Enchanting** | medium XP, consumes materials | Material cost is the natural rate limiter — can be uncapped |
| **First-time bonuses** | one-shot chunks | First win vs each AI persona, first clear of each campaign node, first win with each element |
| **Discovery** | small one-shots | New region visited, new spell used in a winning duel ("spell trials") |
| **Rested XP** 💡 | first 2–3 duels of the day at 1.5× | Retention lever; stacks with dailies as the session opener |

💡 Enchanting/crafting XP awards should scale with material tier, not player
level — high-level players crafting trash get trash XP, which keeps the
30–40% ceiling self-enforcing.

---

## 4. Unlock schedule ✅ (complete — every spell placed)

| Level | Charge cap | Elements | Spells unlocked |
|---|---|---|---|
| **1** | **2** | **Tier 1** (Aqua, Pyro, Flora) | Flick, Bolt, Ward, Aegis, Quicken |
| **5** | — | — | Blast, Sap |
| **10** | **3** | — | Surge, Volley |
| **15** | — | **Tier 2 — Kinetic** (Electro, Aero, Geo) | Leech, Discharge |
| **20** | **4** | — | Ruin, Barrier, Barrage |
| **25** | — | — | Overload, Empower, Rampart, Hallow 📝 |
| **30** | — | **Tier 3 — Celestial** (Solar, Lunar, Astral) 📝 | Phase |
| **35** | — | — | Jolt, Flurry, Bulwark, Hasty |
| **40** | **5** | — | Cataclysm, Sanctuary, Drain |
| **45** | — | **Tier 4 — Ethereal** (Sanctus, Umbra, Arcane) 📝 | — |
| **50** | — | — | max level |

📝 **The level cap stays 50, but Ethereal *content* runs to enemy level 60**
(GAME_DESIGN §5). The last three Ethereal zones are deliberately above your
level — you close a gap of up to ten levels with **equipment**, not XP. Two
things this schedule doesn't yet answer: ❓ where **post-cap XP** goes (it
needs a sink — motes, currency, or a paragon trickle), and ❓ **what one
enemy level is worth** in HP and damage, which is the constant the whole
endgame curve rests on.

📝 **Revised for the V2 expansion** (TYPE_EFFECTS_DESIGN §0): the old Tier 3
(Radiant/Umbra/Arcane) became Tier 4 **Ethereal** at L45, with Radiant renamed
**Sanctus**; the new **Celestial** tier (Solar/Lunar/Astral) takes the L30 slot.
⚠️ Consequence: **Umbra and Arcane — and therefore Creeping Dark and Arcane
Knowledge — move from L30 to L45**, leaving L30–44 without an info-war or
damage-stacking element. Solar inherits Blind, so L30 still gets a proc-based
Tier 3 effect.

All 25 engine spells are placed. The L35 bucket ("all remaining
non-charge-5") resolves to Jolt, Flurry, Bulwark, Hasty; every 5-cost spell
(Cataclysm, Sanctuary, Drain) arrives with the charge-5 cap at L40.

**Spellbook reference** (from the engine, for balance reading):

| Spell | Cost | Priority | Effect |
|---|---|---|---|
| Flick | 0 | 5 | 4–6 dmg |
| Bolt | 1 | 9 | 11–14 dmg |
| Blast | 2 | 9 | 20–26 dmg |
| Surge | 3 | 9 | 31–39 dmg |
| Ruin | 4 | 9 | 44–53 dmg |
| Cataclysm | 5 | 9 | 59–72 dmg |
| Jolt | 2 | 5 | 14–18 dmg, seizes Haste |
| Flurry | 1 | 9 | 3–5 dmg × 3 hits |
| Volley | 3 | 9 | 8–11 dmg × 4 hits |
| Barrage | 1+X | 9 | 10–12 dmg per charge spent |
| Sap | 1 | 9 | 9–11 dmg, lifesteal |
| Leech | 3 | 9 | 25–31 dmg, lifesteal |
| Drain | 5 | 9 | 47–58 dmg, lifesteal |
| Ward | 1 | 3 | 13–17 shield |
| Aegis | 2 | 3 | 26–34 shield |
| Bulwark | 3 | 3 | 39–51 shield |
| Rampart | 4 | 3 | 52–68 shield |
| Sanctuary | 5 | 3 | 65–85 shield |
| Barrier | 2 | 3 | blocks one hit fully |
| Empower | 3 | 7 | next turn deals ×2 damage |
| Quicken | 2 | 7 | next spell acts 2 sooner |
| Phase | 3 | 7 | phase effect (aux) |
| Hasty | 0 | 7 | seizes Haste |
| Discharge | 3 | 7 | wipes all enemy charge |
| Overload | 2 | 7 | 8–12 dmg per point of ENEMY charge |

**Flags:**
- 📝 Note the L35 utility spike: Jolt/Hasty (initiative) and Bulwark arrive
  together — expect the meta to shift noticeably at L35.

### 4.1 Interactions worth knowing (derived, not new rules)

⚠️ *Revised 2026-07-21 for the "charge spent = the spell's COST" ruling
(ITEMS_DESIGN §5b.3a): these notes now depend on which spells you own, not
on your charge cap.*

- **Arcane Knowledge is live from L45** (Ethereal), and only via spells
  **costing** 4+ — by then all of them are unlocked, so the constraint is
  moot at max level. *(Pre-V2 this was L30.)*
- **Solar's Blind** (inheriting Radiant's mechanic at L30) reaches 40% only by
  casting a 4-**cost** spell (Ruin/Rampart), and 50% only with the 5-cost
  spells at L40. Cheap spells cast at high charge no longer blind at high
  rates.
- **Umbra's Midnight** (15 stacks) arrives at L45, by which point 5-cost casts
  are available — so the "three 5-cost casts" path is the normal route, not a
  max-level flex. *(Pre-V2 this was a L30 mechanic reachable only via 4-cost
  casts.)*
- **Discharge arriving at L15 pairs with Tier 2** — the charge-counterplay
  spell lands in the same level as the tempo-disruption tier. Thematic and
  teaches the counter role early.
- **L1–4 dueling** is Flick/Bolt/Ward tempo with charge-2 — effectively the
  tutorial meta; Blast at L5 is the first "big" spell.
- Preset validation (≥1 element, ≥1 offensive spell) is satisfiable from L1:
  Flick and Bolt are both offensive.

---

## 5. Open questions

| # | Question | Section |
|---|---|---|
| 1 | Slot growth rate: +1 per 5 levels (14 at L45) OK, or a custom schedule? | §1 |
| 2 | Confirm XP constants (base 100, growth 1.0675, reward base 20 / 1.033) or retune after playtests | §2 |
| 3 | Anti-farm: repeat-opponent decay acceptable for friendly rematch sessions? | §2.5 |
| 4 | ⚠️ Reconcile §3 with the nine skill tracks: skill XP only, or both? Shared 30–40% ceiling? | §3 |
| 5 | Does Academy mode grant player XP / quest credit? | §3 |

---

## Changelog

**Rev 2** — Unlock schedule completed: Barrage → L20 (dupe resolved),
Discharge → L15, Drain + Cataclysm → L40 (Cataclysm briefly at L35, moved so
no spell unlocks before its charge cap); L35/L40 buckets made explicit
(Jolt, Flurry, Bulwark, Hasty / Cataclysm, Sanctuary, Drain). Full engine
spellbook reference table added (all 25 spells exist in code — no specs
needed).

**Rev 1** — Initial: shared slot pool (5 at L1, ≥1 element + ≥1 offensive
spell validation), geometric XP curve with L40-halfway property (~6.75%
growth), reward curve at half the growth rate, opponent-level modifier,
non-combat XP sources with 30–40% ceiling, unlock schedule L1–L50 with
flags.
