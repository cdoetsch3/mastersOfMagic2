# World Design — geography, places, and in-game text

Status: 📝 **draft — geography built, content not.** `lib/game/world.dart` now
matches this document: all 32 places, the two planes, the graph and
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
[docs/plates/](plates/) — open any of them directly in a browser.

| Plate | Shows | Verdict |
|---|---|---|
| [**I**](plates/plate-1-known-world.html) | plan view, climate causation | superseded by I-a/I-b |
| [**II**](plates/plate-2-wheel.html) | concentric wheel — rings and marches | ❌ not adopted; two ideas salvaged (§5) |
| [**III**](plates/plate-3-long-ascent.html) | elevation section, places numbered by height | ❌ not adopted; ⚠️ its altitudes are **no longer canon** |
| [**I-a**](plates/plate-1a-the-climb.html) | plan view + ascent — the finale becomes a climb | superseded by I-b |
| ✅ [**I-b**](plates/plate-1b-one-crossing.html) | **the settled map** — one world, one crossing | **canonical** |

---

## 1. The four decisions that shape everything ✅

### 1.1 ✅ The world rises; it does not spread

The Ironspine does not end in a polar plain. It **culminates in a single
massif, The Vault**, and the last two tiers are its shelf and its ascent.

⭐ **Why.** A world that spreads outward makes late content "far away", which is
a claim the player has to be told. A world that rises makes late content
*above*, which they can see. It also converts the campaign into one continuous
gradient — sea to summit — instead of four regions in a row.

### 1.2 ✅ One world, one crossing — and only Celestial+ may leave it

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

#### ✅ Amendment (2026-08-02) — the off-world rule is a guideline

The original rule was **"only Arcane leaves the world"**, and every Arcane place
sat above the Veil. The Glass Archive (§4c.1c) is Solar + Arcane and stands on
the ground, which broke it.

✅ **Christian's ruling: that was never meant to be strict.** It is a
**guideline**, and the latitude is wider than Arcane — **anything Celestial or
above may sit off-world**: Solar, Lunar, Astral, Sanctus, Umbra, Arcane.

⚠️ **What IS strict is the other direction, and it is the half worth
guarding:** ⭐ **Primal and Kinetic elements are physical and must stay on the
ground.** Pyro is fire, Aqua is water, Geo is stone, Aero is wind — none of
them has any business above the Veil, in a place §2.4 gives no ground, no
weather and no moon. `test/world_test.dart` enforces exactly that, and nothing
narrower.

⭐ **Why the looser rule is the better one.** The old version was really two
claims wearing one coat: *"Arcane has no natural referent"* (true, and still
the reason the Empyrean is Arcane-flavoured) and *"therefore no other element
may leave"* (never argued for, and it was the half that broke). Splitting them
keeps the good argument and drops the one that was only ever a side effect.

⚠️ **The Empyrean is still capped at three places, not a tier** — that limit is
about art cost and about the finale happening somewhere the player has a stake
in. Loosening *which* elements may go off-world does not loosen *how many*
places are up there.

⭐ **And the Glass Archive still earns its ground on its own terms:** it is a
Solar hillside covered in lenses. Arcane is what was *done* there, not what
lives there — which is why it reads as the door Arcane left through rather than
as a home it kept.

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

Zenith sits at the apex of The Vault. It is **visible for the whole
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

- **No ground.** Places above the veil are not on the world at all.
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
| **Tidewrack Shoals** — Lv 36–40 | Reached **by sea from Galehaven**, not by ascent. ⭐ This finally gives the port an endgame purpose, which §4 of GAME_DESIGN was explicitly hunting for. |
| **The Molten Deep** — Lv 25–29 | The one zone that goes *down*. The mirror of everything else, and exactly right for magma reached through a quarry. |

---

## 3. The vertical structure ✅

| Tier | Band | Climate & character | Lv |
|---|---|---|---|
| **Primal** | the basin | Low, temperate, well-watered. The only part of the world with ordinary weather. | 1–14 |
| **Kinetic** | the range | Where the ground takes over from the climate. Stone, storm, wind. | 15–29 |
| **Celestial** | the high shelf | Thin air, brutal sun, hard dark. The heavens touching the ground. | 30–44 |
| **Ethereal** | the climb | Above the tree line. Ice, rock, and the two faces of one mountain. | 45–60 |
| **The Empyrean** | beyond the Veil | No ground, no weather, no moon. | 50–60 |

📝 **Altitude is described, not tracked.** ⚠️ An earlier revision gave every
place a figure in metres and pinned the tree line at 2 800 m. That is
**removed**: nothing consumed the numbers, they invited a precision the design
does not need, and the *map* carries the world's rise far better than a column
of figures ever did — ice, ranges, and the Vault standing over everything.

⭐ **What survives is the shape**, which is what mattered: basin, range, shelf,
climb. Rimeholt is still "the last mortal outpost, above the tree line" — that
describes a place, and it needs no number to be true.

### 3.1 ⚠️ Height is not difficulty

**A place's level band is not a function of how high it stands.** Three
deliberate exceptions make the point, and must survive any tidying:

- **Tidewrack Shoals** — Celestial-band content on a *shore*, reached by sea
  from Galehaven rather than by climbing.
- **The Molten Deep** — Kinetic content reached by going *down*, through the
  Old Quarry.
- **Ashfall Vale** — late-Primal content well up the volcanic slope.

Guarded by `test/world_test.dart`, which now asserts the *intent* — that
Tidewrack connects to the port and the Molten Deep is an interior under the
quarry — rather than any figure.

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
- ❓ Magnitude, and whether it varies across the shelf or is flat.
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

### 4b.3b ✅ Earning a tier-5 mount — the tack chain

✅ **All three are earned in the Eclipsed Citadel**, which gives the endless
dungeon a reward that is not just gear, and closes the loop between the campaign
and the economy.

✅ **The chain:**

1. The Citadel's final boss rarely drops a piece of **tack** — a **saddle**, a
   **bridle**, or **reins**. ✅ **One set per mount**, so the pieces are
   mount-specific: the Veilcourser's bridle is not the Hallowbearer's.
2. Hold a **complete set of three**, then clear the Citadel **once more**.
3. ✅ The mount is yours.

⭐ **The re-clear is a taming, not a repeat.** This is the detail that keeps the
final step from reading as "do it again because we said so": the tack is useless
on its own, and *the creature lives in the Citadel*. Carrying a complete set is
what lets you take it.

✅ **The taming is a cutscene, not an encounter** — an animation on completion,
not a second interactive fight. Cheap to build, and it keeps the reward as a
*moment* rather than another skill check after the one that already mattered.

⭐ **Three simultaneous reasons to re-run the Citadel.** With the Concordant
Crown (§GAME_DESIGN 3a) and the endless difficulty ladder (§3c) already there,
the tack chain makes a third. An endless dungeon with one goal is a grind; with
three overlapping ones it is a rotation.

✅ **Higher difficulty improves rare-drop odds** — and 📝 possibly clear
*streaks* too. That is what makes the endless ladder pay for itself: pushing
higher is how you farm tack and Crown components faster, rather than being a
separate score-chasing activity bolted on beside them.

✅ **The Crown drops on *every* clear, and is skipped if the player already holds
one.** Checking-then-skipping rather than first-clear-only costs nothing and
quietly covers the case where a player loses it — ⭐ which matters a great deal
now that nothing is exempt from cargo loss.

📝 **The Citadel's content load is lighter than its design weight suggests.** It
has had more design attention than any other zone, which makes it *feel* like
the biggest build. In practice: the twelve-element boss just means every element
unlocked on one enemy; the Crown and the nine tack pieces are entries on a rare
drop table; the taming is an animation. The genuinely new mechanic is the
difficulty ladder. Other zones will get comparable design passes and land in the
same place.

📝 **This is the fifth time the world uses "collect three, then return"** — the
four tier gates (proofs, Sigil, essences, key fragments) and now the tack. That
is deliberate rhyme rather than repetition: it is the game's signature shape, and
the Crown's twelve-and-twelve is the same idea at maximum scale. ⚠️ But it does
mean the *fiction* has to keep varying, the way the four gates escalate from a
guard to a bureaucracy to a barrier to a lock with nobody behind it.

✅ **Every tack piece is tradable on the Concord Market — and so is the finished
mount.** That is the answer to the coupon-collector problem: nine distinct rare
drops across three sets would be punishing to complete from personal luck alone,
but a liquid market means the last piece is a *purchase* rather than a wall. The
grind converts into gold, which is what the trade economy is for.

⚠️ **Drop rates still want checking against the market, not against a solo
player.** With tradability the question changes from "how long to complete a set
alone" to "does enough supply enter the economy" — a rate tuned for solo
completion would flood it.

✅ **Nothing is exempt from cargo loss — including tack.** Journey risks
everything you carry, deliberately. Holding something rare is precisely when you
should be taking **Travel**, and choosing to Journey anyway is a real gamble with
a real consequence. ⭐ The severity is the point: an exemption list would quietly
remove the only teeth the mode has.

💡 **Possible softener — N items kept.** A small number of slots the player
*chooses* to protect on a loss. Worth exploring because it keeps the tension
(you must decide what matters) while removing the worst outcome (losing the one
thing you cannot replace). ⭐ Direct precedent in the project's stated north star:
RuneScape's items-kept-on-death, where the count itself is a thing you can raise.
❓ Undecided — count, whether it is bought or earned, and whether it applies to
PvP.



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

## 4c. ⭐ Element coverage across the world — audit + the late-zone question

**Measured from `world.dart`, 2026-08-02.** 22 element-bearing zones; the
Eclipsed Citadel is excluded (it carries all twelve).

| Element | Zones | Highest band | Where it appears |
|---|---|---|---|
| **Aqua** | 4 | 40 | Glimmerbrook 3–8 · Thornmire 8–13 · Frostfell Pass 21–26 · Tidewrack Shoals 36–40 |
| **Flora** | 3 | ⚠️ **14** | Whispering Woods 1–5 · Thornmire 8–13 · Ashfall Vale 10–14 |
| **Pyro** | 3 | 29 | Cinderpeak 6–11 · Ashfall Vale 10–14 · The Molten Deep 25–29 |
| **Electro** | 3 | 44 | Stormcliff 17–22 · Thunderspire 23–28 · Shattered Orrery 40–44 |
| **Aero** | 3 | 28 | Windward Steppe 19–24 · Frostfell Pass 21–26 · Thunderspire 23–28 |
| **Lunar** | 3 | 42 | Mirrormere 32–37 · Tidewrack 36–40 · Sunless Reach 38–42 |
| **Umbra** | 3 | 58 | Umbral Wastes 47–51 · Reliquary Deep 52–56 · Unwritten Library 54–58 |
| **Geo** | ⚠️ 2 | 29 | Old Quarry 15–19 · The Molten Deep 25–29 |
| **Solar** | ⚠️ 2 | 42 | Kiln Desert 30–34 · Sunless Reach 38–42 |
| **Astral** | ⚠️ 2 | 44 | Starfall Basin 34–39 · Shattered Orrery 40–44 |
| **Sanctus** | ⚠️ 2 | 56 | Hallowmarch 45–49 · Reliquary Deep 52–56 |
| **Arcane** | ⚠️ 2 | 58 | Collapsed Academy 50–54 · Unwritten Library 54–58 |

⭐ **The headline: count was never really the problem — spread is.** The target
of 3–4 zones per element is already nearly met; the range is 2–4, and no
element is starved outright. ⚠️ **But Flora is the only element whose zones
all end early.** Every other element reaches at least band 28; Flora stops at
**14**. A player who falls for Flora in the tutorial has 46 levels with nothing
to look forward to, while an Aqua player gets a zone in every quarter.

⚠️ **The second finding, and it is the one that matters more:** the **Ethereal
quarter is the thinnest stretch of the game** — 5 zones drawing on only 3
elements (Sanctus, Umbra, Arcane) to cover levels 45–58. ⭐ **Zone count per
quarter is flat, but time-per-level is not.** Levels 45→60 take far longer to
earn than 1→14, so the same five zones must sustain several times the play
hours. That is the real gap, and it is exactly where Christian expected it.

### 4c.1 📝 Proposal — two late hybrid zones

⭐ **One change fixes all three problems at once:** put the new zones in the
45–60 band, and pair an Ethereal element with an under-used earlier one.

| Zone | Elements | Effect |
|---|---|---|
| ✅ **The Sealed Garden** — Flora + Sanctus | flora 3 → **4**, sanctus 2 → **3** | ⭐ Gives Flora its late home. See §4c.1a |
| ✅ **The Buried Sky** — Geo + Astral | geo 2 → **3**, astral 2 → **3** | Both topped out mid-game. See §4c.1b |

| ✅ **The Glass Archive** — Solar + Arcane | solar 2 → **3**, arcane 2 → **3** | Fills the thinnest stretch in the back half. See §4c.1c |

✅ **Result: every element now sits at 3 or 4 zones** — the target met exactly,
with nothing starved and nothing dominant. `test/world_test.dart` asserts the
3–4 range rather than a floor, so any future zone that unbalances it fails.

✅ **All three zones are now BUILT** (`world.dart`, `world_map_geometry.dart`), and
`test/world_test.dart` guards the outcome: no element may fall below 2 zones,
and ⚠️ **no element may top out below band 28** — the guard against the
"Flora dies at 14" bug recurring. ⚠️ **Solar and Arcane remain at 2**, which is
the one place this still falls short of the 3–4 target.

⭐ **Flora + Sanctus is the strong one, and it pays off the Primal arc
directly.** Sanctus is consecration — temples, oaths, reliquaries
(GAME_DESIGN §5). A consecrated place that Flora has grown through and
outlived is a premise that needs both elements to state, which is the bar
§2d sets for a hybrid. ⭐ **And it closes a 45-level loop:** the first thing
the game teaches is that the wood in Whispering Woods is one aware organism.
Meeting that same organism at level 50, having outlasted a religion, is the
payoff for a lesson learned at level 1.

⚠️ **Sanctus naming trap:** GAME_DESIGN §5 warns that a Sanctus name which
could plausibly be Solar is the wrong name. The same applies to the zone —
this must read as *overgrown consecration*, never as *sunlit grove*.

### 4c.1a ✅ The Sealed Garden — Flora + Sanctus, and it is Eden

✅ **Christian's call: play the Garden of Eden reference heavy-handed.** Not a
sly allusion — the zone *is* the garden, and should be recognised as such
within seconds of arriving.

⭐ **Theme: the garden is still perfect, it is still guarded, and you are still
not allowed in.**

⭐ **The turn that makes it more than a costume:** the religion that set the
guard is **gone**. Hallowmarch is a march, the Reliquary Deep is a *deep* —
Sanctus in this world is already something in decline. Nobody has come to
relieve the watch in an age, and the watch has not noticed. ⚠️ **The guardians
are not defending a faith. They are keeping a promise that outlived everyone
who cared about it.** That is a colder idea than "overgrown temple", and it is
the version to write.

#### ⭐ Why this zone earns its place in the story, not just the level curve

The endgame is the **Concordant Crown** — twelve elements brought into accord.
⭐ **The Sealed Garden is the proof that the accord already happened once.** A
place where the elements agreed, and which was then shut. That reframes the
whole endgame: the crown is not inventing something new, it is **restoring
something that was taken away** — and the player has *stood outside the gate
of it* at level 50.

⭐ **It also closes the loop opened in the first five minutes of the game.**
Whispering Woods teaches that the wood is one aware organism (ENEMIES §2d).
The Sealed Garden is that same awareness fifty levels later, and it has been
keeping a rule since before the player's civilisation existed.

#### Roster — the Eden furniture, mapped by the §2b rule

| Common | Archetype | Fiction |
|---|---|---|
| **Orchard Warden** | Sentinel | Rooted at the tree it was set to watch; has not moved in an age |
| **Windfall** | **Siphon** | ⭐ Fallen fruit that drinks whoever picks it up — *the temptation, written as a stat block* |
| **Whisperling** | Blighter | A small coiled thing in the branches. It offers you something. It talks |
| **Chorister Vine** | Adept | A vine still singing the hours to an empty cloister |
| **Thornpenitent** | Bruiser | Briar grown through and around a kneeling figure |

**Mini-bosses:** **Cherub of the Turning Blade** (⭐ the flaming sword that
turns every way — the single most recognisable image in the myth) · **The Last
Gardener** (⭐ the only mortal still inside, and *not hostile until you reach
for anything*) · **Root Matriarch** (✅ re-homed from the orphaned Flora roster)
· **The Kept Vow** (an oath with a body).

**Bosses — ⭐ and the pool IS the theme again:**

| Boss | It is |
|---|---|
| ✅ **Guardian of the World Tree** | **The rule.** It will not let you in |
| ✅ **The Serpent in the Branches** | **The invitation.** It would very much like to |

⭐ **Which boss you draw decides whether the garden confronts you or tempts
you.** That is the Ashfall Vale pattern (ENEMIES §2d) landing at the opposite
end of the game — the opening hybrid's pool asks *"who won?"*, the closing
hybrid's asks *"will you be let in, or talked in?"* ⭐ **Two hybrid zones, 45
levels apart, using the same structural trick to ask the quarter's central
question. That rhyme is worth protecting.**

✅ **This finally homes `Guardian of the World Tree`**, which GAME_DESIGN §5
flagged as the one element boss with nowhere to go. It was always a name for a
garden with a tree at the middle of it.

#### ⚠️ Guardrails

- ⚠️ **Keep it to the garden myth, not to scripture.** Use the *roles* — the
  Gardener, the Guardian, the Serpent, the Vow — and do not name real
  religious figures or quote text. ⭐ **This is what makes it heavy-handed and
  still unmistakably THIS world's myth** rather than a crossover; it also keeps
  the tone archetypal instead of denominational.
- 🚫 **"Bloom" is reserved** — it was renamed to Photosynthesis across the
  project. No Flora enemy or item here may use it.
- ⚠️ **The Sanctus naming trap** (GAME_DESIGN §5): a Sanctus name that could
  plausibly be Solar is the wrong name. ⭐ Eden imagery helps here — gates,
  orchards, vows and wardens carry no sun imagery at all.
- ⚠️ **Do not seal the zone after clearing it.** The myth's ending is "you may
  not come back", but §4b makes resource areas a standing reason to return, and
  a one-shot zone would be the only one in the game. ⭐ **Put the expulsion in
  the Tier-1 clear passage instead:** you beat the Guardian and the game still
  does not let you take the tree. The beat lands; the content stays repeatable.

#### 📝 Placement — needs map work

📝 **Adjacent to Hallowmarch**, on the Vault massif (§2.3), band **≈49–53** —
between Hallowmarch (45–49) and the Collapsed Academy (50–54). ❓ **Exact band
and travel edges are open**, and adding a zone touches the Floyd–Warshall
routing table and the map painter, so this is a real code task rather than a
data edit.

### 4c.1b ✅ The Buried Sky — Geo + Astral, dungeon, Lv 46–50

⭐ **Theme: the rock remembers a sky that no longer exists.**

Geology is deep time; Astral is the heavens. ⭐ **The fusion is strata as a
record of the sky** — dig down through the bands of stone and each one holds a
scatter of light in it, and none of the patterns match what is overhead now.
Neither element states that alone: Geo supplies the *layers*, Astral supplies
the *heavens*, and the premise is the two read together.

⭐ **Its claim is SCALE, and that is what the quarter was missing.** The other
late zones make claims about accord (the Sealed Garden) and about the elements
contending (ENEMIES §2d). This one says something none of them do: **this has
all happened before, and the record is in the rock.**

⭐ **Why it is a dungeon that goes DOWN in a quarter that goes UP.** The Vault
is the highest rock in the world, so its exposed strata are the oldest
anywhere. ⭐ **You climb to the top of everything in order to go down** — and
that image is the zone. Precedent exists: the Molten Deep and the Reliquary
Deep both descend while the world rises (§2.5).

| Common | Archetype | Fiction |
|---|---|---|
| **Stratum Warden** | Sentinel | Stone laid down in bands; you break through it one age at a time |
| **Constellate** | Lasher | A scatter of star-points that arrives as many small pieces |
| **Fadelight** | Glasswing | ⭐ The last light of a star that is already gone — brilliant, and barely there |
| **Corebiter** | **Siphon** | Chews through rock and takes what it finds |
| **Deadreckoner** | Adept | Navigates by stars that no longer exist, and is still mostly right |

**Mini-bosses:** Bedrock Colossus (Redoubt) · **Nadir** (Executioner — the
lowest point of the shaft) · The Long Count (Hexer) · Stonefall Herald
(Champion).

**Bosses — ⭐ the pool is the tension, as in the other two hybrids:**

| Boss | It is |
|---|---|
| ✅ **The Overburden** | **What buries.** ⭐ A real mining term for the rock sitting on top of a seam — Geo vocabulary that happens to mean exactly the right thing |
| ✅ **The Buried Constellation** | **What survives.** An old star-pattern still alight down here, refusing to be past tense |

⭐ **Which boss you draw says whether the zone is about what buries or what
lasts.** That is now the third hybrid built this way — Ashfall Vale (10–14),
The Sealed Garden (49–53), The Buried Sky (46–50). ⚠️ **Three is where a
pattern becomes a rule**, so it is worth saying plainly: *a hybrid zone's boss
pool should be the two sides of its premise.* Applying it to the remaining
seven hybrids is a real content decision, not an automatic one.

#### ⚠️ Both new zones pair elements across non-adjacent tiers

The Sealed Garden is Primal + Ethereal; The Buried Sky is Kinetic + Celestial
in an Ethereal band. ✅ **That is the point, not an oversight** — reaching back
for under-used elements is the reason these zones exist. The existing guard in
`world_test.dart` only constrains **pure** zones to their element's tier, and
Frostfell Pass (Primal Aqua + Kinetic Aero) is the precedent.

⭐ **The Sealed Garden's pairing is the strongest argument for the whole
approach:** Flora is the first element a player ever meets, Sanctus is among
the last. The zone is *the beginning of the world guarded by the end of it*,
which is a better reason for the pairing than "Flora needed a late zone."

#### ✅ Placement and roads

| Zone | Pin | Roads |
|---|---|---|
| **The Sealed Garden** | (536, 366) | Hallowmarch 6m · Vespergate 7m |
| **The Buried Sky** | (636, 412) | Rimeholt 7m · Vespergate 8m |

⭐ **The Garden's road pays off a passage that was already written.**
Hallowmarch's arrival text reads *"A raised road, and someone built it… every
mile or so there is a marker, and every marker has been maintained."* ⭐ **The
causeway was built to reach the Garden**, and the markers are still maintained
by the same oath that still holds the gate. ⚠️ **That edge is load-bearing
lore, not just a road** — `world_test.dart` asserts it so it cannot be severed
casually.

### 4c.1c ✅ The Glass Archive — Solar + Arcane, dungeon, Lv 43–47

⭐ **Theme: they wrote it in light, and light does not keep.**

An archive that can only be read at noon, and which the reading destroys.

⭐ **The elements wrote this theme, not the designer.** Solar's side-effect is
**Blind**; Arcane's is **Arcane Knowledge**. Put those two together and you get
*too bright to see by, too much to know* — the premise falls out of the
pairing instead of being imposed on it. ⚠️ **That is the standard to hold new
hybrids to**, and it is a stronger test than "do the two elements sound good
together."

#### ⭐ The band is the whole argument

**43–45 is the thinnest three-level stretch in the back half of the game** —
one zone each, measured from `world.dart`:

| Lv | Zones covering it |
|---|---|
| 41–42 | 2 |
| **43** | **1** — Shattered Orrery |
| **44** | **1** — Shattered Orrery |
| **45** | **1** — Hallowmarch |
| 46+ | 2–4 |

⭐ **And Solar and Arcane's own bands bracket that hole exactly.** Solar's last
zone ends at **42**; Arcane's first begins at **50**. A Solar+Arcane zone at
43–47 is the only pairing in the game whose two elements point at the gap by
themselves — it hands off from Solar's last zone to Arcane's first.

⭐ **It also sits where the player is grinding hardest.** The Rimeholt barrier
(a Celestial Totem of Solar, Lunar and Astral essences) is the tier gate at 45,
so 43–45 is simultaneously the least content and the biggest wall. ✅ **The
Archive is placed BELOW the gate** — reached only from The Shattered Orrery —
so it is where a player farms the Totem rather than something the Totem locks.
⚠️ `world_test.dart` asserts that single connection; adding a road from above
the gate would let the Archive bypass the thing it exists to serve.

#### ⭐ It is the prequel to The Collapsed Academy

Arcane is the element that **left the world** (§1.2). The Academy at 50–54 is
"a school that read too far, and left." ⭐ **The Glass Archive is where it was
working from when it was still here.** The player grinds it to earn passage,
crosses the Veil at Vespergate, and finds where that same school ended up.
⭐ **The gate stops being an errand and becomes the seam between the two halves
of Arcane's story.** ✅ Its on-the-ground placement is settled — see the §1.2
amendment, which loosened the off-world rule to a guideline.

#### ⭐ Deliberately the opposite of The Buried Sky

The two sit three levels apart and are both archives, which reads as a
collision until you say the thing out loud:

| Zone | Medium | Claim |
|---|---|---|
| **The Buried Sky** (46–50) | stone | ⭐ The most durable record there is — *it keeps a sky that no longer exists* |
| **The Glass Archive** (43–47) | light | ⭐ The least durable — *it keeps nothing at all* |

⚠️ **State this wherever the two are described**, or someone will later "fix"
the overlap by making one of them something else.

#### Placement

Pin at **(850, 260)** — the far north-east, the remotest and sunniest corner of
the continent, and previously empty map. One road: **The Shattered Orrery, 7m**.

📝 **Roster is not designed.** The anchor name is **Glasswright**
(`opponentNameFor`); commons, four minis and two bosses are still to do. ⭐ The
boss pool should be the two sides of its premise, like the other three hybrids
— presumably *what was written* against *what is left of it*.

### 4c.2 ❓ The quarter-3 amplification event — bank it, but reframe it

Christian's second idea: an event in the third quarter that sends the player
back to re-clear parts of the Primal quarter at amplified level. ⭐ **His own
hesitation is well-placed, and it is worth naming exactly why.**

- ⚠️ **It does not actually solve the Flora problem.** A level-50 Whispering
  Woods is still Whispering Woods. Flora would gain levels, not a *destination*.
- ⚠️ **It works against the story just written.** The Primal arc (GAME_DESIGN
  §5) depends on those five zones being the player's **first impression** —
  the questions the game opens with. Re-running them as a difficulty tier
  dilutes the one part of the game with a settled narrative.
- ✅ **But its strength is real:** it is the cheapest content in the game per
  hour delivered — map, rosters, painters, materials and drop tables all
  already exist. That is not nothing when the Ethereal quarter is thin.

⭐ **The reframe that keeps the strength and drops the cost: make the event the
CAUSE of the new late zones, not a re-clear mechanic.** If something in the
third quarter makes the elements spill into combinations that did not exist
before, then a late Flora+Sanctus zone stops being a balance patch and becomes
a **consequence** — new ground, new rosters, adjacent to the old world without
overwriting it.

⭐ **Why that is strictly better:** the player gets the narrative escalation
(the argument they met at level 1 is spreading), the world gets genuinely new
content rather than a difficulty slider, and the Primal quarter keeps its job
as the opening statement. ⚠️ **The one thing to watch** is that this event
must not compete with the Concordant Crown for being the story's engine — it
should be *evidence* that the elements are drifting apart, which is the
problem the crown exists to answer.

---

## 5. Ideas salvaged from the rejected plates

Plates II and III were not adopted as maps, but three things from them are:

| From | Idea | Status |
|---|---|---|
| III | Height ≠ difficulty, stated explicitly | ✅ adopted (§3.1) |
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

### 6.1 Primal — the basin · Lv 1–14

#### 🏠 Aldermere · town
> **Blurb** — A wooded river valley where every mage begins.
>
> **Arrival** — Alders lean over the water, and the whole valley smells of wet
> bark and woodsmoke. Someone is sharpening something. Nobody looks up when you
> pass, which is its own kind of welcome.
>
> **Here** — Woodcarving. Felling in the woods around. The Primal guard who
> wants to see your three proofs before he opens the north road. An **Adamant
> Vein** you cannot touch until Mining 40.

#### Whispering Woods · pure · Flora · Lv 1–5
> **Blurb** — Sun-dappled woods that murmur when nothing is moving them.
>
> **Arrival** — The murmur is not wind. It comes from the ground, from the roots
> crossing under the path, and it stops the moment you stand still to listen.
>
> **Here** — The best Flora motes in the world. Felling. First-clear reward.

#### Glimmerbrook · pure · Aqua · Lv 3–8
> **Blurb** — Springs and shallows east of Aldermere, bright enough to hurt.
>
> **Arrival** — The brook runs over pale stones and throws the light back at
> you in pieces. Fish hang in the current without swimming. The water is colder
> than the season should allow.
>
> **Here** — Best Aqua motes. Foraging along the banks.

#### Cinderpeak Foothills · pure · Pyro · Lv 6–11
> **Blurb** — The first rise north, where the ground is warm through your boots.
>
> **Arrival** — The grass gives out and the slope turns to grey grit that
> shifts under you. Somewhere above, the mountain is breathing. The air tastes
> of struck flint.
>
> **Here** — Best Pyro motes. Mining. The descent to The Molten Deep.

#### Thornmire · hybrid · Flora + Aqua *(Flora ▸ Aqua)* · Lv 8–13
> **Blurb** — Where the woods drown in the brook's outflow.
>
> **Arrival** — The path becomes a suggestion, then a rumour, then water. Trees
> stand in it up to their knees and have made peace with that. Everything green
> here is winning.
>
> **Here** — Flora **and** Aqua motes from one zone. Bog-iron and reed
> materials found nowhere else. Denser encounters than a pure zone of its level.

#### Ashfall Vale · hybrid · Pyro + Flora *(Pyro ▸ Flora)* · Lv 10–14
> **Blurb** — Downwind of the cone: the burn scar where ash falls on forest.
>
> **Arrival** — Grey settles on every leaf until the whole valley looks like a
> charcoal drawing of itself. New shoots are already pushing up through it.
> Fire came through here, and something is arguing about whether it won.
>
> **Here** — Pyro **and** Flora motes. Ashwood, which only grows back burnt.
> ⭐ The proving ground for the Pyro ▸ Flora matchup.

#### ⛲ Pennycross · town
> **Blurb** — The first market, where the river road crosses the mountain road.
>
> **Arrival** — Two roads meet and a town happened. Stalls have grown into
> buildings, and the buildings still look like stalls. Everyone is halfway
> through a transaction.
>
> **Here** — Buying and selling, taught before Concordance turns trade into a
> system. No crafting station on purpose.

---

### 6.2 Kinetic — the range · Lv 15–29

#### ⛏️ Forgeholm · town · **unlocks Kinetic (L15)**
> **Blurb** — The last flat ground before the Ironspine.
>
> **Arrival** — The town is built into the hill rather than on it. Ore goes in
> one end and comes out the other as something with a name. It is never quiet
> and never cold.
>
> **Here** — Metalworking. Mining. The road into the range.

#### Old Quarry · pure · Geo · Lv 15–19
> **Blurb** — Cut into the range's southern flank, and cut too deep.
>
> **Arrival** — Terraces step down into shadow, each one squarer than anything
> nature makes. The tool marks are old. Whatever was quarried out of here left
> a shape, and the shape has started to move.
>
> **Here** — Best Geo motes. Mining. The upper entrance to The Molten Deep.

#### Stormcliff Coast · pure · Electro · Lv 17–22
> **Blurb** — Where the western ocean's weather hits a wall and has nowhere to go.
>
> **Arrival** — The cliffs take the whole Atlantic of it. Spray comes up further
> than it should and your hair lifts before you hear the crack. The rock is
> scorched in long vertical lines.
>
> **Here** — Best Electro motes. Fulgurite, formed where lightning meets sand.

#### ⚓ Galehaven · town
> **Blurb** — The one notch in a hundred miles of cliff.
>
> **Arrival** — The harbour is impossibly calm for what is happening outside it.
> Cloth and dye come off the boats in bales; nothing here is made locally except
> the ships.
>
> **Here** — Tailoring. Foraging. ⭐ **The sea passage to Tidewrack Shoals** —
> the reason to come back at level 36.

#### Windward Steppe · pure · Aero · Lv 19–24
> **Blurb** — A high tableland east of the crest, scoured flat.
>
> **Arrival** — Nothing here is taller than your knee, and everything leans the
> same way. The wind does not gust; it simply blows, and has been blowing since
> before there was anyone to notice.
>
> **Here** — Best Aero motes. Foraging.

#### Frostfell Pass · hybrid · Aqua + Aero · Lv 21–26
> **Blurb** — The way through. Sea air lifted over the crest and frozen there.
>
> **Arrival** — The pass is a white corridor between two black walls. Your
> breath goes up and does not come down. The road is under here somewhere,
> and other people have been sure of that too.
>
> **Here** — Aqua **and** Aero motes. ❄️ **Ice** exists nowhere else — every
> recipe that wants it wants this place. ⭐ The road north *must* use the pass.

#### Thunderspire Peaks · hybrid · Electro + Aero *(Electro ▸ Aero)* · Lv 23–28
> **Blurb** — The summit line where coastal storm meets steppe wind.
>
> **Arrival** — You are inside the weather rather than under it. The cloud is
> lit from within at intervals, and the intervals are getting shorter. Metal
> hums.
>
> **Here** — Electro **and** Aero motes. ⭐ The proving ground for Electro ▸ Aero.

#### The Molten Deep · hybrid · Pyro + Geo · Lv 25–29
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

### 6.3 Celestial — the high shelf · Lv 30–44

⚠️ **Thin Air applies across this band** (§4.1).

#### 🏛️ Concordance · capital · **unlocks Celestial (L30)**
> **Blurb** — The trade capital, at the head of navigation on the River Concord.
>
> **Arrival** — Everything that moves by water or road in this world passes
> through here, and the city has arranged itself around that fact. You show
> your Sigil at the gate. Nobody fights you; someone writes your name down.
>
> **Here** — The bank. The **Concord Market** (10% tax, split evenly). Contracts.
> PvP and Academy entrances. Hour-long district buffs. ⭐ **No crafting
> stations, on purpose** — value *moves* here, it is not made here.

#### The Kiln Desert · pure · Solar · Lv 30–34
> **Blurb** — A cold high desert in the range's rain shadow, and the sunniest
> ground in the world.
>
> **Arrival** — The air is too thin to hold heat, so the sun burns while the
> wind bites. There is no shade anywhere and no water for a day's walk. Your
> shadow is the hardest-edged thing you have ever seen.
>
> **Here** — Best Solar motes. ⭐ Physically the strongest zone on the map: high
> altitude *and* rain shadow is how the real world builds its sunniest places.

#### The Mirrormere · pure · Lunar · Lv 32–37
> **Blurb** — A high still lake that holds the moon better than the sky does.
>
> **Arrival** — Not a ripple. The surface gives you back the mountains, the
> stars, and the moon at a size the moon has no right to be. Walking the shore,
> you are careful not to look down for too long.
>
> **Here** — Best Lunar motes. ❓ Whether the reflected phase matches the real
> one is a mechanic waiting to be used.

#### Starfall Basin · pure · Astral · Lv 34–39
> **Blurb** — A crater field, preserved because nothing grows to cover it.
>
> **Arrival** — Bowl after bowl in the pale ground, each with something at the
> bottom that is not from here. Nothing has grown over them because nothing
> grows. At night the sky is so clear it looks like a threat.
>
> **Here** — Best Astral motes. Star-iron from the crater floors.

#### 🔭 Meridian · town
> **Blurb** — An observatory on the crest of the Scarp: the highest dark-sky
> ground there is.
>
> **Arrival** — A town of long roofs that open. Everyone keeps different hours
> and nobody explains. From the crest you can see the desert on one side and,
> on the other, a valley with no light in it at all.
>
> **Here** — Enchanting — the only skill that works on motes rather than
> matter, and the only town where it can be practised.

#### Tidewrack Shoals · hybrid · Lunar + Aqua · Lv 36–40
> **Blurb** — Tides that obey the moon exactly, on the northern shore.
>
> **Arrival** — The water goes out further than seems survivable and comes back
> faster. What it uncovers has been down there a long time. Everything is
> timed to something overhead.
>
> **Here** — Lunar **and** Aqua motes. ⭐ **Reached by sea from Galehaven, not
> by the climb** — the port's endgame purpose.

#### The Sunless Reach · hybrid · Solar + Lunar *(Solar ▸ Lunar)* · Lv 38–42
> **Blurb** — The Scarp's north face. Direct sun never reaches the floor.
>
> **Arrival** — You come over the crest out of glare into a valley that has
> never been lit. The rock is the same rock. The desert is a thousand feet away
> and on the other side of the world.
>
> **Here** — Solar **and** Lunar motes. ⭐ The proving ground for Solar ▸ Lunar —
> and both faces of one ridge.

#### The Shattered Orrery · hybrid · Astral + Electro · Lv 40–44
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

### 6.4 Ethereal — the climb · Lv 45–60

⚠️ **Enemies here out-level you by up to ten. Gear closes the gap, not XP**
(GAME_DESIGN §5). Everything in this band is above the tree line.

#### 🏔️ Rimeholt · town · **unlocks Ethereal (L45)**
> **Blurb** — Basecamp. The last mortal outpost, above the tree line.
>
> **Arrival** — There is no wood here, so nothing is built of it. The town is
> stone and rope and hide, dug in against a slope that goes up out of sight.
> Everyone you meet is either arriving or leaving; nobody is *from* here.
>
> **Here** — Jewelry — the deep stone is where gems come from and the last
> outpost is where they get cut. Mining. The charged Celestial Totem passes the
> barrier above the town.

#### Hallowmarch · pure · Sanctus · Lv 45–49
> **Blurb** — The Vault's south flank: a consecrated causeway up the only side
> that thaws.
>
> **Arrival** — A raised road, and someone built it. The sun reaches this face
> for a few hours and the meltwater runs beside you the whole way. Every mile
> or so there is a marker, and every marker has been maintained.
>
> **Here** — Best Sanctus motes. 📝 **Not a marsh** — *march* in the older
> borderland sense. Glacial meltwater on a thawing face.

#### The Umbral Wastes · pure · Umbra · Lv 47–51
> **Blurb** — The Vault's north face. No direct sun at any hour of any day.
>
> **Arrival** — You round the shoulder and the light stops. Not dusk — an
> absence with an edge to it. The ice here has never melted and holds its shape
> like something that has been thought about.
>
> **Here** — Best Umbra motes. ⭐ The dark needs no magical cause: a north wall
> at polar latitude simply never sees the sun.

#### The Reliquary Deep · hybrid · Sanctus + Umbra *(Sanctus ▸ Umbra)* · Lv 52–56
> **Blurb** — A vault bored through the mountain from the lit side to the dark.
>
> **Arrival** — The door is on the warm flank and the far end opens onto the
> ice. In between, a corridor that someone consecrated and someone else did not
> leave alone. It is warmer in the middle than at either end.
>
> **Here** — Sanctus **and** Umbra motes. ⭐ **Literally between its two
> parents** — through the rock rather than across the ground. ⚠️ Interior art.

#### *The upper icefall* · no zone
> Deliberately empty. Pure ascent between the Wastes and the crossing, so the
> climb has a stretch that is only climbing.

#### 🚪 Vespergate · town · **the crossing**
> **Blurb** — Where the ground runs out. The last place with a supply line.
>
> **Arrival** — A fortress at the top of the world, facing the wrong way — not
> outward at an enemy but *upward*, at nothing. Above it the rock goes vertical
> and stops being a route. They have been brewing their own everything for a
> long time.
>
> **Here** — Potions and Alchemy — a threshold fortress that cannot resupply
> from behind has to brew its own. ⭐ **The only door out of the world.**

#### ✧ Zenith · town · **sealed until the Crown is finished**
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
the `hasThinAir` / `hasMoon` / `isAboveTreeLine` helpers. *(The altitude ones
were removed again in Rev 4 — see above.)*
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
