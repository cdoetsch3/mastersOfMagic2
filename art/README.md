# Art

Source images and the palettes the pipeline locks them to. ⚠️ **Nothing here
ships** — `tool/pixelate.py` reads this directory and writes to `assets/`.

```
art/
  prompts/      paste-ready prompts, generated from the design docs
  source/
    <zone>/     one image per creature, named after its EnemyDef id
    backgrounds/  one image per zone, named after its zone id
  palettes/     one per element, generated from lib/game/element_style.dart
```

## Creatures

Prompts: [prompts/whispering_woods.md](prompts/whispering_woods.md).
Descriptions come from [../docs/BESTIARY_ART.md](../docs/BESTIARY_ART.md).

```sh
python3 tool/pixelate.py --zone whispering_woods --element flora --cutout
```

⭐ **128×128 by default.** 64 was the first guess and it lost the Listening
Fawn's root legs and lowered head entirely. `--size` overrides it.

⭐ **Every palette carries a neutral ramp as well as its element ramp.** A
single-hue palette destroys material contrast — the Fawn is birch-white bark
under green moss, and against a Flora-only ramp both collapsed into the same
green. The neutral ramp is what lets bark, bone, stone and ash survive while
the element hue still says which zone you are in.

⚠️ **Generate on flat magenta and use `--key`.** It is an exact colour match,
so it is lossless on the subject and thin structures survive.

⚠️ **`--cutout` is the fallback and it GUESSES.** `rembg` is a segmentation
model; against the low-contrast grey background an earlier prompt asked for, it
removed the Hollow Stag's antlers entirely and nothing downstream could recover
them. Use it only for art with no keyable background.

⭐ **The pipeline also stretches each subject's own tonal range** before
quantising, measured over opaque pixels only. A flatly-lit generation occupies
a narrow band of values, and quantising that directly throws away most of the
palette — which is what "the pixelate process removed details" actually was.

## Backgrounds

Prompts: [prompts/backgrounds.md](prompts/backgrounds.md), generated from each
zone's `arrival` text in `lib/game/world.dart`.

```sh
python3 tool/pixelate.py --zone whispering_woods --mode background
```

⭐ **26 backdrops against 275 creatures** — far less work for arguably more
visual impact, since the background is most of the screen.

⚠️ **A background must lose to the sprites.** The mode darkens and desaturates
on top of what the prompt already asks for; measured, a backdrop comes out at
roughly **55% of the source's mean luminance**. The failure mode is a beautiful
backdrop that makes the creature standing on it unreadable.

## Regenerating the prompts

⚠️ Both prompt files are **generated**, and say so at the top. Edit the source —
`docs/BESTIARY_ART.md` for creatures, `world.dart` for backgrounds — and
regenerate, or the two copies drift and nobody knows which is current.
