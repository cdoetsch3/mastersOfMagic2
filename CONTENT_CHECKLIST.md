# Content checklist — combat zones

**Single source of truth for what content each combat zone still needs.**
23 combat zones. Towns are tracked separately (§4) because they need entirely
different things.

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

📝 **Themes, 5 commons, 4 minis and 2 bosses are now drafted for all five
Primal zones** — see [ENEMIES_DESIGN.md](ENEMIES_DESIGN.md) §2d. What that
leaves for the Primal quarter is columns **5b, 8, 9, 10–17**: move sets,
boss effects, painter recipes, materials, nodes, drop tables and achievements.

📝 **Story is now specified but not written.** Each Primal zone's Tier-1 beat
is defined by the quarter's arc (GAME_DESIGN §5) — the `arrival` text poses the
question, and a **zone-clear passage** answers it. The beats are decided; the
23 clear passages are not yet drafted.

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
| **Old Quarry** | ✅ 15–19 | ✅ Geo | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Stormcliff Coast** | ✅ 17–22 | ✅ Electro | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Windward Steppe** | ✅ 19–24 | ✅ Aero | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Yew | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Frostfell Pass** | ✅ 21–26 | ✅ Aqua+Aero | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Thunderspire Peaks** | ✅ 23–28 | ✅ Electro+Aero | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Rowan | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Molten Deep** 🏰 | ✅ 25–29 | ✅ Pyro+Geo | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Celestial (30–44)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **The Kiln Desert** | ✅ 30–34 | ✅ Solar | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Ironwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Mirrormere** | ✅ 32–37 | ✅ Lunar | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Bloodwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Starfall Basin** | ✅ 34–39 | ✅ Astral | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Tidewrack Shoals** | ✅ 36–40 | ✅ Lunar+Aqua | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Sunless Reach** | ✅ 38–42 | ✅ Solar+Lunar | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Ebony | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Shattered Orrery** 🏰 | ✅ 40–44 | ✅ Astral+Electro | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Ethereal (45–60)

| Zone | Band | Elem | Lore | Roster | Names | Moves | Minis | Boss | BossFX | Art | Mats | Nodes | Motes | Drop-C | Drop-M | Drop-B | Ach | Story |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Hallowmarch** | ✅ 45–49 | ✅ Sanctus | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Spiritwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Umbral Wastes** | ✅ 47–51 | ✅ Umbra | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Collapsed Academy** 🏰 | ✅ 50–54 | ✅ Arcane | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 Aetherwood | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Reliquary Deep** 🏰 | ✅ 52–56 | ✅ Sanctus+Umbra | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Unwritten Library** 🏰 | ✅ 54–58 | ✅ Umbra+Arcane | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **The Eclipsed Citadel** 🏰 | ✅ 58–60 | ✅ all | 🟡 | ⬜ | 🟡 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

🏰 = dungeon rather than route.

---

## 4. Towns — tracked separately

Towns need none of the above and several things zones do not: shop inventory,
station recipes, prices, and the per-character daily stock (ITEMS §9b.7).

| Town | Opens | Station | Shop stock | Recipes | Prices |
|---|---|---|---|---|---|
| **Aldermere** | 1 | ✅ Woodcarving | ⬜ | ⬜ | ⬜ |
| **Pennycross** | 8 | ✅ Tailoring | ⬜ | ⬜ | ⬜ |
| **Forgeholm** | 15 | ✅ Metalworking | ⬜ | ⬜ | ⬜ |
| **Galehaven** | 22 | 🟡 Potions & Alchemy ⚠️ | ⬜ | ⬜ | ⬜ |
| **Concordance** | 30 | — (trade capital) | ⬜ | — | ⬜ |
| **Meridian** | 36 | ✅ Enchanting | ⬜ | ⬜ | ⬜ |
| **Rimeholt** | 45 | ✅ Jewelry | ⬜ | ⬜ | ⬜ |
| **Vespergate** | 50 | — | ⬜ | — | ⬜ |
| **Zenith** | 60 | ✅ all six | ⬜ | ⬜ | ⬜ |

⚠️ **Galehaven and Vespergate are decided in the docs but not yet changed in
`world.dart`** — the code still has Tailoring at Galehaven and Potions at
Vespergate. Pending edit, see ITEMS §9b.1.

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

✅ **Resolved (2026-08-02): every region gets its own complete, coherent
roster** — 5 mini-bosses and 3 bosses, hybrids included (ENEMIES §4). No zone
borrows from a parent element.

⚠️ **The scope that commits to: 92 mini-bosses and 46 bosses across 23 zones**
— 20 and 10 for the Primal quarter alone. Still the single biggest content
task in the project. The archetype layer absorbs the statlines; what remains
new per enemy is a creature, a name, a move set and art.

📝 **12 pure zones** can start from GAME_DESIGN §5's existing per-element names
(3 of 5 minis each). **11 zones** — the 10 hybrids plus the Eclipsed Citadel —
have nothing today and need rosters built from scratch.
