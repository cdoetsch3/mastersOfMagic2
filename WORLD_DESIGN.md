# World Design — geography, places, and in-game text

Status: 📝 **draft — geography built, content not.** `lib/game/world.dart` now
matches this document: all 32 places, the two planes, the graph, elevations and
the player-facing text below. Guarded by `test/world_test.dart`. Still unbuilt:
the bestiary, the three-section zone structure, resource nodes, gate
enforcement, and the Thin Air / no-moon mechanics of §4.

**What this document owns.** The *physical* world: landforms, where each place
sits and why, the two planes, the environmental mechanics that come out of the
geography, and the player-facing text for every location.

**What it does not own.** The logical map (which elements pair with which, level
bands, counter-edge coverage) lives in [GAME_DESIGN.md](GAME_DESIGN.md) §5. The
unlock schedule and slot curve live in
[PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md). Where this document and those
disagree, **they win on rules and this wins on place.**

Status legend: ✅ decided · 📝 draft · 💡 idea bank · ❓ open · ⚠️ risk

Companion plates are checked in as self-contained HTML under
[docs/plates/](docs/plates/) — open any of them directly in a browser.

| Plate | Shows | Verdict |
|---|---|---|
| [**I**](docs/plates/plate-1-known-world.html) | plan view, climate causation | superseded by I-a/I-b |
| [**II**](docs/plates/plate-2-wheel.html) | concentric wheel — rings and marches | ❌ not adopted; two ideas salvaged (§5) |
| [**III**](docs/plates/plate-3-long-ascent.html) | elevation section, places numbered by height | ❌ not adopted as the map; **tree line adopted** |
| [**I-a**](docs/plates/plate-1a-the-climb.html) | plan view + ascent — the finale becomes a climb | superseded by I-b |
| ✅ [**I-b**](docs/plates/plate-1b-one-crossing.html) | **the settled map** — one world, one crossing | **canonical** |

---

## 1. The four decisions that shape everything ✅

### 1.1 ✅ The world rises; it does not spread

The Ironspine does not end in a polar plain. It **culminates in a single
massif, The Vault**, and the last two tiers are its shelf and its ascent.

⭐ **Why.** A world that spreads outward makes late content "far away", which is
a claim the player has to be told. A world that rises makes late content
*above*, which they can see. It also converts the campaign into one continuous
gradient — sea to summit — instead of four regions in a row.

### 1.2 ✅ One world, one crossing — and only Arcane leaves it

Everything is physical ground up to The Vault's upper flanks. Then the route
leaves the world at **Vespergate**, passes through three Arcane places above
the veil (**The Empyrean**), and re-enters at the summit.

⭐ **Why Celestial stays on the ground.** This was the decisive argument against
making Celestial the cosmic plane:

- **Concordance is a Celestial-tier town and the trade capital of the world** —
  bank, the Concord Market, contracts, hour-long buffs. It is the most
  civic, mundane, human place in the game. It cannot be on a cosmic plane.
- **Meridian is an observatory**, and you observe the heavens *from* the world.
- The zone names already insist on it: **Starfall Basin** is a crater field of
  *fallen* stars (must be ground), **The Mirrormere** is the moon's *reflection
  on a lake* (must be a lake), **The Kiln Desert** is a *desert*.

Celestial is the heavens **touching** the ground, not the heavens themselves.

⭐ **Why Arcane leaves it.** Arcane is the only element with no natural referent.
Pyro is fire, Aqua is water, Solar is the sun — Arcane is magic itself, and has
never had terrain to live in. That is precisely why The Collapsed Academy and
The Unwritten Library always read as placeholders. A non-place solves a real
problem rather than adding flavour.

⚠️ **Keep The Empyrean small — three places, not a tier.** It is a passage with
consequences, not a second world to populate. This bounds the art cost and stops
the finale happening somewhere the player has no stake in.

### 1.3 ✅ The Citadel is the way back **in**

The Vault's last pitch is **impassable**. The summit is never climbed.

⭐ **Why this is the load-bearing decision.** Three problems close at once:

| Problem | How this solves it |
|---|---|
| Zenith must be the summit *and* be gated behind the Citadel | The Citadel is the door back into the world at the summit. No contrivance needed. |
| Vespergate was a generic border fort | "A threshold fortress that cannot resupply from behind" now means *it is the last place with a supply line to reality*. |
| "Eclipsed" was decoration | The Citadel is literally what stands between you and the light at the top. |

The finale is therefore **out → around → back in**, and the last boss is a
door rather than a wall at the end of a corridor.

### 1.4 ✅ Zenith is the summit, sealed and visible

Zenith sits at 5 200 m at the apex of The Vault. It is **visible for the whole
final act and unreachable from below.** Its doors open when the Concordant
Crown is finished.

- ✅ **Teleports to every city** need no justification: it is the one point in
  the world with line of sight to all of it.
- ✅ The Z-for-last-city symmetry from GAME_DESIGN §3b is preserved.
- ⭐ Seeing a city you cannot enter for twenty levels is a better carrot than
  any quest log entry.

---

## 2. Landforms — one feature, many consequences

A map feels invented when every feature exists to justify one zone. It feels
real when a single landform has consequences it never asked for.

### 2.1 ✅ The Ironspine — the range, and five jobs

Runs roughly north–south through the middle of the continent.

| # | Consequence | Zones it produces |
|---|---|---|
| 1 | Weather off the western ocean piles against the cliffs | **Stormcliff Coast** (Electro); **Galehaven** in its one sheltered notch |
| 2 | What the range wrings out never reaches the far side — a rain shadow | **The Kiln Desert** (Solar) |
| 3 | Its passes are the only roads north | **Frostfell Pass** — sea moisture lifted over the crest by steppe wind and frozen; the road *must* use it |
| 4 | Its flanks feed the rivers | **The River Concord** → Concordance at the head of navigation, Pennycross where the river road crosses the mountain road; **Glimmerbrook** → the southern basin |
| 5 | Stone, storm and wind are what a range *is* | the entire **Kinetic** tier needed no invention — Old Quarry, Stormcliff and Windward Steppe are three faces of one massif |

### 2.2 ✅ The Meridian Scarp — one ridge, both halves of a counter edge

An east–west spur off the Ironspine.

- **Sunlit south face** → bakes into **The Kiln Desert** (Solar).
- **Permanently shadowed north face** → **The Sunless Reach** (Solar ▸ Lunar).
- **Meridian** sits on the crest — the highest dark-sky ground, above the haze.

⭐ *"Where day never comes"* could have been hand-waved anywhere. Sitting it on
the shadowed face of the same escarpment that makes the Solar desert means the
zone, its counter edge and its neighbour all come from one piece of terrain.

### 2.3 ✅ The Vault — the massif, and the Sanctus–Umbra edge

✅ **Name: The Vault.** The vault of the sky — and it houses the Reliquary,
which makes Zenith the vault's own apex. (Rejected: *the Crown*, which collides
with the Concordant Crown.)

The same trick as the Scarp, at the scale of a tier:

| Where | Zone | Element |
|---|---|---|
| **South flank** — sun-facing, the only side that thaws | **Hallowmarch** | Sanctus |
| **North face** — no direct sun at any hour of any day | **The Umbral Wastes** | Umbra |
| **Bored between them** | **The Reliquary Deep** | Sanctus + Umbra |
| **Upper icefall** | *deliberately empty* | — |
| **The crossing** | **Vespergate** | — |
| **The summit** | **Zenith** (sealed) | — |

⭐ **The Sanctus ▸ Umbra edge is now terrain.** A north wall at polar latitude
never receives direct sun; the south flank is the only side that thaws. Put the
consecrated causeway on the warm face, the wastes on the cold one, and bore the
Reliquary between them — the edge, both its parents, and the hybrid that
teaches it are one mountain.

📝 **The upper icefall is empty on purpose** — pure ascent between the Wastes
and the crossing, so the climb has a stretch that is only climbing.

### 2.4 ✅ The Empyrean — above the veil

✅ **Name: The Empyrean.** The classical highest heaven. Deliberately distinct
from *Celestial* (sky-as-observed) and *Ethereal* (the tier name), and it does
not collide with the names GAME_DESIGN already ruled out. Runners-up: *the
Firmament*, *the Pale*, *the Lattice*.

- **No altitude.** Places above the veil have no elevation; the vertical axis
  stops meaning anything.
- **No weather, no moon** (see §4.2).
- Contains exactly three places: **The Collapsed Academy**, **The Unwritten
  Library**, **The Eclipsed Citadel**.
- The boundary itself is **The Veil**, crossed only at Vespergate and at the
  summit.

### 2.5 ✅ Two deliberate exceptions to the climb

Kept as exceptions rather than forced onto the ascent, because each earns
something:

| Place | Why it is off the climb |
|---|---|
| **Tidewrack Shoals** — Lv 36–40 at **20 m** | Reached **by sea from Galehaven**, not by ascent. ⭐ This finally gives the port an endgame purpose, which §4 of GAME_DESIGN was explicitly hunting for. |
| **The Molten Deep** — Lv 25–29 at **−400 m** | The one zone that goes *down*. The mirror of everything else, and exactly right for magma reached through a quarry. |

---

## 3. The vertical structure ✅

| Tier | Band | Altitude | Climate & character | Lv |
|---|---|---|---|---|
| **Primal** | the basin | 0 – 1 000 m | Low, temperate, well-watered. The only part of the world with ordinary weather. | 1–14 |
| **Kinetic** | the range | −400 – 2 500 m | Where the ground takes over from the climate. Stone, storm, wind. | 15–29 |
| **Celestial** | the high shelf | 1 700 – 2 700 m | Thin air, brutal sun, hard dark. The heavens touching the ground. | 30–44 |
| **Ethereal** | the climb | 2 900 – 5 200 m | Above the tree line. Ice, rock, and the two faces of one mountain. | 45–60 |
| **The Empyrean** | above the veil | *no elevation* | No ground, no weather, no moon. | 50–60 |

### 3.1 ✅ The tree line is 2 800 m

The only hard altitude the existing docs ever implied — Rimeholt is *"the last
mortal outpost, above the tree line."*

⭐ Pinning it does real work: it sorts the Ethereal band from everything else,
and it explains why Rimeholt is an **outpost** and not a city. Ethereal is not
merely far, it is *uninhabitable* — which makes Vespergate brewing its own
potions a consequence rather than flavour.

### 3.2 ⚠️ Altitude is not difficulty

Numbering places by height instead of level exposes real mismatches, and they
are all deliberate:

- **Tidewrack Shoals** — Lv 36–40 at 20 m, lower than Aldermere.
- **Galehaven** — a Kinetic town at sea level.
- **Ashfall Vale** — late-Primal content at 700 m, above several Kinetic places.

⚠️ **Therefore no rule of the form "higher means harder."** Height is a *climate*
input, not a difficulty input. The UI must never imply otherwise.

---

## 4. Environmental mechanics that fall out of the geography

### 4.1 📝 Thin Air — Celestial only

**A visible, named status applied on entering the high shelf: you deal reduced
damage.**

⭐ **Why Celestial and not Ethereal.** The L45–60 band *already* has a difficulty
mechanic — enemies run up to ten levels above you and gear closes the gap
(GAME_DESIGN §5). Stacking an environmental debuff on top builds a wall.
Celestial is the empty slot, and filling it makes Celestial a **tutorial for
Ethereal's whole thesis**: the environment hurts you, equipment is the answer.
The ten-level gap then reads as a graduation rather than a surprise.

⚠️ **It must be asymmetric.** It hits the player, not the natives, who are
acclimatised. A symmetric debuff is a pure time tax — every fight longer, no
outcome changed.

⚠️ **It must be legible.** A named status with HUD pips and a stated counter, not
a hidden multiplier, or it reads as "numbers feel bad up here." The
`StatusCatalog` and pip framework already support this, and `damageScale` in
`duel.dart` is a single chokepoint feeding all three damage paths — the
implementation is small.

- Countered by: equipment, and Vespergate/alchemy consumables.
- ❓ Magnitude, and whether it scales with altitude within the shelf or is flat.
- ❓ Whether acclimatisation is purchasable, timed, or permanent per zone.

### 4.2 📝 No moon in The Empyrean

There is no moon above the veil, so **Lunar's Full Moon bonus never fires in the
final act.**

- Nearly free to build: `moonPhaseForTurn` is already a pure function of the
  turn number, and `_effectiveMoonPhase` already exists as an override point.
- Thematically exact, and it stops the player leaning on one element for the
  finale — ⭐ which is the Citadel's stated job (GAME_DESIGN §3c: *"punishes only
  having one plan"*).
- ❓ Should Astral get a compensating quirk above the veil, or is one-sided
  correct?

### 4.3 💡 Banked — not adopted

- **Tempo** (shorter move timers at higher difficulty) — still tabled, see
  TYPE_EFFECTS §4d.
- Environmental effects for the other two bands. The basin and the range are
  deliberately plain; ordinary weather is what makes the shelf feel thin.

---

## 4b. Travel, mounts and trade 📝

Status: 📝 **draft — designed here, nothing built.** Travel today is an instant
graph hop; everything below is the model to build toward.

### 4b.1 ✅ Travel is click-and-wait, on a real clock

You click a connected location and arrive after a **duration**. That duration is
the resource the whole trade economy is built on — if travel is free, none of
the rest of this section has any tension in it.

✅ **The clock is real, and tuned to be waitable.** ~**5 minutes** per leg as
the baseline. Long enough that a mount is worth buying, short enough that
waiting it out is a legitimate choice rather than a wall.

⭐ **5 rather than 3 because Journey can beat it** (§4b.2). A fixed safe time
that a skilled player can undercut by fighting is a better number than one they
can only ever match — it means the baseline is the *ceiling* for a good player,
not the floor for everyone.

✅ **Every edge carries its own base time.** No terrain classes, no modifiers —
each location simply stores a duration to each of its neighbours, and mounts
multiply it. Deliberately the simplest thing that works.

✅ **Time crystals expedite travel**, the same way they skip crafting and
research timers (GAME_DESIGN idea bank #8/#9).

📝 **Worked example — the thing to tune against.** Aldermere → Rimeholt is a
long chain of legs. At ~5 minutes each on foot that is **~30 minutes**; the same
trip is **~3 minutes** on a Giant Eagle and **~90 seconds** on a Veilcourser.
That collapse *is* the mount ladder's appeal, and it is why the top tiers can be
priced steeply.

⚠️ 20 minutes is still a lot to ask of a player who has not bought a mount yet,
which is what the alternate transports are for — ⭐ **a ferry from Pennycross to
Concordance**, unlocked with Concordance itself, turns the worst early leg into
a single hop. Every long overland chain wants a counterpart like it.

⚠️ **This supersedes GAME_DESIGN idea bank #9**, which proposed ~10–15s early
legs scaling to hours. Minutes-not-seconds is the settled scale; hours is too
long to ever be waitable.

⚠️ **Code implication.** `GameLocation.connections` is a `List<String>` — it has
nowhere to put a duration. ✅ **Edges must become objects** (`TravelEdge { to,
minutes }`). This is the first real refactor the section forces, and it is
confirmed rather than optional.

### 4b.2 ✅ Travel modes — "just get me there" vs "fight through"

Two ways to cover the same ground:

| | **Travel** | **Journey** |
|---|---|---|
| **Route** | ✅ direct between **any two towns** | leg by leg, ⚠️ **stopping at each town** |
| **Duration** | fixed — the sum of the legs | ⭐ **variable** — how fast you clear what you meet |
| **Encounters** | none | the road's encounter table |
| **Rewards** | none | XP, gold, loot, motes |
| **Cargo** | ✅ safe | ⚠️ **at risk** |

⭐ **Journey is faster when you are good at it.** Clear encounters quickly and
you beat the fixed Travel time; struggle and you lose to it. That makes the
baseline a *ceiling for skilled play* rather than a floor everyone shares, and
it is why the base leg is 5 minutes rather than 3.

⭐ **Cargo risk is what stops Journey dominating.** Faster *and* more rewarding
would leave Travel with no purpose — but a trader hauling 100 slots of stock
cannot gamble it, so they take the safe direct route while an adventurer with an
empty pack takes the road. Same map, two playstyles, no artificial gate between
them.

✅ **Travel is point-to-point between any two towns.** You do not hop
town-by-town; you pick a destination and pay the summed duration. ✅ **Journey
stops at every town on the way**, which is where you heal — so the long road is
naturally broken into survivable stages.

⚠️ **Code implication: this needs pathfinding.** Direct town-to-town travel means
computing a route and its total duration over the edge graph, not just reading
one edge. Together with §4b.1's `TravelEdge` refactor, that is the shape of the
travel system's first build.

- Gives the **push-your-luck adventure loop** (GAME_DESIGN §5) a natural home:
  the road *is* the run.
- ❓ Open: what "at risk" means — a fraction of cargo on defeat, or all of it?
  Loot insurance (ITEMS §6b.4) is the existing lever.
- ❓ Open: is Journey offered on every edge, or only ones with a designed
  encounter table?

### 4b.3 ✅ Mounts — a price ladder, plus a speed-vs-bulk fork

✅ **No terrain rules.** A mount is a **speed multiplier** and a pile of **extra
cargo slots**. Nothing else. Some mounts are simply better than others; that is
intended, and price carries it.

⭐ **The interesting part is that each price tier above the intro offers a
speed play and a bulk play at the same cost**, so the ladder is a series of
forks rather than a single line.

| Tier | Mount | Speed | Cargo | Note |
|---|---|---|---|---|
| **1** | 🐐 **Goat** | 1× | +5 | Cheap intro. Walks beside you — you do not ride it |
| **1** | 🫏 **Mule** | 1× | +20 | Also walked, not ridden. The first real hauler |
| **2** | 🐴 **Horse** | 2× | +10 | The first time you are actually riding |
| **3** | 🐎 **Quarter Horse** | **5×** | +10 | *the speed play* |
| **3** | 🐴 **Clydesdale** | 2× | **+35** | *the bulk play* — same price as the Quarter Horse |
| **4** | 🦅 **Giant Eagle** | **10×** | +8 | *speed* |
| **4** | 🦁 **Griffon** | 4× | +28 | *middle* — 📝 proposed, see below |
| **4** | 🐘 **Elephant** | 1.5× | **+60** | *bulk* |
| **5** | 🐉 *speed monster* | **20×** | +20 | 📝 naming below |
| **5** | 🐲 *bulk monster* | 5× | **+100** | 📝 naming below |

📝 **The Griffon fills tier 4's middle slot** — it is literally an eagle joined
to a horse, which is exactly where it sits mechanically between the Giant Eagle
and the Elephant. If tier 4 only needs two options, drop it.

### 4b.3a ✅ Tier 5 — the Ethereal three-pack

⭐ **The top tier is three mounts, one per Ethereal element** — Umbra fast,
Arcane balanced, Sanctus vast. The tier that ends the game is built out of the
tier that ends the elements, and the speed/bulk fork of the lower tiers opens
into a three-way choice at the top.

| Mount | Element | Speed | Cargo | Reading |
|---|---|---|---|---|
| 🌑 **Veilcourser** | Umbra | **20×** | +20 | *the speed play* |
| 🌀 **Riftwing** | Arcane | 10× | +50 | *the balance* |
| ✨ **Hallowbearer** | Sanctus | 5× | **+100** | *the bulk play* |

**Veilcourser** — a *courser* is a swift warhorse, so the name means "fast"
before it means anything else, and it caps the Horse → Quarter Horse line at
the top of the game. It runs *along* the Veil, taking the shortcut the world
cannot, which is what earns the 20× rather than merely asserting it.
⚠️ **It must not open the Veil** — the design rests on there being exactly two
doors (§1.3). It skims; it does not cross wherever it likes.

**Hallowbearer** — holy, enormous, and *bearer* says cargo in the name. Matches
Hallowmarch, so the Sanctus vocabulary is consistent across the world.

**Riftwing** — Arcane, flying, and the only tier-5 mount that is good at both
without being best at either. 💡 **Codexwing** is the alternative if you want it
tied to the Collapsed Academy and the Unwritten Library rather than to raw
rifts.

📝 Alternates considered: *Veilhound / Veilstag* (Umbra), *Thronebeast /
Lamassu* (Sanctus), *Glyphwing / Cipher* (Arcane).

⭐ **These should drop from the Eclipsed Citadel.** The final dungeon giving you
your final mounts closes the loop between the campaign and the economy, and it
gives the Citadel a reward that is not just gear.

### 4b.4 📝 Boats

The Galehaven ↔ Tidewrack passage is already sea-only in the graph. Boats
generalise that:

- Run only on sea edges, on a **schedule or for a fare** — the fare is a gold
  sink that scales with cargo.
- ⭐ **Carry mounts.** The only way to relocate an animal without walking it.
- Cargo-heavy and slow: the bulk option against the horse's speed.

### 4b.5 ✅ The Concord Market, and shops

✅ **The player-to-player market is the CONCORD MARKET.** One name, one order
book, **two access points** — Concordance and Zenith. It is called the Concord
Market from both doors, because it *is* the same system; a second name would
imply a second market and split liquidity (GAME_DESIGN §3b).

✅ **Everything else is a "shop" or a "store"** — never a market. Keeping the
word *market* exclusively for the player economy is what stops every UI label
and design conversation needing a disambiguator.

| | Concord Market | Town shops |
|---|---|---|
| **Where** | Concordance and Zenith | every town **past Pennycross** |
| **Prices** | floating, set by players | **static**, per-town |
| **Scope** | global, one shared book | local |
| **Tax** | 10%, split evenly both sides | — |

### 4b.6 ⭐ The trade loop

Static local prices plus a floating global price is an **arbitrage engine**, and
that is deliberate:

> Travel to a town, buy what is cheap *there*, carry it back, sell it on the
> Concord Market for the global price.

Every travel mechanic above is a lever on that loop: **mounts' cargo** caps the
profit per trip, **mounts' speed** caps trips per hour, **boats** move bulk, and
**teleports** cut the outbound leg but strand your animal.

⭐ **Pennycross earns a sharper job from this.** Shops start *past* it, so
Pennycross is the last fixed-price town and the first place a price difference
is visible — a better tutorial beat than "teaches buying and selling", which is
what §4 of GAME_DESIGN currently claims. Update that line when this is built.

⚠️ **The risk this had to solve: a static buy price permanently below the market
floor is a gold faucet.** Players drive the *market* price down by flooding
supply — that half is self-correcting — but the *town* price never moves, so the
spread would only ever close from one side.

✅ **The ruling: shop stock is per-player, limited, and restocks daily.** Each
player has their own inventory at each shop, capped per day and replenished
overnight. That caps the faucet at *N players × daily stock* instead of
infinity, and it does it without any price simulation.

⭐ **It also makes the trade loop a daily route rather than a grind.** You cannot
stand in one shop and drain it; you visit several, take what each has, and come
back tomorrow. That is a far better shape for a game with travel times in it —
the constraint pushes players outward across the map instead of into a loop of
one edge.

- 📝 Some town prices should still sit *above* market, or routing is solved once
  and never thought about again.
- ❓ Open: whether shops also *buy* from players (a price floor, and a second
  faucet to watch).

---

## 5. Ideas salvaged from the rejected plates

Plates II and III were not adopted as maps, but three things from them are:

| From | Idea | Status |
|---|---|---|
| III | **The 2 800 m tree line** | ✅ adopted (§3.1) |
| III | Altitude ≠ difficulty, stated explicitly | ✅ adopted (§3.2) |
| II | **Every tier's counter triangle opens with its radiant element** — Pyro ▸ Flora, Electro ▸ Aero, Solar ▸ Lunar, Sanctus ▸ Umbra. Verified against `_counters` in `element.dart`, not asserted anywhere in the docs. | 📝 true and unused — a possible hook for lore or UI grouping |
| II | Zenith at the hub / equidistant from everywhere | ❌ superseded by Zenith-at-the-summit, which achieves the same end |

---

## 6. Gazetteer

Every place, with the text the game can show. Each entry carries:

- **Blurb** — one line, for the map and travel screens.
- **Arrival** — shown on first entry. Second person, present tense, no
  exposition about game systems.
- **Here** — the mechanical contents.

⚠️ **The level shown is the *enemy* level, not a requirement** (GAME_DESIGN §5).
The UI must make that unmistakable or players will read "58–60" as "come back
at 58" and never return.

📝 All arrival text is a **first draft** — written to establish voice and length,
not locked.

---

### 6.1 Primal — the basin · Lv 1–14 · 0–1 000 m

#### 🏠 Aldermere · town · 240 m
> **Blurb** — A wooded river valley where every mage begins.
>
> **Arrival** — Alders lean over the water, and the whole valley smells of wet
> bark and woodsmoke. Someone is sharpening something. Nobody looks up when you
> pass, which is its own kind of welcome.
>
> **Here** — Woodcarving. Felling in the woods around. The Primal guard who
> wants to see your three proofs before he opens the north road. An **Adamant
> Vein** you cannot touch until Mining 40.

#### Whispering Woods · pure · Flora · Lv 1–5 · 300 m
> **Blurb** — Sun-dappled woods that murmur when nothing is moving them.
>
> **Arrival** — The murmur is not wind. It comes from the ground, from the roots
> crossing under the path, and it stops the moment you stand still to listen.
>
> **Here** — The best Flora motes in the world. Felling. First-clear reward.

#### Glimmerbrook · pure · Aqua · Lv 3–8 · 180 m
> **Blurb** — Springs and shallows east of Aldermere, bright enough to hurt.
>
> **Arrival** — The brook runs over pale stones and throws the light back at
> you in pieces. Fish hang in the current without swimming. The water is colder
> than the season should allow.
>
> **Here** — Best Aqua motes. Foraging along the banks.

#### Cinderpeak Foothills · pure · Pyro · Lv 6–11 · 950 m
> **Blurb** — The first rise north, where the ground is warm through your boots.
>
> **Arrival** — The grass gives out and the slope turns to grey grit that
> shifts under you. Somewhere above, the mountain is breathing. The air tastes
> of struck flint.
>
> **Here** — Best Pyro motes. Mining. The descent to The Molten Deep.

#### Thornmire · hybrid · Flora + Aqua *(Flora ▸ Aqua)* · Lv 8–13 · 0 m
> **Blurb** — Where the woods drown in the brook's outflow.
>
> **Arrival** — The path becomes a suggestion, then a rumour, then water. Trees
> stand in it up to their knees and have made peace with that. Everything green
> here is winning.
>
> **Here** — Flora **and** Aqua motes from one zone. Bog-iron and reed
> materials found nowhere else. Denser encounters than a pure zone of its level.

#### Ashfall Vale · hybrid · Pyro + Flora *(Pyro ▸ Flora)* · Lv 10–14 · 700 m
> **Blurb** — Downwind of the cone: the burn scar where ash falls on forest.
>
> **Arrival** — Grey settles on every leaf until the whole valley looks like a
> charcoal drawing of itself. New shoots are already pushing up through it.
> Fire came through here, and something is arguing about whether it won.
>
> **Here** — Pyro **and** Flora motes. Ashwood, which only grows back burnt.
> ⭐ The proving ground for the Pyro ▸ Flora matchup.

#### ⛲ Pennycross · town · 360 m
> **Blurb** — The first market, where the river road crosses the mountain road.
>
> **Arrival** — Two roads meet and a town happened. Stalls have grown into
> buildings, and the buildings still look like stalls. Everyone is halfway
> through a transaction.
>
> **Here** — Buying and selling, taught before Concordance turns trade into a
> system. No crafting station on purpose.

---

### 6.2 Kinetic — the range · Lv 15–29 · −400–2 500 m

#### ⛏️ Forgeholm · town · 1 080 m · **unlocks Kinetic (L15)**
> **Blurb** — The last flat ground before the Ironspine.
>
> **Arrival** — The town is built into the hill rather than on it. Ore goes in
> one end and comes out the other as something with a name. It is never quiet
> and never cold.
>
> **Here** — Metalworking. Mining. The road into the range.

#### Old Quarry · pure · Geo · Lv 15–19 · 1 400 m
> **Blurb** — Cut into the range's southern flank, and cut too deep.
>
> **Arrival** — Terraces step down into shadow, each one squarer than anything
> nature makes. The tool marks are old. Whatever was quarried out of here left
> a shape, and the shape has started to move.
>
> **Here** — Best Geo motes. Mining. The upper entrance to The Molten Deep.

#### Stormcliff Coast · pure · Electro · Lv 17–22 · 430 m
> **Blurb** — Where the western ocean's weather hits a wall and has nowhere to go.
>
> **Arrival** — The cliffs take the whole Atlantic of it. Spray comes up further
> than it should and your hair lifts before you hear the crack. The rock is
> scorched in long vertical lines.
>
> **Here** — Best Electro motes. Fulgurite, formed where lightning meets sand.

#### ⚓ Galehaven · town · 5 m
> **Blurb** — The one notch in a hundred miles of cliff.
>
> **Arrival** — The harbour is impossibly calm for what is happening outside it.
> Cloth and dye come off the boats in bales; nothing here is made locally except
> the ships.
>
> **Here** — Tailoring. Foraging. ⭐ **The sea passage to Tidewrack Shoals** —
> the reason to come back at level 36.

#### Windward Steppe · pure · Aero · Lv 19–24 · 1 900 m
> **Blurb** — A high tableland east of the crest, scoured flat.
>
> **Arrival** — Nothing here is taller than your knee, and everything leans the
> same way. The wind does not gust; it simply blows, and has been blowing since
> before there was anyone to notice.
>
> **Here** — Best Aero motes. Foraging.

#### Frostfell Pass · hybrid · Aqua + Aero · Lv 21–26 · 2 500 m
> **Blurb** — The way through. Sea air lifted over the crest and frozen there.
>
> **Arrival** — The pass is a white corridor between two black walls. Your
> breath goes up and does not come down. The road is under here somewhere,
> and other people have been sure of that too.
>
> **Here** — Aqua **and** Aero motes. ❄️ **Ice** exists nowhere else — every
> recipe that wants it wants this place. ⭐ The road north *must* use the pass.

#### Thunderspire Peaks · hybrid · Electro + Aero *(Electro ▸ Aero)* · Lv 23–28 · 2 400 m
> **Blurb** — The summit line where coastal storm meets steppe wind.
>
> **Arrival** — You are inside the weather rather than under it. The cloud is
> lit from within at intervals, and the intervals are getting shorter. Metal
> hums.
>
> **Here** — Electro **and** Aero motes. ⭐ The proving ground for Electro ▸ Aero.

#### The Molten Deep · hybrid · Pyro + Geo · Lv 25–29 · **−400 m**
> **Blurb** — Under the quarry, under the mountain, under the sea's level.
>
> **Arrival** — The quarry's deepest gallery keeps going after the tool marks
> stop. The rock gets warm, then hot, then lit from below. There is a floor
> down here that moves like water because it is not water.
>
> **Here** — Pyro **and** Geo motes. **Magma** materials found nowhere else.
> ⚠️ The only place in the world below sea level — it wants interior art, not
> outdoor.

---

### 6.3 Celestial — the high shelf · Lv 30–44 · 1 700–2 700 m

⚠️ **Thin Air applies across this band** (§4.1).

#### 🏛️ Concordance · capital · 1 700 m · **unlocks Celestial (L30)**
> **Blurb** — The trade capital, at the head of navigation on the River Concord.
>
> **Arrival** — Everything that moves by water or road in this world passes
> through here, and the city has arranged itself around that fact. You show
> your Sigil at the gate. Nobody fights you; someone writes your name down.
>
> **Here** — The bank. The **Concord Market** (10% tax, split evenly). Contracts.
> PvP and Academy entrances. Hour-long district buffs. ⭐ **No crafting
> stations, on purpose** — value *moves* here, it is not made here.

#### The Kiln Desert · pure · Solar · Lv 30–34 · 2 100 m
> **Blurb** — A cold high desert in the range's rain shadow, and the sunniest
> ground in the world.
>
> **Arrival** — The air is too thin to hold heat, so the sun burns while the
> wind bites. There is no shade anywhere and no water for a day's walk. Your
> shadow is the hardest-edged thing you have ever seen.
>
> **Here** — Best Solar motes. ⭐ Physically the strongest zone on the map: high
> altitude *and* rain shadow is how the real world builds its sunniest places.

#### The Mirrormere · pure · Lunar · Lv 32–37 · 2 400 m
> **Blurb** — A high still lake that holds the moon better than the sky does.
>
> **Arrival** — Not a ripple. The surface gives you back the mountains, the
> stars, and the moon at a size the moon has no right to be. Walking the shore,
> you are careful not to look down for too long.
>
> **Here** — Best Lunar motes. ❓ Whether the reflected phase matches the real
> one is a mechanic waiting to be used.

#### Starfall Basin · pure · Astral · Lv 34–39 · 2 300 m
> **Blurb** — A crater field, preserved because nothing grows to cover it.
>
> **Arrival** — Bowl after bowl in the pale ground, each with something at the
> bottom that is not from here. Nothing has grown over them because nothing
> grows. At night the sky is so clear it looks like a threat.
>
> **Here** — Best Astral motes. Star-iron from the crater floors.

#### 🔭 Meridian · town · 2 600 m
> **Blurb** — An observatory on the crest of the Scarp: the highest dark-sky
> ground there is.
>
> **Arrival** — A town of long roofs that open. Everyone keeps different hours
> and nobody explains. From the crest you can see the desert on one side and,
> on the other, a valley with no light in it at all.
>
> **Here** — Enchanting — the only skill that works on motes rather than
> matter, and the only town where it can be practised.

#### Tidewrack Shoals · hybrid · Lunar + Aqua · Lv 36–40 · **20 m**
> **Blurb** — Tides that obey the moon exactly, on the northern shore.
>
> **Arrival** — The water goes out further than seems survivable and comes back
> faster. What it uncovers has been down there a long time. Everything is
> timed to something overhead.
>
> **Here** — Lunar **and** Aqua motes. ⭐ **Reached by sea from Galehaven, not
> by the climb** — the port's endgame purpose.

#### The Sunless Reach · hybrid · Solar + Lunar *(Solar ▸ Lunar)* · Lv 38–42 · 2 650 m
> **Blurb** — The Scarp's north face. Direct sun never reaches the floor.
>
> **Arrival** — You come over the crest out of glare into a valley that has
> never been lit. The rock is the same rock. The desert is a thousand feet away
> and on the other side of the world.
>
> **Here** — Solar **and** Lunar motes. ⭐ The proving ground for Solar ▸ Lunar —
> and both faces of one ridge.

#### The Shattered Orrery · hybrid · Astral + Electro · Lv 40–44 · 2 500 m
> **Blurb** — A broken model of the heavens, still trying to run.
>
> **Arrival** — Rings the size of bridges, half of them fallen, and the fallen
> half still turning. The arcing is not weather; it is the mechanism. Something
> is being calculated and has been for a very long time.
>
> **Here** — Astral **and** Electro motes. Orrery brass. ⚠️ Its lightning is
> mechanical, not meteorological — the one hybrid whose second element comes
> from a *made* thing.

---

### 6.4 Ethereal — the climb · Lv 45–60 · 2 900–5 200 m

⚠️ **Enemies here out-level you by up to ten. Gear closes the gap, not XP**
(GAME_DESIGN §5). Everything in this band is above the tree line.

#### 🏔️ Rimeholt · town · 2 900 m · **unlocks Ethereal (L45)**
> **Blurb** — Basecamp. The last mortal outpost, above the tree line.
>
> **Arrival** — There is no wood here, so nothing is built of it. The town is
> stone and rope and hide, dug in against a slope that goes up out of sight.
> Everyone you meet is either arriving or leaving; nobody is *from* here.
>
> **Here** — Jewelry — the deep stone is where gems come from and the last
> outpost is where they get cut. Mining. The charged Celestial Totem passes the
> barrier above the town.

#### Hallowmarch · pure · Sanctus · Lv 45–49 · 3 150 m
> **Blurb** — The Vault's south flank: a consecrated causeway up the only side
> that thaws.
>
> **Arrival** — A raised road, and someone built it. The sun reaches this face
> for a few hours and the meltwater runs beside you the whole way. Every mile
> or so there is a marker, and every marker has been maintained.
>
> **Here** — Best Sanctus motes. 📝 **Not a marsh** — *march* in the older
> borderland sense. Glacial meltwater on a thawing face.

#### The Umbral Wastes · pure · Umbra · Lv 47–51 · 3 600 m
> **Blurb** — The Vault's north face. No direct sun at any hour of any day.
>
> **Arrival** — You round the shoulder and the light stops. Not dusk — an
> absence with an edge to it. The ice here has never melted and holds its shape
> like something that has been thought about.
>
> **Here** — Best Umbra motes. ⭐ The dark needs no magical cause: a north wall
> at polar latitude simply never sees the sun.

#### The Reliquary Deep · hybrid · Sanctus + Umbra *(Sanctus ▸ Umbra)* · Lv 52–56 · 3 300 m
> **Blurb** — A vault bored through the mountain from the lit side to the dark.
>
> **Arrival** — The door is on the warm flank and the far end opens onto the
> ice. In between, a corridor that someone consecrated and someone else did not
> leave alone. It is warmer in the middle than at either end.
>
> **Here** — Sanctus **and** Umbra motes. ⭐ **Literally between its two
> parents** — through the rock rather than across the ground. ⚠️ Interior art.

#### *The upper icefall* · no zone · ~4 000 m
> Deliberately empty. Pure ascent between the Wastes and the crossing, so the
> climb has a stretch that is only climbing.

#### 🚪 Vespergate · town · 4 500 m · **the crossing**
> **Blurb** — Where the ground runs out. The last place with a supply line.
>
> **Arrival** — A fortress at the top of the world, facing the wrong way — not
> outward at an enemy but *upward*, at nothing. Above it the rock goes vertical
> and stops being a route. They have been brewing their own everything for a
> long time.
>
> **Here** — Potions and Alchemy — a threshold fortress that cannot resupply
> from behind has to brew its own. ⭐ **The only door out of the world.**

#### ✧ Zenith · town · 5 200 m · **sealed until the Crown is finished**
> **Blurb** — The summit. Visible from everywhere below, and shut.
>
> **Arrival** *(on opening)* — The doors were never locked from the inside. From
> up here the whole world is one thing, and every city you have ever walked
> into is a mark on it you could put a finger over.
>
> **Here** — **Every crafting station** — the only town with all six. Teleports
> to every other city. The **Concord Market** — the *same* order book as
> Concordance, a second door, never a second market. The unbinding enchant. Post-cap
> XP→motes. Tier IV set assembly.
>
> ⚠️ **Reached from above, through the Citadel.** The last pitch cannot be
> climbed.

---

### 6.5 The Empyrean — above the veil · Lv 50–60 · *no elevation*

⚠️ **No weather. No moon** (§4.2). Nothing here has an altitude.

#### The Collapsed Academy · pure · Arcane · Lv 50–54
> **Blurb** — A school that read too far, and left.
>
> **Arrival** — It is not ruined so much as *unfinished in the wrong
> direction*. Staircases arrive at rooms that were never built. The syllabus is
> still on the wall and the last three items on it are not in any language you
> have.
>
> **Here** — Best Arcane motes. ⭐ Arcane is the only element with no natural
> referent, which is why it is the only one that needed a non-place.

#### The Unwritten Library · hybrid · Umbra + Arcane *(Umbra ▸ Arcane)* · Lv 54–58
> **Blurb** — Knowledge that eats its keeper. The shelves are still filling.
>
> **Arrival** — Every book here is being written right now, by nobody. The
> shelves go up past where a ceiling would be. Something is taking dictation
> and it would like your name for the record.
>
> **Here** — Umbra **and** Arcane motes. ⭐ Proving ground for Umbra ▸ Arcane.

#### 🏰 The Eclipsed Citadel · final dungeon · **all twelve elements** · Lv 58–60
> **Blurb** — The door back into the world, and the thing standing in it.
>
> **Arrival** — Below it, through a gap in nothing, is the summit of the
> mountain you could not climb. The Citadel is between you and it. That is what
> the name has always meant.
>
> **Here** — All twelve elements at once — ⭐ no five-slot loadout counters
> everything, so it tests whether you can *adapt* rather than *specialise*.
> Difficulty starts at 100% and scales without a fixed ceiling. First clear
> drops the **crown with twelve empty gem slots**. Beyond it: the summit, and
> Zenith.

---

## 7. Open questions

| Question | Blocks | Owner doc |
|---|---|---|
| ❓ Thin Air magnitude; flat or altitude-scaled; how acclimatisation is bought | Celestial tuning | this doc §4.1 |
| ❓ Does Astral get a compensating quirk in the Empyrean, or is no-moon one-sided? | Empyrean rules | this doc §4.2 |
| ❓ Does the Mirrormere's *reflected* phase differ from the real one? | a Lunar mechanic | TYPE_EFFECTS |
| ❓ What the three Primal proofs actually are | Aldermere's gate | GAME_DESIGN §3 |
| ❓ Are assembled gate objects consumed or kept? (The Totem wants to be keepable) | gate items | GAME_DESIGN §3 |
| ❓ Core drop rate, sized against *twelve* for the crown | endgame pacing | ITEMS §6.0 |
| ❓ Concordance's hour-long buffs — needs the real-time buff machinery | capital content | ITEMS §6b.1 |
| ❓ Does the mini-boss/boss pool reroll per run or per day? | zone replay | GAME_DESIGN §3d |
| ⚠️ **Bestiary must grow**: 3–5 mini-bosses and 1–2 bosses *per zone* | the enemies pass | GAME_DESIGN §3d |
| ✅ ~~`world.dart` does not match this document~~ — **rebuilt**, 32 places, guarded by `test/world_test.dart` | — | done |
| ⚠️ Zone gates are recorded as data (`GameLocation.gate`) but **not enforced** — nothing checks them yet | Phase 5 | IMPLEMENTATION_PLAN |
| ⚠️ Zenith's teleports are **one-way** in the graph; the return trip needs the Crown check | Phase 5 | IMPLEMENTATION_PLAN |

### 7.1 ⚠️ Discrepancy found while taking inventory

GAME_DESIGN §5's map section is headed **"12 pure zones + 9 hybrids"**, but its
own tables list **ten** hybrid rows plus the Citadel. The header is the wrong
part. Counted twice.

---

## 8. Revision history

**Rev 2** (2026-07-26) — `world.dart` rebuilt from Plate I-b: 32 locations with
tier, plane, elevation, station, gate, blurb and arrival text; the walkable
graph; Zenith's teleport net. Added `WorldPlane`, `World.treeLineMetres`, and
the `hasThinAir` / `hasMoon` / `isAboveTreeLine` helpers.
`test/world_test.dart` guards graph symmetry, reachability, the two-door Veil
crossing, one-pure-zone-per-element, the tree line, and the Tidewrack/Molten
Deep exceptions.

📝 **No save migration.** The game is in beta with no single-player progression
built — no bestiary, no way to advance between areas — so there is nothing to
convert. `World.byId` still falls back to the start town for an unrecognised id,
which is enough. Revisit only once real progression exists to lose.

**Rev 1** (2026-07-26) — Created. Settles the physical geography after a
five-plate design pass: the world rises rather than spreads; **The Vault** named;
Celestial confirmed as physical high shelf (Concordance and Meridian make it
near-mandatory); **The Empyrean** added above the veil holding only the three
Arcane places; the Citadel established as the way *back in* at the summit;
Zenith fixed as the sealed summit; **Thin Air** assigned to Celestial with the
asymmetry and legibility caveats; **no moon** in the Empyrean; tree line pinned
at 2 800 m; altitude explicitly divorced from difficulty; Tidewrack-by-sea and
the Molten Deep's descent kept as deliberate exceptions; Hallowmarch released
from being a marsh. Full gazetteer with first-draft player-facing text for all
32 places.
