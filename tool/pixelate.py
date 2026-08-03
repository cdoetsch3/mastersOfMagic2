#!/usr/bin/env python3
"""Turn generated artwork into game-ready creature sprites.

    python3 tool/pixelate.py --zone whispering_woods --element flora --cutout
    python3 tool/pixelate.py --zone whispering_woods --mode background

**Creature mode** (default) reads `art/source/<zone>/`, and writes a small,
palette-locked sprite per creature to `assets/creatures/<zone>/`.

**Background mode** reads `art/source/backgrounds/<zone>.*` and writes one wide
arena backdrop to `assets/backgrounds/`.

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

# ⭐ Small enough that the art reads as deliberate pixel art rather than a
# blurry photo, large enough to keep a silhouette. 64 is the sweet spot for a
# ~160px display height.
DEFAULT_SIZE = 64

# ⭐ Wide, and small enough to still read as pixel art when scaled up behind
# the arena. 16:9 so it fits the duel screen without cropping.
BACKGROUND_SIZE = (384, 216)

# A scene needs more than a creature's 16 — fewer and skies band badly.
BACKGROUND_COLOURS = 28

# ⚠️ How far a background is pushed back. Both deliberate: without them a good
# backdrop makes the creature standing on it unreadable.
BACKGROUND_DARKEN = 0.42
BACKGROUND_DESATURATE = 0.45

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


def build_ramp(rgb: tuple[int, int, int], steps: int = 10) -> list[tuple[int, int, int]]:
    """A dark-to-light ramp through an element's colour.

    ⭐ Not a rainbow. A creature palette is one hue's tonal range plus a near
    black and a near white — that is what makes a limited palette read as
    lighting rather than as posterisation.
    """
    shadow = (18, 14, 26)  # the game's own background, so sprites sit in it
    light = (255, 250, 240)
    ramp: list[tuple[int, int, int]] = []
    half = steps // 2
    for i in range(half):  # shadow -> colour
        t = i / half
        ramp.append(tuple(round(shadow[c] + (rgb[c] - shadow[c]) * t) for c in range(3)))
    for i in range(steps - half):  # colour -> light
        t = i / (steps - half)
        ramp.append(tuple(round(rgb[c] + (light[c] - rgb[c]) * t) for c in range(3)))
    return ramp


def write_palettes(size: int = 16) -> dict[str, list[tuple[int, int, int]]]:
    """Writes one palette PNG per element and returns them."""
    PALETTE_DIR.mkdir(parents=True, exist_ok=True)
    palettes = {}
    for name, rgb in element_colours().items():
        ramp = build_ramp(rgb, steps=size - 2)
        # ⭐ A true black and a near-white on every palette: outlines and
        # specular highlights are what stop a sprite reading as a flat blob.
        full = [(10, 8, 14)] + ramp + [(255, 255, 255)]
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


def to_background(src: pathlib.Path, size: tuple[int, int]) -> Image.Image:
    """A wide, dimmed, quantised arena backdrop.

    ⚠️ No element remap. A scene is many hues; forcing it through one ramp
    turns a forest into a green smear.
    """
    img = Image.open(src).convert("RGB")

    # Cover-fit, then centre-crop — letterboxing a backdrop looks like a bug.
    tw, th = size
    scale = max(tw / img.width, th / img.height)
    img = img.resize(
        (max(1, round(img.width * scale)), max(1, round(img.height * scale))),
        Image.BOX,
    )
    left = (img.width - tw) // 2
    top = (img.height - th) // 2
    img = img.crop((left, top, left + tw, top + th))

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
            f"  Prompts: art/prompts/backgrounds.md"
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
        choices=["creature", "background"],
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
            f"  Prompts: art/prompts/{args.zone}.md"
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
