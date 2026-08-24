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
| 26 | 9 | 121 | 110 | 41 | 23 |

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
| Seawrack Hood | `seawrack_hood` | 3 | hat | common | 16 | stormcliff_coast |
| Uplight | `uplight` | 4 | mainHand | epic | 22 | stormcliff_coast |
| Yew Knot | `yew_knot` | 5 | offHand | common | 20 | windward_steppe |
| Yew Quarterstaff | `yew_quarterstaff` | 7 | mainHand | common | 20 | windward_steppe |
| Yew Wand | `yew_wand` | 2 | mainHand | common | 20 | windward_steppe |
| Leanstone Charm | `leanstone_charm` | 2 | ring | rare | 22 | windward_steppe |
| The Long Lean | `the_long_lean` | 3 | robeTop | epic | 24 | windward_steppe |
| Tussock Hood | `tussock_hood` | 4 | hat | common | 24 | windward_steppe |
| Rowan Knot | `rowan_knot` | 6 | offHand | common | 25 | thunderspire_peaks |
| Rowan Quarterstaff | `rowan_quarterstaff` | 8 | mainHand | common | 25 | thunderspire_peaks |
| Rowan Wand | `rowan_wand` | 3 | mainHand | common | 25 | thunderspire_peaks |
| Groundfault Grips | `groundfault_grips` | 5 | gloves | epic | 28 | thunderspire_peaks |

### `dodge`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Seawrack Boots | `seawrack_boots` | 2 | boots | common | 16 | stormcliff_coast |
| Leanstone Charm | `leanstone_charm` | 6 | ring | rare | 22 | windward_steppe |
| The Long Lean | `the_long_lean` | 8 | robeTop | epic | 24 | windward_steppe |
| Tussock Boots | `tussock_boots` | 3 | boots | common | 24 | windward_steppe |
| Rimebound Ring | `rimebound_ring` | 3 | ring | rare | 24 | frostfell_pass |

### `critChance`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Heartwood Staff | `heartwood_stave` | 5 | mainHand | epic | 5 | whispering_woods |
| Cinder Loop | `cinder_loop` | 5 | ring | rare | 9 | cinderpeak_foothills |
| Fulgurite Pendant | `fulgurite_pendant` | 8 | neck | rare | 20 | stormcliff_coast |
| Uplight | `uplight` | 12 | mainHand | epic | 22 | stormcliff_coast |
| Rowan Knot | `rowan_knot` | 2 | offHand | common | 25 | thunderspire_peaks |
| Rowan Quarterstaff | `rowan_quarterstaff` | 3 | mainHand | common | 25 | thunderspire_peaks |
| Rowan Wand | `rowan_wand` | 4 | mainHand | common | 25 | thunderspire_peaks |
| Countstone Pendant | `countstone_pendant` | 10 | neck | rare | 26 | thunderspire_peaks |
| Firstmelt Loop | `firstmelt_loop` | 5 | ring | rare | 28 | the_molten_deep |

### `critDamage`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Heartwood Staff | `heartwood_stave` | 10 | mainHand | epic | 5 | whispering_woods |
| Cinder Loop | `cinder_loop` | 5 | ring | rare | 9 | cinderpeak_foothills |
| Fulgurite Pendant | `fulgurite_pendant` | 10 | neck | rare | 20 | stormcliff_coast |
| Uplight | `uplight` | 15 | mainHand | epic | 22 | stormcliff_coast |
| Rowan Quarterstaff | `rowan_quarterstaff` | 8 | mainHand | common | 25 | thunderspire_peaks |
| Rowan Wand | `rowan_wand` | 6 | mainHand | common | 25 | thunderspire_peaks |
| Countstone Pendant | `countstone_pendant` | 12 | neck | rare | 26 | thunderspire_peaks |
| Firstmelt Loop | `firstmelt_loop` | 25 | ring | rare | 28 | the_molten_deep |
| The Long Cooling | `the_long_cooling` | 15 | hat | epic | 29 | the_molten_deep |

### `deflectChance`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Overseer's Seal | `overseers_seal` | 12 | ring | rare | 18 | old_quarry |
| The Given Weight | `the_given_weight` | 10 | neck | epic | 19 | old_quarry |
| Seawrack Gloves | `seawrack_gloves` | 6 | gloves | common | 16 | stormcliff_coast |
| Tussock Gloves | `tussock_gloves` | 8 | gloves | common | 24 | windward_steppe |
| Rimebound Ring | `rimebound_ring` | 10 | ring | rare | 24 | frostfell_pass |
| The Long Cooling | `the_long_cooling` | 12 | hat | epic | 29 | the_molten_deep |

### `deflectAmount`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Overseer's Seal | `overseers_seal` | 20 | ring | rare | 18 | old_quarry |
| The Given Weight | `the_given_weight` | 25 | neck | epic | 19 | old_quarry |
| Seawrack Gloves | `seawrack_gloves` | 15 | gloves | common | 16 | stormcliff_coast |
| Tussock Gloves | `tussock_gloves` | 20 | gloves | common | 24 | windward_steppe |
| Rimebound Ring | `rimebound_ring` | 20 | ring | rare | 24 | frostfell_pass |
| The Long Cooling | `the_long_cooling` | 25 | hat | epic | 29 | the_molten_deep |

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
| Seawrack Boots | `seawrack_boots` | 3 | boots | common | 16 | stormcliff_coast |
| Seawrack Gloves | `seawrack_gloves` | 3 | gloves | common | 16 | stormcliff_coast |
| Seawrack Leggings | `seawrack_leggings` | 10 | robeBottom | common | 16 | stormcliff_coast |
| Seawrack Robe | `seawrack_robe` | 15 | robeTop | common | 16 | stormcliff_coast |
| The Long Lean | `the_long_lean` | 24 | robeTop | epic | 24 | windward_steppe |
| Tussock Boots | `tussock_boots` | 4 | boots | common | 24 | windward_steppe |
| Tussock Gloves | `tussock_gloves` | 4 | gloves | common | 24 | windward_steppe |
| Tussock Leggings | `tussock_leggings` | 14 | robeBottom | common | 24 | windward_steppe |
| Tussock Robe | `tussock_robe` | 20 | robeTop | common | 24 | windward_steppe |
| The Long Cooling | `the_long_cooling` | 22 | hat | epic | 29 | the_molten_deep |

### `damagePerCast`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Oak Wand | `oak_wand` | 2 | mainHand | common | 1 | whispering_woods |
| Birch Wand | `birch_wand` | 3 | mainHand | common | 10 | ashfall_vale |
| Uplight | `uplight` | 6 | mainHand | epic | 22 | stormcliff_coast |
| Yew Wand | `yew_wand` | 4 | mainHand | common | 20 | windward_steppe |
| Rowan Wand | `rowan_wand` | 5 | mainHand | common | 25 | thunderspire_peaks |
| Groundfault Grips | `groundfault_grips` | 4 | gloves | epic | 28 | thunderspire_peaks |

### `damagePerCharge`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Oak Quarterstaff | `oak_quarterstaff` | 1 | mainHand | common | 1 | whispering_woods |
| Heartwood Staff | `heartwood_stave` | 3 | mainHand | epic | 5 | whispering_woods |
| Birch Quarterstaff | `birch_quarterstaff` | 2 | mainHand | common | 10 | ashfall_vale |
| Yew Quarterstaff | `yew_quarterstaff` | 3 | mainHand | common | 20 | windward_steppe |
| Rowan Quarterstaff | `rowan_quarterstaff` | 4 | mainHand | common | 25 | thunderspire_peaks |

### `shieldStrengthPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Brookstone Pendant | `brookstone_pendant` | 10 | neck | rare | 6 | glimmerbrook |
| The Holdfast | `the_holdfast` | 15 | neck | epic | 25 | frostfell_pass |

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
| Rimepelt Belt | `rimepelt_belt` | 3 | belt | common | 23 | frostfell_pass |
| Emberhide Belt | `emberhide_belt` | 4 | belt | common | 27 | the_molten_deep |


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
| `aqua_crystal` | Aqua Crystal | mote |  | uncommon | 1 |  | drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; drop: `the_cold_below`; drop: `stillwater`; +12 more (see content.json) |
| `aqua_dust` | Aqua Dust | mote |  | common | 1 |  | drop: `brook_naiad`; drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; +27 more (see content.json) |
| `aqua_shard` | Aqua Shard | mote |  | common | 1 |  | drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; drop: `the_held_breath`; +20 more (see content.json) |
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
| `pyro_crystal` | Pyro Crystal | mote |  | uncommon | 1 |  | drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; drop: `the_breathing_stone`; drop: `flintmaw`; +12 more (see content.json) |
| `pyro_dust` | Pyro Dust | mote |  | common | 1 |  | drop: `ashjaw_brute`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; +27 more (see content.json) |
| `pyro_shard` | Pyro Shard | mote |  | common | 1 |  | drop: `ashjaw_brute`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; +21 more (see content.json) |
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
| `bronze_ingot` | Bronze Ingot | material |  | common | 1 |  | craft: `craft_bronze_ingot` |
| `geo_crystal` | Geo Crystal | mote |  | uncommon | 1 |  | drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; drop: `mountain_heart`; drop: `the_empty_course`; +6 more (see content.json) |
| `geo_dust` | Geo Dust | mote |  | common | 1 |  | drop: `quarry_golem`; drop: `tailings_drudge`; drop: `chiselback`; drop: `gravelswarm`; drop: `plumbline_sentry`; drop: `obsidian_golem`; +16 more (see content.json) |
| `geo_shard` | Geo Shard | mote |  | common | 1 |  | drop: `quarry_golem`; drop: `chiselback`; drop: `gravelswarm`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; +12 more (see content.json) |
| `hardtack` | Hardtack | consumable |  | common | 1 |  | drop: `quarry_golem`; drop: `tailings_drudge`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; +16 more (see content.json) |
| `quarry_jasper` | Quarry Jasper | material |  | uncommon | 1 |  | gather: `oq_jasper_face`; drop: `chiselback`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; +2 more (see content.json) |
| `tin_ore` | Tin Ore | material |  | common | 1 |  | gather: `oq_tin_seam`; drop: `quarry_golem`; drop: `tailings_drudge`; drop: `gravelswarm`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; +3 more (see content.json) |
| `overseers_seal` | Overseer's Seal | equipment | ring | rare | 18 | deflectChance +12, deflectAmount +20 | drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; drop: `mountain_heart`; drop: `the_empty_course` |
| `the_given_weight` | The Given Weight | equipment | neck | epic | 19 | deflectChance +10, deflectAmount +25, maxHpBonus +30 | drop: `mountain_heart`; drop: `the_empty_course` |

### Stormcliff Coast (`stormcliff_coast`) — 13 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `electro_crystal` | Electro Crystal | mote |  | uncommon | 1 |  | drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman`; drop: `storm_lord`; drop: `the_return_stroke`; +6 more (see content.json) |
| `electro_dust` | Electro Dust | mote |  | common | 1 |  | drop: `stormcliff_tidecaller`; drop: `fulgurite_crawler`; drop: `sparkwing`; drop: `static_shoal`; drop: `groundling`; drop: `brinecharge`; +16 more (see content.json) |
| `electro_shard` | Electro Shard | mote |  | common | 1 |  | drop: `fulgurite_crawler`; drop: `sparkwing`; drop: `static_shoal`; drop: `groundling`; drop: `brinecharge`; drop: `the_long_line`; +13 more (see content.json) |
| `saltwort` | Saltwort | material |  | common | 1 |  | gather: `sc_saltwort_ledge`; drop: `stormcliff_tidecaller`; drop: `sparkwing`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman`; +2 more (see content.json) |
| `saltwort_draught` | Saltwort Draught | beltable |  | common | 1 |  | craft: `craft_saltwort_draught`; drop: `fulgurite_crawler`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman` |
| `seawrack_fibre` | Seawrack Fibre | material |  | common | 1 |  | gather: `sc_wrackline`; drop: `fulgurite_crawler`; drop: `static_shoal`; drop: `groundling`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; +3 more (see content.json) |
| `seawrack_boots` | Seawrack Boots | equipment | boots | common | 16 | dodge +2, maxHpBonus +3 | craft: `craft_seawrack_boots` |
| `seawrack_gloves` | Seawrack Gloves | equipment | gloves | common | 16 | deflectChance +6, deflectAmount +15, maxHpBonus +3 | craft: `craft_seawrack_gloves` |
| `seawrack_hood` | Seawrack Hood | equipment | hat | common | 16 | accuracyBonus +3 | craft: `craft_seawrack_hood` |
| `seawrack_leggings` | Seawrack Leggings | equipment | robeBottom | common | 16 | maxHpBonus +10 | craft: `craft_seawrack_leggings` |
| `seawrack_robe` | Seawrack Robe | equipment | robeTop | common | 16 | maxHpBonus +15 | craft: `craft_seawrack_robe` |
| `fulgurite_pendant` | Fulgurite Pendant | equipment | neck | rare | 20 | critChance +8, critDamage +10 | drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman`; drop: `storm_lord`; drop: `the_return_stroke` |
| `uplight` | Uplight | equipment | mainHand | epic | 22 | accuracyBonus +4, critChance +12, critDamage +15, damagePerCast +6 | drop: `storm_lord`; drop: `the_return_stroke` |

### Windward Steppe (`windward_steppe`) — 15 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `aero_crystal` | Aero Crystal | mote |  | uncommon | 1 |  | drop: `old_lean`; drop: `sky_titan`; drop: `gale_serpent`; drop: `wind_wraith`; drop: `the_unbroken_blow`; drop: `tempest_monarch`; +12 more (see content.json) |
| `aero_dust` | Aero Dust | mote |  | common | 1 |  | drop: `steppe_harrier`; drop: `leanstone`; drop: `chaff`; drop: `tumblehusk`; drop: `kitewing`; drop: `old_lean`; +27 more (see content.json) |
| `aero_shard` | Aero Shard | mote |  | common | 1 |  | drop: `steppe_harrier`; drop: `leanstone`; drop: `chaff`; drop: `kitewing`; drop: `old_lean`; drop: `sky_titan`; +19 more (see content.json) |
| `tussock_flax` | Tussock Flax | material |  | common | 1 |  | gather: `ws_tussock_swale`; drop: `steppe_harrier`; drop: `chaff`; drop: `tumblehusk`; drop: `old_lean`; drop: `sky_titan`; drop: `gale_serpent`; +3 more (see content.json) |
| `yew_log` | Yew Log | material |  | common | 1 |  | gather: `ws_yew_break`; drop: `leanstone`; drop: `kitewing`; drop: `old_lean`; drop: `sky_titan`; drop: `gale_serpent`; drop: `wind_wraith`; +2 more (see content.json) |
| `yew_knot` | Yew Knot | equipment | offHand | common | 20 | accuracyBonus +5 | craft: `craft_yew_knot` |
| `yew_quarterstaff` | Yew Quarterstaff | equipment | mainHand | common | 20 | accuracyBonus +7, damagePerCharge +3 | craft: `craft_yew_quarterstaff` |
| `yew_wand` | Yew Wand | equipment | mainHand | common | 20 | accuracyBonus +2, damagePerCast +4 | craft: `craft_yew_wand` |
| `leanstone_charm` | Leanstone Charm | equipment | ring | rare | 22 | accuracyBonus +2, dodge +6 | drop: `old_lean`; drop: `sky_titan`; drop: `gale_serpent`; drop: `wind_wraith`; drop: `the_unbroken_blow`; drop: `tempest_monarch` |
| `the_long_lean` | The Long Lean | equipment | robeTop | epic | 24 | accuracyBonus +3, dodge +8, maxHpBonus +24 | drop: `the_unbroken_blow`; drop: `tempest_monarch` |
| `tussock_boots` | Tussock Boots | equipment | boots | common | 24 | dodge +3, maxHpBonus +4 | craft: `craft_tussock_boots` |
| `tussock_gloves` | Tussock Gloves | equipment | gloves | common | 24 | deflectChance +8, deflectAmount +20, maxHpBonus +4 | craft: `craft_tussock_gloves` |
| `tussock_hood` | Tussock Hood | equipment | hat | common | 24 | accuracyBonus +4 | craft: `craft_tussock_hood` |
| `tussock_leggings` | Tussock Leggings | equipment | robeBottom | common | 24 | maxHpBonus +14 | craft: `craft_tussock_leggings` |
| `tussock_robe` | Tussock Robe | equipment | robeTop | common | 24 | maxHpBonus +20 | craft: `craft_tussock_robe` |

### Frostfell Pass (`frostfell_pass`) — 6 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `everice` | Everice | material |  | uncommon | 1 |  | gather: `ff_everice_seam`; drop: `cairnwight`; drop: `snowblind_wanderer`; drop: `the_last_cairn`; drop: `hoarking`; drop: `coldsnap`; drop: `the_certain_road`; +2 more (see content.json) |
| `hoarlichen` | Hoarlichen | material |  | common | 1 |  | gather: `ff_lichen_shelf`; drop: `breathfrost`; drop: `cairnwight`; drop: `the_last_cairn`; drop: `hoarking`; drop: `coldsnap`; drop: `the_certain_road`; +2 more (see content.json) |
| `rimepelt` | Rimepelt | material |  | common | 1 |  | drop: `rime_stalker`; drop: `hoarbound`; drop: `the_last_cairn`; drop: `hoarking`; drop: `coldsnap`; drop: `the_certain_road`; +2 more (see content.json) |
| `rimepelt_belt` | Rimepelt Belt | equipment | belt | common | 23 | beltSlots +3 | craft: `craft_rimepelt_belt` |
| `rimebound_ring` | Rimebound Ring | equipment | ring | rare | 24 | dodge +3, deflectChance +10, deflectAmount +20 | drop: `the_last_cairn`; drop: `hoarking`; drop: `coldsnap`; drop: `the_certain_road`; drop: `the_white_corridor`; drop: `the_road_under` |
| `the_holdfast` | The Holdfast | equipment | neck | epic | 25 | shieldStrengthPercent +15 | drop: `the_white_corridor`; drop: `the_road_under` |

### Thunderspire Peaks (`thunderspire_peaks`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `hum_quartz` | Hum Quartz | material |  | uncommon | 1 |  | gather: `tp_humming_face`; drop: `humming_ore`; drop: `ionwake`; drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; +2 more (see content.json) |
| `iron_ingot` | Iron Ingot | material |  | common | 1 |  | craft: `craft_iron_ingot` |
| `iron_ore` | Iron Ore | material |  | common | 1 |  | gather: `tp_iron_seam`; drop: `flashcount`; drop: `ionwake`; drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; +2 more (see content.json) |
| `rowan_log` | Rowan Log | material |  | common | 1 |  | gather: `tp_rowan_stand`; drop: `stormcrest_roc`; drop: `updraft_wisp`; drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; +2 more (see content.json) |
| `rowan_knot` | Rowan Knot | equipment | offHand | common | 25 | accuracyBonus +6, critChance +2 | craft: `craft_rowan_knot` |
| `rowan_quarterstaff` | Rowan Quarterstaff | equipment | mainHand | common | 25 | accuracyBonus +8, critChance +3, critDamage +8, damagePerCharge +4 | craft: `craft_rowan_quarterstaff` |
| `rowan_wand` | Rowan Wand | equipment | mainHand | common | 25 | accuracyBonus +3, critChance +4, critDamage +6, damagePerCast +5 | craft: `craft_rowan_wand` |
| `countstone_pendant` | Countstone Pendant | equipment | neck | rare | 26 | critChance +10, critDamage +12 | drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; drop: `the_storm_that_passes`; drop: `the_strike_that_lands` |
| `groundfault_grips` | Groundfault Grips | equipment | gloves | epic | 28 | accuracyBonus +5, damagePerCast +4 | drop: `the_storm_that_passes`; drop: `the_strike_that_lands` |

### The Molten Deep (`the_molten_deep`) — 6 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `emberhide` | Emberhide | material |  | common | 1 |  | drop: `molten_warden`; drop: `crustwalker`; drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt`; +2 more (see content.json) |
| `firesalt` | Firesalt | material |  | common | 1 |  | gather: `md_firesalt_crust`; drop: `slagswimmer`; drop: `ember_vent`; drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt` |
| `obsidian` | Obsidian | material |  | uncommon | 1 |  | gather: `md_obsidian_flow`; drop: `ember_vent`; drop: `cooling_thing`; drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt`; +2 more (see content.json) |
| `emberhide_belt` | Emberhide Belt | equipment | belt | common | 27 | beltSlots +4 | craft: `craft_emberhide_belt` |
| `firstmelt_loop` | Firstmelt Loop | equipment | ring | rare | 28 | critChance +5, critDamage +25 | drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt`; drop: `the_slow_stone`; drop: `efreet` |
| `the_long_cooling` | The Long Cooling | equipment | hat | epic | 29 | critDamage +15, deflectChance +12, deflectAmount +25, maxHpBonus +22 | drop: `the_slow_stone`; drop: `efreet` |


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

### Stormcliff Coast (`stormcliff_coast`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `fulgurite_crawler` | Fulgurite Crawler | Wild | Sentinel | electro | 17-22 | ×1.25 | ×0.7 | Seawrack Fibre, Electro Shard, Electro Dust, Saltwort Draught |
| `groundling` | Groundling | Wild | Skirmisher | electro | 17-22 | ×0.7 | ×1.15 | Seawrack Fibre, Electro Shard, Electro Dust, Hardtack |
| `sparkwing` | Sparkwing | Wild | Glasswing | electro | 17-22 | ×0.5 | ×1.7 | Saltwort, Electro Shard, Electro Dust |
| `static_shoal` | Static Shoal | Wild | Lasher | electro | 17-22 | ×0.85 | ×1.0 | Seawrack Fibre, Electro Shard, Electro Dust |
| `stormcliff_tidecaller` | Stormcliff Tidecaller | Wild | Adept | electro | 17-22 | ×1.0 | ×0.9 | Saltwort, Hardtack |
| `brinecharge` | Brinecharge | Mini-boss | Champion | electro | 17-22 | ×1.7 | ×1.2 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `storm_shaman` | Storm Shaman | Mini-boss | Hexer | electro | 17-22 | ×1.6 | ×0.75 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `the_long_line` | The Long Line | Mini-boss | Redoubt | electro | 17-22 | ×2.2 | ×0.85 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `voltgeist` | Voltgeist | Mini-boss | Executioner | electro | 17-22 | ×1.2 | ×1.9 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `storm_lord` | Storm Lord | Boss | Tyrant | electro | 17-22 | ×2.6 | ×1.7 | Seawrack Fibre, Saltwort, Fulgurite Pendant, Uplight |
| `the_return_stroke` | The Return Stroke | Boss | Aspect | electro | 17-22 | ×2.6 | ×1.5 | Seawrack Fibre, Saltwort, Fulgurite Pendant, Uplight |

### Windward Steppe (`windward_steppe`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `chaff` | Chaff | Wild | Lasher | aero | 19-24 | ×0.85 | ×1.0 | Tussock Flax, Aero Shard, Aero Dust |
| `kitewing` | Kitewing | Wild | Glasswing | aero | 19-24 | ×0.5 | ×1.7 | Yew Log, Aero Shard, Aero Dust, Hardtack |
| `leanstone` | Leanstone | Wild | Sentinel | aero | 19-24 | ×1.25 | ×0.7 | Yew Log, Aero Shard, Aero Dust, Hardtack |
| `steppe_harrier` | Steppe Harrier | Wild | Skirmisher | aero | 19-24 | ×0.7 | ×1.15 | Tussock Flax, Aero Shard, Aero Dust |
| `tumblehusk` | Tumblehusk | Wild | Drudge | aero | 19-24 | ×0.8 | ×0.7 | Tussock Flax, Hardtack |
| `gale_serpent` | Gale Serpent | Mini-boss | Executioner | aero | 19-24 | ×1.2 | ×1.9 | Yew Log, Tussock Flax, Hardtack, Leanstone Charm |
| `old_lean` | Old Lean | Mini-boss | Champion | aero | 19-24 | ×1.7 | ×1.2 | Yew Log, Tussock Flax, Hardtack, Leanstone Charm |
| `sky_titan` | Sky Titan | Mini-boss | Redoubt | aero | 19-24 | ×2.2 | ×0.85 | Yew Log, Tussock Flax, Hardtack, Leanstone Charm |
| `wind_wraith` | Wind Wraith | Mini-boss | Hexer | aero | 19-24 | ×1.6 | ×0.75 | Yew Log, Tussock Flax, Hardtack, Leanstone Charm |
| `tempest_monarch` | Tempest Monarch | Boss | Tyrant | aero | 19-24 | ×2.6 | ×1.7 | Yew Log, Tussock Flax, Leanstone Charm, The Long Lean |
| `the_unbroken_blow` | The Unbroken Blow | Boss | Juggernaut | aero | 19-24 | ×3.6 | ×1.4 | Yew Log, Tussock Flax, Leanstone Charm, The Long Lean |

### Frostfell Pass (`frostfell_pass`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `breathfrost` | Breathfrost | Wild | Glasswing | aero | 21-26 | ×0.5 | ×1.7 | Hoarlichen, Aero Shard, Aero Dust |
| `cairnwight` | Cairnwight | Wild | Blighter | aqua/aero | 21-26 | ×1.0 | ×0.6 | Hoarlichen, Everice |
| `hoarbound` | Hoarbound | Wild | Sentinel | aqua | 21-26 | ×1.25 | ×0.7 | Rimepelt, Aqua Shard, Aqua Dust, Hardtack |
| `rime_stalker` | Rime Stalker | Wild | Adept | aqua/aero | 21-26 | ×1.0 | ×0.9 | Rimepelt, Aqua Shard, Aqua Dust |
| `snowblind_wanderer` | Snowblind Wanderer | Wild | Drudge | aero | 21-26 | ×0.8 | ×0.7 | Everice, Aero Shard, Aero Dust, Hardtack |
| `coldsnap` | Coldsnap | Mini-boss | Executioner | aqua | 21-26 | ×1.2 | ×1.9 | Rimepelt, Hoarlichen, Everice, Rimebound Ring |
| `hoarking` | Hoarking | Mini-boss | Redoubt | aqua | 21-26 | ×2.2 | ×0.85 | Rimepelt, Hoarlichen, Everice, Rimebound Ring |
| `the_certain_road` | The Certain Road | Mini-boss | Hexer | aqua/aero | 21-26 | ×1.6 | ×0.75 | Rimepelt, Hoarlichen, Everice, Rimebound Ring |
| `the_last_cairn` | The Last Cairn | Mini-boss | Champion | aqua/aero | 21-26 | ×1.7 | ×1.2 | Rimepelt, Hoarlichen, Everice, Rimebound Ring |
| `the_road_under` | The Road Under | Boss | Aspect | aqua | 21-26 | ×2.6 | ×1.5 | Rimepelt, Hoarlichen, Everice, Rimebound Ring, The Holdfast |
| `the_white_corridor` | The White Corridor | Boss | Juggernaut | aqua/aero | 21-26 | ×3.6 | ×1.4 | Rimepelt, Hoarlichen, Everice, Rimebound Ring, The Holdfast |

### Thunderspire Peaks (`thunderspire_peaks`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `flashcount` | Flashcount | Wild | Lasher | electro | 23-28 | ×0.85 | ×1.0 | Iron Ore, Electro Shard, Electro Dust |
| `humming_ore` | Humming Ore | Wild | Sentinel | electro | 23-28 | ×1.25 | ×0.7 | Hum Quartz, Electro Shard, Electro Dust, Hardtack |
| `ionwake` | Ionwake | Wild | Adept | electro/aero | 23-28 | ×1.0 | ×0.9 | Iron Ore, Hum Quartz |
| `stormcrest_roc` | Stormcrest Roc | Wild | Bruiser | aero | 23-28 | ×1.15 | ×1.1 | Rowan Log, Electro Shard, Electro Dust, Hardtack |
| `updraft_wisp` | Updraft Wisp | Wild | Glasswing | aero | 23-28 | ×0.5 | ×1.7 | Rowan Log, Aero Shard, Aero Dust |
| `anvilhead` | Anvilhead | Mini-boss | Redoubt | electro/aero | 23-28 | ×2.2 | ×0.85 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `crown_fire` | Crown Fire | Mini-boss | Champion | electro | 23-28 | ×1.7 | ×1.2 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `the_shortening` | The Shortening | Mini-boss | Hexer | electro | 23-28 | ×1.6 | ×0.75 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `thunder_roc` | Thunder Roc | Mini-boss | Executioner | electro | 23-28 | ×1.2 | ×1.9 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `the_storm_that_passes` | The Storm That Passes | Boss | Juggernaut | electro/aero | 23-28 | ×3.6 | ×1.4 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant, Groundfault Grips |
| `the_strike_that_lands` | The Strike That Lands | Boss | Aspect | electro | 23-28 | ×2.6 | ×1.5 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant, Groundfault Grips |

### The Molten Deep (`the_molten_deep`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `cooling_thing` | Cooling Thing | Wild | Glasswing | geo | 25-29 | ×0.5 | ×1.7 | Obsidian, Geo Shard, Geo Dust |
| `crustwalker` | Crustwalker | Wild | Bruiser | geo | 25-29 | ×1.15 | ×1.1 | Emberhide, Geo Shard, Geo Dust, Hardtack |
| `ember_vent` | Ember Vent | Wild | Blighter | pyro | 25-29 | ×1.0 | ×0.6 | Firesalt, Obsidian |
| `molten_warden` | Molten Warden | Wild | Sentinel | pyro/geo | 25-29 | ×1.25 | ×0.7 | Emberhide, Pyro Shard, Pyro Dust, Hardtack |
| `slagswimmer` | Slagswimmer | Wild | Adept | pyro | 25-29 | ×1.0 | ×0.9 | Firesalt, Pyro Shard, Pyro Dust |
| `firstmelt` | Firstmelt | Mini-boss | Hexer | pyro/geo | 25-29 | ×1.6 | ×0.75 | Emberhide, Obsidian, Firesalt, Firstmelt Loop |
| `magma_behemoth` | Magma Behemoth | Mini-boss | Redoubt | pyro | 25-29 | ×2.2 | ×0.85 | Emberhide, Obsidian, Firesalt, Firstmelt Loop |
| `pyroclast` | Pyroclast | Mini-boss | Executioner | pyro | 25-29 | ×1.2 | ×1.9 | Emberhide, Obsidian, Firesalt, Firstmelt Loop |
| `the_floor` | The Floor | Mini-boss | Champion | pyro/geo | 25-29 | ×1.7 | ×1.2 | Emberhide, Obsidian, Firesalt, Firstmelt Loop |
| `efreet` | Efreet | Boss | Tyrant | pyro | 25-29 | ×2.6 | ×1.7 | Emberhide, Obsidian, Firstmelt Loop, The Long Cooling |
| `the_slow_stone` | The Slow Stone | Boss | Juggernaut | geo | 25-29 | ×3.6 | ×1.4 | Emberhide, Obsidian, Firstmelt Loop, The Long Cooling |


## Recipes by skill

### Woodcarving — 12 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_oak_knot` | 1 | 2x Oak Log | 1x Oak Knot | 12 |
| `craft_oak_quarterstaff` | 1 | 3x Oak Log | 1x Oak Quarterstaff | 18 |
| `craft_oak_wand` | 1 | 2x Oak Log | 1x Oak Wand | 12 |
| `craft_birch_knot` | 10 | 2x Birch Log | 1x Birch Knot | 48 |
| `craft_birch_quarterstaff` | 10 | 3x Birch Log | 1x Birch Quarterstaff | 72 |
| `craft_birch_wand` | 10 | 2x Birch Log | 1x Birch Wand | 48 |
| `craft_yew_knot` | 20 | 2x Yew Log | 1x Yew Knot | 88 |
| `craft_yew_quarterstaff` | 20 | 3x Yew Log, 1x Bronze Ingot | 1x Yew Quarterstaff | 176 |
| `craft_yew_wand` | 20 | 2x Yew Log, 1x Bronze Ingot | 1x Yew Wand | 132 |
| `craft_rowan_knot` | 30 | 2x Rowan Log | 1x Rowan Knot | 128 |
| `craft_rowan_quarterstaff` | 30 | 3x Rowan Log, 1x Iron Ingot | 1x Rowan Quarterstaff | 256 |
| `craft_rowan_wand` | 30 | 2x Rowan Log, 1x Iron Ingot | 1x Rowan Wand | 192 |

### Tailoring — 24 recipes

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
| `craft_seawrack_boots` | 20 | 2x Seawrack Fibre | 1x Seawrack Boots | 88 |
| `craft_seawrack_gloves` | 20 | 2x Seawrack Fibre | 1x Seawrack Gloves | 88 |
| `craft_seawrack_hood` | 20 | 2x Seawrack Fibre | 1x Seawrack Hood | 88 |
| `craft_seawrack_leggings` | 20 | 4x Seawrack Fibre | 1x Seawrack Leggings | 176 |
| `craft_seawrack_robe` | 20 | 5x Seawrack Fibre | 1x Seawrack Robe | 220 |
| `craft_rimepelt_belt` | 24 | 2x Rimepelt, 1x Tussock Flax | 1x Rimepelt Belt | 156 |
| `craft_tussock_boots` | 30 | 3x Tussock Flax | 1x Tussock Boots | 192 |
| `craft_tussock_gloves` | 30 | 3x Tussock Flax | 1x Tussock Gloves | 192 |
| `craft_tussock_hood` | 30 | 3x Tussock Flax | 1x Tussock Hood | 192 |
| `craft_tussock_leggings` | 30 | 5x Tussock Flax | 1x Tussock Leggings | 320 |
| `craft_tussock_robe` | 30 | 6x Tussock Flax | 1x Tussock Robe | 384 |
| `craft_emberhide_belt` | 34 | 2x Emberhide, 1x Tussock Flax | 1x Emberhide Belt | 216 |

### Metalworking — 2 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_bronze_ingot` | 1 | 2x Copper Ore, 1x Tin Ore, 1x Charcoal | 1x Bronze Ingot | 24 |
| `craft_iron_ingot` | 10 | 3x Iron Ore, 2x Charcoal | 1x Iron Ingot | 120 |

### Potions & Alchemy — 3 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_sapwort_draught` | 1 | 2x Sapwort | 1x Sapwort Draught | 12 |
| `craft_brookmint_tonic` | 10 | 2x Brookmint | 1x Brookmint Tonic | 48 |
| `craft_saltwort_draught` | 20 | 2x Saltwort | 1x Saltwort Draught | 88 |


