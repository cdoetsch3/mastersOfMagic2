# Masters of Magic 2 — START HERE

A simultaneous-turn elemental mage-duel game. Flutter — phones, tablets, and
browsers. Live at <https://mastersofmagic2.web.app>.

Both players lock in a move each turn, then the round resolves together —
prediction and mind-games are the point. The duel engine is pure Dart,
deterministic, and runs lockstep with commit-reveal netcode.

> **This file is the index, and the only Markdown at the repo root.** Every
> design doc lives in [docs/](docs/); this exists so a human or an AI arriving
> cold can find the right one in one hop instead of grepping. If you add a
> design doc, put it in `docs/` and add a row here.

---

## 1. Read this first, whoever you are

**The status legend, used in every design doc:**

| Mark | Meaning |
|---|---|
| ✅ | **Decided.** Safe to build against. |
| 📝 | **Draft.** Shape agreed, details may move. Safe to build against. |
| 💡 | **Idea bank.** Not adopted. Do not build. |
| ❓ | **Open question.** Needs a human ruling. Do not guess. |
| ⚠️ | **Risk / gotcha.** Balance concern, abuse vector, or a trap someone already fell into. |
| ⭐ | **Load-bearing rationale.** The *why* behind a decision — read before changing it. |

🚫 **Only ✅ and 📝 are safe to build.** If a design question is marked ❓,
surface it and ask; do not decide it in code.

---

## 2. Where to go, by what you want to do

### "I want to change gameplay"

| Question | Doc |
|---|---|
| How does a turn resolve? Priority, Haste, charge? | [GAME_DESIGN.md](docs/GAME_DESIGN.md) §1 |
| What do the twelve elements *do*? | [TYPE_EFFECTS_DESIGN.md](docs/TYPE_EFFECTS_DESIGN.md) |
| Exact resolution order / precedence pipeline | [TYPE_EFFECTS_DESIGN.md](docs/TYPE_EFFECTS_DESIGN.md) §5.1–5.2 |
| Spell list, costs, priorities | [GAME_DESIGN.md](docs/GAME_DESIGN.md) §3 |
| Levels, XP, unlock schedules | [PROGRESSION_DESIGN.md](docs/PROGRESSION_DESIGN.md) |
| Game modes (PvP, campaign, Discordant, Mortal) | [GAME_DESIGN.md](docs/GAME_DESIGN.md) §5 |

### "I want to change the world or the map"

| Question | Doc |
|---|---|
| Which places exist, how they connect, what is in them | [WORLD_DESIGN.md](docs/WORLD_DESIGN.md) |
| Travel times, mounts, trade, the Concord Market | [WORLD_DESIGN.md](docs/WORLD_DESIGN.md) §4b |
| 🗺️ **The current world map, rendered and labelled** | [docs/plates/world-map.html](docs/plates/world-map.html) |
| How the map is *drawn* (and the bugs that shaped it) | [docs/reviews/](docs/reviews/) |
| Visual plates / map artwork history | [docs/plates/](docs/plates/) |

### "I want to change items, crafting, or the economy"

| Question | Doc |
|---|---|
| Equipment slots, sets, rarity, modifiers | [ITEMS_DESIGN.md](docs/ITEMS_DESIGN.md) §1–4, §8 |
| Motes and the crafting currency ladder | [ITEMS_DESIGN.md](docs/ITEMS_DESIGN.md) §6 |
| Skills — gathering and processing | [ITEMS_DESIGN.md](docs/ITEMS_DESIGN.md) §6a |
| ⭐ **Crafting model, quality tiers, stations, gathering nodes, the wood ladder, naming grammar** | [ITEMS_DESIGN.md](docs/ITEMS_DESIGN.md) **§9b** — the newest and most concrete section |
| What can be traded, and what can never be | [ITEMS_DESIGN.md](docs/ITEMS_DESIGN.md) §6c |
| 🚫 **Monetization — read before touching anything purchasable** | [ITEMS_DESIGN.md](docs/ITEMS_DESIGN.md) **§3.6** |
| Achievements and character progress | [ACHIEVEMENTS_DESIGN.md](docs/ACHIEVEMENTS_DESIGN.md) |

### "I want to work on enemies or zone content"

| Question | Doc |
|---|---|
| ⭐ **The 16 enemy archetypes, and how an enemy is built** | [ENEMIES_DESIGN.md](docs/ENEMIES_DESIGN.md) §1–2 |
| ⭐ **Why a creature's fiction picks its archetype** — the rule everything else follows | [ENEMIES_DESIGN.md](docs/ENEMIES_DESIGN.md) **§2b** |
| ⭐ **Primal-quarter zone themes and full rosters** (commons, minis, bosses) | [ENEMIES_DESIGN.md](docs/ENEMIES_DESIGN.md) **§2d** |
| ⭐ **The Primal quarter's story arc** — what the five themes add up to | [GAME_DESIGN.md](docs/GAME_DESIGN.md) §5 |
| Element coverage across the world, and the late-zone proposal | [WORLD_DESIGN.md](docs/WORLD_DESIGN.md) §4c |
| ⭐ **The Sealed Garden** — the late Flora+Sanctus zone, and why Eden matters to the endgame | [WORLD_DESIGN.md](docs/WORLD_DESIGN.md) **§4c.1a** |
| ⭐ **The Buried Sky** — the late Geo+Astral zone | [WORLD_DESIGN.md](docs/WORLD_DESIGN.md) **§4c.1b** |
| ⭐ **What content each zone still needs** — the tracking grid | [CONTENT_CHECKLIST.md](docs/CONTENT_CHECKLIST.md) |
| 🎨 **What each creature looks like** — the descriptions | [BESTIARY_ART.md](docs/BESTIARY_ART.md) |
| 🎨 **Paste-ready image prompts**, and the art pipeline | [art/README.md](art/README.md) |
| Boss/mini-boss names per element, zone structure | [GAME_DESIGN.md](docs/GAME_DESIGN.md) §5, §3d |

### "I want to know what to work on"

⭐ **[IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) is the work queue.** It
holds the phase order, dependency gates, what is done, what is blocked and why,
and a *Deferred / banked* list of things deliberately **not** being built yet.
Read its §0 "Rules of engagement" before writing code — those are conventions
learned the hard way.

---

## 3. The rules that are easiest to break by accident

Four decisions cut across everything. Violating one usually looks fine locally
and breaks something distant.

1. 🚫 **Reserved vocabulary.** These words already mean something specific; do
   not reuse them for anything else:
   - **Bound** — permanently untradeable (ITEMS §6c). Not a name for modes,
     items, or statuses.
   - **Sudden Death** — the turn-51 fatigue mechanic (TYPE_EFFECTS §8).
   - **Eclipsed** — both the Lunar/Blind lock and the Eclipsed Citadel.
   - Every element's status name (Ignite, Waterlogged, Tailwind, Stagger,
     Creeping Dark, …). See ITEMS §9b.5b for the twelve aspect prefixes chosen
     specifically to avoid them.

2. ⚠️ **Determinism is load-bearing.** The duel is lockstep with commit-reveal
   netcode. **Every roll must draw from the shared per-turn seed** — a stray
   `Random()` in resolution code desyncs the two clients instantly.

3. ⚠️ **Fizzled, missed and fully-shielded casts behave like a charge** for
   every counter and trigger: they do not advance streaks, do not reset them,
   do not proc, do not grant stacks (TYPE_EFFECTS §5.4).

4. 🚫 **Monetization (ITEMS §3.6): nothing purchasable with RP may be
   unobtainable with gold.** RP buys *time*, and may even buy *gold*; there are
   no RP-only functional items (cosmetics excepted). ⭐ What actually enforces
   this is **tradability, not price** — so making a Bound item tradeable is a
   monetization decision, not an economy one.

---

## 4. Code layout

```
lib/                        Flutter app
  game/                     game logic, persistence, matchmaking, world data
  screens/                  UI (duel, home shell, tabs)
  ui/                       shared widgets, painters, the map camera
packages/mom_engine/        pure-Dart duel engine — no Flutter imports
  lib/src/                  duel resolution, elements, statuses, netcode, AI
  test/                     engine tests
  tool/balance_sim.dart     AI-vs-AI balance simulator
test/                       app-level widget tests
docs/                       ⭐ every design doc lives here
  plates/                   map artwork, generated + historical
  reviews/                  architecture reviews
art/                        source art and per-element palettes
  prompts/                  image-generation prompts, per zone
assets/creatures/           pixelated sprites, per zone
```

⭐ **The engine is deliberately Flutter-free.** It is a pure Dart package so it
can be tested exhaustively, run headless in the balance simulator, and one day
run server-side. Never import Flutter into `packages/mom_engine`.

⭐ **Almost everything is a `CustomPainter`** — the world map, the mage sprite,
element glyphs, every combat effect. That is why the map is seeded and
deterministic, and it stays true.

⚠️ **Amended 2026-08-02: creature art is the one exception.** A bestiary of 275
creatures is not something hand-placed pixels can carry — a full pass at
pixel-grid sprites produced nine interchangeable green lumps out of eleven
(IMPLEMENTATION_PLAN). Creatures and arena backdrops are therefore **generated
images**, pixelated through `tool/pixelate.py`; see [art/README.md](art/README.md).

⚠️ **The exception is bounded.** Anything else wanting a bitmap is still a real
decision, not a detail. And `CreatureView` **falls back** to the pixel grid, so
a zone without art renders rather than breaking.

---

## 5. Working on it

```sh
flutter test                              # app tests
(cd packages/mom_engine && dart test)     # engine tests — must run FROM the package
flutter analyze                           # must be clean
dart run packages/mom_engine/tool/balance_sim.dart

flutter test tool/render_map_test.dart   # redraw the world map plate...
python3 tool/build_map_plate.py          # ...then overlay its labels
```

⚠️ **Regenerate the map plate after any change to positions, roads or level
bands**, or `docs/plates/world-map.html` silently goes stale. It is two steps
because `flutter test` substitutes a placeholder font that draws every glyph as
a box — the terrain is painted by the real painter with text off, and the names
are overlaid as SVG.

⚠️ **The engine suite must be run from inside `packages/mom_engine`.** Invoking
`dart test packages/mom_engine` from the repo root fails with *"You need to add
a dev_dependency on package:test"* — it resolves the app's pubspec, not the
package's. The README said the wrong thing until 2026-08-02.

**Both suites must pass and `flutter analyze` must be clean before a commit.**

### Releasing

⚠️ **Always `flutter clean` before a release build.** `flutter build web` has
silently reused stale artifacts and shipped a build with whole features
missing.

```sh
flutter clean && flutter build web --release
firebase deploy --only hosting --project mastersofmagic2
```

⚠️ **Always pass `--project mastersofmagic2`**, so a deploy fails loudly if the
CLI happens to be authenticated to a different Firebase project.

Verify what actually shipped:

```sh
curl -s https://mastersofmagic2.web.app/version.json
```

Keep `pubspec.yaml`'s `version:` in sync with `lib/game/app_version.dart`, and
bump it every release — otherwise `version.json` cannot tell you which build is
live.

---

## 6. For AI agents specifically

- **Read [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) §0 first.** It is
  written for you and encodes conventions that have already cost real time.
- 🚫 **Do not do UI or browser verification.** Christian drives all visual
  testing. Write widget/unit tests for logic, then hand over an explicit list
  of manual steps.
- 🚫 **Do not guess on a ❓.** Surface it and ask.
- ⚠️ **Design docs are the source of truth for *intent*; code is the source of
  truth for *behaviour*.** When they disagree, say so rather than silently
  picking one — a stale doc and a bug look identical from the outside.
- ⚠️ **Check the reserved vocabulary in §3** before naming anything.
