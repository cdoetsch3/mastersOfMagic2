# Item icons — physical descriptions

**What this is for:** one concrete, visual description per item, written to be
handed to an image generator. Design lives in
[ITEMS_DESIGN.md](ITEMS_DESIGN.md); this file only describes what a thing
*looks like*. It is the item counterpart of
[BESTIARY_ART.md](BESTIARY_ART.md).

⚠️ **The problem this exists to fix.** Every item in the game currently renders
as **its own name in 9pt text** — a backpack is twenty grey rectangles of
wrapped words, the belt shows a single capital letter per bottle, and the duel's
belt rail gives every consumable in the game the same generic drink glyph. A
Heartwood Staff and a Forager's Ration are visually the same object. ⭐ **Rarity
is the only thing an item communicates on sight today**, and it does it with a
border colour.

---

## How to use these

⚠️ **This file is a live prompt source, and its formatting is load-bearing.**
`tool/artgen.py` parses it on every run — an entry is `**Name** — *rarity ·
kind · stats*` followed by its `` `assets/items/<zone>/<id>.png` `` filename
line and one blockquote, each zone states a wrapped `**Palette:**` line, and
the shared preamble below is quoted verbatim into all 265 icon prompts. Reword
the prose freely; change those shapes and the tool silently finds fewer icons,
which `test/item_icon_test.dart` and `tool/test_artgen.py` both fail on.

Each entry is written so it can be pasted straight into an image generator
**after the style preamble below**, without editing. They deliberately state
**form, real-world size, material, colour and silhouette**, because those are
what a generator gets wrong when left to guess.

### ⭐ The shared style preamble — prepend this to every prompt

> A single game item icon. One object only, centred, filling about 80% of a
> square frame, seen from a three-quarter front view slightly above. Plain flat
> pure-white background — no scene, no table, no floor, no props, no hands, no
> packaging, no text, no watermark, no border and no frame. Even soft lighting
> from the upper left with one dim fill from the right; a small soft contact
> shadow directly beneath the object and nothing else. Hand-painted fantasy
> game-asset style, flat limited palette, clean readable **silhouette** that
> still reads as this object when shrunk to 40 pixels. Muted natural colour with
> one clear accent hue; no gloss, no lens flare, no glow spilling onto the
> background.

⚠️ **Every word of that is load-bearing.** "One object" stops the generator
returning a display case of variants; "plain pure-white background" keys out
cleanly when the API's transparency fails and never bleeds into the object's
own darks (ruling 2026-08-19 — it replaced near-black after a no-cutout run
shipped baked-in grounds); "no border and no frame" matters because **the UI already draws
rarity as the border colour** around every slot (`rarityColour`) — an icon that
paints its own frame fights the one cue the interface already has.

⚠️ **Real-world size is stated in every entry**, the way scale is in
BESTIARY_ART. It is the single thing a generator most reliably ignores, and a
wand drawn at quarterstaff length makes the two weapon lanes — the whole
Woodcarving choice — indistinguishable in the backpack.

### ⭐ The stats decide the look

An icon is the only place a player meets an item before reading its numbers, so
**the numbers are the brief**. The conventions below are applied consistently in
every entry, and a new item should follow them rather than invent its own:

| The stat | What it looks like |
|---|---|
| `accuracyBonus` | straight, true, aimed — a dead-flat edge, a line the eye can follow |
| `damagePerCharge` (quarterstaff lane) | heavy, two-handed, committed — thick shaft, weighted end |
| `damagePerCast` (wand lane) | light, quick, tapering — thin, short, obviously one-handed |
| `maxHpBonus` (the armour sets) | thick, layered, covering — visible weave, doubled seams |
| `critChance` / `critDamage` | spiky and hot — a hairline of live ember, a point rather than a face |
| `shieldStrengthPercent` | smooth, closed, water-worn — nothing sharp anywhere on it |
| `healingReceivedPercent`, and every heal | green, soft, wet, rounded |
| `regrowPercent` | caught mid-regrowth: the same object dying and budding at once |
| `beltSlots` | loops and straps, drawn **empty** — the capacity is the point |

### ⭐ Rarity, without a frame

Rarity is a **light** convention here, never a border and never a colour wash:

- **Common** — no glow at all. Honest materials, visible wear, a working object.
- **Uncommon** — one clean note of the element hue, unlit.
- **Rare** — the element hue as an actual light source: one small emissive
  feature, the rest of the object lit by it.
- **Epic** — emissive *and* doing something. An Epic object is never at rest.

⚠️ Nothing in the game is Mythic or Legendary — not in the Primal quarter and
not at level 60, where the Citadel's best pieces are still Epic. Those two
rungs of §8's ladder have no convention yet, and after four quarters that is a
decision waiting, not an omission.

### Palette

⭐ **Anchored to the item's zone element, exactly as the creature sprites are**,
so a Cinderpeak icon and a Cinderpeak enemy read as the same place. Each zone
section below states its palette once and every entry in it stays inside it.
⚠️ **A warm neutral always sits beside the element hue** — bark, bone, stone,
tallow. That is the same finding `tool/pixelate.py` records for creatures: a
single-hue palette destroys material contrast, and the contrast between neutral
and hue is what makes the hue visible at all.

### The pipeline

⭐ **Generate at 1024×1024 (square)**, drop the files in
`art/source/items/<zone id>/` named after the **item id** — the filename below,
without the folder — then:

```sh
python3 tool/pixelate.py --zone whispering_woods --mode icon
```

which square cover-crops to 64×64 and quantises to 20 colours. ⚠️ **No darken,
no desaturate, no element remap and no `--cutout`**, unlike the other two modes:
a backdrop is pushed back because it must lose to the sprites, but an icon shown
at **14px** on the duel's belt rail has the opposite problem. So paint these
**saturated and high-contrast** — the opposite instruction to the backdrops.

📝 **Icons ship as real bundled PNGs**, at `assets/items/<zone id>/<item id>.png`
— one directory per zone declared in `pubspec.yaml`, and **no `manifest.json`**
(the reasoning is on `itemIconFor` in `lib/ui/item_icon.dart`: `ItemCatalogue`
is already the roster). ⚠️ `test/item_icon_test.dart` fails the suite if a PNG
lands whose stem is not a real item id, or which is filed under the wrong zone.

⭐ **A cross-zone recipe output belongs to the zone whose catalogue file defines
it**, not to the zone that supplies its materials — the Tuskhide Belt is
Cinderpeak's even though Thornmire's Bogflax is its thread. `ItemCatalogue.byZone`
is the authority, and nothing falls between two sections.

---

## Whispering Woods · Lv 1–5 · Flora · **18 items**

> ⭐ *The wood is one creature, and you are standing on it.* ⚠️ Everything
> harvested here should look **grown and recently cut**, not manufactured —
> green wood, wet fibre, sap still moving. Nothing in this zone is finished.

**Palette:** birch grey-white, pale root, moss and bracken green, wet black
earth, one dull amber.

### Materials

**Oak Log** — *common · material · Woodcarving t1*
`assets/items/whispering_woods/oak_log.png`
> A single short length of freshly felled oak, about as long as a forearm and
> as thick as a wrist, lying at a slight angle. Rough grey-brown bark down the
> length, both ends cut clean and square to show pale cream heartwood and tight
> growth rings. ⭐ **Cut green**: a bead of clear sap stands on the upper cut
> face and one thin run of it has crept down the bark. Bright green moss on the
> underside only. Damp, heavy, unseasoned. No axe, no stack, no woodpile.

**Bindweed Fibre** — *common · material · Tailoring t1*
`assets/items/whispering_woods/bindweed_fibre.png`
> A loose coil of stripped plant fibre, about a hand's span across, wound into a
> flat spiral like a skein of rough twine and tied off with one turn of itself.
> Pale green-grey strands, each one hair-thin and visibly stronger than it
> looks — the coil holds its shape with no support. A few unstripped scraps of
> darker leaf still caught in the winding. Dry, wiry, faintly fuzzed at the cut
> ends.

### Motes

> ⭐ **The three mote tiers are one object at three degrees of settling**, and
> that has to read at a glance: dust is a loose scatter, shard is a fragment,
> crystal is a whole solid. ⚠️ Same premise in every element — the Flora, Aqua
> and Pyro ladders differ only in hue and behaviour, never in form.

**Flora Dust** — *common · mote · dust · Flora*
`assets/items/whispering_woods/flora_dust.png`
> A small loose heap of fine green powder, roughly a spoonful, mounded on
> nothing. Pale sap-green shading to a deeper moss green in the shadow of the
> heap. A faint scatter of individual grains has drifted off the pile and hangs
> just above it, catching a little light. No container, no bottle, no bag — the
> dust itself is the object.

**Flora Shard** — *common · mote · shard · Flora*
`assets/items/whispering_woods/flora_shard.png`
> A single angular splinter of translucent green mineral, about the length of a
> thumb, standing on end at a slight lean. Flat conchoidal faces like broken
> glass, edges sharp and unpolished, colour deepening from pale sap-green at the
> tip to bottle-green in the body. ⭐ A thin dusting of the same green powder
> clings to the base, saying plainly what it settled out of. Unlit — this one
> does not glow.

**Flora Crystal** — *uncommon · mote · crystal · Flora*
`assets/items/whispering_woods/flora_crystal.png`
> A whole hexagonal crystal the size of a plum, resting on one facet. Clear
> deep-green mineral, every face flat and true, with a soft warm light rising
> from **inside** the stone and picking out the internal fractures. ⚠️ *"It is
> warm, and it does not stop being warm"* — so the glow must look steady and
> internal, never like a reflection or a spark. Faint green light on the ground
> immediately under it and nowhere else.

### Consumables

**Forager's Ration** — *common · consumable · restores 25 health*
`assets/items/whispering_woods/foragers_ration.png`
> A dense fist-sized block of pressed trail food on a square of waxed cloth,
> the cloth folded back off the top and tied underneath with twine. Dark
> brown-green compressed mass, visibly made of seeds, dried berries and chopped
> leaf, pressed hard enough that the individual pieces show at the cut edge.
> ⭐ *Filling; that is the whole of its reputation* — so make it look **heavy
> and unappetising**, not a pastry. No glow of any kind.

### Equipment — Oak

**Oak Circlet** — *common · hat · +1 accuracy*
`assets/items/whispering_woods/oak_circlet.png`
> A plain open headband of green oak, a single strip of wood the width of two
> fingers bent into a ring and pinned where the ends overlap with one small
> whittled peg. Shown upright and slightly tilted so the ring reads as a ring.
> Pale sapwood, bark left on the outer face only, the inner face planed flat.
> ⭐ *It tightens as it dries* — the ring is very slightly out of round and the
> overlap has pulled tight against the peg. Perfectly level all the way round:
> that is the accuracy. No gem, no metal, no carving.

**Oak Quarterstaff** — *common · main hand · +1 dmg/charge, +5 accuracy*
`assets/items/whispering_woods/oak_quarterstaff.png`
> A plain two-handed staff of pale oak as tall as a person, shown at a diagonal
> across the square so its full length reads. Thick as a wrist, absolutely
> straight, both ends blunt and slightly flared from use. Bark stripped, surface
> planed but not polished, the grain running dead straight along it. ⚠️ **Its
> whole silhouette is heaviness and straightness** — the commitment lane and the
> accuracy in one shape. Two darker bands where hands have worn it.

**Oak Wand** — *common · main hand · +2 dmg/cast*
`assets/items/whispering_woods/oak_wand.png`
> A short one-handed wand of pale oak, the length of a forearm and no thicker
> than a finger, tapering to a fine rounded tip. A small plain grip of the same
> wood turned at the base. ⚠️ **Unmistakably light next to the quarterstaff** —
> thin, short, quick, nothing added to it anywhere. Smooth honey-pale wood, one
> knot near the grip, no carving and no ornament at all.

**Oak Knot** — *common · off hand · +3 accuracy*
`assets/items/whispering_woods/oak_knot.png`
> A rounded burl of oak the size of an apple, worked smooth and held in the palm.
> The whole surface is one continuous swirling grain pattern spiralling into a
> dark centre, polished to a soft sheen from handling. Slightly flattened on one
> side where it sits in a hand. ⭐ *The tangle remembers which way it grew* —
> the spiral has one clear direction and the eye should be able to follow it to
> the centre, because that is the accuracy this thing grants.

### Equipment — the Bindweed set (Tailoring)

> ⭐ **Five pieces of one set, and they must look it**: the same pale green-grey
> woven fibre, the same open basketwork weave, the same unbleached colour, in
> five different garments. ⚠️ Draw the *weave* large enough to survive 40px —
> it is the only thing tying the set together.

**Bindweed Hood** — *common · hat · +1 accuracy*
`assets/items/whispering_woods/bindweed_hood.png`
> A simple woven hood of pale green-grey plant fibre, shown empty and holding
> its own shape as if a head had just left it. Coarse open weave with a visible
> over-under pattern, a plain rolled edge around the face opening, no lining and
> no fastening. Slightly stiff, like something woven wet and dried on a form.

**Bindweed Robe** — *common · robe top · +6 max HP*
`assets/items/whispering_woods/bindweed_robe.png`
> A sleeveless woven overtunic of pale green-grey fibre, laid flat and seen from
> the front, shoulders at the top. Coarse open basketwork weave, doubled and
> visibly thicker across the chest and shoulders where it has to protect. Plain
> straight hem, no belt, no clasp, no decoration. ⭐ *Woven wet and left to
> shrink* — so the weave is tight and slightly puckered along every seam.

**Bindweed Leggings** — *common · robe bottom · +4 max HP*
`assets/items/whispering_woods/bindweed_leggings.png`
> A pair of woven trousers in the same pale green-grey fibre, laid flat, legs
> together. Same coarse open weave, a plain drawstring of twisted fibre at the
> waist, ankles left raw-edged. Lighter and looser than the robe above it — one
> layer, not two.

**Bindweed Boots** — *common · boots · +1 max HP*
`assets/items/whispering_woods/bindweed_boots.png`
> A pair of low woven ankle boots in pale green-grey fibre, standing side by
> side. Soft flat soles of the same material, no heel, no nails, no leather
> anywhere — the whole boot is one continuous weave. ⭐ *Quiet on leaf litter* —
> they should look like they would make no sound at all.

**Bindweed Gloves** — *common · gloves · +1 max HP*
`assets/items/whispering_woods/bindweed_gloves.png`
> A pair of woven fingerless gloves in pale green-grey fibre, laid flat and
> slightly overlapping. Tight even weave over the back of the hand, looser cuff,
> raw-edged openings at the fingers and thumb. ⭐ *The weave tightens when you
> grip* — draw the palm side's weave visibly denser than the back's.

### Equipment — the chases

**Sporecap Mantle** — *rare · robe top · +12 max HP, +2 accuracy · Lv 4*
`assets/items/whispering_woods/sporecap_mantle.png`
> A heavy shoulder mantle grown rather than sewn, seen from the front, empty and
> holding its shape. The body is thick felted grey-brown fungal matter; the
> whole shoulder line and collar are crowded with **pale grey mushroom caps** of
> varying size, overlapping like scale armour. ⭐ **Still shedding** — the
> largest caps are split underneath and a fine pale dust is falling from them in
> a thin drift down the front of the garment. Damp, dense, slightly swollen.
> Rare, so one clean note of sap-green shows in the gills and nowhere else.

**Heartwood Staff** — *epic · main hand · +3 dmg/charge, +7 accuracy, 5% crit,
+10 crit dmg, 2 sockets · Lv 5*
`assets/items/whispering_woods/heartwood_stave.png`
> A two-handed quarterstaff cut from the living centre of a tree, as tall as a
> person, shown at a diagonal. Thick, straight and heavy like the Oak
> Quarterstaff, but the wood is deep red-amber heartwood with the grain visibly
> spiralling up its length. ⭐ **It is still growing**: the upper end is not cut
> but *tapering into new pale growth*, two small live green shoots pushing out
> of the tip, and the whole upper third is lit from within by a slow warm amber
> glow that follows the grain. Two empty round sockets are set into the shaft
> below the grip, dark and unfilled. ⚠️ Epic, so it must look like it is doing
> something even standing still — the light should read as sap moving.

### The gate

**Proof of the Woods** — *rare · key · opens Hearthwood's north road*
`assets/items/whispering_woods/proof_of_the_woods.png`
> A fist-sized knot of tree root, cut clean through at the base and still
> growing out of the cut. Tangled pale root braided into a rough sphere; from
> the severed face, three fresh white rootlets have pushed out and curled back
> around the knot. Wet black earth still packed in the crevices. ⚠️ **A token,
> not a treasure** — no metal, no setting, no glow. Its whole strangeness is
> that it did not stop.

---

## Glimmerbrook · Lv 3–8 · Aqua · **9 items**

> ⭐ *Everything here is holding still, and that is the wrong thing for water to
> do.* ⚠️ Nothing from this zone should look fast or splashing. Cold, poised,
> water-worn, glassy.

**Palette:** pale river-stone grey, glass green, cold white, and a warm tan hide
to hold against them.

### Materials

**Fawnhide** — *common · material · Tailoring t1*
`assets/items/glimmerbrook/fawnhide.png`
> A single soft hide, rolled loosely into a bundle about the size of two fists
> and tied once with a thong. Thin pale fawn-tan leather, suede-nap on the
> outside of the roll, one edge trimmed straight and the others left as the
> animal's own outline. ⭐ *It takes a dye better than anything else this close
> to the water* — so the nap should look thirsty and slightly uneven in tone.
> Supple enough that the roll sags.

**Sapwort** — *common · material · Potions & Alchemy t1*
`assets/items/glimmerbrook/sapwort.png`
> A small bundle of freshly pulled herb, a hand's length, tied at the stems with
> a wisp of grass. Broad soft leaves of a pale watery green, the undersides
> paler still; thick pale stems with the wet root ends left on and a little
> gravel caught in them. ⭐ *Feet in the brook and head in the sun* — the leaves
> at the top are sun-bleached and the roots are dark and dripping.

### Motes

**Aqua Dust** — *common · mote · dust · Aqua*
`assets/items/glimmerbrook/aqua_dust.png`
> A small loose heap of fine pale blue-green powder, roughly a spoonful, mounded
> on nothing. Cold glacier-blue in the light, deepening to teal in the shadow of
> the heap. A few grains drift just above it. ⚠️ Same form as Flora Dust in
> every respect but colour — the ladder is one object in three elements.

**Aqua Shard** — *common · mote · shard · Aqua*
`assets/items/glimmerbrook/aqua_shard.png`
> A single angular splinter of translucent blue-green mineral, thumb-length,
> standing on end at a slight lean. Flat glassy fracture faces, sharp unpolished
> edges, pale ice-blue at the tip deepening to teal in the body. A dusting of
> the same blue powder at its base. Unlit.

**Aqua Crystal** — *uncommon · mote · crystal · Aqua*
`assets/items/glimmerbrook/aqua_crystal.png`
> A whole hexagonal crystal the size of a plum, resting on one facet. Clear
> deep blue-green mineral, every face flat and true, with a soft cold light
> rising from **inside** the stone. ⚠️ *"It is cold, and it does not stop being
> cold"* — a pale rime of frost has formed on the lower facets and on the ground
> immediately beneath it, and nowhere else.

### Consumables

**Sapwort Draught** — *common · beltable · restores 30 health*
`assets/items/glimmerbrook/sapwort_draught.png`
> A small squat glass bottle the size of a fist, stoppered with a whittled wood
> plug and sealed with a twist of green twine. The liquid inside is a cloudy
> pale green, filled to the shoulder, with a little sediment settled at the
> bottom. ⭐ **Round, soft and green — the healing convention**, and small enough
> to read instantly as belt cargo. A paper tag would be text; do not add one.

### Equipment

**Fawnhide Belt** — *common · belt · +1 belt slot · Lv 4*
`assets/items/glimmerbrook/fawnhide_belt.png`
> A soft narrow leather belt in pale fawn-tan, laid out in a loose open curve
> rather than coiled, with a small plain bone buckle. ⭐ **One empty loop** of
> the same leather is stitched to the strap, wide enough to hold a bottle and
> visibly holding nothing. ⚠️ The loop is the entire point of the item — draw it
> large, open and unmistakable, because the capacity *is* the stat.

**Brookstone Pendant** — *rare · neck · +10% shield strength · Lv 6*
`assets/items/glimmerbrook/brookstone_pendant.png`
> A flat oval river pebble the size of a thumb, hung on a plain twisted cord of
> gut through a natural hole worn right through its middle. Cold grey-green
> stone, completely smooth, every edge rounded by water — **nothing sharp
> anywhere on it**, which is the shield stat made visible. ⭐ Rare: through the
> worn hole, the view is not the background but a pale still light, as if the
> hole opened onto calmer water. Faint cold glow at the rim of the hole only.

### The gate

**Proof of the Brook** — *rare · key · opens Hearthwood's north road*
`assets/items/glimmerbrook/proof_of_the_brook.png`
> A single pale river stone the size of a hen's egg, smooth and slightly
> flattened, sitting on nothing. Cold near-white grey, faintly translucent at
> the thin edge, with a permanent beading of condensation on its surface and one
> drip forming underneath. ⚠️ **It has not warmed since it left the water** —
> that is the whole image: an ordinary stone that is visibly, wrongly cold.

---

## Cinderpeak Foothills · Lv 6–11 · Pyro · **8 items**

> ⭐ *Everything here has been through a fire and kept working.* ⚠️ Scorch,
> soot, heat-scale and verdigris — not flame. Nothing in this zone is currently
> burning except where an entry says so.

**Palette:** charcoal black, ember orange, copper verdigris green, scorched
tan hide, pale ash grey.

### Materials

**Copper Ore** — *common · material · Metalworking t2 · ⏳ banks for Q2*
`assets/items/cinderpeak_foothills/copper_ore.png`
> Two or three broken lumps of ore the size of eggs, resting together as one
> mass. Dark grey rough rock shot through with veins of raw metallic copper —
> bright pink-orange where freshly broken, and ⭐ **crusted over with bright
> blue-green verdigris** across every weathered face. *The hills here rust
> green*: that green crust is the recognisable thing about it and must survive
> at 40px. Gritty, heavy, faintly sparkling.

**Tuskhide** — *common · material · Tailoring t2*
`assets/items/cinderpeak_foothills/tuskhide.png`
> A single thick hide folded into a heavy slab about the size of a loaf, edges
> squared, sitting flat and holding its shape without help. Dark scarred
> grey-brown leather, far thicker than the Fawnhide — the cut edge shows real
> depth. ⭐ **Scarred and singed**: old pale scar ridges across the surface and
> two blackened scorch marks with brittle curled edges. *Thicker than a door.*

### Motes

**Pyro Dust** — *common · mote · dust · Pyro*
`assets/items/cinderpeak_foothills/pyro_dust.png`
> A small loose heap of fine orange-red powder, roughly a spoonful, mounded on
> nothing. Bright ember-orange on the lit side, dull brick-red in the shadow of
> the heap, a few grains drifting just above it. ⚠️ Same form as the other two
> dusts — colour is the only difference. Not glowing; *it was put out before it
> finished*.

**Pyro Shard** — *common · mote · shard · Pyro*
`assets/items/cinderpeak_foothills/pyro_shard.png`
> A single angular splinter of translucent orange-red mineral, thumb-length,
> standing on end at a slight lean. Sharp glassy fracture faces, amber-orange at
> the tip deepening to dark red in the body. ⭐ *Dust that banked itself and went
> on quietly burning* — one hairline crack in the body carries a faint live
> ember line, and that is the only light on it.

**Pyro Crystal** — *uncommon · mote · crystal · Pyro*
`assets/items/cinderpeak_foothills/pyro_crystal.png`
> A whole hexagonal crystal the size of a plum, resting on one facet. Clear
> deep orange-red mineral, every face flat and true, lit from **inside** by a
> steady ember glow that picks out the internal fractures. ⚠️ *"It is hot, and
> it does not cool"* — a small ring of scorched blackening on the ground
> directly beneath it, and a bare shimmer of heat-haze at its upper edge.

### Equipment

**Tuskhide Belt** — *common · belt · +2 belt slots · Lv 11*
`assets/items/cinderpeak_foothills/tuskhide_belt.png`
> A broad heavy leather belt in dark scarred grey-brown, laid out in a loose
> open curve. ⭐ **Two empty bottle loops** of doubled hide, both visibly
> holding nothing, plus a third narrower loop with room to spare. A massive
> square iron buckle, blackened and out of all proportion to the strap —
> *the buckle outweighs the knife*. ⚠️ Loops large and open: the capacity is
> the stat.

**Cinder Loop** — *rare · ring · 5% crit, +5 crit damage · Lv 9*
`assets/items/cinderpeak_foothills/cinder_loop.png`
> A single finger ring of charred black material, shown standing upright, thick
> and irregular like a twist of burnt wood rather than cast metal. The whole
> band is cracked with a fine craquelure and ⭐ **live orange light comes up
> through every crack**, brightest where the band is thinnest. The surface is
> matt black char; the light is entirely in the fissures. ⚠️ Crit, so the
> silhouette wants an edge — one point of the band is drawn up into a small
> sharp peak. *The moment before a pot boils over.*

### The gate

**Proof of the Foothills** — *rare · key · opens Hearthwood's north road*
`assets/items/cinderpeak_foothills/proof_of_the_foothills.png`
> A flat irregular plate of black volcanic glass, the size of a palm and no
> thicker than a coin, held upright at a slight angle. Glossy fracture surface,
> razor edges, opaque black at the centre and ⭐ **translucent deep red where it
> thins at the rim, with the heat still visibly somewhere inside it** — a faint
> ember glow that shows only when the plate is seen edge-on to the light. No
> setting, no cord, no metal. A token, held up to be looked through.

---

## Thornmire · Lv 8–13 · Flora + Aqua · **9 items**

> ⭐ *A hybrid zone, and everything from it is wet and stays wet.* ⚠️ Peat,
> tannin, retted fibre, standing water. Nothing here is clean and nothing here
> is dry — *cloth of it never fully dries, and never quite burns either*.

**Palette:** peat brown-black, bog green, tannin amber-gold, wet grey, one
sickly pale highlight.

### Materials

**Bogflax Fibre** — *common · material · Tailoring t2*
`assets/items/thornmire/bogflax_fibre.png`
> A hank of retted flax fibre the size of two fists, twisted once in the middle
> and doubled over on itself. Long straight strands in a dull olive-grey, darker
> and wetter at the folded end where they are still soaked through, with a
> couple of drips forming. ⭐ **Retted in the mire by the mire** — a smear of
> black peat is worked into one side, and the fibre is visibly heavier and
> limper than the Whispering Woods' bindweed.

**Fenroot** — *common · material · Potions & Alchemy t2 · ⏳ banks for Q2*
`assets/items/thornmire/fenroot.png`
> A single thick pale root, a hand's length, knobbled and forked at one end,
> pulled whole from the ground. Dirty cream-white flesh under a thin brown skin,
> one end sliced open to show a wet cross-section beaded with pale sap. Fine
> hair-roots still trailing, black peat clinging to them. ⭐ *Bitter enough to
> make your eyes water at arm's length* — draw the cut face weeping.

**Amber** — *uncommon · material · Jewelry t2 · ⏳ banks for Q2*
`assets/items/thornmire/amber.png`
> A single rounded nugget of amber the size of a walnut, resting on one flat
> face. Warm translucent honey-gold, glassy where it has been rubbed and matt
> crazed rind on the untouched side. ⭐ **Lit from behind rather than glowing**,
> so the whole nugget carries a deep internal gold — and *sometimes there is a
> wing in it*: one small dark insect wing suspended near the centre, sharply in
> focus. Uncommon, so this one clean gold note and nothing else.

### Equipment — the Bogflax set (Tailoring)

> ⭐ **The Bindweed set's older, heavier sibling**, and the family resemblance
> is the brief: the same five garments and the same woven construction, but in
> a dense dark olive-grey cloth instead of pale open basketwork, and **wet
> through in every piece**. ⚠️ Mud to the knee is the local dye lot — the lower
> half of every piece is darker than the upper half.

**Bogflax Hood** — *common · hat · +2 accuracy · Lv 10*
`assets/items/thornmire/bogflax_hood.png`
> A deep woven hood of dark olive-grey flax, empty and holding its shape, with a
> long pointed crown that flops slightly forward. Tight dense weave, a doubled
> waterproofed brim standing stiffly out over the face opening, and a dark
> waterline stain around the shoulders where the rain has run off. ⭐ The brim is
> dead straight and level — that is the accuracy.

**Bogflax Robe** — *common · robe top · +10 max HP · Lv 10*
`assets/items/thornmire/bogflax_robe.png`
> A long-sleeved woven overrobe of dark olive-grey flax, laid flat and seen from
> the front. Heavy tight weave, visibly **three layers thick** across the chest
> with quilted stitching lines holding them together. The whole lower half is
> several shades darker with soaked-in bog water, the hem still dripping.
> *Heavy when wet, and it is always wet.*

**Bogflax Leggings** — *common · robe bottom · +7 max HP · Lv 10*
`assets/items/thornmire/bogflax_leggings.png`
> Woven trousers of dark olive-grey flax, laid flat, legs together. Dense weave,
> a broad doubled waistband, reinforced patches at the knees. ⭐ Both legs are
> caked in black peat mud from the knee down, with a hard tide-line where the
> mud stops — *mud to the knee is the local dye lot*.

**Bogflax Boots** — *common · boots · +2 max HP · Lv 10*
`assets/items/thornmire/bogflax_boots.png`
> A pair of tall woven calf boots in dark olive-grey flax, standing side by
> side, both slumping slightly. Thick waxed soles, a wrapped cord binding at the
> ankle, dense weave gone almost black with water up to the calf. ⭐ *The mire
> keeps boots; these are the kind it gives back* — one is visibly more worn and
> stained than the other.

**Bogflax Gloves** — *common · gloves · +2 max HP · Lv 10*
`assets/items/thornmire/bogflax_gloves.png`
> A pair of full-fingered woven gloves in dark olive-grey flax, laid flat and
> slightly overlapping. Tight weave, a hard waxed sheen across the palms and
> fingertips that catches the light, plain cuffs. *Waxed against the wet.*

### Equipment — the chase

**Wickerbound Ring** — *rare · ring · +10% healing received · Lv 12*
`assets/items/thornmire/wickerbound_ring.png`
> A finger ring woven from living willow withies, shown standing upright. Six or
> seven pale green-gold rods knotted over and under each other in a dense
> continuous braid with no visible end and no join — ⭐ **a knot that took
> someone a whole winter**, so the weave has to look genuinely intricate at this
> scale. Smooth, rounded, nothing sharp: soft green healing, not an edge. One
> tiny fresh leaf bud has opened on the band, saying it grows closed by morning.
> Rare, so a soft green light in the gaps of the weave and nowhere else.

---

## Ashfall Vale · Lv 10–14 · Pyro + Flora · **8 items**

> ⭐ *A burned valley with new green coming back through it.* ⚠️ The two
> elements do not blend here, they sit beside each other: char-black and ash
> grey everywhere, and one narrow band of vivid living green in every single
> item. That contrast is the zone.

**Palette:** ash grey, paper-white birch bark, char black, one dull ember
orange, one vivid new green.

### Materials

**Birch Log** — *common · material · Woodcarving t2*
`assets/items/ashfall_vale/birch_log.png`
> A single short length of birch, forearm-long and straight as a rule, lying at
> a slight angle. ⭐ **Paper-white bark with black horizontal lenticel dashes**,
> peeling away in fine translucent curls along one side. Both ends cut clean to
> show pale even heartwood. *First back after the burn* — a light dusting of
> grey ash sits along the upper surface, and one end is faintly scorched.

**Brookmint** — *common · material · Potions & Alchemy t2*
`assets/items/ashfall_vale/brookmint.png`
> A small bundle of freshly cut herb, a hand's length, tied at the stems. Square
> stems and paired serrated leaves in an ⭐ **intensely vivid green — the
> brightest colour anywhere in this zone**, deliberately louder than everything
> around it. A faint bloom of frost-white on the upper leaf surfaces. A little
> grey ash caught in the bundle where it was picked. *Cold on the tongue even in
> this valley.*

**Charcoal** — *common · material · Metalworking t2 · ⏳ banks for Q2*
`assets/items/ashfall_vale/charcoal.png`
> Three or four irregular chunks of hardwood charcoal resting together as one
> mass, the largest the size of a fist. Matt black, completely light-absorbing,
> with ⭐ **the original wood grain and growth rings still perfectly visible** in
> the fracture faces. Sharp brittle edges, a scatter of black dust beneath.
> Dead cold — no ember, no glow anywhere. *The vale makes its own.*

### Consumables

**Brookmint Tonic** — *common · beltable · 10 health a turn for 3 turns*
`assets/items/ashfall_vale/brookmint_tonic.png`
> A tall narrow glass bottle the height of a hand, stoppered with cork and
> sealed over with dark wax. The liquid is a clear vivid green, and ⭐ **it is
> visibly layered** — three faintly distinct bands of the same green, palest at
> the top, which is the three-turn payout drawn rather than written. A slow
> stream of small bubbles rising through it. Cold enough that the glass is
> fogged with condensation at the base.

### Equipment — Birch weapons (Woodcarving)

**Birch Quarterstaff** — *common · main hand · +2 dmg/charge, +6 accuracy · Lv 10*
`assets/items/ashfall_vale/birch_quarterstaff.png`
> A two-handed staff of birch as tall as a person, shown at a diagonal. Same
> heavy straight silhouette as the Oak Quarterstaff — thick, blunt-ended,
> committed — but the wood is **paper-white with black lenticel dashes**, bark
> left on except where the hands go. ⭐ *Springy where oak is stubborn*: draw
> one very slight, deliberate bow along its length, as though it is mid-flex.

**Birch Wand** — *common · main hand · +3 dmg/cast, +1 accuracy · Lv 10*
`assets/items/ashfall_vale/birch_wand.png`
> A short one-handed wand of birch, forearm-length and finger-thin, tapering to
> a fine tip. Paper-white bark with black dashes. ⭐ *Peels itself a little more
> each week, like it is in a hurry* — several fine curls of bark have lifted and
> are peeling back along the shaft, showing pale wood underneath. Light, quick,
> obviously one-handed beside the staff above.

**Birch Knot** — *common · off hand · +4 accuracy · Lv 10*
`assets/items/ashfall_vale/birch_knot.png`
> A rounded burl of birch the size of an apple, worked smooth and palm-sized.
> ⭐ **A pale whorl with a dark centre** — creamy white grain spiralling tightly
> into an almost black knot at the middle, polished to a soft sheen. Slightly
> flattened where it sits in a hand. The spiral has one clear followable
> direction, as the Oak Knot does.

### Equipment — the chase

**The Charlock** — *epic · neck · +2% regrow per turn · Lv 14*
`assets/items/ashfall_vale/the_charlock.png`
> A pendant on a fine blackened chain: a single seed case of black volcanic
> glass, thumb-sized and pointed like a poppy head, on a short charred stem.
> ⚠️ **The object is caught mid-cycle, and that is the whole brief** — the seed
> case is split open along one side, and out of the split a small vivid yellow
> wildflower has opened; on the other side of the same flower the outer petals
> have already gone to grey ash and are crumbling away. ⭐ Epic, so it is
> visibly *doing* something: a soft green light in the split and a thin drift of
> ash falling from the spent petals. *Every morning it has flowered again, and
> every evening the flower is ash.*

---

## Old Quarry · Lv 15–19 · Geo · **9 items**

> ⭐ *Everything here is what the hole gave back.* ⚠️ Grey stone and dust
> first, colour only where a material or a mechanic earns it — jasper's
> red-brown, bronze's warm gold, and deflection's cool grey-white light.
> Nothing in this zone should read as bright or decorative by default.

**Palette:** quarry grey, tool-mark black, dull red-brown jasper, tin-ore
silver-grey, bronze warm gold-brown.

### Materials

**Tin Ore** — *common · material · Metalworking t3*
`assets/items/old_quarry/tin_ore.png`
> Two or three broken lumps of dull silver-grey ore the size of eggs, resting
> together as one mass. Fine metallic glints scattered through a grey rock
> matrix, faintly bright where freshly broken. Gritty, heavy, unremarkable —
> no glow, no colour.

**Quarry Jasper** — *uncommon · material · Jewelry t3 · ⏳ banks for Q2*
`assets/items/old_quarry/quarry_jasper.png`
> A single squared chunk of banded stone about the size of a fist, cut with
> one flat face where a chisel took it clean. Deep brick-red banding running
> parallel through a duller grey-brown body, polished only on the cut face.
> ⭐ Uncommon — one clean warm red note against the grey, unlit.

### Motes

**Geo Dust** — *common · mote · dust · Geo*
`assets/items/old_quarry/geo_dust.png`
> A small loose heap of fine grey powder, roughly a spoonful, mounded on
> nothing. Pale stone-grey on the lit side, darker slate in the shadow of the
> heap, with a scatter of coarser grit mixed through. ⚠️ Same form as the
> other dusts — colour is the only difference. Inert and matte, exactly what
> falls off a chisel stroke.

**Geo Shard** — *common · mote · shard · Geo*
`assets/items/old_quarry/geo_shard.png`
> A single angular splinter of grey mineral, thumb-length, standing on end at
> a slight lean. Sharp fracture faces, pale stone-grey deepening to a darker
> slate at the base. ⭐ One hairline vein of dull ochre runs through the
> body — dust that held its shape long enough to grow edges.

**Geo Crystal** — *uncommon · mote · crystal · Geo*
`assets/items/old_quarry/geo_crystal.png`
> A whole hexagonal crystal the size of a plum, resting on one facet. Clear
> deep grey-brown mineral, every face flat and true, with a dense, heavy
> presence rather than any glow. ⚠️ *"It is heavy, and it does not get
> lighter"* — a small compression mark pressed into the ground directly
> beneath it.

### Consumables

**Hardtack** — *common · consumable · heals 60*
`assets/items/old_quarry/hardtack.png`
> A single flat brick of dense pale biscuit, cracked at one corner, about the
> size of a deck of cards. Dry matte tan-grey surface, faint grain lines
> pressed into it like tool marks. Plain, hard-edged, entirely unglamorous.

### Intermediate goods

**Bronze Ingot** — *common · material · Metalworking t3 output*
`assets/items/old_quarry/bronze_ingot.png`
> A single cast bar of bronze the size of a hand, resting flat, edges
> slightly rounded from the mould. Warm gold-brown metal with a faint ruddy
> sheen, a thin seam line down one side where the mould closed. ⭐ Neither
> copper's pink nor tin's grey — bronze reads as its own colour, the two gone
> into the crucible and come out something new.

### Equipment

**Overseer's Seal** — *rare · ring · 12% deflect, 20% amount · Lv 18*
`assets/items/old_quarry/overseers_seal.png`
> A single flat signet ring shown standing upright, bronze in the same warm
> gold-brown as the ingot, with one groove on its face worn bright and smooth
> from use and every other surface still sharp-edged and matte. ⭐ Rare, so
> the deflection reads as a light source: a thin cool grey-white line traces
> the worn groove, as though something in it were still measuring. ⚠️ No
> border — the ring's own bright groove is the whole cue.

**The Given Weight** — *epic · neck · +30 HP, 10% deflect, 25% amount · Lv 19*
`assets/items/old_quarry/the_given_weight.png`
> A heavy locket on a fine chain, shown hanging, disc-shaped and the size of a
> large coin, cut from dense dark quarrystone rather than metal. ⭐ Epic, so
> it is visibly doing something: a faint grey-white haze of dust drifts
> continuously from a hairline crack around its rim, as though it is still
> settling. ⚠️ The dust never stops — that is the whole tell of *"the precise
> mass the hole is missing."*

---

## Windward Steppe · Lv 19–24 · Aero · **15 items**

> ⭐ *One direction, forever.* Everything here is shaped by having stopped
> resisting a single steady force. ⚠️ **Dodge and deflection debut this
> quarter** (KINETIC_CONTRACT §2) — dodge reads as **poised, light, already
> leaning into the next step**; deflection (on the Tussock gloves) reads as a
> **smooth, blunt surface with nothing for a blow to catch on**, the same
> "nothing sharp" instinct the shield-strength convention above already uses.

**Palette:** pale straw tan, silvered yew-grey, dust-pale white, one thin
overcast sky-grey accent.

### Materials

**Yew Log** — *common · material · Woodcarving t3*
`assets/items/windward_steppe/yew_log.png`
> A single length of yew about a forearm and a half long, shown at a slight
> diagonal. Dense reddish-brown heartwood at the core, a narrow band of pale
> creamy sapwood just under the bark. ⭐ **The whole piece has a faint but
> unmistakable lean along its grain** — cut with the wind's own bias rather
> than straight, which is the recognisable thing about it. Both ends cut
> clean, slightly weathered along the top face.

**Tussock Flax** — *common · material · Tailoring t4*
`assets/items/windward_steppe/tussock_flax.png`
> A hand-sized hank of stripped fibre, wiry and pale straw-tan, bound loosely
> at the middle with a single twist of itself. Individual strands are visibly
> tough and slightly kinked rather than smooth — *grown low and dense, in
> tussocks that learned to grow around each other*. A little pale grit caught
> in the twist near the base.

### Motes

**Aero Dust** — *common · mote · dust · Aero*
`assets/items/windward_steppe/aero_dust.png`
> A small loose heap of fine pale grey-white powder, roughly a spoonful,
> mounded on nothing, with two or three grains caught mid-drift just above it
> as though a breath moved them a moment ago. ⚠️ Same form as the other dusts
> — colour is the only difference. *What a moving thing leaves when the wind
> gets there first.*

**Aero Shard** — *common · mote · shard · Aero*
`assets/items/windward_steppe/aero_shard.png`
> A single angular splinter of translucent pale grey mineral, thumb-length,
> standing on end at a slight lean — the same lean every object in this zone
> carries. Sharp glassy fracture faces, near-white at the edge deepening to a
> soft blue-grey in the body. ⭐ *Dust that caught on something and stopped
> moving, briefly* — faint motion-blur striations run along one face.

**Aero Crystal** — *uncommon · mote · crystal · Aero*
`assets/items/windward_steppe/aero_crystal.png`
> A whole hexagonal crystal the size of a plum, resting on one facet but
> angled as if about to tip. Clear pale grey-blue mineral, every face flat and
> true, with a faint internal shimmer that reads as **captured motion** rather
> than light — a blurred inner facet or two, as though something inside it is
> still moving very slowly. ⚠️ *"It is moving, and it does not stop"* — a thin
> drift of dust perpetually sliding off its upper edge.

### Equipment — Yew weapons (Woodcarving)

⭐ **Yew is the wood ladder's tier-3 rung, equipping at 20** — the third stop
after Oak and Birch. No crit anywhere below: it stays off Yew entirely this
quarter (§2.5), so nothing here should carry a hot or spiky note.

**Yew Quarterstaff** — *common · main hand · +3 dmg/charge, +7 accuracy · Lv 20*
`assets/items/windward_steppe/yew_quarterstaff.png`
> A two-handed staff of yew as tall as a person, shown at a diagonal. Thick,
> blunt-ended, heavily committed silhouette, same weight class as Oak and
> Birch before it. Dense reddish-brown heartwood with a pale sapwood edge
> along one side. ⭐ **A single straight, unbroken grain line runs its full
> length** — the one branch that never learned to lean, which is why it was
> chosen. Bark left only at the grip.

**Yew Wand** — *common · main hand · +4 dmg/cast, +2 accuracy · Lv 20*
`assets/items/windward_steppe/yew_wand.png`
> A short one-handed wand of yew, forearm-length and finger-thin, tapering to
> a fine flexible tip. Reddish-brown heartwood, smooth pale sapwood edge.
> ⭐ *Trimmed thin enough to whip in the wind and not break* — drawn with a
> very slight live curve along its length, as though caught mid-flex. Light,
> quick, obviously one-handed.

**Yew Knot** — *common · off hand · +5 accuracy · Lv 20*
`assets/items/windward_steppe/yew_knot.png`
> A rounded burl of yew the size of an apple, worked smooth and palm-sized.
> Deep reddish-brown, with the grain knotted tightly at the centre —
> *carved from a lean-side branch, where the grain knots up from decades of
> holding against the same wind*. Slightly flattened where it sits in a hand,
> the knot's spiral running one clear followable direction.

### Equipment — the Tussock set (Tailoring)

⭐ **The dodge and deflect debut** (§2.5): boots carry the zone's first dodge,
gloves its first crafted deflect. ⚠️ Flat HP and accuracy elsewhere, exactly
Q1's shape — only the boots and gloves carry the new stats.

**Tussock Hood** — *common · hat · +4 accuracy · Lv 24*
`assets/items/windward_steppe/tussock_hood.png`
> A close-fitting hood woven from tussock flax, pale straw-tan, the weave
> visibly tight and even. Drawn snug with a single cord at the crown. Straight
> true stitching lines running front to back — *woven tight enough that the
> wind whistles instead of getting in*.

**Tussock Robe** — *common · robe top · +20 max HP · Lv 24*
`assets/items/windward_steppe/tussock_robe.png`
> A layered tunic of woven flax, shown from the front, straw-tan throughout.
> ⭐ **Visibly doubled fabric across the chest** — two full layers stitched
> together with a clear seam line, thicker and heavier than the hood or
> leggings beside it. Loose at the shoulders, snug at the waist with a simple
> tie.

**Tussock Leggings** — *common · robe bottom · +14 max HP · Lv 24*
`assets/items/windward_steppe/tussock_leggings.png`
> Straight-cut leggings of the same straw-tan woven flax, shown laid flat.
> Cut long, with a doubled panel of fabric at the shins and thighs — visible
> stitched-over layering, lighter than the robe's but still a clear second
> ply. Plain cord ties at the waist.

**Tussock Boots** — *common · boots · +4 max HP, dodge · Lv 24*
`assets/items/windward_steppe/tussock_boots.png`
> A pair of low woven boots, straw-tan flax over a thick pale sole, laced
> tight up the ankle. ⭐ **Dodge, so the silhouette wants poise, not bulk** —
> shown lifted slightly on the toe, as though already mid-step, laces drawn
> at a slight forward-leaning angle rather than straight up.

**Tussock Gloves** — *common · gloves · +4 max HP, deflect · Lv 24*
`assets/items/windward_steppe/tussock_gloves.png`
> A pair of fingerless woven gloves, straw-tan flax, shown one resting over
> the other. ⭐ **Deflect, so the palms are the whole brief** — the palm and
> outer edge of each glove are a smooth, doubled, slightly domed panel with no
> texture or seam to catch on, in clear contrast to the coarser woven backs.

### Equipment — the chases

**Leanstone Charm** — *rare · ring · dodge, +2 accuracy · Lv 22*
`assets/items/windward_steppe/leanstone_charm.png`
> A single finger ring, shown standing upright: a finger-length sliver of pale
> weathered stone set into a plain dark band. The sliver leans at a fixed
> angle off the band rather than sitting flush — *worn from the windward face
> of a leaning stone, and held loosely it wants to point the same direction
> every time*. ⭐ Dodge, so the whole piece reads off-balance in one consistent
> direction, poised rather than planted.

**The Long Lean** — *epic · robe top · max HP, dodge, accuracy · Lv 24*
`assets/items/windward_steppe/the_long_lean.png`
> A heavy mantle worn over the shoulders, shown from the front: thick combed
> windgrass in the same straw-tan as Tussock but visibly coarser and denser,
> lying flat across the shoulders all in one combed direction. ⭐ **Epic, so it
> is visibly doing something** — a faint pale motion-blur trails off the lower
> edge and one shoulder, as though the whole garment is very slowly being
> pulled sideways and simply keeping its shape. *It has been leaning the same
> way since it was cut.*

---

## Stormcliff Coast · Lv 17–22 · Electro · **13 items**

> ⭐ *Everything here has been charged in passing, not struck.* ⚠️ Nothing in
> this zone glows all over — the light lives in **hairline cracks and single
> veins**, exactly where a strike would enter or leave. Everything else is wet
> dark rock, sea-bleached fibre or storm-cloud grey.

**Palette:** wet black rock, storm-cloud grey, pale sea-foam white, salt-cured
tan fibre, one hairline vein of white-blue light.

### Materials

**Seawrack Fibre** — *common · material · Tailoring t3*
`assets/items/stormcliff_coast/seawrack_fibre.png`
> A coiled hank of dark rope-like fibre the size of two fists, laid in loose
> loops. Stiff, salt-crusted, weathered tan-brown, drying pale white where the
> salt has bloomed on the outer wraps. ⭐ *The tideline's own rope* — a few
> strands still hold the crimped wave-pattern of the water that laid it out.

**Saltwort** — *common · material · Potions & Alchemy t3*
`assets/items/stormcliff_coast/saltwort.png`
> A small bundle of low, fleshy herb stems, a hand's length, tied at the base.
> Thick blue-green paddle-shaped leaves with a fine white salt bloom dusted
> across every surface. A single bead of clear brine sits in the crook of one
> leaf. *Grows where the spray reaches and nowhere the spray does not.*

### Motes

**Electro Dust** — *common · mote · dust · Electro*
`assets/items/stormcliff_coast/electro_dust.png`
> A small loose heap of fine white-blue powder, roughly a spoonful, mounded on
> nothing. Bright hairline-white on the lit side, deep storm grey in the shadow
> of the heap, a few grains suspended just above it as if still faintly charged.
> ⚠️ Same form as the other two dusts — colour is the only difference.

**Electro Shard** — *common · mote · shard · Electro*
`assets/items/stormcliff_coast/electro_shard.png`
> A single angular splinter of translucent pale mineral, thumb-length, standing
> on end at a slight lean. Sharp glassy fracture faces, near-white at the tip
> deepening to a cold storm-blue in the body. ⭐ *Dust that held its charge a
> moment longer* — one hairline crack in the body carries a faint live white
> line, and that is the only light on it.

**Electro Crystal** — *uncommon · mote · crystal · Electro*
`assets/items/stormcliff_coast/electro_crystal.png`
> A whole hexagonal crystal the size of a plum, resting on one facet. Clear
> pale blue-white mineral, every face flat and true, lit from **inside** by a
> flickering, unsteady white light that never settles the way an ember would.
> ⚠️ *"It is live, and it does not discharge"* — a fine static haze clings to
> the air immediately around it.

### Consumables

**Saltwort Draught** — *common · beltable · 75 health*
`assets/items/stormcliff_coast/saltwort_draught.png`
> A short, wide glass bottle the height of a hand, corked and sealed with dark
> wax. The liquid inside is a cloudy, briny blue-grey with fine white sediment
> settled at the bottom and a thin salt-crust ring at the waterline. Cold, and
> faintly sweating on the glass.

### Equipment — the Seawrack set (Tailoring)

> ⭐ **The quarter's first crit/dodge/deflect debut, from the gear side** —
> boots carry the game's first crafted dodge, gloves the first crafted
> deflect. ⚠️ Keep both small and legible at 14px: one clean accent detail
> each, not a build's worth of ornament.

**Seawrack Hood** — *common · hat · +3 accuracy · Lv 16*
`assets/items/stormcliff_coast/seawrack_hood.png`
> A close-fitting hood of dark salt-stiffened fibre, empty and holding its
> shape, edges crusted pale white with dried salt. Tight weave, a straight low
> brow-line pulled taut across the front. ⭐ The brow-line is dead straight and
> level — that is the accuracy.

**Seawrack Robe** — *common · robe top · +15 max HP · Lv 16*
`assets/items/stormcliff_coast/seawrack_robe.png`
> A long woven overrobe of dark salt-cured fibre, laid flat, seen from the
> front. Dense tight weave, visibly **doubled across the chest and shoulders**
> with a stitched reinforcing line. Pale salt bloom along every hem, never
> fully dry.

**Seawrack Leggings** — *common · robe bottom · +10 max HP · Lv 16*
`assets/items/stormcliff_coast/seawrack_leggings.png`
> Woven trousers of dark salt-cured fibre, laid flat, legs together. Dense
> weave, a broad doubled waistband, a crust of pale dried salt at both cuffs
> where the tide has caught them again and again.

**Seawrack Boots** — *common · boots · +3 max HP, +2 dodge · Lv 16*
`assets/items/stormcliff_coast/seawrack_boots.png`
> A pair of low woven boots in dark salt-cured fibre, standing side by side.
> Thick ridged soles cut for wet rock, a wrapped ankle cord, both slightly
> angled as if already mid-step. ⭐ **Light and unencumbered** — the dodge
> stat wants a boot that looks ready to move, not to stand.

**Seawrack Gloves** — *common · gloves · +3 max HP, 6% deflect chance /
15% amount · Lv 16*
`assets/items/stormcliff_coast/seawrack_gloves.png`
> A pair of full-fingered woven gloves in dark salt-cured fibre, laid flat and
> slightly overlapping. ⭐ **A hardened, slightly domed panel across each
> palm and knuckle** — smooth, closed, nothing sharp — the surface the deflect
> stat is glancing off of. Salt-stiff cuffs.

### Equipment — the chase

**Fulgurite Pendant** — *rare · neck · 8% crit, +10 crit damage · Lv 20*
`assets/items/stormcliff_coast/fulgurite_pendant.png`
> A pendant on a plaited cord: a single shard of fused dark glass, thumb-sized
> and branching like frozen lightning, hung point-down. ⭐ **A hairline of live
> white light runs the branching crack down its centre** — spiky and hot, a
> point rather than a face, the same convention crit always draws to. The rest
> of the glass is matte, near-black.

**Uplight** — *epic · main hand · +6 dmg/cast, +4 accuracy, 12% crit, +15
crit damage · Lv 22 · 1 socket*
`assets/items/stormcliff_coast/uplight.png`
> A short one-handed wand of fused dark glass, forearm-length, branching at
> the tip like a root cast in lightning rather than growing toward it. ⚠️ Epic,
> so it is doing something: a live white-blue light travels **up** the
> branching tip toward the hand, never down — *the return stroke travels
> upward*. One small empty socket cut into the grip, waiting. Light, quick,
> obviously one-handed.

## Thunderspire Peaks · Lv 23–28 · Electro + Aero · **9 items**

> ⭐ *You are inside the storm, and it is building to something.* Everything
> here should read as **gathering charge, not spending it** — light lives in
> tight coiled veins and single bright points rather than open glow. ⚠️ No
> motes here: a hybrid drops its parents' Electro and Aero families rather
> than owning any of its own, so this zone's icon set is materials, an
> intermediate good, and equipment only.

**Palette:** pale rowan wood, rust-red iron ore, humming quartz white-violet,
storm-cloud grey, one hairline vein of white-blue light.

### Materials

**Rowan Log** — *common · material · Woodcarving t4*
`assets/items/thunderspire_peaks/rowan_log.png`
> A single straight-grained length of pale ash-white wood, forearm-long,
> resting at a slight angle. Bark stripped from one face, the exposed grain
> faintly silvered, twisted subtly along its length from a life spent leaning
> into wind. ⭐ *Mountain ash above the treeline, which should not be
> possible.*

**Iron Ore** — *common · material · Metalworking t4*
`assets/items/thunderspire_peaks/iron_ore.png`
> Two or three broken lumps of dense rust-red rock the size of eggs, resting
> together as one mass. A dull metallic sheen where freshly broken, otherwise
> matte and grainy. Heavier-looking than Tin — no glow, no colour beyond the
> rust.

**Hum Quartz** — *uncommon · material · Enchanting t4 · ⏳ banks for Q3*
`assets/items/thunderspire_peaks/hum_quartz.png`
> A single rough crystal point the size of a thumb, pale white shot through
> with faint violet, standing on its broken end. ⭐ **A hairline blur around
> the tip** — the note it holds, drawn as the one thing in the image that
> is not quite still. ⚠️ Uncommon — no other light on it.

### Intermediate goods

**Iron Ingot** — *common · material · Metalworking t4 output*
`assets/items/thunderspire_peaks/iron_ingot.png`
> A single cast bar of iron the size of a hand, resting flat, edges sharp
> from the mould. Dull grey-black metal with a faint cold sheen, a thin seam
> line down one side. ⭐ Plainer than Bronze — iron reads as workmanlike, not
> ornamental, exactly what a weapon's core should look like.

### Equipment — the Rowan set (Woodcarving)

> ⭐ **The first crafted crit in the game, and the wood ladder's first gem
> socket.** ⚠️ Keep the socket small, dark and genuinely empty — a shallow
> round recess with no gem in it yet, never a stand-in glow.

**Rowan Quarterstaff** — *common · main hand · +4 dmg/charge, +8 accuracy, 3%
crit, +8 crit damage · Lv 25 · 1 socket*
`assets/items/thunderspire_peaks/rowan_quarterstaff.png`
> A long staff of pale ash-white Rowan wood, shown diagonally, grain running
> true and straight the full length. A hairline of white-blue light traces
> one edge of the grain, brightest near the top and fading toward the base.
> One small dark empty socket cut into the shaft below the grip, waiting.

**Rowan Wand** — *common · main hand · +5 dmg/cast, +3 accuracy, 4% crit,
+6 crit damage · Lv 25 · 1 socket*
`assets/items/thunderspire_peaks/rowan_wand.png`
> A short one-handed wand of pale Rowan wood, forearm-length, trimmed thin
> and straight-grained. The same hairline white-blue vein as the quarterstaff
> runs its length. One small dark empty socket at the base of the grip.

**Rowan Knot** — *common · off hand · +6 accuracy, 2% crit · Lv 25 ·
1 socket*
`assets/items/thunderspire_peaks/rowan_knot.png`
> A burl of dense, tightly whorled pale wood, fist-sized, carved smooth on
> one face and left rough on the other where the grain is deepest. The
> socket is cut into the smooth face, small and dark, empty. A single faint
> white-blue thread follows one whorl of the grain.

### Equipment — the chase

**Countstone Pendant** — *rare · neck · 10% crit, +12 crit damage · Lv 26*
`assets/items/thunderspire_peaks/countstone_pendant.png`
> A finger-length shard of Hum Quartz on a plaited cord, hung point-down.
> ⭐ Rare, so the crit reads as a live point: a single bright white-violet
> pulse sits at the tip, sharp rather than diffuse — spiky and hot, the same
> convention crit always draws to. The rest of the crystal is pale and matte.

**Groundfault Grips** — *epic · gloves · +5 accuracy, +4 dmg/cast · Lv 28*
`assets/items/thunderspire_peaks/groundfault_grips.png`
> A pair of heavy full-fingered gloves, dark storm-grey leather over a
> reinforced knuckle and palm plate. ⚠️ Epic, so it is doing something: a
> hairline of live white-blue light runs the seam of every finger and meets
> at the palm's centre in one small bright point, as though the last charge
> that hit them is still finding its way out. Scorched, not decorative.

---

## Frostfell Pass · Lv 21–26 · Aqua + Aero · **6 items**

> ⭐ *Everything that moves through here gets held.* The fusion is breath
> frozen mid-air — Aero stopped by Aqua. ⚠️ Nothing here should read as wet;
> everything is already stopped, not still freezing. Rime white and stone
> grey first, colour only where the shield stat or the epic's anchor motif
> earns it.

**Palette:** rime white, packed-frost grey, pale stone, faint held-breath
blue, one cold grey-white light for deflection.

### Materials

**Rimepelt** — *common · material · Tailoring t4*
`assets/items/frostfell_pass/rimepelt.png`
> A folded pelt of thick white fur the size of a lap-blanket, laid flat, edges
> still faintly stiff with frost that has not thawed. Dense pale fur with a
> grey undercoat showing at the part, a fine crust of white rime clinging to
> the guard hairs. Matte, cold-looking, no shine anywhere.

**Hoarlichen** — *common · material · Potions & Alchemy t4 · ⏳ banks for Q2*
`assets/items/frostfell_pass/hoarlichen.png`
> A single flat scab of lichen the size of a hand, peeled whole off black
> rock, grey-green fading to pale white at the crinkled edges. Rough, dry,
> faintly crystalline texture across its face. ⭐ Uncommon note of colour
> against the palette — the only living green in the whole zone.

**Everice** — *uncommon · material · Jewelry t5 · ⏳ banks for Q2*
`assets/items/frostfell_pass/everice.png`
> A single clean shard of clear ice the size of a thumb, resting on one flat
> face where it broke free of the rock. Glass-clear at the core, a faint milky
> haze at the edges, one hairline internal crack catching the light. ⭐
> Uncommon — one cold blue-white note, unlit, no melt anywhere on it.

### Equipment

**Rimepelt Belt** — *common · belt · +3 belt slots · Lv 23*
`assets/items/frostfell_pass/rimepelt_belt.png`
> A wide belt of stiff white rimepelt, laid out in a loose open curve, with a
> plain dark bone buckle. ⭐ **Three empty loops** of the same pelt stitched
> along the strap, each wide enough for a bottle and visibly holding nothing.
> ⚠️ The loops are the entire point — draw them large, open and unmistakable,
> because the capacity *is* the stat.

**Rimebound Ring** — *rare · ring · 10% deflect, 20% amount, +3 dodge · Lv 24*
`assets/items/frostfell_pass/rimebound_ring.png`
> A slim band of clear ice-shot stone shown standing upright, near-colourless
> with one faint milky vein running around its circumference. ⭐ Rare, so both
> stats read as light: a thin cool grey-white line traces the deflect vein,
> and a second, fainter thread of pale blue seems to lift slightly off the
> band's outer edge — dodge as a thing barely touching the surface it sits on.

**The Holdfast** — *epic · neck · +15% shield strength · Lv 25*
`assets/items/frostfell_pass/the_holdfast.png`
> A heavy grip of stone-grey rimestone worn at the throat on a plain cord,
> shaped the way kelp anchors itself to rock — a splayed, gripping base
> tapering to a smooth worn top. ⭐ Epic, so it is visibly doing something: a
> faint cool grey-white light pulses slowly along the gripping base, as though
> testing its hold and finding it every time. ⚠️ Nothing sharp anywhere on
> it — the shield stat's convention, carried by the whole object rather than
> one feature.

---

## The Molten Deep · Lv 25–29 · Pyro + Geo · **6 items**

> ⭐ *The stone is a liquid and has been the whole time.* ⚠️ Nothing here
> should read as two elements sharing a frame — it is one substance at two
> temperatures. Black cooled crust and dull ash grey first; ember orange only
> where a crack, a mechanic, or a crit earns it; deflection's cool grey-white
> light where the Geo half earns it instead.

**Palette:** black cooled crust, ember orange, dull ash grey, cool grey-white
deflection light.

### Materials

**Obsidian** — *uncommon · material · Jewelry t4 · ⏳ banks for Q2*
`assets/items/the_molten_deep/obsidian.png`
> A single chunk of glassy black stone about the size of a fist, sheared
> along one conchoidal face that catches the light in a sharp curve. Deep
> matte black elsewhere, no glow. ⭐ Uncommon — one clean edge of reflected
> light along the broken face, unlit.

**Firesalt** — *common · material · Potions & Alchemy t5 · ⏳ banks for Q2*
`assets/items/the_molten_deep/firesalt.png`
> A small crust of pale mineral flakes, roughly a handful, mounded loosely on
> nothing. Dusty white-grey with a faint yellow bloom at the edges where the
> heat concentrated it. Dry, inert, no shimmer.

**Emberhide** — *common · material · Tailoring t5 · kill-only, no node*
`assets/items/the_molten_deep/emberhide.png`
> A single folded hide the size of a lap-blanket, matte black on the outer
> face with a scatter of hairline cracks. Dull ember orange shows through
> only at the cracks, never as a wash. Heavy, faintly warm.

### Equipment

**Emberhide Belt** — *common · belt · 4 belt slots · Lv 27*
`assets/items/the_molten_deep/emberhide_belt.png`
> A wide strap of black Emberhide shown laid flat, four empty loops sewn
> along its length. ⭐ **Loops drawn empty** — the capacity is the point.
> Hairline orange cracks run through the leather itself, the same texture as
> the raw hide.

**Firstmelt Loop** — *rare · ring · 5% crit, +25 crit damage · Lv 28*
`assets/items/the_molten_deep/firstmelt_loop.png`
> A single ring shown standing upright, cast in one motion from dark stone
> that never quite closed into a true circle — a visible seam where the ends
> nearly meet. ⭐ Rare, so the crit reads as a light source: a hairline of
> live ember-orange runs the seam, a point rather than a face, the rest of
> the band matte black. ⚠️ No border — the ring's own ember seam is the whole
> cue.

**The Long Cooling** — *epic · hat · +22 max HP, 12% deflect, 25% amount, +15
crit damage · Lv 29*
`assets/items/the_molten_deep/the_long_cooling.png`
> A circlet of polished black obsidian, shown from a three-quarter angle,
> smooth and worn bright in one groove around the brow. ⚠️ Epic, so it is
> visibly doing two things at once: the groove itself carries a cool
> grey-white light, smooth and closed, nothing sharp for a blow to catch on
> — the deflect; and one hairline crack low on the band still shows a live
> ember-orange point — the crit. ⭐ *"It is still cooling; it will always
> still be cooling"* — the two lights never meet.

---

## The Kiln Desert · Lv 30–34 · Solar · **13 items**

> ⭐ *Burning and freezing at once.* ⚠️ **A contradiction, not a heat.**
> Every object here is sun-bleached and salt-crusted in the same breath,
> hard-edged, and dry all the way through. Nothing is soft, nothing is
> damp, and there is no cloth in this zone at all — so leather, fibre and
> weave are simply absent from the set.

**Palette:** bleached bone white, salt crust, dried blood-grey ironwood,
pale gold for the Solar motes, one hard white shadow-edge on the epic.

### Materials

**Ironwood Log** — *common · material · Woodcarving t5*
`assets/items/the_kiln_desert/ironwood_log.png`
> A single short, squat log the length of a forearm, bark the colour of
> dried blood-grey and split away at one end to show pale dense heartwood
> with a near-invisible grain; one cut face is polished smooth by sand.

**Glasswort** — *common · material · Potions & Alchemy t5*
`assets/items/the_kiln_desert/glasswort.png`
> A hand-sized sprig of jointed, leafless succulent stems, translucent pale
> green shading to a salt-crusted red at the tips, laid flat with a scatter
> of white salt grains around its base.

**Solar Essence** — *rare · material · Enchanting t6 · **bound** ·
kill-only*
`assets/items/the_kiln_desert/solar_essence.png`
> A closed sphere of pale-gold light the size of a plum held inside a cage
> of three thin dark-iron bands; Rare, so the gold is a real light source
> and the iron is lit by it.

### Motes

**Solar Dust** — *common · mote · dust · Solar*
`assets/items/the_kiln_desert/solar_dust.png`
> A small loose heap of glittering pale-gold powder, the size of a coin
> pile, unlit and matte with one warm highlight.

**Solar Shard** — *common · mote · shard · Solar*
`assets/items/the_kiln_desert/solar_shard.png`
> Three angular slivers of pale-gold translucent stone the size of a
> thumbnail, fanned so one lies edge-on.

**Solar Crystal** — *uncommon · mote · crystal · Solar*
`assets/items/the_kiln_desert/solar_crystal.png`
> A single clear six-sided crystal a thumb long, colourless at the base and
> warming to pale gold at the tip, with one clean note of unlit gold — no
> glow spilling off it.

### Consumables

**Pilgrim's Ration** — *common · consumable · restores 110 health*
`assets/items/the_kiln_desert/pilgrims_ration.png`
> A cloth-wrapped brick of pale pressed meal the size of a fist, twine-tied,
> one corner unwrapped to show the dry crumbling interior.

**Glasswort Draught** — *common · beltable · restores 125 health*
`assets/items/the_kiln_desert/glasswort_draught.png`
> A squat stoppered glass bottle the height of a hand, full of cloudy
> pale-green liquid, its cork sealed under a wrap of salt-stiffened cloth.

### Equipment

**Ironwood Quarterstaff** — *common · main hand · +5 dmg/charge, +9
accuracy, 4% crit, +10 crit damage · Lv 30 · 1 socket*
`assets/items/the_kiln_desert/ironwood_quarterstaff.png`
> A two-handed staff as tall as a person, dark red-grey ironwood with a
> thick weighted butt and a dull bronze ferrule at each end; one small empty
> round socket sits in the grip, obviously unfilled.

**Ironwood Wand** — *common · main hand · +6 dmg/cast, +4 accuracy, 5% crit,
+8 crit damage · Lv 30 · 1 socket*
`assets/items/the_kiln_desert/ironwood_wand.png`
> A tapering one-handed wand the length of a forearm, dark ironwood polished
> to a low sheen with a fine hairline of ember-red inlay along the taper;
> one small empty socket at the base.

**Ironwood Knot** — *common · off hand · +5 accuracy, 3% crit · Lv 30 · 1
socket*
`assets/items/the_kiln_desert/ironwood_knot.png`
> A fist-sized dark burl of ironwood, worn glass-smooth by handling, with
> one dead-flat filed facet across its face and a single empty socket in the
> middle of it.

**The Shadeless Band** — *rare · ring · +6 accuracy, +18 max HP · Lv 32*
`assets/items/the_kiln_desert/the_shadeless_band.png`
> A plain heavy ring of pale sand-fused glass standing upright, its outer
> face rough and frosted, its inner face mirror-bright; Rare, so one thin
> line of hard gold light traces the polished inside and lights the rough
> outside from within.

**The Hardest Edge** — *epic · main hand · +7 dmg/charge, +11 accuracy, 8%
crit, +18 crit damage · Lv 34 · 1 socket*
`assets/items/the_kiln_desert/the_hardest_edge.png`
> A two-handed ironwood staff, near-black, with one side of its entire
> length cut dead flat and razor-straight while the other stays round; Epic,
> so a blade of hard white light runs along the flat face and *moves* — the
> edge is a shadow's edge and it is sweeping slowly as though the sun were
> going down.

---

## The Mirrormere · Lv 32–37 · Lunar · **16 items**

> ⭐ *The reflection is bigger than the thing, and it is looking back.*
> ⚠️ Near-monochrome throughout, and **flat or slightly too smooth** —
> surfaces that should have depth and do not. Bloodwood's red is the only
> warm note in the whole zone, and it belongs to the wood, not to light.

**Palette:** silver, bone-white, lake-grey, deep-water dark, one
bloodwood red; pale cold silver for the Lunar motes.

### Materials

**Bloodwood Log** — *common · material · Woodcarving t6*
`assets/items/the_mirrormere/bloodwood_log.png`
> A short split log the length of a forearm, grey weathered bark outside and
> a deep wine-red heartwood face inside with darker rings; the red face is
> turned toward the viewer and is matte, not wet.

**Mirrorflax** — *common · material · Tailoring t5*
`assets/items/the_mirrormere/mirrorflax.png`
> A tied hank of long pale fibre the size of a forearm, silver-grey and
> faintly iridescent, with one strand catching a cold white highlight along
> its whole length.

**Lunar Essence** — *rare · material · Enchanting t6 · **bound** ·
kill-only*
`assets/items/the_mirrormere/lunar_essence.png`
> A sphere of pale silver light the size of a plum inside three thin dark
> bands; Rare, so the silver lights the bands from inside.

### Motes

**Lunar Dust** — *common · mote · dust · Lunar*
`assets/items/the_mirrormere/lunar_dust.png`
> A small heap of fine silver-white powder, matte, with a single cool
> highlight.

**Lunar Shard** — *common · mote · shard · Lunar*
`assets/items/the_mirrormere/lunar_shard.png`
> Three flat slivers of silvered translucent stone, thumbnail-sized, one of
> them face-on and faintly mirroring.

**Lunar Crystal** — *uncommon · mote · crystal · Lunar*
`assets/items/the_mirrormere/lunar_crystal.png`
> A single clear six-sided crystal a thumb long, colourless at the base and
> cooling to pale silver-blue at the tip, one unlit cold note.

### Equipment

**Bloodwood Quarterstaff** — *common · main hand · +6 dmg/charge, +10
accuracy, 5% crit, +12 crit damage · Lv 35 · 1 socket*
`assets/items/the_mirrormere/bloodwood_quarterstaff.png`
> A two-handed staff as tall as a person, deep wine-red wood with near-black
> figuring, a weighted butt and plain steel ferrules; one empty round socket
> in the grip.

**Bloodwood Wand** — *common · main hand · +7 dmg/cast, +4 accuracy, 6%
crit, +10 crit damage · Lv 35 · 1 socket*
`assets/items/the_mirrormere/bloodwood_wand.png`
> A short tapering one-handed wand, deep red and polished, with a darker
> spiral of grain running its length; one empty socket at the base.

**Bloodwood Knot** — *common · off hand · +6 accuracy, 4% crit · Lv 35 · 1
socket*
`assets/items/the_mirrormere/bloodwood_knot.png`
> A fist-sized dark-red burl worn smooth, one flat filed facet, a single
> empty socket.

**Mirrorflax Hood** — *common · hat · +5 accuracy · Lv 34*
`assets/items/the_mirrormere/mirrorflax_hood.png`
> A soft silver-grey hood laid flat, its brim stiffened into a perfectly
> straight horizontal edge, doubled seams visible at the shoulders.

**Mirrorflax Robe** — *common · robe top · +23 max HP · Lv 34*
`assets/items/the_mirrormere/mirrorflax_robe.png`
> A long silver-grey robe on an invisible form, thick and visibly layered
> with doubled seams down both sides, the weave legible up close.

**Mirrorflax Leggings** — *common · robe bottom · +16 max HP · Lv 34*
`assets/items/the_mirrormere/mirrorflax_leggings.png`
> Silver-grey quilted leggings laid flat, the quilting lines running in
> visible parallel channels.

**Mirrorflax Boots** — *common · boots · +5 max HP, +4 dodge · Lv 34*
`assets/items/the_mirrormere/mirrorflax_boots.png`
> A pair of low silver-grey boots with thick soft soles, one lifted slightly
> as though mid-step and barely touching its own shadow.

**Mirrorflax Gloves** — *common · gloves · +5 max HP, 10% deflect, 20%
amount · Lv 34*
`assets/items/the_mirrormere/mirrorflax_gloves.png`
> A pair of silver-grey gloves, palms outward, the palm panels visibly
> doubled and quilted; one faint cool grey-white line traces each palm.

**The Waning Charm** — *rare · ring · +16 max HP, +9 dodge · Lv 35*
`assets/items/the_mirrormere/the_waning_charm.png`
> A slim silver band standing upright, thinning smoothly from a broad arc at
> the top to almost nothing at the bottom so the circle looks incomplete;
> Rare, so a thread of pale blue light lifts very slightly off the thin end
> and does not quite touch it.

**The Larger Reflection** — *epic · robe top · +40 max HP, +6 dodge · Lv 37*
`assets/items/the_mirrormere/the_larger_reflection.png`
> A long silver-grey mantle on an invisible form, the cloth reading
> correctly at the shoulders but subtly *too big* at the hem; Epic, so the
> hem is moving — a slow ripple travelling outward as though something below
> were wearing the other half.

---

## Starfall Basin · Lv 34–39 · Astral · **9 items**

> ⭐ *Everything here arrived, and the ground is the record of it.* ⚠️ The
> objects are **impact debris and what was quarried out of it** — nothing
> here grew and nothing here was placed. Cold, pitted, and darker than the
> ground it came out of.

**Palette:** blue-black, indigo, pitted sky-iron grey, pale ground-white,
and hard white points for the Astral motes.

### Materials

**Sky-Iron Ore** — *common · material · Metalworking t5*
`assets/items/starfall_basin/skyiron_ore.png`
> A fist-sized lump of dark pitted metal-bearing rock, its surface scabbed
> with a thin black fusion crust and broken open on one face to show bright
> grey metal flecked through the stone.

**Fallstone** — *uncommon · material · Enchanting t5*
`assets/items/starfall_basin/fallstone.png`
> A smooth ovoid stone the size of an egg, matte black-grey, with a faint
> indigo sheen across one curve and a shallow dimple where it struck;
> Uncommon, so the indigo is one clean unlit note.

**Skysteel Ingot** — *common · material · Metalworking t5*
`assets/items/starfall_basin/skysteel_ingot.png`
> A single small rectangular ingot the length of a hand, cool blue-grey with
> a faint watered figure across its top face and one bevelled corner; matte,
> no glow.

**Astral Essence** — *rare · material · Enchanting t6 · **bound** ·
kill-only*
`assets/items/starfall_basin/astral_essence.png`
> A sphere of deep indigo light the size of a plum caged in three thin bands
> of sky-iron; Rare, so the indigo is a real light source.

### Motes

**Astral Dust** — *common · mote · dust · Astral*
`assets/items/starfall_basin/astral_dust.png`
> A small heap of blue-black powder shot with points of white, loosely
> spread rather than piled.

**Astral Shard** — *common · mote · shard · Astral*
`assets/items/starfall_basin/astral_shard.png`
> Three angular slivers of deep indigo translucent stone with white flecks
> inside, thumbnail-sized, fanned.

**Astral Crystal** — *uncommon · mote · crystal · Astral*
`assets/items/starfall_basin/astral_crystal.png`
> A clear six-sided crystal a thumb long, deep indigo at the base clearing
> to colourless, with a scatter of white points suspended inside it.

### Equipment

**Zodiac Pendant** — *rare · neck · 10% crit, +12 crit damage · Lv 37*
`assets/items/starfall_basin/zodiac_pendant.png`
> A flat disc of dark sky-iron the size of a coin on a fine chain, its rim
> punched with small marks; Rare, so a single point of hot white light sits
> at the top of the rim and lights the rest of the disc.

**The Aimed Sky** — *epic · neck · +9 dmg/cast, 10% crit, +18 crit damage ·
Lv 39*
`assets/items/starfall_basin/the_aimed_sky.png`
> A heavy dark sky-iron pendant, a flat disc with a single fine line scored
> across it from edge to edge; Epic, so a bead of hard white light travels
> slowly along that line, arrives at the rim, and starts again.

---

## Tidewrack Shoals · Lv 36–40 · Lunar + Aqua · **11 items**

> ⭐ *The water goes out further than seems survivable and comes back
> faster.* ⚠️ Everything here has been **left behind by a tide**, so every
> object reads as wet-then-dried: salt bloom, water marks, weed still
> clinging. The Lunar half is cold and pale; the Aqua half is dark and
> heavy.

**Palette:** wrack-brown, wet slate, pale shell nacre, cold moon-silver,
one green-black note of deep water.

### Materials

**Wrackcotton** — *common · material · Tailoring t6*
`assets/items/tidewrack_shoals/wrackcotton.png`
> A tied bundle of pale fibrous strands the size of a forearm, sea-grey
> fading to bleached white, with a fine dusting of dried salt and one dark
> strand of weed still caught in it.

**Nacre** — *uncommon · material · Jewelry t6*
`assets/items/tidewrack_shoals/nacre.png`
> A single curved plate of mother-of-pearl the size of a palm, resting
> concave-up, pale cream with soft bands of pink and green iridescence
> across its inner face; Uncommon, so the iridescence is one clean note,
> unlit.

**Drownling Hide** — *common · material · Tailoring t6*
`assets/items/tidewrack_shoals/drownling_hide.png`
> A folded hide the size of a lap blanket, slate-grey and faintly
> translucent at the thin edges, with a fine pebbled grain; matte, no shine.

### Equipment

**Wrackcotton Hood** — *common · hat · +5 accuracy · Lv 39*
`assets/items/tidewrack_shoals/wrackcotton_hood.png`
> A pale grey hood laid flat, brim stiffened dead straight, the weave
> visibly coarse and doubled at the crown.

**Wrackcotton Robe** — *common · robe top · +32 max HP · Lv 39*
`assets/items/tidewrack_shoals/wrackcotton_robe.png`
> A long pale sea-grey robe on an invisible form, thick and unmistakably
> layered, doubled seams down both sides and at the hem.

**Wrackcotton Leggings** — *common · robe bottom · +22 max HP · Lv 39*
`assets/items/tidewrack_shoals/wrackcotton_leggings.png`
> Pale grey leggings laid flat, quilted in visible channels down to the knee
> and smooth from there.

**Wrackcotton Boots** — *common · boots · +6 max HP, +5 dodge · Lv 39*
`assets/items/tidewrack_shoals/wrackcotton_boots.png`
> A pair of tall pale-grey boots with soft soles and long rear laces, one
> caught mid-step and barely touching its shadow.

**Wrackcotton Gloves** — *common · gloves · +7 max HP, 14% deflect, 24%
amount · Lv 39*
`assets/items/tidewrack_shoals/wrackcotton_gloves.png`
> Pale grey gloves, palms outward, palm panels visibly tripled; a cool
> grey-white line traces each palm.

**Drownling Belt** — *common · belt · +5 belt slots · Lv 38*
`assets/items/tidewrack_shoals/drownling_belt.png`
> A wide slate-grey hide belt laid in a loose open curve with a plain dark
> shell buckle and **five empty loops** stitched along it, each wide enough
> for a bottle and visibly holding nothing.

**The Turning Tide** — *rare · neck · +6 dodge, +12% shield strength · Lv
38*
`assets/items/tidewrack_shoals/the_turning_tide.png`
> A broad teardrop of mother-of-pearl on a plain cord, standing upright;
> Rare, so one soft cool light runs around the shell's outer rim and lights
> the iridescence from the edge inward.

**Lowwater Tread** — *epic · boots · +24 max HP, +7 dodge, +10% shield
strength · Lv 40*
`assets/items/tidewrack_shoals/lowwater_tread.png`
> A pair of tall grey drownling-hide boots, soles worn to nothing at the
> toe, standing in a shallow wet footprint; Epic, so the footprint is
> *filling* — a thin sheet of water creeping in around them and never quite
> reaching the sole.

---

## The Sunless Reach · Lv 38–42 · Solar + Lunar · **9 items**

> ⭐ *Identical ground, opposite worlds, one line between them.* ⚠️ **The
> fusion is a boundary, not a blend** — no dusk, no gradient, no soft
> falloff anywhere. An object is hard-lit or wholly unlit, and the few that
> are both carry a straight visible edge across them.

**Palette:** hard yellow-white glare, flat lightless black, pale cold
moon-grey as the only third value, ebony near-black for the wood.

### Materials

**Ebony Log** — *common · material · Woodcarving t7*
`assets/items/the_sunless_reach/ebony_log.png`
> A short split log the length of a forearm, near-black throughout with a
> fine straight grain, one end cut and polished to a dull sheen, the bark
> dark grey and papery.

**Duskcap** — *common · material · Potions & Alchemy t6*
`assets/items/the_sunless_reach/duskcap.png`
> A single mushroom the size of a fist, cap half bleached bone-white and
> half deep slate-grey with a hard straight division between the two, on a
> pale stem.

**Eclipse Opal** — *uncommon · material · Jewelry t7*
`assets/items/the_sunless_reach/eclipse_opal.png`
> An oval polished stone the size of a thumb, one half milk-white with soft
> fire, the other half matte black, split by a clean straight edge;
> Uncommon, so the fire is one unlit note.

### Consumables

**Duskcap Tonic** — *common · beltable · 34 health a turn for 3 turns*
`assets/items/the_sunless_reach/duskcap_tonic.png`
> A tall narrow stoppered bottle the height of a hand holding a layered
> liquid — pale grey above, near-black below — with a soft rounded shoulder
> and a wax-sealed cork.

### Equipment

**Ebony Quarterstaff** — *common · main hand · +7 dmg/charge, +11 accuracy,
6% crit, +14 crit damage · Lv 40 · 1 socket*
`assets/items/the_sunless_reach/ebony_quarterstaff.png`
> A two-handed near-black staff as tall as a person, polished to a
> stone-like sheen, with plain dark steel ferrules and a thick weighted
> butt; one empty round socket in the grip.

**Ebony Wand** — *common · main hand · +8 dmg/cast, +5 accuracy, 7% crit,
+12 crit damage · Lv 40 · 1 socket*
`assets/items/the_sunless_reach/ebony_wand.png`
> A short tapering one-handed wand of near-black polished wood, its
> silhouette very clean against the white ground; one empty socket at the
> base.

**Ebony Knot** — *common · off hand · +6 accuracy, 5% crit · Lv 40 · 1
socket*
`assets/items/the_sunless_reach/ebony_knot.png`
> A fist-sized near-black burl, glass-smooth, with one flat filed facet
> showing raw pale-grey end grain; a single empty socket.

**Crestline Ring** — *rare · ring · +5 accuracy, +20 max HP, +5 dodge · Lv
40*
`assets/items/the_sunless_reach/crestline_ring.png`
> A ring standing upright, one half of the band polished bright and the
> other half matte black, meeting at two hard seams; Rare, so a thin warm
> light traces the bright half and a thread of cool blue lifts just off the
> dark half.

**The Dividing Line** — *epic · main hand · +12 dmg/cast, +6 accuracy, 10%
crit, +20 crit damage · Lv 42 · 1 socket*
`assets/items/the_sunless_reach/the_dividing_line.png`
> A slim black ebony wand held vertically; Epic, so one side of its entire
> length is lit hard white and the other is in total shadow, with no falloff
> between them — and the lit side is slowly *changing sides*.

---

## The Shattered Orrery · Lv 40–44 · Astral + Electro · **7 items**

> ⭐ *Rings the size of bridges, half of them fallen, and the fallen half
> still turning.* ⚠️ Every object is **a part off a machine that has not
> stopped** — cut, fitted, numbered, and now loose. Nothing is organic and
> nothing is decorative.

**Palette:** tarnished brass, blue-black iron, cold indigo, and a live
white-blue arc note where the Electro half shows.

### Materials

**Orrery Scrap** — *common · material · Metalworking t7*
`assets/items/the_shattered_orrery/orrery_scrap.png`
> A single broken gear tooth of dull yellow-brown brass the length of a
> hand, sheared at the root with a bright ragged break face, the rest
> tarnished and scored with fine wear lines.

**Arcsalt** — *common · material · Potions & Alchemy t7*
`assets/items/the_shattered_orrery/arcsalt.png`
> A broken slab of white crystalline crust the size of a palm, thin and
> plate-like, its underside stained a faint violet-black where it lifted off
> the metal.

**Sidereal Glass** — *uncommon · material · Jewelry t7*
`assets/items/the_shattered_orrery/sidereal_glass.png`
> A thick round lens of pale blue-green glass the size of a palm, one edge
> chipped, lying at a slight angle so its curve catches a hard highlight;
> Uncommon, so that highlight is the only colour note.

**Starbrass Ingot** — *common · material · Metalworking t7*
`assets/items/the_shattered_orrery/starbrass_ingot.png`
> A small rectangular ingot the length of a hand, warm yellow-brown brass
> with a faint blue tarnish bloom at one end and a bevelled corner; matte.

### Consumables

**Arcsalt Draught** — *common · beltable · restores 185 health*
`assets/items/the_shattered_orrery/arcsalt_draught.png`
> A heavy squat bottle of thick blue-green glass, half the height of a hand,
> with a brass collar and stopper and a clear colourless liquid inside in
> which a few white crystals are still settling.

### Equipment

**Sidereal Signet** — *rare · ring · +4 accuracy, 10% crit · Lv 42*
`assets/items/the_shattered_orrery/sidereal_signet.png`
> A broad flat-faced brass signet ring standing upright, its face cut with
> fine incised marks arranged in a ring; Rare, so one of the marks is a
> point of hot white light and the others are lit by it.

**The Running Count** — *epic · gloves · +10 dmg/cast, +5 accuracy, 8% crit
· Lv 44*
`assets/items/the_shattered_orrery/the_running_count.png`
> A pair of brass-plated gauntlets, palms outward, with a row of small
> toothed wheels set along the back of each hand; Epic, so the wheels are
> *turning* — slowly, unevenly, and never stopping.

---

## The Glass Archive · Lv 43–47 · Solar + Arcane · **11 items**

> ⭐ *They wrote it in light, and light does not keep.* ⚠️ The light here
> is **white and flat, never golden** — no sunset anywhere in the set.
> Nothing is ruined either: everything is intact, well made, and simply
> unreadable.

**Palette:** colourless plate glass, brass, bone-white vellum, hard white
glare, one cool violet note for the Arcane half.

### Materials

**Sunbleach Lichen** — *common · material · Potions & Alchemy t8*
`assets/items/the_glass_archive/sunbleach_lichen.png`
> A flat scab of lichen the size of a hand, bone-white at the centre fading
> to pale ochre at its crinkled edge, peeled whole off pale stone, dry and
> faintly crystalline.

**Aetherglass** — *uncommon · material · Jewelry t8*
`assets/items/the_glass_archive/aetherglass.png`
> A thin square plate of colourless glass the size of a palm, one corner
> broken, standing on edge; Uncommon, so a single faint violet note runs
> along one internal flaw and nothing else is lit.

**Palimpsest Vellum** — *common · material · Tailoring t7*
`assets/items/the_glass_archive/palimpsest_vellum.png`
> A single sheet of pale cream vellum the size of a book, lying flat with
> its edges curling, its surface scraped visibly thin in patches where older
> grey script shows faintly through the newer.

### Motes

**Arcane Dust** — *common · mote · dust · Arcane*
`assets/items/the_glass_archive/arcane_dust.png`
> A small heap of fine violet-grey powder, matte, with one cool highlight.

**Arcane Shard** — *common · mote · shard · Arcane*
`assets/items/the_glass_archive/arcane_shard.png`
> Three angular slivers of translucent violet stone, thumbnail-sized, fanned
> with one edge-on.

**Arcane Crystal** — *uncommon · mote · crystal · Arcane*
`assets/items/the_glass_archive/arcane_crystal.png`
> A clear six-sided crystal a thumb long, colourless at the base deepening
> to violet at the tip, one clean unlit violet note.

### Consumables

**Sunbleach Tonic** — *common · beltable · 42 health a turn for 3 turns*
`assets/items/the_glass_archive/sunbleach_tonic.png`
> A tall narrow stoppered bottle the height of a hand holding a cloudy
> bone-white liquid, its shoulder soft and rounded, a strip of written
> vellum tied to its neck as a label with the writing faded out.

### Equipment

**Palimpsest Belt** — *common · belt · +6 belt slots · Lv 45*
`assets/items/the_glass_archive/palimpsest_belt.png`
> A wide pale-cream vellum belt laid in a loose open curve with a plain
> brass buckle and **six empty loops** stitched along it, faint grey script
> visible running beneath the stitches.

**The Last Reading** — *rare · neck · +5 accuracy, +20 crit damage, +30 max
HP · Lv 45*
`assets/items/the_glass_archive/the_last_reading.png`
> A flat rectangular locket of pale glass on a fine chain, standing upright,
> a folded scrap of blank vellum visible inside it; Rare, so one hard white
> point of light sits at the locket's edge and throws a single thin straight
> line of shadow across the glass, like the shadow of a ruled edge — no
> letters, no marks, nothing readable anywhere.

**The Noon Hour** — *epic · hat · +20 crit damage, +55 max HP, 12% deflect,
14% amount · Lv 47*
`assets/items/the_glass_archive/the_noon_hour.png`
> A broad circlet of pale archive glass, worn as a band, its front panel a
> flat lens; Epic, so a band of hard white light crosses the lens and
> *travels* — sweeping from one side to the other over several seconds,
> leaving a faint after-image of writing behind it that fades before it can
> be read.

### The gate

**Celestial Totem** — *rare · key · opens the road above Rimeholt*
`assets/items/the_glass_archive/celestial_totem.png`
> A hand-length rod of dark sky-iron with three small caged spheres set
> along it — gold, silver and indigo — and a fourth empty seat at the top;
> Rare, so all three spheres are real light sources and the iron between
> them is lit by all three at once.

---

## Hallowmarch · Lv 45–49 · Sanctus · **13 items**

> ⭐ *Someone is still doing the upkeep, and nobody has seen them.*
> ⚠️ **Nothing here is ruined, mossy or overgrown.** Every object is
> maintained, square, and recently attended to — that intactness is the
> whole idea, and an artist's instinct toward picturesque decay must be
> resisted. ⚠️ The Sanctus naming trap applies to the icons too: no sun
> discs, no rays, no haloes.

**Palette:** pale dressed road-stone, silver-white spiritwood, whitewash,
plain pale metal, and one warm gold note — lamplight and goldenrood.

### Materials

**Spiritwood Log** — *common · material · Woodcarving t8*
`assets/items/hallowmarch/spiritwood_log.png`
> A short pale log the length of a forearm, bark silver-white and smooth,
> split at one end to show near-white heartwood with a faint gold figure
> running through it.

**Goldenrood** — *common · material · Potions & Alchemy t8*
`assets/items/hallowmarch/goldenrood.png`
> A cut stem the length of a forearm topped with a dense plume of small gold
> flowers, a few pale leaves along the stalk, laid flat with the cut end
> wet.

### Motes

**Sanctus Dust** — *common · mote · dust · Sanctus*
`assets/items/hallowmarch/sanctus_dust.png`
> A small heap of fine warm-white powder with a faint gold cast, matte, one
> soft highlight.

**Sanctus Shard** — *common · mote · shard · Sanctus*
`assets/items/hallowmarch/sanctus_shard.png`
> Three flat slivers of translucent warm-white stone, thumbnail-sized,
> fanned, one edge-on.

**Sanctus Crystal** — *uncommon · mote · crystal · Sanctus*
`assets/items/hallowmarch/sanctus_crystal.png`
> A clear six-sided crystal a thumb long, colourless at the base warming to
> pale gold at the tip, one clean unlit warm note.

### Consumables

**Climber's Ration** — *common · consumable · restores 195 health*
`assets/items/hallowmarch/climbers_ration.png`
> An oilcloth-wrapped bundle the size of two fists tied with cord, one fold
> open to show a wedge of pale hard cheese and a dark dried strip.

**Goldenrood Draught** — *common · beltable · restores 225 health*
`assets/items/hallowmarch/goldenrood_draught.png`
> A round-shouldered stoppered bottle the height of a hand full of clear
> gold liquid, a band of pale stamped tin around its neck.

### Equipment

**Spiritwood Quarterstaff** — *common · main hand · +8 dmg/charge, +12
accuracy, 7% crit, +16 crit damage · Lv 45 · 2 sockets*
`assets/items/hallowmarch/spiritwood_quarterstaff.png`
> A two-handed pale staff as tall as a person, silver-white wood with gold
> figuring, a weighted butt and plain pale-metal ferrules; **two** small
> empty round sockets set in the grip, clearly unfilled.

**Spiritwood Wand** — *common · main hand · +9 dmg/cast, +5 accuracy, 8%
crit, +14 crit damage · Lv 45 · 2 sockets*
`assets/items/hallowmarch/spiritwood_wand.png`
> A tapering one-handed pale wand the length of a forearm with a fine gold
> vein down the taper; two empty sockets at the base.

**Spiritwood Knot** — *common · off hand · +7 accuracy, 6% crit · Lv 45 · 2
sockets*
`assets/items/hallowmarch/spiritwood_knot.png`
> A fist-sized silver-white burl, worn smooth, one flat filed facet, **two**
> empty sockets side by side in the facet.

**Votive Pendant** — *rare · neck · +18% shield strength, +12% healing
received · Lv 47*
`assets/items/hallowmarch/votive_pendant.png`
> A small flat teardrop of pale spiritwood on a plain cord, standing
> upright, its face carved with a single smooth channel; Rare, so a soft
> warm light sits in the channel and lights the whole pendant from that one
> line.

**The Maintained Road** — *epic · neck · +45 max HP, +20% shield strength,
+15% healing received · Lv 49*
`assets/items/hallowmarch/the_maintained_road.png`
> A broad flat icon of pale wood and pale metal worn at the throat on a
> short cord, its face a smooth unbroken bar like a length of road; Epic, so
> a soft gold light travels slowly along that bar from one end to the other
> and begins again without pause.

### The gate

**The Kept Third** — *rare · key · opens The Eclipsed Citadel*
`assets/items/hallowmarch/the_kept_third.png`
> A wedge-shaped plate of pale gold-veined wood the size of a palm, two
> edges cut dead straight and one broken, a single small green shoot growing
> from the broken edge; Rare, so a soft warm light comes from the joint
> where the shoot meets the wood.

---

## The Buried Sky · Lv 46–50 · Geo + Astral · **9 items**

> ⭐ *The rock remembers a sky that no longer exists.* ⚠️ **Strata, not
> caves** — every object reads as banded, layered or counted. The light set
> in the stone is cold, small and **point-like**: pinpricks, never a wash
> and never a beam.

**Palette:** charcoal, rust-brown, pale grey and near-black in horizontal
bands, with cold blue-white points for the Astral half.

### Materials

**Deepstratum Ore** — *common · material · Metalworking t8*
`assets/items/the_buried_sky/deepstratum_ore.png`
> A fist-sized block of banded dark rock, near-black with two fine paler
> grey strata running through it, one face freshly broken to show a dull
> blue-grey metallic sheen.

**Nadir Garnet** — *uncommon · material · Jewelry t8*
`assets/items/the_buried_sky/nadir_garnet.png`
> A deep red-black faceted stone the size of a thumb resting on one face,
> with a scatter of tiny pale points suspended inside it; Uncommon, so the
> red is one unlit note.

**Corebiter Hide** — *common · material · Tailoring t8*
`assets/items/the_buried_sky/corebiter_hide.png`
> A folded hide the size of a lap blanket, matte charcoal-black with a fine
> pebbled grain and a paler grey underside showing at the fold.

**Deepsteel Ingot** — *common · material · Metalworking t8*
`assets/items/the_buried_sky/deepsteel_ingot.png`
> A rectangular ingot the length of a hand, dark blue-grey with a faint
> banded figure across its top face echoing the strata, one bevelled corner;
> matte.

### Equipment

**Corebiter Belt** — *common · belt · +7 belt slots · Lv 48*
`assets/items/the_buried_sky/corebiter_belt.png`
> A wide charcoal-black hide belt laid in a loose open curve with a plain
> dark-steel buckle and **seven empty loops** stitched along it, each wide
> enough for a bottle and visibly holding nothing.

**Everice Band** — *common · ring · +15 max HP, +3 dodge, +12% shield
strength · Lv 45*
`assets/items/the_buried_sky/everice_band.png`
> A plain ring standing upright, a clear colourless ice-like stone set flush
> into a dark band, with one hairline milky vein through the stone; no glow
> — it is Common, an honest working object.

**Nacre Pendant** — *common · neck · +25 max HP, +6 dodge, +8% shield
strength · Lv 46*
`assets/items/the_buried_sky/nacre_pendant.png`
> An oval plate of mother-of-pearl the size of a thumb set in a dark
> obsidian backing on a fine chain, its soft pink-green iridescence unlit.

**Stonefall Signet** — *rare · ring · 6% crit, +22 max HP, 18% deflect · Lv
48*
`assets/items/the_buried_sky/stonefall_signet.png`
> A heavy dark ring with a broad flat garnet face, standing upright, the
> face entirely uncut and polished flat; Rare, so a single hard red point of
> light sits at the face's edge and throws the rest into relief.

**Bedrock Greaves** — *epic · robe bottom · +45 max HP, 10% deflect, 10%
amount · Lv 50*
`assets/items/the_buried_sky/bedrock_greaves.png`
> A pair of dark blue-grey plated greaves standing upright, layered in
> overlapping banded plates like strata; Epic, so a slow cool grey-white
> pulse travels up through the plates from the ankle and stops at the knee,
> over and over.

---

## The Umbral Wastes · Lv 47–51 · Umbra · **13 items**

> ⭐ *The dark here is deliberate. Something decided its shape.* ⚠️ Every
> silhouette should read as **cut**, not as faded — edges clean enough to
> be a drawing, interiors that swallow light entirely. Nothing is tattered
> and nothing is decayed; the dark is *neat*.

**Palette:** matte near-black against blue-white glacier ice, one cold
indigo note, and nothing warm anywhere.

### Materials

**Umbralweave** — *common · material · Tailoring t8*
`assets/items/the_umbral_wastes/umbralweave.png`
> A folded length of near-black cloth the size of a forearm, matte and
> swallowing light, its edges fraying into fine dark threads with one faint
> cold blue sheen along a single fold.

**Thoughtglass** — *uncommon · material · Jewelry t8*
`assets/items/the_umbral_wastes/thoughtglass.png`
> A faceted block of near-black translucent glass the size of a thumb, its
> facets unnaturally regular, with a faint indigo depth at the centre;
> Uncommon, so the indigo is one unlit note.

### Motes

**Umbra Dust** — *common · mote · dust · Umbra*
`assets/items/the_umbral_wastes/umbra_dust.png`
> A small heap of matte black powder that reads as a *shape* rather than a
> pile, with one cold edge highlight.

**Umbra Shard** — *common · mote · shard · Umbra*
`assets/items/the_umbral_wastes/umbra_shard.png`
> Three angular slivers of near-black translucent stone, thumbnail- sized,
> fanned; one catches a cold blue edge.

**Umbra Crystal** — *uncommon · mote · crystal · Umbra*
`assets/items/the_umbral_wastes/umbra_crystal.png`
> A clear six-sided crystal a thumb long, colourless at the base darkening
> to near-black at the tip, one unlit cold indigo note.

### Equipment

**Umbralweave Hood** — *common · hat · +6 accuracy · Lv 48*
`assets/items/the_umbral_wastes/umbralweave_hood.png`
> A near-black hood laid flat, brim stiffened into a dead-level horizontal
> edge, doubled seams visible at the shoulders.

**Umbralweave Robe** — *common · robe top · +42 max HP · Lv 48*
`assets/items/the_umbral_wastes/umbralweave_robe.png`
> A long near-black robe on an invisible form, thick and visibly layered
> with doubled seams, the weave legible only where the light catches an
> edge.

**Umbralweave Leggings** — *common · robe bottom · +29 max HP · Lv 48*
`assets/items/the_umbral_wastes/umbralweave_leggings.png`
> Near-black quilted leggings laid flat, the quilting channels catching a
> faint cold rim light.

**Umbralweave Boots** — *common · boots · +8 max HP, +6 dodge · Lv 48*
`assets/items/the_umbral_wastes/umbralweave_boots.png`
> A pair of tall matte-black boots with thick soft soles, one lifted as
> though mid-step and casting almost no contact shadow.

**Umbralweave Gloves** — *common · gloves · +9 max HP, 16% deflect, 22%
amount · Lv 48*
`assets/items/the_umbral_wastes/umbralweave_gloves.png`
> Near-black gloves, palms outward, panels visibly tripled; a cool
> grey-white line traces each palm.

**The Considered Ring** — *rare · ring · 8% crit, +34 crit damage · Lv 49*
`assets/items/the_umbral_wastes/the_considered_ring.png`
> A plain black band standing upright, its inner and outer surfaces both
> perfectly smooth and its proportions faintly, unsettlingly exact; Rare, so
> a single hot violet point sits on the band and lights the whole ring from
> that one place.

**The Deliberate Dark** — *epic · ring · 6% crit, +28 crit damage, +20 max
HP · Lv 51*
`assets/items/the_umbral_wastes/the_deliberate_dark.png`
> A heavy black ring with a deep faceted thoughtglass stone; Epic, so the
> stone is emissive and *working* — a slow violet glow gathering at its
> centre, reaching the facets, and going out, again and again.

### The gate

**The Dark Third** — *rare · key · opens The Eclipsed Citadel*
`assets/items/the_umbral_wastes/the_dark_third.png`
> A wedge-shaped plate of dark banded stone the size of a palm, two of its
> edges cut dead straight and one broken, with a scatter of pale points
> across its face; Rare, so those points are a real cold light and the stone
> is lit by them.

---

## The Sealed Garden · Lv 49–53 · Flora + Sanctus · **9 items**

> ⭐ *Still perfect, still guarded, still not allowed in.* ⚠️ Nothing here
> is ruined and nothing is overgrown — the beds are kept, the rows are
> straight and the fruit is on the trees. ⚠️ Sanctus reads as **gates,
> orchards and vows**, in pale stone and dull silver; never as sun discs or
> haloes.

**Palette:** green leaf, warm amber, pale grey stone, bark brown, one
clean white note on the consecrated things.

### Materials

**Worldroot** — *common · material · Potions & Alchemy t9*
`assets/items/the_sealed_garden/worldroot.png`
> A thick pale root the length of a forearm, knuckled and forked, with fine
> gold hair-roots along it and a clean pale cut at one end still beaded with
> sap.

**Orchard Amber** — *uncommon · material · Jewelry t9*
`assets/items/the_sealed_garden/orchard_amber.png`
> A smooth lump of warm gold amber the size of a thumb with a single small
> green leaf suspended whole inside it; Uncommon, so the gold is one clean
> unlit note.

**Thornpenitent Hide** — *common · material · Tailoring t9*
`assets/items/the_sealed_garden/thornpenitent_hide.png`
> A folded hide the size of a lap blanket, pale grey-green, with fine dark
> thorns emerging through its surface from the inside at regular intervals.

### Consumables

**Worldroot Tonic** — *common · beltable · 53 health a turn for 3 turns*
`assets/items/the_sealed_garden/worldroot_tonic.png`
> A round-bellied stoppered bottle the height of a hand holding a thick
> green-gold liquid in three faintly visible settled layers, a length of
> pale root tied to its neck.

### Equipment

**Thornpenitent Belt** — *common · belt · +8 belt slots · Lv 52*
`assets/items/the_sealed_garden/penitent_belt.png`
> A wide pale grey-green hide belt laid in a loose open curve with a dark
> thorn-wood buckle and **eight empty loops** stitched along it, with fine
> dark thorn points just visible along the inner face.

**Eclipse Opal Signet** — *common · ring · +3 accuracy, 6% crit, +10 crit
damage, +3 dodge · Lv 50*
`assets/items/the_sealed_garden/eclipse_signet.png`
> A broad flat-faced ring standing upright, its face a single eclipse opal
> cut so the light and dark halves meet exactly at the centre line of the
> face; Common, so nothing is emissive — the stone's own halves do the work.

**Orchard Amber Loop** — *common · ring · +25 max HP, +15% healing received,
+1% regrow per turn · Lv 54*
`assets/items/the_sealed_garden/orchard_loop.png`
> A plain pale-gold band standing upright with a round amber cabochon set
> flush, the leaf inside it clearly visible; no glow.

**The Gardener's Loop** — *rare · ring · +25 max HP, +18% healing received,
+2% regrow per turn · Lv 51*
`assets/items/the_sealed_garden/the_gardeners_loop.png`
> A worn gold band with a large amber stone, standing upright, a fine green
> tendril grown around the band and into the setting; Rare, so a soft warm
> light comes from inside the amber and lights the tendril.

**The Season At Once** — *epic · robe top · +60 max HP, +15% healing
received, +3% regrow per turn · Lv 53*
`assets/items/the_sealed_garden/the_season_at_once.png`
> A long vestment on an invisible form, its cloth carrying bud, leaf,
> blossom and fruit at the same time in embroidered bands down its length;
> Epic, so it is visibly *turning* — one band budding as the band beside it
> drops its fruit, endlessly, never settling on a season.

---

## The Collapsed Academy · Lv 50–54 · Arcane · **9 items**

> ⭐ *It was not destroyed — it was continued past the point where building
> makes sense.* ⚠️ **Over-completion, not ruin.** Nothing is broken,
> nothing is rubble, nothing is charred; everything is squared and finished
> to a high standard, and there is simply too much of it. Where a ruin
> would show a jagged edge, show a clean cut that continues.

**Palette:** pale grey-violet planed timber, chalk white, dressed pale
stone, one cold violet note, and the dull bubbled grey of cooled slag.

### Materials

**Aetherwood Log** — *common · material · Woodcarving t9*
`assets/items/the_collapsed_academy/aetherwood_log.png`
> A short squared beam the length of a forearm rather than a round log, pale
> grey-violet, its four sides planed dead flat and its end grain showing
> rings that do not quite close.

**Mana Slag** — *common · material · Metalworking t9*
`assets/items/the_collapsed_academy/mana_slag.png`
> A fist-sized lump of frozen glassy slag, dull grey-violet, bubbled and
> porous on top and flowed smooth underneath where it pooled.

**Aethersteel Ingot** — *common · material · Metalworking t9*
`assets/items/the_collapsed_academy/aethersteel_ingot.png`
> A rectangular ingot the length of a hand, pale grey with a violet sheen
> across its top face and one bevelled corner; matte.

### Equipment

**Aetherwood Quarterstaff** — *common · main hand · +9 dmg/charge, +12
accuracy, 8% crit, +18 crit damage · Lv 50 · 3 sockets*
`assets/items/the_collapsed_academy/aetherwood_quarterstaff.png`
> A two-handed staff as tall as a person, pale grey-violet, the shaft
> squared rather than round for its middle third, with pale metal ferrules
> and a weighted butt; **three** empty round sockets in a row along the
> grip.

**Aetherwood Wand** — *common · main hand · +10 dmg/cast, +5 accuracy, 9%
crit, +16 crit damage · Lv 50 · 3 sockets*
`assets/items/the_collapsed_academy/aetherwood_wand.png`
> A one-handed pale grey-violet wand the length of a forearm, squared in
> section, ending in a flat cut rather than a point; three empty sockets
> along its base.

**Aetherwood Knot** — *common · off hand · +7 accuracy, 7% crit · Lv 50 · 3
sockets*
`assets/items/the_collapsed_academy/aetherwood_knot.png`
> A fist-sized pale grey-violet burl, its whorls unnaturally regular, one
> flat filed facet holding **three** empty sockets.

**Chalkline Signet** — *rare · ring · 8% crit, 18% deflect, 8% amount · Lv
52*
`assets/items/the_collapsed_academy/chalkline_signet.png`
> A heavy pale-grey ring with a broad flat face, standing upright, its face
> incised with three short parallel lines and a fourth that is only
> half-cut; Rare, so a cold violet light sits in the unfinished line and
> lights the three finished ones.

**The Unbuilt Stair** — *epic · main hand · +10 dmg/charge, +13 accuracy, 8%
crit, +16 crit damage · Lv 54 · 3 sockets*
`assets/items/the_collapsed_academy/the_unbuilt_stair.png`
> A two-handed pale grey-violet staff whose upper third steps upward in
> three squared offsets like a flight of stairs; Epic, so a band of cold
> violet light climbs those steps one at a time and, at the top step, simply
> keeps going into nothing before starting again at the bottom.

### The gate

**The Written Third** — *rare · key · opens The Eclipsed Citadel*
`assets/items/the_collapsed_academy/the_written_third.png`
> A wedge-shaped plate of pale stone banded with gold the size of a palm,
> two edges cut dead straight and one broken; Rare, so a warm light comes
> from the *centre* of the plate rather than an edge, and fades outward.

---

## The Reliquary Deep · Lv 52–56 · Sanctus + Umbra · **12 items**

> ⭐⭐ *Two hands worked on this, and the second has not finished.*
> ⚠️ **Made-then-unmade, not light-versus-dark.** The Sanctus objects are
> finished work — dressed stone, gold fittings, folded cream cloth. The
> Umbra objects are what has been done to them since: smoke stain, prised
> fittings, missing gold, a residue where a thing stood. ⚠️ Lamplit
> interior throughout, never open sky and never ice.

**Palette:** pale dressed limestone, soft yellow gold, heavy cream linen,
ceiling-black smoke, one warm red-gold resin note.

### Materials

**Censer Resin** — *common · material · Potions & Alchemy t9*
`assets/items/the_reliquary_deep/censer_resin.png`
> A broken lump of translucent red-gold resin the size of a thumb, glossy
> where it fractured and dull grey with old smoke where it did not.

**Reliquary Gold** — *uncommon · material · Jewelry t9*
`assets/items/the_reliquary_deep/reliquary_gold.png`
> A small twisted length of soft yellow gold the size of a finger, clearly
> prised off a fitting, with a stamped pattern still legible along one
> flattened side; Uncommon, so the gold is one unlit note.

**Unleft Linen** — *common · material · Tailoring t9*
`assets/items/the_reliquary_deep/unleft_linen.png`
> A folded square of heavy cream linen the size of two hands, its creases
> sharp from long folding, one edge worked with a plain dark band.

### Consumables

**Censer Draught** — *common · beltable · restores 295 health*
`assets/items/the_reliquary_deep/censer_draught.png`
> A squat round-shouldered bottle the height of a hand holding a thick
> red-gold liquid, a band of soft stamped gold around its neck and a wax
> seal over the stopper.

### Equipment

**Unleft Linen Hood** — *common · hat · +6 accuracy · Lv 53*
`assets/items/the_reliquary_deep/unleft_hood.png`
> A heavy cream hood laid flat, brim stiffened dead straight, a plain dark
> band worked along the edge, doubled seams at the shoulders.

**Unleft Linen Robe** — *common · robe top · +55 max HP · Lv 53*
`assets/items/the_reliquary_deep/unleft_robe.png`
> A long heavy cream robe on an invisible form, thick and visibly layered,
> doubled seams down both sides, a dark band at the hem.

**Unleft Linen Leggings** — *common · robe bottom · +38 max HP · Lv 53*
`assets/items/the_reliquary_deep/unleft_leggings.png`
> Cream quilted leggings laid flat, the quilting channels running in visible
> parallel lines with a dark band at each ankle.

**Unleft Linen Boots** — *common · boots · +10 max HP, +7 dodge · Lv 53*
`assets/items/the_reliquary_deep/unleft_boots.png`
> A pair of tall cream boots with thick soft soles and dark banding, one
> lifted as though mid-step and barely touching its shadow.

**Unleft Linen Gloves** — *common · gloves · +12 max HP, 18% deflect, 26%
amount · Lv 53*
`assets/items/the_reliquary_deep/unleft_gloves.png`
> Heavy cream gloves, palms outward, the palm panels visibly built up in
> four layers; a cool grey-white line traces each palm.

**Aetherglass Locket** — *common · neck · +45 max HP, +12% shield strength,
+10% healing received · Lv 53*
`assets/items/the_reliquary_deep/aetherglass_locket.png`
> A flat rectangular locket of pale archive glass in a soft gold bezel on a
> fine chain, standing upright, a faint ruled pattern of pale lines in the
> glass, no letters; Common, so nothing is emissive.

**Censer Pendant** — *rare · neck · +20 crit damage, +15% shield strength,
+15% healing received · Lv 54*
`assets/items/the_reliquary_deep/censer_pendant.png`
> A small gold censer worn as a pendant on a short chain, one half of its
> pierced body bright and finely worked and the other half blackened and
> crudely reworked; Rare, so a warm light comes from inside the bright half
> and throws the reworked half into shadow.

**The Unconsecrated** — *epic · boots · +32 max HP, +6 dodge, +10% healing
received · Lv 56*
`assets/items/the_reliquary_deep/the_unconsecrated.png`
> A pair of tall boots of gold-banded dark leather, soles worn through at
> the ball of the foot, standing on bare stone; Epic, so a warm gold light
> runs up the banding from the sole and *stops* at the ankle every time,
> never reaching the top.

---

## The Unwritten Library · Lv 54–58 · Umbra + Arcane · **7 items**

> ⭐ *It is still writing, and it wants you in it.* ⚠️ **Nothing here is
> ruined, burnt, dusty or cobwebbed** — everything is clean, intact and in
> use, and the only thing missing from it is anybody. The Umbra black is an
> **absolute** black: not shadow, not shade, a black with nothing in it.

**Palette:** cream and bone-white vellum, dark grey-violet stone, dull
black ink, absolute black, one cold violet note where the writing happens.

### Materials

**Nightink** — *common · material · Potions & Alchemy t10*
`assets/items/the_unwritten_library/nightink.png`
> A small stoppered pot of dense black liquid the size of a fist, the liquid
> sitting proud of the rim in a meniscus that should have spilled, with one
> cold blue sheen across its surface.

**Colophon Stone** — *uncommon · material · Jewelry t10*
`assets/items/the_unwritten_library/colophon_stone.png`
> A flat polished tablet of dark grey-violet stone the size of a thumb, one
> face incised with a single small mark; Uncommon, so the mark holds one
> clean unlit violet note.

**Blankspine Vellum** — *common · material · Tailoring t10*
`assets/items/the_unwritten_library/blankspine_vellum.png`
> A single sheet of flawless pale vellum the size of a book, lying flat and
> perfectly clean with a hard straight edge, its corners uncurled.

### Consumables

**Nightink Draught** — *common · beltable · restores 320 health*
`assets/items/the_unwritten_library/nightink_draught.png`
> A tall narrow bottle of dark glass the height of a hand holding an opaque
> black liquid, a pale vellum label tied at the neck with nothing written on
> it.

### Equipment

**Blankspine Belt** — *common · belt · +9 belt slots · Lv 56*
`assets/items/the_unwritten_library/blankspine_belt.png`
> A wide pale-cream vellum belt laid in a loose open curve with a plain dark
> buckle and **nine empty loops** stitched along it, the vellum entirely
> unmarked.

**Colophon Signet** — *rare · ring · +3 accuracy, 12% crit, +30 crit damage
· Lv 56*
`assets/items/the_unwritten_library/colophon_signet.png`
> A heavy dark ring with a flat stone face, standing upright, the face cut
> with one small deep mark; Rare, so a hot violet point burns in that mark
> and lights the whole face.

**The Open Colophon** — *epic · off hand · +12 dmg/cast, +9 accuracy, 8%
crit · Lv 58*
`assets/items/the_unwritten_library/the_open_colophon.png`
> A thick codex bound in pale vellum, the size of two hands, held open in
> mid-air at its final page; Epic, so a thin line of cold violet light is
> drawing itself across that otherwise blank page like the stroke of a pen
> with no letters in it, reaching the margin and continuing on the next
> line without ever filling the page.

---

## The Eclipsed Citadel · Lv 58–60 · all twelve · **7 items**

> ⭐ *The last thing in the way.* ⚠️ **Not a place — an obstruction.** Every
> object reads as something **between** the viewer and something else: a
> shape that occludes rather than occupies. Nothing is ruined and nothing is
> decorative; this is the endgame set and it is still doing its job.

**Palette:** black stone and black iron, cold white edge light, and one
warm gold note reserved for the corona.

### Materials

**Eclipse Iron** — *uncommon · material · Jewelry t10*
`assets/items/the_eclipsed_citadel/eclipse_iron.png`
> A fist-sized block of dense black metal with one broken face, so matte it
> reads as a silhouette, with a single hairline of cold white along the
> break; Uncommon, so that hairline is the only note.

**Corona Pearl** — *uncommon · material · Jewelry t10*
`assets/items/the_eclipsed_citadel/corona_pearl.png`
> A large pale pearl the size of a plum resting on a flat face, its surface
> a soft cream-white with a faint ring of warm gold iridescence around its
> widest circumference; Uncommon, so that ring is one unlit note.

### Equipment

**Corona Pearl Torc** — *common · neck · +3 accuracy, 5% crit, +45 max HP ·
Lv 58*
`assets/items/the_eclipsed_citadel/corona_torc.png`
> An open circular neck torc of dark metal with a pale pearl finial at each
> of its two open ends, standing upright; Common, so nothing is emissive —
> the pearls carry their own soft colour.

**Eclipse Iron Ring** — *common · ring · +7 dmg/cast, 6% crit, +12 crit
damage · Lv 60*
`assets/items/the_eclipsed_citadel/eclipse_ring.png`
> A plain heavy band of matte black eclipse iron standing upright, utterly
> unornamented, its silhouette perfectly circular and its surface giving
> back no light at all except a single thin rim highlight.

**The Eclipsed Band** — *rare · ring · 8% crit, +60 max HP, +6 dodge · Lv
58*
`assets/items/the_eclipsed_citadel/the_eclipsed_band.png`
> A broad black band standing upright with a narrow slot cut clean through
> its front, so the ring is a circle with a gap in its face; Rare, so a hard
> white light shows *through* that slot from behind and lights nothing else.

**The Last Thing in the Way** — *epic · gloves · +14 dmg/cast, +6 accuracy,
10% crit, +10 crit damage · Lv 60*
`assets/items/the_eclipsed_citadel/the_last_thing_in_the_way.png`
> A pair of heavy black gauntlets, palms outward and fingers spread in a
> flat halt, the plate scored with old impact marks; Epic, so a hard white
> light builds in both palms, reaching full brightness, and goes out — over
> and over, like something being refused and refusing again.

**The Corona** — *epic · hat · +70 max HP, 16% deflect, 14% amount, +12%
shield strength · Lv 60*
`assets/items/the_eclipsed_citadel/the_corona.png`
> A low coronet of dark metal set with a single large pale pearl at the
> brow, worn as a band; Epic, so a full ring of warm gold light stands off
> the coronet's whole circumference — a corona around a dark centre — and it
> *breathes*, widening and narrowing without ever closing.

---

## ✅ Written — all 265 items

Every item in `ItemCatalogue` has an icon description here. The **Primal
quarter (52)**, the **Kinetic quarter (58)**, the **Celestial quarter (76)**
and the **Ethereal quarter plus The Eclipsed Citadel (79)** are all written.

📝 **The Celestial and Ethereal icon lines came out of the contracts, not out
of this file.** Each zone lane wrote its items' icon briefs into
`docs/contracts/CELESTIAL_CONTRACT.md` §4 and `ETHEREAL_CONTRACT.md` §4,
beside the catalogue table that defines them, and they were folded in here
verbatim on 2026-09-22. ⚠️ **This file is the one the generator reads.** A
contract edited after the fold changes nothing on disk, so an icon reworded
there has to be carried across by hand — or, better, reworded here and left
alone there.

| Quarter | Zones | Items | Icon descriptions | Icons (PNG) |
|---|---|---|---|---|
| **Primal** 1–14 | 5 | 52 | ✅ | ⬜ |
| Kinetic 15–29 | 6 | 58 | ✅ | ⬜ |
| Celestial 30–47 | 7 | 76 | ✅ | ⬜ |
| Ethereal 45–58 | 7 | 72 | ✅ | ⬜ |
| The Eclipsed Citadel 58–60 | 1 | 7 | ✅ | ⬜ |

⚠️ **No icon PNG exists for any zone yet**, and `assets/items/<zone>/` is
declared in pubspec only for the zones that have one. Every inventory tile in
the game falls back to its wrapped name until the art lands; that is the
whole reason `test/item_icon_test.dart` exists.

⭐ **The Primal quarter is still the one that matters first** — it is the
player's first impression, and it is the quarter whose icons should be
generated first.

### Adding an item

📝 The count in each zone heading above must equal that zone's list in
`lib/game/items/catalogue/`. `test/item_icon_test.dart` asserts the catalogue
total is **265**, so an item added without an entry here fails the suite with
a pointer to this file. ⚠️ Add the entry in the zone's own section, under the
heading its kind belongs to, and give it a `assets/items/<zone>/<id>.png`
line — the path, not the name, is what ties the description to the item.
