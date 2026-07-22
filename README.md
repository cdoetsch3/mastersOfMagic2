# Masters of Magic 2

A simultaneous-turn elemental mage-duel game. Flutter, targeting phones,
tablets, and browsers. Live at <https://mastersofmagic2.web.app>.

Both players lock in a move each turn, then the round resolves — prediction
and mind-games are the point. The duel engine is pure Dart, deterministic,
and runs lockstep with commit-reveal netcode.

## Start here

| Doc | What it covers |
|---|---|
| **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)** | ⭐ **The work queue.** Phased plan spanning every design doc, with dependency gates and rules of engagement. Read first. |
| [GAME_DESIGN.md](GAME_DESIGN.md) | Core combat, priority/Haste, spells, world map, bestiary, app roadmap |
| [TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md) | Elements and their side-effects; turn phases and the precedence pipeline. §0 is the planned V2 twelve-element expansion |
| [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) | Levels, XP, unlock schedule, charge caps |
| [ITEMS_DESIGN.md](ITEMS_DESIGN.md) | Equipment, sets, motes, crafting, enchanting, potions, the economy |

Docs use a status legend: ✅ decided · 📝 draft · 💡 idea bank · ❓ open
question · ⚠️ balance or abuse concern. **Only ✅ and 📝 are safe to build.**

## Layout

```
lib/                        Flutter app
  game/                     game logic, persistence, matchmaking
  screens/                  UI (duel, home shell, tabs)
packages/mom_engine/        pure-Dart duel engine — no Flutter imports
  lib/src/                  duel resolution, elements, statuses, netcode, AI
  test/                     engine tests
  tool/balance_sim.dart     AI-vs-AI balance simulator
test/                       app-level widget tests
```

## Working on it

```sh
flutter test                          # app tests
dart test packages/mom_engine         # engine tests
dart run packages/mom_engine/tool/balance_sim.dart
```

⚠️ **Always `flutter clean` before a release build.** `flutter build web` has
silently reused stale artifacts and shipped a build with whole features
missing. Verify a deploy with:

```sh
curl -s https://mastersofmagic2.web.app/main.dart.js | grep -o "0\.9\.[0-9]*"
```

Keep the version in `pubspec.yaml` in sync with `lib/game/app_version.dart`.
