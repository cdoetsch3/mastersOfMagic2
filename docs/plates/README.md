# World design plates

Visual companions to [WORLD_DESIGN.md](../../WORLD_DESIGN.md), from the
geography design pass of 2026-07-26.

Each file is **self-contained HTML** — no external scripts, styles, fonts or
images, so nothing can rot and nothing needs a build step. Open one directly in
a browser, or serve the directory. Each is theme-aware except where noted.

| Plate | File | Status |
|---|---|---|
| **I-b** — One World, One Crossing | [plate-1b-one-crossing.html](plate-1b-one-crossing.html) | ✅ **canonical** |
| I-a — The Climb | [plate-1a-the-climb.html](plate-1a-the-climb.html) | superseded by I-b |
| I — The Known World | [plate-1-known-world.html](plate-1-known-world.html) | superseded by I-a |
| II — The Wheel of the World | [plate-2-wheel.html](plate-2-wheel.html) | ❌ not adopted |
| III — The Long Ascent | [plate-3-long-ascent.html](plate-3-long-ascent.html) | ❌ not adopted as the map |

## What each one is for

**Plate I-b — the settled map.** Three figures: the plan view, the ascent of The
Vault in section, and the crossing diagram. This is the one to read.

**Plate I-a** — the intermediate step, kept because it shows the reasoning that
turned the finale from a walk north into a climb. Its Ethereal tier still has all
six zones on the mountain; I-b moves the three Arcane places above the veil.

**Plate I** — the first pass. Its value is the climate reasoning, which I-b
inherits unchanged: the Ironspine's rain shadow makes the Kiln Desert, its
windward side makes Stormcliff, and the Meridian Scarp's two faces make both
halves of the Solar ▸ Lunar edge.

**Plate II — the wheel.** A concentric alternative built on the docs' own "Ring
0–1, Ring 2…" language. Not adopted: a wheel is a diagram of the *rules*, and a
continent is a diagram of the *place*. Two ideas survived — the observation that
every tier's counter triangle opens with its radiant element, and the
equidistant-endgame-city idea that became Zenith-at-the-summit.

**Plate III — the section.** Places numbered by altitude rather than level, which
is how the tree line and the altitude-is-not-difficulty point were found. Its
panorama deliberately commits to a single twilight palette rather than adapting
to the viewer's theme.

## Regenerating

These were hand-authored via throwaway generator scripts and are **not** built
from the design doc — treat the HTML as the source. If a plate needs a
correction, edit it directly; if the geography changes materially, the honest
move is a new plate with a new letter, since the whole point of keeping the
superseded ones is the visible trail of decisions.
