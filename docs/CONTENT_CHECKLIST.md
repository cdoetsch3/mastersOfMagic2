# Content checklist — combat zones

**Single source of truth for what content each combat zone still needs.**
**26 combat zones, all built.** ⚠️ **The region list re-opened on 2026-08-08 and
was closed again the same day** — two north-road zones went in and came back
out; the road from Pennycross to Forgeholm now runs through the **Old Quarry**,
which already existed. ⭐ **The zone list is the one that was locked.** All 26
exist in `world.dart`, on the map, and in the routing table. Towns are tracked
separately (§4) because they need entirely different things.

Design lives elsewhere — this file only tracks *state*:
[ENEMIES_DESIGN.md](ENEMIES_DESIGN.md) ·
[ITEMS_DESIGN.md](ITEMS_DESIGN.md) ·
[WORLD_DESIGN.md](WORLD_DESIGN.md)

**Legend:** ✅ done · 🟡 partial · ⬜ not started · — not applicable

---

## 1. The columns, and what each one means

| # | Column | What "done" means | Depends on |
|---|---|---|---|
| 1 | **Band** | Level range set | ✅ already in `world.dart` |
| 2 | **Elem** | Element(s) assigned | ✅ already in `world.dart` |
| 3 | **Lore** | `blurb` + `arrival` text written | ✅ mostly done |
| 4 | **Roster** | Which archetypes fill each of the 3 sections, and how many | ENEMIES §2 |
| 5 | **Names** | A display name per enemy instance | Roster |
| 5b | **Moves** | ⭐ A move set per creature — **not** per archetype (ENEMIES §3). Beasts get creature moves; mage-type enemies draw from `Spellbook` | Names |
| 6 | **Minis** | Pool of **4** mini-bosses, coherent with the region (ENEMIES §4) | Roster |
| 7 | **Boss** | Pool of **2** bosses, coherent with the region (ENEMIES §4) | Roster |
| 8 | **BossFX** | What makes each boss more than a big statline | Boss |
| 9 | **Art** | ⭐ A **generated sprite per creature**, run through `tool/pixelate.py`. Prompts in `art/prompts/<zone>.md` | Names |
| 9b | **Backdrop** | The zone's arena scene, `--mode background`. One per zone, not per encounter | Lore |
| 10 | **Mats** | Which raw materials this zone yields | ITEMS §9b.6 |
| 11 | **Nodes** | Resource nodes placed — which skill, which material, per section | Mats |
| 12 | **Motes** | Which element motes drop, at which tiers | Elem |
| 13 | **Drop-C** | Drop table for common enemies | Mats, ITEMS §9b.6a |
| 14 | **Drop-M** | Drop table for mini-bosses | Minis |
| 15 | **Drop-B** | Drop table for bosses — incl. Bound set components | Boss |
| 15b | **Icons** | ⭐ An image per **item** the zone yields, same pipeline as creatures | Mats, Drop-* |
| 16 | **Ach** | The 3 achievements (Clear / Purge / Collect) | Roster, Drop-* |
| | | ⭐ **Clear** is unblocked — `PlayerProfile.zoneClears` exists. **Purge** needs a per-enemy defeat log (~4.2 clears per zone, since the pool shows 2 of 4 minis and 1 of 2 bosses). **Collect** needs items *and* a permanent seen-log separate from inventory. ACHIEVEMENTS §2.3 | |
| 17 | **Story** | ⭐ Three things now, not one: the `arrival` (poses), up to **3 section beats** (paced through the run), and the `epilogue` (answers) | Lore, Roster |

⭐ **Columns 1–3 are already mostly done for every zone** — that is 3 of 17
columns free, and the `arrival` passages are strong direction for everything
downstream. Column 12 derives from column 2 and should never be authored
by hand.

⚠️ **Columns 9, 9b and 15b were re-scoped 2026-08-05.** They used to say
"`CustomPainter` recipe, **not bitmaps**". ⭐ **That was tried and abandoned:**
a full pass of hand-authored pixel grids for Whispering Woods produced nine
interchangeable green lumps out of eleven. Creatures, backdrops and item icons
are now **generated images pixelated through `tool/pixelate.py`**
(see [../art/README.md](../art/README.md)); everything else in the game is
still a painter.

⭐ **These three columns are cheap per item and expensive in aggregate.** One
sprite is ~8 KB and a few minutes; the bestiary is 275 of them. Budget them as
a per-zone batch, not a per-creature task.

⚠️ **Icons (15b) has no pipeline mode yet.** Creatures and backdrops do;
`--mode icon` (small, square, probably 48px on a transparent field) is unbuilt.

---

## 2. The grid — Primal quarter (levels 1–14)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Backdrop | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Icons | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Whispering Woods** | ✅ 1–5 | ✅ Flora | ✅ | ✅ | ✅ 5 | ✅ | ✅ 4 | ✅ 2 | 🟡 | ✅ 11 | ⬜ | ✅ 2 | ✅ 2 | ✅ | ✅ | ✅ | ✅ | ⬜ | 🟡 | ✅ |
| **Glimmerbrook** | ✅ 3–8 | ✅ Aqua | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ✅ 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Cinderpeak Foothills** | ✅ 6–11 | ✅ Pyro | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ✅ 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Thornmire** | ✅ 8–13 | ✅ Flora+Aqua | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ✅ 3 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Ashfall Vale** | ✅ 10–14 | ✅ Pyro+Flora | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ✅ 3 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |

⭐ **Whispering Woods is BUILT** — `lib/game/enemies/whispering_woods.dart` and
`lib/game/items/catalogue/whispering_woods_items.dart`. 11 creatures with their
own move sets and drop tables, 13 items, guarded by 24 tests in
`test/whispering_woods_test.dart`. ⚠️ **It is the template for the other 26**,
so a change to its shape is a change to all of them.

⭐ **The Old Quarry became load-bearing for the story on 2026-08-08.** It is now
the only road into the range, the place the player first sees Forgeholm's ward
failing, and the source of the Sigil's Geo essence (NARRATIVE §4b.1). Its roster
already exists; what it needs is a theme that carries all three jobs.

⭐ It also lands the **first real gate item**: both bosses guarantee
`proof_of_the_woods`, one of Hearthwood's *"three ordinary proofs"* — until now
every gate in the game was a prose string with nothing behind it.

✅ **Art is done for this zone** — 11 generated sprites in
`assets/creatures/whispering_woods/`, and `CreatureView` draws them in the
duel. ⚠️ Two need re-cutting: the Hollow Stag lost its antlers and The
Standing Green lost detail, both to `rembg` during background removal rather
than to anything in the palette.

⚠️ Still open for this zone: **BossFX** (what makes each boss more than a big
statline), **Backdrop**, **Nodes** (gathering placement), **Icons**, and the
three **achievements**, which need the `progress/` subcollection.

🟡 **Names:** one placeholder existed per zone in `World.opponentNameFor` —
Thornback Sprite · Brook Naiad · Ashjaw Brute · Mirewalker · Cinderbloom Husk.
Good names; all five were **kept as their roster's anchor**.

📝 **Themes, 5 commons, 4 minis and 2 bosses are now drafted for ALL 25
rostered zones** (ENEMIES §2d–2e; the Citadel is exempt and needs its own
structure). ⚠️ **Minis and bosses are names + premises only — no archetypes
assigned yet**, which ENEMIES §2f flags as the blocking gap.

📝 **Originally drafted for the five Primal zones** — see [ENEMIES_DESIGN.md](ENEMIES_DESIGN.md) §2d. What that
leaves for the Primal quarter is columns **5b, 8, 9, 10–17**: move sets,
boss effects, painter recipes, materials, nodes, drop tables and achievements.

📝 **Story is now specified but not written.** Each Primal zone's Tier-1 beat
is defined by the quarter's arc (GAME_DESIGN §5) — the `arrival` text poses the
question, and a **zone-clear passage** answers it. The beats are decided; the
**26** clear passages are not yet drafted (one per combat zone).

⭐ **The order to do them in is `Mats → Nodes → Drop-*`, not left-to-right.**
Drop tables cannot be written before the materials exist, and three of the five
zones still have no materials assigned. Materials are the actual bottleneck for
eight of the seventeen columns.

✅ **Every Primal zone's materials are in code** (ITEMS §9b.8): pure zones
carry 2, hybrids 3, and the hybrid extras all ⏳ bank for later skills —
Copper and Charcoal for Metalworking, Fenroot for the Antidote, Amber for
Jewelry. The full list is `docs/wiki/content.json`, never this file.

---

## 2a. ⭐ What to do next, in order

Measured off the grid above, not from memory.

| # | Work | Why it is first |
|---|---|---|
| **1** | ⭐ **Build the other four Primal zones** — enemies, moves, items, drop tables | Whispering Woods proved the shape and is the template. Four zones × 11 creatures = the rest of the quarter playable. Everything downstream (icons, nodes, achievements) needs these to exist first |
| **2** | **Gathering nodes** (col 11) | The only ⬜ that blocks a whole *skill*. Materials exist and drop from kills; nothing can be gathered from the world yet, so Woodcarving has no input that is not a corpse |
| **3** | **Icons** (col 15b) | New column. Needs `--mode icon` in the pipeline first — small, square, transparent field |
| **4** | **Backdrops** (col 9b) | 26 prompts already written from the `arrival` text; the pipeline mode exists. Cheapest visual win per hour on the board |
| **5** | **BossFX** (col 8) | The only design work left in the quarter. What makes Heartwood more than a big statline |
| **6** | ⛔ **Achievements** (col 16) | Blocked on the `progress/` subcollection, which is logged in IMPLEMENTATION_PLAN and unbuilt |
| **7** | **Story** (col 17) | 26 zone-clear passages. Arrival poses the question; the clear answers it (GAME_DESIGN §5) |

⚠️ **Two things are NOT on this list and should be**, because they block
shipping rather than content:

- ⛔ **The login content-version gate.** The moment item *stats* exist, two
  clients on different builds disagree about what a staff does and the lockstep
  duel diverges — presenting as a netcode bug rather than a data bug.
- ⚠️ **Nothing equips.** `EquipmentDef` drops and is carried, but
  `ItemModifiers` reaches no `MageState`. The paper doll is display-only, so
  every piece of gear in the quarter is currently decorative.

---

## 3. The grid — remaining zones

### Kinetic (15–29)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Backdrop | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Icons | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Old Quarry** | ✅ 15–19 | ✅ Geo | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Stormcliff Coast** | ✅ 17–22 | ✅ Electro | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Windward Steppe** | ✅ 19–24 | ✅ Aero | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Yew | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Frostfell Pass** | ✅ 21–26 | ✅ Aqua+Aero | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Thunderspire Peaks** | ✅ 23–28 | ✅ Electro+Aero | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Rowan | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Molten Deep** 🏰 | ✅ 25–29 | ✅ Pyro+Geo | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Celestial (30–44)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Backdrop | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Icons | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **The Kiln Desert** | ✅ 30–34 | ✅ Solar | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Ironwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Mirrormere** | ✅ 32–37 | ✅ Lunar | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Bloodwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Starfall Basin** | ✅ 34–39 | ✅ Astral | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Tidewrack Shoals** | ✅ 36–40 | ✅ Lunar+Aqua | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Sunless Reach** | ✅ 38–42 | ✅ Solar+Lunar | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Ebony | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Shattered Orrery** 🏰 | ✅ 40–44 | ✅ Astral+Electro | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Glass Archive** 🏰 | ✅ 43–47 | ✅ Solar+Arcane | ✅ | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Ethereal (45–60)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Backdrop | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Icons | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Hallowmarch** | ✅ 45–49 | ✅ Sanctus | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Spiritwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Umbral Wastes** | ✅ 47–51 | ✅ Umbra | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Collapsed Academy** 🏰 | ✅ 50–54 | ✅ Arcane | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | 🟡 Aetherwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Reliquary Deep** 🏰 | ✅ 52–56 | ✅ Sanctus+Umbra | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Unwritten Library** 🏰 | ✅ 54–58 | ✅ Umbra+Arcane | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Buried Sky** 🏰 | ✅ 46–50 | ✅ Geo+Astral | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Sealed Garden** | ✅ 49–53 | ✅ Flora+Sanctus | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Eclipsed Citadel** 🏰 | ✅ 58–60 | ✅ all | 🟡 | ❓ | 🟡 1 | ⬜ | ❓ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

🏰 = dungeon rather than route.

❓ **The Citadel is deliberately NOT on the 5/4/2 template.** It is the finale
and carries all twelve elements; a flat roster of five commons cannot express
that. ENEMIES §2e proposes its encounters be **echoes of bosses the player has
already beaten**, which is the only structure that can field twelve elements
and costs almost nothing in new content. Needs a ruling.

✅ **The Sealed Garden and The Buried Sky are built** — locations, map pins,
roads, themed opponents, `blurb` and `arrival` text. Routing is derived from
edges, so Floyd–Warshall picked them up with no change to `travel.dart`;
verified reachable from Hearthwood in both directions with zero unreachable
same-plane pairs. Design in WORLD_DESIGN §4c.1a–1b.

⭐ **Both are the only zones whose Lore is ✅ rather than 🟡** — their `arrival`
passages were written *after* the theme, so for once the text states the theme
outright instead of the theme being recovered from it.

🟡 **Minis/Boss partial credit comes from the element rosters** in GAME_DESIGN
§5, which name 3 mini-bosses and 1 boss per element. For the nine non-Primal
**pure** zones that mapping is 1:1, so each already has candidate names against
the 4-and-2 target. ⚠️ **The Primal pure zones get no such credit** — their
element rosters were epic-scale and were either re-homed (§2c) or replaced
outright by the ENEMIES §2d rosters.

🟡 **Two hybrids inherited a re-homed name each:** The Molten Deep took Efreet
and Magma Behemoth; Tidewrack Shoals took Kraken and Leviathan.

✅ **Every element now sits in 3–4 zones** — the target met exactly.
`test/world_test.dart` asserts the 3–4 range (not just a floor) and that no
element tops out below band 28.

🗺️ **[docs/plates/world-map.html](plates/world-map.html) is the current
map.** Regenerate it after any change to positions, roads or bands with
`flutter test tool/render_map_test.dart`.

---

## 4. Towns — tracked separately

Towns need none of the above and several things zones do not: shop inventory,
station recipes, prices, and the per-character daily stock (ITEMS §9b.7).

| Town | Opens | Station | Shop stock | Recipes | Prices |
|---|---|---|---|---|---|
| **Hearthwood** | 1 | ✅ Woodcarving | ⬜ | ⬜ | ⬜ |
| **Pennycross** | 8 | ✅ Tailoring | ⬜ | ⬜ | ⬜ |
| **Forgeholm** | 15 | ✅ Metalworking | ⬜ | ⬜ | ⬜ |
| **Galehaven** | 22 | ✅ Potions & Alchemy | ⬜ | ⬜ | ⬜ |
| **Concordance** | 30 | — (trade capital) | ⬜ | — | ⬜ |
| **Meridian** | 36 | ✅ Enchanting | ⬜ | ⬜ | ⬜ |
| **Rimeholt** | 45 | ✅ Jewelry | ⬜ | ⬜ | ⬜ |
| **Vespergate** | 50 | — | ⬜ | — | ⬜ |
| **Zenith** | 60 | ✅ all six | ⬜ | ⬜ | ⬜ |

✅ **Stations now match the design in `world.dart`** — Pennycross has
Tailoring, Galehaven has Potions & Alchemy, and Vespergate has none.

---

## 5. Reading the grid — where the work actually is

**17 columns × 23 zones = 391 cells.** Roughly 70 are already done (bands,
elements, most lore, the placeholder names), leaving ~320.

⭐ **But the archetype model collapses much of it.** Columns 4 and 9 (Roster,
Art) are *assignments from a fixed set of 15*, not fresh designs — picking
which archetypes appear is minutes per zone once the set exists. The genuinely
expensive columns are:

| Expensive | Why |
|---|---|
| **Minis + Boss** | 3–5 and 1–2 *per zone* = 70–130 designs. GAME_DESIGN §3d already flags this as "the single largest content task" |
| **Drop-C/M/B** | Three tables per zone, and the rarest entry in each sets the length of the Collect achievement |
| **Names** | ~10 per zone once rosters exist |

📝 **Suggested order per zone** (demand before supply, per the earlier ruling):
Roster → Names → Minis/Boss → Mats → Nodes → Drop tables → Art → Ach → Story.

✅ **Resolved (2026-08-02): every region has its own complete, coherent
roster** — **4 mini-bosses and 2 bosses**, hybrids included. No zone borrows
from a parent element.

✅ **Drafted in full for all 25 rostered zones** (ENEMIES §2d–2e):
**125 commons, 100 mini-bosses, 50 bosses — 172 distinct names.** Every theme
was recovered from that zone's own `arrival` passage rather than invented.

✅ **Archetypes assigned to all 150 minis and bosses** (ENEMIES §2g, first
pass). Every zone fields one Champion, Redoubt, Executioner and Hexer, so a
2-of-4 draw is always a different pair of roles; bosses split
Juggernaut 17 / Tyrant 17 / Aspect 16.

✅ **Elements resolved (ENEMIES §2h):** pure zones use their element; hybrids
may assign one of the two per creature or use both; and in the **Celestial and
Ethereal quarters** a mini or boss may carry a third element sparingly — never
the counter to the zone's own, which would punish correct preparation.

⛔ **Still missing per creature:** its move set (§3 — creatures get creature
moves, not spells). Coefficients stay at the archetype defaults until the
balance sim moves them.

⚠️ **Other gaps §2f found:** Adept appears in only 10 of 25 zones despite being
the yardstick every other archetype is felt against; the Siphon is in 12 of 25,
which dilutes the one archetype meant to be a shock; two Drudges sit at levels
45–54 where a 0.80/0.70 "barely fights" enemy is a wasted slot; and Stormcliff
Coast and Thunderspire Peaks are adjacent Electro zones built on the same idea.
