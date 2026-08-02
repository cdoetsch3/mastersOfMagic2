# Content checklist — combat zones

**Single source of truth for what content each combat zone still needs.**
**26 combat zones, all built.** ✅ The region list is CLOSED — The Sealed
Garden, The Buried Sky and The Glass Archive were the last three, and all now
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
| 9 | **Art** | A `CustomPainter` recipe per enemy — ⚠️ **not bitmaps**, this project has no image assets | Roster |
| 10 | **Mats** | Which raw materials this zone yields | ITEMS §9b.6 |
| 11 | **Nodes** | Resource nodes placed — which skill, which material, per section | Mats |
| 12 | **Motes** | Which element motes drop, at which tiers | Elem |
| 13 | **Drop-C** | Drop table for common enemies | Mats, ITEMS §9b.6a |
| 14 | **Drop-M** | Drop table for mini-bosses | Minis |
| 15 | **Drop-B** | Drop table for bosses — incl. Bound set components | Boss |
| 16 | **Ach** | The 3 achievements (Clear / Purge / Collect) | Roster, Drop-* |
| | | ⭐ **Clear** is unblocked — `PlayerProfile.zoneClears` exists. **Purge** needs a per-enemy defeat log (~4.2 clears per zone, since the pool shows 2 of 4 minis and 1 of 2 bosses). **Collect** needs items *and* a permanent seen-log separate from inventory. ACHIEVEMENTS §2.3 | |
| 17 | **Story** | Tier-1 narrative beat, if this zone gets one | GAME_DESIGN §5 |

⭐ **Columns 1–3 are already mostly done for every zone** — that is 3 of 17
columns free, and the `arrival` passages are strong direction for everything
downstream. Column 12 derives from column 2 and should never be authored
by hand.

⚠️ **Column 9 is the one to be careful about.** "Images for the enemies" was
the original phrasing, but there are **no image assets anywhere in this
project** — every visual is a `CustomPainter`. Treat this column as "painter
recipe + palette", parameterised by archetype with the element supplying
colour, and it stays cheap. Treat it as bitmaps and it becomes an art
pipeline, a licensing question, and download weight.

---

## 2. The grid — Primal quarter (levels 1–14)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Whispering Woods** | ✅ 1–5 | ✅ Flora | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Oak | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Glimmerbrook** | ✅ 3–8 | ✅ Aqua | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Cinderpeak Foothills** | ✅ 6–11 | ✅ Pyro | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Thornmire** | ✅ 8–13 | ✅ Flora+Aqua | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |
| **Ashfall Vale** | ✅ 10–14 | ✅ Pyro+Flora | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Birch | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📝 |

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

📝 **Known Primal materials so far:** Oak (Whispering Woods) and Birch (Ashfall
Vale) from the wood ladder (ITEMS §9b.6). Glimmerbrook, Cinderpeak and
Thornmire have no materials assigned yet.

---

## 3. The grid — remaining zones

### Kinetic (15–29)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Old Quarry** | ✅ 15–19 | ✅ Geo | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Stormcliff Coast** | ✅ 17–22 | ✅ Electro | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Windward Steppe** | ✅ 19–24 | ✅ Aero | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Yew | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Frostfell Pass** | ✅ 21–26 | ✅ Aqua+Aero | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Thunderspire Peaks** | ✅ 23–28 | ✅ Electro+Aero | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Rowan | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Molten Deep** 🏰 | ✅ 25–29 | ✅ Pyro+Geo | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Celestial (30–44)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **The Kiln Desert** | ✅ 30–34 | ✅ Solar | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Ironwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Mirrormere** | ✅ 32–37 | ✅ Lunar | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Bloodwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Starfall Basin** | ✅ 34–39 | ✅ Astral | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Tidewrack Shoals** | ✅ 36–40 | ✅ Lunar+Aqua | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Sunless Reach** | ✅ 38–42 | ✅ Solar+Lunar | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Ebony | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Shattered Orrery** 🏰 | ✅ 40–44 | ✅ Astral+Electro | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Glass Archive** 🏰 | ✅ 43–47 | ✅ Solar+Arcane | ✅ | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Ethereal (45–60)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Hallowmarch** | ✅ 45–49 | ✅ Sanctus | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Spiritwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Umbral Wastes** | ✅ 47–51 | ✅ Umbra | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Collapsed Academy** 🏰 | ✅ 50–54 | ✅ Arcane | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | 🟡 Aetherwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Reliquary Deep** 🏰 | ✅ 52–56 | ✅ Sanctus+Umbra | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Unwritten Library** 🏰 | ✅ 54–58 | ✅ Umbra+Arcane | 🟡 | 📝 | 🟡 1 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Buried Sky** 🏰 | ✅ 46–50 | ✅ Geo+Astral | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Sealed Garden** | ✅ 49–53 | ✅ Flora+Sanctus | ✅ | 📝 | 📝 5 | ⬜ | 📝 4 | 📝 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Eclipsed Citadel** 🏰 | ✅ 58–60 | ✅ all | 🟡 | ❓ | 🟡 1 | ⬜ | ❓ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

🏰 = dungeon rather than route.

❓ **The Citadel is deliberately NOT on the 5/4/2 template.** It is the finale
and carries all twelve elements; a flat roster of five commons cannot express
that. ENEMIES §2e proposes its encounters be **echoes of bosses the player has
already beaten**, which is the only structure that can field twelve elements
and costs almost nothing in new content. Needs a ruling.

✅ **The Sealed Garden and The Buried Sky are built** — locations, map pins,
roads, themed opponents, `blurb` and `arrival` text. Routing is derived from
edges, so Floyd–Warshall picked them up with no change to `travel.dart`;
verified reachable from Aldermere in both directions with zero unreachable
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

🗺️ **[docs/plates/world-map.html](docs/plates/world-map.html) is the current
map.** Regenerate it after any change to positions, roads or bands with
`flutter test tool/render_map_test.dart`.

---

## 4. Towns — tracked separately

Towns need none of the above and several things zones do not: shop inventory,
station recipes, prices, and the per-character daily stock (ITEMS §9b.7).

| Town | Opens | Station | Shop stock | Recipes | Prices |
|---|---|---|---|---|---|
| **Aldermere** | 1 | ✅ Woodcarving | ⬜ | ⬜ | ⬜ |
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

⛔ **What is NOT done, and it is the half that decides whether a fight is
good:** all 150 mini-bosses and bosses are **names and premises with no
archetype attached**. §2.2–2.3 define seven elevated archetypes and none of the
150 is mapped to one. Nothing can be built or balance-simmed until they are.

⚠️ **Other gaps §2f found:** Adept appears in only 10 of 25 zones despite being
the yardstick every other archetype is felt against; the Siphon is in 12 of 25,
which dilutes the one archetype meant to be a shock; two Drudges sit at levels
45–54 where a 0.80/0.70 "barely fights" enemy is a wasted slot; and Stormcliff
Coast and Thunderspire Peaks are adjacent Electro zones built on the same idea.
