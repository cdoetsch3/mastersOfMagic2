# Map drawing & navigation — architecture review

Reviewed 2026-07-28, against `f8193c8`. Scope: `world_map_geometry.dart`,
`world_map_painter.dart`, `world_map_screen.dart`, the Map-tab wiring, and
`world_map_test.dart` (~2,700 lines).

Lens: principal engineer / game developer. Concerns are ranked; each carries
evidence and a concrete recommendation. **P0 is a confirmed defect, verified
with a widget test during this review** — everything else is architecture.

---

## What this system gets right (keep these)

- **Graph/drawing separation.** `World` owns what connects to what;
  `WorldMapGeometry` owns where it is drawn — with tests guarding the seam in
  both directions. This is the single most important structural decision here
  and it is correct.
- **Labels as data.** `featureLabels` is a checkable list, not paint calls;
  capitalisation, overlap, canvas bounds and pin collisions are assertions.
- **Seeded determinism, no assets.** The whole map is `Path` + `drawPath` from
  fixed seeds, consistent with the codebase's no-image-assets pattern, and a
  test pins the determinism.
- **Design invariants encoded.** *Exactly two* roads may cross the Veil; the
  Empyrean must draw above it. The build fails if the fiction is violated.

---

## P0 — CONFIRMED DEFECT: tap-to-travel mis-maps coordinates

> ✅ **Fixed in the same commit as this review**, with five regression tests in
> `test/world_map_screen_test.dart` that tap true pin positions at fit scale,
> zoomed, and on a short-wide window. Both halves were verified to fail again
> when reintroduced. Fixing it also surfaced a third defect: `_PlaceSheet`
> overflowed its height budget for content-heavy places (fixed — the sheet
> scrolls). The analysis below is kept as written, as the record of what was
> wrong and why nothing caught it.

`_WorldMapScreenState._toMap` applies `Matrix4.inverted(_controller.value)` to
the tap position. But the `GestureDetector` sits **inside** the
`InteractiveViewer`'s transformed subtree, so Flutter's hit-testing has
**already un-transformed** the coordinates — `localPosition` is in child
space. The code applies the inverse a second time.

Verified empirically (widget test, 400×800 viewport):

| Tap position | Sheet opens? |
|---|---|
| Correctly computed screen position of Aldermere | ❌ no |
| Position transformed by **M²** (the double-inverse's fixed point) | ✅ yes |

Consequences by zoom:

- At phone fit scale (k≈1, small translate): error ≈ the fit translation —
  **~43 px vertically** in the probe. Taps "feel off"; near-misses select
  nothing or a neighbour.
- At any real zoom the error compounds quadratically: at 3× centred on the
  player, the position the code responds to is **off-screen** (computed
  y ≈ −130 on an 800-px screen). Tap-to-travel is effectively unusable when
  zoomed in — which is precisely when players tap.

**Fix.** Delete the inversion: divide `localPosition` by `unit` and add the
bounds origin, nothing else. Flutter's transform hit-testing already did the
rest. (If the detector ever moves *outside* the viewer, use
`TransformationController.toScene` — the documented pattern — instead of
hand-rolled matrix math.)

**Why review caught it and tests did not:** the existing widget test only
asserts the painter paints without throwing; nothing exercises the
tap-to-sheet path. A regression test should tap a pin's true screen position
and expect its sheet.

### P0-adjacent: `InteractiveViewer` is `constrained: true` (default)

> ✅ **Fixed, then superseded.** `constrained: false` was the right fix for the
> child as it stood. The child itself was the deeper problem: a tall
> scale-to-width canvas centred by *translation*, which `InteractiveViewer`
> clamps against its own boundary on every gesture — so the viewer spent the
> whole time undoing the centring. Users saw stuttering pans and a map that
> snapped to the left edge. The map is now **contained** in the box and
> centred by layout, making the child exactly the viewport; `constrained` is
> back to its default and there is nothing left to fight. `MapCamera` owns the
> containment and the painter asks it for the fit, so the drawing and the
> hit-test cannot disagree.
>
> ⚠️ **Containment alone was a regression, and the first round of tests
> asserted it as a feature.** Opening the map *fitted* puts the whole world on
> screen — so `InteractiveViewer` refuses every drag, correctly, because there
> is nowhere to go — while on a wide window the world shrinks to a strip with
> two thirds of the space empty ocean. Reported as "it's drawn but I can't pan
> there", in both views. The camera now also knows `coverScale` (the scale that
> **fills** the box) and both views open there, framed on the player, with
> "Whole world" one tap away. The lesson worth keeping: a test that asserts
> *nothing moves* should always be read twice — the map passed it by being
> unusable.

The child `SizedBox` is taller than most viewports (aspect 1150:1890). With
`constrained: true` the child is forced to the incoming constraints when the
viewport is shorter than the painted height: the canvas keeps painting
(CustomPaint does not clip) but the widget's **hit area and layout height are
clamped**. The bottom of the map draws yet cannot be interacted with on
short-wide windows. This should be `constrained: false` with an explicit child
size — the documented mode for pan-a-large-canvas.

---

## P1 — Correctness time-bombs (work today, will break silently)

### 1. The painter reads global `World` state

`_paintRoads` and `_paintPins` iterate `World.locations` directly. The painter
is therefore **not a pure function of its constructor arguments**:

- `shouldRepaint` cannot observe graph changes. Today `World.locations` is
  `const`, so this is latent — but zone unlocks, seasonal areas, or any
  dynamic world content will change what should be drawn with no repaint
  triggered and no compile-time warning.
- The painter cannot draw any world but *the* world: no test fixtures, no
  alternate planes, no "map as it looked at chapter 3".

**Recommendation:** pass the location list (or a narrowed
`List<MapPin>` view model) into the painter. The painter should render what it
is handed.

### 2. Aliased mutable state + length-based dirty checking

> ✅ **Fixed.** The painter now snapshots `reachable`/`seen` with
> `Set.unmodifiable` **in its own constructor** — so no call site can hand it a
> live collection by accident — and `shouldRepaint` compares with `setEquals`.
> Both halves were mutation-tested: reverting either one fails a named test in
> `world_map_test.dart`. (Note the copy is the load-bearing half: `setEquals`
> alone still compares an aliased set with itself.)

`seen: widget.game.profile.discoveredLocationIds` hands the painter **the live
mutable Set from the profile**. After travel, the old and new painter hold the
*same instance* — so `old.seen.length != seen.length` compares an object with
itself and is always false. Repaints currently happen only because `currentId`
changes in the same frame.

The moment anything changes `seen` *without* moving the player (a quest
revealing a location, a scrying spell, multiplayer presence), the map will not
repaint, and nothing will say why.

**Recommendation:** painters take immutable copies (or the screen passes
`Set.unmodifiable` snapshots), and `shouldRepaint` compares with
`setEquals`, not `.length`.

### 3. The screen never listens to `GameState`

> ✅ **Fixed.** The screen is wrapped in a `ListenableBuilder` on `game`, and
> `travelTo` is awaited with failures surfaced in a snackbar. Guarded by a test
> that moves the player from *outside* the widget and expects the app bar to
> follow; it fails when the listener is removed.

`WorldMapScreen` takes `game` by constructor and never subscribes
(`ListenableBuilder` / `GameStateScope.of` are absent). Travel appears to work
because `GameState._mutate` applies the change **synchronously before its
first await**, and the sheet's callback happens to call `setState` right
after. That is accidental coupling to an implementation detail of `_mutate` —
reorder one line there (e.g., an optimistic-concurrency read before the
write) and the map silently shows the player in the wrong place.

It also means *any* externally-triggered state change while the map is open
(future travel timers completing, cloud sync) will not render.

**Recommendation:** the screen observes `GameState` like the tabs do
(`GameStateScope` / `ListenableBuilder`). Also: `travelTo`'s future is
dropped — persistence failures (offline Firestore) vanish. Await it or route
errors somewhere visible.

### 4. Camera math is scattered, and the map can be lost

> ✅ **Fixed.** `lib/ui/map_camera.dart` is now the single owner:
> `mapToChild`/`childToMap`/`mapToScreen`/`screenToMap`,
> `fitted`/`centredOn`/`zoomedBy`/`clamped`/`resized`, and
> `screenToMapDistance` for tap targets. All six call sites go through it,
> `minScale` is the fit scale (the world can no longer be flung away), and
> `test/map_camera_test.dart` asserts 15 properties **with no widget tree** —
> including that `childToMap` and `screenToMap` differ, which is P0 stated as a
> unit test. The tap radius is now 26 screen px, replacing the fixed 34 map
> units called out in §6.

`_fitScale`, `_fitWorld`, `_centreOn`, `_zoomBy`, `_toMap`, and the
thumbnail's `_focus` each independently re-derive the unit conversion
(`viewport.width / bounds.width`) and hand-roll matrix composition. Six
call-sites encode one concept. This is exactly how the P0 defect happened —
transform logic with no single owner.

`boundaryMargin: EdgeInsets.all(double.infinity)` + `minScale: 0.05` also
means a fling can put the entire map off-screen at 1/20th scale — a dot in a
corner with no rubber-band back.

**Recommendation:** one `MapCamera` value type owning
`mapToScreen`/`screenToMap`/`fit`/`centreOn`/`zoomBy` and a clamp that keeps
some of the world on screen. Every consumer — screen, thumbnail, hit-test,
future minimap — goes through it, and it is unit-testable in isolation, which
would have caught P0 before any widget existed.

---

## P2 — Performance (matters on phones; fine on a dev machine)

### 5. Every repaint re-issues the entire scene

Per `paint()` call, measured from the code:

| Layer | Draw ops |
|---|---|
| Sea waves | **~3,120** two-curve paths (80 rows × 39 cols) |
| Mountain peaks | 284 peaks × 3–4 paths ≈ **1,000** |
| Trees/dunes/cracks | ~370 |
| Roads | 47 edges, most re-dashed via `computeMetrics` each paint |
| Labels | ~25 labels × 2 passes = **~50 `Paragraph` build + layout** |

A tap that only changes `selectedId` — one ring — replays all of it.
Paragraph layout alone is among the most expensive operations in Flutter.
The thumbnail pays the same full cost to render at ~350 px.

**Recommendation (standard game-rendering shape):** split static from
dynamic. Record terrain + feature labels once into a `ui.Picture` (or a
second `CustomPaint` behind a `RepaintBoundary` whose `shouldRepaint` is
`false`) and blit; keep pins/rings/roads in a thin dynamic layer. The
thumbnail then reuses the same picture for free. Within the current design,
three free wins: pre-sort `_forest` in its initializer instead of every paint,
cache dashed road paths, and set `isComplex: true` on the `CustomPaint`.

### 6. No zoom awareness — so no LOD, and a fixed-size world for taps

The painter never learns the current scale. Consequences:

- Sub-pixel sea waves are drawn at fit scale; nothing can be culled.
- Labels cannot do the expected map UX (zone names appear as you zoom in;
  `showPins` is all-or-nothing).
- The screen's tap radius is **34 map units**: ~10 px at desktop fit scale
  (nearly untappable), ~270 px at 8× zoom (taps from across the screen open a
  pin). A tap target should be constant in *screen* pixels — divide by the
  current scale.

The same "pin footprint" concept is encoded three independent times: pin
radius 12–13 (painter), min spacing 34 (test), tap radius 34 (screen). One
constant, three owners.

---

## P2 — Data architecture

### 7. Coordinates duplicated between geometry and painter

- The three Empyrean isle blobs are hardcoded in `_paintVoid` at literal
  `(474,-132) (606,-186) (726,-148)` — which are exactly
  `positions[the_eclipsed_citadel / the_unwritten_library /
  the_collapsed_academy]`. Move a place, and its island stays behind.
- The lake blob paints at `(520,500)`; the Mirrormere pin is `(520,508)`.
- The Veil's path endpoints re-encode `y = -60` alongside
  `WorldMapGeometry.veilY = -60`.

The geometry/graph seam is tested; the geometry/**painter** seam is not.
**Recommendation:** derive — `isleFor(positions[id])`, veil path built from
`veilY` — so there is nothing to drift.

### 8. Rendering decisions keyed to magic strings

`loc.id == 'the_eclipsed_citadel'` selects a pin style inside the painter. A
rename breaks it silently (the id↔position test would catch a rename in
*geometry*, but nothing guards this comparison). Pin style should derive from
data (`kind` + `plane`, or an explicit flag on `GameLocation`).

### 9. Tests model the renderer with duplicated heuristics

Label-overlap tests estimate text width as `length × (size×0.58 + tracking)`
and pin boxes as `150×40 at −21` — constants copied from (not shared with)
the painter. They can pass while the true render overlaps (halo stroke and
real font metrics differ), and must be hand-updated when label styling
changes. Acceptable at this scale; when labels next change, measure with the
same `TextPainter` the renderer uses, or export the constants.

Related latent constraint: `_label` lays out at a hardcoded width of 600 and
centres by −300; any future label wider than 600 px silently wraps and
mis-centres.

---

## P3 — Forward-looking (decisions coming due, not defects)

- **Phase 5b will break the road model.** `connections: List<String>` is
  committed (IMPLEMENTATION_PLAN) to become edge objects with durations and
  modes. `_paintRoads` and the place sheet are the two consumers to design
  for. Today every edge draws as the same straight dashed line — which means
  **the Galehaven↔Tidewrack sea passage is visually indistinguishable from a
  road**, though it is design-significant (WORLD_DESIGN §2.5). Edge *kind*
  wants to exist before edge *duration* does.
- **Straight-line roads now cross the terrain art** (over mountains, through
  the lake). Fine at this fidelity; when roads gain waypoints, they belong in
  `WorldMapGeometry` beside the rivers, not in the painter.
- **Cosmetic residue** in `world_map_geometry.dart`: a duplicated ALL-CAPS
  doc block (lines 52–57) and the file/enum doc comments fused at the top —
  leftovers of scripted edits worth sweeping.

---

## Suggested order of work

1. ~~**Fix P0**~~ ✅ done — double inversion deleted, `constrained: false`,
   five regression tests.
2. ~~**`MapCamera`**~~ ✅ done — with P1 #2 (dirty checking) and P1 #3
   (listening) alongside it, since a screen that rebuilds in front of a painter
   that will not repaint is only half a fix.
3. **Picture-cache the terrain**; split static/dynamic painters; thumbnail
   reuses the picture.
4. **Purify the painter** — takes locations + view-model state as arguments;
   `setEquals` dirty checks; unmodifiable collections.
5. **Derive duplicated geometry** (isles, veil, lake) from single sources;
   replace the citadel string special-case with data.

Also done since: the Map-tab card is no longer a picture with a tap-to-open
overlay — it is the same `InteractiveWorldMap` widget, so panning, zooming and
travelling all work without leaving the tab. Expanding buys room and the
geography labels, not capability.

Items 1–2 are done (plus P1 #2 and #3). Items 3–5 remain, and P1 #1 — the
painter reading global `World` — is the one still open at P1, deliberately: it
pairs naturally with item 4, and both are cheapest to do while Phase 5b is
already rewriting the same constructor for edge objects.

**See the addendum at the end of this document** for three defects that
survived this work and were caught in playtesting.

---

# Addendum — 2026-07-28, after playtesting

The work above was implemented in one sitting. Three defects survived it and
were caught by a player, not by the suite. All three are fixed and guarded;
they are recorded here because *why the tests missed them* is more useful than
the fixes.

## The three defects

### A. The southern fifth of the world was drawn outside the canvas

`WorldMapPainter.paint` applied `canvas.translate(-b.left, -b.top)` **twice** —
a line re-inserted by a scripted edit onto one that was already there. The map
was drawn 130 px low and 28 px right of where it belonged. Because the child
is now sized exactly to the canvas, the strip that fell off the bottom was
unreachable by panning *and* invisible when zoomed out.

**Why nothing caught it.** Every test derived its expected position from
`MapCamera` — the hit-test did too. Painter and hit-test disagreed, but the
tests only ever compared the hit-test against itself. The suite could not see
the drawing at all: the sole rendering test asserted "paints without throwing".

**The guard.** `world_map_test.dart` now renders the painter to a real image,
scans for the land's true top and bottom edges, and compares them against
`MapCamera`'s prediction at three window shapes. Reintroducing the duplicated
line fails three tests.

> ⭐ The general rule: when a value type owns a layout, *something must compare
> rendered pixels against it*. Two consumers agreeing with each other proves
> nothing if both read the same oracle.

### B. The card could not be panned vertically at all

The map card lived inside the Map tab's `ListView`. A pannable surface inside a
scrolling list loses the gesture arena every time: measured, a 250 px drag
scrolled the page 230 px and moved the map's transform by exactly zero. The
card now sits **above** the list, which also keeps it visible while the travel
options scroll.

### C. A wheel or trackpad scroll zoomed instead of panning

`InteractiveViewer` treats every mouse-wheel scroll as zoom. Scrolling down —
the obvious way to move south — zoomed out instead, reached the whole-world
limit in three notches, and then stopped responding entirely. It reads exactly
like a wall.

Scrolling now pans; ⌘/Ctrl + scroll zooms. Note the mechanism: the viewer
mutates its controller **directly** in `_receivedPointerSignal`, without the
`PointerSignalResolver`, so a competing handler cannot preempt it. It can only
outlive it — `GestureBinding` resolves pointer signals after every listener has
been dispatched, so the registered callback runs last. The pre-zoom camera is
captured on the way in, because by then the viewer has already changed scale.

## What this cost, and the lesson

Three rounds of "still broken" before the cause was found, because each round
diagnosed from geometry the tests already agreed with. What broke the deadlock
was measuring instead of reasoning: rendering the painter to pixels and
scanning them, and instrumenting the gesture path to see which recognizer won.

One test in the first round asserted *"at fit scale a pan cannot move the map
AT ALL"*. It passed because the map was unusable. **A test that asserts nothing
happens deserves a second reading** — it is as easily satisfied by a broken
feature as by a correct one.

## Still open

Unchanged from the list above: P1 #1 (painter reads global `World`), P2 items
3–5. Two additions:

- **The letterbox bands.** At full zoom-out on a wide window the world sits in
  a column of open ocean — honest, since the map is far taller than a laptop
  screen, and only visible at maximum zoom-out. If it ever grates, the answer
  is a tighter `bounds` (the land occupies 810×1400 of a 1150×1890 rect), not
  a different fit.
- **Scroll capture.** The card takes wheel events for panning, so the Map tab
  cannot be scrolled with the cursor over the map. Acceptable while the map is
  a fixed header above the list; revisit if the tab layout changes.
