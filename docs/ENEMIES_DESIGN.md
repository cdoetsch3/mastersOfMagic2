# Masters of Magic 2 — Enemies

Status: 📝 **draft.** Started 2026-08-02. This is the Phase 6 design
deliverable named in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

✅ **2026-09-22 — the late-game pass.** All **26 zones are now rostered**: the
fifteen at level 30+ were rebalanced against §2f's targets in one pass (§2f
carries the before/after), **The Sealed Garden**, **The Buried Sky** and **The
Eclipsed Citadel** were designed from nothing to the §2d standard, every
creature in the fifteen carries a **drop role** (§2e.1), and §2h's off-element
guardrail got a number (§2e.2). ⭐ **§2e is now the single source a build lane
reads** — it does not need this document's history, WORLD_DESIGN, or §2g.

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
- ✅ **Resolved: an enemy may only bring spells a *player* of its level could**
  (`Progression.spellsAtLevel`), which reuses a curve that already exists. A
  Primal Bruiser does not get Cataclysm at level 8.
- ✅ **Which element a creature uses — see §2h.**

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

> ✅ **All five rosters below are BUILT** — `lib/game/enemies/*.dart`, 55
> creatures with elements, move sets and drop tables, one test file per zone.
> Build state per column lives in
> [CONTENT_CHECKLIST.md](CONTENT_CHECKLIST.md) §2, not here; the ✅ on each
> heading is only "this design has been implemented as written".

### Whispering Woods · 1–5 · Flora ✅ built

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

### Glimmerbrook · 3–8 · Aqua ✅ built

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

### Cinderpeak Foothills · 6–11 · Pyro ✅ built

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

### Thornmire · 8–13 · Flora + Aqua ⭐ hybrid ✅ built

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

### Ashfall Vale · 10–14 · Pyro + Flora ⭐ hybrid ✅ built

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

### ✅ Beyond the Primal quarter — the whole world is now rostered

✅ **Every zone in the game has a designed roster as of 2026-09-22.** The
fifteen zones at level 30+ live in **§2e**, rebalanced in one pass against
§2f's targets, with full rank / archetype / element / drop-role tables.

⭐ **Three of them were designed from nothing in that pass** and are written to
this section's standard — theme line, premise, the reasoning to preserve, the
5/4/2 table, per-creature element, lore and *teaches* lines, and a move-kit
sketch per creature:

| Zone | Band | Theme | Design |
|---|---|---|---|
| **The Buried Sky** | 46–50 | The rock remembers a sky that no longer exists | **§2e** ⭐ *(map decisions remain in WORLD_DESIGN §4c.1b)* |
| **The Sealed Garden** | 49–53 | The garden is still perfect, still guarded, and you are still not allowed in | **§2e** ⭐ *(map decisions remain in WORLD_DESIGN §4c.1a)* |
| **The Eclipsed Citadel** | 58–60 | The last thing in the way | **§2e** ⭐ all twelve elements, and Procarius |

⚠️ **The two hybrids' designs moved here from WORLD_DESIGN**, which now holds
their placement, roads and story load only. ⭐ **A code lane should read §2e and
nothing else** — that was the point of the pass.

⭐ **Both hybrids follow the §2b rule and both use the boss pool as their
premise's two sides** — the same trick as Ashfall Vale. ⚠️ **That is now the
rule rather than a pattern:** *a hybrid zone's boss pool should be the two sides
of its premise*, and §2e applies it to every remaining hybrid, with the element
assignment carrying it too (Tidewrack's Kraken is Aqua and its Undertow is
Lunar, because the undertow is not the water — it is the pull).

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

## 2e. ✅ The rest of the world — themes and rosters (26 of 28 zones)

⚠️ The two north-road zones are NOT in this section — see "The north road" above.

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

#### Old Quarry · 15–19 · Geo ✅ built
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

#### Stormcliff Coast · 17–22 · Electro ✅ built
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

#### Windward Steppe · 19–24 · Aero ✅ built
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

#### Frostfell Pass · 21–26 · Aqua + Aero ⭐ hybrid ✅ built
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

#### Thunderspire Peaks · 23–28 · Electro + Aero ⭐ hybrid ✅ built
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

#### The Molten Deep · 25–29 · Pyro + Geo ⭐ hybrid · 🏰 ✅ built
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

✅ **Final 2026-09-22 — the fifteen zones at level 30+ were rebalanced in one
pass** (§2f's targets; ruled by Christian 2026-09-22: *"rebalance during the
design pass, keeping creature names and themes; built zones keep their code"*).
⭐ **Every entry below is the final state.** A code lane can build straight
from it plus the two example zone files (`lib/game/enemies/old_quarry.dart`,
`lib/game/enemies/frostfell_pass.dart`) without reading any history.

**How to read a roster table.** Every zone is **5 commons · 4 minis · 2
bosses**, the four minis are **one of each mini archetype**, and the boss pair
is the two sides of the premise (or one of §2f's licensed breaks).

| Column | What it binds |
|---|---|
| **Archetype** | ⭐ Supplies everything mechanical except the moves: HP×, DMG×, intelligence rung, **move count** and **cost band** (`enemy_archetype.dart`), and the stat lean of §2.5 |
| **Element** | The creature's `elements` list, verbatim. A pure zone's is the zone's element; a hybrid's is assigned per creature here, never "both by default" |
| **Drops** | Role words only (§2e.1). The item contract names the actual items |
| **Teaches** | ⭐ §2.7 — what the player walks away knowing. A real lesson, not a restatement of the stat line |

⚠️ **Ids are the snake_case of the name** and are not printed. Apostrophes and
hyphens drop: *Sky-Iron Husk* → `sky_iron_husk`, *Pilgrim's Remnant* →
`pilgrims_remnant`, *The Dictating Hand* → `the_dictating_hand`.

---

#### 2e.1 ✅ Drop roles — the five words, and nothing else

✅ **Each creature row carries a `drops` role list so the item lane and the
code lanes can join without either inventing the other's work.** ⚠️ **These are
ROLES, not items.** The item contract names every actual id; this document
never does.

| Role | Means | Who may carry it |
|---|---|---|
| `mote` | The zone element's shard/dust ladder | ⭐ **Every creature, always.** A hybrid pays both ladders at half chance each (the shipped Frostfell shape) |
| `hide` | A **kill-only** material — it exists only because something died | Commons and minis with a body worth taking something off |
| `material` | A gatherable material that also drops | Commons and minis made of stuff — stone, glass, brass, ice, wood |
| `key` | A **tier-gate part** | ⭐ **Bosses of gate zones only** — see below |
| `unique` | A boss's named equipment | Bosses only, one apiece |

⭐ **Which zones are gate zones, derived rather than invented.** `world.dart`
records the Primal gate as *"One proof from each Primal **pure-zone** boss"*.
Applying the same shape upward gives the answer for the two later tiers, and
it lands on exactly the elements each gate names:

| Gate | Named in | Supplied by |
|---|---|---|
| **Celestial Totem** (Solar · Lunar · Astral essences), at Rimeholt | `world.dart` · GAME_DESIGN §3 | **The Kiln Desert** (Solar) · **The Mirrormere** (Lunar) · **Starfall Basin** (Astral) |
| **Three Ethereal key fragments**, at the Citadel | `world.dart` · GAME_DESIGN §3 | **Hallowmarch** (Sanctus) · **The Umbral Wastes** (Umbra) · **The Collapsed Academy** (Arcane) |
| **The Concordant Crown** frame, at Zenith | `world.dart` | **The Eclipsed Citadel** — first clear, per the gazetteer |

⭐ **`key` goes on BOTH bosses of a gate zone, and that is a ruling, not a
convenience.** A run draws one boss of two (§3d). A gate part that only dropped
from the boss you did not draw would turn a mandatory progression item into a
coin flip, which is the one place the boss pool must not reach.

✅ **Confirmed against the contracts (2026-09-22):** Celestial —
`solar_essence` · `lunar_essence` · `astral_essence`, crafted into the one
`celestial_totem` that Rimeholt asks for; Ethereal — `the_kept_third`
(Hallowmarch) · `the_dark_third` (Umbral Wastes) · `the_written_third`
(Collapsed Academy). ⚠️ A `hide` role in a zone whose contract defines no
hide item resolves to the zone's second gatherable material
(ETHEREAL_CONTRACT §3.5). ⚠️ Procarius's `key` (the Crown frame) has no
item yet and drops nothing.

❓ **Superseded — for the item lane to confirm:** the essence/fragment ids themselves. The
Kinetic Sigil's mechanism was deferred once already (KINETIC_CONTRACT §8.6),
so the Celestial and Ethereal parts may land the same way — the roster says
*which boss owes one*, not what it is called.

---

#### 2e.2 ✅ Off-element moves — §2h's guardrail, given a number

§2h licenses a third element on **minis and bosses only**, **one move**,
**Celestial and Ethereal only**, and ⚠️ **never the zone's own counter** —
which is the row that matters, because a boss that punishes correct
preparation makes players stop preparing.

✅ **"Sparingly" now means three creatures in fifteen zones, named here and
nowhere else.** Each was checked against both of its zone's counters. (It was
four until The Long Count's grant was withdrawn below; the row is struck
through rather than deleted so the reasoning stays visible.)

| Zone | Creature | Off-element move | Legal because |
|---|---|---|---|
| ~~**The Buried Sky**~~ | ~~The Long Count~~ | ~~one lunar~~ | ❌ **Withdrawn 2026-09-22 (build manager).** The reasoning was inverted: the tier-3 wheel runs Solar → Lunar → Astral → Solar, so Lunar IS Astral's counter, and §2h's law wins. The Long Count is pure Astral. §2e.2 now names THREE creatures |
| **The Glass Archive** | Burnt Index | one **pyro** | Solar is countered by Astral, Arcane by Umbra. The index burned |
| **The Sealed Garden** | Cherub of the Turning Blade | one **solar** | ⚠️ **NOT pyro** — Flora's counter. The flaming sword is written as light, not fire, for exactly this reason |
| **The Collapsed Academy** | The Fourth Item | one **astral** | Arcane is countered by Umbra. The fourth item is not in any language you have |

⚠️ **The Eclipsed Citadel is exempt** — it carries all twelve, so it has no
off-element and no counter to avoid.

📝 **How the engine actually expresses this, and why "one move" is a fiction.**
`EnemyDef` has no per-spell element: a `Spell` carries damage, cost and
priority, and the creature's `elements` list is what the brain charges from.
So an off-element move is built as **an extra entry in `elements`** — the Burnt
Index ships `[solar, pyro]` (The Glass Archive) and the Cherub of the Turning
Blade ships `[sanctus, solar]` (The Sealed Garden), each alongside the ordinary
`elements: _solar` / `_sanctus` its zone-mates carry.

⚠️ **The consequence: the creature can charge the off-element on *any* of its
moves, not just the named one.** Nothing in the engine ties pyro to one
particular Burnt Index spell, and nothing could without a per-spell element
field. What the table above is really fixing is therefore **which element the
player must be able to see coming**, and the AI honours "one move" only
indirectly — by counter-picking, since a `LadderAi` rung high enough to read
the matchup will reach for the element that is currently good against you, and
that is the move the off-element shows up on.

⭐ **So read the table as a licence, not as a script.** Adding a second element
to a creature is the whole of the implementation, and the design cost of one is
that the zone's element identity blurs for that fight — which is exactly why
this section caps it at three creatures and forbids the zone's own counter. 📝
If a per-spell element is ever added, this section becomes enforceable rather
than advisory, and the three creatures above are the migration list.

---

#### The Kiln Desert · 30–34 · Solar ✅ final 2026-09-22
> *"The air is too thin to hold heat, so the sun burns while the wind bites."*

⭐ **Theme: burning and freezing at once.** The zone is a **contradiction**, not
a heat. That is what makes it Solar-at-altitude rather than a second desert.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Shadeless** | Common | **Adept** *(was Skirmisher)* | solar | mote · hide | ⭐ The yardstick. A figure the sun has taken the shadow from, fighting you perfectly straight — the only honest thing in a zone built on contradiction |
| **Sunstruck Pilgrim** ✅ | Common | **Blighter** *(was Drudge)* | solar | mote · hide | ⭐⭐ **Solar's passive is Blind, and this creature is named for sun-blindness.** It barely damages you and you lose anyway — the zone's status tutor, and the best-fitted archetype change in the pass |
| **Glasspan Crawler** | Common | **Bruiser** *(was Sentinel)* | solar | mote · material | A slab of fused salt-glass that crosses the pan without stopping. Reading the charge bar |
| **Mirage** | Common | Glasswing | solar | mote | Killing fast beats playing safe — it is barely there and it hits like the noon |
| **Kiln Moth** | Common | Lasher | solar | mote · hide | Why a big shield is not always the answer |
| **Sun Templar** ✅ | Mini | Champion | solar | mote · material | |
| **Prism Sentinel** ✅ | Mini | Redoubt | solar | mote · material | |
| **Saltmarch Wraith** | Mini | Executioner | solar | mote · hide | |
| **The Shadeless Hour** | Mini | Hexer | solar | mote | |
| **The Cold Shadow** | **Boss** | **Juggernaut** *(was Tyrant)* | solar | mote · **key** · unique | ⭐ *What the sun cannot reach.* A shadow is a **mass**, not a mind — §2g gives Tyrant to *"a person, a will, something that decided"*, and nothing decided this |
| **Solar Deity** ✅ | **Boss** | Aspect | solar | mote · **key** · unique | *The sun.* Blind taken further than the player has seen it |

⚠️ **Both bosses carry `key`** — the Totem's Solar essence (§2e.1).

#### The Mirrormere · 32–37 · Lunar ✅ final 2026-09-22
> *"The moon at a size the moon has no right to be… you are careful not to look down for too long."*

⭐ **Theme: the reflection is bigger than the thing, and it is looking back.**

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Mirror Wraith** ✅ | Common | Adept | lunar | mote · hide | The yardstick — and it is your own shape, which is the zone saying it first |
| **Stillface** | Common | **Blighter** *(was Sentinel)* | lunar | mote | ⭐ It does not hit you; it **holds** you, and what it holds it keeps. What statuses actually do |
| **Undershine** | Common | **Glasswing** *(was Siphon)* | lunar | mote | ⭐ Light moving under the surface: brilliant, and one hit from gone. ⚠️ **Siphon cut** — nothing in this zone drinks, it only reflects (§2f) |
| **Ripplecut** | Common | Skirmisher | lunar | mote | Priority — it crosses the surface before you have finished looking at it |
| **Palefish Shoal** | Common | Lasher | lunar | mote · hide | Shields chip rather than shatter |
| **The Second You** | Mini | Champion | lunar | mote · hide | |
| **Herald of the Waxing** ✅ | Mini | Redoubt | lunar | mote · material | |
| **Stalker of the New Moon** ✅ | Mini | Executioner | lunar | mote · hide | |
| **The Waning Wraith** ✅ | Mini | Hexer | lunar | mote | |
| **The Moon Below** | **Boss** | Tyrant | lunar | mote · **key** · unique | *The moon in the water* — and it is **looking back**, which is a mind, which is a Tyrant |
| **Luna Plena, the Full Moon** ✅ | **Boss** | Aspect | lunar | mote · **key** · unique | *The moon above.* 💡 Banked: fightable only on a Full Moon turn |

⭐ **Which one is real is the fight.** ⚠️ Both bosses carry `key` — the Totem's
Lunar essence.

#### Starfall Basin · 34–39 · Astral ✅ final 2026-09-22
> *"At night the sky is so clear it looks like a threat."*

⭐ **Theme: things fell here, and the sky is still aiming.**

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Crater Revenant** ✅ | Common | **Adept** *(was Bruiser)* | astral | mote · hide | ⭐ The yardstick, and it is a **person who came back** — the honest fight in a zone where everything else arrived at terminal velocity |
| **Sky-Iron Husk** | Common | Sentinel | astral | mote · material | Shield-breaking. ⭐ One of the seven Sentinels kept: it is literally iron |
| **Fallpoint** | Common | Glasswing | astral | mote | Killing fast beats playing safe |
| **Scatterling** | Common | Lasher | astral | mote · material | Damage in pieces |
| **Cold Ejecta** | Common | Skirmisher | astral | mote · material | Priority — it was already moving |
| **The Zodiac Ascendant** ✅ | Mini | Champion | astral | mote · material | |
| **Constellation Warden** ✅ | Mini | Redoubt | astral | mote · material | |
| **Rift Walker** ✅ | Mini | Executioner | astral | mote | |
| **Echo of the Between** ✅ | Mini | Hexer | astral | mote | |
| **The Next One** | **Boss** | Juggernaut | astral | mote · **key** · unique | *Enormous, and still inbound* |
| **What Landed** | **Boss** | Tyrant | astral | mote · **key** · unique | *Small, and already at the bottom of a crater* |

⭐ **NOT a mirror — the same thing at two scales** (§2f). Drawing the small one
is a **warning about the big one**. ⚠️ Both carry `key` — the Totem's Astral
essence.

#### Tidewrack Shoals · 36–40 · Lunar + Aqua ⭐ hybrid ✅ final 2026-09-22
> *"Everything is timed to something overhead."*

⭐ **Theme: the sea is on a schedule it did not choose, and it keeps uncovering
things.** The fusion is **obedience** — Aqua doing what Lunar says.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Tidewrack Drowned** ✅ | Common | **Adept** *(was Drudge)* | lunar + aqua | mote · hide | ⭐ The yardstick. ⚠️ **A Drudge at level 38 was a wasted encounter slot** (§2f); the drowned still fight the way they fought, which is worse |
| **Wrackcrab** | Common | Sentinel | aqua | mote · material | Shield-breaking. ⭐ A shell is §2b's own example, so this is one of the seven Sentinels kept |
| **Lowwater Thing** | Common | **Blighter** *(was Siphon)* | aqua | mote | ⭐ What the tide leaves standing in the warm shallow. ⚠️ **Siphon cut** — the zone's idea is a schedule, not an appetite (§2f) |
| **Gullbone Flock** | Common | Lasher | lunar | mote · hide | ⭐ Lunar, not Aqua: the flock is **timed to something overhead**, which is the whole theme |
| **Spindrift** | Common | **Skirmisher** *(was Glasswing)* | aqua | mote | ⭐ §2b: *darts, skims, flits → Skirmisher*. Spray off a wave top literally skims |
| **Tidal Empress** ✅ | Mini | Champion | lunar + aqua | mote · material | |
| **Leviathan** ✅ | Mini | Redoubt | aqua | mote · hide | *(re-homed)* |
| **Maelstrom Horror** ✅ | Mini | Executioner | aqua | mote · hide | |
| **The Turning** | Mini | Hexer | lunar | mote | ⭐ The moment the tide changes — a Hexer's clock, stated as fiction |
| **Kraken** ✅ | **Boss** | Juggernaut | aqua | mote · unique | *What the tide uncovers* — a mass from the deep |
| **The Undertow** | **Boss** | Aspect | lunar | mote · unique | ⭐⭐ *What it takes back.* **The undertow is not the water, it is the pull — and the pull is the moon.** Lunar taken to an extreme: the moon decides when you may act |

⭐ **The boss pool is the hybrid's two elements, one each**, which is the
cleanest possible statement of "Aqua doing what Lunar says."

#### The Sunless Reach · 38–42 · Solar + Lunar ⭐ hybrid ✅ final 2026-09-22
> *"The rock is the same rock. The desert is a thousand feet away and on the other side of the world."*

⭐⭐ **Theme: identical ground, opposite worlds, one line between them.** The
fusion is **a boundary, not a blend**.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Eclipse Herald** ✅ | Common | Adept | solar + lunar | mote · hide | The yardstick, and the only thing here that stands on both sides |
| **Crestline Warden** | Common | **Bruiser** *(was Sentinel)* | solar | mote · material | ⭐ It does not hold the line, it **shoves you back over it** — which is a boundary zone's premise expressed as a stat block |
| **Nightglare** | Common | **Blighter** *(was Glasswing)* | solar | mote | ⭐⭐ Solar's passive is **Blind**, and a glare that follows you into a valley that has never been lit is the purest version of it |
| **Coldlight Swarm** | Common | Lasher | lunar | mote | Damage in pieces |
| **Shadowpitch Stalker** | Common | Skirmisher | lunar | mote · hide | Priority |
| **Solar Archon** ✅ | Mini | Champion | solar | mote · material | |
| **The Crest** | Mini | Redoubt | solar + lunar | mote · material | ⭐ The ridge itself — the only creature that IS the line |
| **Both-Sided Thing** | Mini | Executioner | solar + lunar | mote · hide | |
| **Duskmarch** | Mini | Hexer | lunar | mote | |
| **The Last Light** | **Boss** | Aspect | solar | mote · unique | |
| **The First Dark** | **Boss** | Aspect | lunar | mote · unique | |

⚠️ **The only zone with two Aspects, and it is kept deliberately** (§2g). Its
premise is identical ground on two sides of a line, so *the same archetype in
two elements* **is** the mechanical statement of the theme.

#### The Shattered Orrery · 40–44 · Astral + Electro ⭐ hybrid · 🏰 ✅ final 2026-09-22
> *"Something is being calculated and has been for a very long time."*

⭐ **Theme: a broken machine still computing, and nobody knows what toward.**
The fusion is **the heavens as mechanism** — Electro is the power, Astral is
what it is modelling.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Orrery Automaton** ✅ | Common | **Adept** *(was Sentinel)* | astral + electro | mote · material | ⭐⭐ **A machine executing a correct program is the definition of a straight, competent game.** The yardstick was always standing here; it was labelled a wall |
| **Gear-Ghost** | Common | Glasswing | astral | mote | Killing fast beats playing safe |
| **Armature** | Common | Bruiser | electro | mote · material | Reading the charge bar |
| **Arcflock** | Common | Lasher | electro | mote | Shields chip rather than shatter |
| **Errant Ring** | Common | Skirmisher | astral | mote · material | Priority — it came loose a long time ago and has not stopped |
| **Sidereal Fault** | Mini | Champion | astral | mote · material | |
| **Escapement** | Mini | Redoubt | electro | mote · material | |
| **Long Division** | Mini | Executioner | astral + electro | mote | |
| **The Remainder** | Mini | Hexer | astral | mote | |
| **The Calculation** | **Boss** | Juggernaut | electro | mote · unique | *The process* — it grinds, and it has been grinding |
| **The Answer** | **Boss** | Tyrant | astral | mote · unique | *The result* — ⭐ **drawing the Answer means it finished** |

⭐ **The archetypes ARE the premise** (§2g) — and the elements now say it too:
the Juggernaut is the power, the Tyrant is what the power was for.

#### The Glass Archive · 43–47 · Solar + Arcane ⭐ hybrid · 🏰 ✅ final 2026-09-22
> *"They wrote it in light, and light does not keep."* (WORLD_DESIGN §4c.1c)

⭐ **Theme: an archive readable only at noon, which the reading destroys.**
⚠️ **Deliberately the opposite of The Buried Sky** — light that keeps nothing
against stone that keeps everything. Do not "fix" the pairing.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Glasswright** ✅ | Common | **Adept** *(was Sentinel)* | solar + arcane | mote · material | ⭐ A **wright** is a maker, and a maker fights you straight. The zone's anchor name becomes its yardstick |
| **Noonmark** | Common | Glasswing | solar | mote | Killing fast beats playing safe — at noon it is everything, and then it is not |
| **Palimpsest** | Common | **Blighter** *(was Siphon)* | arcane | mote · material | ⭐ A page scraped clean and rewritten **writes over you** — that is a status, not a drink. ⚠️ Siphon cut (§2f) |
| **Readerless** | Common | **Lasher** *(was Drudge)* | arcane | mote · material | ⭐ Loose unread leaves arrive all at once. 📝 **Rename proposed: *Loose Quire*** — a quire is a gathering of leaves, which is a Lasher said in one archaic word. Old name kept here so the change stays visible |
| **Lensfly** | Common | Skirmisher | solar | mote | Priority |
| **The Last Reader** | Mini | Champion | solar + arcane | mote · hide | |
| **Aperture** | Mini | Redoubt | solar | mote · material | |
| **Burnt Index** | Mini | Executioner | solar | mote · material | ⚠️ Carries the zone's **one off-element move** — pyro (§2e.2) |
| **The Marginalia** | Mini | Hexer | arcane | mote | |
| **What Was Written** | **Boss** | Tyrant | arcane | mote · unique | *A mind, and it wrote this down* |
| **What Is Left Of It** | **Boss** | Aspect | solar | mote · unique | ⭐ **Blind taken to an extreme is the theme, mechanised** — the Aspect destroys the reading by being too bright to read by |

---

### Ethereal · 45–60

#### Hallowmarch · 45–49 · Sanctus ✅ final 2026-09-22
> *"Every mile or so there is a marker, and every marker has been maintained."*

⭐ **Theme: someone is still doing the upkeep, and nobody has seen them.**
⚠️ **Load-bearing:** the causeway leads to The Sealed Garden, and the same oath
maintains both. Changing this theme breaks that zone too.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Causeway Warden** ✅ | Common | Sentinel | sanctus | mote · material | ⭐ One of the seven Sentinels kept: a warden on a road **is** a barrier, and this is the zone's anchor name |
| **Marker-Sworn** | Common | Adept | sanctus | mote · hide | The yardstick — someone who swore to keep the markers and is keeping them |
| **Meltwater Choir** | Common | Lasher | sanctus | mote | Damage in pieces |
| **Votive** | Common | Glasswing | sanctus | mote | ⭐ A small flame is one good hit from out, and one good hit from everything |
| **Pilgrim's Remnant** | Common | **Bruiser** *(was Drudge)* | sanctus | mote · hide | ⚠️ **A Drudge at level 47 was the clearest waste in the audit** (§2f). 📝 **Rename proposed: *Pilgrim's Weight*** — the Bruiser is the pack, not the person, and it is still coming up the road. Old name kept here so the change stays visible |
| **Milestone** | Mini | Champion | sanctus | mote · material | |
| **Vestal Warden** ✅ | Mini | Redoubt | sanctus | mote · material | |
| **Seraph Judicant** ✅ | Mini | Executioner | sanctus | mote · hide | |
| **The Upkeep** | Mini | Hexer | sanctus | mote | ⭐ Something that has been doing a small thing to you for a very long time |
| **The Keeper of the Road** | **Boss** | Juggernaut | sanctus | mote · **key** · unique | *Who still does it* |
| **The Hierophant Eternal** ✅ | **Boss** | Tyrant | sanctus | mote · **key** · unique | *Who ordered it* |

⚠️ **Both bosses carry `key`** — one of the three Ethereal fragments (§2e.1).

#### The Buried Sky · 46–50 · Geo + Astral ⭐ hybrid · 🏰 ✅ **designed 2026-09-22**

> ⭐ **Theme: the rock remembers a sky that no longer exists.**

**Premise.** The Vault is the highest rock in the world, so its exposed strata
are the oldest anywhere — and you climb to the top of everything in order to go
**down**. Each band of stone you break through holds a scatter of light set in
it, and **none of the patterns match what is overhead now**. The zone is not
haunted and nothing here is angry. It is a record, and the record disagrees
with the sky.

**⭐ Why this theme.** Geology is deep time; Astral is the heavens. Neither
states the premise alone: Geo supplies the **layers**, Astral supplies the
**heavens**, and the idea only exists when the two are read together — which
is the bar §2d sets for a hybrid (*"if the theme still makes sense with one
element removed, it is not a hybrid theme yet"*). ⭐ **Its claim is SCALE**, and
that is what the Ethereal quarter was missing: the other late zones make claims
about accord and about contest; this one says *this has all happened before, and
the record is in the rock.* ⚠️ **Deliberately the opposite of The Glass
Archive** (43–47) — stone that keeps everything against light that keeps
nothing. Stated in both places so nobody "fixes" the overlap later.

| Creature | Rank | Archetype | Element | Drops | Lore line | Teaches |
|---|---|---|---|---|---|---|
| **Stratum Warden** ✅ | Common | Sentinel | geo | mote · material | Stone laid down in bands, each one a different colour and a different age, standing across the shaft in the order it was made | ⭐ Shield-breaking — and that you get through it **one age at a time**, which is the zone's clock |
| **Constellate** | Common | Lasher | astral | mote | A scatter of star-points that does not hold still long enough to be a figure, and arrives before you have finished counting it | Why a big shield is not always the answer: it comes in pieces |
| **Fadelight** | Common | Glasswing | astral | mote | The last light of a star that went out before any of this rock was laid down, still arriving, still on time | ⭐ Killing fast beats playing safe — it is already gone and it can still end you |
| **Corebiter** | Common | **Bruiser** *(was Siphon)* | geo | mote · material | A blunt, patient thing that goes through a seam the way water goes through a crack, only slower and with teeth | Reading the charge bar. ⚠️ **Siphon cut** — it eats rock, not you (§2f) |
| **Deadreckoner** | Common | Adept | geo + astral | mote · hide | It navigates by stars that no longer exist and is still mostly right, which is worse than being wrong | ⭐ The yardstick — the honest fight, run on out-of-date information |
| **Stonefall Herald** | Mini | Champion | geo + astral | mote · material | It arrives a little before the rock does, every time, and has never once been early for anything else | A clean skill check |
| **Bedrock Colossus** | Mini | Redoubt | geo | mote · material | The last layer, the one with nothing under it, standing up | Attrition — there is no going around it |
| **Nadir** | Mini | Executioner | geo | mote · material | The lowest point of the shaft, which is a place and is also looking at you | One misplay ends you |
| **The Long Count** | Mini | Hexer | astral | mote | A tally kept in a notation nobody now reads, still being added to, and the number is about you | It punishes a bad loadout. *(The lunar off-element grant was withdrawn 2026-09-22 — it was Astral's own counter.)* |
| **The Overburden** ✅ | **Boss** | Juggernaut | geo | mote · unique | ⭐ *What buries.* A real mining term for the rock sitting on top of a seam, and it happens to mean exactly the right thing | Endurance — it is not fast and it does not need to be |
| **The Buried Constellation** ✅ | **Boss** | Aspect | astral | mote · unique | ⭐ *What survives.* An old star-pattern still alight down here, refusing to be past tense | **Astral Alignment taken to an extreme**: by the end, the shield you are holding is not where the damage is going |

⭐ **Which boss you draw says whether the zone is about what buries or what
lasts.** The hybrid rule (§2d), and the elements carry it: Geo buries, Astral
survives.

##### Move kits — The Buried Sky

⚠️ **Counts and cost bands are the archetype's, verbatim**
(`enemy_archetype.dart`). Names are **verbs** (§3.3a) — the log narrates
*"the stratum warden beds in"*, and the noun form is what the bestiary shows.
Ids are zone-tagged `bs_*`.

| Creature | Moves | Kit |
|---|---|---|
| **Stratum Warden** | 2 · cost 2–4 | **Lay Down Another Band** (2 · pri 9 · `DamageEffect`) · **Bed In** (4 · pri 3 · `ShieldEffect`) — ⭐ slow on purpose: the shield is the expensive move, so it telegraphs |
| **Constellate** | 2 · cost 1–3 | **Scatter** (1 · pri 8 · `DamageEffect(hits: 3)`) · **Draw the Figure** (3 · pri 9 · `DamageEffect(hits: 4)`) |
| **Fadelight** | 2 · cost 1–3 | **Flicker** (1 · pri 5 · `DamageEffect`) · **Arrive Late** (3 · pri 9 · `DamageEffect`, the band's top) — ⭐ the name is the physics |
| **Corebiter** | 2 · cost 2–5 | **Bore In** (2 · pri 9 · `DamageEffect`) · **Take the Whole Seam** (5 · pri 9 · `DamageEffect`) — nothing cheap, so it must charge |
| **Deadreckoner** | 3 · cost 1–3 | **Sight It** (1 · pri 9 · `DamageEffect`) · **Hold the Bearing** (3 · pri 9 · `DamageEffect`) · **Set the Mark** (2 · pri 3 · `ShieldEffect`) — ⭐ the Adept's honest kit: cheap hit, big hit, one shield |
| **Stonefall Herald** | 3 · cost 1–4 | **Call It Down** (1 · pri 5 · `DamageEffect`) · **Bring the Face Away** (4 · pri 9 · `DamageEffect`) · **Brace the Shaft** (3 · pri 3 · `ShieldEffect`) |
| **Bedrock Colossus** | 3 · cost 2–4 | **Settle** (2 · pri 9 · `DamageEffect`) · **Take the Weight** (4 · pri 3 · `ShieldEffect`) · **Close the Seam** (3 · pri 9 · `DamageEffect(lifesteal: 0.4)`) — ⭐ the Redoubt's heal, using the lever the engine actually has |
| **Nadir** | 2 · cost 3–5 | **Bottom Out** (3 · pri 9 · `DamageEffect`) · **Finish the Descent** (5 · pri 9 · `DamageEffect(executeBelowPercent: 30)`) — ⭐⭐ the Executioner's lesson written into the effect |
| **The Long Count** | 3 · cost 1–3 | **Mark the Age** (1 · pri 4 · `DamageEffect`) · **Count Back** (2 · pri 1 · `DamageEffect`) · **Older Than the Sky** (3 · pri 2 · `DamageEffect(ignoresShields: true)`) — ⭐ the Hexer's signature is priority, not status: it lands before your shield does |
| **The Overburden** | 3 · cost 3–5 | **Press Down** (3 · pri 9 · `DamageEffect`) · **Pack the Roof** (4 · pri 3 · `ShieldEffect`) · **Bring the Whole Column** (5 · pri 9 · `DamageEffect`) |
| **The Buried Constellation** | 3 · cost 1–4 | **Still Alight** (1 · pri 9 · `DamageEffect`) · **Rise Where It Should Not** (2 · pri 9 · `DamageEffect(ignoresShields: true)`) · **The Pattern Holds** (4 · pri 9 · `DamageEffect(hits: 3, ignoresShields: true)`) — ⭐ **the Aspect's whole kit walks through shields**, because that is what Astral Alignment does, taken further than the player has met it |

#### The Umbral Wastes · 47–51 · Umbra ✅ final 2026-09-22
> *"Not dusk — an absence with an edge to it… the ice holds its shape like something that has been thought about."*

⭐ **Theme: the dark here is deliberate. Something decided its shape.** Not
absence — **design**. ⭐ **Deliberate rhyme with Old Quarry (15–19), not a
repeat** — there something was **removed** and the hole is animate; here dark
was **imposed** and given a shape.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Umbral Devourer** ✅ | Common | **Siphon** | umbra | mote · hide | ⭐ **One of the three zones the Siphon is kept in** (§2f): it is named for eating and the dark here consumes by design. Chip damage never accumulates — commit to burst |
| **Edgewalker** | Common | **Adept** *(was Skirmisher)* | umbra | mote · hide | ⭐ The yardstick. It walks the edge of the absence and fights you completely straight, which in this zone is the strangest thing in it |
| **Considered Ice** | Common | Sentinel | umbra | mote · material | ⭐ One of the seven Sentinels kept: ice that holds its shape **because it was decided** is a wall with a reason |
| **Nightspill** | Common | Blighter | umbra | mote | ⭐ Umbra's passive is **Creeping Dark**, the only element status built to stack — this is the creature that teaches it |
| **Thoughtform** | Common | Glasswing | umbra | mote | Killing fast beats playing safe — it is a shape somebody held in mind, and it has the substance of one |
| **Umbral Knight** ✅ | Mini | Champion | umbra | mote · material | |
| **The Edge** | Mini | Redoubt | umbra | mote · material | |
| **Void Stalker** ✅ | Mini | Executioner | umbra | mote · hide | |
| **Eclipse Weaver** ✅ | Mini | Hexer | umbra | mote | |
| **Nightbringer** ✅ | **Boss** | Tyrant | umbra | mote · **key** · unique | *Who made it dark* — a will, which is what a Tyrant is for |
| **What Was Thought About** | **Boss** | Aspect | umbra | mote · **key** · unique | *The shape it was given.* Creeping Dark taken to an extreme |

⚠️ **Both bosses carry `key`** — one of the three Ethereal fragments (§2e.1).

#### The Sealed Garden · 49–53 · Flora + Sanctus ⭐ hybrid ✅ **designed 2026-09-22**

> ⭐ **Theme: the garden is still perfect, it is still guarded, and you are
> still not allowed in.**

**Premise.** ✅ Christian's call is to play the Eden reference **heavy-handed** —
the zone *is* the garden and should be recognised as such within seconds. ⭐
**The turn that makes it more than a costume: the religion that set the guard is
gone.** Nobody has come to relieve the watch in an age, and the watch has not
noticed. ⚠️ **The guardians are not defending a faith. They are keeping a
promise that outlived everyone who cared about it.** That is a colder idea than
"overgrown temple", and it is the version the roster is written to.

**⭐ Why this theme.** It closes a 45-level loop: the first thing the game
teaches is that the wood in Whispering Woods is **one aware organism** (§2d);
meeting that same awareness at level 50, having outlasted a religion, is the
payoff for a lesson learned at level 1. ⭐ **And it is the proof the accord
already happened once** — a place where the twelve agreed, and which was then
shut, which reframes the Concordant Crown as *restoring* rather than inventing.
The hybrid test passes both ways: with Sanctus removed it is a garden, with
Flora removed it is a temple, and **only together** is it consecration a garden
outlived.

⚠️ **Guardrails, carried forward from WORLD_DESIGN §4c.1a and binding on the
build:** use the **roles** — Gardener, Guardian, Serpent, Vow — and never name
real religious figures or quote text. 🚫 **"Bloom" is reserved** (renamed to
Photosynthesis project-wide); no creature or move here may use it. ⚠️ **The
Sanctus naming trap:** a Sanctus name that could plausibly be Solar is the
wrong name — gates, orchards, vows and wardens carry no sun imagery, which is
why they were chosen.

| Creature | Rank | Archetype | Element | Drops | Lore line | Teaches |
|---|---|---|---|---|---|---|
| **Orchard Warden** ✅ | Common | Sentinel | sanctus | mote · material | Set at the foot of one tree to watch it, and has watched it long enough that the bark has grown around where it stands | ⭐ Shield-breaking — and one of the seven Sentinels kept, because *rooted and set to guard* is §2b's own definition |
| **Windfall** | Common | **Siphon** | flora | mote · material | Fruit already on the ground, perfect, unbruised, and warmer than fruit on the ground has any business being | ⭐⭐ **One of the three zones the Siphon is kept in** (§2f) — *the temptation, written as a stat block*. Chip damage never accumulates; commit to burst |
| **Whisperling** | Common | Blighter | flora | mote · hide | A small coiled thing high in the branches that talks, pleasantly, and offers you something you had not thought to want | What statuses actually do — it barely touches you and you lose anyway |
| **Chorister Vine** | Common | Adept | flora + sanctus | mote · material | A vine still singing the hours to an empty cloister, on time, in a form of the office nobody has used in an age | ⭐ The yardstick — and it is the one creature in the garden doing its job correctly |
| **Thornpenitent** | Common | Bruiser | flora + sanctus | mote · hide | A briar that grew through and around someone kneeling, and kept the posture after there stopped being a reason for it | Reading the charge bar |
| **The Last Gardener** | Mini | Champion | flora + sanctus | mote · hide | The only mortal still inside, and ⭐ **not hostile until you reach for anything** | A clean skill check |
| **Root Matriarch** ✅ | Mini | Redoubt | flora | mote · material | The oldest stock in the orchard, and every other tree here is a runner off it | Attrition |
| **Cherub of the Turning Blade** | Mini | Executioner | sanctus | mote · material | ⭐ The flaming sword that turns every way — the single most recognisable image in the myth, and it has never stopped turning | One misplay ends you. ⚠️ Carries the zone's **one off-element move** — **solar, never pyro** (§2e.2) |
| **The Kept Vow** | Mini | Hexer | sanctus | mote | An oath with a body. Nobody remembers the wording and it has not needed to be reminded | It punishes a bad loadout, not bad reflexes |
| **Guardian of the World Tree** ✅ | **Boss** | Juggernaut | sanctus | mote · unique | ⭐ **The rule.** It will not let you in. Not angry, not negotiating | Endurance — a wall does not need a plan |
| **The Serpent in the Branches** | **Boss** | Tyrant | flora | mote · unique | ⭐ **The invitation.** It would very much like to let you in | ⭐ The intelligence is the threat — §2g: *the rule is a wall you must get through; the tempter's threat is that it plays well* |

⭐ **Which boss you draw decides whether the garden confronts you or tempts
you** — the Ashfall Vale pattern landing at the opposite end of the game. ⭐
**And the elements carry it:** Sanctus is the rule, Flora is the garden doing
the asking.

⚠️ **Do not seal the zone after clearing it.** The myth's ending is *"you may
not come back"*, but §4b makes resource areas a standing reason to return. ⭐
**Put the expulsion in the Tier-1 clear passage instead:** you beat the Guardian
and the game still does not let you take the tree. The beat lands; the content
stays repeatable.

##### Move kits — The Sealed Garden

Ids are zone-tagged `sg_*`.

| Creature | Moves | Kit |
|---|---|---|
| **Orchard Warden** | 2 · cost 2–4 | **Close the Row** (2 · pri 9 · `DamageEffect`) · **Keep the Watch** (4 · pri 3 · `ShieldEffect`) |
| **Windfall** | 2 · cost 1–3 | **Draw Up** (1 · pri 9 · `DamageEffect(lifesteal: 0.5)`) · **Take the Whole Hand** (3 · pri 9 · `DamageEffect(lifesteal: 0.6)`) — ⭐ both moves heal it; there is no safe chip |
| **Whisperling** | 2 · cost 1–2 | **Suggest It** (1 · pri 9 · `DotAttackEffect(2,4, dotId:'sg_suggestion', dotName:'Suggestion', damagePerTick: 4, ticks: 3)`) · **Keep Talking** (2 · pri 9 · `DotAttackEffect(4,6, dotId:'sg_suggestion', dotName:'Suggestion', damagePerTick: 5, ticks: 5)`) — ⭐ same `dotId`, two price points, so the second replaces the first (`bank_dots.dart` law) |
| **Chorister Vine** | 3 · cost 1–3 | **Take Up the Hour** (1 · pri 9 · `DamageEffect`) · **Sing It Through** (3 · pri 9 · `DamageEffect`) · **Close the Office** (2 · pri 3 · `ShieldEffect`) |
| **Thornpenitent** | 2 · cost 2–5 | **Kneel Into It** (2 · pri 9 · `DamageEffect`) · **Bear the Whole Penance** (5 · pri 9 · `DamageEffect`) |
| **The Last Gardener** | 3 · cost 1–4 | **Prune** (1 · pri 5 · `DamageEffect`) · **Turn the Bed Over** (4 · pri 9 · `DamageEffect`) · **Put It Back** (3 · pri 3 · `ShieldEffect`) |
| **Root Matriarch** | 3 · cost 2–4 | **Put Down a Runner** (2 · pri 9 · `DamageEffect`) · **Thicken** (3 · pri 3 · `ShieldEffect`) · **Draw From the Whole Orchard** (4 · pri 9 · `DamageEffect(lifesteal: 0.4)`) |
| **Cherub of the Turning Blade** | 2 · cost 3–5 | **Turn Every Way** (3 · pri 9 · `DamageEffect(hits: 2)`) · **Come Down Once** (5 · pri 9 · `DamageEffect`, **solar** — the off-element) |
| **The Kept Vow** | 3 · cost 1–3 | **Hold You To It** (1 · pri 4 · `DamageEffect`) · **Say It Back** (2 · pri 1 · `DamageEffect`) · **The Vow Does Not Lapse** (3 · pri 2 · `DamageEffect(ignoresShields: true)`) |
| **Guardian of the World Tree** | 3 · cost 3–5 | **Bar the Way** (3 · pri 9 · `DamageEffect`) · **Root the Gate** (4 · pri 3 · `ShieldEffect`) · **You Are Not Allowed In** (5 · pri 9 · `DamageEffect`) — ⭐ the theme, as a move |
| **The Serpent in the Branches** | 3 · cost 1–5 | **Lean Closer** (1 · pri 5 · `DamageEffect`) · **Name What You Want** (2 · pri 8 · `DischargeEffect`) · **Say Yes** (5 · pri 9 · `DamageEffect`, the band's top) — ⭐⭐ **the tempter takes your charge, not your health**: `DischargeEffect` is the mechanical form of "you were saving that for something" |

#### The Collapsed Academy · 50–54 · Arcane · 🏰 · Empyrean ✅ final 2026-09-22
> *"Not ruined so much as unfinished in the wrong direction… the last three items on the syllabus are not in any language you have."*

⭐ **Theme: it was not destroyed — it was continued past the point where
building makes sense.** ⚠️ **Over-completion, not ruin**, and that distinction
is the whole zone.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Unfinished Scholar** ✅ | Common | Adept | arcane | mote · hide | The yardstick |
| **Stairhead** | Common | **Bruiser** *(was Sentinel)* | arcane | mote · material | ⭐ A flight of stone that arrives where a room should be and keeps arriving. Reading the charge bar |
| **Chalkwraith** | Common | Skirmisher | arcane | mote | Priority |
| **Marginal Note** | Common | Blighter | arcane | mote | What statuses actually do |
| **Emeritus** | Common | **Glasswing** *(was Drudge)* | arcane | mote · hide | ⭐⭐ **An emeritus is someone still here past their time: brittle, and with one catastrophic thing left in them.** ⚠️ A Drudge at level 52 was a wasted slot (§2f); the name's joke survives the fix intact |
| **The Fourth Item** | Mini | Champion | arcane | mote | ⚠️ Carries the zone's **one off-element move** — astral (§2e.2) |
| **Mana Golem** ✅ | Mini | Redoubt | arcane | mote · material | |
| **Arcane Chimera** ✅ | Mini | Executioner | arcane | mote · hide | |
| **Spell Weaver** ✅ | Mini | Hexer | arcane | mote | |
| **The Archmage** ✅ | **Boss** | Tyrant | arcane | mote · **key** · unique | *Who read too far* — ⭐ a **mage**: draws from `Spellbook`, not a creature kit (§3.4) |
| **The Last Three Items** | **Boss** | Aspect | arcane | mote · **key** · unique | *What they read.* ⭐ Arcane Knowledge taken to an extreme — it gets stronger every turn you let it live |

⚠️ **Both bosses carry `key`** — one of the three Ethereal fragments (§2e.1).

#### The Reliquary Deep · 52–56 · Sanctus + Umbra ⭐ hybrid · 🏰 ✅ final 2026-09-22
> *"Someone consecrated it and someone else did not leave it alone. It is warmer in the middle than at either end."*

⭐ **Theme: two hands worked on this, and the second has not finished.**
⭐ **The warmth in the middle is the tell** — the corridor is not empty.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **Reliquary Keeper** ✅ | Common | **Adept** *(was Sentinel)* | sanctus | mote · material | ⭐ The yardstick, and the one thing in the corridor still doing the job it was left |
| **Censer-Wraith** | Common | **Blighter** *(was Glasswing)* | umbra | mote | ⭐⭐ §2b: *spores, fumes, venom → Blighter.* A censer is smoke, and **Umbra's Creeping Dark is the status that hides the board** — the fiction and the passive are the same thing |
| **The Unleft** | Common | **Glasswing** *(was Blighter)* | umbra | mote | ⭐ What did not leave: a residue with almost nothing to it, and everything behind it |
| **Bone-Reliquary** | Common | Bruiser | sanctus | mote · material | Reading the charge bar |
| **Corridor Crawler** | Common | **Skirmisher** *(was Siphon)* | sanctus + umbra | mote · hide | ⭐ It comes down the warm part of the corridor first. ⚠️ **Siphon cut** — this zone's idea is unfinished work, not appetite (§2f) |
| **Antechoir** | Mini | Champion | sanctus | mote · material | |
| **Reliquary Colossus** ✅ | Mini | Redoubt | sanctus | mote · material | |
| **The Second Hand** | Mini | Executioner | umbra | mote | ⭐ The one that did not leave it alone, and is quick about it |
| **Warm Middle** | Mini | Hexer | sanctus + umbra | mote | ⭐ The tell from the arrival line, given a stat block |
| **What Was Consecrated** | **Boss** | Juggernaut | sanctus | mote · unique | |
| **What Did Not Leave It Alone** | **Boss** | Tyrant | umbra | mote · unique | |

⭐⭐ **Both boss names are lifted straight from the arrival line, and the
elements split on the same seam** — Sanctus is the first hand, Umbra is the
second.

#### The Unwritten Library · 54–58 · Umbra + Arcane ⭐ hybrid · 🏰 · Empyrean ✅ final 2026-09-22
> *"Every book here is being written right now, by nobody… it would like your name for the record."*

⭐ **Theme: it is still writing, and it wants you in it.** The fusion is
**authorship with no author** — Arcane supplies the writing, Umbra supplies the
nobody.

| Creature | Rank | Archetype | Element | Drops | Teaches / note |
|---|---|---|---|---|---|
| **The Dictating Hand** ✅ | Common | Adept | umbra + arcane | mote · hide | The yardstick |
| **Blankspine** | Common | **Glasswing** *(was Sentinel)* | umbra | mote · material | ⭐ A book with nothing written in it is the easiest thing in the room to destroy and the worst thing to open |
| **Footnote** | Common | Lasher | arcane | mote | Damage in pieces — and there are always more of them |
| **Erratum** | Common | Skirmisher | arcane | mote | Priority — it corrects you before you have finished being wrong |
| **Ink-Drinker** | Common | **Siphon** | umbra | mote · hide | ⭐ **One of the three zones the Siphon is kept in** (§2f): the zone's entire premise is that this place **feeds on you** — it would like your name for the record |
| **The Index** | Mini | Champion | arcane | mote · material | |
| **Colophon** | Mini | Redoubt | arcane | mote · material | |
| **Redaction** | Mini | Executioner | umbra | mote | |
| **The Amanuensis** | Mini | Hexer | umbra + arcane | mote · hide | |
| **The Record** | **Boss** | Juggernaut | arcane | mote · unique | *What is written* — and it is not finished, and it is not short |
| **The Author** | **Boss** | **Aspect** *(was Tyrant)* | umbra | mote · unique | ⭐⭐ **The single best archetype change in this pass.** §2g gives Tyrant to *"a person, a will, something that decided"* — and this zone's premise is that **there is no author**. An Aspect is the element embodied, and Umbra's Creeping Dark taken to an extreme is *writing done by nobody, in the dark, about you* |

❓ **The repeat-clear third boss, *Your Entry*, still has no archetype.** It is
the player's own build written down, gated on
`PlayerProfile.hasCleared('the_unwritten_library')`. 📝 **Recommendation:
Tyrant** — a mind that plays well, because it is playing your game. ⚠️ Not an
Aspect, which is now taken by The Author and means something specific here.

#### ⚠️ The Eclipsed Citadel · 58–60 · all twelve · 🏰 · Empyrean ✅ **designed 2026-09-22**

> *"The Citadel is between you and it. That is what the name has always meant."*

⭐ **Theme: the last thing in the way.** Not a place — an **obstruction**.

**Premise.** Below it, through a gap in nothing, is the summit of the mountain
you could not climb. Everything in the Citadel exists to be between you and
that, and it is built out of the whole world to do it. Difficulty starts at
100% and scales without a fixed ceiling; the first clear drops the Crown with
twelve empty gem slots.

##### ✅ Reversal — the Citadel DOES use the 5 / 4 / 2 template

⛔ **§2e previously proposed abandoning the template**, on the grounds that a
flat roster of five commons cannot express twelve elements. ✅ **That is
withdrawn.** The template is kept, and the twelve are carried **inside** it, by
making **each rank spend the twelve a different way**. ⭐ Three reasons this is
the better answer:

1. ⭐ **It is still the game replaying itself** — the idea §2e wanted — but
   structural rather than a grab-bag of echoes.
2. ⭐ **It stays buildable by the same lane and the same tests.** The roster
   laws (5/4/2, one of each mini archetype, exactly one Adept, archetype tier
   matches rank) all hold, so the Citadel needs no bespoke test file.
3. ⚠️ **A bespoke finale structure is the kind of thing that ships last and
   ships broken.** The template is the reason the other 25 zones are cheap.

##### ⭐ The twelve, three times — the structure in one table

| Rank | How it spends the twelve |
|---|---|
| **Commons** | ⭐ **The macro-tier loop, walked once.** Four commons carry one **macro-tier counter edge** each (`element.dart`: Kinetic ▸ Primal ▸ Ethereal ▸ Celestial ▸ Kinetic), one element from each side. The fifth — the Adept — carries **the four left over, one per tier**. Twelve elements, each exactly once |
| **Minis** | ⭐ **The four quarters the player walked**, by their own names from the gazetteer: the basin, the range, the high shelf, the climb. Each carries its quarter's three elements, and each is a different mini archetype. Twelve again, by tier |
| **Bosses** | ⭐ **The eclipse.** One body covering, one light covered |

| Creature | Rank | Archetype | Element | Drops | Lore line | Teaches |
|---|---|---|---|---|---|---|
| **The Held Door** | Common | Sentinel | geo + flora | mote · material | Stone that has been shut long enough for root to grow into the seam, so that the rock and the green are now one fitting | ⭐ Shield-breaking, and the macro edge **Kinetic ▸ Primal** in one object |
| **Ashlight** | Common | Blighter | pyro + umbra | mote | A fire that gives off heat, and smoke, and no light whatsoever, burning in a sconce nobody lit | ⭐⭐ What statuses do — the only creature in the game stacking **Ignite and Creeping Dark together**. The macro edge **Primal ▸ Ethereal** |
| **The Kept Watch** | Common | Bruiser | sanctus + solar | mote · hide | Still on post, still in the armour, still facing the direction it was told to face, which is not the direction you came from | Reading the charge bar. The macro edge **Ethereal ▸ Celestial** |
| **Nightcurrent** | Common | Lasher | lunar + electro | mote | Moonlight arriving along the ironwork the way current arrives along a wire, and reaching the floor at the same time you do | Why a big shield is not always the answer. The macro edge **Celestial ▸ Kinetic** |
| **The Last Applicant** | Common | **Adept** | aqua + aero + astral + arcane | mote · hide | Somebody else who came all this way to be let back in, and who is still here, and who is still asking | ⭐⭐ The yardstick — and **one element from each tier is the Concordant Crown in miniature.** The last honest fight in the game is a person trying to do exactly what you are trying to do |
| **The Basin** | Mini | Champion | flora + aqua + pyro | mote · hide | The first ground, arriving with everything it taught you and none of the patience | ⭐ A clean skill check, because the Primal quarter is where you learned to fight straight |
| **The Range** | Mini | Redoubt | geo + electro + aero | mote · material | The rock you crossed, standing across the way again, in no hurry at all | ⭐ Attrition, because the Kinetic quarter was weight |
| **The Shelf** | Mini | Executioner | solar + lunar + astral | mote | The high air, which never had enough in it, and which now has none | ⭐⭐ One misplay ends you — **Thin Air is the Celestial band's own mechanic**, returning as a fight |
| **The Climb** | Mini | Hexer | sanctus + umbra + arcane | mote · material | The last stretch, which was always above your level and was always answered with what you were carrying | ⭐⭐ It punishes a bad **loadout** — which is precisely what the Ethereal quarter does (*gear closes the gap, not XP*) |
| **Totality** | **Boss** | Juggernaut | **all twelve** | mote · unique | ⭐ The moment the light is completely covered. Not a creature standing in the door — the door, having decided to be a creature | ⭐⭐ Endurance, and the mechanical statement of *"no five-slot loadout counters everything"*: it shields and attacks in a different element almost every turn |
| **Procarius, the Eclipsed** ✅ | **Boss** | Tyrant | arcane · umbra · lunar · electro · pyro | mote · **key** · unique | The one the Citadel was built around, and the reason the name is in the passive voice | ⭐ The intelligence is the threat — and he is a **mage**, so the last fight in the game is your own toolbox |

⭐ **The zone's name is the relationship between its two bosses.** Totality is
the covering; Procarius is the covered. ⚠️ **`key` on Procarius** is the
Concordant Crown frame, which gates Zenith (§2e.1) — and only on him, because
he is not drawn against Totality but fought after it.

##### ✅ Ruling — the two-boss rule in a final dungeon is a SEQUENCE, not a pool

✅ **Both bosses are fought, in order, on every clear.** The **count** of two is
honoured; the **draw** is not.

⭐ **Why.** Every other zone's pool exists so that a clear is a coin flip and a
zone is not memorised after one run (§3d, §4.1). A **finale** that ends on a
coin flip has no ending — half the players would never meet Procarius, who is
the game's named antagonist and its only level-60 persona. ⭐ **And the sequence
is what the arrival text already says:** the Citadel is between you and it, so
you fight the Citadel, and then you fight the thing standing in the door.

⚠️ **This is the one place the shipped adventure shape needs a code change.**
`adventure.dart` draws **one** boss from the pool. The Citadel needs a
two-stage boss encounter, or a boss node that runs both. ⭐ **Flagged here
rather than worked around**, because the alternative — dropping Totality to a
fifth mini — would cost the zone its structure.

##### ⚠️ Procarius — integrating the persona, and two things that do not fit

✅ **`ai_personas.dart` is canon for him and the roster honours it verbatim:**
level **60**, intelligence **10**, apparel as written, and the `_archmage`
loadout — Arcane, Umbra, Lunar, Electro, Pyro, with Jolt · Blast · Ruin ·
Cataclysm · Barrage · Drain · Sanctuary · Barrier · Overload · Discharge.

⚠️ **Two deliberate exceptions, stated so a build lane does not "fix" them:**

| What | The archetype says | Procarius is | Why he wins |
|---|---|---|---|
| **Intelligence** | Tyrant = 9 | **10** | ⭐ The persona is the older, shipped record and the ladder already runs him at 10. A finale antagonist demoted by a table is a bug, not a balance decision |
| **Move count** | Tyrant = 3 moves, cost 1–5 | **10 spells** | ⭐ §3.4: *beasts and constructs get creature moves; humanoid casters get `Spellbook`.* The archetype's move-count shape describes a **creature kit**; a mage brings a **loadout**. ⚠️ `moves.length == archetype.moveCount` is asserted in every shipped zone suite — ❓ **the Citadel's suite needs an explicit mage exemption, and so will The Archmage in The Collapsed Academy.** Needs a ruling before either is built |

⭐ **He is also the zone's `opponentNameFor` anchor** (`world.dart`), which no
other zone spends on a boss — the map names the Citadel after the man, not
after a common, and that is correct.

##### Move kits — The Eclipsed Citadel

Ids are zone-tagged `ec_*`. ⚠️ **Procarius has no kit here** — he casts
`Spellbook` nouns (*"Procarius casts Arcane Cataclysm"*) while everything else
in the zone does verbs (§3.3a). ⭐ **That grammatical split is the last thing
the game says**: the creatures act, the mage casts.

| Creature | Moves | Kit |
|---|---|---|
| **The Held Door** | 2 · cost 2–4 | **Set the Jamb** (2 · pri 9 · `DamageEffect`) · **Hold It Shut** (4 · pri 3 · `ShieldEffect`) |
| **Ashlight** | 2 · cost 1–2 | **Take the Light Out** (1 · pri 9 · `DotAttackEffect(3,5, dotId:'ec_afterburn', dotName:'Afterburn', damagePerTick: 5, ticks: 3)`) · **Burn Without Showing** (2 · pri 9 · `DotAttackEffect(4,6, dotId:'ec_afterburn', dotName:'Afterburn', damagePerTick: 6, ticks: 6)`) |
| **The Kept Watch** | 2 · cost 2–5 | **Challenge** (2 · pri 9 · `DamageEffect`) · **Bring the Whole Office Down** (5 · pri 9 · `DamageEffect`) |
| **Nightcurrent** | 2 · cost 1–3 | **Run the Line** (1 · pri 8 · `DamageEffect(hits: 3)`) · **Come In on Every Wire** (3 · pri 9 · `DamageEffect(hits: 4)`) |
| **The Last Applicant** | 3 · cost 1–3 | **Present the Claim** (1 · pri 9 · `DamageEffect`) · **Argue It Properly** (3 · pri 9 · `DamageEffect`) · **Stand on the Threshold** (2 · pri 3 · `ShieldEffect`) |
| **The Basin** | 3 · cost 1–4 | **Start Again** (1 · pri 5 · `DamageEffect`) · **Everything You Learned Here** (4 · pri 9 · `DamageEffect`) · **Close the Canopy** (3 · pri 3 · `ShieldEffect`) |
| **The Range** | 3 · cost 2–4 | **Stand in the Road** (2 · pri 9 · `DamageEffect`) · **Put the Mountain in Front** (4 · pri 3 · `ShieldEffect`) · **Grind It Out** (3 · pri 9 · `DamageEffect(lifesteal: 0.4)`) |
| **The Shelf** | 2 · cost 3–5 | **Thin the Air** (3 · pri 9 · `DamageEffect`) · **Step Off the Edge** (5 · pri 9 · `DamageEffect(executeBelowPercent: 35)`) |
| **The Climb** | 3 · cost 1–3 | **Weigh the Pack** (1 · pri 4 · `DamageEffect`) · **Keep Going Up** (2 · pri 1 · `DamageEffect`) · **Nothing You Brought Is Enough** (3 · pri 2 · `DamageEffect(ignoresShields: true)`) — ⭐ the move name is the lesson |
| **Totality** | 3 · cost 3–5 | **Cover It** (3 · pri 9 · `DamageEffect`) · **Close Over** (4 · pri 3 · `ShieldEffect`) · **Nothing Gets Past** (5 · pri 9 · `DamageEffect`) |
| **Procarius, the Eclipsed** | — | ⚠️ `Spellbook`, per his persona. No creature moves |

---

## 2f. ⚠️ Overlap audit — what the full rosters exposed

⛔ First run 2026-08-02 · ✅ **re-run and its targets discharged 2026-09-22**

⛔ **Run 2026-08-02 across 25 rostered zones** (the Citadel had no roster then):
172 distinct creature names, 125 commons, 100 mini-bosses, 50 bosses.

✅ **Re-run 2026-09-22, and the Citadel is no longer exempt** — all **26 zones**
are rostered: **183 distinct creature names, 130 commons, 104 mini-bosses,
52 bosses.**

### ✅ Clean

- ✅ **One name collision, fixed.** *Obsidian Golem* was a mini in both Old
  Quarry and The Molten Deep — both Geo. The Molten Deep took **Pyroclast**.
- ✅ **No zone repeats an archetype inside its own five commons.** Every zone
  fields five genuinely different fights. ✅ **Still true after the 2026-09-22
  rebalance** — it was treated as an invariant, not an outcome, so every
  reassignment was checked against the other four commons in its zone.

### ✅ Resolved — minis and bosses now have archetypes

⛔ **Was:** all 150 elevated encounters were names and premises with nothing
mechanical attached, so none could be built or balance-simmed.

✅ **Fixed in §2g**, and ✅ **refined 2026-09-22 with the Citadel added**. Minis
are one of each per zone — Champion / Redoubt / Executioner / Hexer, **26 each**
— so a run's 2-of-4 draw is always a different pair of **roles**. Bosses take 2
of 3 by premise: **Juggernaut 19 · Tyrant 16 · Aspect 17** over 26 zones.

### ✅ RESOLVED 2026-09-22 — the distribution was rebalanced across the fifteen

⛔ **Was lopsided** (audit of 2026-08-02, kept for the record):

| Archetype | Zones, of 25 | |
|---|---|---|
| Sentinel | 23 | ⚠️ near-universal |
| Skirmisher · Glasswing | 19 each | |
| Lasher | 14 | |
| **Siphon** | 12 | ⚠️ a shock that happens in half the zones is not a shock |
| Bruiser · **Adept** | 10 each | ⚠️ the *yardstick* was missing from 15 zones |
| Drudge · Blighter | 9 each | ⚠️ Drudge appeared at levels 45–54 |

✅ **Ruled by Christian, 2026-09-22: *"rebalance during the design pass, keeping
creature names and themes; built zones keep their code."*** ⭐ So the fix lands
on the **fifteen unbuilt zones at level 30+** only; the ten built zones
(Primal 5 + Kinetic 5… and the Kinetic six) keep every archetype their shipped
Dart declares. ⚠️ **Archetypes changed; names and themes did not** — where a
name stopped fitting its new archetype, a rename is *proposed* in a 📝 and the
old name stays in §2e's table so the change is visible.

#### The fifteen, before and after

⭐ **75 common slots** (5 × 15). The Citadel had no roster at all before, so
"before" counts 14 zones and 70 slots.

| Archetype | Before (14 zones) | After (15 zones) | Target | Met |
|---|---|---|---|---|
| **Adept** | 7 | **15** | exactly one per zone | ✅ |
| **Sentinel** | 14 | **7** | ≤ half of 15 | ✅ 7 ≤ 7 |
| **Siphon** | 8 | **3** | only where the theme literally drains or feeds | ✅ |
| **Drudge** | 5 | **0** | none above level 30 | ✅ |
| Glasswing | 10 | 11 | — | |
| Lasher | 9 | 11 | — | |
| Blighter | 4 | 10 | — | |
| Bruiser | 4 | 9 | — | |
| Skirmisher | 9 | 9 | — | |
| **Total** | **70** | **75** | | |

⭐ **The point is not that the columns are equal — it is that no column is the
default any more.** Sentinel fell from *every zone but one* to fewer than half;
Blighter and Bruiser, which were nearly absent from the back half of the game,
now carry a fair share of it. ⚠️ **And the rebalance deliberately did not just
move the problem** — the first draft of this pass pushed Glasswing to 14 of 15,
which is the same failure with a different name. Four Glasswings were moved to
Blighter and Skirmisher on fiction grounds, not to make a number look better:
*Nightglare* blinds, *Spindrift* skims, *Ashlight* burns without showing, and a
*Censer-Wraith* is smoke.

#### ✅ Adept — mandatory, and it usually lands on the anchor name

✅ **Every zone now has exactly one Adept**, so a player always has a baseline
to feel the other four commons against. ⭐ **A pattern fell out of doing it:**
in 9 of the 15 the Adept is the zone's `World.opponentNameFor` **anchor** — the
creature whose name the player already sees on the map. That matches the built
zones, where Brook Naiad, Mirewalker, Stormcliff Tidecaller and Rime Stalker
are all anchor-name Adepts.

📝 **A tendency, not a law.** Six zones put the Adept elsewhere because the
anchor had a better job: *Sunstruck Pilgrim* is named for sun-blindness and
Solar's passive **is** Blind, so it is the Blighter; *Causeway Warden*, *Stratum
Warden*, *Orchard Warden* and *Umbral Devourer* are the four anchors whose
fiction is load-bearing for another archetype.

#### ✅ Siphon — cut from 8 zones to 3, and here is the test it now passes

✅ **The rule is now literal: the zone's premise must be drinking, eating or
being fed.** Not "takes something", not "is greedy" — the creature drinks.

| Zone | Creature | Why it survives |
|---|---|---|
| **The Umbral Wastes** | Umbral Devourer | ⭐ Named for eating, in a zone whose dark is an appetite with a shape |
| **The Sealed Garden** | Windfall | ⭐ Fruit that drinks whoever picks it up — *the temptation as a stat block*, and the reason the archetype exists (§2.6) |
| **The Unwritten Library** | Ink-Drinker | ⭐ The zone's whole premise is *"it would like your name for the record."* The place feeds on the player; the Siphon is that said once more, smaller |

⚠️ **Five cut, and each cut names the thing it was mistaken for:** *Undershine*
reflects, *Lowwater Thing* is left behind by a schedule, *Palimpsest* overwrites,
*Corebiter* eats **rock**, *Corridor Crawler* is unfinished work. ⭐ **None of
those is an appetite**, and calling them all Siphons is exactly how the
archetype stopped being a shock.

⭐ **Thornmire keeps both of its Siphons** — it is built, and two drinkers in
one zone is the lesson it exists to teach.

#### ✅ Drudge — zero above level 30

✅ **All five are reassigned**, none by inventing a creature:

| Zone | Creature | Now | ⭐ |
|---|---|---|---|
| The Kiln Desert (30–34) | Sunstruck Pilgrim | **Blighter** | Solar's passive is Blind and the name already said so |
| Tidewrack Shoals (36–40) | Tidewrack Drowned | **Adept** | The drowned still fight the way they fought, which is worse |
| The Glass Archive (43–47) | Readerless | **Lasher** | Loose unread leaves arrive all at once |
| Hallowmarch (45–49) | Pilgrim's Remnant | **Bruiser** | 📝 rename *Pilgrim's Weight* — the pack, not the person |
| The Collapsed Academy (50–54) | Emeritus | **Glasswing** | ⭐ Still here past their time: brittle, with one catastrophic thing left |

#### ✅ Mini archetypes — every one used far more than twice

✅ **The one-of-each-per-zone rule holds across all fifteen**, so Champion 15 ·
Redoubt 15 · Executioner 15 · Hexer 15. ⚠️ **This is a LAW, not a preference** —
`test/frostfell_pass_test.dart` asserts it (*"the four minis are one of each
mini archetype"*), and it is what makes a run's 2-of-4 draw a different pair of
tactical **roles** rather than different names.

#### ✅ Boss archetypes — no zone repeats its neighbour's pair

⚠️ **"Neighbour" means adjacent in band order**, which is how a player actually
meets them. Two collisions existed and both are fixed:

| Where | Was | Now | ⭐ Why the new one is also better fiction |
|---|---|---|---|
| **The Kiln Desert** (30) beside **The Mirrormere** (32) | both `Tyrant + Aspect` | Kiln's *The Cold Shadow* Tyrant → **Juggernaut** | §2g gives Tyrant to *"a person, a will, something that decided"* — **a shadow decided nothing.** It is a mass |
| **The Reliquary Deep** (52) beside **The Unwritten Library** (54) | both `Juggernaut + Tyrant` | Library's *The Author* Tyrant → **Aspect** | ⭐⭐ The zone's premise is that **there is no author**. Calling it a Tyrant contradicted the zone out loud |

✅ **Resulting spread across the fifteen: Juggernaut 10 · Tyrant 10 · Aspect 10**
— exactly even, 30 boss slots. ⚠️ **The Sunless Reach's two Aspects are kept**
(§2g's licensed exception: identical ground on two sides of a line).

### ⚠️ Thematic collisions

| Pair | Risk |
|---|---|
| **Stormcliff Coast** vs **Thunderspire Peaks** | ⚠️ **The real one, and the 2026-09-21 re-band changed its shape.** See the ❓ proposal below — ⚠️ **this row's old wording was stale**, describing Stormcliff as *"the warning before the strike"*, which §2e rethemed away on 2026-08-02 |
| **The Glass Archive** (43–47) vs **The Buried Sky** (46–50) | ✅ Deliberate opposition — light that keeps nothing vs stone that keeps everything. Documented in WORLD_DESIGN §4c.1c so it is not "fixed" later |
| **Old Quarry** (*absence made solid*) vs **The Umbral Wastes** (*dark given a shape*) | 📝 Same idea, 30 levels apart. Probably fine; worth not making it a third time |

#### ❓ Proposal for Christian — Stormcliff Coast should take the different idea

❓ **Two findings, one recommendation.** First, the collision as this section
originally wrote it **is already fixed**: §2e rethemed Stormcliff on 2026-08-02
from *"the warning before the strike"* to *"everything here is a path to the
ground, including you"*, splitting the two zones **space against time** —
Stormcliff is *where* the lightning goes, Thunderspire is *when* it comes — and
the row above simply never caught up. ⚠️ **But the 2026-09-21 re-band re-opened
it from the other end.** That split silently assumed the player met them in the
order Stormcliff (17–22) → Thunderspire (23–28): a single strike's geography
first, then a storm accelerating toward something. Reversed — Thunderspire is
now the **mandatory road out of Forgeholm at 17–22** and Stormcliff the later
coast at **23–28** — the player meets *"the intervals are getting shorter"*
first and *"the rock is a path to the ground"* second, so the zones' claims now
**de-escalate**: a countdown resolves into a diagram. ⭐ **My recommendation is
that Stormcliff Coast takes the different idea, precisely because it is now the
later zone** — and that the new idea is **aftermath, not anticipation**: *the
coast is what is left after the strike; everything here has already been hit and
is still carrying it.* ⭐ **The built roster already says this and nobody has to
touch it** — fulgurite is literally the glass left where lightning passed
through sand, the Static Shoal is residual charge in the water, the Groundling
survived by staying low, and **The Return Stroke** is the ground answering back
*afterwards*. ✅ **The cost is a theme line and the arrival passage's emphasis —
no creature, archetype, item, drop table or test changes** (both zones are built
and Ruling 2026-09-22 protects their code), and it restores the escalation the
re-band inverted: at 17–22 *it is coming*, at 23–28 *it came, and the coast is
still holding it.*

### ⚠️ The structural risk nobody will notice until playtest

⭐ **Every boss pool is now "X versus its opposite."** The pattern is excellent
— it is why Ashfall Vale, The Sealed Garden and The Buried Sky all land. But it
is now applied to **all 26 zones**, and ⚠️ **a player will decode the formula
around zone six and stop being surprised by it for the remaining twenty.**

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
| ✅ **The Eclipsed Citadel** *(added 2026-09-22)* | **no draw at all** | ⭐⭐ Both bosses, in order, every clear. *Totality* is the body covering; *Procarius* is what it covers. **A finale that ends on a coin flip has no ending**, and half the players would otherwise never meet the game's named antagonist |

⭐ **And the strongest one, now unblocked:** **The Unwritten Library** gets a
**third boss that only exists on a repeat clear**. The zone's premise is *"it
would like your name for the record"* — so the first clear takes your name, and
every clear after that can draw **you**, written in. ✅ `PlayerProfile` now
carries `zoneClears`, which is what this needs.

---

## 2g. 📝 Archetypes for every mini-boss and boss (first pass)

⚠️ **First pass, explicitly for refinement.** These close the gap §2f flagged —
150 elevated encounters that had names and premises but nothing mechanical.

### ⭐ The minis assign themselves, and that is the good news

**Four mini archetypes exist and every zone has exactly four minis**, so the
default is **one of each, per zone**. That is not a convenience — it is the
best available answer:

⭐ **A run draws 2 of the 4 (GAME_DESIGN §3d), so every visit is a different
pair of tactical ROLES**, not just different names. Champion + Redoubt is a
grind; Executioner + Hexer is a scramble. ⭐ **The pool stops being cosmetic
variety and becomes the reason a zone plays differently on a second run** —
which is exactly what the Purge achievement (~4.2 clears, ACHIEVEMENTS §2.3)
asks players to do anyway.

✅ **Distribution is perfectly even by construction: Champion 26, Redoubt 26,
Executioner 26, Hexer 26** — 25 zones plus the Citadel, whose four minis are
✅ **the four quarters the player walked** (§2e).

⚠️ **Break the one-of-each rule only with a reason.** A zone whose four minis
are all wardens genuinely wants two Redoubts — but then say so, because the
cost is a run that can draw two of the same shape.

### Bosses — 2 of 3, chosen by the premise

| Boss archetype | Goes to |
|---|---|
| **Aspect** | The one that **is** the place or the element — leans on the passive taken to an extreme |
| **Juggernaut** | The one that is a **mass or a force** — enormous, predictable, an endurance test |
| **Tyrant** | The one that is a **mind** — a person, a will, something that decided |

⛔ **Was: Juggernaut 17 · Tyrant 17 · Aspect 16** across 25 zones.

✅ **Now, after the 2026-09-22 rebalance and with the Citadel added:
Juggernaut 19 · Tyrant 16 · Aspect 17** over 26 zones (52 boss slots). ⭐ Across
**the fifteen rebalanced zones alone the spread is exactly even — 10 · 10 · 10**
— and ✅ **no zone repeats its band-order neighbour's pair** (§2f).

---

### The table

| Zone | Champion | Redoubt | Executioner | Hexer | Boss A | Boss B |
|---|---|---|---|---|---|---|
| **Whispering Woods** | Elderroot | Mother Spore | Hollow Stag | The Murmur | Heartwood ⛰️ | The Standing Green ✨ |
| **Glimmerbrook** | Weirkeeper | The Held Breath | Pale Coil | Frostgleam Naiad | The Cold Below ⛰️ | Stillwater ✨ |
| **Cinderpeak Foothills** | Slagheart | Vent Warden | Char-Tusk | The Emberqueen | The Breathing Stone ⛰️ | Flintmaw 👑 |
| **Thornmire** | Old Wallow | The Green Drowning | Wickerdrowned | Fenmother | Mirethroat ⛰️ | The Drinking Grove ✨ |
| **Ashfall Vale** | The Grey Stag | First Green | Last Ember | Kindleroot | The Blackened Crown 👑 | The Rooting ✨ |
| **Old Quarry** | Obsidian Golem | Earth Titan | Deadweight | The Overseer | Mountain Heart ⛰️ | The Empty Course 👑 |
| **Stormcliff Coast** | Brinecharge | The Long Line | Voltgeist | Storm Shaman | Storm Lord 👑 | The Return Stroke ✨ |
| **Windward Steppe** | Old Lean | Sky Titan | Gale Serpent | Wind Wraith | The Unbroken Blow ⛰️ | Tempest Monarch 👑 |
| **Frostfell Pass** | The Last Cairn | Hoarking | Coldsnap | The Certain Road | The White Corridor ⛰️ | The Road Under ✨ |
| **Thunderspire Peaks** | Crown Fire | Anvilhead | Thunder Roc | The Shortening | The Storm That Passes ⛰️ | The Strike That Lands ✨ |
| **The Molten Deep** | The Floor | Magma Behemoth | Pyroclast | Firstmelt | The Slow Stone ⛰️ | Efreet 👑 |
| **The Kiln Desert** | Sun Templar | Prism Sentinel | Saltmarch Wraith | The Shadeless Hour | The Cold Shadow ⛰️ ⭐*was 👑* | Solar Deity ✨ |
| **The Mirrormere** | The Second You | Herald of the Waxing | Stalker of the New Moon | The Waning Wraith | The Moon Below 👑 | Luna Plena ✨ |
| **Starfall Basin** | The Zodiac Ascendant | Constellation Warden | Rift Walker | Echo of the Between | The Next One ⛰️ | What Landed 👑 |
| **Tidewrack Shoals** | Tidal Empress | Leviathan | Maelstrom Horror | The Turning | Kraken ⛰️ | The Undertow ✨ |
| **The Sunless Reach** | Solar Archon | The Crest | Both-Sided Thing | Duskmarch | The Last Light ✨ | The First Dark ✨ |
| **The Shattered Orrery** | Sidereal Fault | Escapement | Long Division | The Remainder | The Calculation ⛰️ | The Answer 👑 |
| **The Glass Archive** | The Last Reader | Aperture | Burnt Index | The Marginalia | What Was Written 👑 | What Is Left Of It ✨ |
| **Hallowmarch** | Milestone | Vestal Warden | Seraph Judicant | The Upkeep | The Keeper of the Road ⛰️ | The Hierophant Eternal 👑 |
| **The Buried Sky** | Stonefall Herald | Bedrock Colossus | Nadir | The Long Count | The Overburden ⛰️ | The Buried Constellation ✨ |
| **The Umbral Wastes** | Umbral Knight | The Edge | Void Stalker | Eclipse Weaver | Nightbringer 👑 | What Was Thought About ✨ |
| **The Sealed Garden** | The Last Gardener | Root Matriarch | Cherub of the Turning Blade | The Kept Vow | Guardian of the World Tree ⛰️ | The Serpent in the Branches 👑 |
| **The Collapsed Academy** | The Fourth Item | Mana Golem | Arcane Chimera | Spell Weaver | The Archmage 👑 | The Last Three Items ✨ |
| **The Reliquary Deep** | Antechoir | Reliquary Colossus | The Second Hand | Warm Middle | What Was Consecrated ⛰️ | What Did Not Leave It Alone 👑 |
| **The Unwritten Library** | The Index | Colophon | Redaction | The Amanuensis | The Record ⛰️ | The Author ✨ ⭐*was 👑* |
| **The Eclipsed Citadel** ✅ *new* | The Basin | The Range | The Shelf | The Climb | Totality ⛰️ | Procarius, the Eclipsed 👑 |

⛰️ Juggernaut · 👑 Tyrant · ✨ Aspect

### ⭐ Assignments worth keeping through any refinement

- ⭐ **Ashfall Vale — First Green is the Redoubt, Last Ember is the
  Executioner.** The two sides of the zone's argument are mechanically
  opposite: regrowth wins by outlasting, fire wins by being faster. ⭐ **The
  theme is now legible in the statlines**, not just the names.
- ⭐ **Thunderspire's *The Shortening* is the Hexer.** The zone's premise is
  intervals getting shorter; a stacking status IS that premise.
- ⭐ **Starfall's two-scale pool maps exactly** — *What Landed* is compact and
  clever (Tyrant), *The Next One* is enormous and unavoidable (Juggernaut).
- ⭐ **The Shattered Orrery** — *The Calculation* grinds forever (Juggernaut),
  *The Answer* knows (Tyrant). The archetypes ARE the premise.
- ⭐ **The Sealed Garden's Serpent is the Tyrant, not the Guardian.** The rule
  is a wall you must get through; the tempter's threat is that it plays well.
- ⭐ **Cherub of the Turning Blade is the Executioner** — a flaming sword that
  turns every way is not a wall.

### ⚠️ The deliberate exceptions

- ⚠️ **The Sunless Reach fields TWO Aspects** — the only zone that does. Its
  premise is identical ground on two sides of a line, so *The Last Light*
  (Solar) and *The First Dark* (Lunar) being the same archetype of different
  elements **is the mechanical statement of the theme**. ⭐ Keep it; it is the
  one place doubling says something.
- ❓ **The Unwritten Library's repeat-clear third boss, *Your Entry*,** has no
  archetype here. It is the player's own build written down — arguably not any
  of the three, and possibly a new one. Needs a ruling. 📝 **Recommendation
  (2026-09-22): Tyrant.** It is a mind that plays well because it is playing
  *your* game. ⚠️ **Not an Aspect** — that slot is now *The Author*, and in this
  zone an Aspect means something specific (Creeping Dark as authorship by
  nobody).
- ✅ **The Eclipsed Citadel is no longer absent** (designed 2026-09-22, §2e).
  ⭐ **It uses this template after all** — the earlier proposal to abandon it is
  withdrawn — because the twelve elements are carried *inside* the 5/4/2 shape
  rather than by widening it: commons walk the macro-tier loop, minis are the
  four quarters, bosses are the eclipse. ✅ **Its two bosses are a SEQUENCE, not
  a pool** — both fought, in order, every clear — which is the one place the
  2-boss draw does not apply, and the one place `adventure.dart` needs a change
  to match.

### ⚠️ What this pass did NOT do

- ⚠️ **No element assigned per enemy.** A zone's elements are known, but which
  of a hybrid's two a given creature uses is not decided. ✅ **Settled in code
  for the Primal quarter's five zones**, per §2h: both by default, and a lean
  only where this document names one — the Thirstvine (Flora) and Last Ember
  (Pyro) are the only two.
- ⚠️ **No move sets.** §3 requires creature moves, not spells, for anything
  that is not a mage. ✅ **Written for the Primal quarter's 55 creatures**; the
  remaining 21 zones still have none.
- ⚠️ **Coefficients are untouched** — every Champion is 1.70/1.20 until the
  balance sim says otherwise. ⭐ **That is the point of the archetype layer:**
  these 150 encounters are now buildable and simmable, which they were not an
  hour ago.

---

## 2h. ✅ Which element a creature uses (Christian, 2026-08-02)

✅ **Pure zones: the zone's element.** No decision to make — every creature in
Whispering Woods is Flora.

✅ **Hybrid zones: either way is fine.** Per creature, either assign it **one**
of the zone's two elements, or let it use **both**. ⭐ Both readings are
legitimate and the choice can be made creature by creature rather than as a
blanket rule — a Thirstvine is obviously Flora drinking Aqua, while a
Both-Sided Thing in The Sunless Reach should plainly be both.

### ⭐ Enemies are NOT locked to their zone's elements

✅ **In the last two quarters — Celestial (30–44) and Ethereal (45–60) — a
creature may use a third or even fourth element, sparingly.**

⭐ **Why this is scoped to the back half, and why that scoping is the whole
point.** The player counter-picks a loadout from the zone's advertised
elements. If enemies can surprise them off-element:

- **Early, that is unfair.** A level-4 player is still learning that elements
  counter each other at all; an off-element hit reads as the game cheating.
- ⭐ **Late, it is exactly the tension the endgame needs.** By level 40 a player
  has twelve elements, five slots and a settled counter-pick habit. A rare
  off-element move means the safe loadout is not perfectly safe, and the shield
  plan has to leave a little room. ⭐ **It keeps loadout choice alive long after
  the counter wheel has been memorised** — which is the thing that otherwise
  goes stale in the last twenty levels.

✅ **Given a number, 2026-09-22 — see §2e.2**, which names the **four**
creatures in the fifteen late zones that carry an off-element move, and shows
each one checked against both of its zone's counters. ⭐ *The Sealed Garden's
Cherub of the Turning Blade is written with a blade of **light, not fire**,
precisely because Pyro is Flora's counter* — which is the guardrail below doing
real work on a real creature rather than sitting in a table.

📝 **The guardrail itself — mine, not a ruling. "Sparingly" needs a number or it
becomes "sometimes anything happens":**

| Rule | Why |
|---|---|
| **Minis and bosses only, never commons** | A common is the fight a player learns the zone on; surprises belong on the fights they came for |
| **At most one off-element move per creature** | Enough to break the assumption, not enough to invalidate a whole loadout |
| **Celestial and Ethereal only** | Per the ruling above |
| **Never the zone's own counter** | ⚠️ **The real trap.** A player brings the element that beats the zone; if a boss carries the one thing that beats *that*, the counter-pick is not a choice but a punishment |

⚠️ **That last row is the one to keep.** The others are tunable; a boss that
specifically punishes correct preparation is the version of this idea that
makes players stop preparing.

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

⚠️ **This is a REVIEW rule, not an automated one — deliberately.** A blocklist
was tried and dropped (2026-08-02): it only ever catches the handful of words
someone thought to type, while giving false confidence about everything else.
✅ **What IS enforced in tests** is the narrower correctness rule below — no
move may be named `Charge`, `Cast`, `Focus`, or after an element, because those
are ambiguous in the battle log rather than merely derivative.

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
3. **Mini-boss and boss pools** — ✅ now **4 and 2 per region** (§4, which
   supersedes the 5-and-3 line this item was written against), each region with
   its own coherent roster. ✅ **No zone has nothing any more** — all 26 are
   rostered as of 2026-09-22, the Citadel included (§2e).
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
