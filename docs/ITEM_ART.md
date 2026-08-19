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
the shared preamble below is quoted verbatim into all 52 icon prompts. Reword
the prose freely; change those shapes and the tool silently finds fewer icons,
which `test/item_icon_test.dart` and `tool/test_artgen.py` both fail on.

Each entry is written so it can be pasted straight into an image generator
**after the style preamble below**, without editing. They deliberately state
**form, real-world size, material, colour and silhouette**, because those are
what a generator gets wrong when left to guess.

### ⭐ The shared style preamble — prepend this to every prompt

> A single game item icon. One object only, centred, filling about 80% of a
> square frame, seen from a three-quarter front view slightly above. Plain flat
> near-black background — no scene, no table, no floor, no props, no hands, no
> packaging, no text, no watermark, no border and no frame. Even soft lighting
> from the upper left with one dim fill from the right; a small soft contact
> shadow directly beneath the object and nothing else. Hand-painted fantasy
> game-asset style, flat limited palette, clean readable **silhouette** that
> still reads as this object when shrunk to 40 pixels. Muted natural colour with
> one clear accent hue; no gloss, no lens flare, no glow spilling onto the
> background.

⚠️ **Every word of that is load-bearing.** "One object" stops the generator
returning a display case of variants; "plain near-black background" is what the
pipeline's square cover-crop assumes and what lets an icon sit on the game's own
dark panels; "no border and no frame" matters because **the UI already draws
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

⚠️ Nothing in the Primal quarter is Mythic or Legendary, so those two rungs of
§8's ladder have no convention yet — that is a decision waiting, not an omission.

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

**Forager's Ration** — *common · consumable · restores 25% health*
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

**Sapwort Draught** — *common · beltable · restores 20% health*
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

**Brookmint Tonic** — *common · beltable · 9% health per turn for 3 turns*
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

## ⚠️ Still to describe — the other three quarters

Only the **Primal quarter (52 items)** is written, matching BESTIARY_ART's
coverage exactly.

| Quarter | Zones | Items | Status |
|---|---|---|---|
| **Primal** 1–14 | 5 | 52 | ✅ described |
| Kinetic 15–29 | 6 | ❓ | ⬜ no catalogue yet |
| Celestial 30–47 | 7 | ❓ | ⬜ no catalogue yet |
| Ethereal 45–60 | 7 | ❓ | ⬜ no catalogue yet |

⭐ **The Primal quarter is the one that matters first** — it is the only content
built, and it is the player's first impression. ⚠️ Unlike the bestiary, the
later quarters have **no catalogue at all** yet, so there is nothing to describe
rather than a described-later backlog: ITEMS §9b.8 covers Q1 only.

### Adding an item

📝 The count in each zone heading above must equal that zone's list in
`lib/game/items/catalogue/`. `test/item_icon_test.dart` asserts the catalogue
total is 52, so an item added without an entry here fails the suite with a
pointer to this file.
