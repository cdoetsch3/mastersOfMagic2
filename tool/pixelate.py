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

# ⚠️ How far a background is pushed back. Both deliberate: without them a good
# backdrop makes the creature standing on it unreadable.
BACKGROUND_DARKEN = 0.42
BACKGROUND_DESATURATE = 0.45

# ⚠️ Anything below this alpha becomes fully transparent. Soft edges at this
# scale read as grime, not as antialiasing.
ALPHA_CUTOFF = 128


# ⭐ Chroma key. Nothing in a natural bestiary is magenta, so it can never be
# confused with the subject — including a birch-WHITE creature, which a white
# background would eat.
KEY_COLOUR = (255, 0, 255)
KEY_TOLERANCE = 60


def key_out(img: "Image.Image", tol: int = KEY_TOLERANCE) -> "Image.Image":
    """Removes an exact background colour.

    ⭐ **Lossless on the subject, and it keeps thin structures.** `rembg` is a
    segmentation model and it guesses: it ate the Hollow Stag's antlers whole,
    because branching shapes against a low-contrast background read as
    background. A colour key cannot make that mistake.
    """
    px = np.asarray(img.convert("RGBA")).astype(np.int16)
    dist = np.abs(px[:, :, :3] - np.array(KEY_COLOUR, dtype=np.int16)).sum(axis=2)
    px[:, :, 3] = np.where(dist <= tol, 0, px[:, :, 3])
    return Image.fromarray(px.astype(np.uint8), "RGBA")


def cut_out(img: "Image.Image") -> "Image.Image":
    """Removes the background, leaving the subject on alpha.

    ⚠️ **Prefer `--key`.** This is a segmentation model and it guesses; on the
    Hollow Stag it removed the antlers entirely. Use it only for art that was
    generated without a keyable background.

    ⚠️ Lazily imported — `rembg` pulls in onnxruntime and a 176 MB model.
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


def build_ramp(
    rgb: tuple[int, int, int],
    steps: int,
    # ⚠️ **Not near-black.** A ramp bottoming out at the panel colour crushes
    # any creature that is mostly mid-tone — The Standing Green is green from
    # head to foot, and the dark half of the Flora ramp swallowed its interior
    # entirely. A lifted floor keeps detail inside the silhouette.
    shadow: tuple[int, int, int] = (46, 42, 58),
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
    NEUTRAL = (168, 158, 148)
    palettes = {}
    for name, rgb in element_colours().items():
        hue = build_ramp(rgb, steps=size - 8)
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
    key: bool = False,
) -> Image.Image:
    img = Image.open(src).convert("RGBA")

    if key:
        img = key_out(img)
    elif cutout:
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

    # ⭐ Stretch the subject's own range to fill the ramp, measured over the
    # OPAQUE pixels only. A flatly-lit generation uses a narrow band of values,
    # and quantising that directly throws away most of the palette — which is
    # what "the pixelate process removed details" actually was.
    img = _stretch(img, alpha)

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


def _stretch(img: "Image.Image", alpha: "Image.Image") -> "Image.Image":
    """Linear contrast stretch over the subject, ignoring transparency."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    mask = np.asarray(alpha) >= ALPHA_CUTOFF
    if mask.sum() < 16:
        return img
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    lo, hi = np.percentile(lum[mask], (2, 98))
    if hi - lo < 8:
        return img  # already flat; stretching would only amplify noise
    scaled = (rgb - lo) * (255.0 / (hi - lo))
    return Image.fromarray(scaled.clip(0, 255).astype(np.uint8), "RGB")


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
        "--key",
        action="store_true",
        help="remove a flat magenta background (preferred — exact, keeps "
        "thin structures like antlers)",
    )
    ap.add_argument(
        "--cutout",
        action="store_true",
        help="strip the background with rembg (guesses; use only when the art "
        "has no keyable background)",
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
        sprite = to_sprite(
            src, palette, args.size, cutout=args.cutout, key=args.key
        )
        # ⭐ Always .png out, whatever went in — the creature id is the stem.
        dst = out_dir / f"{src.stem}.png"
        sprite.save(dst)
        made.append(src.stem)
        print(f"  {src.name} -> {dst.relative_to(ROOT)}  ({args.size}x{args.size})")

    if made and not (args.cutout or args.key):
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
