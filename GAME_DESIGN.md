# Masters of Magic 2 — Game Design

A remake/sequel of Masters of Magic (MoM1). Flutter app targeting phones, tablets, and browsers.

Legend: ✅ decided · 📝 draft (needs review) · 💡 idea bank (later) · ❓ open question

---

## 1. Core Combat ("Mage Duel")

✅ Turn-based 1v1 duel with **simultaneous turns** — both players lock in a move,
then the round resolves. Prediction/mind-games are the heart of the game.

### Turn flow
1. If you have **0 charge**, you first choose a **Magic Element** for this casting cycle.
2. Each turn you either:
   - **Charge** ("begin casting" — final term TBD): +1 charge, no attack or defense this turn. Max charge = 5.
   - **Cast a spell** with `charge cost <= current charge`.
3. ✅ Casting a spell **consumes ALL charge** (even leftover above the spell's cost) and ends the cycle — next turn you pick a new element.
4. ✅ You must keep the **same element** for an entire charging cycle (baseline rule).
5. ✅ 0-cost spells (e.g. Flick) can always be cast, even at 0 charge — you're never forced to charge.

### Forfeited turns — two kinds ✅

A turn can pass without an action for two very different reasons, and the
game must treat them differently:

| Kind | Cause | Counts toward the 3-strike auto-surrender? |
|---|---|---|
| **Timeout forfeit** | The player ran out the 10s clock, tabbed away, or disconnected | ✅ **Yes** — this is how a vanished opponent eventually loses |
| **Compelled forfeit** | The game left the player **no legal action** | 🚫 **No** — never penalize a player for a situation they couldn't act in |

⚠️ **Design rule: no combination of effects may leave a player with zero legal
actions.** Rule 5 above (0-cost spells are always castable) plus "you can
always charge below max" currently guarantees this — at max charge every spell
is affordable, and below max you can always channel.

However, a compelled forfeit is still *reachable* in principle — e.g. a narrow
loadout at max charge, or the proposed **lockout effects**
([ITEMS_DESIGN.md](ITEMS_DESIGN.md) §5b.1) which can bar whole action
categories. So the distinction must exist in the engine regardless: being
locked out is not the same as being asleep, and only the latter should march
you toward an auto-surrender.

📝 Implementation note: the forfeit streak lives in `DuelController`
(`forfeitLimit`, currently 3). It counts every `ForfeitAction` today; when
lockouts land it needs to distinguish the compelled case and skip the
increment.

⚠️ **Netcode prerequisite:** the wire protocol has one forfeit token (`'F'`),
and in commit-reveal it's the **opponent's client** that counts your
forfeits. Compelled-vs-timeout must be distinguishable on the wire *and
verifiable* (a cheater could claim "compelled" to dodge the auto-surrender;
the claim is checkable against the visible statuses/loadout). `TunableAi`
also returns `ForfeitAction` when nothing is playable — a compelled forfeit
that currently counts. Details: ITEMS_DESIGN §5b.1.

### Resolution order — Priority
✅ Formalized, transparent **Priority 1–10** property on every spell (priority 1 acts first):

| Priority | Category |
|---|---|
| 1 | Instant attacks |
| 3 | Shields |
| 4 | **Channel** (charging) |
| 5 | Quick attacks (Flick, Jolt) |
| 7 | Other defensive / aux spells |
| 9 | Regular spells |
| — | End-of-turn effects (burn ticks, etc.) |

- 📝 Aux spells may modify priority (e.g. "your next spell acts X sooner").
- ✅ **Channel has priority 4** (after shields, before quick attacks). This is why a
  faster Discharge (7) or Overload (7) interacts with a same-turn channel — see below.
- ✅ Charge-scaling spells (Barrage, Overload) read charge **live at resolution**, so a
  faster Discharge fizzles a same-turn Barrage, and channeling right before an Overload
  makes the hit bigger.
- ✅ A mage defeated at an earlier priority step does **not** resolve casts at later
  steps (e.g. a Quickened kill at priority 2 prevents the victim's priority-9 attack).

### Haste (initiative tiebreaker)
✅ A single **Haste** token — held by nobody, you, or your opponent — breaks
same-priority collisions: **the holder's spell resolves first**, so a lethal hit lands
before the opponent can fire back. This replaces the old "same-priority mutual kills are
a draw" rule (draws dropped from ~12% to ~0% in AI-vs-AI sims once Haste was added).
- Only consulted for same-priority ties, using the **start-of-turn** holder.
- **While unheld:** the first non-channel cast grabs it; if both cast, the faster one
  grabs it; a same-priority pair leaves it unheld.
- **Once held:** only a Haste-granting spell (Hasty, Jolt) moves it, and it goes to the
  **last grant to resolve**. So a same-priority pair **flips it to the opponent** (the
  holder resolves first via the tiebreak, so the other's grant lands last and steals
  it); among different-priority grants the slower one wins. Ordinary spells don't move it.
- Channeling never grants or moves Haste.

### Health
- MoM1: everyone started at 100 HP.
- ✅ MoM2: base HP modified by **equipment**.

---

## 2. Elements

✅ **SUPERSEDED & SHIPPED:** [TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md)
is the authority on elements — the 9-element roster in three tiers (Primal:
Aqua/Pyro/Flora · Kinetic: Electro/Aero/Geo · Ethereal: Radiant/Umbra/Arcane),
three closed counter-triangles, and per-element side-effects. **Implemented
and live as of v0.9.0.** Renames from the old roster: Water→Aqua, Fire→Pyro,
Electric→Electro, Air→Aero, Earth→Geo, Light→Radiant, Shadow→Umbra; Flora and
Arcane added; Ice dropped.

Still true: shield counter math (×2 vs the countered element's shield; bare-
health damage is element-neutral) and elements-as-information (your shield's
color reveals its element). **No longer true:** "elements matter only for
shield math" — every element now carries a side-effect (Ignite, Waterlogged,
Photosynthesis, Static Feedback, Tailwind, Stagger, Blind, Creeping Dark,
Arcane Knowledge).

### Counter wheel — ❌ SUPERSEDED (kept for history)

*The variable-volatility wheel below was replaced by the three uniform
counter-triangles in TYPE_EFFECTS_DESIGN (every element counters exactly one
and is countered by exactly one, within its tier). The engine's element tests
now enforce volatility = 1 for all nine.*

✅ Rule: elements need not all have 2 strengths / 2 weaknesses. The only invariant is
**per-element balance**: # strengths == # weaknesses. Different counts = different
"volatility", which is itself a strategic identity. Mutual counters are legal under
this rule (each adds one to both columns) but the current draft uses none.

| Element | Volatility | Strong against (2× to their shields) | Weak against |
|---|---|---|---|
| Air | 0/0 | — | — |
| Fire | 2/2 | Ice, Shadow | Water, Light |
| Water | 2/2 | Fire, Light | Electric, Shadow |
| Earth | 2/2 | Electric, Light | Ice, Shadow |
| Electric | 2/2 | Water, Shadow | Earth, Light |
| Ice | 2/2 | Earth, Light | Fire, Shadow |
| Light | 3/3 | Shadow, Fire, Electric | Water, Earth, Ice |
| Shadow | 3/3 | Water, Earth, Ice | Light, Fire, Electric |

Flavor / mnemonics:
- **Air** — "the untouchable wind": counters nothing, countered by nothing. Its shields
  can never be double-broken (safest, zero info leaked), but its attacks never crack
  shields. The poker player's element.
- **Light outshines every other light source** (Fire, Electric, Shadow) but is swallowed
  by the dark places (deep Water, stone Earth, entombing Ice).
- **Shadow claims the dark places** (the depths, the caverns, the long cold night) but is
  banished by everything that glows (Light, firelight, lightning).
- Classics keep intuitive pairings: Water douses Fire; Fire melts Ice; permafrost
  shatters stone; Ice cracks under flame; Earth grounds Electric; Electric conducts
  through Water.
- ⚖️ Balance watch: if Air's "never double-broken shield" proves dominant, tune with
  slightly weaker Air shields or juicier side effects on volatile elements (verify via
  AI-vs-AI simulation).

### Elemental side effects — ✅ SHIPPED (see TYPE_EFFECTS_DESIGN §2–4)
*The early draft (Fire→Burn, Ice→Freeze, Shadow→accuracy loss) grew into the
full nine-effect system: Pyro→Ignite, Aqua→Waterlogged, Flora→Photosynthesis,
Electro→Static Feedback, Aero→Tailwind, Geo→Stagger, Radiant→Blind,
Umbra→Creeping Dark, Arcane→Arcane Knowledge.*

---

## 3. Spells

✅ Spells are **element-agnostic** — any spell takes on your currently charged element
(a Bolt can be a Fire Bolt or Water Bolt, etc.).

✅ **Damage variance**: every damaging spell rolls within an explicit min–max range
(~10–15% around its center, e.g. 4–6, 11–14, 20–26). Each hit of a multi-hit spell
rolls independently. **Shields roll too**, with a **tiny overlap** between a max-roll
attack and a min-roll shield at the same charge level.

✅ **Information rules**: the opponent **can see the element you're charging** (and your
charge count). 💡 A future **Concealed** status (a Shadow side-effect) will hide the
charging element again — the "mystery ?" code path is kept for it. Shields always
visibly carry their element ("the shield's color reveals it").

✅ Loadout: before a match you choose which elements and spells you bring.
MoM2 adds **spell slots** unlocked via leveling.

### Flat-damage offensive
| Spell | Charge | Notes |
|---|---|---|
| Flick | 0 | very low damage |
| Bolt | 1 | low damage |
| Blast | 2 | medium damage |
| *(a few mid-tier spells)* | 3–4 | TBD |
| Cataclysm | 5 | very high damage |

### Multi-hit offensive
| Spell | Charge | Notes |
|---|---|---|
| Flurry | 1 | small damage ×3 |
| Volley | 3 | medium damage ×4 |
| Barrage | X | damage per charge spent (consumes all charge) |

### Lifesteal offensive (heal = damage actually dealt to enemy **health**, not shields)
| Spell | Charge | Notes |
|---|---|---|
| Sap | 1 | small damage |
| Leech | 3 | medium damage |
| Drain | 5 | high damage |

### Defensive
- ✅ One elemental shield per charge level. Shield strength scales **linearly with
  charge** (midpoint 15 × charge: a 4-charge shield is exactly 2× a 2-charge shield);
  attacks scale super-linearly, so offense slowly catches up to defense at high charge.
- ✅ Shields resolve **before** regular attacks (priority 3 vs 9).
- ✅ Counter-element attacks deal **2× damage to the shield**; overflow damage passes
  through to the player at normal (1×) rate. (e.g. 30-dmg water attack vs 50-pt fire
  shield: 25 of the 30 breaks the shield at 2×, remaining 5 hits the player.)
- ✅ **Barrier** (2-charge): blocks 100% of all damage, destroyed after the first hit.
- ✅ **Shield persistence**: players start with **one shield slot**. A cast shield persists
  across turns until depleted or overwritten by casting a new shield.
- 💡 Unlockable 2nd and 3rd shield tiers (multiple simultaneous shields) later.
- 💡 Shield duration types: **permanent** (more expensive) vs **decaying over time**
  (cheaper, good in a pinch). Engine should model shield lifetime from day 1.

### Aux (priority 7 unless noted)
- **Empower** (3) — next offensive spell deals double damage
- **Quicken** (2) — next offensive spell executes before enemy defensives
- **Phase** (3) — next offensive spell ignores shields
- **Hasty** (0) — seizes Haste, nothing else
- **Discharge** (3) — removes ALL of the opponent's charge, no damage (fizzles a
  same-turn Barrage since it's faster)
- **Overload** (2) — a full attack (respects shields, benefits from Empower/Phase)
  dealing ~8–12 damage × the **enemy's** charge, read live at resolution
- **Jolt** is a quick attack (priority 5) that also **grants Haste**
- **Flick** is now a quick attack (priority 5)

---

## 4. Progression & Meta

- ✅ **Levels & XP** — more XP unlocks more spells and spell slots. Single-player is the
  primary source of XP, gold, and loot.
- 📝 **Superseding spec:** [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) — L1–50
  curve (level 40 = halfway XP point), the L1–L50 unlock schedule (charge caps,
  element tiers, spells), non-combat XP, and the **unified slot pool** below.
- 📝 **Spell unlocking**: likely a "studying" timer per spell, skippable with premium
  currency (exact mechanism TBD). Managed from the Spellbook tab. **Temporarily all
  spells are unlocked** until the leveling/unlock schedule is implemented.
- ✅ **Loadout capacity (reworked)**: one pool of **slots shared between elements and
  spells** (5 total at L1, growing with level) — 4 elements + 1 spell or 1 element +
  4 spells are both legal splits. Presets must include ≥1 element and ≥1 offensive
  spell. Supersedes the old "3 element slots + 5 spell slots" split. (Keybinds still
  support up to 8 elements / 10 spells.)
- ✅ **Loadout presets**: named spell/element presets in the Spellbook tab. 1 preset
  slot initially, up to 5 unlocked by leveling.
- ✅ **Loadout switching rules**: in 1-player mode, loadouts can only be changed at a
  dedicated location in town; in PvP, the player picks a loadout before each match.
- 📝 **Superseding spec:** [ITEMS_DESIGN.md](ITEMS_DESIGN.md) — the endgame
  ceiling, archetype sets × element enchants, the modifier vocabulary, the
  elemental-mote economy, and the full catalogue of statuses gear can hook.
- ✅ **Equipment** — items affect stats including max HP. Dropped as loot.
  - ✅ Slots: **Hat, Top, Bottom, Boots, Hands, Neck, Ring, Left hand, Right hand**.
    - Hands = worn gear (gloves or bracers), separate from held items.
    - Held items: one-handed weapons (wand) pair with an off-hand (orb, book,
      shield); **two-handed weapons (staves) occupy both hand slots**.
  - ❓ Rarity tiers TBD (e.g. common → legendary).
  - ❓ Are held items restricted by slot (wand = right only?) or freely assignable?
- ✅ **Luck** — a stat influenced by items/enchantments that increases gold quantity
  and the likelihood of rare drops.
- 🎨 Creative north star: **RuneScape 3** — take inspiration from its equipment/skilling/
  economy feel without plagiarizing or copying assets/names.
- 💡 **Consumables** — potions purchasable/usable.
- 💡 **Enchantments** — enhance equipment.
- 💡 **Crafting** — craft equipment from raw materials.
- ✅ **Daily & weekly quests** for bonus XP.

### Economy / freemium
- ✅ Gold = primary currency (earned in-game).
- ✅ Secondary (premium) currency, primarily from microtransactions.
- ✅ Time-gated processes (crafting, enchanting) skippable with premium currency.

---

## 5. Game Modes

- ✅ **Online 1v1 PvP** with **two Elo ladders** (per ITEMS_DESIGN §7.4):
  **ranked counts gear** (matchmaking should seed on gear power + Elo), and
  **Academy mode** strips all gear and consumables for a separate
  **skills-only Elo**. ❓ Does Academy grant XP / quest credit?
  Single-player is still built first.
- ✅ **Single-player campaign**: battle increasingly difficult monsters that drop
  increasingly good loot. Primary XP/gold/loot source.
  - ✅ Monsters fight by the **exact same rules** as players (elements, charges, spells,
    shields) with an AI brain.

### Adventure loop (push-your-luck)
- ✅ **HP persists between encounters** within an adventure. After each encounter the
  player chooses **"return to town"** (bank the loot) or **"keep going"**.
- ✅ Rewards improve the deeper you push into a single run — and so does the competition.
- ✅ Each area has **5–7 monster types**, a **mini-boss** roughly halfway, and a **boss**
  at the end.
- ✅ **Defeat penalty**: lose the run and **all loot earned during it**, plus a
  **respawn timer** that escalates with each sequential death. Death-timer reset is a
  freemium option.
  - 📝 Escalation details TBD (how fast it grows, how it cools down over time).
- 📝 Assumption to confirm: charge/shields reset between encounters; only HP carries.
- ✅ **No energy/stamina gate for v1** — deliberately deferred.
  - 💡 Gentler "take a break" alternatives to consider later: rested bonus (first N runs
    per day get bonus XP/luck), daily-quest cadence as the natural session shape,
    diminishing returns after many consecutive runs.

### World structure
- ✅ Pokemon-style topology: safe **hub towns** connected by **dangerous routes**, plus
  offshoot dangerous areas branching from towns/paths. All players start in one home
  town; difficulty scales with distance from home.
- ✅ **No walking/terrain simulation** — simple menu-based travel ("Travel to X",
  "Venture into the forest").
- ✅ Each adventure/route shows its **encounter count** up front so progress is visible
  (e.g. "encounter 3 of 7").
- ✅ Areas are **element-themed** (volcano = fire+earth monsters, icy pass = ice+air,
  shadowlands = shadow, etc.).

### Bestiary — 📝 DRAFT (from the V2 inspiration doc + boss design pass)

Enemy rosters per element zone. Each zone runs **5–7 monster types**, three
**mini-bosses**, and a **final boss** (per the adventure-loop rules above).
Bosses drop the best loot — and are the natural home for the rare Tier III/IV
set components ([ITEMS_DESIGN.md](ITEMS_DESIGN.md) §3.5) and for Core-tier
motes.

| Element | Mini-bosses | Final boss |
|---|---|---|
| **Aqua** | Tidal Empress · Maelstrom Horror · Leviathan | **Kraken** |
| **Pyro** | Inferno Lord · Magma Behemoth · Phoenix | **Efreet** |
| **Flora** | Root Matriarch · Spore Warlord · Thorn Colossus | **Guardian of the World Tree** |
| **Electro** | Storm Shaman · Thunder Roc · Voltgeist | **Storm Lord** |
| **Aero** | Wind Wraith · Gale Serpent · Sky Titan | **Tempest Monarch** |
| **Geo** | Earth Titan · Obsidian Golem · Sandstorm Djinn | **Mountain Heart** |
| **Solar** † | Sun Templar · Solar Archon · Prism Sentinel | **Solar Deity** |
| **Umbra** | Void Stalker · Umbral Knight · Eclipse Weaver | **Nightbringer** |
| **Arcane** | Spell Weaver · Mana Golem · Arcane Chimera | **Archmage** |

† ❓ **This roster was written for "Radiant," but every name is solar** (Sun
Templar, Solar Archon, Solar Deity) — so it belongs to the new **Solar**
element rather than to **Holy**, its renamed successor. Assigning it to Solar
here; confirm.

📝 **Missing rosters — three elements have no bestiary yet:** **Holy**,
**Lunar**, and **Astral**. (Holy needs a distinct identity from Solar now that
they're separate elements in separate tiers.)

💡 Note "Void Stalker" survives as a *monster* name even though **Void was
rejected as an element** (TYPE_EFFECTS_DESIGN §0) — no conflict, but worth
knowing it's not an element reference.

❓ Also unmapped: which **zones/regions** host which element's bestiary, and
at what levels. The region table below predates the 12-element roster and
still uses old element names (Fire, Water, Ice, Light, Shadow).

### World map — 📝 DRAFT region brainstorm (names/levels all tunable)

| Ring | Region | Type | Elements | Lv |
|---|---|---|---|---|
| 0 | **Aldermere** | home town | — | — |
| 1 | Whispering Woods | route | Earth, Air | 1–5 |
| 1 | Glimmerbrook | route | Water, Light | 2–6 |
| 1 | Old Quarry | offshoot of Whispering Woods | Earth | 4–8 |
| 2 | **Forgeholm** | mining town | — | — |
| 2 | Cinderpeak Foothills | route (Aldermere→Forgeholm) | Fire, Earth | 8–14 |
| 2 | **Galehaven** | port town | — | — |
| 2 | Stormcliff Coast | route (Aldermere→Galehaven) | Water, Electric | 8–14 |
| 3 | The Caldera | offshoot of Forgeholm | Fire | 15–22 |
| 3 | Crystal Caverns | offshoot of Forgeholm | Earth, Light | 16–24 |
| 3 | Frostfell Pass | route (Forgeholm→Rimeholt) | Ice, Air | 18–26 |
| 4 | **Rimeholt** | mountain village | — | — |
| 4 | The Mirrormere | offshoot of Rimeholt (frozen lake) | Water, Ice | 26–34 |
| 4 | Thunderspire Peaks | route (Galehaven→Rimeholt) | Electric, Air | 26–34 |
| 4 | Radiant Sanctum | offshoot of Rimeholt | Light | 30–38 |
| 5 | Nightfen Marsh | route (Rimeholt→wastes) | Water, Shadow | 38–46 |
| 5 | The Umbral Wastes | far-edge region | Shadow | 45–55 |
| 5 | The Eclipsed Citadel | final dungeon | Shadow, Light | 55+ |

---

## 5b. Accounts & Backend

- ✅ **Firebase** is the backend (Auth + Firestore; Cloud Functions later for PvP
  resolution and Elo).
- ✅ Even single-player saves persist to the cloud (with local cache for offline play).
- ✅ Account creation requires: **validated email**, **password**, **character name**,
  and a **captcha**.
  - 📝 Implementation: Firebase Auth (email/password + email verification link);
    bot protection via Firebase App Check — reCAPTCHA on web, Play Integrity (Android)
    / App Attest (iOS) on mobile, so mobile users don't see a visible captcha.
  - ❓ Character name uniqueness rules & change policy.
- 📝 PvP integrity: simultaneous turns require server-authoritative resolution
  (or commit-reveal) via Cloud Functions so a client can't peek at the opponent's move.

---

## 6. Duel screen UI (v1)

- ✅ **Landscape phone layout** ("arena" direction): your mage on the left, enemy on
  the right, status panels in the top corners, spell bar along the bottom.
- ✅ **Not card/deck based** — spells are icon buttons.
- ✅ **Character graphics**: fine-pixel (32x44) statically drawn mages with shading;
  apparel (hat, robe, boots, staff...) is visible and palette-swaps with equipment.
  (Upgraded from 16x22 after playtest feedback that it read as too blocky.)
- ✅ **Spell animations**: charge swirls, projectiles in the cast element's color,
  shield domes, hit flashes, floating damage numbers, defeat animation.
- ✅ **Tooltips** on spell icons: cost, priority (with category name), damage range,
  description. Element icons show strengths/weaknesses.
- ✅ **Action bar layout**: element slots on top, then two rows of five spell slots so
  the QWERT and ASDFG shortcut rows align like a keyboard; Channel to the right.
- ✅ **Keyboard shortcuts** bind to SLOTS, not contents: 1-8 = element slots,
  QWERT/ASDFG = spell slots 1-10, C = channel. Slots are unlockable later.
- ✅ **Surrender** (PvP) / **Flee** (campaign): forfeits the match as a loss, behind a
  confirmation dialog. Engine support: `DuelEngine.concede()`.
- ✅ Turn resolution plays events in priority order as an animated sequence whose
  intensity scales with charge spent (bigger projectiles, more impact rings, screen
  shake at 3+ charge, full-screen flash at Cataclysm tier).

---

## 7. 💡 Idea Bank (banked for later — do not build yet)

1. **Multi-element charging** — an upgrade allowing charging different elements in one
   cycle and dealing damage of multiple types.
2. **Charge retention** — upgrade/ability to keep unused charge after casting.
3. **Element conversion** — a 2-charge spell converting remaining charge to a new element.
4. **Elemental attunement / transformation** — a spell that makes the caster "become" an
   element (fire elemental, shadow demon...): +X% to attacks of that type, but your own
   health becomes subject to shield-cracking counter logic.
5. **Unlockable elements** beyond the launch 8.
6. **Priority-boosting aux spells** (priority +X per charge or similar).
7. **Duel-mechanic stats on hand slots** — make the one-hand-plus-off-hand vs
   two-hand choice a playstyle decision, not just a stat trade: e.g. wand boosts
   1–2 charge spells; staff boosts 4–5 charge spells but costs the off-hand;
   off-hand shield strengthens shield spells; tome improves aux buffs.
8. **Tiamonds** — a consumable/currency that instantly **skips time-gated
   processes** (travel, crafting, researching/studying). ❓ Relationship to the
   existing premium currency ("gems") TBD — Tiamonds may BE the premium currency
   renamed, or a distinct time-skip item earned/bought separately.
   ⚠️ *Review note (2026-07-21): ITEMS_DESIGN §3.6 now defines the same role
   for "purple gems" (cooldown skips, "time crystals") — these are almost
   certainly one concept under two names; reconcile before implementing
   either.*
9. **Timed travel** — traveling between locations takes real time. Early legs
   ~10–15s; scales up to hours for distant regions. Skippable with [8] Tiamonds.
   (Pairs with the crafting/research timers as the core freemium time-gate loop.)
10. **First-visit town gate** — unlocking a town for the first time requires
    completing a one-time **required adventure** (a gating encounter) before the
    town's services open. ❓ Design: towns currently have no adventure of their
    own — likely a boss encounter on the approaching route, or a special
    town-intro fight.

### 7a. 💡 Banked spells

Designed but **not scheduled** — no unlock levels assigned; the current
schedule (PROGRESSION_DESIGN §4) is full through L40 with the 25 shipped
spells. Bank until there's a reason to slot them in.

**Batch 1 — built on the existing status framework** (DoTs, HoTs, streaks,
the precedence pipeline). Buildable today; no new engine mechanics needed.

| Spell | Cost | Priority | Effect |
|---|---|---|---|
| **Regrowth** | 2 | 7 aux | HoT: heal 5 at end of turn for 3 turns (heal band, so it lands before same-turn burns) |
| **Blight** | 2 | 9 | 5–7 now, plus **Corrosion**: 4–5 at end of turn for 3 turns, in your cast element (shield-aware ticks) |
| **Combust** | 1 | 5 quick | Consume all DoTs on the enemy and deal their remaining total as one shield-aware hit; otherwise a 4–6 spark |
| **Purify** | 1 | 7 aux | Remove all negative statuses from yourself |
| **Crescendo** | 2 | 9 | 8–10 damage × your current element streak (capped at 5) — the first spell that *reads the streak counter* |
| **Truestrike** | 1 | 7 aux | Your next offensive spell cannot miss and cannot fizzle |
| **Dawnmend** | 3 | 7 aux | Heal 9–12 at the **start** of your next 2 turns — the first tenant of the empty start lane |
| **Siphon** | 3 | 9 | Parasite: 3–4 damage at end of each of the next 3 turns, healing you for the health damage dealt |

**Batch 2 — built on the proposed mechanics** in
[ITEMS_DESIGN.md](ITEMS_DESIGN.md) §5b. Each needs its mechanic to exist
first; they are the spell-side expression of those effects.

| Spell | Cost | Priority | Needs | Effect |
|---|---|---|---|---|
| **Hush** | 2 | 7 aux | Silence | Target can't cast offensive spells for 2 turns |
| **Shackle** | 2 | 7 aux | Bind | Target can't charge for 2 turns |
| **Sunder** | 3 | 7 aux | Sunder | Target can't raise shields for 2 turns |
| **Endure** | 2 | 7 aux | Endurance | Self: the next lethal hit leaves you at 1 HP (once) |
| **Reservoir** | 2 | 7 aux | Charge retention | Self: your next cast keeps its unspent charge |
| **Siege** | 3 | 9 | Sustained | Escalating attack — grows each turn, interruptible |
| **Vigil** | 3 | 3 | Sustained | Escalating shield — grows each turn, interruptible |
| **Disrupt** | 1 | 5 quick | Interrupt | Interrupts a sustained spell; minor damage otherwise |

💡 Also banked from the earlier brainstorm, held back deliberately:
**Dispel** (strip the enemy's *beneficial* statuses — risks making Flora
unplayable if cheap), **Exhaust** (start the enemy's Fatigue 5 turns early —
dead weight before turn ~25), **Cocoon** (a shield that also heals while it
holds — crowds the shield ladder).

⚠️ Note the lockout spells (Hush/Shackle/Sunder) are subject to the
always-a-legal-action invariant and the forfeit-counter rule in §1.

---

## 8. App structure & roadmap

### Navigation (phone-first)
- ✅ Five tabs: **Map · Inventory · Home · Spellbook · Social**.
  - **Map**: current location, travel, location-specific actions (shop, etc.);
    campaign adventures launch from here.
  - **Inventory**: items + crafting (transmute / craft / salvage).
    ⚠️ *"Unlimited space" conflicts with ITEMS_DESIGN's 20-item backpack.*
    ❓ Ruling needed: presumably a **bank/backpack split** — unlimited (or
    large) storage at home/town, the 20-item backpack (+ craftable pouches)
    being what you *carry on a run*. Define explicitly.
  - **Home** (center): dashboard — quests, resume adventure, PvP queue, timers,
    currencies, events.
  - **Spellbook**: spell collection, unlocks (studying timers), loadout presets.
  - **Social**: friends & challenges (stub for now).
- ✅ Duels are landscape; menu orientation decided via mockups (avoid forcing the
  player to flip back and forth).

### Data model
- ✅ `PlayerProfile` and friends are shaped as Firestore documents from day 1, but
  persisted locally until the Firebase project is initialized.

### Phase 1 — ✅ SHIPPED
Live at **https://mastersofmagic2.web.app** (Firebase project `mastersofmagic2`).
Five-tab nav (Option C: raised center Home button with a **magic-wand** icon;
bottom bar in portrait, left rail in landscape), map travel + location actions
("visit shop" placeholder), campaign adventures with XP/gold rewards and
level-ups, inventory placeholder, spellbook with presets, rotate-to-duel guard
(menus any orientation, duels landscape). Find-a-duel is a pinned bottom CTA.
- ✅ **Firebase Auth** (email/password): create-account (character name, email,
  password, confirm), sign-in, email-verification send, sign-out — reachable
  from the Social tab; guest play preserved (no gate). Email/password worked
  out of the box (client init provisioned the Auth config); no console toggle
  needed. **Captcha via App Check is still pending** a reCAPTCHA key.
- ✅ Loadout caps: **3 element + 5 spell slots**; **all spells unlocked** for now;
  old saves auto-clamped on load.
- ✅ Hosting cache: app-shell files (`index.html`, `flutter_bootstrap.js`,
  `flutter_service_worker.js`, `main.dart.js`) serve `Cache-Control: no-cache`
  so returning players always get the latest build.
- ✅ Stale-build fix: builds use `--pwa-strategy=none` (no service worker), and a
  **kill-switch service worker** ships at the old worker's URL to purge caches,
  unregister, and reload clients that installed the early offline-first worker.
  (`web/flutter_service_worker.js` must be copied into `build/web/` post-build —
  the build empties that reserved filename.)
- ✅ **About panel** (app name + version) on the Account screen near Sign out;
  version constant lives in `lib/game/app_version.dart` (keep in sync with
  pubspec). *(Version number in this doc goes stale — trust the constant.)*
- ✅ **Pixel wizard-hat favicon** + PWA icons (generated, in `web/`); page title
  and manifest branded "Masters of Magic 2".
- ✅ Desktop layout: tab content is centered in a **720px max-width column**;
  the spellbook grid uses fixed-size tiles (no more giant cards on monitors).
- ⚠️ A throwaway test account (`zephyr@example.com`) exists from verifying signup;
  delete from the console if desired.
Deploy:
```
flutter build web --release --pwa-strategy=none
cp web/flutter_service_worker.js build/web/flutter_service_worker.js
firebase deploy --only hosting
```

### Multiplayer architecture (v0.8.0)
- ✅ **Matchmaking is separate from dueling**: quick match / friendly room codes /
  practice roster all just produce an `OpponentDriver`; the duel screen and engine
  never know whether the opponent is human or AI.
- ✅ **Commit-reveal over Firestore** (trustless): per turn both clients write
  `sha256(move|nonce)`, then reveal; each verifies the other and resolves the turn
  locally on the shared deterministic engine, seeded by `deriveTurnSeed(master, turn,
  moveA, moveB)` — proven by a lockstep engine test.
- ✅ **Quick match**: claims a waiting queue ticket (Firestore transaction) or posts
  one; if no human answers within ~10s, an **AI persona stands in** (nearest level).
- ✅ **AI roster**: Wick(1), Brightgale(3), Thornwall(5), Morwen(8), Procarius(12) —
  distinct loadouts, apparel, and TunableAi skill dials (mistakeChance/aggression/
  caution). Campaign foes reuse the nearest persona re-skinned with the monster name.
- ✅ **Disconnects**: the 10s move timer forfeits unmade moves; a vanished remote
  opponent is auto-forfeited each turn until they lose. **Three forfeited turns
  in a row auto-surrenders** the duel (so a closed tab resolves in ~75s rather
  than dragging on) — see the two kinds of forfeit below.
- 📝 v1 trust model: room codes are secrets, rules require sign-in; server-authoritative
  arbitration deferred until ranked play.

### Phase 2 (next)
Starts with the inventory/crafting/item-catalog design session: align on level
tiers, build tiers 1–2, playtest, then extend tiers as the game matures.

---

## 9. ❓ Open Questions

~~1. Counter wheel assignments~~ ✅ resolved — three uniform triangles
(TYPE_EFFECTS_DESIGN), shipped.
~~2. Status-effect roster~~ ✅ resolved — all nine effects shipped.
3. Exact damage/shield numbers table (engine + simulator now exist; needs a balance pass).
~~4. Equipment rarity tiers~~ ✅ resolved — Common→Legendary mapped 1:1 to
Dust→Heart (ITEMS_DESIGN §8); only "set pieces Epic+?" remains there.
5. Respawn-timer escalation curve (growth per sequential death, cooldown).
6. Do charge/shields reset between encounters within a run? (assumed yes)
7. Character name uniqueness & change policy.
8. Bank/backpack storage split (see the Inventory note in §8 Navigation).
9. Does Academy mode grant XP / quest credit? (§5)
10. Tiamonds vs purple gems — one time-skip currency or two? (Idea bank #8)
