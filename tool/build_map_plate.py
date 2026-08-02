#!/usr/bin/env python3
"""Build docs/plates/world-map.html from the render test's output.

Run `flutter test tool/render_map_test.dart` first — it writes the terrain PNG
and a JSON sidecar of every pin, label and band straight from `world.dart`.

Why two steps: `flutter test` substitutes a placeholder font that draws every
glyph as a filled box, and nothing reachable from a test overrides it. So the
terrain is painted by the real `WorldMapPainter` with pins and labels OFF, and
the names are overlaid here as SVG text — one source of truth, and text a human
can actually read.
"""

import base64
import html
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PLATES = ROOT / "docs" / "plates"

TONE = {
    "land": "#f2f7ea",
    "cold": "#dff0fa",
    "dry": "#fdf0cf",
    "warm": "#ffd9c4",
    "sea": "#cfeaf5",
    "river": "#cfeaf5",
    "beyond": "#e6dcff",
    "veil": "#ffc8ec",
}

# Highlighted on the plate so a reader can see what changed in the last pass.
NEW = {"the_sealed_garden", "the_buried_sky", "the_glass_archive"}


def main() -> None:
    data = json.loads((PLATES / "world-map.json").read_text())
    png = base64.b64encode((PLATES / "world-map.png").read_bytes()).decode()
    s, b = data["scale"], data["bounds"]
    width, height = b["w"] * s, b["h"] * s
    zones = sum(1 for p in data["places"] if p["kind"] != "town")

    def px(x: float) -> float:
        return (x - b["l"]) * s

    def py(y: float) -> float:
        return (y - b["t"]) * s

    out: list[str] = []
    for f in data["features"]:
        rot = ""
        if f["rot"]:
            rot = (
                f'transform="rotate({f["rot"] * 57.2958:.1f} '
                f'{px(f["x"]):.0f} {py(f["y"]):.0f})"'
            )
        out.append(
            f'<text class="feat" x="{px(f["x"]):.0f}" y="{py(f["y"]):.0f}" {rot} '
            f'font-size="{f["size"] * s:.0f}" '
            f'letter-spacing="{f["tracking"] * s:.1f}" '
            f'fill="{TONE.get(f["tone"], "#fff")}">{html.escape(f["text"])}</text>'
        )

    for p in data["places"]:
        x, y, r = px(p["x"]), py(p["y"]), 15 * s
        cols = p["colors"] or ["#cfd8dc"]
        new = p["id"] in NEW
        if len(cols) == 1:
            out.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.0f}" fill="{cols[0]}"/>')
        else:
            out.append(
                f'<path d="M {x:.0f} {y - r:.0f} A {r:.0f} {r:.0f} 0 0 0 '
                f'{x:.0f} {y + r:.0f} Z" fill="{cols[0]}"/>'
                f'<path d="M {x:.0f} {y - r:.0f} A {r:.0f} {r:.0f} 0 0 1 '
                f'{x:.0f} {y + r:.0f} Z" fill="{cols[1]}"/>'
            )
        ring = "#ffe071" if new else ("#ffffff" if p["kind"] == "town" else "#7fe3c0")
        out.append(
            f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.0f}" fill="none" '
            f'stroke="{ring}" stroke-width="{(5.5 if new else 3.5) * s:.1f}"/>'
        )
        if new:
            out.append(
                f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r * 2.1:.0f}" fill="none" '
                f'stroke="#ffe071" stroke-width="{2 * s:.1f}" '
                f'stroke-dasharray="{6 * s:.0f} {5 * s:.0f}" opacity=".85"/>'
            )
        cls = "pin town" if p["kind"] == "town" else "pin"
        out.append(
            f'<text class="{cls}" x="{x:.0f}" y="{y - r - 10 * s:.0f}" '
            f'font-size="{(19 if p["kind"] == "town" else 17) * s:.0f}">'
            f'{html.escape(p["name"].upper())}</text>'
        )
        if p["band"]:
            out.append(
                f'<text class="band" x="{x:.0f}" y="{y + r + 20 * s:.0f}" '
                f'font-size="{13 * s:.0f}">{html.escape(p["band"])}</text>'
            )

    page = f"""<meta charset="utf-8">
<title>Masters of Magic 2 — world map</title>
<style>
  :root {{ color-scheme: dark; }}
  body {{ margin:0; background:#0e1620; color:#dbe6f0;
         font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }}
  header {{ padding:22px 26px 10px; }}
  h1 {{ margin:0 0 4px; font-size:20px; letter-spacing:.02em; }}
  p  {{ margin:0; color:#8fa3b8; font-size:13px; }}
  .key {{ display:flex; gap:18px; flex-wrap:wrap; padding:12px 26px 18px;
          font-size:12.5px; color:#a8bccf; }}
  .key i {{ display:inline-block; width:11px; height:11px; border-radius:50%;
            margin-right:6px; vertical-align:-1px; }}
  .wrap {{ overflow:auto; padding:0 14px 28px; }}
  svg {{ display:block; max-width:100%; height:auto; }}
  text {{ font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
          text-anchor:middle; paint-order:stroke; stroke:#0c141c;
          stroke-width:5px; stroke-linejoin:round; }}
  .feat {{ font-weight:700; opacity:.92; }}
  .pin  {{ font-weight:700; fill:#f4f9ff; }}
  .town {{ fill:#ffe9a8; }}
  .band {{ fill:#9fb6c9; font-weight:600; stroke-width:4px; }}
</style>
<header>
  <h1>Masters of Magic 2 — the world, {zones} combat zones and 9 towns</h1>
  <p>Terrain painted by <code>WorldMapPainter</code>; pins, names and bands overlaid
     from <code>world.dart</code>. Regenerate with
     <code>flutter test tool/render_map_test.dart &amp;&amp; python3 tool/build_map_plate.py</code>.</p>
</header>
<div class="key">
  <span><i style="background:#ffe071"></i>new — The Glass Archive &middot; The Buried Sky &middot; The Sealed Garden</span>
  <span><i style="background:#fff"></i>town</span>
  <span><i style="background:#7fe3c0"></i>combat zone</span>
  <span>split pins are hybrids, coloured by their two elements</span>
</div>
<div class="wrap">
<svg viewBox="0 0 {width:.0f} {height:.0f}" width="{width:.0f}" height="{height:.0f}">
  <image href="data:image/png;base64,{png}" x="0" y="0"
         width="{width:.0f}" height="{height:.0f}"/>
{chr(10).join(out)}
</svg>
</div>
"""
    (PLATES / "world-map.html").write_text(page)
    print(f"docs/plates/world-map.html — {zones} zones, {len(page) // 1024} KB")


if __name__ == "__main__":
    main()
