# Bestiary — physical descriptions

**What this is for:** one concrete, visual description per creature, written to
be handed to an image generator. Design lives in
[ENEMIES_DESIGN.md](ENEMIES_DESIGN.md); this file only describes what a thing
*looks like*.

⚠️ **The problem this exists to fix.** Every enemy currently renders with the
**mage sprite** — robes, hat, the lot — because `EnemyEncounter` builds an
`AiPersona` and personas wear `MageApparel`. A Listening Fawn is a deer made of
roots, and it is drawn as a wizard in a green cloak. ⭐ **Almost nothing in this
bestiary is a mage**, and the art has to stop saying otherwise.

---

## How to use these

⚠️ **This file is a live prompt source, and its formatting is load-bearing.**
`tool/artgen.py` parses it on every run — an entry is `**Name** — *rank ·
archetype · element*` on one line followed by a blockquote, a backdrop is an
`### Arena backdrop` heading with a `` `assets/backgrounds/<zone>.png` ``
filename line and one blockquote, and the house-style paragraph below is
quoted verbatim into all 286 creature prompts. Reword the prose freely; change
those shapes and the tool silently finds fewer creatures, which
`test/creature_art_test.dart` and `tool/test_artgen.py` both fail on.

Each entry is written so it can be pasted straight into an image generator
without editing. They deliberately state **form, scale, material, colour and
posture**, because those are what a generator gets wrong when left to guess.

⭐ **A house style, so the set looks like one bestiary:** a naturalist's field
plate — creature isolated on a plain flat pure-white background (nothing else
behind it: no ground texture, no gradient, no vignette — white keys out
cleanly in the cutout step), full body, in profile or three-quarter view and
**always facing the RIGHT edge of the image**: the head points right, the eyes
look right, the feet would carry it rightward off the picture. Never facing
the viewer head-on, never facing left, never looking back over its shoulder.
Even light, no scenery, no action pose, no text. That framing
also matches the game's own voice: these are observations, not portraits.
⚠️ **Right-facing is a hard technical requirement, not taste**: the game
mirrors every enemy sprite at render time so it faces the hero across the
arena — a source drawn facing left gets flipped into facing AWAY from the
fight. One canonical direction in, one correct fight out.

⚠️ **No in-game bitmaps.** Every visual in the game is a `CustomPainter`
(README §4). Generated images are **concept reference** for painter recipes —
if that ever changes, it is a real decision, not a detail.

⚠️ **Scale is stated in every entry** because it is the single thing a
generator most reliably ignores, and a knee-high sprite drawn at bear size
makes a level-1 zone read as a level-40 one.

### Backdrops

⭐ **Each zone below ends with an `### Arena backdrop` entry**, written to a
different brief from the creatures because it is a different job: a creature is
a field plate on plain ground, a backdrop is a **stage**. Same rule about lore,
though — nothing in one that a renderer cannot draw.

⚠️ **The duel screen is the composition the description has to survive.** The
arena is landscape-only and it puts the two combatants at **24% and 76% of the
width**, standing on a ground line **just past mid-height**. The middle of the
frame belongs to the interface — turn chip at the top edge, cast banner at 20%
height, the crit word at 30% — the top-left and top-right corners are covered
by the two nameplates, and the action bar sits over the bottom edge. So every
entry below asks for the same shape: **a level ground line just past
mid-height, interest in the left and right thirds, an open and quiet centre,
deep shadow in the bottom fifth, and nothing tall, bright or busy centre-frame**
that a sprite would have to fight.

⭐ **Generate at 1920×1080 (16:9)**, then
`python3 tool/pixelate.py --zone <zone id> --mode background`, which
cover-crops to 384×216, darkens 42% and desaturates 45%; `ArenaBackdrop` lays a
further dark scrim over it in-game. ⚠️ So paint these **muted and low-contrast
but still legible** — a source already pushed to black arrives as mud. A
backdrop must LOSE to the sprites, and three separate steps are already making
sure of it.

📝 **Backdrops ship as real bundled PNGs**, at `assets/backgrounds/<zone id>.png`
— one file per zone, no `manifest.json` (the reasoning is on `backdropFor` in
`lib/ui/creature_art.dart`). ⚠️ The "concept reference only" note above predates
`assets/creatures/` and `assets/backgrounds/`; both are shipped assets now.
Everything that is *not* a creature or a backdrop is still a `CustomPainter`.

---

## Whispering Woods · Lv 1–5 · Flora

> ⭐ *The wood is one creature, and you are standing on it.* Nothing here is an
> animal that lives in a forest — everything is an **extension of one
> organism**. ⚠️ Reflect that: these should look **grown**, not born. Bark,
> grain, root and moss instead of fur and hide, and joints that bend where a
> branch would rather than where a bone would.

### Commons

**Listening Fawn** — *common · Drudge · Flora*
> A deer-shaped creature the size of a large dog, woven from pale root and
> birch bark rather than flesh. Its legs are bundled rootlets; its joints bend
> like green wood. It has **no eyes and no mouth** — the head is a smooth knot
> of grain, tilted downward, with two long leaf-shaped ears angled at the
> ground. Moss over the shoulders. Standing still, head lowered, listening.

**Thornback Sprite** — *common · Skirmisher · Flora*
> A knee-high humanoid of tangled green briar, wiry and hunched, with long thin
> arms. A ridge of black thorns runs from the crown of its head down its spine.
> Small, dark, wet-looking eyes set deep in a face of woven stems. Caught
> mid-stride, low to the ground, as if about to bolt sideways.

**Sporecap Shambler** — *common · Blighter · Flora*
> A slumped, roughly man-shaped mass of decaying wood and leaf litter, waist to
> chest height, walking on knuckles. Its whole back and shoulders are crowded
> with **pale grey-brown mushroom caps** of varying size, the largest split and
> leaking a fine dust. No visible face. Damp, dark, crumbling at the edges.

**Bindweed Creeper** — *common · **Siphon** · Flora*
> A writhing knot of pale green vine about the size of a curled dog, moving as
> a single mass with no head. White trumpet-shaped flowers open along its
> length. ⭐ The vine tips are **fine, pink and rootlike**, and they end in
> small sucking mouths — the one detail that must read clearly, because it is
> what the creature does.

**Rootknuckle** — *common · Bruiser · Flora*
> A single enormous fist of braided tree root, roughly the size of a cow,
> punched up out of the soil and balanced on the wrist. Wet black earth still
> clinging in the crevices. Four thick knuckle-ridges of hard grey bark. No
> face, no eyes — it is a limb, not a body, and there is nothing above it.

### Mini-bosses

**Elderroot** — *mini · Champion · Flora*
> A broad, low creature the size of a bull, built from one ancient root system
> lifted clear of the ground and walking on six thick tapering legs. Deeply
> fissured grey bark. Where a head would be there is a dense woven crown of
> smaller roots, and inside it a single dull amber knot like a clouded eye.

**Mother Spore** — *mini · Redoubt · Flora*
> A vast pale fungal dome, twice the height of a person and wider than it is
> tall, sitting flush against the forest floor. Its surface is soft, slightly
> luminous, and rippling like a lung. A skirt of thick white gills underneath.
> Small mushroom growths cluster around its base like offspring.

**Hollow Stag** — *mini · Executioner · Flora*
> A full-grown stag standing tall as a horse, its body a hollow shell of
> silver-grey bark with the whole ribcage open and empty — you can see the
> forest through it. Its antlers are living branches still in leaf. It moves
> with the poise of a real deer, which is worse.

**The Murmur** — *mini · Hexer · Flora*
> Barely a body: a person-sized column of hanging root-hair and grey-green moss
> suspended just clear of the ground, drifting. Within the tangle, dozens of
> small dark hollows like open mouths at different heights. ⭐ It should look
> like **something you would only notice because it made a sound**.

### Bosses

**Heartwood** — *boss · Juggernaut · Flora*
> An enormous ancient tree that has pulled itself half out of the earth,
> four storeys tall, walking on a splayed mass of root. Its trunk is split
> vertically into a deep vertical cleft lined with pale, wet, living wood. The
> canopy is full and healthy. Everything below the canopy is a wound.

**The Standing Green** — *boss · Aspect · Flora*
> A human figure, slightly too tall and slightly too thin, grown entirely from
> living plants — the proportions right, the posture right, the stillness
> wrong. Face smooth and featureless, grass and small white flowers where hair
> would be. ⭐ **Unsettling because it is nearly correct**, not because it is
> monstrous. Arms at its sides. Standing in profile, body and smooth face
> turned toward the right edge of the image.

### Arena backdrop

`assets/backgrounds/whispering_woods.png` — *16:9 · Flora palette*
> Wide 16:9 landscape painting of a forest floor seen side-on at standing eye
> level, environment only — no creatures, no people, no text. A well-walked
> earth path runs level across the frame just past mid-height: packed brown
> soil with pale tree roots crossing it and worn smooth by use. Below the path,
> the near bank of leaf litter and fern falls into deep shadow across the
> bottom fifth of the frame. Old birch and oak trunks stand at the far left and
> far right edges only, cut off by the frame, their bark grey-white and green
> with moss; the whole centre of the frame is **open woodland floor and empty
> air**, with no trunk, branch, rock or light source in it. Behind the path,
> the wood recedes into soft grey-green haze at ground level. The canopy is
> present only as dark foliage along the top edge, letting scattered pale
> patches of dappled sun fall on the middle distance. **Flora palette**, the
> same as the creatures above: birch grey-white, root pale, moss and bracken
> green, wet black earth. Muted, low-contrast, warm but quiet, and everything
> holding still.

---

## Glimmerbrook · Lv 3–8 · Aqua

> ⭐ *Everything here is holding still, and that is the wrong thing for water to
> do.* ⚠️ Nothing in this zone should look **fast**. Suspended, poised,
> unmoving. Cold light, pale stone, water that behaves like glass.

### Commons

**Brook Naiad** — *common · Adept · Aqua*
> A slender human-shaped figure the height of a child, made of clear moving
> water held in the shape of a body, with pale river stones suspended inside it
> where organs would be. Its outline is sharp, not misty. Standing upright in
> the shallows, arms loose, perfectly still.

**Shiverfish Shoal** — *common · Lasher · Aqua*
> A tight ball of about forty small silver fish, hanging together in the water
> as one creature roughly the size of a beach ball. Each fish is thin and
> pale-eyed. The shoal holds its shape too rigidly to be natural, and casts a
> single shadow.

**Glassfleck Wisp** — *common · Glasswing · Aqua*
> A drifting shard of light about the size of a cat, made of thin overlapping
> plates of clear ice and broken reflection, throwing a scatter of small
> rainbows. Almost transparent. ⭐ It should look like **it would shatter if
> touched**, and like it is made of the light off the water rather than water.

**Siltback Crawler** — *common · Sentinel · Aqua*
> A broad flat armoured creature the size of a large dog, low to the riverbed,
> built like a crayfish crossed with a boulder. Its back is a single thick
> plate of grey silt-crusted shell with freshwater weed growing on it. Short
> heavy legs. Two small eyes on stalks, close together.

**Chill Eel** — *common · Skirmisher · Aqua*
> A long pale eel about the length of a person's arm, bone-white and almost
> translucent, with a fine dark line of spine visible through the skin. Frost
> forms on the water immediately around it. Slender head, small clear teeth.
> Held straight, poised rather than coiled.

### Mini-bosses

**The Held Breath** — *mini · Redoubt · Aqua*
> A single enormous bubble of air, taller than a person, held underwater and
> refusing to rise. Its surface is a taut silver skin. Inside, dimly, the
> silhouette of a curled human figure. ⭐ Read it as **a thing being kept**,
> not a thing swimming.

**Weirkeeper** — *mini · Champion · Aqua*
> A tall figure of wet dark timber and river stone, built like a man but
> assembled from the beams of an old weir, water pouring continuously through
> the gaps in its chest. Moss and rope. It carries nothing and needs nothing.

**Pale Coil** — *mini · Executioner · Aqua*
> A great white eel as thick as a person's waist and three times their length,
> coiled once, head raised. Blind milky eyes. Its jaw is disproportionately
> large and lined with fine backward-curving teeth. The water around it is
> visibly clearer than the rest.

**Frostgleam Naiad** — *mini · Hexer · Aqua*
> A tall, elegant water-figure like a Brook Naiad but adult-sized and part
> frozen — ice crystals blooming across her shoulders, forearms and brow while
> the rest still flows. Suspended within her are dozens of small pale stones.
> Composed, upright, unhurried.

### Bosses

**Stillwater** — *boss · Aspect · Aqua*
> Not a creature but a body of water risen into a standing column three storeys
> high and perfectly smooth, mirror-flat on every surface. It reflects the
> viewer. Nothing inside it moves. ⭐ **No face, no limbs, no features at
> all** — the horror is that it is simply water that has decided to stand up.

**The Cold Below** — *boss · Juggernaut · Aqua*
> An immense dark shape seen through deep water — broad, flat, slow, wider than
> a house — resolving into a vast pale underside ringed with small lights. Only
> partly visible; the rest disappears into black water. It has been down there
> the whole time.

### Arena backdrop

`assets/backgrounds/glimmerbrook.png` — *16:9 · Aqua palette*
> Wide 16:9 landscape painting of a shallow spring-fed brook seen side-on at
> standing eye level, environment only — no creatures, no people, no fish, no
> text. A level shelf of pale grey river gravel and flat wet stones runs
> straight across the frame just past mid-height, wide enough to stand on and
> broken only at the far edges. Below it the near shallows fall into dark
> green-black water in deep shadow across the bottom fifth. At the far left and
> far right edges, low rounded boulders and pale reed clumps no higher than a
> person's waist, cropped by the frame. The whole centre of the frame is
> **flat, unbroken, mirror-still water** running back to a low far bank — no
> rock standing out of it, no waterfall, no bridge, nothing tall. Cold overcast
> light with no visible sun; the water throws it back in small hard broken
> flecks of white rather than glare. **Aqua palette**, matching the creatures
> above: bone-white stone, wet slate grey, glass blue-green, deep still black
> at depth. Muted, low-contrast, and colder than the season.

---

## Cinderpeak Foothills · Lv 6–11 · Pyro

> ⭐ *The mountain is breathing, and it is breathing faster.* ⚠️ **Pressure, not
> eruption.** Heat should read as internal — glowing through cracks, seams and
> vents — rather than as open flame.

### Commons

**Ashjaw Brute** — *common · Bruiser · Pyro*
> A heavy quadruped the size of an ox, hide caked in grey volcanic ash and
> cracked like drying mud, with dull orange light showing in the cracks. Broad
> blunt head, heavy underslung jaw, small deep-set eyes. Squat legs. Standing
> square, head low.

**Flint Skink** — *common · Skirmisher · Pyro*
> A lizard about the length of a forearm, its skin a dark glassy grey like
> knapped flint, with sharp faceted scales. Bright orange seams glow between
> the scales along its flanks. Long tail, splayed toes, poised mid-scurry on
> hot rock.

**Cinder Moth** — *common · Glasswing · Pyro*
> A moth with a wingspan as wide as two hands, wings a fine translucent ash-grey
> shot through with glowing ember veins that brighten toward the body. Thick
> soft thorax dusted in grey. ⭐ Fragile and beautiful; it should look **one
> touch from disintegrating**.

**Slagshell Tortoise** — *common · Sentinel · Pyro*
> A tortoise the size of a wheelbarrow whose shell is a single lump of cooled
> black lava, rough, pitted and cracked, with dull red heat still in the
> fissures. Thick grey legs, wrinkled neck, ancient patient face. Drawn in
> slightly, waiting.

**Ventworm** — *common · Blighter · Pyro*
> A thick segmented worm as long as a person, dull red-brown, emerging halfway
> from a fissure in the rock. Its blunt front end opens into a circular
> ring of small plates rather than a mouth. Pale sulphurous vapour pours
> steadily from it.

### Mini-bosses

**Char-Tusk** — *mini · Executioner · Pyro*
> An enormous boar, shoulder-high to a person, its bristled hide burnt black
> and split with glowing seams. Two great upward tusks of cracked grey stone,
> the tips still hot. Small furious eyes. Head lowered, one foreleg forward.

**Vent Warden** — *mini · Redoubt · Pyro*
> A broad squat figure of fused slag and black basalt, twice as wide as a
> person and only slightly taller, planted over a fissure with its legs sunk
> into the rock. Its whole chest is a grated vent glowing deep orange. No
> visible head — the shoulders simply end.

**The Emberqueen** — *mini · Hexer · Pyro*
> A moth the size of a large dog, wings a deep smouldering red-orange with
> intricate dark scorch patterning, held wide. Her body is thick and furred in
> soft grey ash. Long feathered antennae. Regal, still, wings displayed rather
> than beating.

**Slagheart** — *mini · Champion · Pyro*
> A humanoid figure of cooled black lava a head taller than a person, cracked
> throughout, with a single fist-sized cavity in the chest holding a fiercely
> glowing molten core. Heavy asymmetric arms. Standing upright, balanced,
> deliberate.

### Bosses

**Flintmaw** — *boss · Tyrant · Pyro*
> A long low predator the size of a horse, built like a great cat rendered in
> fractured volcanic glass, every plane sharp and dark and faintly reflective.
> Molten orange runs in the seams between the plates. Its jaw is
> disproportionately long. Watchful, poised, intelligent.

**The Breathing Stone** — *boss · Juggernaut · Pyro*
> A colossal boulder-bodied creature four storeys tall, hunched, made of the
> mountainside itself — grey rock, ash, scree. Its back and sides are split
> with enormous glowing fissures that **widen and narrow as it breathes**.
> Vapour rises from its shoulders. Barely distinguishable from the slope.

### Arena backdrop

`assets/backgrounds/cinderpeak_foothills.png` — *16:9 · Pyro palette*
> Wide 16:9 landscape painting of a volcanic foothill bench seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level terrace of grey volcanic grit and scree runs straight across the frame
> just past mid-height, the loose ground scuffed and slipping at its edge.
> Below it the near slope of coarse dark cinder drops into deep shadow across
> the bottom fifth. At the far left and far right edges, broken outcrops of
> black basalt no higher than a person's chest, cropped by the frame, with dull
> orange heat showing in the fissures between their plates and thin pale
> sulphur vapour leaking from the ground beside them. The centre of the frame
> is **bare open grit**, running back to a low grey ridge line and a flat band
> of ash haze — **the mountain itself is out of shot above the top edge**, so
> nothing rises centre-frame and nothing glows there. Flat overcast daylight,
> greyed by suspended ash; all heat is internal, in cracks and seams, never
> open flame. **Pyro palette**, matching the creatures above: ash grey, black
> basalt, knapped-flint blue-grey, dull ember orange in the cracks only. Muted,
> low-contrast, and warm through the soles.

---

## Thornmire · Lv 8–13 · Flora + Aqua

> ⭐ *The green has beaten the water, and is drinking it.* ⚠️ This is **not**
> Flora creatures next to Aqua ones — everything here should look like a plant
> that has **absorbed** water and is heavy with it. Swollen, dripping,
> waterlogged. Sickly greens and stagnant browns.

### Commons

**Mirewalker** — *common · Adept · Flora+Aqua*
> A tall, thin, long-limbed humanoid of black waterlogged wood and hanging
> weed, a head taller than a person, wading upright. Bog water runs constantly
> out of its joints. Its head is a narrow featureless bud. Slow, upright,
> deliberate.

**Thirstvine** — *common · **Siphon** · Flora+Aqua*
> A mass of thick, glossy, dark-green vine coiled like a python, as long as a
> person is tall, visibly **swollen and taut** with absorbed water. Pale
> hair-fine feeding roots fringe its underside. ⭐ Where it has fed, the vine
> is fat and bright; where it has not, it is thin and grey.

**Leechcap** — *common · **Siphon** · Flora+Aqua*
> A flat plate-sized mushroom of wet dark red, gill-side down, moving across
> the bog on a fringe of small pale feelers. Its underside is a spiral of soft
> concentric ridges with a small dark opening at the centre. Water beads and
> runs off the cap.

**Bog Lantern** — *common · Glasswing · Flora+Aqua*
> A pale drifting seed-head the size of a person's head, floating at chest
> height, glowing a soft greenish white from within. A crown of fine luminous
> filaments trails beneath it. Almost weightless; the light is warm, and the
> thing itself is not.

**Reedback Lurker** — *common · Sentinel · Flora+Aqua*
> A broad flat armoured creature the size of a small boat lying half submerged,
> its back a thick plate of green-black shell so overgrown with living reeds
> that it reads as a patch of bank. Two small dark eyes at the waterline. Utterly
> still.

### Mini-bosses

**Fenmother** — *mini · Hexer · Flora+Aqua*
> A hunched, heavy, broad-hipped figure of woven reed and black mud, waist-deep
> in water, twice a person's bulk. Her arms are long bundles of dripping root.
> Where her face should be, a dense mat of green weed hangs down. Slow,
> attentive, unhurried.

**The Green Drowning** — *mini · Redoubt · Flora+Aqua*
> A standing wall of matted living weed, algae and root, three times a person's
> height and just as wide, rising sheer out of the bog with water pouring off
> it continuously. No limbs, no face. It simply advances.

**Old Wallow** — *mini · Champion · Flora+Aqua*
> An enormous amphibious beast the size of a cart, low and broad like a
> hippopotamus, its dark wet hide entirely overgrown with moss, ferns and small
> saplings. Wide flat head, small eyes high on the skull, heavy jaw. Half out of
> the water.

**Wickerdrowned** — *mini · Executioner · Flora+Aqua*
> A gaunt human-shaped figure of woven wet withies, person-height, hollow
> throughout, with black bog water sloshing visibly inside the ribcage. Long
> sharpened arms. Head a simple woven cage tilted slightly to one side.

### Bosses

**The Drinking Grove** — *boss · Aspect · Flora+Aqua*
> A stand of six drowned trees that has grown together into one creature four
> storeys tall, trunks fused, canopy shared. Its roots are lifted clear of the
> water and end in a thicket of **pale swollen feeding tendrils**, all dripping.
> The higher branches are bright, healthy and in full leaf.

**Mirethroat** — *boss · Juggernaut · Flora+Aqua*
> A vast sinkhole of a creature: a broad ring of dark muscular plant matter
> wider than a house lying flush with the bog, opening into a deep funnel lined
> with concentric rows of soft inward-pointing spines. Water spirals slowly into
> it. Almost no part of it stands above the surface.

### Arena backdrop

`assets/backgrounds/thornmire.png` — *16:9 · Flora + Aqua palette*
> Wide 16:9 landscape painting of a drowned bog seen side-on at standing eye
> level, environment only — no creatures, no people, no text. A level causeway
> of matted root, black peat and trodden sedge runs straight across the frame
> just past mid-height, barely above the waterline and soaked through. Below
> it, still brown-black bog water fills the bottom fifth in deep shadow,
> holding a dull broken reflection. At the far left and far right edges,
> drowned tree trunks standing knee-deep in the water, cropped by the frame —
> bark black and waterlogged, trailing curtains of weed and pale hanging
> lichen, no canopy. The centre of the frame is **flat open standing water and
> low mist**, skinned with duckweed, with nothing rising out of it and no light
> source in it. The far bank is a soft grey-green band of reed dissolving into
> haze. Overcast, windless, heavy air; everything sodden and slightly swollen.
> **Flora + Aqua palette**, matching the creatures above: sickly yellow-green
> duckweed and algae, stagnant peat brown, wet black wood, pale grey mist.
> Muted, low-contrast, and green winning everywhere.

---

## Ashfall Vale · Lv 10–14 · Pyro + Flora

> ⭐ *An argument between fire and regrowth, still unresolved.* ⚠️ Every creature
> should show **both at once** — new green pushing through burnt black, or old
> embers surviving inside new growth. Grey ash over bright shoots.

### Commons

**Cinderbloom Husk** — *common · Blighter · Pyro+Flora*
> An upright burnt-black plant stalk the height of a person, hollow and
> brittle, topped with a large charred seed head that continuously sheds fine
> grey ash. Along the blackened stem, small bright green shoots have already
> broken through. Walks on stiff root-legs.

**Ashroot Sapling** — *common · **Siphon** · Pyro+Flora*
> A young tree no taller than a person, bark scorched black on one side and
> healthy pale green on the other, walking on a splay of roots. ⭐ The roots are
> visibly **drawing grey ash upward** into the trunk, and the green side is
> brighter for it.

**Emberseed** — *common · Glasswing · Pyro+Flora*
> A seed pod the size of a melon, husk cracked open in a spiral, hovering just
> above the ground. Inside the husk is a fiercely glowing orange core. Fine
> charred filaments trail behind it. ⭐ It should read as **about to burst**.

**Scorchmoth** — *common · Skirmisher · Pyro+Flora*
> A fast, narrow-winged moth the size of a hand, wings sooty black patterned
> with tiny bright green spots like new leaves. Thin body, long legs, quick.
> Ash falls constantly around it.

**Charwood Walker** — *common · Bruiser · Pyro+Flora*
> A dead standing tree, twice a person's height, entirely charred and stripped
> of bark, walking on two thick root-legs with long branch arms. Deep cracks in
> the trunk still hold dull orange heat. A single green branch grows from one
> shoulder.

### Mini-bosses

**First Green** — *mini · Redoubt · Pyro+Flora*
> A dense thicket of vivid new growth risen into a broad squat figure twice a
> person's width, every surface crowded with bright young leaves and shoots.
> Beneath the green, glimpses of blackened wood. Rooted, planted, immovable.

**Last Ember** — *mini · Executioner · Pyro+Flora*
> A lean, fast, humanoid figure of charcoal and living flame, person-height and
> thin as a whip, trailing sparks. Its whole body is cracked black with white
> heat at the core. ⭐ **Nothing green on it anywhere** — the one creature in
> the zone that is only fire.

**The Grey Stag** — *mini · Champion · Pyro+Flora*
> A tall stag the colour of cold ash, coat dulled to uniform grey, antlers
> charred black at the tips. From the base of the antlers, small green leaves
> are growing. Poised, alert, head raised.

**Kindleroot** — *mini · Hexer · Pyro+Flora*
> A low sprawling root system lifted from the ground into a wide flat creature
> the size of a cart, its many root-tips glowing hot orange like slow matches.
> Wherever it has crossed, small fires and small shoots both. No head.

### Bosses

**The Blackened Crown** — *boss · Tyrant · Pyro+Flora*
> A towering figure of burnt heartwood, four storeys tall, roughly humanoid and
> deliberately regal — broad shouldered, upright, still. Its head is ringed
> with a crown of charred branches burning steadily with white-hot flame.
> Nothing grows on it. ⭐ It looks like it **won**.

**The Rooting** — *boss · Aspect · Pyro+Flora*
> An immense spreading mound of vivid new growth four storeys wide and only two
> tall, low and unstoppable, made of thousands of young saplings, ferns and
> vines grown together. Burnt black timber and old bones are visible **being
> swallowed** inside it. ⭐ It looks like it **is winning**.

### Arena backdrop

`assets/backgrounds/ashfall_vale.png` — *16:9 · Pyro + Flora palette*
> Wide 16:9 landscape painting of a burnt forest valley floor seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level floor of fine grey ash lying deep over burnt ground runs straight
> across the frame just past mid-height, printed with the shapes of fallen
> branches beneath it. Below it the near ash bank and charred deadfall drop
> into deep shadow across the bottom fifth. At the far left and far right
> edges, charred standing trunks stripped of bark and cropped by the frame,
> black and cracked, with **bright new green shoots pushing up around their
> bases** and one or two dull orange embers still alive deep in the splits. The
> centre of the frame is **open ash flat** running back to a low grey burn-scar
> slope and a flat band of smoke haze — nothing standing in it, nothing
> burning. Fine grey ash falls evenly through the whole frame like slow snow,
> soft and thin, never a plume. Flat colourless daylight. **Pyro + Flora
> palette**, matching the creatures above: charcoal black, ash grey over
> everything, one narrow band of vivid new green low in the frame, dull ember
> orange only inside cracks. Muted, low-contrast — a charcoal drawing of a
> valley with a little green left in it.

---

## Old Quarry · Lv 15–19 · Geo

> ⭐ *The hole remembers what filled it.* ⚠️ **Absence, not stone.** Everything
> here should read as negative space gone solid — a shape with tool-marks and
> no explanation, always slightly too regular for anything nature makes.

### Commons

**Quarry Golem** — *common · Bruiser · Geo*
> A hunched bipedal mass of stacked terrace stone the height of a doorway,
> squared grey blocks held together with no visible mortar, every face scored
> with the same parallel tool-marks cut into the quarry walls. Blunt slab
> head, no neck, arms too thick for the body. Standing square, head low.

**Tailings Drudge** — *common · Drudge · Geo*
> A shapeless heap of loose grey spoil about waist high, holding together in a
> rough hunched mound with no clear head or limbs — just a leading edge that
> drags forward, shedding a thin trail of grit. Dull matte stone-dust grey
> throughout. Slow, low, shuffling.

**Chiselback** — *common · Skirmisher · Geo*
> A many-legged creature the size of a large beetle, its back a single flat
> plate scored with parallel chisel-groove ridges, dark quarry-grey with pale
> dust caught in the grooves. Low and flat to the ground, legs splayed, poised
> mid-scuttle.

**Gravelswarm** — *common · Lasher · Geo*
> Hundreds of fist-sized stones holding one rough heap-shape about waist high,
> shifting constantly as individual stones tumble and resettle at the edges.
> Uniform grey scree and gravel, no single silhouette staying still. Low,
> wide, spilling forward.

**Plumbline Sentry** — *common · Sentinel · Geo*
> A flat rectangular slab of dressed grey stone the height of a person, hung
> perfectly vertical on nothing, thin against its height, with a single dark
> groove running dead-straight down its centre like a plumbline's own string.
> Motionless, upright, unnervingly true.

### Mini-bosses

**Obsidian Golem** — *mini · Champion · Geo*
> A humanoid figure of black volcanic glass a head taller than a person,
> sheared clean along every plane, each facet catching the light differently.
> Its two fists are visibly mismatched in size. Standing upright, balanced,
> deliberate.

**Earth Titan** — *mini · Redoubt · Geo*
> A colossal squared mass of stacked terrace stone twice the height of a
> person and half again as wide, tapering slightly at the top like a dressed
> block left standing on end. No visible face — just a flat weathered front.
> Planted, immovable, patient.

**Deadweight** — *mini · Executioner · Geo*
> A long low slab-bodied creature built like a loaded stone sledge, waist-high
> and twice as long as a person, four short thick legs beneath a flat grey
> top. Head-end blunt and squared, low to the ground, gathering itself before
> a short slow drag.

**The Overseer** — *mini · Hexer · Geo*
> A tall thin figure of jointed grey stone, person-height, its limbs and torso
> scored all over with fine measuring lines and notches like a mason's rule.
> No visible eyes — a flat grooved face marked with a single vertical line.
> Upright, still, precise.

### Bosses

**Mountain Heart** — *boss · Juggernaut · Geo*
> A colossal boulder-bodied creature four storeys tall, roughly humanoid and
> deeply hunched, made of the terrace stone itself in massive uneven slabs. A
> wide crater-shaped hollow sits dead centre of its chest, empty and exact.
> Barely distinguishable from the quarry wall behind it.

**The Empty Course** — *boss · Tyrant · Geo*
> A tall gaunt humanoid outline the height of a house wall, its whole body a
> smooth dark hollow — the same negative shape a standing figure would leave
> in packed earth — edged in a thin rim of pale stone dust. No face, no
> visible material filling it, only the edge. Upright, watchful, unnervingly
> patient.

### Arena backdrop

`assets/backgrounds/old_quarry.png` — *16:9 · Geo palette*
> Wide 16:9 landscape painting of a stepped quarry terrace seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level terrace of cut grey stone runs straight across the frame just past
> mid-height, its edge squared and precise where the terrace above it was
> worked away. Below it the near terrace wall drops in a sheer cut face into
> deep shadow across the bottom fifth. At the far left and far right edges,
> broken quarried blocks no higher than a person's chest, cropped by the
> frame, tool-groove marks still visible on their faces. The centre of the
> frame is **bare open terrace floor**, running back to a low grey quarry wall
> and a flat band of stone-dust haze — **the working face itself is out of
> shot above the top edge**, so nothing rises centre-frame. Flat overcast
> daylight, greyed by rock dust. **Geo palette**, matching the creatures
> above: quarry grey, tool-mark black, pale dust white, one narrow band of
> dull red-brown jasper banding low in a cut face. Muted, low-contrast, and
> heavy underfoot.
## Windward Steppe · Lv 19–24 · Aero

> ⭐ *One direction, forever — everything here has stopped resisting.* Not
> violence. **Relentlessness**, which no other Aero zone claims. Nothing
> should look like it is fighting the wind; everything should look like it
> gave up fighting it a long time ago and found a shape that works anyway.

### Commons

**Steppe Harrier** — *common · Skirmisher · Aero*
> A lean bird of prey with long stiff-angled wings, wingspan about a person's
> armspan, banking low over grass rather than flapping. Mottled tan and grey
> plumage, pale belly, sharp hooked bill, small fierce eyes. Caught mid-glide,
> already correcting.

**Leanstone** — *common · Sentinel · Aero*
> A standing stone the height of a person, weathered to a permanent lean, the
> windward face worn smooth pale grey and the leeward face still rough dark
> grey with sharp broken edges. No limbs, no face — a rock, planted, patient.
> ⭐ Should read as **immovable**, the wall the archetype needs.

**Chaff** — *common · Lasher · Aero*
> A loose drifting mass of threshed stalk, seed husk and dry grass, roughly
> the size of a large dog, holding a rough body-shape only because the wind
> keeps refilling it from behind. Pale straw-tan throughout, ragged edges,
> streaming outward on the windward side.

**Tumblehusk** — *common · Drudge · Aero*
> A hollow dried-out husk of a rootless plant, basketball-sized, rolling
> end over end across open ground. Brittle grey-tan, cracked and curled in on
> itself, empty at the centre. ⭐ It should look incapable of doing anything on
> purpose — it is only ever in the way.

**Kitewing** — *common · Glasswing · Aero*
> A kite-shaped flier with a wingspan about as wide as two hands, its wings a
> translucent pale membrane stretched over hair-thin bone, veined faintly tan.
> Small tapering body. ⭐ Fragile and buoyant; it should look **one gust from
> tearing**.

### Mini-bosses

**Old Lean** — *mini · Champion · Aero*
> A person-shaped figure roughly a head taller than a human, built from
> wind-scoured grey rock and knotted dry root fused together, standing at a
> fixed lean like Leanstone but upright and balanced. Deliberate, composed,
> the one thing here that looks like it chose its stance.

**Sky Titan** — *mini · Redoubt · Aero*
> A towering column of visibly moving air, roughly twice human height,
> compressed hard enough at its core to hold a rough humanoid silhouette —
> pale grey-white, semi-translucent, its edges constantly fraying and
> refilling. No fixed face.

**Gale Serpent** — *mini · Executioner · Aero*
> A long sinuous rope of fast-moving air, snake-thick and several body-lengths
> long, coiled tight on itself. Pale grey-white, near-transparent at the
> edges, visible mainly by the dust and grit it carries. Coiled, poised to
> strike.

**Wind Wraith** — *mini · Hexer · Aero*
> A loose, barely-held humanoid shape made of moving air and carried dust,
> person-sized, its edges never quite resolving into a solid outline. Pale
> grey, near-invisible where the dust thins. ⭐ Should look like it is always
> at the edge of the frame, never squarely in it.

### Bosses

**The Unbroken Blow** — *boss · Juggernaut · Aero*
> An enormous, mostly featureless mass of compressed wind roughly three
> storeys tall, its silhouette a huge rounded column rather than any creature
> shape. Pale grey-white throughout, dense and opaque at the core, fraying to
> visible streaming air at its edges. No face, no limbs — a weather system
> given a standing shape.

**Tempest Monarch** — *boss · Tyrant · Aero*
> A tall, upright, roughly humanoid figure of dense compressed wind the height
> of two people, holding a far more solid and defined silhouette than Sky
> Titan or The Unbroken Blow — deliberately composed rather than diffuse.
> Pale grey-white, faint darker banding suggesting layered robes of moving
> air. Still, watchful, unhurried.

### Arena backdrop

`assets/backgrounds/windward_steppe.png` — *16:9 · Aero palette*
> Wide 16:9 landscape painting of a high flat tableland seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level line of scoured pale earth and low wind-flattened tussock grass runs
> straight across the frame just past mid-height, every blade of grass bent
> the same direction. Below it the near ground of packed pale dirt drops into
> deep shadow across the bottom fifth. At the far left and far right edges,
> a single weathered standing stone at each side, no higher than a person's
> chest, cropped by the frame, worn to the same permanent lean as the grass,
> smooth on the windward face. The centre of the frame is **bare open
> tableland**, running back to a low flat horizon and a pale band of wind
> haze — nothing standing tall in it, nothing breaking the sky. Flat
> overcast light with no visible sun, a faint suggestion of motion in the
> haze and the grass but nothing sharp or busy. **Aero palette**, matching
> the creatures above: pale straw tan, scoured grey stone, dust-pale white,
> muted overcast sky-grey. Muted, low-contrast, and constantly, quietly
> moving.
## Stormcliff Coast · Lv 17–22 · Electro

> ⭐ *Everything here is a path to the ground, including you.* The coast is not
> a target, it is a **conductor** — things are charged in passing rather than
> struck. ⚠️ Reflect that: nothing here is on fire or glowing all over. The
> light lives in **cracks, veins and single points**, exactly where a strike
> would enter or leave; everything else stays wet dark rock, sea-bleached hide
> or storm-cloud grey.

### Commons

**Stormcliff Tidecaller** — *common · Adept · Electro*
> A tall, narrow humanoid figure of wet black rock, person-height, standing in
> profile, body and smooth featureless head turned toward the right edge of
> the image. Hairline cracks of white-blue light run down its front like the
> cliff behind it, brightest at the crown and fading toward the feet. No
> visible face — a smooth rounded head canted slightly forward, listening for
> the next flash.

**Fulgurite Crawler** — *common · Sentinel · Electro*
> A knee-high many-legged creature the size of a large dog, its whole
> carapace fused dark glass, branching veins of trapped white light through
> the shell like frozen root growth. Squat and low to the rock, legs drawn in
> tight, holding still, weight settled.

**Sparkwing** — *common · Glasswing · Electro*
> A hand-span winged insect no larger than a fist, translucent wings shot
> through with a single bright line of white-blue light down each vein over a
> dark wet-slate body. Caught mid-flight, angled sharply upward, wings
> blurred with motion.

**Static Shoal** — *common · Lasher · Electro*
> A loose drift of a dozen finger-length eels, pale translucent grey-white,
> moving as one sinuous mass just above the ground. A faint blue-white
> shimmer travels through the whole group at once, low and coiled, about to
> surge forward.

**Groundling** — *common · Skirmisher · Electro*
> A low, quick lizard-like creature about knee height, hide a dull wet slate
> colour, close to the rock. A single bright line of white light runs down
> its spine and earths at the tail. Caught mid-dash, legs splayed, weight
> thrown forward.

### Mini-bosses

**Brinecharge** — *mini · Champion · Electro*
> A man-tall humanoid figure the size of a large ox at the shoulder, built
> from churning white water and standing light, a held wave that never
> finishes breaking. Branching white-blue veins light it from within. Stance
> even and balanced, deliberate.

**The Long Line** — *mini · Redoubt · Electro*
> An unbroken vertical run of white-blue light down a wet rock face, wide as
> a doorway and three times a person's height, no head and no visible front —
> only more light, climbing out of frame at the top. Fused flush to the rock
> it stands on.

**Voltgeist** — *mini · Executioner · Electro*
> A standing, man-sized shape of pure white afterimage, edges soft and
> smeared as if caught mid-blink, held in a low ready crouch. No detail on it
> stays still except a single point of blinding white where a hand would be.

**Storm Shaman** — *mini · Hexer · Electro*
> A stooped, robed figure at the height of a tall person, cloth soaked black,
> arms raised, body turned toward the right edge of the image. A crown of
> small floating sparks orbits its head and never quite goes out.
> Cliff-edge posture, weight forward into the wind.

### Bosses

**Storm Lord** — *boss · Tyrant · Electro*
> A vast standing figure three storeys tall, built entirely of falling and
> rising light in a roughly humanoid silhouette, shoulders broad, stance wide
> and still, body turned toward the right edge of the image. Never the same
> shape twice at the edges, but the core holds steady, watching.

**The Return Stroke** — *boss · Aspect · Electro*
> Not a body at all — a standing column of blinding white-blue light the
> width of a person, four storeys tall, rooted in scorched black rock and
> reaching up out of frame. The only creature in the bestiary with no limbs
> and no head, and no need of either.

### Arena backdrop

`assets/backgrounds/stormcliff_coast.png` — *16:9 · Electro palette*
> Wide 16:9 landscape painting of a storm-lashed sea cliff seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level ledge of wet dark rock runs straight across the frame just past
> mid-height, streaked with long vertical scorch lines. Below it, the cliff
> drops away into deep shadow and spray across the bottom fifth. At the far
> left and far right edges, broken standing rock stacks cropped by the frame,
> black and wet, each threaded with a single hairline vein of white-blue
> light. The centre of the frame is **open grey sky and sea-haze**, with one
> distant, quiet flash low on the horizon — nothing bright or busy close to
> camera. Heavy salt spray drifts through the whole frame like fine rain.
> Overcast, storm-lit, cold. **Electro palette**, matching the creatures
> above: wet black rock, storm-cloud grey, pale sea-foam white, one thread of
> hairline white-blue light per feature. Muted, low-contrast, and grey
> winning everywhere except the thin live seams.
## The Molten Deep · Lv 25–29 · Pyro + Geo

> ⭐ *The stone is a liquid and has been the whole time.* ⚠️ **Geo revealed as
> Pyro's slow state, not two elements sharing a room.** Everything here should
> read as one substance at two temperatures — black crust and orange melt,
> never fire and rock treated as separate things.

### Commons

**Molten Warden** — *common · Sentinel · Pyro+Geo*
> A flat standing plate of black crust the height of a person, hinged at
> nothing and planted upright over the floor it guards, hairline cracks along
> every edge showing dull orange beneath. No limbs, no face. Motionless,
> squared, immovable.

**Slagswimmer** — *common · Adept · Pyro*
> A long low body the length of a person, moving through molten rock the way
> an eel moves through water, glossy black skin over a core that glows faint
> orange through its seams. Low, sinuous, mid-glide.

**Crustwalker** — *common · Bruiser · Geo*
> A boulder-sized mass on four thick stone legs, its underside a shade
> darker orange-black than the weathered grey top, as though it has not
> finished cooling on one side. Squat, heavy, standing square.

**Ember Vent** — *common · Blighter · Pyro*
> A hand-wide split in the ground with no body beyond it, breathing heat in
> slow irregular pulses that show as a dull orange glow deep in the crack.
> Flat to the floor, motionless except for the breathing.

**Cooling Thing** — *common · Glasswing · Geo*
> A slick black slab the size of a large dog, its surface fused to a hard
> obsidian sheen with sharp broken edges along one side. The only thing here
> that has stopped moving. Still, low, angular.

### Mini-bosses

**The Floor** — *mini · Champion · Pyro+Geo*
> Not a creature on the floor but a stretch of the floor itself, roughly
> person-sized where it rises, black crust cracking open on bright orange
> and closing over a step later. Level, spreading, deceptively calm.

**Magma Behemoth** — *mini · Redoubt · Pyro*
> A house-sized mass of slow-moving black crust, its whole hide a tide of
> cracking plates opening on bright orange and sealing shut again. Massive,
> ponderous, advancing at a walk.

**Pyroclast** — *mini · Executioner · Pyro*
> A tight fist-sized knot of molten rock, glowing bright orange-white at its
> core through a thin black skin, more often airborne than not. Compact,
> fast, caught mid-arc.

**Firstmelt** — *mini · Hexer · Pyro+Geo*
> A person-sized patch of ground gone permanently soft, black crust sagging
> inward at the centre with a faint orange glow showing through the give.
> Low, uneven, unsettlingly aware of where it is standing.

### Bosses

**The Slow Stone** — *boss · Juggernaut · Geo*
> A colossal black mass three storeys tall, roughly boulder-shaped, standing
> where everything around it has gone liquid, its surface a matte unlit grey
> unlike anything else in the zone. Planted, immense, entirely still.

**Efreet** — *boss · Tyrant · Pyro*
> A tall humanoid silhouette the height of two people, built from standing
> fire rather than wearing it, bright orange-white at the core fading to a
> thin dark edge at its outline. Upright, composed, unhurried.

### Arena backdrop

`assets/backgrounds/the_molten_deep.png` — *16:9 · Pyro palette*
> Wide 16:9 landscape painting of a deep volcanic gallery seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level shelf of black cooled crust runs straight across the frame just past
> mid-height, hairline cracks showing dull orange beneath. Below it, the
> shelf drops into a slow-moving band of molten rock across the bottom
> fifth, its surface glowing orange-red under a black skin that never fully
> closes. At the far left and far right edges, broken standing crust cropped
> by the frame, black and cracked, each threaded with a single vein of
> orange light. The centre of the frame is **open dark gallery air**, running
> back to a low black rock ceiling and a faint red haze — nothing rises
> centre-frame. Heat-shimmer drifts through the whole frame like slow
> distortion. Dim, ember-lit, warm. **Pyro palette**, matching the creatures
> above: black cooled crust, ember orange, dull ash grey, one thread of
> molten light per feature. Muted, low-contrast, and dark winning everywhere
> except the live seams.

## Thunderspire Peaks · Lv 23–28 · Electro + Aero

> ⭐ *You are inside the storm, and it is building to something.* The fusion
> is a storm as a **single accelerating event** rather than weather —
> Stormcliff is where the lightning goes, this is *when* it comes. ⚠️ Nothing
> here should read as already discharged; everything is charging, and the
> light should look like it is gathering rather than spent.

### Commons

**Stormcrest Roc** — *common · Bruiser · Aero*
> A roc the size of a cart, wingspan wider than two people standing arm to
> arm, storm-grey plumage ragged at the wingtips. Caught in profile riding an
> up-draft, body and head turned toward the right edge of the image, wings
> swept back and barely moving.

**Humming Ore** — *common · Sentinel · Electro*
> A standing outcrop of rust-veined rock the height of a person, motionless,
> with fine branching lines of white-blue light threaded through the veins
> like something alive under the surface. No limbs, no face — a rock,
> charged, waiting.

**Flashcount** — *common · Lasher · Electro*
> A loose cluster of finger-length white filaments arcing between points in
> the air, no larger than a dinner plate all together, none of them ever
> resting in the same place twice. Pale white-blue throughout, faint trailing
> afterimages.

**Updraft Wisp** — *common · Glasswing · Aero*
> A hand-span knot of pale down and static riding a visible thermal shimmer,
> weightless and barely holding a shape. Near-white, faintly translucent at
> the edges, caught mid-rise and already fraying.

**Ionwake** — *common · Adept · Electro+Aero*
> A compact, person-height humanoid figure of charged wind and standing
> white-blue light, upright and even-postured, body turned toward the right
> edge of the image. A thin visible wake of disturbed, faintly lit air trails
> behind it.

### Mini-bosses

**Crown Fire** — *mini · Champion · Electro*
> A crackling halo of white-blue light the width of a cartwheel, hovering
> fixed at head height above a bare outcrop, bright enough to cast a shadow.
> No body beneath it — light alone, holding a steady ring shape rather than
> flickering.

**Anvilhead** — *mini · Redoubt · Electro+Aero*
> A squat mass of storm-scarred grey stone, cart-sized, weathered into the
> unmistakable shape of an anvil. Deep pitted scorch marks cover every
> upward-facing surface. Wind visibly piles and curls against its windward
> face and goes nowhere.

**Thunder Roc** — *mini · Executioner · Electro*
> A leaner, faster roc than Stormcrest, wingspan a little narrower, feathers
> dark slate rather than storm-grey and branched through with trapped
> white-blue light down every barb. Caught mid-stoop, wings swept tight,
> angled steeply down and to the right.

**The Shortening** — *mini · Hexer · Electro*
> A low floating knot of white sparks the size of a fist, orbited by a loose,
> barely-there haze of disturbed air, hovering at chest height with nothing
> solid beneath it. ⭐ It should look like **a held breath**, not yet a body.

### Bosses

**The Storm That Passes** — *boss · Juggernaut · Electro+Aero*
> A vast standing front of cloud and charged wind three storeys tall, its
> silhouette a huge rolling mass rather than any creature shape, pale
> grey-white shot through with slow branching veins of white-blue light. No
> face, no limbs — weather with the momentum of a mountain.

**The Strike That Lands** — *boss · Aspect · Electro*
> A brightening column of white-blue light four storeys tall, not yet
> touched down, its lower end trailing off into open air above a bare peak.
> Denser and more solid at the top than at the base, gathering rather than
> discharged. The only creature in the bestiary caught **before** it
> arrives.

### Arena backdrop

`assets/backgrounds/thunderspire_peaks.png` — *16:9 · Electro palette*
> Wide 16:9 landscape painting of a high storm-wrapped mountain summit seen
> side-on at standing eye level, environment only — no creatures, no people,
> no text. A level line of bare wind-scoured rock runs straight across the
> frame just past mid-height, thin rust-red ore veins showing through the
> stone. Below it, the peak drops into deep shadow and cloud across the
> bottom fifth. At the far left and far right edges, broken storm-worn rock
> spires cropped by the frame, dark grey, each threaded with a single
> hairline vein of white-blue light. The centre of the frame is **a dense,
> low, roiling cloud bank**, lit from within at one point, low and quiet —
> nothing bright or busy close to camera, the light gathering rather than
> discharged. Heavy blown mist drifts through the whole frame. Overcast,
> charged, cold. **Electro palette**, matching the creatures above: rust-red
> stone, storm-cloud grey, pale sea-foam white, one thread of hairline
> white-blue light per feature, gathering rather than spent. Muted,
> low-contrast, and the whole frame reads as **held**, not yet released.

---

## Frostfell Pass · Lv 21–26 · Aqua + Aero

> ⭐ *Everything that moves through here gets held.* The fusion is **breath
> frozen mid-air** — Aero stopped by Aqua. ⚠️ This zone assigns its element
> per creature, not "both" by default: some things here are pure held-breath
> (Aero), some are pure held-ground (Aqua), and only the ones the roster
> names both are visibly frost AND wind at once. White, rime-grey and
> breath-pale throughout; nothing here is wet, only stopped.

### Commons

**Rime Stalker** — *common · Adept · Aqua+Aero*
> A tall, frost-whitened humanoid figure, a head taller than a person,
> standing in profile, body and head turned toward the right edge of the
> image. Rime crusts every fold of it like clothing gone to ice, and a single
> held plume of breath hangs frozen in front of its face, a beat behind where
> it should already have dispersed. Walking, unhurried, even-paced.

**Hoarbound** — *common · Sentinel · Aqua*
> A heavy quadruped the size of a small ox, hide entirely bound in thick
> white rime built up in overlapping layers like tree rings, thicker at the
> shoulders than anywhere else. Blunt frost-crusted head lowered. Standing
> completely still, weight settled, facing right.

**Breathfrost** — *common · Glasswing · Aero*
> A person-sized cloud of visibly held breath given a rough winged shape,
> pale translucent white shot through with faint blue at the core, thinning
> to nothing at the edges. No solid body at all. Caught rising, angled
> upward and to the right, mid-beat.

**Cairnwight** — *common · Blighter · Aqua+Aero*
> A standing pile of frost-rimed trail-stones roughly person-height, just
> enough shape to read as a figure — a rounded stack for a head, flatter
> slabs for shoulders. Pale grey stone crusted white on every windward
> face. Motionless, upright, facing right.

**Snowblind Wanderer** — *common · Drudge · Aero*
> A muffled humanoid shape, person-sized, wrapped in layers of pale
> wind-scoured cloth until no features show at all, walking in a shallow
> curve rather than a straight line. Dull white-grey throughout, nothing
> bright on it anywhere. Shuffling, off-balance, facing right.

### Mini-bosses

**The Last Cairn** — *mini · Champion · Aqua+Aero*
> A trail-cairn grown to twice a person's height, frost-bound stones stacked
> well past where hands could have placed them, the topmost stones still
> visibly settling. Pale grey stone, heavy white rime in every gap. Standing,
> balanced, facing right, entirely still.

**Hoarking** — *mini · Redoubt · Aqua*
> A crowned, seated mass of packed white rime the size of a loaded cart,
> broader than it is tall, set into a drift that has stopped moving around
> it rather than the reverse. Dense, unbroken white, faint blue in the deep
> creases. Facing right, immovable.

**Coldsnap** — *mini · Executioner · Aqua*
> A lean, sharp-shouldered humanoid figure of clear blue-white ice, person
> height, edges faceted rather than smooth, built for closing distance fast.
> Caught mid-stride, weight thrown forward and right, one arm already drawn
> back.

**The Certain Road** — *mini · Hexer · Aqua+Aero*
> A low, worn track of pale stone made faintly visible only by the frost
> outlining its edges, given just enough height and shape at one end to read
> as a robed figure bent over it, person-height at the shoulder. Muted white
> and stone-grey. Stooped, attentive, facing right.

### Bosses

**The White Corridor** — *boss · Juggernaut · Aqua+Aero*
> A wall of packed white filling the whole width of the frame from waist
> height up, four storeys tall, its face a mass of compacted rime-stone and
> frozen breath with no single silhouette — only more of it, climbing out of
> frame at the top. Advancing slowly, facing right, unstoppable.

**The Road Under** — *boss · Aspect · Aqua*
> Not a body — a cross-section of pale packed road-stone and ice standing
> upright as if the ground itself had been tipped on end, four storeys tall,
> layered bands of frost and stone visible all the way down. No limbs, no
> head, no need of either. Facing right, entirely still, patient past
> reckoning.

### Arena backdrop

`assets/backgrounds/frostfell_pass.png` — *16:9 · Aqua + Aero palette*
> Wide 16:9 landscape painting of a high mountain pass seen side-on at
> standing eye level, environment only — no creatures, no people, no text. A
> level shelf of packed snow and pale trail-stone runs straight across the
> frame just past mid-height, frost-rimed cairns marking its edge. Below it,
> the pass drops away into deep blue-grey shadow across the bottom fifth. At
> the far left and far right edges, broken rock outcrops cropped by the
> frame, dusted white and hung with short frozen-breath plumes that never
> disperse. The centre of the frame is **open pale sky and drifting snow
> haze**, with nothing rising out of it and no light source in it. Overcast,
> windless despite the theme, bitterly still. **Aqua + Aero palette**,
> matching the creatures above: rime white, stone grey, faint held-breath
> blue, nothing wet. Muted, low-contrast, and everything holding its
> position.

---

## The Kiln Desert · Lv 30–34 · Solar

> ⭐ *Burning and freezing at once.* ⚠️ **A contradiction, not a heat.**
> Everything here should read as sun-bleached and frost-bitten in the same
> object — pale, salt-crusted, hard-edged, with shadows cut too sharply for
> the light that is supposedly making them. Nothing is soft, nothing is damp,
> and nothing here has a body worth skinning.

### Commons

**Shadeless** — *common · Adept · Solar*
> A lean human figure the height of a person, wrapped in sun-bleached pale
> linen from crown to ankle with no face visible, the cloth stiff and white
> with salt. The ground beneath and behind it is bare and unshaded — nothing
> falls from it at all. Standing upright, weight even, arms loose at its
> sides.

**Sunstruck Pilgrim** — *common · Blighter · Solar*
> A stooped traveller a head shorter than a person, swaddled in layers of
> cracked grey-brown road cloth burnt through in patches to blistered red
> skin, a broad flat sunhat collapsed at the brim. Both arms extended
> straight ahead at chest height, hands open. Walking, head tipped slightly
> back.

**Glasspan Crawler** — *common · Bruiser · Solar*
> A low slab-bodied creature about knee height and twice as long as a person,
> its back a single fused crust of white salt shot through with bottle-green
> glass, cracked into plates. Six short thick legs beneath. Blunt squared
> front end with no head, pushing forward at a steady walk.

**Mirage** — *common · Glasswing · Solar*
> A tall thin humanoid shape the height of a person made of rippling heat
> distortion rather than matter — the pale desert behind it visible through it
> and bent sideways, edges dissolving into shimmer. Only a darker vertical
> core holds a definite outline. Upright, poised, barely there.

**Kiln Moth** — *common · Lasher · Solar*
> A moth with a wingspan as wide as a person's outstretched arms, wings
> ash-paper grey and translucent, every edge charred black and crumbling. Thick
> furred body the colour of cold cinders, feathered antennae. Wings held
> half-open, angled forward.

### Mini-bosses

**Sun Templar** — *mini · Champion · Solar*
> A suit of mirror-polished pale gold plate armour a head taller than a
> person, standing empty — the visor's eye-slit shows nothing but more
> daylight behind it. Long tabard bleached to bone white. Upright, one hand
> resting on a plain straight pole-standard.

**Prism Sentinel** — *mini · Redoubt · Solar*
> A standing wedge of clear sand-glass twice the height of a person and
> broad at the base, cut into dozens of flat facets at differing angles, each
> face catching the light differently with thin rainbow fringes at the edges.
> No limbs and no face. Planted, motionless.

**Saltmarch Wraith** — *mini · Executioner · Solar*
> A column of fine white salt dust the height of two people, holding the
> loose silhouette of a file of hooded walkers stacked one behind another
> inside it, faces suggested and never resolved. Trailing grit at the base.
> Leaning forward, mid-stride.

**The Shadeless Hour** — *mini · Hexer · Solar*
> An extremely tall, extremely thin humanoid absence the height of two people
> and no wider than an arm, rendered as a hard-edged vertical gap in the
> image with the pale desert visible through it, slightly displaced. Long
> thin limbs, no features. Standing straight, arms hanging.

### Bosses

**The Cold Shadow** — *boss · Juggernaut · Solar*
> An enormous low mass of flat matte black the size of a rock shelf, three
> times the length of a person and chest high, with a perfectly hard
> unfeathered edge all the way round as though cut from the ground. Faint
> white frost rimes the pale salt at its border. Lying low, spread wide.

**Solar Deity** — *boss · Aspect · Solar*
> A standing column of hard white-gold light roughly the height and breadth
> of a person, brightest at its core and never blurring at its outline, with
> the suggestion of shoulders and a raised head but no face or limbs. The pale
> ground beneath it is scorched to a ring. Upright, still, radiant.

---

## The Mirrormere · Lv 32–37 · Lunar

> ⭐ *The reflection is bigger than the thing, and it is looking back.*
> ⚠️ **Not ghosts and not water elementals.** Everything here should read as
> *something seen on a still surface that has stopped agreeing with what cast
> it* — pale, silver-grey and cold-white, flat or slightly too smooth, sized
> against a person and then, on the bosses, sized wrongly on purpose. Colour
> is near-monochrome throughout: silver, bone-white, lake-grey and the dark of
> deep water. ⚠️ **No warm light anywhere except Bloodwood's red**, and that
> belongs to the items, not the creatures.

### Commons

**Mirror Wraith** — *common · Adept · Lunar*
> A standing human figure the height of an adult, made of flat lake-light —
> silver-white, edgeless, with no features cut into the face and no depth to
> the body, like a reflection lifted off the water and stood upright. Squared
> shoulders, arms loose at the sides. Standing balanced and still, weight
> evenly on both feet.

**Stillface** — *common · Blighter · Lunar*
> A flat upright oval of unbroken water about the width of a person's
> shoulders and as tall as a door, held vertical with nothing behind it. Its
> surface is mirror-smooth pale silver, the rim a thin darker meniscus curling
> inward. No limbs, no base. Hanging level at head height, perfectly
> motionless.

**Undershine** — *common · Glasswing · Lunar*
> A long tapering brightness roughly the length of a person and a quarter as
> wide, cold white at its core fading to pale blue at the trailing edge, with
> two thin fin-like sheets of light spread either side. It is seen through a
> hand's depth of dark water, so its edges are soft. Travelling flat and
> horizontal, nose slightly down.

**Ripplecut** — *common · Skirmisher · Lunar*
> A single raised line of water about an arm's length, low and sharp like the
> wake of something just below, rising to a thin blade-edged crest at its
> leading point. Dark lake-grey with one hard white highlight along the crest.
> No body is visible. Angled forward, mid-travel, leaning into the cut.

**Palefish Shoal** — *common · Lasher · Lunar*
> Several hundred finger-length fish holding one loose person-sized cloud just
> under the surface, each one colourless and translucent with a faint silver
> spine showing through. The shoal's outline is soft and constantly ragged at
> the edges. Hanging as a loose vertical column, all heads pointed the same
> way.

### Mini-bosses

**The Second You** — *mini · Champion · Lunar*
> A fully solid human figure of exactly adult height, opaque and dripping,
> wet-dark all over as though just walked out of deep water, with the same
> build and the same clothing silhouette as a traveller but no face — the head
> smooth and blank. Standing squared and forward, weight shifted onto the
> front foot.

**Herald of the Waxing** — *mini · Redoubt · Lunar*
> A broad kneeling figure half again a person's height, carved from pale grey
> stone. One entire side is finished and polished smooth, the other still
> rough-hewn and blocky, with a hard vertical line dividing the two down the
> centre of the body and face. Kneeling low and squat, arms braced on the
> ground.

**Stalker of the New Moon** — *mini · Executioner · Lunar*
> A tall narrow human silhouette a head above adult height and unnaturally
> thin, rendered as pure black absence — no surface, no highlight, no detail,
> a hole cut in the scene in the shape of a walking person. Long arms, long
> stride. Mid-step, leaning forward, one arm already extended.

**The Waning Wraith** — *mini · Hexer · Lunar*
> A person-height figure of thin silver light, narrow and upright, with a
> clean curved bite missing from one whole side of it — head, shoulder and
> ribs cut away along one smooth crescent arc. The remaining edge is bright
> and sharp; the cut edge fades to nothing. Standing turned three-quarters, the
> missing side toward the viewer.

### Bosses

**The Moon Below** — *boss · Tyrant · Lunar*
> An enormous disc of cold white light lying flat just beneath a dark water
> surface, wide enough to fill the frame behind a person standing at the
> shore — many times a person's height across. Its face carries grey maria
> markings arranged into something that reads, uncomfortably, as watching.
> Level, submerged, tilted very slightly up toward the near shore.

**Luna Plena, the Full Moon** — *boss · Aspect · Lunar*
> A full moon hung low over the lake at the size the water had been showing
> it — a vast pale sphere, many times a person's height, close enough that its
> craters read as real relief rather than markings. It is bright enough to
> throw a second, contradictory shadow from everything on the shore. Hanging
> square-on, face fully lit, no crescent anywhere.

---

## Starfall Basin · Lv 34–39 · Astral

> ⭐ *Things fell here, and the sky is still aiming.* ⚠️ **Arrival, not
> residence.** Everything here should read as something that came down rather
> than grew up — hard edges, fusion crust, a direction of travel still legible
> in the shape. Nothing organic, nothing rooted, nothing weathered soft.
> Palette is Astral: blue-black, indigo, and hard white points.

### Commons

**Crater Revenant** — *common · Adept · Astral*
> A human figure of ordinary height standing at the bottom of a shallow pale
> bowl, in the remains of travelling clothes gone grey and stiff. Skin and
> cloth alike are dusted with fine blue-black grit that does not fall off.
> Squared shoulders, hands open and low, weight evenly on both feet.

**Sky-Iron Husk** — *common · Sentinel · Astral*
> An upright hollow shell of dark pitted metal the height of a person, shaped
> like a torso and legs with nothing inside, its outer surface scabbed with a
> thin black fusion crust and split open down one side to show an empty
> interior. Standing square, motionless, faintly heat-hazed at the edges.

**Fallpoint** — *common · Glasswing · Astral*
> A narrow vertical streak of hard white light about the height of a person,
> thin as a drawn line at the top and flaring where it meets the ground,
> surrounded by a faint indigo blur. No body, no limbs, no face. Angled
> slightly off vertical, as though still descending.

**Scatterling** — *common · Lasher · Astral*
> A loose waist-high spread of forty or fifty angular blue-black fragments
> hanging in rough formation with clear air between them, each shard
> thumb-sized to fist-sized with bright white flecks inside. No single
> outline. Low, wide, drifting apart and back together.

**Cold Ejecta** — *common · Skirmisher · Astral*
> A single dense chunk of dark pitted rock about the size of a curled dog,
> travelling low and flat above the ground with a faint indigo trail behind
> it. One face is smooth and scorched, the other broken and bright grey.
> Nose-forward, never still, never touching down.

### Mini-bosses

**The Zodiac Ascendant** — *mini · Champion · Astral*
> A wheel of twelve figures turning on edge, twice the height of a person,
> each figure drawn as a constellation of hard white points joined by fine
> indigo lines. The rim is a complete circle; the interior is open dark.
> Upright, slowly rotating, the topmost figure brightest.

**Constellation Warden** — *mini · Redoubt · Astral*
> A broad humanoid figure half again the height of a person, its whole body
> an outline of fixed white points connected by thin indigo lines with empty
> night between them. Heavy-shouldered, wide-stanced. Planted, arms slightly
> out, facing forward and unmoving.

**Rift Walker** — *mini · Executioner · Astral*
> A tall narrow figure a head and a half above a person, its silhouette a
> clean vertical tear in the air showing deep indigo depth rather than a
> surface, edged in a hard white line. Long-limbed, no features. Mid-stride,
> one leg already gone from view.

**Echo of the Between** — *mini · Hexer · Astral*
> A person-height figure repeated three or four times in fading offset
> copies, the leading copy sharpest and the trailing ones thinning into
> blue-black haze. Slender, robed, no visible face. Leaning forward, the
> copies strung out behind it like a delay.

### Bosses

**The Next One** — *boss · Juggernaut · Astral*
> An enormous dark mass filling the upper half of the frame, its underside
> curved and pitted and lit along one leading edge in hard white, with a long
> indigo tail of shed material streaming back and up. Easily four storeys of
> visible bulk. Overhead, oncoming, no ground contact.

**What Landed** — *boss · Tyrant · Astral*
> A compact curled form the size of a crouching person at the centre of a
> deep bowl, smooth and unmarked and matte blue-black, with a faint indigo
> sheen along one curve. No crust, no damage, no scorching. Low, gathered,
> and turned precisely toward the viewer.

---

## Tidewrack Shoals · Lv 36–40 · Lunar + Aqua

> ⭐ *The sea is on a schedule it did not choose, and it keeps uncovering
> things.* The fusion is **obedience** — Aqua doing what Lunar says. ⚠️ This
> zone assigns its element per creature, not "both" by default: some things
> here are pure water (Aqua), some are pure clock (Lunar), and only the three
> the roster names both are visibly tide AND moon at once. Wet slate, bleached
> shell-white, weed-black and a cold pale grey-green throughout; ⚠️ everything
> here is either **just uncovered** or **about to be covered again** — nothing
> is dry and nothing is deep.

### Commons

**Tidewrack Drowned** — *common · Adept · Lunar+Aqua*
> A drowned soldier the height of a tall person, standing fully upright in
> ankle-deep water, body bulked out by sodden layered cloth gone the colour of
> wet slate. A plain corroded helm with no face visible under the brim; one
> arm holds a short weathered blade low and level. Shoulders square, chin up,
> weight forward — a parade stance, kept.

**Wrackcrab** — *common · Sentinel · Aqua*
> A broad flat crab as wide across as a cartwheel and barely knee-high, its
> shell a single low dome crusted over with pale fibrous weed and small white
> shells until almost no shell shows. Eight short thick legs splayed wide, two
> heavy blunt claws folded flat against the front. Hunkered down, clamped to
> the sand.

**Lowwater Thing** — *common · Blighter · Aqua*
> A wide shallow body of standing water roughly a person's height and three
> times as broad, holding a low humped shape with no head and no limbs — just
> a raised leading edge that stands an inch or two proud of the flat. Warm
> grey-green and faintly cloudy, with a thin rim of scum along the advancing
> edge. Low, spread, creeping.

**Gullbone Flock** — *common · Lasher · Lunar*
> Two dozen long-winged seabirds flying as one loose mass about the size of a
> cart, wings narrow and sharply crooked, bodies bleached bone-white with pale
> grey backs and black wingtips. No single bird is the centre of the shape.
> Banked hard together mid-turn, all at the same angle.

**Spindrift** — *common · Skirmisher · Aqua*
> A torn sheet of sea-spray about the height of a person and twice as wide,
> held flat and streaming horizontally a hand's width above wet sand, thin
> enough at the trailing edge to see the ground through it. White-grey shading
> to near-transparent. Stretched forward, leaning into its own travel.

### Mini-bosses

**Tidal Empress** — *mini · Champion · Lunar+Aqua*
> A tall crowned woman a head and a half above human height, standing on open
> wet flat in a long heavy gown of deep blue-green that pools around her feet.
> Behind her the sea stands as a smooth vertical wall twice her height, not
> breaking. A thin pale circlet of shell sits on her brow. Still, hands at her
> sides, facing forward.

**Leviathan** — *mini · Redoubt · Aqua*
> An immense smooth back breaking shallow water for the length of a jetty,
> dark slate-grey above and fading pale beneath, the visible ridge running out
> of frame at both ends so no whole body is shown. Skin scarred in long pale
> rakes and scattered with barnacle clusters. Barely moving, half-grounded,
> most of it still under.

**Maelstrom Horror** — *mini · Executioner · Aqua*
> A turning column of water three times a person's height, wide as a boat at
> the top and narrowing to a dark throat at the sand, its walls smooth and
> ribbed with spiral bands of grey-green and white foam. Nothing solid inside
> it. Leaning slightly, drawing inward at the base.

**The Turning** — *mini · Hexer · Lunar*
> A tall thin upright seam standing on the open flat at roughly a person's
> height, where the water on one side runs out and the water on the other side
> runs in — a visible vertical line with opposite currents meeting along it.
> No body, no face, only the seam and the pale moon-white glow along its
> length. Motionless while everything around it reverses.

### Bosses

**Kraken** — *boss · Juggernaut · Aqua*
> An enormous cephalopod lying uncovered across the open flats, its mantle
> alone the size of a house and its arms sprawled out further than the frame,
> the whole mass deep purple-grey and glistening with wet weed and sand. One
> flat eye the width of a shield, open. Heaped rather than reared — grounded,
> filling the ground between here and anywhere.

**The Undertow** — *boss · Aspect · Lunar*
> Not a body: a broad sheet of shin-deep water running hard away from the
> viewer across the whole width of the frame, its surface drawn into long
> parallel grooves and the sand beneath it visibly scouring out into hollows.
> Cold pale grey-green, lit as if from far overhead by something not in shot.
> Featureless, low, and entirely in motion away.

---

## The Sunless Reach · Lv 38–42 · Solar + Lunar

> ⭐⭐ *Identical ground, opposite worlds, one line between them.* ⚠️ **The
> fusion is a boundary, not a blend.** Nothing here is dusk, twilight or
> gradient — every creature is either hard-lit or wholly unlit, and the few
> that are both carry the division as a **straight visible edge with no
> falloff across it**. The rock is the same black scarp stone on both sides.
> Palette: bleached desert white and hard yellow-white glare against flat
> lightless black, with pale cold moon-grey as the only third value.

### Commons

**Eclipse Herald** — *common · Adept · Solar+Lunar*
> A robed humanoid figure a head taller than a person, seen in profile and
> facing right, walking at an even pace. Its whole right side is lit hard
> white as if by a low sun and its whole left side is flat unlit black, with
> a single straight vertical division running head to hem and no blending
> anywhere along it. Heavy plain travelling robe, hood up, face in shadow.

**Crestline Warden** — *common · Bruiser · Solar*
> A broad, heavy-shouldered humanoid the height of a doorway and half again
> as wide as a person, built of sun-scoured pale stone the colour of bleached
> bone, its surfaces cracked and flaked from long exposure. No neck, a blunt
> squared head, forearms thicker than its thighs. Planted, leaning forward,
> shoulder turned as if about to push.

**Nightglare** — *common · Blighter · Solar*
> A hard knot of white light about the size of a human head, hanging at chest
> height with no body beneath it, its edge sharp rather than diffuse and a
> short flare of glare trailing back from it to the left. No limbs, no face,
> no visible source. Hanging motionless, oriented right.

**Coldlight Swarm** — *common · Lasher · Lunar*
> A loose cloud of several hundred pale grey-white motes, each the size of a
> fingernail, holding a rough dog-sized mass drawn out toward the right, with
> individual motes drifting free at its trailing edge. No solid core, no
> silhouette that stays fixed. Low to the ground, streaming rightward.

**Shadowpitch Stalker** — *common · Skirmisher · Lunar*
> A low, lean quadruped a little longer than a person is tall, its whole body
> a flat unbroken black that takes no highlight anywhere, so it reads as a
> hole in the picture rather than an animal. Long neck, narrow head lowered
> level with the shoulders, four thin legs. Mid-stride, body stretched out,
> facing right.

### Mini-bosses

**Solar Archon** — *mini · Champion · Solar*
> An armoured humanoid figure half again the height of a person, plated head
> to foot in mirror-polished pale metal so bright the plates read as white
> rather than silver, with a tall plain crested helm and no visible face
> beneath it. Standing upright and square, shoulders back, facing right.

**The Crest** — *mini · Redoubt · Solar+Lunar*
> A single upright slab of black scarp stone roughly thirty feet long and
> twice the height of a person, standing on its long edge like a wall pulled
> up out of the ground. Its upper face is lit hard white, its lower face is
> flat black, and the two meet along the top edge in one dead-straight line
> with no gradient. Immobile, planted, its long axis running rightward.

**Both-Sided Thing** — *mini · Executioner · Solar+Lunar*
> A humanoid figure of ordinary person height, split top to bottom down its
> exact centre line — the right half bleached the pale grey-white of desert
> floor stone, the left half flat lightless black — with a hard seam between
> them and no blending at all. Both halves are the same shape. Turned
> three-quarters to the right, weight forward, arms low and loose.

**Duskmarch** — *mini · Hexer · Lunar*
> A tall, very thin humanoid silhouette of uniform flat black, person-height
> but barely a hand's width deep, like a shadow standing up off the ground
> without anything casting it. No features, no highlights, edges perfectly
> crisp. Walking steadily in profile, facing right, one leg forward.

### Bosses

**The Last Light** — *boss · Aspect · Solar*
> A towering wedge of hard white-gold light four storeys tall, broad at the
> base and narrowing to a blade-thin top edge, with a faint suggestion of
> shoulders and a raised head read into its upper third. Its edges are knife
> sharp against the white ground, marked out by a thin darker rim. Standing
> upright, leaning very slightly rightward.

**The First Dark** — *boss · Aspect · Lunar*
> A colossal mass of total flat black four storeys tall, roughly humanoid and
> heavily hunched, with no surface detail, no highlights and no texture
> anywhere on it — a silhouette rather than a body. Its outline is smooth and
> unbroken, with no edges or points. Standing, shoulders forward, head low
> and turned right.

---

## The Shattered Orrery · Lv 40–44 · Astral + Electro

> ⭐ *A broken machine still computing, and nobody knows what toward.*
> ⚠️ **Mechanism, not weather.** Every silhouette here should read as a
> *part* — something turned, wound, geared or wired — at a scale meant for a
> building. Brass and worked metal gone yellow-brown with a blue tarnish
> bloom; the light is arc-white and hard-edged, never a glow. Nothing organic,
> nothing grown, nothing soft.

### Commons

**Orrery Automaton** — *common · Adept · Astral+Electro*
> An upright brass figure the height of a person, built as a jointed armature
> rather than a body — segmented limbs of tarnished yellow-brown brass over a
> visible internal train of small gears, with a smooth featureless dome for a
> head and a single ring of incised marks around it. Fine blue-white arcs
> cross the gaps at every joint. Standing squarely, weight even, one arm
> raised as if partway through an adjustment.

**Gear-Ghost** — *common · Glasswing · Astral*
> A wheel-shaped absence about the width of a cartwheel, standing on edge in
> the air with nothing in the middle — its rim and teeth drawn only as thin
> pale blue-white lines of light, brightest along the short arc where teeth
> would be meshing and fading to nothing on the far side. No mass, no
> shadow. Hanging upright, mid-turn.

**Armature** — *common · Bruiser · Electro*
> A single torn-loose support arm half again the height of a person, standing
> upright on its ragged hub end — a tapering beam of dull yellow-brown brass
> wrapped along its length in close copper windings, with a bright sheared
> break face at the base. The windings carry a hot white-blue glow that is
> strongest near the top. Planted, leaning slightly back, top-heavy.

**Arcflock** — *common · Lasher · Electro*
> Two dozen small white-blue discharges holding a loose ovoid formation about
> head height and the width of two people, each one a short jagged spark no
> longer than a finger, none of them in the same place twice. No body, no
> outline — only the shape the density makes. Hovering, drifting, constantly
> reshuffling.

**Errant Ring** — *common · Skirmisher · Astral*
> A thin metal ring the width of a doorway, rolling upright on its edge —
> tarnished brass banded with a pale inlaid track of incised star-marks
> around its outer face, slightly out of true so it wobbles as it turns. A
> worn groove in the floor beneath it. Tilted off vertical, caught in the
> moment of correcting.

### Mini-bosses

**Sidereal Fault** — *mini · Champion · Astral*
> A vertical seam in the air as tall as a three-storey building and no thicker
> than a hand, edges drawn hard and bright like a cut in glass. Through it,
> the same field of stars as around it, shifted visibly sideways. Cold pale
> blue-white light along the cut, darkness inside. Standing dead upright,
> perfectly still.

**Escapement** — *mini · Redoubt · Electro*
> A toothed escape wheel the width of a person's armspan, mounted alone in a
> heavy square brass frame twice a person's height, with a two-armed pallet
> poised against its teeth. Dull tarnished brass, the tooth tips polished
> bright by four centuries of contact. Arc-light flares white at the point of
> catch. Stationary, locked, one tooth from releasing.

**Long Division** — *mini · Executioner · Astral+Electro*
> A hanging column of worked figures as tall and wide as a wall, written in
> lines of thin arc-white light, each line shorter than the one above it and
> the whole column drifting slowly downward. Faint blue-brass afterimages
> where finished lines have scrolled past. Vertical, narrow, tapering toward
> the floor and never reaching it.

**The Remainder** — *mini · Hexer · Astral*
> A single irregular lump of set-aside figure about the size of a person,
> hanging at chest height off to one side of nothing — a dense knot of pale
> numerals compacted into a rough mass, brighter at the core than the edges,
> with loose digits still orbiting it slowly. Hunched, compact, waiting.

### Bosses

**The Calculation** — *boss · Juggernaut · Electro*
> The entire working of the machine seen at once, filling a chamber from floor
> to broken roof — a nested set of eight or nine brass rings the size of
> bridges, each on a different axis and each turning at its own rate, hubs and
> gear trains visible where they cross. Tarnished yellow-brown metal with
> white-blue arcs jumping between every ring. A person at the base reaches the
> height of the lowest hub. Vast, layered, indifferent.

**The Answer** — *boss · Tyrant · Astral*
> A single standing arrangement of light about the size of a person, at the
> exact centre where the rings once crossed — a closed, symmetrical figure of
> fine white-gold lines, self-contained and resolved, with nothing orbiting it
> and nothing unfinished at its edges. It casts a hard shadow the machine
> around it does not. Upright, centred, entirely motionless.

---

## The Glass Archive · Lv 43–47 · Solar + Arcane

> ⭐ *They wrote it in light, and light does not keep.* The fusion is **an
> archive readable only at noon, which the reading destroys** — Solar's Blind
> and Arcane's Knowledge read together. ⚠️ This zone assigns its element per
> creature, not "both" by default: the lens-and-glare things are Solar, the
> written things are Arcane, and only the roster's two hybrids are visibly
> both. Palette throughout: colourless plate glass, brass, bone-white vellum,
> hard white glare and one cool violet note. ⚠️ **Nothing here is warm or
> golden** — the light is white and flat, not sunset. Nothing is ruined,
> either; everything is intact and simply unreadable.

### Commons

**Glasswright** — *common · Adept · Solar+Arcane*
> A lean humanoid figure of person height built from fitted rectangular
> plate-glass panes held in a dark lead armature, in profile, head and body
> turned toward the right edge of the image. Colourless glass throughout with
> one faint violet flaw running through the chest pane. A heavy leather
> apron shape hangs from the armature at the waist. Standing squared up,
> weight even, hands open at its sides.

**Noonmark** — *common · Glasswing · Solar*
> A person-sized wedge of hard flat white light standing upright on a bare
> hillside, edged as cleanly as a cast shadow, with no body inside it at all.
> Pure white at the core fading to nothing at the outer edge, where two thin
> blade-shaped planes read as half-open wings. Weightless, angled slightly
> forward, facing right.

**Palimpsest** — *common · Blighter · Arcane*
> A single standing sheet of pale cream vellum roughly person height,
> upright and slightly curling at its edges, scraped visibly thin in patches
> where older grey script shows through the newer. Layer on layer of
> overlapping handwriting in grey and faint violet covers it entirely. No
> limbs and no head — just the sheet, turned edge-on toward the right.

**Readerless** — *common · Lasher · Arcane*
> Several dozen loose written vellum leaves travelling together at about
> chest height in a rough person-wide drift, none of them touching, none of
> them bound. Pale cream pages with grey script, every one face-up. No single
> silhouette holds still. Spilling forward and to the right.

**Lensfly** — *common · Skirmisher · Solar*
> A hand-span of ground brass-rimmed lens carried on four thin jointed brass
> legs, low and flat to the ground like a beetle, its round glass face
> tilted up and to the right. Colourless glass, dull brass, one hard white
> point of glare caught in the lens. Poised mid-scuttle, legs splayed,
> facing right.

### Mini-bosses

**The Last Reader** — *mini · Champion · Solar+Arcane*
> A seated humanoid figure a head taller than a person would be standing,
> robed in overlapping panes of smoked grey glass, a brass reading-frame
> braced across its lap with one vellum sheet still in it. Smoked glass,
> dark brass, cream vellum. Rising from the seat without setting the frame
> down, one hand still flat on the page, facing right.

**Aperture** — *mini · Redoubt · Solar*
> A freestanding upright ring of overlapping brass leaves twice the height of
> a person, standing on the bare hillside with nothing supporting it.
> Weathered dull brass; the narrow opening at its centre is filled with flat
> white light much brighter than anything around it. Motionless, planted,
> the opening turned toward the right edge.

**Burnt Index** — *mini · Executioner · Solar*
> A tall freestanding wooden card-case the height of a person, charred solid
> black from its lower end upward, the upper half still holding neat filed
> ranks of cream index cards and the lower half still holding its shape
> entirely as grey ash. Black char, grey ash, cream card. Leaning forward,
> gathering itself, facing right.

**The Marginalia** — *mini · Hexer · Arcane*
> A dense person-sized crowd of small pale annotating hands, each no larger
> than a child's, crawling over and around one another in a loose upright
> column, every one holding a fine pen. Bone-white hands, grey ink, faint
> violet at the fingertips. Crowding steadily inward and to the right,
> never still.

### Bosses

**What Was Written** — *boss · Tyrant · Arcane*
> A colossal standing column of handwritten script four storeys tall,
> holding together with no page beneath it — the writing itself is the body.
> Grey-violet ink on nothing, denser at the base, thinning toward a top that
> is still being written. No limbs, no face. Upright, unhurried, facing
> right.

**What Is Left Of It** — *boss · Aspect · Solar*
> Not a body — a roughly humanoid four-storey shape of pure white glare
> standing on a hillside of aimed lenses, its silhouette readable only as
> the place the light has nothing further to pass through. Blinding flat
> white at the core, hard-edged, no interior detail of any kind. Facing
> right, motionless, painful to look at directly.

### Arena backdrop

`assets/backgrounds/the_glass_archive.png` — *16:9 · Solar + Arcane palette*
> Wide 16:9 landscape painting of a terraced hillside of glass-roofed reading
> halls seen side-on at standing eye level, environment only — no creatures,
> no people, no text. A level shelf of pale dressed stone runs straight
> across the frame just past mid-height. Behind it to the far left and far
> right, cropped by the frame, the stepped ends of low halls roofed entirely
> in colourless plate glass, every roof panel angled and still aimed. Below
> the shelf the terraces drop away into cool violet-grey shade across the
> bottom fifth. The centre of the frame is **open white sky at noon**, empty,
> with nothing rising out of it and no visible sun disc. Overcast-bright,
> flat, shadowless. **Solar + Arcane palette**, matching the creatures above:
> colourless glass, dull brass, bone-white stone, hard white glare, one cool
> violet note in the shade. Nothing warm, nothing golden, nothing ruined —
> everything intact and unreadable.

---

## Hallowmarch · Lv 45–49 · Sanctus

> ⭐ *Someone is still doing the upkeep, and nobody has seen them.* A raised
> stone causeway climbing the Vault's south flank, with a cut meltwater
> channel running beside it the whole way and a marker every mile. ⚠️ **A
> pure zone: every creature is single-element Sanctus**, so there is no second
> palette to split them by — they are separated by what they are *for*, not by
> colour. Palette throughout: pale dressed road-stone, silver-white spiritwood,
> whitewash, plain pale metal, and one warm gold note — lamplight, small
> flames, and the yellow goldenrood in the channel. ⚠️ **Nothing here is
> ruined, broken, mossy or overgrown.** Everything is maintained, square and
> recently attended to; that intactness is the whole unsettling idea and an
> artist's instinct toward picturesque decay must be resisted.

### Commons

**Causeway Warden** — *common · Sentinel · Sanctus*
> A broad armoured humanoid figure of about person height but twice a
> person's width, standing squared up in the middle of a flat stone road,
> facing right. Plate of pale dressed stone and plain pale metal, all of it
> weathered to the same colour as the roadway under it, with no heraldry and
> no ornament anywhere. Feet planted apart, arms loose at its sides, entirely
> motionless.

**Marker-Sworn** — *common · Adept · Sanctus*
> A robed humanoid figure of ordinary person height in plain undyed
> road-dust-grey cloth, hood back, turned three-quarters toward the right.
> It holds a short straight wooden rule in one hand and a small open pot of
> white lime wash in the other, the brush still in the pot. Pale cloth, pale
> wood, one clean white smear on the sleeve. Standing easily, mid-stride
> interrupted.

**Meltwater Choir** — *common · Lasher · Sanctus*
> A cut stone channel about a pace wide running along beside a road, its
> water thrown up into two dozen separate standing plumes of white spray at
> roughly chest height, spaced evenly along the channel's length. Clear water,
> white foam, pale wet stone. No body, no face and no single silhouette —
> the plumes lean together toward the right as a group.

**Votive** — *common · Glasswing · Sanctus*
> A single upright flame the size of two hands, burning at head height in
> open air beside a pale stone road-marker, with no lamp, wick or vessel
> beneath it. Warm gold at the core fading to near-white at the tip, its
> outer edges drawn out into two thin leaf-shaped sheets of light that read
> as wings. Leaning slightly to the right, as toward a draught.

**Pilgrim's Remnant** — *common · Bruiser · Sanctus*
> A bulky roped travelling pack standing upright on a stone road at about
> chest height, fully loaded and tightly strapped, with the shoulder straps
> hanging empty and no body in them. Worn brown canvas, pale rope, a rolled
> grey blanket lashed across the top, a tin cup on a cord. Tilted forward as
> though walking uphill, facing right.

### Mini-bosses

**Milestone** — *mini · Champion · Sanctus*
> A squared pale stone road-marker twice the height of a person, standing
> upright in the centre of a flat stone road, facing right. Dressed pale
> stone, crisply cut, its upper face carrying one deeply incised numeral
> filled with white lime. Unweathered, unchipped, freshly set — the earth
> around its base is still disturbed.

**Vestal Warden** — *mini · Redoubt · Sanctus*
> A seated armoured humanoid figure half again as tall as a standing person,
> filling a small arched stone roadside shelter built to hold exactly one
> occupant, facing right out of the arch. Pale stone plate, plain pale metal,
> hands resting on its knees. A small brass lamp burns with a steady gold
> flame in a niche cut beside it. Immobile, filling the opening completely.

**Seraph Judicant** — *mini · Executioner · Sanctus*
> A tall winged humanoid figure a head and a half above person height, facing
> directly right, holding an unrolled plain white writ open in both hands at
> chest height and reading from it without lowering its head. Four narrow
> straight wings of pale feather held rigid and half-spread, undyed white
> vestments, a plain smooth face without expression. Poised, already turned
> toward the viewer's side of the frame.

**The Upkeep** — *mini · Hexer · Sanctus*
> A person-sized patch of stone roadway that is visibly cleaner and paler
> than the road on every side of it, with no figure, limbs or head anywhere
> in it. Scrubbed pale stone against road-grey, its leading edge soft and
> its trailing edge sharp, one thin wet gleam along the boundary. Advancing
> low and to the right.

### Bosses

**The Keeper of the Road** — *boss · Juggernaut · Sanctus*
> A colossal four-storey humanoid shape of pale road-stone, stooped forward
> at the waist over the causeway the way a mason stoops to their work, facing
> right. It carries a perfectly straight stone edge as long as the road is
> wide, held level in both hands. Pale dressed stone throughout, blockish and
> square-cut, no face and no armour detail. Unhurried, mid-stoop, in motion.

**The Hierophant Eternal** — *boss · Tyrant · Sanctus*
> A vested humanoid figure four storeys tall standing at the head of a stone
> causeway, facing right and looking back down the road, hands folded at its
> waist and entirely still. Heavy undyed white vestments falling straight to
> the ground, a tall plain pale mitre, one thin band of gold at the hem. The
> face is smooth and featureless. Upright, static, addressing nothing.

### Arena backdrop

`assets/backgrounds/hallowmarch.png` — *16:9 · Sanctus palette*
> Wide 16:9 landscape painting of a raised stone causeway climbing a bare
> sunlit mountain flank, seen side-on at standing eye level, environment only
> — no creatures, no people, no text. The roadway runs straight across the
> lower third of the frame on a built-up embankment of pale dressed blocks, a
> narrow cut water channel glinting along its near edge with a band of
> yellow goldenrood growing in it. Two pale squared road-markers stand at
> regular intervals, upright and clean. Behind, the flank rises out of frame
> to the right in grey-white rock; to the left the slope falls away into pale
> cloud. Low warm sunlight from the left, long clean shadows, high thin air.
> **Sanctus palette**: pale road-stone, whitewash, silver-white timber, plain
> pale metal, one warm gold note in the flowers and the light. Nothing ruined,
> nothing overgrown, nothing broken — every stone square and recently
> attended to.

---

## The Buried Sky · Lv 46–50 · Geo + Astral

> ⭐ *The rock remembers a sky that no longer exists.*
> ⚠️ **Strata, not caves.** Every silhouette here should read against a wall
> of horizontally banded stone — layer on layer, each band a different colour
> and a different grain, dark grey through rust-brown through near-black. The
> light set in the rock is cold, small and **point-like**: pinpricks and
> scatters of pale blue-white, never a wash and never a beam. Nothing is
> angry, nothing is haunted, nothing is decorative. It is a record.
> ⚠️ **Deliberately the opposite of The Glass Archive** — no glass, no lenses,
> no warmth, nothing transparent.

### Commons

**Stratum Warden** — *common · Sentinel · Geo*
> A slab standing across the shaft, twice the height of a person and half
> again as wide, built of five or six stacked horizontal bands of stone —
> charcoal, rust-brown, pale grey, near-black — each band a different
> thickness and each meeting the next at a clean flat seam. A scatter of tiny
> cold blue-white points is set into the upper bands only. No face, no limbs;
> the topmost band overhangs slightly like a brow. Planted square, immovable,
> squarely blocking.

**Constellate** — *common · Lasher · Astral*
> A loose cloud of thirty or forty separate pale blue-white points holding a
> roughly person-sized ovoid about head height, each point no bigger than a
> spark and none of them in the same place twice. Faint hairline threads flick
> between them and vanish. No body, no outline, no shadow — only the shape the
> density suggests. Hovering, drifting, never resolving into a figure.

**Fadelight** — *common · Glasswing · Astral*
> A single thin figure the height of a person drawn entirely in one continuous
> pale white-blue line, like a long exposure of something that walked past —
> no thickness, no interior, the line fading almost to nothing at the ankles
> and at the fingertips. Brightest at the centre of the chest, where a single
> small hard point sits. Upright, drifting, already half gone.

**Corebiter** — *common · Bruiser · Geo*
> A low blunt quadruped the length of two people and only chest-high, built
> like a wedge with the broad end forward — matte charcoal-black hide with a
> fine pebbled grain and a paler grey underside, no eyes, and a wide flat
> mouth of short blunt grinding teeth set in the front face. Rock dust caked
> in the folds. Head down, shoulders bunched, mid-push.

**Deadreckoner** — *common · Adept · Geo+Astral*
> An upright figure a head taller than a person, its body a rough column of
> banded grey stone and its head a smooth eyeless dome, holding both arms out
> level in front of it as if sighting along them. A field of small cold
> blue-white points is set deep inside the chest, visible through the stone
> like something embedded rather than carried. Standing, weight even, taking a
> bearing.

### Mini-bosses

**Stonefall Herald** — *mini · Champion · Geo+Astral*
> A lean figure half again the height of a person, its limbs long slabs of
> dark banded rock and its shoulders and forearms crusted with a dense scatter
> of pale points. A narrow wedge-shaped head with no features, tipped back.
> Loose grit and small stones hang in the air around it, caught falling and
> not yet landed. Poised forward on the balls of its feet, one arm already
> raised.

**Bedrock Colossus** — *mini · Redoubt · Geo*
> A vast squat torso and two tree-thick legs, three times the height of a
> person and wider than it is tall at the shoulder, cut from one unbroken mass
> of the darkest, densest stone in the zone — no banding at all, which is the
> point. No head; the shoulders simply end flat. Fine cracks across the chest
> show a dull cold light deep inside. Standing, feet apart, absorbing weight.

**Nadir** — *mini · Executioner · Geo*
> A deep funnel of stone set into the floor, the width of a room at its rim
> and narrowing to a black point, with the rock around it drawn steeply
> inward — and, at the centre of the point, one small unblinking cold white
> light looking straight up. Nothing rises out of it. Sunken, still, and
> aimed.

**The Long Count** — *mini · Hexer · Astral*
> A tall vertical slab of pale stone the height of two people and no thicker
> than a hand, standing free, its whole face covered in dense rows of small
> incised tally-marks running top to bottom in a notation that is not letters
> or numerals. The lowest rows are freshly cut and faintly lit cold white; the
> upper rows are worn almost smooth. A thin crescent of dim silver light rests
> at the top edge. Upright, narrow, still being added to.

### Bosses

**The Overburden** — *boss · Juggernaut · Geo*
> An enormous hunched mass filling the bottom of the shaft, four or five times
> the height of a person, made of the whole column of strata compressed into a
> single stooped shape — bands of stone visibly stacked and bowed through its
> back and shoulders, sagging under their own weight. No head, no face; the
> mass simply thickens where a head would be. A person at its foot reaches the
> knee. Vast, bowed, pressing downward.

**The Buried Constellation** — *boss · Aspect · Astral*
> A single complete figure of pale blue-white points and fine connecting lines
> standing about twice the height of a person, its pattern closed and
> symmetrical with nothing unfinished at its edges — held inside a thin shell
> of dark stone that has cracked open around it and fallen away in plates. The
> points sit slightly *outside* the shell's outline in places, as though the
> figure does not quite occupy the same space as the rock holding it. Upright,
> centred, entirely alight.

---

## The Umbral Wastes · Lv 47–51 · Umbra

> ⭐ *The dark here is deliberate. Something decided its shape.* ⚠️ **Not
> absence — design.** Every silhouette should read as **cut**, not as faded:
> edges clean enough to be a drawing, interiors that swallow light entirely,
> and proportions that are a little too exact for anything that grew. The
> palette is matte near-black against blue-white glacier ice, with one cold
> indigo note and nothing warm anywhere. ⚠️ Nothing here is tattered, nothing
> is decayed, and nothing has a body worth skinning — the dark is *neat*.
> 📝 Deliberately NOT the Old Quarry's silhouette language: there a hole in
> the world is animate and ragged; here a shape was imposed and held.

### Commons

**Umbral Devourer** — *common · Siphon · Umbra*
> A person-sized gap in the air shaped like an open mouth turned side-on,
> matte black and flat, with a clean lipped edge only around the opening and
> no outline at all anywhere else. No body, no limbs, no eyes. The ice behind
> it is visible up to the edge and then simply stops. Hanging upright at
> chest height, opening slightly.

**Edgewalker** — *common · Adept · Umbra*
> A lean hooded human figure the height of a person in close-cut dark grey
> travelling clothes, standing with one boot on lit blue-white ice and the
> other on matte black ground, the dividing line running up the body so that
> exactly half of it is shadowed. Face in shadow under the hood. Mid-stride,
> weight forward, arms loose.

**Considered Ice** — *common · Sentinel · Umbra*
> A standing slab of black ice twice the height of a person and half as wide,
> every face perfectly flat and every corner square, like a cut block rather
> than a frozen one. Faint blue-white refraction shows only at the edges;
> the interior is opaque. No limbs and no face. Planted, motionless.

**Nightspill** — *common · Blighter · Umbra*
> A low spreading sheet of matte black liquid about ankle deep and as wide as
> three people lying end to end, running downhill over pale ice with a clean
> advancing front edge. No head and no limbs, though several thin fingers of
> it reach further ahead than the rest. Flowing forward, low to the ground.

**Thoughtform** — *common · Glasswing · Umbra*
> A person-height humanoid outline drawn in a single crisp black line, with
> the blue-white ice fully visible through the empty interior. No features,
> no thickness, no shading — only the contour, which is unnaturally precise.
> Standing upright, arms slightly away from the sides.

### Mini-bosses

**Umbral Knight** — *mini · Champion · Umbra*
> A suit of full plate armour a head taller than a person, every surface matte
> black with no highlight anywhere, including the pauldrons and helm where
> armour is always bright. Long black surcoat, closed visor with a narrow
> unlit slit. Standing squared, one gauntlet resting on the hilt of a plain
> dark longsword.

**The Edge** — *mini · Redoubt · Umbra*
> A vertical wall of pure black as wide as a mountain pass and as tall as
> four people, perfectly flat, perfectly straight-edged, and visibly only a
> hair thick when seen from an angle. The lit ice runs right up to its base.
> No limbs, no face, no texture. Standing on end, entirely still.

**Void Stalker** — *mini · Executioner · Umbra*
> A lean long-limbed figure half again the height of a person, built of matte
> black with a clean silhouette and no interior detail: narrow shoulders,
> very long arms, a small featureless head. Crouched forward on the balls of
> its feet, one arm reaching low and ahead, mid-stalk.

**Eclipse Weaver** — *mini · Hexer · Umbra*
> A broad flat spider-like body the size of a cart on many thin black legs,
> the legs far longer than the body and bent high above it. Trailing behind it
> is a broad sheet of matte black drawn taut between anchor points on the ice.
> Moving sideways across a slope, body low, legs high.

### Bosses

**Nightbringer** — *boss · Tyrant · Umbra*
> A tall robed figure half again the height of a person, the robe matte black
> and hanging in heavy straight folds with no hem detail, the deep hood
> entirely empty. One long pale-grey hand extended ahead, palm down, fingers
> spread. Walking unhurried; the ice immediately in front of the hand is
> already black.

**What Was Thought About** — *boss · Aspect · Umbra*
> A mass of pure matte black the size of a house holding one exact shape — a
> broad-shouldered seated silhouette with a bowed head — every contour clean,
> symmetrical and obviously chosen, with no surface texture and no light
> falling on it at any point. A thin cold indigo line traces where its outline
> meets the ice. Seated, still, facing the viewer.

---

## The Sealed Garden · Lv 49–53 · Flora + Sanctus

> ⭐ *Still perfect, still guarded, still not allowed in.* ⚠️ **Nothing here is
> ruined and nothing is overgrown** — the beds are kept, the rows are straight,
> the fruit is on the trees and every guardian is exactly where it was put.
> The wrongness is that it has been like this with nobody watching for
> centuries. ⚠️ **The Sanctus naming trap applies to the ART too:** no sun
> discs, no rays, no gold halos — the consecrated things read as *gates,
> orchards, vows and wardens*, in pale stone, white-grey lichen and dull
> silver. Flora reads as deep green, bark-brown, ripe fruit and pale root.
> Palette throughout: green leaf, warm amber, pale grey stone, bark brown, one
> clean white note on the consecrated things. ⚠️ **Everything faces right.**

### Commons

**Orchard Warden** — *common · Sentinel · Sanctus*
> An upright armoured figure of person height in pale weathered grey stone,
> standing at the foot of a single apple tree with the tree directly behind
> it. Dark bark has grown up over both its feet and around its lower legs,
> fixing it in place. Pale grey stone, black bark, one plain white sash across
> the chest with no device on it. Planted, shoulders square, facing right.

**Windfall** — *common · Siphon · Flora*
> A single unbruised apple the size of two fists lying on mown grass, far too
> large for the tree behind it, with a faint upward shimmer of warm air rising
> from its skin. Deep red flushed to gold, flawless, with a short green stem
> and one perfect leaf. No limbs and no face. Resting still, the stem angled
> to the right.

**Whisperling** — *common · Blighter · Flora*
> A small coiled vine-serpent about the length of a forearm, wound twice
> around a high branch with its head lowered toward the viewer, mouth slightly
> open as though mid-sentence. Supple green stem-body with pale leaf-scales
> along its back and two small amber eyes. Coiled, relaxed, head turned right
> and tilted attentively.

**Chorister Vine** — *common · Adept · Flora+Sanctus*
> A thick flowering vine grown into the rough upright shape of a robed singer
> a head taller than a person, its lower half still rooted into a pale stone
> cloister column behind it. Deep green leaf, white five-petalled flowers
> along the shoulders and hood, pale grey column. No face inside the hood.
> Standing upright, hood turned right, mid-phrase.

**Thornpenitent** — *common · Bruiser · Flora+Sanctus*
> A massive briar mass in the unmistakable shape of a kneeling person, broader
> than a person and about as tall kneeling as one is standing, with the briar
> grown through the posture and holding it. Black thorn-wood, dark green
> leaves, and a pale grey-green hide stretched over the shoulders and back
> where the thorns emerge through it from the inside. Kneeling, head bowed,
> turned right.

### Mini-bosses

**The Last Gardener** — *mini · Champion · Flora+Sanctus*
> A human figure of ordinary person height in worn canvas working clothes gone
> the green-brown colour of the beds, standing on a gravel path with a long
> pruning hook held in both hands across the body. Faded canvas, bare
> weathered hands and face, bright clean steel on the hook. Standing at ease,
> weight back, watching to the right.

**Root Matriarch** — *mini · Redoubt · Flora*
> An enormous ancient apple-stock trunk four times the width of a person and
> twice a person's height, hollowed and split at the front into a broad
> vertical opening, with thick roots breaking the turf and running out of
> frame in every direction. Silver-grey furrowed bark, black heartwood inside
> the split, pale exposed root. Immovable, opening turned right.

**Cherub of the Turning Blade** — *mini · Executioner · Sanctus*
> A single straight double-edged sword the length of a person, turning end
> over end in mid-air above a shut pale stone gate, caught mid-rotation and
> blurred into a partial disc by its own speed. Clean white steel; the air
> immediately around the hilt is faintly brighter and faintly denser than the
> air elsewhere, with nothing else visible holding it. ⚠️ **White light, never
> fire** — no flame, no embers, no orange anywhere. Mid-turn, edge sweeping
> toward the right.

**The Kept Vow** — *mini · Hexer · Sanctus*
> An upright person-shaped volume of still white light standing on the path,
> person height, its silhouette clearly a figure with its hands together and
> nothing inside the silhouette at all. Flat even white with soft edges, no
> features, no seams, no garment. Standing motionless, hands joined, facing
> right.

### Bosses

**Guardian of the World Tree** — *boss · Juggernaut · Sanctus*
> A colossal armoured figure four storeys tall in pale grey stone, standing
> squarely in a stone gateway with an enormous tree filling the frame behind
> it, its shoulders wider than the gateway's opening. Pale grey stone,
> black shadow through the gate, deep green canopy above. Blank faceplate, no
> weapon, both hands open and down. Absolutely still, feet planted, facing
> right.

**The Serpent in the Branches** — *boss · Tyrant · Flora*
> An immense green serpent four storeys long draped along and through the
> upper branches of a fruiting tree, most of its length hidden in leaf, its
> head lowered on a long curve to viewer height at the right of the frame.
> Deep green scales with amber banding along the underside, deep green
> canopy, ripe red fruit hanging beside its head. Relaxed, unhurried, head
> turned to face right and slightly toward the viewer.

### Arena backdrop

`assets/backgrounds/the_sealed_garden.png` — *16:9 · Flora + Sanctus palette*
> Wide 16:9 landscape painting seen side-on at standing eye level from
> **outside** a garden wall, environment only — no creatures, no people, no
> text. A low pale dressed-stone wall runs straight across the frame at about
> chest height, low enough to see over and unbroken. Beyond and above it, the
> tops of orchard trees in full deep-green leaf carrying blossom and ripe
> fruit **at the same time**, in even maintained rows receding to the left and
> right. A shut pale stone gate sits just right of centre in the wall, with
> clean straight mown grass paths visible through its bars. The near ground
> below the wall is rough unkept meadow and bare dug earth. Soft flat overcast
> daylight, no visible sun, no rays, no shadows with direction. **Flora +
> Sanctus palette**: deep green leaf, warm amber and ripe red, pale grey
> stone, bark brown, one clean white note on the gate's ironwork. Nothing is
> ruined, nothing is overgrown, nothing is gold or radiant — everything inside
> is kept and nothing outside is.

---

## The Collapsed Academy · Lv 50–54 · Arcane

> ⭐ *It was not destroyed — it was continued past the point where building
> makes sense.* ⚠️ **Over-completion, not ruin**, and every silhouette here
> must say so: nothing is broken, nothing is rubble, nothing is charred.
> Everything is intact, squared, finished to a high standard, and there is
> simply too much of it going in a direction that stopped making sense. Where
> a normal ruin would show a jagged edge, show a clean cut that continues.
> Palette throughout: pale grey-violet planed timber, chalk white, dressed
> pale stone, one cold violet note, and the dull bubbled grey-violet of
> cooled slag. ⚠️ **Nothing here is warm, mossy or weathered** — no ivy, no
> collapse, no smoke.

### Commons

**Unfinished Scholar** — *common · Adept · Arcane*
> A person-height human figure in a plain dark reader's gown with a high
> square collar, standing upright with one arm out at chest height and the
> palm turned up, as if waiting for a page. No lectern, no book, nothing in
> the hand. The face is in deep shadow under a flat academic cap; the gown
> hangs correctly and is entirely undamaged. Squared up, weight even, patient.

**Stairhead** — *common · Bruiser · Arcane*
> The top four treads and the square landing of a staircase, about twice the
> height of a person overall, in pale grey-violet planed timber with dressed
> pale stone risers and a plain squared newel post at one corner. There is no
> lower flight beneath it — the bottom tread simply ends in clean cut air —
> and nothing at all at the top of it. Angled forward as if mid-climb, the
> leading tread slightly raised.

**Chalkwraith** — *common · Skirmisher · Arcane*
> A loose upright drift of chalk dust roughly the height and width of a
> person standing at a board, its edges constantly powdering away and
> re-forming. Dense white at the core, thinning to nothing at the outline,
> with one arm-shaped extension raised to head height and tapering to a
> writing point. No face and no feet; the lower third dissolves into a
> low-hanging haze. Leaning toward the right, poised to mark.

**Marginal Note** — *common · Blighter · Arcane*
> A narrow vertical column of very small dense handwriting, about a hand's
> width across and the full height of a person, standing upright in the air
> with no page, board or wall behind it. Grey-black ink with a faint cold
> violet cast, packed line on line until the block reads as solid. Perfectly
> straight, slightly canted forward at the top, edges ruler-clean.

**Emeritus** — *common · Glasswing · Arcane*
> A very old seated human figure, thin to the point of translucence, in a
> heavy dark reader's gown far too large for the body inside it, on a plain
> high-backed wooden chair. Pale grey-violet skin and white hair; the gown's
> shoulders hold their shape though the frame beneath them does not. Turned
> three-quarters toward the right, chin lifted, hands flat on the knees.

### Mini-bosses

**The Fourth Item** — *mini · Champion · Arcane*
> A single horizontal line of writing about the length of a forearm, hanging
> unsupported at head height, in a formal upright hand. The characters are
> sharp and confident and belong to no readable alphabet; each one throws a
> hard shadow onto nothing. Ink black shading to cold violet toward the end
> of the line, where the letterforms grow slightly larger rather than
> trailing off. Dead level, facing the viewer.

**Mana Golem** — *mini · Redoubt · Arcane*
> A broad seated humanoid mass half again the height of a person, built from
> cooled grey-violet slag in visible poured layers, each flowed over the one
> beneath and hardened glassy at the lip. Bubbled and porous across the
> shoulders, smooth and flowed underneath. Blunt head with no features, arms
> resting on the knees. A dull violet glow sits deep in a seam at the centre
> of the chest. Planted, squat, immovable.

**Arcane Chimera** — *mini · Executioner · Arcane*
> A four-limbed animal about the size of a large hound whose parts visibly do
> not match: three different coats across the body — short grey fur, pale
> scaled hide, and a dark bristled shoulder — two front legs of different
> lengths, and a long narrow head belonging to none of them. Every seam
> between the parts is a clean straight surgical line with fine even
> stitching. Standing low, weight forward, head turned to the right.

**Spell Weaver** — *mini · Hexer · Arcane*
> A tall narrow humanoid figure a head above person height, in close dark
> wrappings, standing at an upright wooden loom taller than itself with both
> arms raised into the warp. Long thin limbs, elongated fingers, a smooth
> featureless oval head. Pale grey-violet cloth pours off the loom's base and
> spreads across the ground past the edge of the frame. Upright, working, in
> mid-motion.

### Bosses

**The Archmage** — *boss · Tyrant · Arcane*
> An old human man of ordinary height in the plain undyed grey working robe
> of a scholar rather than any robe of office — no trim, no chain, no staff.
> Close-cropped white beard, deeply lined face, both hands open and empty at
> waist height. A faint cold violet light sits in the air around the fingers
> of the right hand only. Standing square in the middle of open floor, chin
> level, entirely at ease.

**The Last Three Items** — *boss · Aspect · Arcane*
> Three stacked horizontal lines of writing, each about the width of a
> person's outstretched arms, standing proud of a pale plastered wall far
> enough to cast three hard shadows down it. The same formal hand as the
> syllabus above them, in characters that belong to no readable alphabet and
> grow subtly larger down the stack. Ink black with a cold violet edge-light
> along the top of every stroke. Level, frontal, filling the frame.

---

## The Reliquary Deep · Lv 52–56 · Sanctus + Umbra

> ⭐⭐ *Two hands worked on this, and the second has not finished.* ⚠️ **The
> fusion is made-then-unmade, not light-versus-dark.** Everything Sanctus here
> is finished work — dressed pale stone, gold fittings, folded cream cloth,
> cut to a plan and cut well. Everything Umbra here is what has been done to
> it since: smoke stain, prised fittings, missing gold, a residue where a
> thing stood. ⚠️ **Nothing is ruined and nothing has collapsed** — this is a
> corridor in excellent repair that is being quietly taken apart. Palette:
> pale dressed limestone, soft yellow gold, heavy cream linen, and, against
> them, ceiling-black smoke and a warm red-gold resin note. ⚠️ **It is a
> lamplit interior throughout** — a bored stone corridor, never open sky,
> never ice.

### Commons

**Reliquary Keeper** — *common · Adept · Sanctus*
> A robed humanoid figure of ordinary standing height seen in profile and
> facing right, in heavy undyed cream vestments with a plain gold band at the
> collar. Its face is a smooth featureless oval of the same pale limestone as
> the wall behind it. Standing squared up and steady beside a shallow empty
> wall niche, one hand raised toward the niche and not touching it.

**Censer-Wraith** — *common · Blighter · Umbra*
> An upright column of thick standing smoke about the height of a person,
> wider at the top and drawing down to a thin trailing point at its lower
> end, where it joins a small pierced gold censer hanging on a chain. Dense
> soot-black at the core, thinning to a warm brown-grey at its edges, with
> no face and no limbs. Leaning slowly rightward, still tethered.

**The Unleft** — *common · Glasswing · Umbra*
> A person-shaped void standing upright in a flat sheet of pale floor dust —
> the figure is the *clean* stone, sharp-edged, with undisturbed grey dust
> everywhere around it. Absolutely no interior detail, no colour and no
> surface: the shape is readable only by its edge. Two thin dust-free planes
> trail from its shoulders like half-open wings. Upright, facing right.

**Bone-Reliquary** — *common · Bruiser · Sanctus*
> A gilt wooden casket the length of a tall man, standing on one end and
> walking on the two stubby carrying-poles projecting from its base, its
> heavy lid swung fully back on a single hinge. Warm yellow gold over
> honey-coloured wood, with pale bone visible in neat stacked rows inside the
> open lid. Heavy, tilted forward, mid-stride to the right.

**Corridor Crawler** — *common · Skirmisher · Sanctus+Umbra*
> A low segmented creature about the length of two people lying down, running
> along the join where the wall meets the floor rather than down the middle,
> with many short legs along both sides. Its upper plates are polished pale
> limestone and its underside and legs are matte soot-black, the two meeting
> at a hard line along its flank. Fast, flattened low, head end to the right.

### Mini-bosses

**Antechoir** — *mini · Champion · Sanctus*
> A freestanding half-circle of carved stone choir stalls about twice the
> height of a person, curved inward around an empty central space, walking on
> the stalls' own stone feet with nothing holding the arc together. Pale
> dressed limestone with gold inlay along every armrest; every seat inside
> the curve is empty. Advancing, the open side of the curve turned right.

**Reliquary Colossus** — *mini · Redoubt · Sanctus*
> An enormous rectangular reliquary chest three times the height of a person
> and wide enough to touch both walls, upright, its every face a panelled
> door with a gold lock plate and no handle. Pale limestone panels in a heavy
> gold frame, deeply carved and entirely undamaged. Standing flat and square,
> filling the corridor, advancing slowly to the right.

**The Second Hand** — *mini · Executioner · Umbra*
> A single human arm and shoulder at person scale reaching out of a stone
> wall up to the elbow, the wall closing around it seamlessly with no hole
> and no seam. The visible skin is grey-white stone and the hand itself is
> blackened as if smoke-stained, fingers curled and working. The wall to
> either side of it is stripped bare of its gold in a rough scoured band.

**Warm Middle** — *mini · Hexer · Sanctus+Umbra*
> No body at all: a stretch of corridor roughly thirty paces long in which
> the air itself is visibly shimmering with heat, the stone walls glowing a
> faint dull red from within at the centre of the stretch and fading to
> ordinary cold pale limestone at both ends. Empty floor, empty air, nothing
> standing in it. The hot centre sits right of frame centre.

### Bosses

**What Was Consecrated** — *boss · Juggernaut · Sanctus*
> The far end of the corridor itself advancing as one mass four storeys tall
> — floor, both walls and ceiling together, moving as a single sealed block
> with no gap at any edge. Pale dressed limestone banded horizontally in
> broad soft gold, every surface carved and perfectly intact, with no face,
> no limbs and no opening anywhere in it. Coming forward, filling the frame.

**What Did Not Leave It Alone** — *boss · Tyrant · Umbra*
> A standing humanoid figure four storeys tall assembled out of what it has
> stripped from the corridor: prised gold strips, broken limestone carving
> and torn cream cloth, all bound together with no visible fastening. The
> materials are the walls' own, so it is pale and gold, but every piece of it
> is wrenched, bent or torn at the edges. Upright, head lowered, hands busy
> at its own chest, facing right.

---

## The Unwritten Library · Lv 54–58 · Umbra + Arcane

> ⭐ *It is still writing, and it wants you in it.* The fusion is **authorship
> with no author** — Arcane supplies the writing, Umbra supplies the nobody.
> ⚠️ This zone assigns its element per creature, not "both" by default: the
> written things are Arcane, the empty and absent things are Umbra, and only
> the roster's two hybrids are visibly both. Palette throughout: cream and
> bone-white vellum, dark grey-violet stone, dull black ink, and an
> **absolute** black — not shadow, not shade, but a black with nothing in it
> at all — plus one cold violet note where the writing is happening.
> ⚠️ **Nothing here is ruined, burnt, dusty or cobwebbed.** Everything is
> clean, intact and in use; the place is working, and the only thing missing
> from it is anybody.

### Commons

**The Dictating Hand** — *common · Adept · Umbra+Arcane*
> A bare human forearm and hand floating at head height with nothing above
> the wrist and nothing behind it, holding a plain dark pen and writing on
> air. Pale skin, black ink at the nib, a thin trail of cold violet script
> hanging where the hand has just passed. The cut at the wrist is clean and
> ends in flat absolute black. Turned three-quarters toward the right edge,
> mid-stroke, unhurried.

**Blankspine** — *common · Glasswing · Umbra*
> A single bound book the height of a child, standing upright on its lower
> edge, covers and spine in undyed cream vellum with no title, no tooling and
> no mark of any kind. The covers are parted a finger's width and the visible
> page edges are perfectly clean. The gap between the covers is flat absolute
> black. Balanced on one corner, tilted forward, facing right.

**Footnote** — *common · Lasher · Arcane*
> A low flat band of very small dense handwriting travelling along the floor
> at ankle height, about two people wide and no deeper than a hand, with
> nothing underneath it holding it up. Dull black ink on nothing, packed
> tight, the lines running left to right and breaking into fragments at the
> leading edge. Spilling forward and to the right, never rising.

**Erratum** — *common · Skirmisher · Arcane*
> A single loose slip of cream paper the size of a hand, upright and edge-on,
> travelling fast above the floor with its corners sharp and uncurled. One
> short line of neat cold-violet script across its middle, tidier and
> brighter than anything around it. Angled hard forward, leading corner
> first, facing right.

**Ink-Drinker** — *common · Siphon · Umbra*
> A stooped soft-edged quadruped about the size of a large dog, its body a
> loose dark mass with no visible legs or face, its head end pressed flat
> against a row of book spines. Dull wet black throughout, glossier at the
> head end than the rear. Low to the ground, back arched, side-on and moving
> toward the right.

### Mini-bosses

**The Index** — *mini · Champion · Arcane*
> A freestanding wall of small square card-drawers two people high and twice
> as wide, standing upright with no wall behind it, dozens of its drawers
> sliding part-way out at different depths. Dark waxed wood, dull brass pulls,
> cream card stacked tight inside every open drawer. Squared up and facing
> right, drawers working.

**Colophon** — *mini · Redoubt · Arcane*
> A squat block of dark grey-violet polished stone the height of a person and
> as wide as it is tall, standing on the floor of a hall with nothing
> supporting it. One face is cut smooth and incised with a single small deep
> mark; the other faces are left rough. Motionless, planted, the cut face
> turned toward the right edge.

**Redaction** — *mini · Executioner · Umbra*
> A single hard-edged horizontal bar of absolute black, about as long as a
> person is tall and no thicker than a finger, floating upright at chest
> height with perfectly straight parallel edges and squared ends. No interior
> detail of any kind — flat black with no shading, no texture and no depth.
> Angled slightly forward, mid-travel, moving right.

**The Amanuensis** — *mini · Hexer · Umbra+Arcane*
> A seated stooped figure in plain dark clerk's dress, a head and shoulders
> taller than a person would be standing, hunched over a writing board on its
> knees with a pen in one hand. Dark grey cloth, pale cream page, cold violet
> script already covering it. ⚠️ Where the face would be, under the hood of
> the collar, there is flat absolute black. Writing without looking down,
> turned toward the right.

### Bosses

**The Record** — *boss · Juggernaut · Arcane*
> A run of enormous bound volumes standing shoulder to shoulder across the
> entire width of the frame and rising four storeys, each single volume the
> size of a door, their spines flush and unbroken. Cream vellum and dark
> leather bindings, dull black lettering too small to read at this distance,
> one cold violet line running along the top edge of the run. Upright,
> immovable, receding toward the right without an end in sight.

**The Author** — *boss · Aspect · Umbra*
> Not a body — a four-storey vertical column of absolute black filling the gap
> between two towering shelf ranks, its edges straight where the shelves are
> and softening to nothing above them. No silhouette, no limbs, no face, no
> interior detail whatsoever. The only thing visible inside it is a single
> line of cold violet script writing itself across the black at mid-height,
> reaching the right-hand edge and starting again lower down. Facing right,
> motionless, still writing.

### Arena backdrop

`assets/backgrounds/the_unwritten_library.png` — *16:9 · Umbra + Arcane palette*
> Wide 16:9 landscape painting of a reading hall between two shelf ranks seen
> side-on at standing eye level, environment only — no creatures, no people,
> no legible text. A plain dark stone floor runs straight across the bottom
> third of the frame. To the far left and far right, cropped by the frame, two
> ranks of cream-and-leather bound shelving rise out of the top of the image
> with no ceiling and no visible top, every shelf full and every spine
> unlabelled. Reading tables stand along the near edge with pens laid down
> and pages half-covered. The centre of the frame is the **gap between the
> ranks**: absolute black, edge to edge, floor to top, with one cold violet
> line of script hanging in it at mid-height. Even, sourceless light on the
> shelving; no lamps, no windows, no shadows cast. **Umbra + Arcane palette**,
> matching the creatures above: cream vellum, dark leather, grey-violet stone,
> dull black ink, absolute black, one cold violet note. Nothing ruined,
> nothing dusty, nothing burnt — everything clean, intact and in use, and
> nobody in it.

---

## The Eclipsed Citadel · Lv 58–60 · all twelve

> ⭐ *The last thing in the way.* ⚠️ **Not a place — an obstruction.** Every
> silhouette here should read as something **between** the viewer and something
> else: a shape that occludes rather than occupies. Nothing is ruined, nothing
> is monstrous, and nothing is decorative — this is architecture and staff, both
> still doing the job. Palette: black stone and black iron, cold white edge
> light, one warm gold note reserved for the corona, and a single element accent
> per creature. ⚠️ **The zone carries all twelve elements, so the accent is the
> ONLY thing that says which** — build each creature out of the same black-and-
> white material and let the accent do the work, or eleven creatures will read
> as one creature.

### Commons

**The Held Door** — *common · Sentinel · Geo+Flora*
> A single slab door of dark grey stone the height of two people, standing
> upright in its own frame with nothing around the frame, seam sealed down the
> middle. Green root has grown into that seam and through it, thick pale
> tendrils holding the two halves together rather than prying them apart.
> Motionless, square, perfectly shut.

**Ashlight** — *common · Blighter · Pyro+Umbra*
> A waist-high sconce of black iron with a fire burning in its cup, and the
> fire is ordinary orange flame that casts no light on anything — the stone
> around it stays black and the air above it carries grey smoke. It leans
> forward on a single spindly bracket like something craning. Hot, smoking,
> utterly unlit.

**The Kept Watch** — *common · Bruiser · Sanctus+Solar*
> A broad armoured figure a head taller than a person, in full dull-white plate
> gone grey with dust, halberd grounded and both hands on it. Its helm is turned
> hard over one pauldron to look at you while its body still faces the other
> way. Planted, square-footed, mid-turn and hating it.

**Nightcurrent** — *common · Lasher · Lunar+Electro*
> A loose fan of a dozen pale blue-white filaments running down from the ceiling
> ironwork to the floor, each one thin as wire and each one taut, spread across
> about the width of a corridor. No body holds them together. Vertical,
> travelling, arriving all at once.

**The Last Applicant** — *common · Adept · Aqua+Aero+Astral+Arcane*
> A stooped figure of ordinary human size in a travel-worn hooded robe, pack
> still on, one hand out flat as if partway through explaining something. Four
> small mote-lights of different colours orbit slowly at its shoulder. Standing
> square, patient, facing you directly.

### Mini-bosses

**The Basin** — *mini · Champion · Flora+Aqua+Pyro*
> A broad-shouldered figure twice the height of a person built out of packed
> wet earth, river stone and living green, with a slow ember glow deep in the
> chest cavity. Its arms end in blunt fists of root-bound clay. Upright,
> forward-leaning, weight already committed.

**The Range** — *mini · Redoubt · Geo+Electro+Aero*
> A long low wall of stacked dark stone three times the width of a person and
> twice their height, standing free with no ends — it simply stops. Thin blue
> arcs crawl between its courses and a constant flat wind pushes off its face.
> Broadside on, motionless, entirely in the way.

**The Shelf** — *mini · Executioner · Solar+Lunar+Astral*
> A flat rectangular plane of nothing standing on edge, person-width and twice
> person-height, its face a cold starless dark and its four edges lit hard white
> like a blade held up to a window. Nothing occupies its far side. Upright,
> edge-on, razor-thin from the side.

**The Climb** — *mini · Hexer · Sanctus+Umbra+Arcane*
> A steep face of black rock filling the frame from bottom to top, with a
> hunched humanoid shape about the size of a person picked out in it — knees
> under chin, one arm reaching upward — visible only where the pale gold and
> violet veining outlines it. Looming, overhead, going on past the top edge.

### Bosses

**Totality** — *boss · Juggernaut · All twelve*
> An enormous smooth black form four times the height of a person, filling a
> doorway from jamb to jamb with no gap anywhere around it, its surface flat
> matte dark that takes no highlight at all. A thin, hard, continuous ring of
> white light stands off its whole outline. Dead centre, motionless, total.

**Procarius, the Eclipsed** — *boss · Tyrant · Arcane+Umbra+Lunar+Electro+Pyro*
> A tall, spare man in dark layered robes with violet trim, hood down, hands
> loose at his sides, standing alone with nothing behind him but black. A narrow
> band of shadow crosses his eyes at exactly the height a crown would sit.
> Upright, still, waiting without any impatience at all.

---

## ✅ Written — all 286 creatures

Every creature in the game has a description here. The **Primal quarter (55)**,
the **Kinetic quarter (66)**, the **Celestial quarter (77)** and the
**Ethereal quarter plus The Eclipsed Citadel (88)** are all written, and
`Bestiary.all` is 286 — `test/creature_art_test.dart` compares the two sets in
both directions, so a creature added, renamed or cut without a description
here fails immediately.

📝 **This file is the single source again.** The Celestial/Ethereal wave staged
its fifteen zone blocks in `docs/art/bestiary/<zone_id>.md`, because fifteen
worktrees editing one shared document is fifteen conflicts. Those files were
folded in above and deleted on 2026-09-22, and the test no longer reads that
directory. ⚠️ A future wave may stage the same way — but the staging directory
is temporary by construction, and leaving it in place is how a description
ends up in two places that disagree.

| Quarter | Zones | Creatures | Descriptions | Backdrop briefs |
|---|---|---|---|---|
| **Primal** 1–14 | 5 | 55 | ✅ | ✅ 5 |
| Kinetic 15–29 | 6 | 66 | ✅ | ✅ 6 |
| Celestial 30–47 | 7 | 77 | ✅ | 📝 1 of 7 (The Glass Archive) |
| Ethereal 45–58 | 7 | 77 | ✅ | 📝 3 of 7 (Hallowmarch, The Sealed Garden, The Unwritten Library) |
| The Eclipsed Citadel 58–60 | 1 | 11 | ✅ | ⬜ |

⚠️ **Backdrops are the half that is still short.** Eleven of the fifteen new
zones have no `### Arena backdrop` entry yet, so their arena background files
have nothing to be generated from. `test/creature_art_test.dart` only requires
a brief for the zones listed in its `_primalZones`, which is exactly the set
whose asset directories are declared in pubspec — so the gap is real but
silent, and it is tracked in IMPLEMENTATION_PLAN's zone matrices and pinned by
name in `tool/test_artgen.py`'s `ZONES_WITH_BACKDROP`.

📝 **No PNG exists for any of the fifteen new zones**, and none is expected
yet: `assets/creatures/<zone>/` is declared in pubspec only for the eleven
zones in `_primalZones`, and the art pipeline runs a quarter at a time. Every
creature in the new quarters draws the elemental silhouette until its sprite
lands.

⭐ **The Primal quarter is still the one that matters first** — it is the
player's first impression, and Whispering Woods' eleven sprites are the only
creature art that has shipped anywhere in the game.
