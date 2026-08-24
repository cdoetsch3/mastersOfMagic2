# The content export — how the wiki gets fed

**The documentation framework for items, recipes, creatures and zones.** One
rule, one artifact, one guard — established while the game has exactly one
finished zone, so the other 25 inherit it instead of retrofitting it.

---

## 1. The rule: code is canonical, everything else is generated

⭐ **Every number lives in exactly one place: a Dart const.** `ItemDef`,
`RecipeDef`, `EnemyDef`, `GameLocation` (ITEMS §10.1, ENEMIES §1.2). The wiki,
the design docs' tables, and any future companion app read the export — they
never hold a second copy of a drop rate.

⚠️ **The prose docs keep the *why*, never the *what*.** ITEMS_DESIGN says
"rarity buys capability, not bigger numbers"; it does not say the Sporecap
Mantle has `dodge: 3`. The moment a doc states a stat, that stat exists twice
and one of them is wrong within a month. Design docs argue; the export
reports.

📝 **Corollary for how we work:** design sessions (like the Primal recipe
session) still happen in prose first — proposals, rulings, tables. But the
table in the doc is a *draft*; the moment it lands in a catalogue file, the
doc's copy is replaced by a pointer to the export. Drafts are allowed to be
wrong; only the code is required to be true.

## 2. The artifact: `docs/wiki/content.json`

Built by [`ContentExport.build()`](../lib/game/content_export.dart) — one JSON
document with a `schemaVersion`, four entity lists, and the derived index:

| Key | Contents |
|---|---|
| `zones` | Every `GameLocation`: band, elements, gate, arrival, beats, epilogue, edges |
| `creatures` | Every `EnemyDef`: rank, archetype, moves, full drop tables **with computed fractions** |
| `items` | Every `ItemDef`: kind, rarity, slot, modifiers, salvage, effects |
| `recipes` | Every `RecipeDef`: skill, skill level, inputs, output, station requirement |
| `index` | ⭐ `itemSources` + `itemUses` — see §4 |

Regenerate after any content change:

```bash
flutter test tool/export_content_test.dart
```

Same two-step pattern as the world map: a `tool/` test writes the artifact
because only `flutter test` runs the real game code cheaply, and
`test/content_export_test.dart` holds the guarantees.

⚠️ **`schemaVersion` bumps on any breaking shape change**, so a wiki built
against an old layout fails loudly instead of rendering blanks.

## 3. The guard: `test/content_export_test.dart`

The reason this scales is not the JSON — it is the tests that run on every
`flutter test`:

- **Determinism.** Two builds encode byte-identically. No timestamps, no
  `Random`, no ordering that depends on insertion elsewhere.
- ⭐ **Referential integrity.** Every id any table references — drops,
  salvage, recipe inputs, recipe outputs — must resolve in a catalogue.
  A zone file that names `oakk_log` compiles clean and **fails here**. This
  is what lets zone 7 be written without re-auditing zones 1–6.
- **Index correctness.** Spot-checked with teeth (oak_log's sources include a
  Whispering Woods drop; the gate item is sourced from both bosses).

## 4. The index — the two questions every wiki page asks

*"Where does X come from?"* and *"What is X used for?"*

⭐ **Both are derived by walking the same tables the game rolls, never
authored.** A hand-written "obtained from" list is stale the first time a
drop table moves; a derived one cannot disagree with the game.

```
itemSources: oak_log ← drop (listening_fawn, 34%) · salvage (oak_circlet) · node (📝 when nodes exist)
itemUses:    oak_log → recipeInput (oak_quarterstaff) · salvageInto (from heartwood_stave)
```

Gathering nodes, quest rewards and shop stock **must** register as source
types here when they are built — a source the index cannot see is a wiki page
that lies.

## 5. Adding a zone — the checklist the framework enforces

1. `lib/game/enemies/<zone>.dart` — creatures, moves, drop tables; list it in
   `Bestiary.all`.
2. `lib/game/items/catalogue/<zone>_items.dart` — items; list it in
   `ItemCatalogue.all`.
3. `lib/game/items/recipes/<band>_recipes.dart` — recipes; list it in
   `RecipeBook.all`. ⭐ **Recipes group by band/skill, not strictly by zone** —
   a recipe's inputs deliberately cross zones (Oak from the Woods, copper
   fittings from Cinderpeak), so a per-zone recipe file would be a fiction.
4. `flutter test` — the catalogue id tests and the export's referential check
   tell you what you forgot.
5. `flutter test tool/export_content_test.dart` — regenerate the artifact.

⚠️ **Forgetting a catalogue listing is the designed-for failure.** Every
catalogue is a hand-maintained list precisely so that one test can walk it;
the integrity tests exist because step 4's mistake is silent otherwise.

## 6. The human-readable rendering: `docs/wiki/REFERENCE.md`

📖 **A SECOND GENERATED OUTPUT of the same pipeline** (designer ask,
2026-08-20), built by [`ContentReference.build()`](../lib/game/content_reference.dart)
and written by the same `tool/export_content_test.dart` run that writes
`content.json` — one `flutter test` refreshes both. Never hand-edited; never
a second truth, because it walks the exact catalogues `ContentExport` walks
(`Bestiary`, `ItemCatalogue`, `RecipeBook`, `GatherNodes`, `World`) rather
than parsing `content.json` back apart.

**The headline feature is the reverse stat index** — one table per
`ItemModifiers` field (accuracy, dodge, crit, deflect, max HP, the two
damage-per-cast lanes, shield strength, healing received, regrow, belt
slots), listing every item that carries it. "What already grants % shield"
used to mean grepping five catalogue files; now it is one lookup, with a
field no item carries listed explicitly under "No item grants" so absence
reads as *checked*, not *forgotten*.

⚠️ Values there are the DEF's base numbers — quality (Rough/Standard/Ornate/
Master) scales every combat stat per-instance at 80/100/120/140%
(`ItemModifiers.scaledBy`), so a dropped or crafted instance can read higher
or lower than the table.

Below that: items by zone (with a stat summary and a derived "obtained by" —
craft output, gather yield, or drop, cross-referencing `RecipeBook`,
`GatherNodes` and every `Bestiary` drop table), bestiary by zone (rank,
archetype, element, the zone's enemy band, HP/damage scale, and notable
main/bonus drops), and recipes by skill (gate, inputs, output, and XP from
the shipped `Skills.xpForRecipe` formula — never a re-typed number).

Guarded by `test/content_reference_test.dart`, mutation-shaped per the two
failure modes a reverse index can have without anyone noticing: a scan that
only walks the first zone's catalogue, and a filter that leaks zero-valued
fields into a table that promises only nonzero ones.

## 7. What the wiki itself will be

📝 Unbuilt, deliberately. When it exists it is a static site generated from
`content.json` — no game code, no Dart, just a renderer over the export. That
is the payoff of §1: the wiki team (or the wiki evening) never needs to read
a catalogue file, and a content patch updates every page by regenerating one
JSON document.

❓ Open: whether spoiler-tier content (boss uniques, endgame zones) is
filtered at export time or render time. Lean: render time, with a `spoiler`
flag derived from band — the export should stay the whole truth.
