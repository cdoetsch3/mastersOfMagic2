# Art

Source images and the palettes the pipeline locks them to. ⚠️ **Nothing here
ships** — `tool/pixelate.py` reads this directory and writes to `assets/`.

```
art/
  prompts/      paste-ready prompts, generated from the design docs
  source/
    <zone>/     one image per creature, named after its EnemyDef id
    backgrounds/  one image per zone, named after its zone id
    items/
      <zone>/   one image per item, named after its ItemDef id
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

## Item icons

Descriptions: [../docs/ITEM_ART.md](../docs/ITEM_ART.md) — which is written to
be pasted straight in, so ⭐ **there is no generated `prompts/items.md`**. The
per-entry paragraph plus the shared style preamble at the top of that file is
the whole prompt, and a second copy would be one more thing to drift.

```sh
python3 tool/pixelate.py --zone whispering_woods --mode icon
```

⭐ **64×64, and nothing done to it but quantising.** No element remap (a Flora
zone's catalogue holds copper ore and black glass), no darken/desaturate (an
icon shown at 14px on the duel's belt rail needs every scrap of contrast it
has). ⚠️ **No `--cutout` either** — the shared style preamble asks for one
object on a plain dark ground, so the mode square cover-crops rather than
trimming to alpha.

⭐ **52 icons for the Primal quarter**, in five zone folders matching
`ItemCatalogue.byZone`. Every stem must be a real item id in the right zone;
`test/item_icon_test.dart` fails the suite if one is not.

## Regenerating the prompts

⚠️ Both prompt files are **generated**, and say so at the top. Edit the source —
`docs/BESTIARY_ART.md` for creatures, `world.dart` for backgrounds — and
regenerate, or the two copies drift and nobody knows which is current.
