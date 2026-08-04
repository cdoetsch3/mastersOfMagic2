# Image prompts — Whispering Woods

⭐ **Paste-ready.** Each block is a complete prompt: house style plus that
creature's description.

## ⚠️ Generate on a FLAT MAGENTA background

The style line asks for pure `#FF00FF`, and that is load-bearing.

⚠️ **This replaces an earlier "plain mid-dark background", which cost real
art.** Background removal was being done by `rembg`, a segmentation model that
guesses — and against a low-contrast grey it **removed the Hollow Stag's
antlers entirely**, branches, leaves and all. The sprite shipped as a stag with
a bare head and nothing in the pipeline could recover it.

⭐ **Magenta cannot be confused with anything in a forest bestiary**, so the
background comes off with an exact colour key instead of a guess — lossless on
the subject, and thin structures survive. ⚠️ **White would not do**: the
Listening Fawn is birch-white, and a white key would eat its body.

**Generate at 1024×1024 or larger.** Save under the id in each heading, into
`art/source/whispering_woods/`, then:

```sh
python3 tool/pixelate.py --zone whispering_woods --element flora --key
```

⚠️ `--key` for magenta art. `--cutout` is the old `rembg` path and remains only
for art generated without a keyable background — it is the one that ate the
antlers.

⚠️ Descriptions come from [../../docs/BESTIARY_ART.md](../../docs/BESTIARY_ART.md).
Edit them there and regenerate this file, or the two drift.

---

## Listening Fawn

`listening_fawn.png` — *common · Drudge · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A deer-shaped creature the size of a large dog, woven from pale root and birch bark rather than flesh. Its legs are bundled rootlets; its joints bend like green wood. It has no eyes and no mouth - the head is a smooth knot of grain, tilted downward, with two long leaf-shaped ears angled at the ground. Moss over the shoulders. Standing still, head lowered, listening.
```

## Thornback Sprite

`thornback_sprite.png` — *common · Skirmisher · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A knee-high humanoid of tangled green briar, wiry and hunched, with long thin arms. A ridge of black thorns runs from the crown of its head down its spine. Small, dark, wet-looking eyes set deep in a face of woven stems. Caught mid-stride, low to the ground, as if about to bolt sideways.
```

## Sporecap Shambler

`sporecap_shambler.png` — *common · Blighter · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A slumped, roughly man-shaped mass of decaying wood and leaf litter, waist to chest height, walking on knuckles. Its whole back and shoulders are crowded with pale grey-brown mushroom caps of varying size, the largest split and leaking a fine dust. No visible face. Damp, dark, crumbling at the edges.
```

## Bindweed Creeper

`bindweed_creeper.png` — *common · **Siphon** · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A writhing knot of pale green vine about the size of a curled dog, moving as a single mass with no head. White trumpet-shaped flowers open along its length. The vine tips are fine, pink and rootlike, and they end in small sucking mouths - the one detail that must read clearly, because it is what the creature does.
```

## Rootknuckle

`rootknuckle.png` — *common · Bruiser · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A single enormous fist of braided tree root, roughly the size of a cow, punched up out of the soil and balanced on the wrist. Wet black earth still clinging in the crevices. Four thick knuckle-ridges of hard grey bark. No face, no eyes - it is a limb, not a body, and there is nothing above it.
```

## Elderroot

`elderroot.png` — *mini · Champion · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A broad, low creature the size of a bull, built from one ancient root system lifted clear of the ground and walking on six thick tapering legs. Deeply fissured grey bark. Where a head would be there is a dense woven crown of smaller roots, and inside it a single dull amber knot like a clouded eye.
```

## Mother Spore

`mother_spore.png` — *mini · Redoubt · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A vast pale fungal dome, twice the height of a person and wider than it is tall, sitting flush against the forest floor. Its surface is soft, slightly luminous, and rippling like a lung. A skirt of thick white gills underneath. Small mushroom growths cluster around its base like offspring.
```

## Hollow Stag

`hollow_stag.png` — *mini · Executioner · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A full-grown stag standing tall as a horse, its body a hollow shell of silver-grey bark with the whole ribcage open and empty - you can see the forest through it. Its antlers are living branches still in leaf. It moves with the poise of a real deer, which is worse.
```

## The Murmur

`the_murmur.png` — *mini · Hexer · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. Barely a body: a person-sized column of hanging root-hair and grey-green moss suspended just clear of the ground, drifting. Within the tangle, dozens of small dark hollows like open mouths at different heights. It should look like something you would only notice because it made a sound.
```

## Heartwood

`heartwood.png` — *boss · Juggernaut · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. An enormous ancient tree that has pulled itself half out of the earth, four storeys tall, walking on a splayed mass of root. Its trunk is split vertically into a deep vertical cleft lined with pale, wet, living wood. The canopy is full and healthy. Everything below the canopy is a wound.
```

## The Standing Green

`the_standing_green.png` — *boss · Aspect · Flora*

```
Digital illustration in the style of a naturalist's field plate. The creature is isolated on a COMPLETELY FLAT, SOLID, PURE MAGENTA background (hex #FF00FF) - a chroma key backdrop. Absolutely no scenery, no ground, no shadow cast on the background, no gradient, no vignette, no text, no border. Full body, three-quarter view, neutral standing pose, even diffuse lighting. Every part of the creature fully inside the frame, including thin extremities like antlers, horns and tendrils. Clear readable silhouette, strong value contrast between the creature and the magenta. Muted natural palette dominated by greens and bark browns. A human figure, slightly too tall and slightly too thin, grown entirely from living plants - the proportions right, the posture right, the stillness wrong. Face smooth and featureless, grass and small white flowers where hair would be. Unsettling because it is nearly correct, not because it is monstrous. Arms at its sides. Standing, facing the viewer.
```
