# Masters of Magic 2 — Enemies

Status: 📝 **draft.** Started 2026-08-02. This is the Phase 6 design
deliverable named in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

Content tracking — which zone has what, and what is still missing — lives in
[CONTENT_CHECKLIST.md](CONTENT_CHECKLIST.md).

---

## 1. The archetype model ✅ (the core decision)

✅ **Ruling: enemies are ARCHETYPES reskinned per creature, not bespoke
designs.** An enemy is:

> **archetype** (stat coefficients + brain) **× element** (from its zone)
> **× level** (from its zone's band) **+ a creature** (name, move set, art)

⚠️ **The archetype does NOT supply the moves** — see §3. A Bruiser boar and a
Bruiser drake share a stat profile and a rhythm, not a move list.

⭐ **Why this is not a shortcut.** The element passives already exist and
already differ enormously — Ignite burns, Photosynthesis heals, Waterlogged
slows, Static Feedback strips charge. So the *same* archetype fights
genuinely differently in each zone **for free**: a Pyro Bruiser is a race
against a burn, an Aqua Bruiser is a fight where you never act first. The
variety players feel comes from the element layer, which is already built and
already tested.

⭐ **And it decides the code shape.** With archetypes, the bestiary is a
**function**, not a table:

```
statline(archetype, element, level) -> MageState
```

~150 lines of Dart for the whole Primal quarter instead of a spreadsheet of
100+ hand-written records, and it stays testable with the same drift-guard
pattern the rest of the project uses.

### 1.1 The baseline already exists ⭐

⚠️ Phase 6 flags "a baseline statline per level" as the thing that makes the
curve tunable. **It is already in the engine.** `MageState(level: n)` gives
`100 × 1.04^(n-1)` max HP and the same multiplier on outgoing damage
(`ElementTuning.percentPerLevel`, geometric).

> ✅ **Baseline = a player-equivalent mage of that level. An archetype is a
> multiplier on it.** A 1.0×/1.0× enemy is an exactly even fight.

That means no second curve to invent, no second curve to drift. It also means
"gear is worth ten levels" has something concrete to be measured against
(ITEMS §9b.4a).

### 1.2 Where the data lives ✅

✅ **Archetype definitions live in code**, as `const` data beside `world.dart`
and `spellbook.dart`. Reasons in order of weight:

1. ⚠️ **Determinism.** Duels are lockstep commit-reveal. Anything a duel
   resolves against must be identical on both clients; server-loaded data adds
   a second way for two clients to disagree, timed by whenever each last
   refreshed. ⛔ See the **content-version handshake** to-do in
   IMPLEMENTATION_PLAN — matchmaking currently compares no version at all.
2. **Testability.** The project's strongest quality pattern is drift-guard
   tests comparing data to player-facing text. Those cannot exist against
   server data.
3. **Type safety.** A typo'd element is a compile error, not a missing drop.

📝 **The exception — tuning knobs may be server-side:** drop *rates*, shop
prices, node timers, XP/gold multipliers. These are what you will want to
change after watching people play, none of them touch duel determinism, and
hardcoding them means an **app-store review per tune** once iOS/Android ship.
One `config/tuning` document, with the in-code values as fallback so the game
works offline.

🚫 **Not JSON/YAML assets.** Gives up type safety *and* compile-time tests
without buying live tuning — the worst of both. (Also: the project has no
asset pipeline at all, deliberately.)

---

## 2. The sixteen archetypes ✅

Coefficients multiply the level baseline (§1.1). **Intelligence** is the
existing 1–10 `LadderAi` rung, which already carries its own blunder rate — so
"this one plays badly" is a dial, not new code.

⭐ **Read the "product" column as the fight's total weight.** Within a tier
the products cluster, so archetypes trade HP against damage rather than being
strictly better or worse. Where a product sits high, a *behavioural* cost pays
for it (Bruiser telegraphs; Juggernaut is slow).

### 2.1 Common — the eight you meet constantly

| # | Archetype | HP× | DMG× | Product | Int | Behaviour — what makes it feel different |
|---|---|---|---|---|---|
| 1 | **Drudge** | 0.80 | 0.70 | 0.56 | 1–2 | Barely fights. Charges aimlessly, flicks. ⭐ The level 1–3 teaching dummy — it exists so a new player can lose *nothing* while learning the charge/cast loop |
| 2 | **Skirmisher** | 0.70 | 1.15 | 0.81 | 3–4 | Quick spells only (priority 5). Never charges past 2. Teaches **priority** — it acts before you and you must plan around that |
| 3 | **Lasher** | 0.85 | 1.00 | 0.85 | 3–4 | Multi-hit spells (Flurry/Volley). Damage arrives in pieces, so shields chip rather than shatter. Teaches **why a big shield is not always the answer** |
| 4 | **Glasswing** | 0.50 | 1.70 | 0.85 | 3–5 | Terrifying and made of paper. A race. Teaches **killing fast beats playing safe** |
| 5 | **Adept** | 1.00 | 0.90 | 0.90 | 5–6 | Plays a straight, competent game — charges sensibly, shields when hurt. ⭐ The honest mirror-match; the yardstick every other archetype is felt against |
| 6 | **Sentinel** | 1.25 | 0.70 | 0.88 | 4–5 | Shields constantly. Low damage, long fight. Teaches **shield-breaking** and makes Barrage feel good |
| 7 | **Bruiser** | 1.15 | 1.10 | 1.27 | 3–4 | Charges to 4–5 and swings heavy. ⚠️ Product is high *on purpose* — it is paid for by being **completely telegraphed**. Teaches reading the charge bar |
| 8 | **Blighter** | 1.00 | 0.60 | 0.60 | 5–6 | Almost no direct damage; wins by stacking its element's status. ⭐ The archetype that teaches players what statuses actually do |

### 2.2 Mini-boss — the four that gate a section

| # | Archetype | HP× | DMG× | Product | Int | Behaviour |
|---|---|---|---|---|---|
| 9 | **Champion** | 1.70 | 1.20 | 2.04 | 7 | An Adept that is simply better at everything. The clean skill check |
| 10 | **Redoubt** | 2.20 | 0.85 | 1.87 | 6 | A wall. Shields on cooldown, heals. ⚠️ **The archetype most likely to produce a stalemate** — needs the fatigue clock (TYPE_EFFECTS §8) to stay honest |
| 11 | **Executioner** | 1.20 | 1.90 | 2.28 | 7 | Kills you in three turns if you misplay one. The fight you bring a shield to |
| 12 | **Hexer** | 1.60 | 0.75 | 1.20 | 8 | Stacks statuses *and* plays well. ⭐ The first opponent that punishes a bad loadout rather than bad reflexes |

### 2.3 Boss — the three that end a zone

| # | Archetype | HP× | DMG× | Product | Int | Behaviour |
|---|---|---|---|---|---|
| 13 | **Juggernaut** | 3.60 | 1.40 | 5.04 | 7 | Enormous. Slow, unsubtle, unavoidable — an endurance test. Pays for its product by being predictable |
| 14 | **Tyrant** | 2.60 | 1.70 | 4.42 | 9 | The real fight: high stats *and* near-perfect play. The intelligence is the threat |
| 15 | **Aspect** | 2.60 | 1.50 | 3.90 | 8 | ⭐ **The element itself, embodied** — leans entirely on its element's passive, taken to an extreme the player has never seen. The Flora Aspect never stops healing; the Pyro Aspect burns from turn one. The boss that *is* a lesson about one element |

### 2.4 What actually differentiates an archetype ⭐ (code audit, 2026-08-02)

Verified against the engine rather than assumed. **Four axes exist today**, not
two:

| # | Axis | Where it lives | What it controls |
|---|---|---|---|
| 1 | **Stats** | `MageState` fields | `maxHp`, `level`, and all six combat stats — `bonusDamagePercent`, `critChance`, `critDamage`, `accuracyBonus`, `dodge`, `deflectChance`, `deflectAmount` |
| 2 | **Intelligence** | `LadderAi(intelligence)` | Blunder rate, plus capability gates: counter-pick at 5, lethal detection at 6, status awareness at 7, payoff planning at 8, prediction at 9 |
| 3 | **Move set** | `LadderAi(spells:)` | ⭐ Much more than it looks — see below |
| 4 | **Element pool** | `LadderAi(elements:, lockedElement:)` | Which elements it cycles; whether it can counter-pick at all |

⭐ **The move set is the real behaviour dial.** `_affordable()` filters to what
the mage can currently pay for, so **a creature that only owns expensive moves
physically cannot act until it has charged**:

```dart
List<Spell> _affordable(MageState self) => [
      for (final s in spells)
        if (s.xCost ? self.charge >= 1 : s.chargeCost <= self.charge) s,
    ];
```

A heavy hitter telegraphs not because a flag says so, but because it has
nothing cheap to do. ⭐ **This also overrides the patience dial**: `LadderAi`
derives strike-early odds from intelligence alone (0.35 at low rungs → 0.08 at
rung 8+), which would otherwise make a *dim* heavy hitter contradictorily
impatient. It cannot poke with a move it cannot afford, so the move set wins.

⚠️ **Behaviour is NOT an independent axis, and two fields lie about that.**
`AiPersona` declares **`aggression`** and **`caution`**, documented as
*"personality dials — orthogonal to intelligence… a cautious level-9 and a
reckless level-9 are both hard, differently."* **Neither is used.**
`buildBrain()` returns `LadderAi(intelligence, spells:)`, which accepts
neither; the dials only exist on `TunableAi`, the older brain, now referenced
in exactly one lockstep test. The behavioural axis was designed and then lost
when the brain was replaced. Logged as a to-do in IMPLEMENTATION_PLAN.

**Consequence for the fifteen:**

| Status | Archetypes |
|---|---|
| ✅ Expressible today | Drudge · Skirmisher · Lasher · Glasswing · Adept · Bruiser · Champion · Executioner · Juggernaut · Tyrant |
| 🟡 Mostly | Sentinel · Redoubt — a defensive move set works, but "shields on a cadence" has no equivalent |
| ⚠️ Blocked on the AI | Blighter · Hexer · Aspect — all three are *built* on statuses, and the AI is effect-blind |

📝 **Recommendation: do not add a behaviour axis yet.** Stats + intelligence +
move set covers 12 of 15. Build the Primal quarter on those three and see
whether fights feel different in practice — with element passives layered on,
they likely will. If they feel samey, the cheapest fix is **reconnecting
`aggression`/`caution` to `LadderAi`**, since the fields, docs and concept
already exist.

### 2.5 Stat and tempo preferences ✅ (added 2026-08-02)

⭐ **Archetypes also express through the six combat stats and through tempo**,
not just HP and damage. All six are per-mage fields that already exist, so this
costs nothing to build and adds a lot of felt variety.

| Archetype | Stat lean | Tempo lean | Reads as |
|---|---|---|---|
| **Drudge** | ⚠️ *negative* accuracy | none | Flails and misses. Its incompetence is visible |
| **Skirmisher** | +accuracy, +dodge | **quick** | Hard to pin, always first |
| **Lasher** | +crit chance, −crit damage | quick | Lots of small bites, one occasionally stings |
| **Glasswing** | ++crit chance, ++crit damage | mixed | Spiky. Some turns are catastrophic |
| **Adept** | balanced | balanced | The yardstick |
| **Sentinel** | ++deflect chance/amount | **slow** | Everything you throw lands softer |
| **Bruiser** | +crit damage, −accuracy | **slow** | Hits like a truck, sometimes whiffs entirely |
| **Blighter** | +accuracy | mixed | Its statuses always land |
| **Champion** | +accuracy, +crit chance | balanced | Simply good at everything |
| **Redoubt** | +++deflect | **slow** | A wall that erodes you |
| **Executioner** | ++crit damage, +accuracy | mixed | One mistake ends you |
| **Hexer** | +accuracy, +dodge | quick | Slippery and always connecting |
| **Juggernaut** | ++deflect amount | **slow** | Unstoppable, unsubtle |
| **Tyrant** | +everything, modestly | balanced | No weakness to exploit |
| **Aspect** | element-dependent | element-dependent | Whatever its element wants |

⚠️ **Dodge on enemies needs a hard cap.** ITEMS §4.1a already warns that dodge
has no engine floor and an all-in build can reach 0% hit chance. On a *player*
that is a build choice; on an *enemy* it is a fight the player cannot win and
did not opt into. **Cap enemy dodge low** — it should read as "slippery", never
as "unhittable".

⭐ **Tempo lean = the cost band of its move set**, not a new field. "Slow"
means its moves are expensive, so it must charge and therefore telegraphs;
"quick" means cheap moves it can throw immediately. This reuses the §2.4
finding rather than adding a mechanism.

### 2.6 Sixteenth archetype — the Siphon ✅

✅ **Adopted.** Approved implicitly when the Primal rosters (§2d) were signed
off — four of the five zones use a Siphon, and Thornmire's entire premise is
built on it. ⭐ It is also the archetype that proves the §2b rule: it exists
because *plants that drink should drink*, not because the roster needed a
slot filling.

📝 Christian's suggestion: a leech/vampire archetype. It earns a slot by the
§2.7 test — it teaches something no other archetype does.

| # | Archetype | HP× | DMG× | Int | Stat lean | Behaviour |
|---|---|---|---|---|---|---|
| 16 | **Siphon** | 0.95 | 0.85 | 5–6 | +lifesteal moves | ⭐ Heals itself off every hit it lands. **Punishes slow, safe play specifically** — chip damage never accumulates, so a war of attrition is unwinnable and the player must commit to burst. The counter-lesson to Sentinel |

⭐ **Why it is worth the sixteenth slot:** every other archetype is beaten by
playing *well*. The Siphon is beaten by playing *differently* — it is the first
enemy that invalidates a strategy rather than punishing a mistake. Lifesteal is
already in the engine (`DamageEffect(lifesteal:)`, Leech and Drain), so it is
free.

⚠️ **Name avoids `Leech` and `Drain`**, which are both spell names in
`Spellbook`. Alternatives if Siphon reads too mechanical: **Sanguine**,
**Parasite**, **Bloodletter**. Not "Vampire" — it over-commits the fiction, and
this archetype should suit a leeching vine or a tick-swarm as readily as an
undead.

### 2.7 Notes on the set

- ⭐ **Every archetype teaches something.** That is the acceptance test for
  adding a sixteenth: if it does not teach a mechanic or punish a specific
  mistake, it is a reskin of one of these fifteen.
- 📝 **Coefficients are starting values**, to be moved by the balance sim
  (`tool/balance_sim.dart`) — which can already run these, since an archetype
  is just a `MageState` plus an intelligence rung.
- ⚠️ **Products within a tier are close but not equal.** Bruiser and Juggernaut
  sit high because telegraphing is a real cost the numbers cannot express.
  Verify that in the sim rather than trusting the table.
- ❓ **Open: does an archetype restrict its spell pool by element tier?** A
  Primal Bruiser should probably not have Cataclysm at level 8. Simplest rule:
  an enemy may only bring spells a *player* of its level could
  (`Progression.spellsAtLevel`), which reuses a curve that already exists.

---

## 2b. ⭐ The governing rule: fiction picks the archetype

✅ **A creature's nature decides its archetype — never the other way round.**
Christian's example is the general case: *a plant that absorbs should absorb*,
so a parasitic vine is a **Siphon**, not a Bruiser with a vine skin.

| Nature | Archetype it must be |
|---|---|
| Drinks, absorbs, parasitises | **Siphon** |
| Armoured, shelled, rooted | **Sentinel** / **Redoubt** |
| Swarms, many small parts | **Lasher** |
| Charges, gores, barrels | **Bruiser** |
| Spores, fumes, venom | **Blighter** |
| Darts, skims, flits | **Skirmisher** |
| Fragile and bright | **Glasswing** |

⭐ **Why this matters more than it sounds.** It is what stops the archetype
layer feeling like a spreadsheet: the player never learns "archetypes", they
learn *"the vines drink, so kill them fast."* The mechanics become an
observation about the world rather than a system to memorise — and a player
who has never heard the word Siphon still plays correctly against one.

⚠️ **The inverse is the failure mode to watch for:** picking an archetype
because a zone "needs a tank" and then inventing a creature to fit. Every time
that happens the zone gets one monster nobody believes in.

---

## 2c. ✅ The existing element rosters were re-homed

GAME_DESIGN §5 names Aqua's boss as the **Kraken**, Flora's as **Guardian of
the World Tree**, Pyro's as the **Efreet**, with Leviathan and Thorn Colossus
among the mini-bosses.

⚠️ **Those are endgame-scale names, and all three pure Primal zones sit at
levels 1–11.** A Kraken in a brook a level-5 character can walk to is absurd,
and it spends a great name on a fight nobody will remember.

✅ **Approved and recorded in GAME_DESIGN §5** — they are re-homed to the
later zones that carry those elements, where the scale fits:

| Name | Element | Suggested home | Band |
|---|---|---|---|
| **Kraken**, **Leviathan** | Aqua | Tidewrack Shoals | 36–40 |
| **Efreet**, **Magma Behemoth** | Pyro | The Molten Deep | 25–29 |
| **Guardian of the World Tree** | Flora | 📝 no late Flora zone exists — ❓ leave unused, or place in a future zone |

⚠️ **Flora is the odd one out**: it appears only in Whispering Woods (1–5),
Thornmire (8–13) and Ashfall Vale (10–14) — all early. So Flora has **no
high-level home at all**, which is worth noticing for reasons beyond naming:
a player who loves Flora has nowhere to take it late.

---

## 2d. ✅ The Primal quarter — themes and rosters

✅ **Approved.** The narrative arc these five themes form is recorded in
**GAME_DESIGN §5, "The Primal quarter's story"** — read it before changing any
theme here, because the themes are load-bearing for the storyline, not just
flavour for the bestiary.

Each zone gets **5 commons, 4 mini-bosses, 2 bosses**. Existing names from
`World.opponentNameFor` are kept and marked ✅.

### Whispering Woods · 1–5 · Flora

> ⭐ **Theme: the wood is a single creature, and you are standing on it.**

Taken from the arrival text — *"the murmur comes from the ground, from the
roots crossing under the path, and it stops the moment you stand still."*
Nothing here is an animal that happens to live in a forest; everything is an
**extension of one organism**, which is why it notices you.

| Common | Archetype | Why |
|---|---|---|
| **Listening Fawn** | Drudge | ⭐ Barely fights — it mostly *watches*. The level-1 teaching enemy, and it pays off the arrival text directly |
| **Thornback Sprite** ✅ | Skirmisher | Small, quick, gone before you swing |
| **Sporecap Shambler** | Blighter | Spores — the first status the game teaches |
| **Bindweed Creeper** | **Siphon** | ⭐ It drinks. The first lesson that chip damage does not always accumulate |
| **Rootknuckle** | Bruiser | A knot of root that punches up through the path |

**Mini-bosses:** Elderroot · The Murmur · Hollow Stag · Mother Spore
**Bosses:** **Heartwood** (the tree the network runs from) · **The Standing Green** (something the wood grew in the shape of a person — ⚠️ deliberately unsettling, and the quarter's first "this world is not safe" beat)

### Glimmerbrook · 3–8 · Aqua

> ⭐ **Theme: everything here is holding still, and that is the wrong thing for
> water to do.**

From *"fish hang in the current without swimming; the water is colder than the
season should allow."* Not a rushing river full of beasts — a **stillness**,
and things suspended in it.

| Common | Archetype | Why |
|---|---|---|
| **Brook Naiad** ✅ | Adept | The honest fight; the player's yardstick |
| **Shiverfish Shoal** | Lasher | Many small bites; shields chip rather than shatter |
| **Glassfleck Wisp** | Glasswing | ⭐ *"throws the light back at you in pieces"* — made of that light |
| **Siltback Crawler** | Sentinel | Armoured bottom-dweller. Slow, patient |
| **Chill Eel** | Skirmisher | Fast, cold, first to act |

**Mini-bosses:** The Held Breath · Weirkeeper · Pale Coil · Frostgleam Naiad
**Bosses:** **Stillwater** (the pool itself) · **The Cold Below**

### Cinderpeak Foothills · 6–11 · Pyro

> ⭐ **Theme: the mountain is breathing, and it is breathing faster.**

From *"somewhere above, the mountain is breathing; the air tastes of struck
flint."* Pressure, not eruption. Everything here lives **on** heat.

| Common | Archetype | Why |
|---|---|---|
| **Ashjaw Brute** ✅ | Bruiser | Heavy, telegraphed, unsubtle |
| **Flint Skink** | Skirmisher | Darts across hot rock |
| **Cinder Moth** | Glasswing | Beautiful, burning, one good hit from dead |
| **Slagshell Tortoise** | Sentinel | Cooled lava for a shell |
| **Ventworm** | Blighter | Breathes fumes up from the vents |

**Mini-bosses:** Char-Tusk · Vent Warden · The Emberqueen · Slagheart
**Bosses:** **Flintmaw** · **The Breathing Stone**

### Thornmire · 8–13 · Flora + Aqua ⭐ hybrid

> ⭐ **Theme: the green has beaten the water, and is drinking it.**

From *"the path becomes a suggestion, then a rumour, then water… everything
green here is winning."* ⭐ **This is the fusion, not a Flora monster standing
next to an Aqua one:** the two elements are one idea — **plants that absorb**,
which makes Thornmire the natural home of the Siphon archetype.

| Common | Archetype | Why |
|---|---|---|
| **Mirewalker** ✅ | Adept | The competent fight |
| **Thirstvine** | **Siphon** | ⭐ The zone's thesis in one creature |
| **Leechcap** | **Siphon** | A second drinker — Thornmire is where attrition stops working |
| **Bog Lantern** | Glasswing | Draws you in, dies to a stiff breeze |
| **Reedback Lurker** | Sentinel | Waits, armoured, in the shallows |

**Mini-bosses:** Fenmother · The Green Drowning · Old Wallow · Wickerdrowned
**Bosses:** **The Drinking Grove** · **Mirethroat**

⚠️ **Two Siphons in one zone is deliberate and needs watching.** It is the
lesson Thornmire exists to teach, but if the player has no burst option at
level 8–13 it becomes a wall rather than a lesson. **Verify against the actual
level-8 spell pool before committing.**

### Ashfall Vale · 10–14 · Pyro + Flora ⭐ hybrid

> ⭐ **Theme: an argument between fire and regrowth, still unresolved.**

The arrival text already writes it — *"fire came through here, and something is
arguing about whether it won."* ⭐ **The best theme in the quarter, and it was
already on the page.**

| Common | Archetype | Why |
|---|---|---|
| **Cinderbloom Husk** ✅ | Blighter | A burnt thing still seeding |
| **Ashroot Sapling** | **Siphon** | New growth drinking the burn |
| **Emberseed** | Glasswing | ⭐ A seed that germinates in fire — fragile, and it *pops* |
| **Scorchmoth** | Skirmisher | Quick through the falling grey |
| **Charwood Walker** | Bruiser | Standing deadwood that still moves |

**Mini-bosses:** First Green · Last Ember · The Grey Stag · Kindleroot
**Bosses:** ⭐ **The Blackened Crown** (fire won) · **The Rooting** (green won)

⭐ **The two-boss pool IS the theme.** Which boss you draw tells you which side
of the argument is winning today. That is the strongest possible use of the
random draw (§3d) — the pool is not variety for its own sake, it is the zone
saying something different each time you clear it. **Worth copying as a
pattern wherever a hybrid zone has a genuine tension.**

---

### 📝 Beyond the Primal quarter — the two late hybrids

The only other zones with finished themes and rosters are the two built to
close the element-coverage gap. Their designs live in WORLD_DESIGN because
they are as much map decisions as bestiary ones:

| Zone | Band | Theme | Design |
|---|---|---|---|
| **The Buried Sky** | 46–50 | The rock remembers a sky that no longer exists | WORLD_DESIGN §4c.1b |
| **The Sealed Garden** | 49–53 | The garden is still perfect, still guarded, and you are still not allowed in | WORLD_DESIGN §4c.1a |

⭐ **Both follow the §2b rule and both use the boss pool as their premise's two
sides** — the same trick as Ashfall Vale. ⚠️ **Three hybrids now do this, which
makes it a pattern worth stating:** *a hybrid zone's boss pool should be the
two sides of its premise.* The remaining seven hybrids have no themes yet, and
applying the rule to them is a content decision rather than an automatic one.

---

### ⭐ Why each theme was chosen — the reasoning to preserve

⚠️ **Read this before rewriting a zone theme.** Each one was derived from
something already in the game, not invented alongside it; a theme swapped
casually will break either an `arrival` passage or the quarter's story arc.

| Zone | The theme came from | What it is doing for the game |
|---|---|---|
| **Whispering Woods** | The arrival line that the murmur comes *from the roots, underground* — and stops when you stand still | ⭐ Makes the tutorial zone's monsters **extensions of one organism** rather than woodland animals. That is why the forest *notices* you, which is a far better first impression than "wolves live here" |
| **Glimmerbrook** | *"Fish hang in the current without swimming; the water is colder than the season should allow"* | ⭐ The only theme built on an element behaving **wrongly**. Deliberately the quarter's unanswered question (GAME_DESIGN §5) |
| **Cinderpeak Foothills** | *"The mountain is breathing"* — present tense, ongoing | ⭐ Chooses **pressure over eruption**. A volcano mid-eruption is a set piece; a volcano getting ready is a threat, and it leaves the eruption available later |
| **Thornmire** | *"Everything green here is winning"* | ⭐ Turns Flora+Aqua into **one idea instead of two rosters side by side** — plants that drink. That is what makes it the home of the Siphon, and it is the clearest example of the §2b rule in the game |
| **Ashfall Vale** | *"Fire came through here, and something is arguing about whether it won"* | ⭐ The strongest theme in the quarter, and it was already written. An **unresolved argument** is the only zone premise that a random boss pool can express mechanically rather than narrate |

⭐ **The general lesson, worth applying to the other 18 zones:** every theme
above was recovered from an `arrival` passage that already existed. None were
invented. The passages are far better direction than they look — they were
written as atmosphere, but each one contains a **claim about how that place
works**, and the roster falls out of taking that claim literally.

⚠️ **The two hybrids matter most and are the easiest to get wrong.** The
failure mode is a hybrid zone that is "Flora monsters and Aqua monsters in the
same swamp." Both hybrids here are instead a **single fused premise** that
needs both elements to state — Thornmire is one element drinking the other,
Ashfall Vale is two elements contesting. ✅ **Hold every later hybrid to that
bar:** if the theme still makes sense with one element removed, it is not a
hybrid theme yet.

---

## 2e. ✅ The rest of the world — themes and rosters (all 26 zones)

📝 **Every theme below was recovered from that zone's `arrival` passage**, the
same method as §2d. None were invented alongside. ⭐ **The passages carry a
claim about how each place works, and the roster falls out of taking the claim
literally** — the quote that produced each theme is given so nobody has to
guess later.

⭐ **Boss pools are the two sides of the zone's premise**, per the pattern §2d
established. That is now the rule for every hybrid *and* every pure zone: which
boss you draw should tell you which half of the place you are fighting.

✅ Existing names are marked — anchors from `World.opponentNameFor` and
mini/boss names from the element rosters in GAME_DESIGN §5.

---

### Kinetic · 15–29

#### Old Quarry · 15–19 · Geo
> *"Whatever was quarried out of here left a shape, and the shape has started to move."*

⭐ **Theme: the hole remembers what filled it.** The threat is the **absence**,
not the stone — negative space gone solid.

⭐ **Deliberate rhyme with The Umbral Wastes (47–51), not a repeat.** They are
**inverse operations**: here something was **removed** and the hole is animate;
there dark was **imposed** and given a shape. Subtraction against addition,
thirty levels and two elements apart. ⚠️ **Stated so nobody "fixes" it later**
by rethinking one of them — unstated, it reads as duplication.

| Common | Archetype |
|---|---|
| **Quarry Golem** ✅ | Bruiser |
| **Tailings Drudge** | Drudge |
| **Chiselback** | Skirmisher |
| **Gravelswarm** | Lasher |
| **Plumbline Sentry** | Sentinel |

**Minis:** Earth Titan ✅ · Obsidian Golem ✅ · The Overseer · Deadweight
**Bosses:** ⭐ **Mountain Heart** ✅ *(what was taken)* · **The Empty Course** *(the shape of what is gone, walking)*

#### Stormcliff Coast · 17–22 · Electro
> *"The cliffs take the whole weight of it… the rock is scorched in **long vertical lines**."*

⭐ **Theme: everything here is a path to the ground, including you.** The
vertical scorch marks are the tell — the coast is not a *target*, it is a
**conductor**. Things here are charged in passing rather than struck.

⚠️ **Retheme, 2026-08-02.** This zone was "the warning before the strike",
which was the same idea as Thunderspire Peaks two bands later (§2f). ⭐ **The
split is now space vs time:** Stormcliff is *where the lightning goes*,
Thunderspire is *when it comes*.

| Common | Archetype |
|---|---|
| **Stormcliff Tidecaller** ✅ | Adept |
| **Fulgurite Crawler** | Sentinel — ⭐ fulgurite is the glass left where lightning passed *through* sand |
| **Sparkwing** | Glasswing |
| **Static Shoal** | Lasher — the sea is one enormous electrode |
| **Groundling** | Skirmisher — survives by staying low |

**Minis:** Storm Shaman ✅ · Voltgeist ✅ · The Long Line · Brinecharge
**Bosses:** ⭐⭐ **Storm Lord** ✅ *(what comes down)* · **The Return Stroke**
*(what goes back up)* — the return stroke is the bright half of a real bolt and
it travels **upward**: the ground answering the sky

#### Windward Steppe · 19–24 · Aero
> *"The wind does not gust; it simply blows, and has been blowing since before there was anyone to notice."*

⭐ **Theme: one direction, forever — everything here has stopped resisting.**
Not violence. **Relentlessness**, which no other Aero zone claims.

| Common | Archetype |
|---|---|
| **Steppe Harrier** ✅ | Skirmisher |
| **Leanstone** | Sentinel |
| **Chaff** | Lasher |
| **Tumblehusk** | Drudge |
| **Kitewing** | Glasswing |

**Minis:** Wind Wraith ✅ · Gale Serpent ✅ · Sky Titan ✅ · Old Lean
**Bosses:** ⭐ **Tempest Monarch** ✅ *(the gust — the exception)* · **The Unbroken Blow** *(the constant)*

#### Frostfell Pass · 21–26 · Aqua + Aero ⭐ hybrid
> *"Your breath goes up and does not come down. The road is under here somewhere, and other people have been sure of that too."*

⭐ **Theme: everything that moves through here gets held.** The fusion is
**breath frozen mid-air** — Aero stopped by Aqua — and the second sentence is
the threat: the confident dead are still here.

| Common | Archetype |
|---|---|
| **Rime Stalker** ✅ | Skirmisher |
| **Hoarbound** | Sentinel |
| **Breathfrost** | Glasswing |
| **Cairnwight** | Blighter |
| **Snowblind Wanderer** | Drudge |

**Minis:** The Certain Road · Hoarking · Coldsnap · The Last Cairn
**Bosses:** ⭐ **NOT a mirror — a boss and its cause.** **The Road Under**
*(what is buried)* · **The White Corridor** *(what buried it)*. ⚠️ Killing the
Corridor does **not** free the Road — nothing you do down here digs anyone out.
⭐ The pool reads as futility rather than symmetry, which suits a pass whose
arrival text is about people who were also sure.

#### Thunderspire Peaks · 23–28 · Electro + Aero ⭐ hybrid
> *"The cloud is lit from within at intervals, and the intervals are getting shorter."*

⭐ **Theme: you are inside the storm, and it is building to something.** The
fusion is a storm as a **single accelerating event** rather than weather.
⚠️ Deliberately distinct from Stormcliff: that zone is one strike's warning,
this one is a countdown.

| Common | Archetype |
|---|---|
| **Stormcrest Roc** ✅ | Bruiser |
| **Humming Ore** | Sentinel |
| **Flashcount** | Lasher |
| **Updraft Wisp** | Glasswing |
| **Ionwake** | Skirmisher |

**Minis:** Thunder Roc ✅ · The Shortening · Anvilhead · Crown Fire
**Bosses:** ⭐ **The Strike That Lands** · **The Storm That Passes**

#### The Molten Deep · 25–29 · Pyro + Geo ⭐ hybrid · 🏰
> *"There is a floor down here that moves like water because it is not water."*

⭐ **Theme: the stone is a liquid and has been the whole time.** The fusion is
Geo revealed as Pyro's slow state — the ground you trusted was only cool.

| Common | Archetype |
|---|---|
| **Molten Warden** ✅ | Sentinel |
| **Slagswimmer** | Skirmisher |
| **Crustwalker** | Bruiser |
| **Ember Vent** | Blighter |
| **Cooling Thing** | Glasswing |

**Minis:** Magma Behemoth ✅ *(re-homed)* · Pyroclast · The Floor · Firstmelt
**Bosses:** ⭐ **Efreet** ✅ *(re-homed — what burns)* · **The Slow Stone** *(what has not melted yet)*

---

### Celestial · 30–47

#### The Kiln Desert · 30–34 · Solar
> *"The air is too thin to hold heat, so the sun burns while the wind bites."*

⭐ **Theme: burning and freezing at once.** The zone is a **contradiction**, not
a heat. That is what makes it Solar-at-altitude rather than a second desert.

| Common | Archetype |
|---|---|
| **Sunstruck Pilgrim** ✅ | Drudge |
| **Glasspan Crawler** | Sentinel |
| **Mirage** | Glasswing |
| **Shadeless** | Skirmisher |
| **Kiln Moth** | Lasher |

**Minis:** Sun Templar ✅ · Prism Sentinel ✅ · The Shadeless Hour · Saltmarch Wraith
**Bosses:** ⭐ **Solar Deity** ✅ *(the sun)* · **The Cold Shadow** *(what it cannot reach)*

#### The Mirrormere · 32–37 · Lunar
> *"The moon at a size the moon has no right to be… you are careful not to look down for too long."*

⭐ **Theme: the reflection is bigger than the thing, and it is looking back.**

| Common | Archetype |
|---|---|
| **Mirror Wraith** ✅ | Adept |
| **Stillface** | Sentinel |
| **Undershine** | **Siphon** |
| **Ripplecut** | Skirmisher |
| **Palefish Shoal** | Lasher |

**Minis:** ⭐ Herald of the Waxing ✅ · Stalker of the New Moon ✅ · The Waning Wraith ✅ · The Second You
**Bosses:** ⭐⭐ **Luna Plena, the Full Moon** ✅ *(the moon above)* · **The Moon Below** *(the moon in the water)* — **which one is real is the fight**

#### Starfall Basin · 34–39 · Astral
> *"At night the sky is so clear it looks like a threat."*

⭐ **Theme: things fell here, and the sky is still aiming.**

| Common | Archetype |
|---|---|
| **Crater Revenant** ✅ | Bruiser |
| **Sky-Iron Husk** | Sentinel |
| **Fallpoint** | Glasswing |
| **Scatterling** | Lasher |
| **Cold Ejecta** | Skirmisher |

**Minis:** Rift Walker ✅ · Constellation Warden ✅ · Echo of the Between ✅ · The Zodiac Ascendant ✅
**Bosses:** ⭐ **NOT a mirror — the same thing at two scales.** **What Landed**
*(small, already at the bottom of a crater)* · **The Next One** *(enormous, and
still inbound)*. ⭐ Drawing the small one is a **warning about the big one**,
which is exactly what *"the sky is so clear it looks like a threat"* promises.

#### Tidewrack Shoals · 36–40 · Lunar + Aqua ⭐ hybrid
> *"Everything is timed to something overhead."*

⭐ **Theme: the sea is on a schedule it did not choose, and it keeps uncovering
things.** The fusion is **obedience** — Aqua doing what Lunar says.

| Common | Archetype |
|---|---|
| **Tidewrack Drowned** ✅ | Drudge |
| **Wrackcrab** | Sentinel |
| **Lowwater Thing** | **Siphon** |
| **Gullbone Flock** | Lasher |
| **Spindrift** | Glasswing |

**Minis:** Tidal Empress ✅ · Maelstrom Horror ✅ · Leviathan ✅ *(re-homed)* · The Turning
**Bosses:** ⭐ **Kraken** ✅ *(re-homed — what the tide uncovers)* · **The Undertow** *(what it takes back)*

#### The Sunless Reach · 38–42 · Solar + Lunar ⭐ hybrid
> *"The rock is the same rock. The desert is a thousand feet away and on the other side of the world."*

⭐⭐ **Theme: identical ground, opposite worlds, one line between them.** The
fusion is **a boundary, not a blend** — and that is the best possible Solar+Lunar
premise, because the two elements refuse to mix by nature.

| Common | Archetype |
|---|---|
| **Eclipse Herald** ✅ | Adept |
| **Crestline Warden** | Sentinel |
| **Nightglare** | Glasswing |
| **Coldlight Swarm** | Lasher |
| **Shadowpitch Stalker** | Skirmisher |

**Minis:** Solar Archon ✅ · The Crest · Duskmarch · Both-Sided Thing
**Bosses:** ⭐ **The Last Light** · **The First Dark**

#### The Shattered Orrery · 40–44 · Astral + Electro ⭐ hybrid · 🏰
> *"Something is being calculated and has been for a very long time."*

⭐ **Theme: a broken machine still computing, and nobody knows what toward.**
The fusion is **the heavens as mechanism** — Electro is the power, Astral is
what it is modelling.

| Common | Archetype |
|---|---|
| **Orrery Automaton** ✅ | Sentinel |
| **Gear-Ghost** | Glasswing |
| **Armature** | Bruiser |
| **Arcflock** | Lasher |
| **Errant Ring** | Skirmisher |

**Minis:** Escapement · The Remainder · Long Division · Sidereal Fault
**Bosses:** ⭐⭐ **The Calculation** *(the process)* · **The Answer** *(the result)* — **drawing the Answer means it finished**

#### The Glass Archive · 43–47 · Solar + Arcane ⭐ hybrid · 🏰
> *"They wrote it in light, and light does not keep."* (WORLD_DESIGN §4c.1c)

⭐ **Theme: an archive readable only at noon, which the reading destroys.**

| Common | Archetype |
|---|---|
| **Glasswright** ✅ | Sentinel |
| **Noonmark** | Glasswing |
| **Palimpsest** | **Siphon** — a page scraped clean and rewritten; it takes what is yours |
| **Readerless** | Drudge |
| **Lensfly** | Skirmisher |

**Minis:** The Marginalia · Burnt Index · The Last Reader · Aperture
**Bosses:** ⭐ **What Was Written** · **What Is Left Of It**

---

### Ethereal · 45–60

#### Hallowmarch · 45–49 · Sanctus
> *"Every mile or so there is a marker, and every marker has been maintained."*

⭐ **Theme: someone is still doing the upkeep, and nobody has seen them.**
⚠️ **Load-bearing:** the causeway leads to The Sealed Garden, and the same oath
maintains both. Changing this theme breaks that zone too.

| Common | Archetype |
|---|---|
| **Causeway Warden** ✅ | Sentinel |
| **Marker-Sworn** | Adept |
| **Meltwater Choir** | Lasher |
| **Votive** | Glasswing |
| **Pilgrim's Remnant** | Drudge |

**Minis:** Vestal Warden ✅ · Seraph Judicant ✅ · The Upkeep · Milestone
**Bosses:** ⭐ **The Hierophant Eternal** ✅ *(who ordered it)* · **The Keeper of the Road** *(who still does it)*

#### The Umbral Wastes · 47–51 · Umbra
> *"Not dusk — an absence with an edge to it… the ice holds its shape like something that has been thought about."*

⭐ **Theme: the dark here is deliberate. Something decided its shape.** Not
absence — **design**. That is what separates Umbra from "night".

| Common | Archetype |
|---|---|
| **Umbral Devourer** ✅ | **Siphon** |
| **Edgewalker** | Skirmisher |
| **Considered Ice** | Sentinel |
| **Nightspill** | Blighter |
| **Thoughtform** | Glasswing |

**Minis:** Void Stalker ✅ · Umbral Knight ✅ · Eclipse Weaver ✅ · The Edge
**Bosses:** ⭐ **Nightbringer** ✅ *(who made it dark)* · **What Was Thought About** *(the shape it was given)*

#### The Buried Sky · 46–50 · Geo + Astral ⭐ hybrid · 🏰
Full design in WORLD_DESIGN §4c.1b. ⭐ *The rock remembers a sky that no longer exists.*
**Commons:** Stratum Warden ✅ (Sentinel) · Constellate (Lasher) · Fadelight (Glasswing) · Corebiter (**Siphon**) · Deadreckoner (Adept)
**Minis:** Bedrock Colossus · Nadir · The Long Count · Stonefall Herald
**Bosses:** **The Overburden** *(what buries)* · **The Buried Constellation** *(what survives)*

#### The Sealed Garden · 49–53 · Flora + Sanctus ⭐ hybrid
Full design in WORLD_DESIGN §4c.1a. ⭐ *Still perfect, still guarded, still not allowed in.*
**Commons:** Orchard Warden ✅ (Sentinel) · Windfall (**Siphon**) · Whisperling (Blighter) · Chorister Vine (Adept) · Thornpenitent (Bruiser)
**Minis:** Cherub of the Turning Blade · The Last Gardener · Root Matriarch ✅ · The Kept Vow
**Bosses:** **Guardian of the World Tree** ✅ *(the rule)* · **The Serpent in the Branches** *(the invitation)*

#### The Collapsed Academy · 50–54 · Arcane · 🏰 · Empyrean
> *"Not ruined so much as unfinished in the wrong direction… the last three items on the syllabus are not in any language you have."*

⭐ **Theme: it was not destroyed — it was continued past the point where
building makes sense.** ⚠️ **Over-completion, not ruin**, and that distinction
is the whole zone.

| Common | Archetype |
|---|---|
| **Unfinished Scholar** ✅ | Adept |
| **Stairhead** | Sentinel |
| **Chalkwraith** | Skirmisher |
| **Marginal Note** | Blighter |
| **Emeritus** | Drudge |

**Minis:** Spell Weaver ✅ · Mana Golem ✅ · Arcane Chimera ✅ · The Fourth Item
**Bosses:** ⭐ **The Archmage** ✅ *(who read too far)* · **The Last Three Items** *(what they read)*

#### The Reliquary Deep · 52–56 · Sanctus + Umbra ⭐ hybrid · 🏰
> *"Someone consecrated it and someone else did not leave it alone. It is warmer in the middle than at either end."*

⭐ **Theme: two hands worked on this, and the second has not finished.**
⭐ **The warmth in the middle is the tell** — the corridor is not empty.

| Common | Archetype |
|---|---|
| **Reliquary Keeper** ✅ | Sentinel |
| **The Unleft** | Blighter |
| **Censer-Wraith** | Glasswing |
| **Bone-Reliquary** | Bruiser |
| **Corridor Crawler** | **Siphon** |

**Minis:** Reliquary Colossus ✅ · The Second Hand · Warm Middle · Antechoir
**Bosses:** ⭐⭐ **What Was Consecrated** · **What Did Not Leave It Alone** — both lifted straight from the arrival line

#### The Unwritten Library · 54–58 · Umbra + Arcane ⭐ hybrid · 🏰 · Empyrean
> *"Every book here is being written right now, by nobody… it would like your name for the record."*

⭐ **Theme: it is still writing, and it wants you in it.** The fusion is
**authorship with no author** — Arcane supplies the writing, Umbra supplies the
nobody.

| Common | Archetype |
|---|---|
| **The Dictating Hand** ✅ | Adept |
| **Blankspine** | Sentinel |
| **Footnote** | Lasher |
| **Erratum** | Skirmisher |
| **Ink-Drinker** | **Siphon** |

**Minis:** The Index · Redaction · Colophon · The Amanuensis
**Bosses:** **The Author** *(who is writing)* · **The Record** *(what is written)*
⭐ **plus a third draw available only on a repeat clear: *Your Entry*** — the
first visit gave it your name, and it has been writing ever since. Gated on
`PlayerProfile.hasCleared('the_unwritten_library')`. ⚠️ **The only encounter in
the game that cannot exist on a first visit**, which is the point.

#### ⚠️ The Eclipsed Citadel · 58–60 · all twelve · 🏰 · Empyrean

> *"The Citadel is between you and it. That is what the name has always meant."*

⭐ **Theme: the last thing in the way.** Not a place — an **obstruction**.

⚠️ **This zone should NOT use the 5-commons / 4-minis / 2-bosses template, and
forcing it to would be a mistake.** It is the finale, it carries all twelve
elements, and a flat roster of five commons cannot express that.

📝 **Proposal — the Citadel's roster is the game replaying itself.** Its
encounters are **echoes of bosses the player has already beaten**, drawn from
the zones they cleared. ⭐ Three things recommend it: it is the only structure
that can legitimately field twelve elements; it makes the finale personal to
each character's route; and it costs almost nothing in new content because the
statlines and painter recipes already exist.

**Boss:** Procarius, the Eclipsed ✅ — ❓ **does the 2-boss pool apply here?**
A finale with a coin-flip boss may undercut the ending. Worth a ruling.

---

## 2f. ⚠️ Overlap audit (2026-08-02) — what the full rosters exposed

Run across all 25 rostered zones (the Citadel is exempt, §2e). **172 distinct
creature names, 125 commons, 100 mini-bosses, 50 bosses.**

### ✅ Clean

- ✅ **One name collision, fixed.** *Obsidian Golem* was a mini in both Old
  Quarry and The Molten Deep — both Geo. The Molten Deep took **Pyroclast**.
- ✅ **No zone repeats an archetype inside its own five commons.** Every zone
  fields five genuinely different fights.

### ⛔ The real gap: minis and bosses have no archetypes

⛔ **Every mini-boss and boss in §2d–2e is a NAME and a premise, with no
archetype attached.** §2.2 defines four mini archetypes (Champion, Redoubt,
Executioner, Hexer) and §2.3 three boss archetypes (Juggernaut, Tyrant,
Aspect), and not one of the 150 elevated encounters is mapped to any of them.

⚠️ **This is the half that decides whether a fight is any good.** A name and a
premise tell you what a boss *means*; the archetype tells you what it *does*.
Until they are assigned, none of these can be built or balance-simmed.

### ⚠️ Archetype distribution is lopsided

| Archetype | Zones | |
|---|---|---|
| Sentinel | 23 | ⚠️ near-universal |
| Skirmisher · Glasswing | 19 each | |
| Lasher | 14 | |
| **Siphon** | 12 | ⚠️ see below |
| Bruiser · **Adept** | 10 each | ⚠️ see below |
| Drudge · Blighter | 9 each | |

⚠️ **Adept appears in only 10 of 25 zones, and it is the yardstick.** §2.1 calls
it "the honest mirror-match; the yardstick every other archetype is felt
against." ⭐ **In the 15 zones without one, the player has no baseline** — every
fight is an exception to a rule they never met. Adept should arguably be
mandatory in every zone.

⚠️ **The Siphon is in 12 of 25 zones and that dilutes it.** §2.6's whole case is
that it is "the first enemy that invalidates a strategy rather than punishing a
mistake." ⭐ **A shock that happens in half the zones is not a shock.** It
should be concentrated where absorption is the zone's actual idea — Thornmire,
The Sealed Garden, The Umbral Wastes — and cut elsewhere.

⚠️ **Drudge appears at levels 45–54** (Pilgrim's Remnant in Hallowmarch,
Emeritus in The Collapsed Academy). A Drudge is 0.80 HP / 0.70 damage and
"barely fights" — ⭐ **it is the level 1–3 teaching dummy, and at level 50 it is
a wasted encounter slot** in the hardest content in the game. Either re-skin
those two or accept they are flavour, not fights.

### ⚠️ Thematic collisions

| Pair | Risk |
|---|---|
| **Stormcliff Coast** (17–22, *the warning before the strike*) vs **Thunderspire Peaks** (23–28, *the countdown to the strike*) | ⚠️ **The real one.** Adjacent bands, both Electro, both built on anticipation. A player goes straight from one to the other. One of them needs a different idea |
| **The Glass Archive** (43–47) vs **The Buried Sky** (46–50) | ✅ Deliberate opposition — light that keeps nothing vs stone that keeps everything. Documented in WORLD_DESIGN §4c.1c so it is not "fixed" later |
| **Old Quarry** (*absence made solid*) vs **The Umbral Wastes** (*dark given a shape*) | 📝 Same idea, 30 levels apart. Probably fine; worth not making it a third time |

### ⚠️ The structural risk nobody will notice until playtest

⭐ **Every boss pool is now "X versus its opposite."** The pattern is excellent
— it is why Ashfall Vale, The Sealed Garden and The Buried Sky all land. But it
is now applied to **all 25 zones**, and ⚠️ **a player will decode the formula
around zone six and stop being surprised by it for the remaining nineteen.**

📝 **Worth deliberately breaking in perhaps a third of zones.** Alternatives
that still give the pool a reason to exist:

- **Two of the same thing at different scales** — the small one is the warning.
- **A boss and its cause** — kill the wrong one and nothing changes.
- **One boss and one absence** — sometimes the arena is empty, and that is
  worse.
- **A boss that is only there on the second clear.**

✅ **Applied 2026-08-02 — three zones now break the mirror:**

| Zone | Structure | Why it is better than a mirror |
|---|---|---|
| **Starfall Basin** | two scales | *What Landed* is small and already down; *The Next One* is enormous and inbound. Drawing the small one is a **warning about the big one** |
| **Frostfell Pass** | boss and its cause | Killing *The White Corridor* does not free *The Road Under*. ⭐ Reads as **futility**, which suits a pass full of people who were also sure |
| **Windward Steppe** | 📝 the empty arena | The premise is a wind that has never stopped, so one draw is *nothing at all* — you reach the end and it just keeps blowing. ⚠️ **Mechanically awkward** — a zone-clear with no fight — so it probably needs to be a very short encounter rather than literally empty. Worth trying because no other zone would do it |

⭐ **And the strongest one, now unblocked:** **The Unwritten Library** gets a
**third boss that only exists on a repeat clear**. The zone's premise is *"it
would like your name for the record"* — so the first clear takes your name, and
every clear after that can draw **you**, written in. ✅ `PlayerProfile` now
carries `zoneClears`, which is what this needs.

---

## 3. Moves — enemies are creatures, not mages ✅ (ruling 2026-08-02)

⚠️ **Correcting an assumption baked into §2:** the archetype tables above
describe behaviour in terms of *spells*. That is wrong for most of the
bestiary.

> ✅ **Spells are cast by MAGES — and not even by all of them.** Most enemies
> are creatures. A boar does not cast Bolt; it has a gore and a charge-down. A
> drake does not cast Cataclysm; it breathes fire. Creatures have **move
> sets**, and those moves are **their own**.

### 3.1 Moves and spells are the same TYPE, different CATALOGUES ⭐

The engine needs no change. A move is mechanically a `Spell`: a name, a charge
cost, a priority, an effect, optionally an element. What differs is the
catalogue it comes from.

| Catalogue | Owner | Example |
|---|---|---|
| `Spellbook` | Players, and mage-type enemies | Bolt, Cataclysm, Ward |
| **Creature move sets** 📝 | Everything else | a boar's gore; a drake's breath |

⭐ This means **the §2.4 finding still holds**: the move set remains the real
behaviour dial, because `_affordable()` gates on cost regardless of which
catalogue a move came from. A creature whose only move is expensive must
charge before it can act, exactly as a mage with only Cataclysm must.

### 3.2 ⚠️ Archetype ≠ move set

✅ **Moves are independent of archetype.** Do not define an archetype by naming
moves, and do not give two creatures the same move because they share an
archetype. A boar and a drake can both be Bruisers and share nothing else.

📝 **Proposed division of labour** — ❓ needs confirming:

| Supplies | What |
|---|---|
| **Archetype** | Stat coefficients, intelligence, and the *shape* of the move set — how many moves, roughly what cost and priority band |
| **Creature** | The moves themselves — names, flavour, how its element shows up |

So a Bruiser has "2–3 moves, at least one expensive and slow"; the boar fills
that with **Gore**, the drake with **Emberbreath**. Same rhythm, different
fiction. ⚠️ Without *some* mechanical shape from the archetype, Bruiser and
Skirmisher differ only in HP and damage numbers, which is thin — but if that
crosses the line into "tying archetypes to moves", say so and the shape moves
onto the creature entirely.

### 3.3 🚫 Move naming — do not drift toward Pokémon

⚠️ **The obvious names are taken, including the ones reached for first.**
**Tackle**, **Bite**, **Ember**, **Gust**, **Scratch**, **Dragon Breath**,
**Quick Attack** and **Body Slam** are all literal Pokémon moves. A bestiary
built from them reads as pastiche immediately.

Safer directions — concrete, physical, slightly archaic:

| Instead of | Use |
|---|---|
| Tackle | **Barrel**, **Bowl Over**, **Ram** |
| Bite | **Gnash**, **Savage**, **Worry** |
| Ember / Flamethrower | **Sear**, **Scorch**, **Kindle**, **Emberbreath** |
| Water Gun | **Douse**, **Sluice**, **Spume** |
| Vine Whip | **Lash**, **Snare**, **Bind** ⚠️ (*Bound* is reserved — "Bind" as a move is fine, but never "Bound") |
| Gust | **Buffet**, **Squall** |

🚫 **Never name a move "Charge."** Charging is the game's core verb — a move by
that name would be genuinely confusing in the log and the tutorial. Same for
**Cast**, **Focus**, and any element name.

⭐ **A good test:** if the move would look at home in a Pokédex, rename it. If
it would look at home in a bestiary entry written by a nervous field
naturalist, it is right.

✅ **Calibrate the strictness by WHERE in the game it appears.** Some overlap is
inevitable and fine — there are only so many things a dragon can do.

| Band | Rule |
|---|---|
| **Primal quarter (1–14)** | 🚫 **Strict.** This is first impressions. A player who decides in the first hour that this is a Pokémon clone will not revise that opinion |
| **Mid game** | ⚠️ Prefer distinct, accept the occasional collision |
| **Late / magic-themed** | ✅ Relaxed. By then the game has established what it is, and an overlapping name reads as coincidence rather than derivation |

### 3.3a ⭐ Narrate moves as VERBS — the structural fix

📝 Christian's idea, and it solves the resemblance problem better than any
blocklist: **do not announce moves, narrate them.**

| Pattern | Reads as |
|---|---|
| 🚫 "Boar used Ram!" | Pokémon, unmistakably |
| ✅ "The boar rams you for 12" | A bestiary, or a roguelike |

⭐ **Then name creature moves as VERBS and the narration writes itself.** A move
called **Gore** narrates as *"the boar gores you"*; **Sear** becomes *"the drake
sears you"*. The verb **is** the move name, conjugated — so nothing is lost.

⭐ **This gives spells and moves a genuine grammatical split**, which reinforces
the fiction at zero cost:

> **Mages cast NOUNS** — *"Wick casts Umbra Bolt"*
> **Creatures do VERBS** — *"the boar gores you"*

⚠️ **The clarity cost Christian flagged is real but recoverable.** A player
still needs to learn "the boar's gore hits hard" — so keep the move name in the
data and surface it in the **bestiary entry** and on tap/hover, even though the
log narrates. Because the name is the verb's root, *"gores"* → **Gore** is
readable without being told.

📝 Consequence for the log: `SpellCastEvent`'s single template
(`'{caster} casts {element} {spell}'`) needs a creature variant. That is a
small change in `events.dart`, but it is a **change to player-facing text that
the tooltip drift-guard tests read** — expect to update those in the same pass.

### 3.3b ❓ Physical damage — open, and higher-stakes than it looks

Christian: verb-narration *"raises the need for possibly non-mage-only move
types such as physical."* Agreed that it raises the question. ⚠️ **It should be
answered carefully, because the naive version breaks the core mechanic in the
worst possible place.**

Today every attack carries an element, and elements are the whole game: the
counter wheel, shield multipliers, and every passive hang off them.

| Option | Consequence |
|---|---|
| **(a) Creature moves carry their ZONE's element** — a Flora boar gores you with Flora damage | ✅ Zero engine change; counter-picking stays meaningful everywhere; the boar still *feels* physical because the move is called Gore, not Bolt |
| **(b) "Physical" as a neutral 13th type, 100% vs all shields, no passive** | ⚠️ Clean fiction, but a zone full of beasts becomes **immune to counter-picking** |
| **(c) Physical ignores elemental shields** | 🚫 Makes shields worthless against beasts |

📝 **Recommendation: (a).** ⭐ The decisive argument is *where* the beasts are:
the Primal quarter is almost entirely creatures, and it is also where the
player is **learning that elements matter**. If early-game beasts deal
element-less damage, the first fourteen levels quietly teach that the counter
wheel is irrelevant — the exact opposite of the intended lesson, delivered at
the exact moment it does most damage.

💡 **If physical is wanted later, add it as a RIDER, not a replacement**: a move
that is Flora-element *and* carries a physical component, so it still interacts
with the wheel. That keeps the fiction without costing the mechanic.

### 3.4 Which enemies are mages? 📝

❓ Open. Some enemies clearly are — the Ethereal band is scholars, wardens and
archmages, and Procarius is explicitly a mage. Those should draw from
`Spellbook` so the player faces their own tools used against them, which is a
genuinely different and welcome fight.

📝 Suggested split, to confirm: **beasts and constructs get creature moves;
humanoid casters get `Spellbook`.** Roughly, the Primal and Kinetic bands are
mostly creatures, and the Ethereal band is mostly mages — which also gives the
late game a distinct texture without any new mechanics.

---

## 4. Rosters are per REGION, not per element ✅ (ruling 2026-08-02)

⚠️ **This supersedes GAME_DESIGN §5's per-element roster table** for every zone
that is not a pure single-element zone.

> ✅ **Every region gets its own complete, distinct roster** — commons,
> mini-bosses and bosses — and it must be **thematically coherent within
> itself**. A hybrid zone does not borrow one parent's mini-boss and the
> other's boss. Thornmire (Flora+Aqua) gets swamp creatures that express
> *both* elements as one idea, not a Flora monster standing next to an Aqua
> monster.

✅ **Counts per region: 4 mini-bosses and 2 bosses.** Final (2026-08-02).
⚠️ GAME_DESIGN §3d still says "3–5 mini-bosses and 1–2 bosses" — **update it to
match**, since a run draws 2 minis + 1 boss from those pools.

### 4.1 ⚠️ The scope this commits to

| | Zones | Mini-bosses | Bosses | Total |
|---|---|---|---|---|
| **Primal quarter** | 5 | 20 | 10 | **30** |
| **Whole game** | 23 | **92** | **46** | **138** |

⭐ **138 elevated enemies, plus commons** — still the largest content
commitment in the project, but 46 fewer than the 5-and-3 shape and, crucially,
**a pool of 4 still gives a run real variance**: two minis drawn from four is
six distinct pairings per zone, so a zone does not become memorised after one
clear (the §3d goal).

⭐ **Two bosses is the smallest number that preserves the surprise.** With one,
every clear of a zone ends identically; with two, the final fight is a coin
flip the player must be prepared for either way.

📝 **Two levers if that proves too large**, neither requiring a design change:

1. **Bosses need not all be unique fights.** Three bosses per zone with one
   shared arena and differing move sets is far less work than three bespoke
   encounters, and the random draw (§3d) already means a player sees one per
   run.
2. **The archetype layer absorbs most of it.** A mini-boss is
   *archetype + creature + name + move set*; only the creature and moves are
   new writing. The statline is a lookup.

### 4.2 What this does to the existing named rosters

The 23 zones split cleanly:

- **12 pure zones**, one per element — GAME_DESIGN §5's existing lists
  (Tidal Empress, Root Matriarch, Inferno Lord…) map onto these directly, and
  are a starting point for 3 of the 5 minis each.
- **11 zones** (10 hybrids + the Eclipsed Citadel) have **no roster at all**
  today and need one built from nothing.

## 3. Still to design 📝

Tracked per zone in [CONTENT_CHECKLIST.md](CONTENT_CHECKLIST.md).

1. **Zone rosters** — which archetypes appear in which zone, and in which of
   the three sections (GAME_DESIGN §3d).
2. **Display names** — one per archetype-instance per zone. Five already exist
   in code (`World.opponentNameFor`) and are good: Thornback Sprite, Brook
   Naiad, Ashjaw Brute, Mirewalker, Cinderbloom Husk.
3. **Mini-boss and boss pools** — ✅ now **5 and 3 per region**, each region
   with its own coherent roster (§4). 11 of the 23 zones have nothing today.
4. **Boss mechanics** — what makes a boss more than a big statline.
   💡 Already banked: Luna Plena fightable only on a Full Moon turn.
5. **Art** — ⚠️ every visual in this project is a `CustomPainter` and there are
   no image assets anywhere. An enemy "image" therefore means a painter recipe
   (silhouette + palette + a motion), most likely parameterised by archetype
   with the element supplying the colour. `mage_sprite.dart` is the precedent.
6. ⚠️ **The AI is effect-blind** — it does not understand statuses. That caps
   how well Blighter, Hexer and Aspect can work, since all three are *built*
   on statuses. Phase 6 calls fixing this "a real fork in the road"; these
   three archetypes are the reason it matters.
