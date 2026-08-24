# Masters of Magic 2 — Item & Bestiary Reference

⚠️ **GENERATED from code by the content export — do not edit.** Regenerate
both this file and `docs/wiki/content.json` with:

```
flutter test tool/export_content_test.dart
```

Source of truth: [`lib/game/content_export.dart`](../../lib/game/content_export.dart)
builds `content.json`; [`lib/game/content_reference.dart`](../../lib/game/content_reference.dart)
builds this file from the same catalogues. See `docs/CONTENT_EXPORT.md` for
the framework both live under.

## Counts

| Zones | Towns | Creatures | Items | Recipes | Gather nodes |
|---|---|---|---|---|---|
| 26 | 9 | 66 | 61 | 20 | 12 |

## Contents

- [Reverse stat index](#reverse-stat-index)
- [Items by zone](#items-by-zone)
- [Bestiary by zone](#bestiary-by-zone)
- [Recipes by skill](#recipes-by-skill)

## Reverse stat index

One table per `ItemModifiers` field: every item that carries it, so "what already grants % shield" is one lookup instead of a grep across five catalogue files.

⚠️ **Values are the DEF's base numbers.** Quality (Rough/Standard/Ornate/Master) scales every combat stat per-instance at 80/100/120/140% (`ItemModifiers.scaledBy`) — an actual dropped or crafted item can read higher or lower than the row below.

### `accuracyBonus`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Bindweed Hood | `bindweed_hood` | 1 | hat | common | 1 | whispering_woods |
| Oak Circlet | `oak_circlet` | 1 | hat | common | 1 | whispering_woods |
| Oak Knot | `oak_knot` | 3 | offHand | common | 1 | whispering_woods |
| Oak Quarterstaff | `oak_quarterstaff` | 5 | mainHand | common | 1 | whispering_woods |
| Sporecap Mantle | `sporecap_mantle` | 2 | robeTop | rare | 4 | whispering_woods |
| Heartwood Staff | `heartwood_stave` | 7 | mainHand | epic | 5 | whispering_woods |
| Bogflax Hood | `bogflax_hood` | 2 | hat | common | 10 | thornmire |
| Birch Knot | `birch_knot` | 4 | offHand | common | 10 | ashfall_vale |
| Birch Quarterstaff | `birch_quarterstaff` | 6 | mainHand | common | 10 | ashfall_vale |
| Birch Wand | `birch_wand` | 1 | mainHand | common | 10 | ashfall_vale |

### `critChance`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Heartwood Staff | `heartwood_stave` | 5 | mainHand | epic | 5 | whispering_woods |
| Cinder Loop | `cinder_loop` | 5 | ring | rare | 9 | cinderpeak_foothills |

### `critDamage`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Heartwood Staff | `heartwood_stave` | 10 | mainHand | epic | 5 | whispering_woods |
| Cinder Loop | `cinder_loop` | 5 | ring | rare | 9 | cinderpeak_foothills |

### `deflectChance`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Overseer's Seal | `overseers_seal` | 12 | ring | rare | 18 | old_quarry |
| The Given Weight | `the_given_weight` | 10 | neck | epic | 19 | old_quarry |

### `deflectAmount`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Overseer's Seal | `overseers_seal` | 20 | ring | rare | 18 | old_quarry |
| The Given Weight | `the_given_weight` | 25 | neck | epic | 19 | old_quarry |

### `maxHpBonus`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Bindweed Boots | `bindweed_boots` | 1 | boots | common | 1 | whispering_woods |
| Bindweed Gloves | `bindweed_gloves` | 1 | gloves | common | 1 | whispering_woods |
| Bindweed Leggings | `bindweed_leggings` | 4 | robeBottom | common | 1 | whispering_woods |
| Bindweed Robe | `bindweed_robe` | 6 | robeTop | common | 1 | whispering_woods |
| Sporecap Mantle | `sporecap_mantle` | 12 | robeTop | rare | 4 | whispering_woods |
| Bogflax Boots | `bogflax_boots` | 2 | boots | common | 10 | thornmire |
| Bogflax Gloves | `bogflax_gloves` | 2 | gloves | common | 10 | thornmire |
| Bogflax Leggings | `bogflax_leggings` | 7 | robeBottom | common | 10 | thornmire |
| Bogflax Robe | `bogflax_robe` | 10 | robeTop | common | 10 | thornmire |
| The Given Weight | `the_given_weight` | 30 | neck | epic | 19 | old_quarry |

### `damagePerCast`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Oak Wand | `oak_wand` | 2 | mainHand | common | 1 | whispering_woods |
| Birch Wand | `birch_wand` | 3 | mainHand | common | 10 | ashfall_vale |

### `damagePerCharge`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Oak Quarterstaff | `oak_quarterstaff` | 1 | mainHand | common | 1 | whispering_woods |
| Heartwood Staff | `heartwood_stave` | 3 | mainHand | epic | 5 | whispering_woods |
| Birch Quarterstaff | `birch_quarterstaff` | 2 | mainHand | common | 10 | ashfall_vale |

### `shieldStrengthPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Brookstone Pendant | `brookstone_pendant` | 10 | neck | rare | 6 | glimmerbrook |

### `healingReceivedPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Wickerbound Ring | `wickerbound_ring` | 10 | ring | rare | 12 | thornmire |

### `regrowPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| The Charlock | `the_charlock` | 2 | neck | epic | 14 | ashfall_vale |

### `beltSlots`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Fawnhide Belt | `fawnhide_belt` | 1 | belt | common | 4 | glimmerbrook |
| Tuskhide Belt | `tuskhide_belt` | 2 | belt | common | 11 | cinderpeak_foothills |

### No item grants

`dodge`


## Items by zone

### Whispering Woods (`whispering_woods`) — 18 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `bindweed_boots` | Bindweed Boots | equipment | boots | common | 1 | maxHpBonus +1 | craft: `craft_bindweed_boots` |
| `bindweed_fibre` | Bindweed Fibre | material |  | common | 1 |  | gather: `ww_bindweed_tangle`; drop: `listening_fawn`; drop: `thornback_sprite`; drop: `sporecap_shambler`; drop: `bindweed_creeper`; drop: `elderroot`; drop: `mother_spore`; +4 more (see content.json) |
| `bindweed_gloves` | Bindweed Gloves | equipment | gloves | common | 1 | maxHpBonus +1 | craft: `craft_bindweed_gloves` |
| `bindweed_hood` | Bindweed Hood | equipment | hat | common | 1 | accuracyBonus +1 | craft: `craft_bindweed_hood` |
| `bindweed_leggings` | Bindweed Leggings | equipment | robeBottom | common | 1 | maxHpBonus +4 | craft: `craft_bindweed_leggings` |
| `bindweed_robe` | Bindweed Robe | equipment | robeTop | common | 1 | maxHpBonus +6 | craft: `craft_bindweed_robe` |
| `flora_crystal` | Flora Crystal | mote |  | uncommon | 1 |  | drop: `elderroot`; drop: `mother_spore`; drop: `hollow_stag`; drop: `the_murmur`; drop: `heartwood`; drop: `the_standing_green`; +12 more (see content.json) |
| `flora_dust` | Flora Dust | mote |  | common | 1 |  | drop: `listening_fawn`; drop: `thornback_sprite`; drop: `sporecap_shambler`; drop: `bindweed_creeper`; drop: `rootknuckle`; drop: `elderroot`; +27 more (see content.json) |
| `flora_shard` | Flora Shard | mote |  | common | 1 |  | drop: `thornback_sprite`; drop: `sporecap_shambler`; drop: `bindweed_creeper`; drop: `rootknuckle`; drop: `elderroot`; drop: `mother_spore`; +19 more (see content.json) |
| `foragers_ration` | Forager's Ration | consumable |  | common | 1 |  | drop: `listening_fawn`; drop: `sporecap_shambler`; drop: `elderroot`; drop: `mother_spore`; drop: `hollow_stag`; drop: `the_murmur`; +7 more (see content.json) |
| `oak_circlet` | Oak Circlet | equipment | hat | common | 1 | accuracyBonus +1 | drop: `rootknuckle` |
| `oak_knot` | Oak Knot | equipment | offHand | common | 1 | accuracyBonus +3 | craft: `craft_oak_knot` |
| `oak_log` | Oak Log | material |  | common | 1 |  | gather: `ww_oak_stand`; drop: `rootknuckle`; drop: `elderroot`; drop: `mother_spore`; drop: `hollow_stag`; drop: `the_murmur`; drop: `heartwood`; +1 more (see content.json) |
| `oak_quarterstaff` | Oak Quarterstaff | equipment | mainHand | common | 1 | accuracyBonus +5, damagePerCharge +1 | craft: `craft_oak_quarterstaff` |
| `oak_wand` | Oak Wand | equipment | mainHand | common | 1 | damagePerCast +2 | craft: `craft_oak_wand` |
| `proof_of_the_woods` | Proof of the Woods | key |  | rare | 1 |  | drop: `heartwood`; drop: `the_standing_green` |
| `sporecap_mantle` | Sporecap Mantle | equipment | robeTop | rare | 4 | accuracyBonus +2, maxHpBonus +12 | drop: `elderroot`; drop: `mother_spore`; drop: `hollow_stag`; drop: `the_murmur`; drop: `heartwood`; drop: `the_standing_green` |
| `heartwood_stave` | Heartwood Staff | equipment | mainHand | epic | 5 | accuracyBonus +7, critChance +5, critDamage +10, damagePerCharge +3 | drop: `heartwood`; drop: `the_standing_green` |

### Glimmerbrook (`glimmerbrook`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `aqua_crystal` | Aqua Crystal | mote |  | uncommon | 1 |  | drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; drop: `the_cold_below`; drop: `stillwater`; +6 more (see content.json) |
| `aqua_dust` | Aqua Dust | mote |  | common | 1 |  | drop: `brook_naiad`; drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; +16 more (see content.json) |
| `aqua_shard` | Aqua Shard | mote |  | common | 1 |  | drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; drop: `the_held_breath`; +12 more (see content.json) |
| `fawnhide` | Fawnhide | material |  | common | 1 |  | drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; +2 more (see content.json) |
| `proof_of_the_brook` | Proof of the Brook | key |  | rare | 1 |  | drop: `the_cold_below`; drop: `stillwater` |
| `sapwort` | Sapwort | material |  | common | 1 |  | gather: `gb_sapwort_shallows`; drop: `brook_naiad`; drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; +3 more (see content.json) |
| `sapwort_draught` | Sapwort Draught | beltable |  | common | 1 |  | craft: `craft_sapwort_draught`; drop: `glassfleck_wisp` |
| `fawnhide_belt` | Fawnhide Belt | equipment | belt | common | 4 | beltSlots +1 | craft: `craft_fawnhide_belt` |
| `brookstone_pendant` | Brookstone Pendant | equipment | neck | rare | 6 | shieldStrengthPercent +10 | drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; drop: `the_cold_below`; drop: `stillwater` |

### Cinderpeak Foothills (`cinderpeak_foothills`) — 8 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `copper_ore` | Copper Ore | material |  | common | 1 |  | gather: `cp_copper_seam`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; drop: `vent_warden`; +4 more (see content.json) |
| `proof_of_the_foothills` | Proof of the Foothills | key |  | rare | 1 |  | drop: `the_breathing_stone`; drop: `flintmaw` |
| `pyro_crystal` | Pyro Crystal | mote |  | uncommon | 1 |  | drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; drop: `the_breathing_stone`; drop: `flintmaw`; +6 more (see content.json) |
| `pyro_dust` | Pyro Dust | mote |  | common | 1 |  | drop: `ashjaw_brute`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; +16 more (see content.json) |
| `pyro_shard` | Pyro Shard | mote |  | common | 1 |  | drop: `ashjaw_brute`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; +13 more (see content.json) |
| `tuskhide` | Tuskhide | material |  | common | 1 |  | drop: `ashjaw_brute`; drop: `slagshell_tortoise`; drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; +2 more (see content.json) |
| `cinder_loop` | Cinder Loop | equipment | ring | rare | 9 | critChance +5, critDamage +5 | drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; drop: `the_breathing_stone`; drop: `flintmaw` |
| `tuskhide_belt` | Tuskhide Belt | equipment | belt | common | 11 | beltSlots +2 | craft: `craft_tuskhide_belt` |

### Thornmire (`thornmire`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `amber` | Amber | material |  | uncommon | 1 |  | gather: `tm_amber_bog_oak`; drop: `leechcap`; drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; drop: `fenmother`; drop: `mirethroat`; +1 more (see content.json) |
| `bogflax_fibre` | Bogflax Fibre | material |  | common | 1 |  | gather: `tm_bogflax_retting`; drop: `mirewalker`; drop: `thirstvine`; drop: `reedback_lurker`; drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; +3 more (see content.json) |
| `fenroot` | Fenroot | material |  | common | 1 |  | gather: `tm_fenroot_hummock`; drop: `mirewalker`; drop: `leechcap`; drop: `bog_lantern`; drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; +3 more (see content.json) |
| `bogflax_boots` | Bogflax Boots | equipment | boots | common | 10 | maxHpBonus +2 | craft: `craft_bogflax_boots` |
| `bogflax_gloves` | Bogflax Gloves | equipment | gloves | common | 10 | maxHpBonus +2 | craft: `craft_bogflax_gloves` |
| `bogflax_hood` | Bogflax Hood | equipment | hat | common | 10 | accuracyBonus +2 | craft: `craft_bogflax_hood` |
| `bogflax_leggings` | Bogflax Leggings | equipment | robeBottom | common | 10 | maxHpBonus +7 | craft: `craft_bogflax_leggings` |
| `bogflax_robe` | Bogflax Robe | equipment | robeTop | common | 10 | maxHpBonus +10 | craft: `craft_bogflax_robe` |
| `wickerbound_ring` | Wickerbound Ring | equipment | ring | rare | 12 | healingReceivedPercent +10 | drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; drop: `fenmother`; drop: `mirethroat`; drop: `the_drinking_grove` |

### Ashfall Vale (`ashfall_vale`) — 8 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `birch_log` | Birch Log | material |  | common | 1 |  | gather: `av_birch_stand`; drop: `ashroot_sapling`; drop: `charwood_walker`; drop: `the_grey_stag`; drop: `first_green`; drop: `last_ember`; drop: `kindleroot`; +2 more (see content.json) |
| `brookmint` | Brookmint | material |  | common | 1 |  | gather: `av_brookmint_rill`; drop: `cinderbloom_husk`; drop: `scorchmoth`; drop: `the_grey_stag`; drop: `first_green`; drop: `last_ember`; drop: `kindleroot`; +2 more (see content.json) |
| `brookmint_tonic` | Brookmint Tonic | beltable |  | common | 1 |  | craft: `craft_brookmint_tonic`; drop: `scorchmoth`; drop: `the_grey_stag`; drop: `first_green`; drop: `last_ember`; drop: `kindleroot` |
| `charcoal` | Charcoal | material |  | common | 1 |  | gather: `av_charcoal_burn`; drop: `cinderbloom_husk`; drop: `emberseed`; drop: `charwood_walker`; drop: `the_grey_stag`; drop: `first_green`; drop: `last_ember`; +3 more (see content.json) |
| `birch_knot` | Birch Knot | equipment | offHand | common | 10 | accuracyBonus +4 | craft: `craft_birch_knot` |
| `birch_quarterstaff` | Birch Quarterstaff | equipment | mainHand | common | 10 | accuracyBonus +6, damagePerCharge +2 | craft: `craft_birch_quarterstaff` |
| `birch_wand` | Birch Wand | equipment | mainHand | common | 10 | accuracyBonus +1, damagePerCast +3 | craft: `craft_birch_wand` |
| `the_charlock` | The Charlock | equipment | neck | epic | 14 | regrowPercent +2 | drop: `the_blackened_crown`; drop: `the_rooting` |

### Old Quarry (`old_quarry`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `bronze_ingot` | Bronze Ingot | material |  | common | 1 |  | drop |
| `geo_crystal` | Geo Crystal | mote |  | uncommon | 1 |  | drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; drop: `mountain_heart`; drop: `the_empty_course` |
| `geo_dust` | Geo Dust | mote |  | common | 1 |  | drop: `quarry_golem`; drop: `tailings_drudge`; drop: `chiselback`; drop: `gravelswarm`; drop: `plumbline_sentry`; drop: `obsidian_golem`; +5 more (see content.json) |
| `geo_shard` | Geo Shard | mote |  | common | 1 |  | drop: `quarry_golem`; drop: `chiselback`; drop: `gravelswarm`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; +4 more (see content.json) |
| `hardtack` | Hardtack | consumable |  | common | 1 |  | drop: `quarry_golem`; drop: `tailings_drudge`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; +1 more (see content.json) |
| `quarry_jasper` | Quarry Jasper | material |  | uncommon | 1 |  | gather: `oq_jasper_face`; drop: `chiselback`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; +2 more (see content.json) |
| `tin_ore` | Tin Ore | material |  | common | 1 |  | gather: `oq_tin_seam`; drop: `quarry_golem`; drop: `tailings_drudge`; drop: `gravelswarm`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; +3 more (see content.json) |
| `overseers_seal` | Overseer's Seal | equipment | ring | rare | 18 | deflectChance +12, deflectAmount +20 | drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; drop: `mountain_heart`; drop: `the_empty_course` |
| `the_given_weight` | The Given Weight | equipment | neck | epic | 19 | deflectChance +10, deflectAmount +25, maxHpBonus +30 | drop: `mountain_heart`; drop: `the_empty_course` |


## Bestiary by zone

### Whispering Woods (`whispering_woods`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `bindweed_creeper` | Bindweed Creeper | Wild | Siphon | flora | 1-5 | ×0.95 | ×0.85 | Bindweed Fibre, Flora Shard, Flora Dust |
| `listening_fawn` | Listening Fawn | Wild | Drudge | flora | 1-5 | ×0.8 | ×0.7 | Bindweed Fibre, Forager's Ration |
| `rootknuckle` | Rootknuckle | Wild | Bruiser | flora | 1-5 | ×1.15 | ×1.1 | Oak Log, Flora Shard, Flora Dust, Oak Circlet |
| `sporecap_shambler` | Sporecap Shambler | Wild | Blighter | flora | 1-5 | ×1.0 | ×0.6 | Bindweed Fibre, Flora Shard, Flora Dust, Forager's Ration |
| `thornback_sprite` | Thornback Sprite | Wild | Skirmisher | flora | 1-5 | ×0.7 | ×1.15 | Bindweed Fibre, Flora Shard, Flora Dust |
| `elderroot` | Elderroot | Mini-boss | Champion | flora | 1-5 | ×1.7 | ×1.2 | Oak Log, Bindweed Fibre, Forager's Ration, Sporecap Mantle |
| `hollow_stag` | Hollow Stag | Mini-boss | Executioner | flora | 1-5 | ×1.2 | ×1.9 | Oak Log, Bindweed Fibre, Forager's Ration, Sporecap Mantle |
| `mother_spore` | Mother Spore | Mini-boss | Redoubt | flora | 1-5 | ×2.2 | ×0.85 | Oak Log, Bindweed Fibre, Forager's Ration, Sporecap Mantle |
| `the_murmur` | The Murmur | Mini-boss | Hexer | flora | 1-5 | ×1.6 | ×0.75 | Oak Log, Bindweed Fibre, Forager's Ration, Sporecap Mantle |
| `heartwood` | Heartwood | Boss | Juggernaut | flora | 1-5 | ×3.6 | ×1.4 | Oak Log, Bindweed Fibre, Sporecap Mantle, Heartwood Staff |
| `the_standing_green` | The Standing Green | Boss | Aspect | flora | 1-5 | ×2.6 | ×1.5 | Oak Log, Bindweed Fibre, Sporecap Mantle, Heartwood Staff |

### Glimmerbrook (`glimmerbrook`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `brook_naiad` | Brook Naiad | Wild | Adept | aqua | 3-8 | ×1.0 | ×0.9 | Sapwort, Forager's Ration |
| `chill_eel` | Chill Eel | Wild | Skirmisher | aqua | 3-8 | ×0.7 | ×1.15 | Fawnhide, Aqua Shard, Aqua Dust |
| `glassfleck_wisp` | Glassfleck Wisp | Wild | Glasswing | aqua | 3-8 | ×0.5 | ×1.7 | Sapwort, Aqua Shard, Aqua Dust, Sapwort Draught |
| `shiverfish_shoal` | Shiverfish Shoal | Wild | Lasher | aqua | 3-8 | ×0.85 | ×1.0 | Sapwort, Aqua Shard, Aqua Dust |
| `siltback_crawler` | Siltback Crawler | Wild | Sentinel | aqua | 3-8 | ×1.25 | ×0.7 | Fawnhide, Aqua Shard, Aqua Dust |
| `frostgleam_naiad` | Frostgleam Naiad | Mini-boss | Hexer | aqua | 3-8 | ×1.6 | ×0.75 | Fawnhide, Sapwort, Forager's Ration, Brookstone Pendant |
| `pale_coil` | Pale Coil | Mini-boss | Executioner | aqua | 3-8 | ×1.2 | ×1.9 | Fawnhide, Sapwort, Forager's Ration, Brookstone Pendant |
| `the_held_breath` | The Held Breath | Mini-boss | Redoubt | aqua | 3-8 | ×2.2 | ×0.85 | Fawnhide, Sapwort, Forager's Ration, Brookstone Pendant |
| `weirkeeper` | Weirkeeper | Mini-boss | Champion | aqua | 3-8 | ×1.7 | ×1.2 | Fawnhide, Sapwort, Forager's Ration, Brookstone Pendant |
| `stillwater` | Stillwater | Boss | Aspect | aqua | 3-8 | ×2.6 | ×1.5 | Fawnhide, Sapwort, Brookstone Pendant, Forager's Ration |
| `the_cold_below` | The Cold Below | Boss | Juggernaut | aqua | 3-8 | ×3.6 | ×1.4 | Fawnhide, Sapwort, Brookstone Pendant, Forager's Ration |

### Cinderpeak Foothills (`cinderpeak_foothills`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `ashjaw_brute` | Ashjaw Brute | Wild | Bruiser | pyro | 6-11 | ×1.15 | ×1.1 | Tuskhide, Pyro Shard, Pyro Dust |
| `cinder_moth` | Cinder Moth | Wild | Glasswing | pyro | 6-11 | ×0.5 | ×1.7 | Copper Ore, Pyro Shard, Pyro Dust |
| `flint_skink` | Flint Skink | Wild | Skirmisher | pyro | 6-11 | ×0.7 | ×1.15 | Copper Ore, Pyro Shard, Pyro Dust |
| `slagshell_tortoise` | Slagshell Tortoise | Wild | Sentinel | pyro | 6-11 | ×1.25 | ×0.7 | Copper Ore, Pyro Shard, Pyro Dust, Tuskhide |
| `ventworm` | Ventworm | Wild | Blighter | pyro | 6-11 | ×1.0 | ×0.6 | Copper Ore, Pyro Shard, Pyro Dust |
| `char_tusk` | Char-Tusk | Mini-boss | Executioner | pyro | 6-11 | ×1.2 | ×1.9 | Tuskhide, Copper Ore, Pyro Shard, Pyro Dust, Cinder Loop |
| `slagheart` | Slagheart | Mini-boss | Champion | pyro | 6-11 | ×1.7 | ×1.2 | Tuskhide, Copper Ore, Pyro Shard, Pyro Dust, Cinder Loop |
| `the_emberqueen` | The Emberqueen | Mini-boss | Hexer | pyro | 6-11 | ×1.6 | ×0.75 | Tuskhide, Copper Ore, Pyro Shard, Pyro Dust, Cinder Loop |
| `vent_warden` | Vent Warden | Mini-boss | Redoubt | pyro | 6-11 | ×2.2 | ×0.85 | Tuskhide, Copper Ore, Pyro Shard, Pyro Dust, Cinder Loop |
| `flintmaw` | Flintmaw | Boss | Tyrant | pyro | 6-11 | ×2.6 | ×1.7 | Tuskhide, Copper Ore, Cinder Loop, Pyro Shard, Pyro Dust |
| `the_breathing_stone` | The Breathing Stone | Boss | Juggernaut | pyro | 6-11 | ×3.6 | ×1.4 | Tuskhide, Copper Ore, Cinder Loop, Pyro Shard, Pyro Dust |

### Thornmire (`thornmire`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `bog_lantern` | Bog Lantern | Wild | Glasswing | flora/aqua | 8-13 | ×0.5 | ×1.7 | Fenroot, Flora Shard, Flora Dust |
| `leechcap` | Leechcap | Wild | Siphon | flora/aqua | 8-13 | ×0.95 | ×0.85 | Fenroot, Aqua Shard, Aqua Dust, Amber |
| `mirewalker` | Mirewalker | Wild | Adept | flora/aqua | 8-13 | ×1.0 | ×0.9 | Bogflax Fibre, Fenroot |
| `reedback_lurker` | Reedback Lurker | Wild | Sentinel | flora/aqua | 8-13 | ×1.25 | ×0.7 | Bogflax Fibre, Aqua Shard, Aqua Dust |
| `thirstvine` | Thirstvine | Wild | Siphon | flora | 8-13 | ×0.95 | ×0.85 | Bogflax Fibre, Flora Shard, Flora Dust |
| `fenmother` | Fenmother | Mini-boss | Hexer | flora/aqua | 8-13 | ×1.6 | ×0.75 | Bogflax Fibre, Fenroot, Amber, Wickerbound Ring |
| `old_wallow` | Old Wallow | Mini-boss | Champion | flora/aqua | 8-13 | ×1.7 | ×1.2 | Bogflax Fibre, Fenroot, Amber, Wickerbound Ring |
| `the_green_drowning` | The Green Drowning | Mini-boss | Redoubt | flora/aqua | 8-13 | ×2.2 | ×0.85 | Bogflax Fibre, Fenroot, Amber, Wickerbound Ring |
| `wickerdrowned` | Wickerdrowned | Mini-boss | Executioner | flora/aqua | 8-13 | ×1.2 | ×1.9 | Bogflax Fibre, Fenroot, Amber, Wickerbound Ring |
| `mirethroat` | Mirethroat | Boss | Juggernaut | flora/aqua | 8-13 | ×3.6 | ×1.4 | Bogflax Fibre, Fenroot, Wickerbound Ring, Amber |
| `the_drinking_grove` | The Drinking Grove | Boss | Aspect | flora/aqua | 8-13 | ×2.6 | ×1.5 | Bogflax Fibre, Fenroot, Wickerbound Ring, Amber |

### Ashfall Vale (`ashfall_vale`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `ashroot_sapling` | Ashroot Sapling | Wild | Siphon | pyro/flora | 10-14 | ×0.95 | ×0.85 | Birch Log, Flora Shard, Flora Dust |
| `charwood_walker` | Charwood Walker | Wild | Bruiser | pyro/flora | 10-14 | ×1.15 | ×1.1 | Birch Log, Charcoal |
| `cinderbloom_husk` | Cinderbloom Husk | Wild | Blighter | pyro/flora | 10-14 | ×1.0 | ×0.6 | Charcoal, Brookmint |
| `emberseed` | Emberseed | Wild | Glasswing | pyro/flora | 10-14 | ×0.5 | ×1.7 | Charcoal, Pyro Shard, Pyro Dust |
| `scorchmoth` | Scorchmoth | Wild | Skirmisher | pyro/flora | 10-14 | ×0.7 | ×1.15 | Brookmint, Pyro Shard, Pyro Dust, Brookmint Tonic |
| `first_green` | First Green | Mini-boss | Redoubt | pyro/flora | 10-14 | ×2.2 | ×0.85 | Birch Log, Charcoal, Brookmint, Brookmint Tonic |
| `kindleroot` | Kindleroot | Mini-boss | Hexer | pyro/flora | 10-14 | ×1.6 | ×0.75 | Birch Log, Charcoal, Brookmint, Brookmint Tonic |
| `last_ember` | Last Ember | Mini-boss | Executioner | pyro | 10-14 | ×1.2 | ×1.9 | Birch Log, Charcoal, Brookmint, Brookmint Tonic |
| `the_grey_stag` | The Grey Stag | Mini-boss | Champion | pyro/flora | 10-14 | ×1.7 | ×1.2 | Birch Log, Charcoal, Brookmint, Brookmint Tonic |
| `the_blackened_crown` | The Blackened Crown | Boss | Tyrant | pyro/flora | 10-14 | ×2.6 | ×1.7 | Birch Log, Charcoal, Brookmint, The Charlock |
| `the_rooting` | The Rooting | Boss | Aspect | pyro/flora | 10-14 | ×2.6 | ×1.5 | Birch Log, Charcoal, Brookmint, The Charlock |

### Old Quarry (`old_quarry`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `chiselback` | Chiselback | Wild | Skirmisher | geo | 15-19 | ×0.7 | ×1.15 | Quarry Jasper, Geo Shard, Geo Dust |
| `gravelswarm` | Gravelswarm | Wild | Lasher | geo | 15-19 | ×0.85 | ×1.0 | Tin Ore, Geo Shard, Geo Dust |
| `plumbline_sentry` | Plumbline Sentry | Wild | Sentinel | geo | 15-19 | ×1.25 | ×0.7 | Quarry Jasper, Geo Shard, Geo Dust, Hardtack |
| `quarry_golem` | Quarry Golem | Wild | Bruiser | geo | 15-19 | ×1.15 | ×1.1 | Tin Ore, Geo Shard, Geo Dust, Hardtack |
| `tailings_drudge` | Tailings Drudge | Wild | Drudge | geo | 15-19 | ×0.8 | ×0.7 | Tin Ore, Hardtack |
| `deadweight` | Deadweight | Mini-boss | Executioner | geo | 15-19 | ×1.2 | ×1.9 | Tin Ore, Quarry Jasper, Hardtack, Overseer's Seal |
| `earth_titan` | Earth Titan | Mini-boss | Redoubt | geo | 15-19 | ×2.2 | ×0.85 | Tin Ore, Quarry Jasper, Hardtack, Overseer's Seal |
| `obsidian_golem` | Obsidian Golem | Mini-boss | Champion | geo | 15-19 | ×1.7 | ×1.2 | Tin Ore, Quarry Jasper, Hardtack, Overseer's Seal |
| `the_overseer` | The Overseer | Mini-boss | Hexer | geo | 15-19 | ×1.6 | ×0.75 | Tin Ore, Quarry Jasper, Hardtack, Overseer's Seal |
| `mountain_heart` | Mountain Heart | Boss | Juggernaut | geo | 15-19 | ×3.6 | ×1.4 | Tin Ore, Quarry Jasper, Overseer's Seal, The Given Weight |
| `the_empty_course` | The Empty Course | Boss | Tyrant | geo | 15-19 | ×2.6 | ×1.7 | Tin Ore, Quarry Jasper, Overseer's Seal, The Given Weight |


## Recipes by skill

### Woodcarving — 6 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_oak_knot` | 1 | 2x Oak Log | 1x Oak Knot | 12 |
| `craft_oak_quarterstaff` | 1 | 3x Oak Log | 1x Oak Quarterstaff | 18 |
| `craft_oak_wand` | 1 | 2x Oak Log | 1x Oak Wand | 12 |
| `craft_birch_knot` | 10 | 2x Birch Log | 1x Birch Knot | 48 |
| `craft_birch_quarterstaff` | 10 | 3x Birch Log | 1x Birch Quarterstaff | 72 |
| `craft_birch_wand` | 10 | 2x Birch Log | 1x Birch Wand | 48 |

### Tailoring — 12 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_bindweed_boots` | 1 | 2x Bindweed Fibre | 1x Bindweed Boots | 12 |
| `craft_bindweed_gloves` | 1 | 2x Bindweed Fibre | 1x Bindweed Gloves | 12 |
| `craft_bindweed_hood` | 1 | 2x Bindweed Fibre | 1x Bindweed Hood | 12 |
| `craft_bindweed_leggings` | 1 | 3x Bindweed Fibre | 1x Bindweed Leggings | 18 |
| `craft_bindweed_robe` | 1 | 4x Bindweed Fibre | 1x Bindweed Robe | 24 |
| `craft_fawnhide_belt` | 4 | 2x Fawnhide, 1x Bindweed Fibre | 1x Fawnhide Belt | 36 |
| `craft_bogflax_boots` | 10 | 2x Bogflax Fibre | 1x Bogflax Boots | 48 |
| `craft_bogflax_gloves` | 10 | 2x Bogflax Fibre | 1x Bogflax Gloves | 48 |
| `craft_bogflax_hood` | 10 | 2x Bogflax Fibre | 1x Bogflax Hood | 48 |
| `craft_bogflax_leggings` | 10 | 4x Bogflax Fibre | 1x Bogflax Leggings | 96 |
| `craft_bogflax_robe` | 10 | 5x Bogflax Fibre | 1x Bogflax Robe | 120 |
| `craft_tuskhide_belt` | 11 | 2x Tuskhide, 1x Bogflax Fibre | 1x Tuskhide Belt | 78 |

### Potions & Alchemy — 2 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_sapwort_draught` | 1 | 2x Sapwort | 1x Sapwort Draught | 12 |
| `craft_brookmint_tonic` | 10 | 2x Brookmint | 1x Brookmint Tonic | 48 |


