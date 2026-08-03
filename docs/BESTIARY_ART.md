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

Each entry is written so it can be pasted straight into an image generator
without editing. They deliberately state **form, scale, material, colour and
posture**, because those are what a generator gets wrong when left to guess.

⭐ **A house style, so the set looks like one bestiary:** a naturalist's field
plate — creature isolated on a plain ground, full body, side-on or
three-quarter, even light, no scenery, no action pose, no text. That framing
also matches the game's own voice: these are observations, not portraits.

⚠️ **No in-game bitmaps.** Every visual in the game is a `CustomPainter`
(README §4). Generated images are **concept reference** for painter recipes —
if that ever changes, it is a real decision, not a detail.

⚠️ **Scale is stated in every entry** because it is the single thing a
generator most reliably ignores, and a knee-high sprite drawn at bear size
makes a level-1 zone read as a level-40 one.

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
> monstrous. Arms at its sides. Standing, facing the viewer.

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

---

## ⚠️ Still to describe — 220 creatures

Only the **Primal quarter (55)** is written. The Kinetic, Celestial and
Ethereal quarters have full rosters in ENEMIES_DESIGN §2e — names, ranks,
archetypes and premises — but no physical descriptions yet.

| Quarter | Zones | Creatures | Status |
|---|---|---|---|
| **Primal** 1–14 | 5 | 55 | ✅ described |
| Kinetic 15–29 | 6 | 66 | ⬜ |
| Celestial 30–47 | 7 | 77 | ⬜ |
| Ethereal 45–60 | 7 | 77 | ⬜ |
| The Eclipsed Citadel | 1 | ❓ | needs its own structure first (§2e) |

⭐ **The Primal quarter is the one that matters first** — it is the only
content built, and it is the player's first impression.
