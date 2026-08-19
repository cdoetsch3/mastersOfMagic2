#!/usr/bin/env python3
"""Turn generated artwork into game-ready creature sprites.

    python3 tool/pixelate.py --zone whispering_woods --element flora --cutout
    python3 tool/pixelate.py --zone whispering_woods --mode background
    python3 tool/pixelate.py --zone whispering_woods --mode icon

**Creature mode** (default) reads `art/source/<zone>/`, and writes a small,
palette-locked sprite per creature to `assets/creatures/<zone>/`.

**Background mode** reads `art/source/backgrounds/<zone>.*` and writes one wide
arena backdrop to `assets/backgrounds/`.

**Icon mode** reads `art/source/items/<zone>/` and writes one 64x64 item icon
per file to `assets/items/<zone>/`, named for the item id. Prompts:
`docs/ITEM_ART.md`.

📝 **`tool/artgen.py` is the front door**, and it calls every mode below with
the right flags after fetching the source art from an image API. This file
stays usable on its own — hand-made or hand-downloaded art still goes through
exactly these three modes — and remains the only place the picture maths lives.

⭐ **An icon is neither a creature nor a background, and gets neither
treatment.** No element remap: a Flora zone's catalogue contains copper ore and
black glass, and locking them to a green ramp would make the icon set lie about
what the objects are. No darken/desaturate either: a backdrop is pushed back
because it must lose to the sprites, but an icon shown at 14px on the duel's
belt rail has the opposite problem and needs every scrap of contrast it has.
⚠️ Square **cover**-crop rather than the creature path's alpha-trim — the
descriptions ask for one centred object on a plain ground, so there is nothing
to trim to and letterboxing an icon inside its slot reads as a bug.

⭐ **A background must LOSE to the sprites.** It is most of the screen, so the
temptation is to make it beautiful — but creature legibility is what the fight
depends on. Background mode therefore darkens and desaturates deliberately, and
uses a wider palette than a creature (a scene posterises into bands at 16
colours) without locking to one element hue.

⚠️ **Pass `--cutout` for artwork with a background.** Generators usually return
a scene, not a subject — a forest behind the creature, a floor beneath it. The
alpha-driven trim and composite below assume the background is already gone, so
without this the trees get downsampled along with the fawn. Needs `rembg`:

    python3 -m pip install --user rembg onnxruntime

Why each step is the way it is
------------------------------
⭐ **The point is coherence, not compression.** Generated images never look
like one game; remapping every creature in a zone onto one element palette is
what makes them a set.

⚠️ **Area-average downsampling, never nearest-neighbour.** Nearest-neighbour
samples one pixel out of every block, so noise and antialiasing survive as
speckle. Averaging first, then quantising, gives the flat blocks pixel art
depends on.

⚠️ **Dithering off, everywhere.** At 64px a dither pattern reads as dirt and
destroys the flat colour regions that make a sprite legible.

⚠️ **Alpha is handled separately from colour.** Quantising an image with a
transparent background pulls background pixels into the palette and leaves a
halo. The alpha channel is lifted out first, thresholded, and put back last.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

try:
    import numpy as np
    from PIL import Image
except ImportError:
    sys.exit("needs Pillow and numpy:  python3 -m pip install --user Pillow numpy")

ROOT = pathlib.Path(__file__).resolve().parent.parent
STYLE = ROOT / "lib" / "game" / "element_style.dart"
PALETTE_DIR = ROOT / "art" / "palettes"
SOURCE_DIR = ROOT / "art" / "source"
OUT_DIR = ROOT / "assets" / "creatures"
BG_OUT = ROOT / "assets" / "backgrounds"
ICON_OUT = ROOT / "assets" / "items"

# ⚠️ **128, not 64.** 64 was the first guess and it was too small — measured on
# the Listening Fawn, the root legs and the lowered head both dissolved. 128
# keeps them and still reads as deliberate pixel art rather than a blurry
# photo. Costs about 11 KB a sprite, so ~3 MB for the whole 275-creature
# bestiary, which is nothing next to the 37 MB of canvaskit.
DEFAULT_SIZE = 128

# ⭐ Wide, and small enough to still read as pixel art when scaled up behind
# the arena. 16:9 so it fits the duel screen without cropping.
BACKGROUND_SIZE = (384, 216)

# A scene needs more than a creature's 16 — fewer and skies band badly.
BACKGROUND_COLOURS = 28

# ⭐ **64, not the creature's 128.** An icon is shown between 14px (the duel's
# belt rail) and roughly 40px (a backpack tile), so 128 would be four times the
# pixels anyone ever sees — and 52 icons at 64px is about 130 KB for the whole
# Primal quarter. ⚠️ Square, because every slot that shows one is square.
ICON_SIZE = (64, 64)

# ⭐ Between a creature's 16 and a scene's 28. An icon is one object with a
# small number of materials, and a tight palette is what makes fifty-two
# separately generated pictures read as one set.
ICON_COLOURS = 20

# ⚠️ How far a background is pushed back. Both deliberate: without them a good
# backdrop makes the creature standing on it unreadable.
BACKGROUND_DARKEN = 0.42
BACKGROUND_DESATURATE = 0.45

# ⚠️ How hard the element hue is pushed. Above 1.0 = more saturated than the
# element's own UI colour — deliberate, because the hue ramp is competing with
# neutrals for the same mid-tones and loses at 1.0.
ELEMENT_SATURATION = 1.6

# ⚠️ Anything below this alpha becomes fully transparent. Soft edges at this
# scale read as grime, not as antialiasing.
ALPHA_CUTOFF = 128


def cut_out(img: "Image.Image") -> "Image.Image":
    """Removes the background, leaving the subject on alpha.

    ⚠️ Optional and lazily imported — `rembg` pulls in onnxruntime and a model
    download, which is a lot to force on someone whose art already has alpha.
    """
    try:
        from rembg import remove
    except ImportError:
        sys.exit(
            "--cutout needs rembg:\n"
            "  python3 -m pip install --user rembg onnxruntime\n"
            "Or remove the background yourself and drop the flag."
        )
    return remove(img)


# ---- palettes ------------------------------------------------------------


def element_colours() -> dict[str, tuple[int, int, int]]:
    """The twelve element colours, read from element_style.dart.

    ⭐ Parsed rather than copied so the sprites cannot drift from the colours
    the rest of the game uses.
    """
    text = STYLE.read_text()
    out: dict[str, tuple[int, int, int]] = {}
    for name, hexcode in re.findall(
        r"MagicElement\.(\w+):\s*(?:const\s*)?ElementStyle\(\s*Color\(0x[0-9A-Fa-f]{2}"
        r"([0-9A-Fa-f]{6})\)",
        text,
    ):
        out[name] = tuple(int(hexcode[i : i + 2], 16) for i in (0, 2, 4))
    if not out:
        sys.exit(f"could not parse any element colours from {STYLE}")
    return out


def _saturate(rgb: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    """Pushes a colour away from its own grey.

    ⭐ Around the colour's own luminance, so it gets more colourful without
    getting lighter or darker — which would shift where it lands in the ramp.
    """
    lum = 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]
    return tuple(
        int(max(0, min(255, round(lum + (c - lum) * amount)))) for c in rgb
    )


def build_ramp(
    rgb: tuple[int, int, int],
    steps: int,
    shadow: tuple[int, int, int] = (18, 14, 26),
    light: tuple[int, int, int] = (255, 250, 240),
) -> list[tuple[int, int, int]]:
    """A dark-to-light ramp through one colour.

    ⭐ Not a rainbow. A ramp is one hue's tonal range — that is what makes a
    limited palette read as lighting rather than as posterisation.
    """
    ramp: list[tuple[int, int, int]] = []
    half = steps // 2
    for i in range(half):  # shadow -> colour
        t = i / half
        ramp.append(tuple(round(shadow[c] + (rgb[c] - shadow[c]) * t) for c in range(3)))
    for i in range(steps - half):  # colour -> light
        t = i / (steps - half)
        ramp.append(tuple(round(rgb[c] + (light[c] - rgb[c]) * t) for c in range(3)))
    return ramp


def write_palettes(size: int = 24) -> dict[str, list[tuple[int, int, int]]]:
    """One palette per element: an element ramp PLUS a neutral ramp.

    ⚠️ **A single-hue palette destroys material contrast**, and that was not
    obvious until real art went through it. The Listening Fawn is birch-white
    bark under green moss; against a Flora-only ramp both collapsed into the
    same green and the creature read as one flat colour.

    ⭐ The neutral ramp is what lets bark, bone, stone, ash and snow survive
    while the element hue still says which zone you are in.
    """
    PALETTE_DIR.mkdir(parents=True, exist_ok=True)
    # A warm-grey ramp: bark and bone, never a pure neutral, so it sits with
    # the element rather than looking like a different image.
    #
    # ⚠️ **Do NOT tint this toward the element.** Tried at 35% and it made the
    # zone read as LESS green, not more: once the bark is greenish too, the
    # moss has nothing to contrast against and the element stops registering.
    # The contrast between neutral and hue is what makes the hue visible.
    NEUTRAL = (168, 158, 148)
    palettes = {}
    for name, rgb in element_colours().items():
        # ⭐ Saturate the element ramp instead. The source art is mostly
        # desaturated bark and bone, so an unboosted hue ramp gets out-competed
        # by the neutrals during quantisation and the greens go quiet.
        hue = build_ramp(_saturate(rgb, ELEMENT_SATURATION), steps=size - 8)
        neutral = build_ramp(NEUTRAL, steps=6, shadow=(24, 22, 28))
        full = [(10, 8, 14)] + hue + neutral + [(255, 255, 255)]
        img = Image.new("RGB", (len(full), 1))
        img.putdata(full)
        img.save(PALETTE_DIR / f"{name}.png")
        palettes[name] = full
    return palettes


# ---- the pipeline --------------------------------------------------------


def to_sprite(
    src: pathlib.Path,
    palette: list[tuple[int, int, int]],
    size: int,
    cutout: bool = False,
) -> Image.Image:
    img = Image.open(src).convert("RGBA")

    if cutout:
        img = cut_out(img).convert("RGBA")

    # ⚠️ Alpha first, and kept out of the colour maths entirely.
    alpha = img.getchannel("A")

    # Trim to content, so every creature fills its box rather than floating
    # wherever the generator happened to put it.
    box = alpha.point(lambda a: 255 if a >= ALPHA_CUTOFF else 0).getbbox()
    if box:
        img = img.crop(box)
        alpha = alpha.crop(box)

    # Fit inside a square, preserving aspect. ⭐ Box filter = area average.
    w, h = img.size
    scale = size / max(w, h)
    small = (max(1, round(w * scale)), max(1, round(h * scale)))
    img = img.resize(small, Image.BOX)
    alpha = alpha.resize(small, Image.BOX)

    # Harden the edge before quantising, or the palette learns the halo.
    alpha = alpha.point(lambda a: 255 if a >= ALPHA_CUTOFF else 0)

    # Remap colour onto the element palette. ⚠️ dither=NONE.
    pal_img = Image.new("P", (1, 1))
    flat = [c for rgb in palette for c in rgb]
    flat += [0] * (768 - len(flat))
    pal_img.putpalette(flat)
    quantised = img.convert("RGB").quantize(palette=pal_img, dither=Image.Dither.NONE)

    out = quantised.convert("RGBA")
    out.putalpha(alpha)

    # Centre in a square canvas so every sprite aligns in the UI.
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(out, ((size - small[0]) // 2, (size - small[1]) // 2), out)
    return canvas


def cover_crop(img: "Image.Image", size: tuple[int, int]) -> "Image.Image":
    """Fills [size] exactly, cropping the overflow off the centre.

    ⭐ Cover, never contain — letterboxing a backdrop or an icon inside its own
    slot looks like a bug rather than a framing choice. ⚠️ `Image.BOX` is the
    area average the whole file depends on; see the module docstring.
    """
    tw, th = size
    scale = max(tw / img.width, th / img.height)
    img = img.resize(
        (max(1, round(img.width * scale)), max(1, round(img.height * scale))),
        Image.BOX,
    )
    left = (img.width - tw) // 2
    top = (img.height - th) // 2
    return img.crop((left, top, left + tw, top + th))


def to_background(src: pathlib.Path, size: tuple[int, int]) -> Image.Image:
    """A wide, dimmed, quantised arena backdrop.

    ⚠️ No element remap. A scene is many hues; forcing it through one ramp
    turns a forest into a green smear.
    """
    img = cover_crop(Image.open(src).convert("RGB"), size)

    # ⭐ Push it back BEFORE quantising, so the palette is chosen from the
    # colours that will actually be shown rather than the bright originals.
    px = np.asarray(img).astype(np.float32)
    grey = px.mean(axis=2, keepdims=True)
    px = px + (grey - px) * BACKGROUND_DESATURATE
    px = px * (1.0 - BACKGROUND_DARKEN)
    img = Image.fromarray(px.clip(0, 255).astype(np.uint8), "RGB")

    return img.quantize(
        colors=BACKGROUND_COLOURS,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")


def to_icon(src: pathlib.Path, size: tuple[int, int]) -> Image.Image:
    """One square item icon, quantised and nothing else.

    ⚠️ **Deliberately the shortest path in this file.** No element remap (a
    Flora zone yields copper ore), no darken/desaturate (an icon at 14px needs
    all the contrast it has), no alpha handling (the shared style preamble in
    docs/ITEM_ART.md asks for one object on a plain dark ground, so there is
    nothing to cut out). Every one of those is a step the other two modes need
    and this one would be actively harmed by.
    """
    img = cover_crop(Image.open(src).convert("RGB"), size)
    return img.quantize(
        colors=ICON_COLOURS,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")


def run_icons(zone: str, size: tuple[int, int]) -> None:
    src_dir = SOURCE_DIR / "items" / zone
    if not src_dir.is_dir():
        sys.exit(
            f"no source art at {src_dir}\n"
            f"  Put generated images there, named after the ITEM id "
            f"(oak_log.png, heartwood_stave.png, ...).\n"
            f"  Prompts: docs/ITEM_ART.md\n"
            f"  Or let the generator fetch them: "
            f"python3 tool/artgen.py --zone {zone} --kind icons"
        )
    out_dir = ICON_OUT / zone
    out_dir.mkdir(parents=True, exist_ok=True)
    sources = sorted(
        f
        for f in src_dir.iterdir()
        if f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    )
    w, h = size
    for src in sources:
        # ⭐ Always .png out, whatever went in — the ITEM id is the stem, and
        # `test/item_icon_test.dart` fails the build if one is not a real id.
        dst = out_dir / f"{src.stem}.png"
        to_icon(src, size).save(dst)
        print(f"  {src.name} -> {dst.relative_to(ROOT)}  ({w}x{h})")
    print(f"\n{len(sources)} icons for {zone}")
    if not sources:
        print("⚠️  nothing to do — the source directory is empty")


def run_backgrounds(zone: str) -> None:
    src_dir = SOURCE_DIR / "backgrounds"
    matches = [
        f
        for f in sorted(src_dir.glob(f"{zone}.*"))
        if f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    ] if src_dir.is_dir() else []
    if not matches:
        sys.exit(
            f"no backdrop at {src_dir}/{zone}.png\n"
            f"  Prompts: the `### Arena backdrop` entry in docs/BESTIARY_ART.md\n"
            f"  Or let the generator fetch it: "
            f"python3 tool/artgen.py --zone {zone} --kind backdrop"
        )
    BG_OUT.mkdir(parents=True, exist_ok=True)
    dst = BG_OUT / f"{zone}.png"
    to_background(matches[0], BACKGROUND_SIZE).save(dst)
    w, h = BACKGROUND_SIZE
    print(f"  {matches[0].name} -> {dst.relative_to(ROOT)}  ({w}x{h})")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--zone", required=True, help="e.g. whispering_woods")
    ap.add_argument(
        "--mode",
        choices=["creature", "background", "icon"],
        default="creature",
    )
    ap.add_argument("--element", help="e.g. flora — creature mode only")
    ap.add_argument("--size", type=int, default=DEFAULT_SIZE)
    ap.add_argument(
        "--cutout",
        action="store_true",
        help="strip the background first (needed for generated scenes)",
    )
    args = ap.parse_args()

    if args.mode == "background":
        run_backgrounds(args.zone)
        return

    if args.mode == "icon":
        # ⭐ `--size` still works, squared: an icon's box is square by
        # definition, so one number is the whole of it.
        run_icons(
            args.zone,
            ICON_SIZE if args.size == DEFAULT_SIZE else (args.size, args.size),
        )
        return

    if not args.element:
        sys.exit("creature mode needs --element (the palette to lock to)")

    palettes = write_palettes()
    if args.element not in palettes:
        sys.exit(f"unknown element '{args.element}'. Known: {sorted(palettes)}")
    palette = palettes[args.element]

    src_dir = SOURCE_DIR / args.zone
    if not src_dir.is_dir():
        sys.exit(
            f"no source art at {src_dir}\n"
            f"  Put generated images there, named after the creature id "
            f"(listening_fawn.png, heartwood.png, ...).\n"
            f"  Prompts: docs/BESTIARY_ART.md\n"
            f"  Or let the generator fetch them: "
            f"python3 tool/artgen.py --zone {args.zone} --kind creatures"
        )

    out_dir = OUT_DIR / args.zone
    out_dir.mkdir(parents=True, exist_ok=True)
    made = []
    sources = sorted(
        f
        for f in src_dir.iterdir()
        if f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    )
    for src in sources:
        sprite = to_sprite(src, palette, args.size, cutout=args.cutout)
        # ⭐ Always .png out, whatever went in — the creature id is the stem.
        dst = out_dir / f"{src.stem}.png"
        sprite.save(dst)
        made.append(src.stem)
        print(f"  {src.name} -> {dst.relative_to(ROOT)}  ({args.size}x{args.size})")

    if made and not args.cutout:
        print(
            "\n⚠️  ran without --cutout. If the source art has a background, "
            "it has just been pixelated along with the creature."
        )

    # ⭐ A manifest, so the Dart side can assert every creature has art rather
    # than discovering a missing file at runtime.
    (out_dir / "manifest.json").write_text(json.dumps(sorted(made), indent=2))
    print(f"\n{len(made)} sprites, palette '{args.element}' ({len(palette)} colours)")
    if not made:
        print("⚠️  nothing to do — the source directory is empty")


if __name__ == "__main__":
    main()
