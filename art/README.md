# Art

Where generated artwork lands, what turns it into game assets, and how it gets
looked at before it ships.

```
art/
  state.json    the ledger — one record per asset, COMMITTED
  source/       raw generator output, GITIGNORED (see below)
    <zone>/       one image per creature, named after its EnemyDef id
    backgrounds/  one image per zone, named after its zone id
    items/
      <zone>/     one image per item, named after its ItemDef id
  palettes/     one per element, generated from lib/game/element_style.dart
```

⚠️ **Nothing in `art/` ships.** `tool/pixelate.py` reads this directory and
writes to `assets/`, and `assets/` is what `pubspec.yaml` bundles.

## The one command

```sh
python3 tool/artgen.py --zone glimmerbrook
```

That enumerates every awaited picture in the zone — 11 creatures, one arena
backdrop and the zone's item icons — assembles each prompt from the art docs,
calls the image API, saves the raw source where pixelate expects it, runs
pixelate, checks the file landed on the path the game asks for, and records all
of it in `art/state.json`. Then:

```sh
python3 tool/artgen.py --review --zone glimmerbrook
```

⭐ **Descriptions live in the docs and are never copied.**
[docs/BESTIARY_ART.md](../docs/BESTIARY_ART.md) is the creature and backdrop
database, [docs/ITEM_ART.md](../docs/ITEM_ART.md) the item one. Both are parsed
on every run. ⚠️ That makes their **anchor formats load-bearing**, and both
files now say so at the top; `tool/test_artgen.py` pins the counts at 55 / 52 /
5 in both directions so a reformat cannot quietly shrink the roster.

📝 **`art/prompts/` is gone.** It held auto-derived copies of prompts that the
docs already carry better — the back-port-or-retire question on the backgrounds
file is settled as **retired**. A second copy of a description is one more
thing to drift.

## The key

Either works, and the environment wins:

```sh
export OPENAI_API_KEY=sk-...
# or, at the repo root:
echo 'OPENAI_API_KEY=sk-...' > .env
```

⚠️ **`.env` is gitignored, and so is every path a key could otherwise reach.**
The tool never prints, logs or formats the key into an error — a 401 says
"the image API rejected the credential" and stops there, and a key echoed back
by the API is redacted out of the message. `tool/test_artgen.py` asserts it.

## The command set

| | |
|---|---|
| `--zone <z>` | generate everything pending or rejected in the zone |
| `--kind creatures\|icons\|backdrop` | narrow the run to one kind |
| `--only <asset_id>` | one picture, by id (`listening_fawn`, `oak_log`, `thornmire`) |
| `--dry-run` | print the plan and an estimated cost, touch no network |
| `--status [--zone <z>]` | table of every asset, its status, attempts and drift |
| `--review [--zone <z>]` | serve the contact sheet |
| `--force` | regenerate even approved art |
| `--quality low\|medium\|high` | generator quality, and what the estimate assumes |
| `--no-verify` | skip the three Dart contract suites after placement |

⭐ **A `--zone` run only touches `pending` and `rejected` assets.** Approved art
is finished; art awaiting review has already been paid for and is about to be
looked at. Both are skipped and both say so. ⚠️ Always `--dry-run` first — a
whole zone is around 20 images and the tool prints what it thinks that costs,
labelled as an estimate, before you spend it.

⭐ **A raw that was paid for but never made it through pixelate is
re-pixelated, not re-bought.** The ledger tracks placement separately from
generation, so a missing `rembg` or a crashed run costs nothing to recover
from.

## The review loop

`--review` serves a dark, dependency-free contact sheet from Python's own
`http.server`. ⚠️ **Bound to 127.0.0.1 only** — it writes the ledger on POST
with no authentication and must not be reachable from the network.

Each card shows the generator's 1024px source beside **what the game will
actually draw, at the size the game draws it**: an icon in a 40px slot mock, a
creature at 2× its 128px sprite, a backdrop at its real 384×216. ⭐ That
comparison is the whole point — art that reads beautifully at 1024 and turns to
mud at 128 is the failure this pipeline exists to catch, and nothing but a
side-by-side finds it.

- **Approve** → the asset is done and later runs leave it alone.
- **Reject** → feedback is **required**, because it becomes the next prompt.

⭐ **A rejection is an edit, not a re-roll.** The next `--zone` run sends the
previous raw plus the original description plus *every* note so far to the
image API's edits endpoint, so attempt two is recognisably the same picture with
the complaint fixed — rather than a fresh gamble that loses whatever was right
about attempt one. All the notes are carried, oldest first, so fixing the ears
on the third pass cannot un-fix the scale on the second.

## What is committed and what is not

| | |
|---|---|
| `assets/**/*.png` | ✅ committed — the pixelated output, what ships |
| `art/state.json` | ✅ committed — prompts, hashes, attempts, feedback |
| `art/palettes/` | ✅ committed — generated, but cheap and reviewable |
| `art/source/` | ❌ gitignored — raws cost cents to make again |
| `.env` | ❌ gitignored — never, under any circumstances |

⚠️ **Whispering Woods' eleven creature sources predate artgen and stay
tracked.** Git keeps tracking a file the ignore rule was added after, and that
is deliberate here: nothing in the ledger can reproduce art that was made
before the ledger existed. They are seeded into `state.json` as `approved` with
model `pre-artgen (hand run)` so a zone run does not regenerate over them.

## Prompt drift

⭐ Every record stores the hash of the prompt its picture was made from. Rewrite
a description afterwards and `--status` marks that asset **stale** — but
nothing regenerates on its own. A reworded sentence is usually a typo fix, and
art is not free. `--only <id> --force` is the deliberate version.

## The underlying step: pixelate

`tool/artgen.py` shells out to [`tool/pixelate.py`](../tool/pixelate.py), which
remains usable on its own for hand-made or hand-downloaded art and is still the
only place the picture maths lives.

```sh
python3 tool/pixelate.py --zone whispering_woods --element flora --cutout
python3 tool/pixelate.py --zone whispering_woods --mode background
python3 tool/pixelate.py --zone whispering_woods --mode icon
```

**Creatures** — 128×128, remapped onto the zone's element palette. ⭐ 64 was the
first guess and it lost the Listening Fawn's root legs and lowered head
entirely. ⭐ **Every palette carries a neutral ramp as well as its element
ramp**: the Fawn is birch-white bark under green moss, and against a Flora-only
ramp both collapsed into the same green. Hybrid zones use their **lead**
element (Thornmire flora, Ashfall Vale pyro) so the sprite and the silhouette
fallback agree.

⚠️ **`--cutout` is off when artgen drives it.** The generator is asked for a
transparent background, so the creature arrives already cut out and `rembg`
would be a heavyweight no-op — and an install forced on everyone. Pass
`--cutout` to artgen for sources that came from somewhere else; it warns if a
raw arrives with no alpha channel at all.

**Backgrounds** — 384×216, darkened 42% and desaturated 45%. ⚠️ **A background
must lose to the sprites**; measured, a backdrop comes out at roughly 55% of
the source's mean luminance. 📝 artgen requests **1536×1024**, which is 3:2
against the arena's 16:9 — deliberate, because pixelate cover-crops rather than
letterboxing, so the extra height is trimmed off top and bottom. The backdrop
briefs already put nothing important there.

**Item icons** — 64×64, quantised and nothing else. ⭐ No element remap (a Flora
zone's catalogue holds copper ore and black glass), no darken or desaturate (an
icon shown at 14px on the duel's belt rail needs every scrap of contrast it
has), no cutout.

## Tests

```sh
python3 tool/test_artgen.py
```

67 tests, stdlib only, no network anywhere: the docs parse to 55 / 52 / 5 with
the ids matching the contract paths, prompts carry their preamble and no build
instructions, the ledger round-trips and flags drift, the generator adapter is
asserted against a fake transport (transparent background on creatures and
icons but never on a backdrop, the edits endpoint once feedback exists, the key
absent from every exception), and the review sheet is driven over a real
loopback socket.

Then the three Dart suites artgen runs for you after placement:

```sh
flutter test test/creature_art_test.dart test/arena_backdrop_test.dart test/item_icon_test.dart
```

## Another generator, later

⭐ **`ImageGenerator` is the only class that knows a vendor exists.** It is
three things — a `name`, a `generate(prompt, size, transparent)` and an
`edit(prompt, size, transparent, image)`, all returning raw PNG bytes — and the
orchestrator picks between the two purely on whether the ledger holds feedback.
A `GeminiGenerator` is that one class and no other edit; its docstring in
`tool/artgen.py` states the contract, including that a vendor without an edit
endpoint should fold the feedback into a plain generation rather than raise,
because the review loop's whole value is that a rejection goes somewhere.
