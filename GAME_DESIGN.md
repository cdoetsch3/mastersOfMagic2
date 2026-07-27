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

### Combat stats — 📝 NEW (accuracy, crit, deflection)

Six stats that sit underneath every attack. They exist mainly so **equipment
has numbers to move** that aren't just flat damage, and so defensive builds
have an axis other than shields.

| Stat | Lives on | Default |
|---|---|---|
| **Accuracy** | spell (+ gear) | **100%** for every shipped spell · **can exceed 100%** |
| **Dodge** | mage (gear) | 0% · subtracts from accuracy |
| **Crit Chance** | mage (gear) | **0%** |
| **Crit Damage** | mage (gear) | +50% *(the bonus when a crit lands)* |
| **Deflection Chance** | mage (gear) | 0% |
| **Deflection Amount** | mage (gear) | — *(% of damage reduced on proc; **capped at 50% for players**)* |

✅ **Crit Chance starts at 0 on purpose.** Crit and Crit Damage are a pair;
until gear grants chance, crit damage is inert. That keeps the early game
clean and makes the first crit item feel like an unlock rather than a
percentage nudge.

#### One hit roll, not two ⭐

⚠️ **Blind already implements a miss chance** (TYPE_EFFECTS §4.1). Two
independent miss systems would double-roll every attack and make the numbers
unreadable. So **Blind is re-expressed as a flat −50 accuracy penalty** and
folded into a single subtraction:

```
hitChance = spellAccuracy + gearAccuracy − targetDodge − blindPenalty
```

- ✅ **Pure subtraction, one calculation, no clamp at 100%.** Accuracy above
  100% is real and useful: **120% accuracy vs 30% dodge still hits 90% of the
  time.** That makes accuracy the natural counter-pick to a dodge build —
  exactly the adaptive tech-slot role ITEMS §2.2 wants — instead of a stat
  that's wasted the moment it's maxed.
- ✅ **Blind is a flat −50**, matching its old 50% miss chance.
- ✅ **The hit roll is per *cast*** (a whole harmful spell hits or misses),
  which preserves Blind's exact behaviour — a blinded multi-hit spell whiffs
  as a unit. Only crit and deflection roll per *hit*. And the roll is taken
  **only when the hit chance is below 100** (dodge or blind present), so a
  default-stat attack draws no RNG — that's why turning these stats on is the
  only thing that ever changes a duel.
- Astral's Blind exemption becomes "drop the blind term" — same behaviour,
  no special case in the roll.
- 📝 **0% hit chance is reachable, and that's allowed.** No hard floor. An
  all-in dodge build *may* temporarily zero out an attacker; the guardrail is
  **content design** — items and spells tuned so it's unlikely and
  short-lived — not a clamp in the engine.
  ⚠️ **Keep it temporary.** A permanent 0% state is the same "opponent no
  longer gets to play" failure that got Waterlogged capped at every-3rd
  (ITEMS §7.1). Reaching 0 through a *status with a duration* is fine;
  reaching it through flat stat totals that never expire is not. Worth
  holding those two rulings side by side when tuning dodge gear.

#### Deflection — damage reduction

✅ **Deflection reduces the damage you take. It does not bounce it back.**
Take a 100-damage hit with 20% deflection and you take **80** — the other 20
is simply gone.

```
on proc:  taken = damage × (1 − deflectionAmount)
```

- ✅ **Cap deflection at 50% for players.** 📝 Note the wording — the cap is a
  *player* cap, so enemies and bosses may be tuned past it.
- 💡 **"Reflection" is a separate modifier worth adding on top** — a late-game
  perk that sends the *deflected* portion back at the attacker. Distinct from
  deflection itself; deflection is the defensive base, reflection is the
  optional aggressive rider.
- ✅ **Reflection chains terminate on their own, so let them chain.** 100
  deflected/reflected at 20% → they take 20 → they deflect and reflect →
  you take 4 → 1 → done. It's geometric decay, and with the 50% player cap
  the worst case still halves each bounce. 📝 Two implementation notes:
  **round down** so it provably reaches 0, and keep the arithmetic integer so
  both clients terminate on the identical step. A very niche interaction —
  it needs a small late-game subset of effects on *both* mages — but it
  should be correct rather than special-cased.
- ✅ **Deflection resolves before Astral's pierce split** — pierce governs how
  the *remaining* damage is routed.

#### Multi-hit ⚠️

Crit and deflection both **roll per hit**, so Flurry (×3) and Volley (×4) make
three and four rolls. That deliberately makes multi-hit spells
**low-variance** crit carriers and single big spells high-variance — a real
build axis, and one more reason ITEMS §7.3 flags multi-hit + on-hit effects as
a thing to watch.

#### Should these be element effects?

🚫 **Recommend no — keep them on equipment.** Every element already carries a
side-effect; a second one each would double the mechanics a player must hold
in their head and blur identities that took a whole design pass to separate.

✅ **The one exception is a merge, not an addition:** Blind becomes an
accuracy debuff (above). That removes a system rather than adding one.

💡 **Flavour without new mechanics:** let gear *roll* these stats with
elemental affinity — Aero gear favours **dodge**, Geo **deflection**, Electro
**crit chance**, Pyro **crit damage**, Solar **accuracy**. The fantasy lands
and the rules stay where they are.

#### Spell accuracy — do not retrofit the shipped spells

⚠️ **Low accuracy on a high-charge spell is the worst feel in the game.**
Missing a Cataclysm after five turns of charging isn't tension, it's a
wasted session. So:

- ✅ **Every shipped spell stays at 100%.** Accuracy exists so that *dodge*
  has something to reduce, not to make current spells unreliable.
- 💡 If low-accuracy spells are wanted later, put them on **cheap, high-value
  gamblers** where a miss costs one turn — never on the 4–5 cost payoffs.
- ⭐ **The more interesting lever is accuracy above 100%**: a spell at 110%
  reads as *inevitable* and is the clean answer to a dodge build. Good fit
  for Cataclysm (the spell you saw coming and couldn't avoid) or the quick
  attacks.

📝 Precedence integration is specified in
[TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md) §5.2; gear modifiers in
[ITEMS_DESIGN.md](ITEMS_DESIGN.md) §4.

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
| Barrage | X | **one hit per charge spent**, each rolled separately (consumes all charge) |

### Lifesteal offensive (heal = **half** the damage dealt to enemy **health**, never shields)
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
- ✅ **Barrier** (2-charge): blocks 100% of all damage, destroyed after the first
  hit. ⭐ **It occupies its own slot**, so it stacks with an elemental shield
  instead of overwriting one you already paid for — the Barrier eats the next
  hit whole and the shield underneath is untouched, ready for the one after.
  A shield-ignoring attack (Phase) bypasses both.
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
- 📝 **Hallow** (1) — gain **Grace**: the next debuff applied to you is
  blocked outright (max 1, persists until consumed). Element-neutral. New in
  V2 — full spec in [TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md) §4c.4
- **Discharge** (2) — removes ALL of the opponent's charge, no damage (fizzles a
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
  spells** — 4 elements + 1 spell or 1 element + 4 spells are both legal splits.
  **5 slots at L1 → 15 at L50, +5 more from equipment (ceiling 20).** Presets must
  include ≥1 element and ≥1 offensive spell. Supersedes the old "3 element slots +
  5 spell slots" split. (Keybinds still support up to 8 elements / 10 spells, so no
  pool can be spent entirely on one kind.) Schedule in
  [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) §1. ⚠️ Level-gating the pool is
  intentionally the *last* thing implemented, so playtesting keeps everything.
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
| **Solar** ✅ | Sun Templar · Solar Archon · Prism Sentinel | **Solar Deity** |
| **Lunar** 📝 | Herald of the Waxing · Stalker of the New Moon · The Waning Wraith | **Luna Plena, the Full Moon** |
| **Astral** 📝 | Rift Walker · Constellation Warden · Echo of the Between | **The Zodiac Ascendant** |
| **Sanctus** 📝 | Vestal Warden · Reliquary Colossus · Seraph Judicant | **The Hierophant Eternal** |
| **Umbra** | Void Stalker · Umbral Knight · Eclipse Weaver | **Nightbringer** |
| **Arcane** | Spell Weaver · Mana Golem · Arcane Chimera | **Archmage** |

✅ **The Radiant roster went to Solar** (confirmed) — every name in it was
already solar imagery, and it would have read as a duplicate of Sanctus.

📝 **Lunar's roster teaches the mechanic.** The three mini-bosses *are* the
three non-peak moon phases (§TYPE_EFFECTS 4b.2), and the final boss is the
Full Moon itself — so a player learns the four-phase cycle by fighting it
before they ever cast it.
- 💡 **Hook worth building:** make **Luna Plena only fightable on a Full Moon
  turn** — or have the fight begin locked to a phase. The moon is the one
  piece of state the game already exposes publicly; a boss keyed to it costs
  nothing to implement and is instantly legible.

📝 **Sanctus's roster is deliberately temple/oath imagery, not light** —
vestals, reliquaries, hierophants, judgment. Sanctus is *consecration*;
Solar is *brightness*. If a Sanctus monster name could plausibly be a Solar
monster name, it is the wrong name.

📝 **Astral's roster is the space between things** — rifts, constellations,
echoes. Ties to Astral Alignment: these are creatures that are not entirely here.

💡 Note "Void Stalker" survives as a *monster* name even though **Void was
rejected as an element** (TYPE_EFFECTS_DESIGN §0) — no conflict, but worth
knowing it's not an element reference. Ditto "Eclipse Weaver," which now
rhymes with the Solar→Lunar eclipse mechanic by coincidence.

### World design session — 📝 IN PROGRESS (2026-07-25)

Working through towns, flow, gating and what brings a player back. **Nothing
here is built yet**; the map below is the previous draft and gets rebuilt from
whatever this section settles on.

#### 1. Structure — confirmed shape

✅ **Twelve pure zones, four groups of three, one group per tier.** Each pure
zone is the undiluted home of one element's bestiary and the best source of
its motes. That is the spine, and it is what makes "visit everywhere" a
mechanical need rather than a completionist urge (see §3 below).

✅ **The nine hybrid zones are optional** — never required, but worth going to.
Pure zones are the road; hybrids are the shoulder.

That only works if the perks are real, so they need designing rather than
assuming. Candidates, strongest first:

| Pull | Why it works |
|---|---|
| ⭐ **Two mote types from one zone** | A hybrid drops both its elements' motes, so it is the efficient stop when you need a pair — no other zone can offer that |
| ⭐ **The counter matchup is the reward** | A hybrid pairs elements on a counter edge, so it is where you *learn* a matchup safely before meeting it in PvP. Frame it as a proving ground, not a lecture |
| **Denser encounters** | More fights per run than a pure zone of the same level — the farming spot |
| **Hybrid-only materials** | Ice only exists where Aqua meets Aero; magma only where Pyro meets Geo. Recipes that want those must come here |
| **Better first-clear reward** | Optional content should pay *better* than required content for the same level, since it costs a detour |

⚠️ **The trap to avoid:** if hybrids pay strictly better than pure zones, the
"optional" content becomes mandatory in practice and the pure zones — the ones
the Attunement gate is built on — turn into a chore to rush. Hybrids should be
**better at something specific** (paired motes, hybrid materials, density),
not better at everything.

#### 2. Towns — and the capital

✅ **Nine towns — two per tier, plus a post-campaign ninth (§3b).** Six exist
in the current draft (Aldermere, Forgeholm, Galehaven, Rimeholt, Meridian,
Vespergate); **Pennycross**, **Concordance** and **Zenith** are new.

| Tier | Towns | When |
|---|---|---|
| **Primal** | 🏠 **Aldermere** *(home village)* · ⛲ **Pennycross** *(the first market)* | L1 · ~L8 |
| **Kinetic** | ⛏️ **Forgeholm** *(mining)* · ⚓ **Galehaven** *(port)* | ~L15 · ~L22 |
| **Celestial** | 🏛️ **Concordance** *(capital · gateway to Celestial)* · 🔭 **Meridian** *(observatory)* | ~L30 · ~L36 |
| **Ethereal** | 🏔️ **Rimeholt** *(the last mortal outpost, above the tree line)* · 🚪 **Vespergate** *(threshold fortress)* | ~L45 · ~L50 |

✅ **The capital opens at the mid-point — the Kinetic→Celestial boundary
(~L30).** Two full tiers behind you, two ahead; it is the literal middle of
the campaign and the moment the world stops being provincial.

- It is the **"act two begins"** beat, and the reward for finishing Kinetic.
- Celestial spokes off it, so it becomes your base for the back half rather
  than a place you pass through. Difficulty still scales with distance from
  home — the capital simply *becomes* home.
- Aldermere stays a humble village, which it should: opening in the capital
  would spend the game's biggest location on a player who cannot appreciate
  it.

✅ **What the capital is for** (this shapes the name):

- **The trade capital of the world**, and one of the only planned
  **player-to-player trading hubs**. Everywhere else you make things; here you
  exchange them.
- **Hour-long buffs** available from its districts — a real reason to route
  through before a long session. 📝 These are the real-time timed buffs
  ITEMS §6b.1 has as a TODO; the capital is their natural home and probably
  their first implementation.
- ⭐ **Still no crafting stations.** The six making-skills stay decentralised
  (§4 below) — the capital is where value *moves*, not where it is made.

✅ **The capital is CONCORDANCE.** An agreement *and* an index of a text — it
carries the trade-hub meaning and the scholarly one in a single word, without
shouting "wizards live here" the way Magisterium did. Runners-up, kept in case
it ever needs a second look: Thousandgate, Cynosure, Vellum, Wyrdholm.

⚠️ **Names ruled out:** *Arcanum*/*Arcanis* (read as the Arcane element's home
town), *Sanctum* (collides with Sanctus), *Caelum*/*Aether* (collide with the
Celestial and Ethereal tier names), *Magisterium* (too on-the-nose).

#### 3. Gating — two different problems, two different tools

The brief asked for gates that stop skipping *and* mechanisms that make people
want the content. Those are **not the same problem**, and conflating them is
how games end up with walls that annoy the prepared player.

⚠️ **A level gate stops you rushing ahead. It does nothing about skipping.**
A player who out-levels a zone can walk straight past it — level gates only
have a floor, never a ceiling.

**The hard gate — ⭐ Attunements.**

📝 **This is a new proposal, not something from the existing docs** — it was
invented in this session, which is why it won't be familiar. In one line:

> Each tier's road is sealed until you hold that tier's **Attunement**, a key
> item earned by defeating **all three of its pure-zone bosses**.

So to reach Celestial content you must have beaten the Electro, Aero and Geo
bosses — not merely reached level 30. It is the only mechanism here that makes
*breadth* mandatory; everything else in this section is a pull rather than a
wall.

✅ **Each tier's gate is its own object, and each teaches something different.**
Three collectables per tier, one from each pure-zone boss, on **first defeat
only** — but the *shape* of the lock changes as the world gets stranger:

| Tier | What you gather | The lock | What it teaches |
|---|---|---|---|
| **Primal** | Three ordinary **proofs** — an arbitrary set of trophies | A **guard** who wants to see them before letting you leave | The world is still mundane: a person, a request, a door |
| **Kinetic** | Three parts of a **Sigil** | Displayed to enter **Concordance** | Authority is now bureaucratic — you are showing papers, not fighting |
| **Celestial** | Three **essences** (Solar · Lunar · Astral) | Charge a **Celestial Totem**; the charged totem passes a **magical barrier** to Rimeholt | The world stops asking permission and starts asking power |
| **Ethereal** | Three **key fragments** | The **Eclipsed Citadel** itself | No gatekeeper left — only the door |

⭐ **Why the escalation is worth keeping exactly as written.** The gate is the
same mechanic four times (kill three bosses, assemble three things), but the
*fiction* moves from a guard, to a bureaucracy, to a barrier, to a lock with
nobody behind it. The player feels the world getting less human without a
single line of exposition. Keep the shapes distinct even if the underlying
rule is shared.

📝 **Deferred:** what the three Primal proofs actually are, and whether the
assembled objects are consumed or kept as trophies. The Totem in particular
wants to be keepable — a charged artifact is a better souvenir than a spent
one.

#### 3a. The endgame chain — Citadel → Crown → Zenith ⭐

✅ **This is the long tail, and it is deliberately enormous.**

1. **Beat the Eclipsed Citadel's final boss** (first clear) → it drops a
   **crown with twelve empty gem slots**.
2. **Collect twelve elemental gems**, one per element. ✅ Hybrid zones count,
   which is what finally makes them matter to a completionist.
3. **Collect twelve elemental Hearts**, one per element — the top of the mote
   ladder (ITEMS §6.0).
4. **Buy a binding spell** for a large sum of gold, and cast it to bind each
   essence to the crown using its Heart.
5. ✅ **Zenith opens.**

⭐ **What this structure gets right:** it is the only goal in the game that
requires *all twelve elements at once*. Every other system lets you
specialise; the crown does not care what you main. It is the perfect final ask
of a game whose whole identity is twelve elements in four tiers.

✅ **Twelve CORES, not twelve Hearts** — and Zenith stays a single, complete
achievement rather than opening in stages. The crown must be finished.

⚠️ **Why the step down matters.** Running the ITEMS §6.0 ladder backwards:

| Requirement | In Crystals | In Dust-equivalent | Direct drops needed |
|---|---|---|---|
| 12 **Hearts** *(rejected)* | 576 | 576,000 | ~48 Cores |
| ✅ 12 **Cores** | 144 | 144,000 | **12 Cores** |

That is a **quarter** of the ask, and — the part that actually matters — it
preserves the design: **one Core of each element** still means touring all
twelve zones. Nothing about the crown's "you must have met the whole world"
character is lost; only the grind is cut. Hearts also stay meaningful as the
top of the ladder rather than becoming a checklist item.

❓ **Still decide the Core drop rate against this number**, not independently:
twelve is now a *findable* target rather than an endurance test, so the rate
can be generous enough that the last element is a satisfying hunt rather than
a wall.

📝 **Crown name candidates:** ⭐ **The Concordant Crown** (it binds twelve
things into agreement, and quietly ties back to Concordance), **The Twelvefold
Crown** (plainest and clearest), **The Diadem of Ages**, **The Aetherwrought
Crown**.


This is the piece that actually prevents skipping, because it is keyed to
*breadth* rather than *level*. Combined with the existing element unlocks you
get a clean two-lock door:

| Lock | Stops | Earned by |
|---|---|---|
| **Level** (15/30/45) | rushing ahead under-levelled | XP |
| **Attunement** | skipping sideways past content | clearing all 3 pure zones of the tier |

It is also thematically exact: you attune to a *tier* of magic, which is
precisely what unlocking Celestial means.

**The soft pull — the mote economy already does this work.**

Enchanting needs **element-bound motes**, and each element's motes come best
from its own pure zone. A Pyro enchant therefore means a trip to Cinderpeak.
Twelve elements, twelve zones, and an endgame that wants all of them — that is
an organic reason to tour the whole map that never has to be enforced.

💡 Other pulls worth considering, cheapest first:
- **First-clear bonuses** — a one-time reward per zone, so completion is
  rewarded without punishing repetition.
- **Set components by boss** — spread the five archetypes' Tier III/IV
  components across different bosses so a full set requires a tour (ITEMS
  §3.5 already demands "rare components from difficult enemies"; this just
  says *which*).
- **Bestiary/codex completion** — a passive per element mastered.

⚠️ **One thing to watch:** attunements make the *first* playthrough linear by
design. That is right for a campaign, but if alt characters or seasons ever
happen, they need a way to inherit or fast-track attunements or the second
run-through will feel like a chore.

#### 3d. The shape of a zone — ✅ three sections

✅ **Every zone runs in three parts:**

| Section | Contents |
|---|---|
| **1** | 4–5 enemies → **mini-boss** |
| **2** | 4–5 enemies → **mini-boss** |
| **3** | a few more enemies → **final boss** |

✅ **Sizes grow with the game** — the first few zones run lean, and the count
climbs toward the late game, so a Primal route is a short outing and an
Ethereal one is an expedition.

✅ **Each zone keeps a POOL, and a run draws from it.** Not a fixed roster —
**3–5 mini-bosses and 1–2 bosses** exist per zone, and every run rolls a
random combination. Two mini-bosses and one boss appear; which ones is a
surprise.

⭐ **This is what makes a zone worth running twice.** A fixed roster is
memorised after one clear and every later visit is the same fight. A pool
means the counter-pick you brought might be the wrong one, which keeps a zone
tense long after its level band has been outgrown — and that matters a great
deal here, because the resource areas (§4b) are a standing reason to come
back.

📝 **Consequences to carry forward:**

1. ⚠️ **The bestiary needs to GROW, not shrink.** It currently lists three
   mini-bosses and one boss per element; the pool wants **3–5 and 1–2**. That
   is up to twelve more mini-bosses and twelve more bosses to design, and it
   is the single largest content task the enemies pass now carries.
2. ✅ **Three sections means three resource areas** — one at each mini-boss and
   one at the boss (§4b). A natural gathering ramp: the deeper you push in a
   run, the richer the ground.
3. ❓ **Does the pool reroll per run or per day?** Per run is more surprising;
   per day lets a player plan a loadout around what is up, which suits a game
   built on counter-picking.

#### 4. What makes a town worth returning to

⭐ **Decentralise crafting.** The strongest available lever: make each town the
**only** place one skill can be practised, so travel stays meaningful after
the levelling is done.

✅ **The thematic fit, one skill per town** — six making-skills across eight
towns, leaving two deliberately civic:

| Town | Tier | Station | Why there |
|---|---|---|---|
| 🏠 **Aldermere** | Primal | **Woodcarving** | The woods are its whole geography, and a stave is the first weapon a new mage cuts |
| ⛲ **Pennycross** | Primal | — *(first market)* | Teaches buying and selling before Concordance turns trade into a system |
| ⛏️ **Forgeholm** | Kinetic | **Metalworking** | It is the mining town; ore is refined where it comes out of the ground |
| ⚓ **Galehaven** | Kinetic | **Tailoring** | A port is where cloth and dye arrive from elsewhere — robes are a trade good, not a local one |
| 🏛️ **Concordance** | Celestial | — *(trade + buffs)* | Value **moves** here; it is not made here |
| 🔭 **Meridian** | Celestial | **Enchanting** | An observatory is where you *study*, and enchanting is the only skill that works on motes rather than matter |
| 🏔️ **Rimeholt** | Ethereal | **Jewelry** | The deep stone is where gems come from, and the last outpost is where they get cut |
| 🚪 **Vespergate** | Ethereal | **Potions / Alchemy** | A threshold fortress that cannot resupply from behind has to brew its own |

⭐ **Why this arrangement and not another.** Three principles, in order:

1. **The skill lives where its raw material comes from.** Woodcarving in the
   woods, Metalworking at the mine, Jewelry in the deep stone. The exception
   proves it — **Tailoring sits in the port**, because cloth is the one
   material you *import* rather than dig up.
2. **The two skills with no physical material go late.** Enchanting works on
   motes and Alchemy on essences, so both belong in the back half where the
   player has motes to spend and reagents worth brewing.
3. ⭐ **The difficulty curve of the craft matches the difficulty curve of the
   road.** A player meets Woodcarving at level 1 and Alchemy at level 50, so
   the crafting tree unfolds at the same pace as the world — no town ever
   offers a skill the player has no use for yet.

📝 Gathering skills sit alongside naturally: **Felling** around Aldermere,
**Mining** around Forgeholm and Rimeholt, **Foraging** around Galehaven and
Vespergate.

⭐ **And give the capital no crafting stations at all.** The instinct is to put
everything in the capital; that would kill the other six towns overnight.
Instead the capital owns what nowhere else can: **the bank, the ✅ CONCORD
MARKET, contracts, and the PvP + Academy entrances**. You bank in the capital
and you *make things* out in the world.

**Advanced nodes as previews** (the brief's own idea, and a good one):

> Place a resource node near each town that is **far above your current skill**,
> visible and clearly labelled — *"Adamant Vein · requires Mining 40"*.

⭐ Sharpen it: put the node for a **later tier's material next to an earlier
tier's town**. You walk past the Adamant Vein outside Aldermere at level 6 and
finally crack it at level 40 — which drags you back to the starting village at
the endgame. That single trick makes every town permanently relevant and costs
nothing but placement.

⚠️ **Blocked on a contradiction in ITEMS_DESIGN.** §6.1 says *"Motes also drop
from gathering — a Pyro-attuned vein yields Pyro Dust alongside its ore"*,
while §6a says *"Motes come from combat, not gathering (§6.1)"* — and cites
§6.1 for the opposite of what §6.1 says. ❓ **Which is it?** It decides whether
advanced nodes are a *gathering* reward or an *enchanting* one, and therefore
whether a pure crafter can reach the ceiling without fighting.

#### 3c. The Eclipsed Citadel — ✅ required, all twelve, and scalable

✅ **No longer optional.** Zenith sits behind it, so it is the campaign's
capstone rather than a dashed side-zone.

✅ **A hybrid of every element.** Not two elements like the other hybrids —
**all twelve**, and incredibly difficult.

⭐ **This is the single best possible final exam, and the reason is
mechanical.** Under the §0.3 shield table, every attack lands somewhere
between ½× and 2× depending on the matchup. Against a twelve-element dungeon
**no loadout counters everything** — five element slots against twelve enemy
elements means you will always be at ½× against something. The Citadel
therefore tests the one thing nothing else can: whether you can *adapt* rather
than *specialise*. Every other zone rewards a plan; this one punishes only
having one.

✅ **Difficulty scaling.** The Citadel starts at **100%** and can be pushed
higher and higher — an endless ladder rather than a fixed wall.

📝 **What should actually scale** (proposal, needs a ruling):

| Scale | Don't scale |
|---|---|
| Enemy **HP** and **damage** | Enemy **level** — it feeds the shield/counter maths and the numbers stop being readable |
| Enemy **count per section** | The **element roster** — twelve is already all of them |
| **Reward quality**: drop rates, mote tier, gold | The **rules** — a percentage that changes mechanics is a different mode, not a difficulty |

⚠️ **The ceiling to watch.** Scaling damage indefinitely eventually reaches
"the player never gets a second turn," which is the same failure the design
already rejected for permanent Waterlogged and 0% hit chance. A difficulty
ladder should make fights *longer and sharper*, not *shorter and decided on
turn one*. ❓ Worth deciding whether there is a hard cap, or whether the curve
simply flattens.

❓ **Open:** does pushing higher persist as a personal best (a score to beat),
or does each threshold unlock permanently the way a raid difficulty does?
Persistent unlocks are friendlier; personal bests give leaderboards something
to hold.

#### 3b. The ninth town — ✅ **ZENITH** ⭐

✅ **A ninth town sits past the end of the campaign**, reached only by
defeating **The Eclipsed Citadel**. Everything the tier ladder and the
key-fragment gates have been building toward.

✅ **It has everything, on purpose:**

| It holds | Note |
|---|---|
| ⭐ **Every crafting station** | All six making-skills in one place — the only town that has them all |
| ⭐ **Teleports to every other city** | The map folds up once you have earned it |
| ⭐ **The Concord Market** | ✅ **The same market as Concordance**, reached from a second door — *not* a second market, and it keeps the same name. **10% tax on every sale** (below) |
| The unbinding enchant (ITEMS §6c) | The most consequential thing the economy allows |
| Post-cap XP → motes (10 XP = 1 Dust, 250/day) | It only exists at level 50; its home should be a place only level-50s stand in |
| Tier IV set assembly · the hardest repeatable content | Where the loop keeps going once the story stops |

⭐ **One market, two doors — this is the detail that matters.** ✅ It is the
**Concord Market** from both, and everything else in the world is a *shop* or a
*store*, never a market. A second, separate marketplace would split liquidity: fewer listings in each, worse
prices, and a player never sure which door to try. Because Concordance and the
Zenith are **access points onto one shared order book**, the endgame town
adds convenience without fragmenting the economy. Worth stating explicitly in
the build, because "add a market to the new town" is exactly the kind of thing
that gets implemented as a second table by accident.

📝 **What this means for the other eight towns — a deliberate trade, not an
oversight.** The one-craft-per-town rule (§4) is a **mid-game structure that
dissolves at endgame**, and that is fine:

- Crafting exclusivity exists to make the *world* feel worth crossing while
  you are learning it. Once the campaign is done, that lesson has landed, and
  making a level-50 player sail to Galehaven for every robe is friction
  without purpose.
- The towns keep the reason that outlasts convenience: **they are next to
  their zones and their resource nodes.** You still go to Rimeholt to mine —
  you simply teleport back to craft. The gathering loop is untouched.
- ⚠️ The thing to watch is not the towns, it's **whether the mid-game ever
  felt tedious rather than characterful.** If players resent the travel *while
  it is happening*, the endgame teleport is a bandage over a design problem
  rather than a reward. Worth asking directly in playtesting.

✅ **The ninth town is ZENITH.** The highest point of the sky's arc — and
⭐ **it begins with Z, the last letter, for the last city.** A quiet piece of
symmetry that costs nothing and rewards anyone who notices. It also rhymes
with **Meridian**: both are astronomical terms, so the two most advanced towns
in the world read as a matched pair.

📝 "Super Capital" is retired as a working title — Concordance is the
*capital*; Zenith is the summit. Runners-up, kept only in case Zenith ever
needs replacing: Thousandgate, The Convergence, Axis Mundi, Cor Mundi, The
Firmament, Omphalos, Everdawn, Wayscross, Ultima.

⚠️ **Do not rename Zenith casually.** The Z-for-last-city symmetry is
deliberate; a rename loses something the docs would not otherwise record.

⚠️ **A structural consequence worth naming.** The Eclipsed Citadel is currently
the **final dungeon** *and* a hybrid zone (Arcane + Sanctus), which the map
marks optional. It cannot be both: if Zenith is behind it, the Citadel
is **required**, and should be drawn as the campaign's capstone rather than one
more dashed side-zone. ❓ Confirm — or gate the hub behind something else and
let the Citadel stay optional.

#### 4b. Boss-gated resource areas — ⭐ and the "free levels" problem

✅ **Every mini-boss and boss arena also holds a resource area.** You can work
an ordinary node out in the zone, or you can kill what guards the good ground
and gather far more in the same time. ✅ **Hybrid zones are harder and richer**
on the same principle — some deliberately hard enough that you leave and come
back later.

⚠️ **The danger the brief already named: this must not hand out gathering
levels for free.** Left naive, a strong fighter would out-level a dedicated
gatherer by punching bosses, and the whole gathering skill line becomes a
formality.

⭐ **The fix — split what each system pays out:**

> A boss-gated node yields **more material per action**, but the **same skill
> XP per action** as an ordinary node.

So combat prowess buys you **stuff**; the gathering skill still buys you
**levels**. A fighter who clears a boss arena fills their bags faster, and
gains not one point of Mining for it. Two more guards on the same idea:

- ✅ **The node still checks the gathering skill.** Beating the boss grants
  *access*, never *capability* — an Adamant Vein behind a level-40 boss is
  still unworkable at Mining 10, so nobody skips the skill line by fighting.
- ✅ **First clear opens it; the area stays open.** The attunement fragments
  (§3) are one-time, but the resource area is the repeatable reason to return
  — that is the whole point of putting it there.
- ❓ **Open:** does the boss need re-killing each visit, or does one clear open
  the ground permanently? Permanent is friendlier and makes the arena a
  genuine destination; re-killing keeps the challenge but risks becoming a toll
  players resent.

#### 5. Settled this session

| Decision | |
|---|---|
| Hybrid zones are **optional**, pulled by paired motes, hybrid-only materials and density — never required | ✅ |
| **Eight towns, two per tier** | ✅ |
| The capital opens at the **mid-point** (Kinetic→Celestial, ~L30) | ✅ |
| The capital is the **trade hub** with **hour-long buffs**, and has **no crafting stations** | ✅ |
| Motes drop from **combat and gathering** — steady from the first, random drops/events from the second (ITEMS §6.1 corrected) | ✅ |

#### 6. ✅ The map is settled — what's left is content and tuning

Every question this session opened about **geography, names, gates and the
economy** is answered. ✅ Concordance · Pennycross · Zenith · the four-object
gate chain · hybrids optional · nine towns · boss-gated resource areas · the
10% split tax.

📝 **Five things remain open, and all five are deliberately deferred** — they
are content to author or numbers to tune, not decisions that block building the
map:

| Deferred | Belongs to |
|---|---|
| The three Primal **"proofs"** — arbitrary trophies, but arbitrary still needs choosing, and they are the first collectables a player ever sees | the enemies/loot pass |
| Whether the assembled **gate objects are consumed or kept** *(the Celestial Totem especially wants to be keepable — a charged artifact is a better souvenir than a spent one)* | the loot pass |
| The **Core drop rate**, decided *against* the crown's twelve-Core requirement rather than independently | the loot tables |
| What **Concordance's hour-long buffs** do — ✅ confirmed TBD. Also needs the persistent real-time buff machinery ITEMS §6b.1 flags as unbuilt | items/potions |
| The **crown's name** — The Concordant Crown, The Twelvefold Crown, or another | naming, any time |

⚠️ **One item is a task rather than a question, and it is large:** the bestiary
needs to **grow** to pools of 3–5 mini-bosses and 1–2 bosses per zone, against
the three-and-one it lists today. Up to twelve more mini-bosses and twelve more
bosses. That is the biggest single content job the enemies pass now carries.

#### 6b. Difficulty levers that aren't damage and health ⭐

The Citadel's scaling threshold (§3c) needs to mean something more interesting
than multiplying enemy HP. Two levers, both orthogonal to stats:

**1 · 📝 Tempo — TABLED for now.**

Shortening the move clock (10s → 5s → 2–3s) is designed in TYPE_EFFECTS §4d and
**deliberately parked**. Recorded here because it is the clearest example of
the category: a difficulty knob that changes *how the fight feels* rather than
how long it takes. It carries unresolved netcode and accessibility questions,
so it waits — but it stays on the shelf as something to reach for.

**2 · ⭐ Intelligence — a 1–10 capability ladder.**

Not a single "accuracy of play" dial but a **ladder of competences**, each
level adding a specific thing the brain can now do. That matters: a dial only
makes an opponent better or worse at the same game, while a ladder makes each
step a *qualitatively different* opponent.

| Lvl | It can… | New capability |
|---|---|---|
| **1** | Any legal move, uniformly | ⭐ **Random.** Unpredictable *and* incompetent — burns a 5-charge cycle on a Flick. Measurably the weakest thing on the ladder (~3.0 dmg/turn) |
| **2** | Repeat one cheap attack forever | One habit. Fully readable, cannot punish anything — what a new player should meet first |
| **3** | Charge to a fixed number, then spend it | Uses the charge system on a rhythm anyone can read (~7.1 dmg/turn) |
| **4** | Play sensibly, and **shield when threatened** | Stops wasting charge. ⭐ Shielding is core play, not an advanced tactic |
| **5** | Read the enemy shield's element | ⭐ **Counter-aware.** Picks the *element* that beats the wall — ranking spells cannot do it, since one element's spells all scale alike |
| **6** | Take a guaranteed kill | Never misses lethal |
| **7** | See statuses | ⚠️ Counts damage already on the clock, and won't swing while Blinded |
| **8** | Plan toward a payoff | Patience — holds for the cast that lands instead of poking on a rhythm |
| **9** | Infer the enemy's action from charge | ⭐ **Predictive**, and the strongest single competence measured |
| **10** | Everything 9 does, perfectly | **Never blunders** |

✅ **Two things carry difficulty, not one.**

1. **Competences** (the table) make each rung a *qualitatively different*
   opponent.
2. ⭐ **A blunder rate** — a flat chance each turn of throwing the move away and
   playing at random — falls as the ladder rises: 32% at level 2 down to **0% at
   level 10**.

⚠️ **The second is what makes it a usable dial.** With competences alone, levels
6–9 sat within *two points* of each other in simulation: real differences in
character, useless as a difficulty setting. With the blunder gradient the scale
fans out properly — measured against a level-5 baseline over 7 000 duels per
pair, five seeds, both seats, on realistic ~5-element/~10-spell loadouts:

| vs level 5 | 1 | 2 | 3 | 4 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|
| win % | 12.5 | 23.8 | 43.1 | 41.3 | 66.5 | 68.8 | 72.7 | 77.3 | 79.7 |

✅ **Every adjacent rung now beats the one below it**, guarded by
`packages/mom_engine/test/ladder_ai_test.dart`.

⚠️ **Levels 1–3 are ordered by weakness, not by sophistication.** The first draft
of this table had them the other way round — flick-forever at 1, random at 3 —
which ran the bottom of the dial backwards, because a beginner who has unlocked
the whole action space and has no judgement plays *worse* than one with a single
narrow habit.

⚠️ **The AI does not cheat.** Umbra's Creeping Dark hides the enemy's charging
element (Shadow) and their charge and health (Dusk). The brain reads an
`EnemyView`, not the raw state, so a hidden health bar really does deny it the
lethal — otherwise Umbra's whole identity would work against humans and nobody
else.

📝 **Superseded: level 10 was going to play a mixed strategy.** The reasoning
was that in a simultaneous-turn game a deterministic "optimal" is exploitable —
whatever it always plays, a human learns and counters. That is still true, but
mixing spell choice and cash-out timing is *deliberately suboptimal in
isolation*, and it only pays against an opponent that learns patterns. Nothing
in a simulation does, so level 10 was paying a real cost to collect nothing and
measured **worse** than level 9. A perfect executor is the cleaner definition.

💡 **Banked:** to make a mixed strategy provably better, the harness needs an
*exploiter* opponent that records what you did in each state and pre-counters
it. Worth building before ever revisiting this.

⭐ **And this ladder is also the fix for the balance sim's known blind spot.**
Every sim run so far has carried the same caveat — the AI is effect-blind, so
it under-represents strategic archetypes. **Levels 5, 8 and 9 are precisely
the missing competences**: counter-picking, status awareness, and resource
planning. Building the ladder does double duty, giving the Phase 4 sim gate an
opponent capable of actually playing Lunar timing, Sanctus streaks, Grace and
dodge builds. Right now it cannot, which is why Flora's numbers have never been
trustworthy.

📝 **Notes for the enemies pass:**
- ✅ **Intelligence is orthogonal to stats.** A frail level-9 caster is a
  completely different threat from a level-1 tank with triple HP — which is
  exactly the difficulty-that-isn't-numbers this section is for.
- ✅ **`AiRoster` personas now build a `LadderAi` from their rating alone**, so
  intelligence is a separate entity from the character: the persona supplies the
  body (level, loadout, look) and the rating supplies the mind. The same loadout
  at 3 and at 9 is two genuinely different opponents.
- ❓ **Where does a boss sit?** A tier boss at intelligence 9–10 with modest
  stats might be a better fight than one at 5 with inflated ones. Worth
  playtesting both, since it is the whole thesis of this section.

#### 7. Economy rulings from this session

✅ **Player trading is taxed at 10%, split evenly across both sides.**

> An item **listed at 100g**: the **buyer pays 105g**, the **seller receives
> 95g**. The 10g in between is **deleted**.

✅ **The gold is destroyed, not redistributed.** A tax that recirculates is not
a sink — it just moves inflation somewhere else.

✅ **The rate is configurable**, so it can be tuned once there is a real
economy to observe rather than guessed at now.

⭐ **Why the split beats a one-sided fee.** A seller-only fee makes the listed
price honest for the buyer but quietly lies to the seller; a buyer-only fee
does the reverse. Splitting it means the listed price is **the midpoint both
sides negotiate around**, and each party can see exactly what the market costs
them. It also makes the spread visible, which is the honest way to show a
player that trading has a price.

⚠️ **The one thing this must get right is the UI.** With a split fee, the
number on the listing is what *neither* party actually pays. Both figures have
to be on screen at the point of action — "you pay 105g" on the buy button,
"you receive 95g" on the list form. Showing only the listing price would be
the most confusing possible presentation of a perfectly fair rule.

📝 **Still worth watching:** 10% is a meaningful drag on cheap trades — a 20g
item nets 19g and costs 21g. If small trades dry up in practice, a flat
minimum fee at the bottom end (rather than the percentage) would let the tax
bite the large trades it is aimed at while leaving pocket-change trading alive.
Configurability makes that a tuning change rather than a rewrite.

---

### World map — 📝 DRAFT v2: 12 pure zones + 10 hybrids

> ⚠️ **Superseded on physical geography.**
> [WORLD_DESIGN.md](WORLD_DESIGN.md) now owns *where* everything is, the two
> planes, the altitude structure, and the player-facing text for every place.
> **This section remains authoritative for the logical map only** — which
> elements pair with which, level bands, and counter-edge coverage.
>
> Changes settled there that contradict the tables below: the Ethereal tier is
> one massif (**The Vault**) rather than a polar plain; the three **Arcane**
> places sit above the veil in **The Empyrean**; **Zenith** is the sealed summit,
> entered from above through the Citadel; **Tidewrack Shoals** is reached by sea
> from Galehaven. Corrected the header count from 9 hybrids to 10 — the tables
> below always listed ten.

Rebuilt for the twelve-element roster. **Twelve pure zones — one per element**
— each the undiluted home of that element's bestiary and its best mote drop
rate; plus **nine hybrid zones**, one per tier boundary and one per
within-tier counter edge.

✅ **Design rules the map follows:**
1. **Every hybrid zone pairs two elements that are on a counter edge**, so
   the zone itself teaches the matchup. A player who brings only Pyro into
   Ashfall Vale meets the Flora it beats *and* the Aqua that beats it.
2. **Pure zone before hybrid zone, in every tier.** You learn an element
   alone before you meet it mixed.
3. **Level bands track the tier unlocks** — Primal 1–14, Kinetic 15–29,
   Celestial 30–44, Ethereal 45–50+.
4. **The tier's unlock town sits at the mouth of that tier's first zone**, so
   the unlock and the content arrive in the same breath.
5. ✅ **Ice is Aqua + Aero** (confirmed) — a hybrid *look*, not a thirteenth
   element. The same trick carries every other classic that isn't on the
   roster: magma is Pyro + Geo, storms are Electro + Aero, jungle is Flora +
   Geo.

#### Ring 0–1 · Primal · **L1–14**

| Region | Type | Elements | Lv |
|---|---|---|---|
| **Aldermere** | 🏠 home town | — | — |
| **Whispering Woods** | pure | Flora | 1–5 |
| **Glimmerbrook** | pure | Aqua | 3–8 |
| **Cinderpeak Foothills** | pure | Pyro | 6–11 |
| **Thornmire** | hybrid — *drowned swamp* | Flora + Aqua *(Flora ▸ Aqua)* | 8–13 |
| **Ashfall Vale** | hybrid — *wildfire* | Pyro + Flora *(Pyro ▸ Flora)* | 10–14 |
| **Forgeholm** | ⛏️ mining town — **unlocks Kinetic (L15)** | — | — |

#### Ring 2 · Kinetic · **L15–29**

| Region | Type | Elements | Lv |
|---|---|---|---|
| **Old Quarry** | pure | Geo | 15–19 |
| **Stormcliff Coast** | pure | Electro | 17–22 |
| **Windward Steppe** | pure | Aero | 19–24 |
| **Galehaven** | ⚓ port town | — | — |
| **Frostfell Pass** | hybrid — ❄️ **ice** | Aqua + Aero | 21–26 |
| **Thunderspire Peaks** | hybrid — *storm* | Electro + Aero *(Electro ▸ Aero)* | 23–28 |
| **The Molten Deep** | hybrid — *magma* | Pyro + Geo *(cross-tier)* | 25–29 |
| **Rimeholt** | 🏔️ mountain village — **unlocks Celestial (L30)** | — | — |

#### Ring 3 · Celestial · **L30–44**

| Region | Type | Elements | Lv |
|---|---|---|---|
| **The Kiln Desert** | pure | Solar | 30–34 |
| **The Mirrormere** | pure — *the moon's reflection on a still lake* | Lunar | 32–37 |
| **Starfall Basin** | pure — *a crater field of fallen stars* | Astral | 34–39 |
| **Meridian** | 🔭 observatory town | — | — |
| **Tidewrack Shoals** | hybrid — *tides that obey the moon* | Lunar + Aqua | 36–40 |
| **The Sunless Reach** | hybrid — *where day never comes* | Solar + Lunar *(Solar ▸ Lunar)* | 38–42 |
| **The Shattered Orrery** | hybrid — *a broken model of the heavens* | Astral + Electro | 40–44 |
| **Vespergate** | 🚪 threshold town — **unlocks Ethereal (L45)** | — | — |

#### Ring 4 · Ethereal · **L45–60** ✅ *enemies out-level you; gear closes the gap*

| Region | Type | Elements | Enemy Lv |
|---|---|---|---|
| **Hallowmarch** | pure — *a consecrated causeway* | Sanctus | 45–49 |
| **The Umbral Wastes** | pure | Umbra | 47–51 |
| **The Collapsed Academy** | pure — *a school that read too far* | Arcane | 50–54 |
| **The Reliquary Deep** | hybrid — *sanctity buried in the dark* | Sanctus + Umbra *(Sanctus ▸ Umbra)* | 52–56 |
| **The Unwritten Library** | hybrid — *knowledge that eats its keeper* | Umbra + Arcane *(Umbra ▸ Arcane)* | 54–58 |
| **The Eclipsed Citadel** | 🏰 **final dungeon** | Arcane + Sanctus *(Arcane ▸ Sanctus)* | 58–60 |

✅ **The Ethereal band runs to enemy level 60 while the player cap stays at
50.** The last three zones are deliberately **above your level** — you close
a gap of up to **ten levels with equipment**, not with XP. This solves the
five-level squeeze (Tier 4 would otherwise have had to fit into L45–50 while
Primal got fourteen levels) without raising the cap or pulling the Ethereal
unlock earlier, which would reopen the L30–44 gap (TYPE_EFFECTS §0.4) from
the other side.

Consequences worth being deliberate about:

- ⭐ **It quantifies the gear power budget.** [ITEMS_DESIGN.md](ITEMS_DESIGN.md)
  already asserts that full best-in-slot beats fully naked ≈ 100% of the
  time; this pins a number to it — **gear must be worth about ten levels**.
  The two documents now constrain each other, which is exactly what you want
  from an endgame curve. Sim against it.
- ✅ **Difficulty becomes gear-driven, not XP-driven, past 50.** That is the
  intended endgame loop: the Tier III/IV set chase *is* the progression.
- ✅ **Post-cap XP converts to motes** — **10 XP → 1 Dust, capped at 250 Dust
  per day**, as a daily-play hook. Sizing and caveats in
  [ITEMS_DESIGN.md](ITEMS_DESIGN.md) §6.1; it's a trickle, not a path.
- ✅ **Enemy HP and damage are set per-monster, not by a global per-level
  constant.** Two monsters of the same level can differ sharply — some tanky,
  some damage-heavy. That's the better design; it's what makes a zone's
  roster feel varied rather than reskinned.
  ⚠️ **But without a single constant there is no automatic difficulty
  curve.** The enemies pass (IMPLEMENTATION_PLAN Phase 6) therefore needs a
  **baseline statline per level** that archetypes deviate *from* — tank
  +HP/−damage, glass −HP/+damage, comparable totals. Otherwise "gear is worth
  about ten levels" has nothing to be measured against, and the L45–60 band
  can be neither tuned nor simmed.
- ⚠️ **The level shown on a zone is now the *enemy* level, not a
  requirement.** The UI has to make that unmistakable, or players will read
  "58–60" as "come back when you're 58" and never return — the same
  legibility lesson as the move timer and Midnight.

📝 **Counter-edge coverage.** Of the twelve within-tier counter edges, the
map teaches **seven** through hybrid zones:

| Tier | Edges taught | Edges untaught |
|---|---|---|
| Primal | Pyro ▸ Flora, Flora ▸ Aqua | Aqua ▸ Pyro |
| Kinetic | Electro ▸ Aero | Aero ▸ Geo, Geo ▸ Electro |
| Celestial | Solar ▸ Lunar | Lunar ▸ Astral, Astral ▸ Solar |
| **Ethereal** | **all three** ✅ | — |

The remaining four hybrids (Frostfell, Molten Deep, Tidewrack, Shattered
Orrery) are *cross-tier or neutral* pairings that exist for flavour and for
the macro-tier loop rather than for a counter edge. ✅ **Accepted as-is** —
the five untaught edges get learned in duels rather than in the world, and
more zones can be added later if that proves to be a gap. Ethereal being
fully closed is deliberate — the endgame tier is
where the counter game has to be second nature.

**Old draft (superseded, kept for names only):**

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
8. **Time Crystals** — a consumable that instantly **skips time-gated
   processes** (travel, crafting, researching/studying). ✅ They are **crafted
   from RESONANCE PRISMS ("RP")**, the premium currency — not bought directly
   and not the same thing as it. ✅ RP is the renamed "gems" currency; the word
   *gem* now means a socketed stone only (ITEMS §6d).
9. **Timed travel** — ✅ **promoted out of the idea bank**; designed in
   [WORLD_DESIGN.md](WORLD_DESIGN.md) §4b. Real time, ~5 min per leg, mounts as
   speed multipliers, Travel vs Journey modes, skippable with [8] Time Crystals.
   ⚠️ The "~10–15s early legs scaling to hours" sketch here is **superseded** —
   minutes, not seconds, and never hours.
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
- ✅ Loadout caps: **one shared pool** (§4 — 5 at L1 → 15 at L50, ceiling 20), with
  per-kind keybind limits of 8 elements / 10 spells; **all spells unlocked** and the
  pool un-gated for now; old saves auto-clamped on load. (Superseded the earlier
  "3 element + 5 spell slots", then "5 + 10", splits.)
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
10. ✅ **CLOSED** — the premium currency is **Resonance Prisms ("RP")**, renamed
    off "gems" so that *gem* means a socketed stone only (ITEMS §6d). Time
    Crystals are crafted *from* RP and are a separate thing. (Idea bank #8)
