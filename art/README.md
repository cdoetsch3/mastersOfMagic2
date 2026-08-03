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

⚠️ **`--cutout` unless the art already has a transparent background.** A
generator returns a scene; the pipeline's trim and composite assume the
background is gone, so without it the scenery gets pixelated too.

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
