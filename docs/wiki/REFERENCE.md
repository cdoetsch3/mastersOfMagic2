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
| 26 | 9 | 286 | 337 | 233 | 58 |

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
| Jasper Pendant | `jasper_pendant` | 2 | neck | common | 17 | old_quarry |
| Seawrack Hood | `seawrack_hood` | 3 | hat | common | 16 | stormcliff_coast |
| Uplight | `uplight` | 4 | mainHand | epic | 28 | stormcliff_coast |
| Yew Knot | `yew_knot` | 5 | offHand | common | 20 | windward_steppe |
| Yew Quarterstaff | `yew_quarterstaff` | 7 | mainHand | common | 20 | windward_steppe |
| Yew Wand | `yew_wand` | 2 | mainHand | common | 20 | windward_steppe |
| Leanstone Charm | `leanstone_charm` | 2 | ring | rare | 22 | windward_steppe |
| The Long Lean | `the_long_lean` | 3 | robeTop | epic | 24 | windward_steppe |
| Tussock Hood | `tussock_hood` | 4 | hat | common | 24 | windward_steppe |
| Rowan Knot | `rowan_knot` | 6 | offHand | common | 19 | thunderspire_peaks |
| Rowan Quarterstaff | `rowan_quarterstaff` | 8 | mainHand | common | 19 | thunderspire_peaks |
| Rowan Wand | `rowan_wand` | 3 | mainHand | common | 19 | thunderspire_peaks |
| Groundfault Grips | `groundfault_grips` | 5 | gloves | epic | 22 | thunderspire_peaks |
| Ironwood Knot | `ironwood_knot` | 5 | offHand | common | 30 | the_kiln_desert |
| Ironwood Quarterstaff | `ironwood_quarterstaff` | 9 | mainHand | common | 30 | the_kiln_desert |
| Ironwood Wand | `ironwood_wand` | 4 | mainHand | common | 30 | the_kiln_desert |
| The Shadeless Band | `the_shadeless_band` | 6 | ring | rare | 32 | the_kiln_desert |
| The Hardest Edge | `the_hardest_edge` | 11 | mainHand | epic | 34 | the_kiln_desert |
| Mirrorflax Hood | `mirrorflax_hood` | 5 | hat | common | 34 | the_mirrormere |
| Bloodwood Knot | `bloodwood_knot` | 6 | offHand | common | 35 | the_mirrormere |
| Bloodwood Quarterstaff | `bloodwood_quarterstaff` | 10 | mainHand | common | 35 | the_mirrormere |
| Bloodwood Wand | `bloodwood_wand` | 4 | mainHand | common | 35 | the_mirrormere |
| Wrackcotton Hood | `wrackcotton_hood` | 5 | hat | common | 39 | tidewrack_shoals |
| Eclipse Opal Pendant | `opal_pendant` | 3 | neck | common | 39 | the_sunless_reach |
| Crestline Ring | `crestline_ring` | 5 | ring | rare | 40 | the_sunless_reach |
| Ebony Knot | `ebony_knot` | 6 | offHand | common | 40 | the_sunless_reach |
| Ebony Quarterstaff | `ebony_quarterstaff` | 11 | mainHand | common | 40 | the_sunless_reach |
| Ebony Wand | `ebony_wand` | 5 | mainHand | common | 40 | the_sunless_reach |
| The Dividing Line | `the_dividing_line` | 6 | mainHand | epic | 42 | the_sunless_reach |
| Sidereal Signet | `sidereal_signet` | 4 | ring | rare | 42 | the_shattered_orrery |
| The Running Count | `the_running_count` | 5 | gloves | epic | 44 | the_shattered_orrery |
| Spiritwood Knot | `spiritwood_knot` | 7 | offHand | common | 45 | hallowmarch |
| Spiritwood Quarterstaff | `spiritwood_quarterstaff` | 12 | mainHand | common | 45 | hallowmarch |
| Spiritwood Wand | `spiritwood_wand` | 5 | mainHand | common | 45 | hallowmarch |
| Umbralweave Hood | `umbralweave_hood` | 6 | hat | common | 48 | the_umbral_wastes |
| Unleft Linen Hood | `unleft_hood` | 6 | hat | common | 53 | the_reliquary_deep |
| Eclipse Opal Signet | `eclipse_signet` | 3 | ring | common | 50 | the_sealed_garden |
| The Last Reading | `the_last_reading` | 5 | neck | rare | 45 | the_glass_archive |
| Aetherwood Knot | `aetherwood_knot` | 7 | offHand | common | 50 | the_collapsed_academy |
| Aetherwood Quarterstaff | `aetherwood_quarterstaff` | 12 | mainHand | common | 50 | the_collapsed_academy |
| Aetherwood Wand | `aetherwood_wand` | 5 | mainHand | common | 50 | the_collapsed_academy |
| The Unbuilt Stair | `the_unbuilt_stair` | 13 | mainHand | epic | 54 | the_collapsed_academy |
| Colophon Signet | `colophon_signet` | 3 | ring | rare | 56 | the_unwritten_library |
| The Open Colophon | `the_open_colophon` | 9 | offHand | epic | 58 | the_unwritten_library |
| Corona Pearl Torc | `corona_torc` | 3 | neck | common | 58 | the_eclipsed_citadel |
| The Last Thing in the Way | `the_last_thing_in_the_way` | 6 | gloves | epic | 60 | the_eclipsed_citadel |
| Greater Solar Gem | `gem_solar_greater` | 7 | gem | epic | 1 | — |
| Lesser Solar Gem | `gem_solar_lesser` | 3 | gem | uncommon | 1 | — |
| Standard Solar Gem | `gem_solar_standard` | 6 | gem | rare | 1 | — |

### `dodge`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Seawrack Boots | `seawrack_boots` | 2 | boots | common | 16 | stormcliff_coast |
| Leanstone Charm | `leanstone_charm` | 6 | ring | rare | 22 | windward_steppe |
| The Long Lean | `the_long_lean` | 8 | robeTop | epic | 24 | windward_steppe |
| Tussock Boots | `tussock_boots` | 3 | boots | common | 24 | windward_steppe |
| Rimebound Ring | `rimebound_ring` | 3 | ring | rare | 24 | frostfell_pass |
| Mirrorflax Boots | `mirrorflax_boots` | 4 | boots | common | 34 | the_mirrormere |
| The Waning Charm | `the_waning_charm` | 9 | ring | rare | 35 | the_mirrormere |
| The Larger Reflection | `the_larger_reflection` | 6 | robeTop | epic | 37 | the_mirrormere |
| The Turning Tide | `the_turning_tide` | 6 | neck | rare | 38 | tidewrack_shoals |
| Wrackcotton Boots | `wrackcotton_boots` | 5 | boots | common | 39 | tidewrack_shoals |
| Lowwater Tread | `lowwater_tread` | 7 | boots | epic | 40 | tidewrack_shoals |
| Crestline Ring | `crestline_ring` | 5 | ring | rare | 40 | the_sunless_reach |
| Umbralweave Boots | `umbralweave_boots` | 6 | boots | common | 48 | the_umbral_wastes |
| Unleft Linen Boots | `unleft_boots` | 7 | boots | common | 53 | the_reliquary_deep |
| The Unconsecrated | `the_unconsecrated` | 6 | boots | epic | 56 | the_reliquary_deep |
| Eclipse Opal Signet | `eclipse_signet` | 3 | ring | common | 50 | the_sealed_garden |
| Everice Band | `everice_band` | 3 | ring | common | 45 | the_buried_sky |
| Nacre Pendant | `nacre_pendant` | 6 | neck | common | 46 | the_buried_sky |
| The Eclipsed Band | `the_eclipsed_band` | 6 | ring | rare | 58 | the_eclipsed_citadel |
| Greater Aero Gem | `gem_aero_greater` | 2 | gem | epic | 1 | — |
| Lesser Aero Gem | `gem_aero_lesser` | 1 | gem | uncommon | 1 | — |
| Standard Aero Gem | `gem_aero_standard` | 1 | gem | rare | 1 | — |
| Greater Lunar Gem | `gem_lunar_greater` | 2 | gem | epic | 1 | — |
| Lesser Lunar Gem | `gem_lunar_lesser` | 1 | gem | uncommon | 1 | — |
| Standard Lunar Gem | `gem_lunar_standard` | 1 | gem | rare | 1 | — |

### `critChance`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Heartwood Staff | `heartwood_stave` | 5 | mainHand | epic | 5 | whispering_woods |
| Cinder Loop | `cinder_loop` | 5 | ring | rare | 9 | cinderpeak_foothills |
| Fulgurite Pendant | `fulgurite_pendant` | 8 | neck | rare | 26 | stormcliff_coast |
| Uplight | `uplight` | 12 | mainHand | epic | 28 | stormcliff_coast |
| Rowan Knot | `rowan_knot` | 2 | offHand | common | 19 | thunderspire_peaks |
| Rowan Quarterstaff | `rowan_quarterstaff` | 3 | mainHand | common | 19 | thunderspire_peaks |
| Rowan Wand | `rowan_wand` | 4 | mainHand | common | 19 | thunderspire_peaks |
| Countstone Pendant | `countstone_pendant` | 10 | neck | rare | 20 | thunderspire_peaks |
| Firstmelt Loop | `firstmelt_loop` | 5 | ring | rare | 28 | the_molten_deep |
| Ironwood Knot | `ironwood_knot` | 3 | offHand | common | 30 | the_kiln_desert |
| Ironwood Quarterstaff | `ironwood_quarterstaff` | 4 | mainHand | common | 30 | the_kiln_desert |
| Ironwood Wand | `ironwood_wand` | 5 | mainHand | common | 30 | the_kiln_desert |
| The Hardest Edge | `the_hardest_edge` | 8 | mainHand | epic | 34 | the_kiln_desert |
| Bloodwood Knot | `bloodwood_knot` | 4 | offHand | common | 35 | the_mirrormere |
| Bloodwood Quarterstaff | `bloodwood_quarterstaff` | 5 | mainHand | common | 35 | the_mirrormere |
| Bloodwood Wand | `bloodwood_wand` | 6 | mainHand | common | 35 | the_mirrormere |
| Zodiac Pendant | `zodiac_pendant` | 10 | neck | rare | 37 | starfall_basin |
| The Aimed Sky | `the_aimed_sky` | 10 | neck | epic | 39 | starfall_basin |
| Ebony Knot | `ebony_knot` | 5 | offHand | common | 40 | the_sunless_reach |
| Ebony Quarterstaff | `ebony_quarterstaff` | 6 | mainHand | common | 40 | the_sunless_reach |
| Ebony Wand | `ebony_wand` | 7 | mainHand | common | 40 | the_sunless_reach |
| The Dividing Line | `the_dividing_line` | 10 | mainHand | epic | 42 | the_sunless_reach |
| Sidereal Glass Pendant | `sidereal_pendant` | 4 | neck | common | 42 | the_shattered_orrery |
| Sidereal Signet | `sidereal_signet` | 10 | ring | rare | 42 | the_shattered_orrery |
| The Running Count | `the_running_count` | 8 | gloves | epic | 44 | the_shattered_orrery |
| Spiritwood Knot | `spiritwood_knot` | 6 | offHand | common | 45 | hallowmarch |
| Spiritwood Quarterstaff | `spiritwood_quarterstaff` | 7 | mainHand | common | 45 | hallowmarch |
| Spiritwood Wand | `spiritwood_wand` | 8 | mainHand | common | 45 | hallowmarch |
| The Considered Ring | `the_considered_ring` | 8 | ring | rare | 49 | the_umbral_wastes |
| The Deliberate Dark | `the_deliberate_dark` | 6 | ring | epic | 51 | the_umbral_wastes |
| Eclipse Opal Signet | `eclipse_signet` | 6 | ring | common | 50 | the_sealed_garden |
| Stonefall Signet | `stonefall_signet` | 6 | ring | rare | 48 | the_buried_sky |
| Aetherwood Knot | `aetherwood_knot` | 7 | offHand | common | 50 | the_collapsed_academy |
| Aetherwood Quarterstaff | `aetherwood_quarterstaff` | 8 | mainHand | common | 50 | the_collapsed_academy |
| Aetherwood Wand | `aetherwood_wand` | 9 | mainHand | common | 50 | the_collapsed_academy |
| Chalkline Signet | `chalkline_signet` | 8 | ring | rare | 52 | the_collapsed_academy |
| The Unbuilt Stair | `the_unbuilt_stair` | 8 | mainHand | epic | 54 | the_collapsed_academy |
| Colophon Signet | `colophon_signet` | 12 | ring | rare | 56 | the_unwritten_library |
| The Open Colophon | `the_open_colophon` | 8 | offHand | epic | 58 | the_unwritten_library |
| Corona Pearl Torc | `corona_torc` | 5 | neck | common | 58 | the_eclipsed_citadel |
| The Eclipsed Band | `the_eclipsed_band` | 8 | ring | rare | 58 | the_eclipsed_citadel |
| Eclipse Iron Ring | `eclipse_ring` | 6 | ring | common | 60 | the_eclipsed_citadel |
| The Last Thing in the Way | `the_last_thing_in_the_way` | 10 | gloves | epic | 60 | the_eclipsed_citadel |
| Greater Astral Gem | `gem_astral_greater` | 3 | gem | epic | 1 | — |
| Lesser Astral Gem | `gem_astral_lesser` | 1 | gem | uncommon | 1 | — |
| Standard Astral Gem | `gem_astral_standard` | 2 | gem | rare | 1 | — |
| Greater Electro Gem | `gem_electro_greater` | 3 | gem | epic | 1 | — |
| Lesser Electro Gem | `gem_electro_lesser` | 1 | gem | uncommon | 1 | — |
| Standard Electro Gem | `gem_electro_standard` | 2 | gem | rare | 1 | — |

### `critDamage`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Heartwood Staff | `heartwood_stave` | 10 | mainHand | epic | 5 | whispering_woods |
| Cinder Loop | `cinder_loop` | 5 | ring | rare | 9 | cinderpeak_foothills |
| Fulgurite Pendant | `fulgurite_pendant` | 10 | neck | rare | 26 | stormcliff_coast |
| Uplight | `uplight` | 15 | mainHand | epic | 28 | stormcliff_coast |
| Rowan Quarterstaff | `rowan_quarterstaff` | 8 | mainHand | common | 19 | thunderspire_peaks |
| Rowan Wand | `rowan_wand` | 6 | mainHand | common | 19 | thunderspire_peaks |
| Countstone Pendant | `countstone_pendant` | 12 | neck | rare | 20 | thunderspire_peaks |
| Obsidian Pendant | `obsidian_pendant` | 8 | neck | common | 27 | the_molten_deep |
| Firstmelt Loop | `firstmelt_loop` | 25 | ring | rare | 28 | the_molten_deep |
| The Long Cooling | `the_long_cooling` | 15 | hat | epic | 29 | the_molten_deep |
| Ironwood Quarterstaff | `ironwood_quarterstaff` | 10 | mainHand | common | 30 | the_kiln_desert |
| Ironwood Wand | `ironwood_wand` | 8 | mainHand | common | 30 | the_kiln_desert |
| The Hardest Edge | `the_hardest_edge` | 18 | mainHand | epic | 34 | the_kiln_desert |
| Bloodwood Quarterstaff | `bloodwood_quarterstaff` | 12 | mainHand | common | 35 | the_mirrormere |
| Bloodwood Wand | `bloodwood_wand` | 10 | mainHand | common | 35 | the_mirrormere |
| Zodiac Pendant | `zodiac_pendant` | 12 | neck | rare | 37 | starfall_basin |
| The Aimed Sky | `the_aimed_sky` | 18 | neck | epic | 39 | starfall_basin |
| Ebony Quarterstaff | `ebony_quarterstaff` | 14 | mainHand | common | 40 | the_sunless_reach |
| Ebony Wand | `ebony_wand` | 12 | mainHand | common | 40 | the_sunless_reach |
| The Dividing Line | `the_dividing_line` | 20 | mainHand | epic | 42 | the_sunless_reach |
| Spiritwood Quarterstaff | `spiritwood_quarterstaff` | 16 | mainHand | common | 45 | hallowmarch |
| Spiritwood Wand | `spiritwood_wand` | 14 | mainHand | common | 45 | hallowmarch |
| The Considered Ring | `the_considered_ring` | 34 | ring | rare | 49 | the_umbral_wastes |
| The Deliberate Dark | `the_deliberate_dark` | 28 | ring | epic | 51 | the_umbral_wastes |
| Censer Pendant | `censer_pendant` | 20 | neck | rare | 54 | the_reliquary_deep |
| Eclipse Opal Signet | `eclipse_signet` | 10 | ring | common | 50 | the_sealed_garden |
| The Last Reading | `the_last_reading` | 20 | neck | rare | 45 | the_glass_archive |
| The Noon Hour | `the_noon_hour` | 20 | hat | epic | 47 | the_glass_archive |
| Aetherwood Quarterstaff | `aetherwood_quarterstaff` | 18 | mainHand | common | 50 | the_collapsed_academy |
| Aetherwood Wand | `aetherwood_wand` | 16 | mainHand | common | 50 | the_collapsed_academy |
| The Unbuilt Stair | `the_unbuilt_stair` | 16 | mainHand | epic | 54 | the_collapsed_academy |
| Colophon Signet | `colophon_signet` | 30 | ring | rare | 56 | the_unwritten_library |
| Eclipse Iron Ring | `eclipse_ring` | 12 | ring | common | 60 | the_eclipsed_citadel |
| The Last Thing in the Way | `the_last_thing_in_the_way` | 10 | gloves | epic | 60 | the_eclipsed_citadel |
| Greater Pyro Gem | `gem_pyro_greater` | 9 | gem | epic | 1 | — |
| Lesser Pyro Gem | `gem_pyro_lesser` | 4 | gem | uncommon | 1 | — |
| Standard Pyro Gem | `gem_pyro_standard` | 8 | gem | rare | 1 | — |
| Greater Umbra Gem | `gem_umbra_greater` | 9 | gem | epic | 1 | — |
| Lesser Umbra Gem | `gem_umbra_lesser` | 4 | gem | uncommon | 1 | — |
| Standard Umbra Gem | `gem_umbra_standard` | 8 | gem | rare | 1 | — |

### `deflectChance`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Overseer's Seal | `overseers_seal` | 12 | ring | rare | 18 | old_quarry |
| The Given Weight | `the_given_weight` | 10 | neck | epic | 19 | old_quarry |
| Seawrack Gloves | `seawrack_gloves` | 6 | gloves | common | 16 | stormcliff_coast |
| Tussock Gloves | `tussock_gloves` | 8 | gloves | common | 24 | windward_steppe |
| Rimebound Ring | `rimebound_ring` | 10 | ring | rare | 24 | frostfell_pass |
| The Long Cooling | `the_long_cooling` | 12 | hat | epic | 29 | the_molten_deep |
| Mirrorflax Gloves | `mirrorflax_gloves` | 10 | gloves | common | 34 | the_mirrormere |
| Wrackcotton Gloves | `wrackcotton_gloves` | 14 | gloves | common | 39 | tidewrack_shoals |
| Umbralweave Gloves | `umbralweave_gloves` | 16 | gloves | common | 48 | the_umbral_wastes |
| Unleft Linen Gloves | `unleft_gloves` | 18 | gloves | common | 53 | the_reliquary_deep |
| The Noon Hour | `the_noon_hour` | 12 | hat | epic | 47 | the_glass_archive |
| Stonefall Signet | `stonefall_signet` | 18 | ring | rare | 48 | the_buried_sky |
| Bedrock Greaves | `bedrock_greaves` | 10 | robeBottom | epic | 50 | the_buried_sky |
| Chalkline Signet | `chalkline_signet` | 18 | ring | rare | 52 | the_collapsed_academy |
| The Corona | `the_corona` | 16 | hat | epic | 60 | the_eclipsed_citadel |
| Greater Arcane Gem | `gem_arcane_greater` | 7 | gem | epic | 1 | — |
| Lesser Arcane Gem | `gem_arcane_lesser` | 3 | gem | uncommon | 1 | — |
| Standard Arcane Gem | `gem_arcane_standard` | 6 | gem | rare | 1 | — |
| Greater Geo Gem | `gem_geo_greater` | 7 | gem | epic | 1 | — |
| Lesser Geo Gem | `gem_geo_lesser` | 3 | gem | uncommon | 1 | — |
| Standard Geo Gem | `gem_geo_standard` | 6 | gem | rare | 1 | — |

### `deflectAmount`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Overseer's Seal | `overseers_seal` | 20 | ring | rare | 18 | old_quarry |
| The Given Weight | `the_given_weight` | 25 | neck | epic | 19 | old_quarry |
| Seawrack Gloves | `seawrack_gloves` | 15 | gloves | common | 16 | stormcliff_coast |
| Tussock Gloves | `tussock_gloves` | 20 | gloves | common | 24 | windward_steppe |
| Rimebound Ring | `rimebound_ring` | 20 | ring | rare | 24 | frostfell_pass |
| The Long Cooling | `the_long_cooling` | 25 | hat | epic | 29 | the_molten_deep |
| Mirrorflax Gloves | `mirrorflax_gloves` | 20 | gloves | common | 34 | the_mirrormere |
| Wrackcotton Gloves | `wrackcotton_gloves` | 24 | gloves | common | 39 | tidewrack_shoals |
| Umbralweave Gloves | `umbralweave_gloves` | 22 | gloves | common | 48 | the_umbral_wastes |
| Unleft Linen Gloves | `unleft_gloves` | 26 | gloves | common | 53 | the_reliquary_deep |
| The Noon Hour | `the_noon_hour` | 14 | hat | epic | 47 | the_glass_archive |
| Bedrock Greaves | `bedrock_greaves` | 10 | robeBottom | epic | 50 | the_buried_sky |
| Chalkline Signet | `chalkline_signet` | 8 | ring | rare | 52 | the_collapsed_academy |
| The Corona | `the_corona` | 14 | hat | epic | 60 | the_eclipsed_citadel |

### `maxHpBonus`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Bindweed Boots | `bindweed_boots` | 1 | boots | common | 1 | whispering_woods |
| Bindweed Gloves | `bindweed_gloves` | 1 | gloves | common | 1 | whispering_woods |
| Bindweed Leggings | `bindweed_leggings` | 4 | robeBottom | common | 1 | whispering_woods |
| Bindweed Robe | `bindweed_robe` | 6 | robeTop | common | 1 | whispering_woods |
| Sporecap Mantle | `sporecap_mantle` | 12 | robeTop | rare | 4 | whispering_woods |
| Amber Band | `amber_band` | 4 | ring | common | 8 | thornmire |
| Bogflax Boots | `bogflax_boots` | 2 | boots | common | 10 | thornmire |
| Bogflax Gloves | `bogflax_gloves` | 2 | gloves | common | 10 | thornmire |
| Bogflax Leggings | `bogflax_leggings` | 7 | robeBottom | common | 10 | thornmire |
| Bogflax Robe | `bogflax_robe` | 10 | robeTop | common | 10 | thornmire |
| Amber Ring | `amber_ring` | 6 | ring | common | 12 | thornmire |
| Jasper Ring | `jasper_ring` | 7 | ring | common | 17 | old_quarry |
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
| Obsidian Ring | `obsidian_ring` | 10 | ring | common | 27 | the_molten_deep |
| The Long Cooling | `the_long_cooling` | 22 | hat | epic | 29 | the_molten_deep |
| The Shadeless Band | `the_shadeless_band` | 18 | ring | rare | 32 | the_kiln_desert |
| Mirrorflax Boots | `mirrorflax_boots` | 5 | boots | common | 34 | the_mirrormere |
| Mirrorflax Gloves | `mirrorflax_gloves` | 5 | gloves | common | 34 | the_mirrormere |
| Mirrorflax Leggings | `mirrorflax_leggings` | 16 | robeBottom | common | 34 | the_mirrormere |
| Mirrorflax Robe | `mirrorflax_robe` | 23 | robeTop | common | 34 | the_mirrormere |
| The Waning Charm | `the_waning_charm` | 16 | ring | rare | 35 | the_mirrormere |
| The Larger Reflection | `the_larger_reflection` | 40 | robeTop | epic | 37 | the_mirrormere |
| Wrackcotton Boots | `wrackcotton_boots` | 6 | boots | common | 39 | tidewrack_shoals |
| Wrackcotton Gloves | `wrackcotton_gloves` | 7 | gloves | common | 39 | tidewrack_shoals |
| Wrackcotton Leggings | `wrackcotton_leggings` | 22 | robeBottom | common | 39 | tidewrack_shoals |
| Wrackcotton Robe | `wrackcotton_robe` | 32 | robeTop | common | 39 | tidewrack_shoals |
| Lowwater Tread | `lowwater_tread` | 24 | boots | epic | 40 | tidewrack_shoals |
| Eclipse Opal Ring | `opal_ring` | 14 | ring | common | 39 | the_sunless_reach |
| Crestline Ring | `crestline_ring` | 20 | ring | rare | 40 | the_sunless_reach |
| Sidereal Glass Ring | `sidereal_ring` | 16 | ring | common | 42 | the_shattered_orrery |
| The Maintained Road | `the_maintained_road` | 45 | neck | epic | 49 | hallowmarch |
| Umbralweave Boots | `umbralweave_boots` | 8 | boots | common | 48 | the_umbral_wastes |
| Umbralweave Gloves | `umbralweave_gloves` | 9 | gloves | common | 48 | the_umbral_wastes |
| Umbralweave Leggings | `umbralweave_leggings` | 29 | robeBottom | common | 48 | the_umbral_wastes |
| Umbralweave Robe | `umbralweave_robe` | 42 | robeTop | common | 48 | the_umbral_wastes |
| The Deliberate Dark | `the_deliberate_dark` | 20 | ring | epic | 51 | the_umbral_wastes |
| Aetherglass Locket | `aetherglass_locket` | 45 | neck | common | 53 | the_reliquary_deep |
| Unleft Linen Boots | `unleft_boots` | 10 | boots | common | 53 | the_reliquary_deep |
| Unleft Linen Gloves | `unleft_gloves` | 12 | gloves | common | 53 | the_reliquary_deep |
| Unleft Linen Leggings | `unleft_leggings` | 38 | robeBottom | common | 53 | the_reliquary_deep |
| Unleft Linen Robe | `unleft_robe` | 55 | robeTop | common | 53 | the_reliquary_deep |
| The Unconsecrated | `the_unconsecrated` | 32 | boots | epic | 56 | the_reliquary_deep |
| The Gardener's Loop | `the_gardeners_loop` | 25 | ring | rare | 51 | the_sealed_garden |
| The Season At Once | `the_season_at_once` | 60 | robeTop | epic | 53 | the_sealed_garden |
| Orchard Amber Loop | `orchard_loop` | 25 | ring | common | 54 | the_sealed_garden |
| The Last Reading | `the_last_reading` | 30 | neck | rare | 45 | the_glass_archive |
| The Noon Hour | `the_noon_hour` | 55 | hat | epic | 47 | the_glass_archive |
| Everice Band | `everice_band` | 15 | ring | common | 45 | the_buried_sky |
| Nacre Pendant | `nacre_pendant` | 25 | neck | common | 46 | the_buried_sky |
| Stonefall Signet | `stonefall_signet` | 22 | ring | rare | 48 | the_buried_sky |
| Bedrock Greaves | `bedrock_greaves` | 45 | robeBottom | epic | 50 | the_buried_sky |
| Corona Pearl Torc | `corona_torc` | 45 | neck | common | 58 | the_eclipsed_citadel |
| The Eclipsed Band | `the_eclipsed_band` | 60 | ring | rare | 58 | the_eclipsed_citadel |
| The Corona | `the_corona` | 70 | hat | epic | 60 | the_eclipsed_citadel |

### `damagePerCast`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Oak Wand | `oak_wand` | 2 | mainHand | common | 1 | whispering_woods |
| Birch Wand | `birch_wand` | 3 | mainHand | common | 10 | ashfall_vale |
| Uplight | `uplight` | 6 | mainHand | epic | 28 | stormcliff_coast |
| Yew Wand | `yew_wand` | 4 | mainHand | common | 20 | windward_steppe |
| Rowan Wand | `rowan_wand` | 5 | mainHand | common | 19 | thunderspire_peaks |
| Groundfault Grips | `groundfault_grips` | 4 | gloves | epic | 22 | thunderspire_peaks |
| Ironwood Wand | `ironwood_wand` | 6 | mainHand | common | 30 | the_kiln_desert |
| Bloodwood Wand | `bloodwood_wand` | 7 | mainHand | common | 35 | the_mirrormere |
| The Aimed Sky | `the_aimed_sky` | 9 | neck | epic | 39 | starfall_basin |
| Ebony Wand | `ebony_wand` | 8 | mainHand | common | 40 | the_sunless_reach |
| The Dividing Line | `the_dividing_line` | 12 | mainHand | epic | 42 | the_sunless_reach |
| The Running Count | `the_running_count` | 10 | gloves | epic | 44 | the_shattered_orrery |
| Spiritwood Wand | `spiritwood_wand` | 9 | mainHand | common | 45 | hallowmarch |
| Aetherwood Wand | `aetherwood_wand` | 10 | mainHand | common | 50 | the_collapsed_academy |
| The Open Colophon | `the_open_colophon` | 12 | offHand | epic | 58 | the_unwritten_library |
| Eclipse Iron Ring | `eclipse_ring` | 7 | ring | common | 60 | the_eclipsed_citadel |
| The Last Thing in the Way | `the_last_thing_in_the_way` | 14 | gloves | epic | 60 | the_eclipsed_citadel |

### `damagePerCharge`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Oak Quarterstaff | `oak_quarterstaff` | 1 | mainHand | common | 1 | whispering_woods |
| Heartwood Staff | `heartwood_stave` | 3 | mainHand | epic | 5 | whispering_woods |
| Birch Quarterstaff | `birch_quarterstaff` | 2 | mainHand | common | 10 | ashfall_vale |
| Yew Quarterstaff | `yew_quarterstaff` | 3 | mainHand | common | 20 | windward_steppe |
| Rowan Quarterstaff | `rowan_quarterstaff` | 4 | mainHand | common | 19 | thunderspire_peaks |
| Ironwood Quarterstaff | `ironwood_quarterstaff` | 5 | mainHand | common | 30 | the_kiln_desert |
| The Hardest Edge | `the_hardest_edge` | 7 | mainHand | epic | 34 | the_kiln_desert |
| Bloodwood Quarterstaff | `bloodwood_quarterstaff` | 6 | mainHand | common | 35 | the_mirrormere |
| Ebony Quarterstaff | `ebony_quarterstaff` | 7 | mainHand | common | 40 | the_sunless_reach |
| Spiritwood Quarterstaff | `spiritwood_quarterstaff` | 8 | mainHand | common | 45 | hallowmarch |
| Aetherwood Quarterstaff | `aetherwood_quarterstaff` | 9 | mainHand | common | 50 | the_collapsed_academy |
| The Unbuilt Stair | `the_unbuilt_stair` | 10 | mainHand | epic | 54 | the_collapsed_academy |

### `shieldStrengthPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Brookstone Pendant | `brookstone_pendant` | 10 | neck | rare | 6 | glimmerbrook |
| The Holdfast | `the_holdfast` | 15 | neck | epic | 25 | frostfell_pass |
| The Turning Tide | `the_turning_tide` | 12 | neck | rare | 38 | tidewrack_shoals |
| Lowwater Tread | `lowwater_tread` | 10 | boots | epic | 40 | tidewrack_shoals |
| Votive Pendant | `votive_pendant` | 18 | neck | rare | 47 | hallowmarch |
| The Maintained Road | `the_maintained_road` | 20 | neck | epic | 49 | hallowmarch |
| Aetherglass Locket | `aetherglass_locket` | 12 | neck | common | 53 | the_reliquary_deep |
| Censer Pendant | `censer_pendant` | 15 | neck | rare | 54 | the_reliquary_deep |
| Everice Band | `everice_band` | 12 | ring | common | 45 | the_buried_sky |
| Nacre Pendant | `nacre_pendant` | 8 | neck | common | 46 | the_buried_sky |
| The Corona | `the_corona` | 12 | hat | epic | 60 | the_eclipsed_citadel |
| Greater Aqua Gem | `gem_aqua_greater` | 9 | gem | epic | 1 | — |
| Lesser Aqua Gem | `gem_aqua_lesser` | 4 | gem | uncommon | 1 | — |
| Standard Aqua Gem | `gem_aqua_standard` | 8 | gem | rare | 1 | — |
| Greater Sanctus Gem | `gem_sanctus_greater` | 5 | gem | epic | 1 | — |
| Lesser Sanctus Gem | `gem_sanctus_lesser` | 2 | gem | uncommon | 1 | — |
| Standard Sanctus Gem | `gem_sanctus_standard` | 4 | gem | rare | 1 | — |

### `healingReceivedPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Amber Drop | `amber_drop` | 3 | neck | common | 8 | thornmire |
| Amber Pendant | `amber_pendant` | 5 | neck | common | 12 | thornmire |
| Wickerbound Ring | `wickerbound_ring` | 10 | ring | rare | 12 | thornmire |
| Votive Pendant | `votive_pendant` | 12 | neck | rare | 47 | hallowmarch |
| The Maintained Road | `the_maintained_road` | 15 | neck | epic | 49 | hallowmarch |
| Aetherglass Locket | `aetherglass_locket` | 10 | neck | common | 53 | the_reliquary_deep |
| Censer Pendant | `censer_pendant` | 15 | neck | rare | 54 | the_reliquary_deep |
| The Unconsecrated | `the_unconsecrated` | 10 | boots | epic | 56 | the_reliquary_deep |
| The Gardener's Loop | `the_gardeners_loop` | 18 | ring | rare | 51 | the_sealed_garden |
| The Season At Once | `the_season_at_once` | 15 | robeTop | epic | 53 | the_sealed_garden |
| Orchard Amber Loop | `orchard_loop` | 15 | ring | common | 54 | the_sealed_garden |
| Greater Flora Gem | `gem_flora_greater` | 9 | gem | epic | 1 | — |
| Lesser Flora Gem | `gem_flora_lesser` | 4 | gem | uncommon | 1 | — |
| Standard Flora Gem | `gem_flora_standard` | 8 | gem | rare | 1 | — |
| Greater Sanctus Gem | `gem_sanctus_greater` | 5 | gem | epic | 1 | — |
| Lesser Sanctus Gem | `gem_sanctus_lesser` | 2 | gem | uncommon | 1 | — |
| Standard Sanctus Gem | `gem_sanctus_standard` | 4 | gem | rare | 1 | — |

### `regrowPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| The Charlock | `the_charlock` | 2 | neck | epic | 14 | ashfall_vale |
| The Gardener's Loop | `the_gardeners_loop` | 2 | ring | rare | 51 | the_sealed_garden |
| The Season At Once | `the_season_at_once` | 3 | robeTop | epic | 53 | the_sealed_garden |
| Orchard Amber Loop | `orchard_loop` | 1 | ring | common | 54 | the_sealed_garden |

### `beltSlots`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Fawnhide Belt | `fawnhide_belt` | 1 | belt | common | 4 | glimmerbrook |
| Tuskhide Belt | `tuskhide_belt` | 2 | belt | common | 11 | cinderpeak_foothills |
| Rimepelt Belt | `rimepelt_belt` | 3 | belt | common | 23 | frostfell_pass |
| Emberhide Belt | `emberhide_belt` | 4 | belt | common | 27 | the_molten_deep |
| Drownling Belt | `drownling_belt` | 5 | belt | common | 38 | tidewrack_shoals |
| Thornpenitent Belt | `penitent_belt` | 8 | belt | common | 52 | the_sealed_garden |
| Palimpsest Belt | `palimpsest_belt` | 6 | belt | common | 45 | the_glass_archive |
| Corebiter Belt | `corebiter_belt` | 7 | belt | common | 48 | the_buried_sky |
| Blankspine Belt | `blankspine_belt` | 9 | belt | common | 56 | the_unwritten_library |

### `consumablePotencyPercent`

| Name | Id | Value | Slot | Rarity | Equip Lv | Zone |
|---|---|---|---|---|---|---|
| Fawnhide Belt | `fawnhide_belt` | 10 | belt | common | 4 | glimmerbrook |
| Tuskhide Belt | `tuskhide_belt` | 15 | belt | common | 11 | cinderpeak_foothills |
| Rimepelt Belt | `rimepelt_belt` | 20 | belt | common | 23 | frostfell_pass |
| Emberhide Belt | `emberhide_belt` | 20 | belt | common | 27 | the_molten_deep |
| Drownling Belt | `drownling_belt` | 25 | belt | common | 38 | tidewrack_shoals |
| Thornpenitent Belt | `penitent_belt` | 30 | belt | common | 52 | the_sealed_garden |
| Palimpsest Belt | `palimpsest_belt` | 25 | belt | common | 45 | the_glass_archive |
| Corebiter Belt | `corebiter_belt` | 30 | belt | common | 48 | the_buried_sky |
| Blankspine Belt | `blankspine_belt` | 30 | belt | common | 56 | the_unwritten_library |


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
| `flora_crystal` | Flora Crystal | mote |  | uncommon | 1 |  | craft: `refine_flora_crystal`; craft: `transmute_flora_crystal`; drop: `elderroot`; drop: `mother_spore`; drop: `hollow_stag`; drop: `the_murmur`; drop: `heartwood`; drop: `the_standing_green`; +19 more (see content.json) |
| `flora_dust` | Flora Dust | mote |  | common | 1 |  | craft: `transmute_flora_dust`; drop: `listening_fawn`; drop: `thornback_sprite`; drop: `sporecap_shambler`; drop: `bindweed_creeper`; drop: `rootknuckle`; drop: `elderroot`; +44 more (see content.json) |
| `flora_shard` | Flora Shard | mote |  | common | 1 |  | craft: `refine_flora_shard`; craft: `transmute_flora_shard`; drop: `thornback_sprite`; drop: `sporecap_shambler`; drop: `bindweed_creeper`; drop: `rootknuckle`; drop: `elderroot`; drop: `mother_spore`; +28 more (see content.json) |
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
| `aqua_crystal` | Aqua Crystal | mote |  | uncommon | 1 |  | craft: `refine_aqua_crystal`; craft: `transmute_aqua_crystal`; drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; drop: `the_cold_below`; drop: `stillwater`; +18 more (see content.json) |
| `aqua_dust` | Aqua Dust | mote |  | common | 1 |  | craft: `transmute_aqua_dust`; drop: `brook_naiad`; drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; +44 more (see content.json) |
| `aqua_shard` | Aqua Shard | mote |  | common | 1 |  | craft: `refine_aqua_shard`; craft: `transmute_aqua_shard`; drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; drop: `the_held_breath`; +29 more (see content.json) |
| `fawnhide` | Fawnhide | material |  | common | 1 |  | drop: `siltback_crawler`; drop: `chill_eel`; drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; +2 more (see content.json) |
| `proof_of_the_brook` | Proof of the Brook | key |  | rare | 1 |  | drop: `the_cold_below`; drop: `stillwater` |
| `sapwort` | Sapwort | material |  | common | 1 |  | gather: `gb_sapwort_shallows`; drop: `brook_naiad`; drop: `shiverfish_shoal`; drop: `glassfleck_wisp`; drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; +3 more (see content.json) |
| `sapwort_draught` | Sapwort Draught | beltable |  | common | 1 |  | craft: `craft_sapwort_draught`; drop: `glassfleck_wisp` |
| `fawnhide_belt` | Fawnhide Belt | equipment | belt | common | 4 | beltSlots +1, consumablePotencyPercent +10 | craft: `craft_fawnhide_belt` |
| `brookstone_pendant` | Brookstone Pendant | equipment | neck | rare | 6 | shieldStrengthPercent +10 | drop: `weirkeeper`; drop: `the_held_breath`; drop: `pale_coil`; drop: `frostgleam_naiad`; drop: `the_cold_below`; drop: `stillwater` |

### Cinderpeak Foothills (`cinderpeak_foothills`) — 8 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `copper_ore` | Copper Ore | material |  | common | 1 |  | gather: `cp_copper_seam`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; drop: `vent_warden`; +4 more (see content.json) |
| `proof_of_the_foothills` | Proof of the Foothills | key |  | rare | 1 |  | drop: `the_breathing_stone`; drop: `flintmaw` |
| `pyro_crystal` | Pyro Crystal | mote |  | uncommon | 1 |  | craft: `refine_pyro_crystal`; craft: `transmute_pyro_crystal`; drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; drop: `the_breathing_stone`; drop: `flintmaw`; +12 more (see content.json) |
| `pyro_dust` | Pyro Dust | mote |  | common | 1 |  | craft: `transmute_pyro_dust`; drop: `ashjaw_brute`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; +32 more (see content.json) |
| `pyro_shard` | Pyro Shard | mote |  | common | 1 |  | craft: `refine_pyro_shard`; craft: `transmute_pyro_shard`; drop: `ashjaw_brute`; drop: `flint_skink`; drop: `cinder_moth`; drop: `slagshell_tortoise`; drop: `ventworm`; drop: `slagheart`; +21 more (see content.json) |
| `tuskhide` | Tuskhide | material |  | common | 1 |  | drop: `ashjaw_brute`; drop: `slagshell_tortoise`; drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; +2 more (see content.json) |
| `cinder_loop` | Cinder Loop | equipment | ring | rare | 9 | critChance +5, critDamage +5 | drop: `slagheart`; drop: `vent_warden`; drop: `char_tusk`; drop: `the_emberqueen`; drop: `the_breathing_stone`; drop: `flintmaw` |
| `tuskhide_belt` | Tuskhide Belt | equipment | belt | common | 11 | beltSlots +2, consumablePotencyPercent +15 | craft: `craft_tuskhide_belt` |

### Thornmire (`thornmire`) — 13 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `amber` | Amber | material |  | uncommon | 1 |  | gather: `tm_amber_bog_oak`; drop: `leechcap`; drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; drop: `fenmother`; drop: `mirethroat`; +1 more (see content.json) |
| `bogflax_fibre` | Bogflax Fibre | material |  | common | 1 |  | gather: `tm_bogflax_retting`; drop: `mirewalker`; drop: `thirstvine`; drop: `reedback_lurker`; drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; +3 more (see content.json) |
| `fenroot` | Fenroot | material |  | common | 1 |  | gather: `tm_fenroot_hummock`; drop: `mirewalker`; drop: `leechcap`; drop: `bog_lantern`; drop: `old_wallow`; drop: `the_green_drowning`; drop: `wickerdrowned`; +3 more (see content.json) |
| `amber_band` | Amber Band | equipment | ring | common | 8 | maxHpBonus +4 | craft: `craft_amber_band` |
| `amber_drop` | Amber Drop | equipment | neck | common | 8 | healingReceivedPercent +3 | craft: `craft_amber_drop` |
| `bogflax_boots` | Bogflax Boots | equipment | boots | common | 10 | maxHpBonus +2 | craft: `craft_bogflax_boots` |
| `bogflax_gloves` | Bogflax Gloves | equipment | gloves | common | 10 | maxHpBonus +2 | craft: `craft_bogflax_gloves` |
| `bogflax_hood` | Bogflax Hood | equipment | hat | common | 10 | accuracyBonus +2 | craft: `craft_bogflax_hood` |
| `bogflax_leggings` | Bogflax Leggings | equipment | robeBottom | common | 10 | maxHpBonus +7 | craft: `craft_bogflax_leggings` |
| `bogflax_robe` | Bogflax Robe | equipment | robeTop | common | 10 | maxHpBonus +10 | craft: `craft_bogflax_robe` |
| `amber_pendant` | Amber Pendant | equipment | neck | common | 12 | healingReceivedPercent +5 | craft: `craft_amber_pendant` |
| `amber_ring` | Amber Ring | equipment | ring | common | 12 | maxHpBonus +6 | craft: `craft_amber_ring` |
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

### Old Quarry (`old_quarry`) — 11 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `bronze_ingot` | Bronze Ingot | material |  | common | 1 |  | craft: `craft_bronze_ingot` |
| `geo_crystal` | Geo Crystal | mote |  | uncommon | 1 |  | craft: `refine_geo_crystal`; craft: `transmute_geo_crystal`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; drop: `mountain_heart`; drop: `the_empty_course`; +13 more (see content.json) |
| `geo_dust` | Geo Dust | mote |  | common | 1 |  | craft: `transmute_geo_dust`; drop: `quarry_golem`; drop: `tailings_drudge`; drop: `chiselback`; drop: `gravelswarm`; drop: `plumbline_sentry`; drop: `obsidian_golem`; +33 more (see content.json) |
| `geo_shard` | Geo Shard | mote |  | common | 1 |  | craft: `refine_geo_shard`; craft: `transmute_geo_shard`; drop: `quarry_golem`; drop: `chiselback`; drop: `gravelswarm`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; +21 more (see content.json) |
| `hardtack` | Hardtack | consumable |  | common | 1 |  | drop: `quarry_golem`; drop: `tailings_drudge`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; +16 more (see content.json) |
| `quarry_jasper` | Quarry Jasper | material |  | uncommon | 1 |  | gather: `oq_jasper_face`; drop: `chiselback`; drop: `plumbline_sentry`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; +2 more (see content.json) |
| `tin_ore` | Tin Ore | material |  | common | 1 |  | gather: `oq_tin_seam`; drop: `quarry_golem`; drop: `tailings_drudge`; drop: `gravelswarm`; drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; +3 more (see content.json) |
| `jasper_pendant` | Jasper Pendant | equipment | neck | common | 17 | accuracyBonus +2 | craft: `craft_jasper_pendant` |
| `jasper_ring` | Jasper Ring | equipment | ring | common | 17 | maxHpBonus +7 | craft: `craft_jasper_ring` |
| `overseers_seal` | Overseer's Seal | equipment | ring | rare | 18 | deflectChance +12, deflectAmount +20 | drop: `obsidian_golem`; drop: `earth_titan`; drop: `deadweight`; drop: `the_overseer`; drop: `mountain_heart`; drop: `the_empty_course` |
| `the_given_weight` | The Given Weight | equipment | neck | epic | 19 | deflectChance +10, deflectAmount +25, maxHpBonus +30 | drop: `mountain_heart`; drop: `the_empty_course` |

### Stormcliff Coast (`stormcliff_coast`) — 13 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `electro_crystal` | Electro Crystal | mote |  | uncommon | 1 |  | craft: `refine_electro_crystal`; craft: `transmute_electro_crystal`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman`; drop: `storm_lord`; drop: `the_return_stroke`; +12 more (see content.json) |
| `electro_dust` | Electro Dust | mote |  | common | 1 |  | craft: `transmute_electro_dust`; drop: `stormcliff_tidecaller`; drop: `fulgurite_crawler`; drop: `sparkwing`; drop: `static_shoal`; drop: `groundling`; drop: `brinecharge`; +33 more (see content.json) |
| `electro_shard` | Electro Shard | mote |  | common | 1 |  | craft: `refine_electro_shard`; craft: `transmute_electro_shard`; drop: `fulgurite_crawler`; drop: `sparkwing`; drop: `static_shoal`; drop: `groundling`; drop: `brinecharge`; drop: `the_long_line`; +22 more (see content.json) |
| `saltwort` | Saltwort | material |  | common | 1 |  | gather: `sc_saltwort_ledge`; drop: `stormcliff_tidecaller`; drop: `sparkwing`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman`; +2 more (see content.json) |
| `saltwort_draught` | Saltwort Draught | beltable |  | common | 1 |  | craft: `craft_saltwort_draught`; drop: `fulgurite_crawler`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman` |
| `seawrack_fibre` | Seawrack Fibre | material |  | common | 1 |  | gather: `sc_wrackline`; drop: `fulgurite_crawler`; drop: `static_shoal`; drop: `groundling`; drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; +3 more (see content.json) |
| `seawrack_boots` | Seawrack Boots | equipment | boots | common | 16 | dodge +2, maxHpBonus +3 | craft: `craft_seawrack_boots` |
| `seawrack_gloves` | Seawrack Gloves | equipment | gloves | common | 16 | deflectChance +6, deflectAmount +15, maxHpBonus +3 | craft: `craft_seawrack_gloves` |
| `seawrack_hood` | Seawrack Hood | equipment | hat | common | 16 | accuracyBonus +3 | craft: `craft_seawrack_hood` |
| `seawrack_leggings` | Seawrack Leggings | equipment | robeBottom | common | 16 | maxHpBonus +10 | craft: `craft_seawrack_leggings` |
| `seawrack_robe` | Seawrack Robe | equipment | robeTop | common | 16 | maxHpBonus +15 | craft: `craft_seawrack_robe` |
| `fulgurite_pendant` | Fulgurite Pendant | equipment | neck | rare | 26 | critChance +8, critDamage +10 | drop: `brinecharge`; drop: `the_long_line`; drop: `voltgeist`; drop: `storm_shaman`; drop: `storm_lord`; drop: `the_return_stroke` |
| `uplight` | Uplight | equipment | mainHand | epic | 28 | accuracyBonus +4, critChance +12, critDamage +15, damagePerCast +6 | drop: `storm_lord`; drop: `the_return_stroke` |

### Windward Steppe (`windward_steppe`) — 15 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `aero_crystal` | Aero Crystal | mote |  | uncommon | 1 |  | craft: `refine_aero_crystal`; craft: `transmute_aero_crystal`; drop: `old_lean`; drop: `sky_titan`; drop: `gale_serpent`; drop: `wind_wraith`; drop: `the_unbroken_blow`; drop: `tempest_monarch`; +12 more (see content.json) |
| `aero_dust` | Aero Dust | mote |  | common | 1 |  | craft: `transmute_aero_dust`; drop: `steppe_harrier`; drop: `leanstone`; drop: `chaff`; drop: `tumblehusk`; drop: `kitewing`; drop: `old_lean`; +32 more (see content.json) |
| `aero_shard` | Aero Shard | mote |  | common | 1 |  | craft: `refine_aero_shard`; craft: `transmute_aero_shard`; drop: `steppe_harrier`; drop: `leanstone`; drop: `chaff`; drop: `kitewing`; drop: `old_lean`; drop: `sky_titan`; +19 more (see content.json) |
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
| `rimepelt_belt` | Rimepelt Belt | equipment | belt | common | 23 | beltSlots +3, consumablePotencyPercent +20 | craft: `craft_rimepelt_belt` |
| `rimebound_ring` | Rimebound Ring | equipment | ring | rare | 24 | dodge +3, deflectChance +10, deflectAmount +20 | drop: `the_last_cairn`; drop: `hoarking`; drop: `coldsnap`; drop: `the_certain_road`; drop: `the_white_corridor`; drop: `the_road_under` |
| `the_holdfast` | The Holdfast | equipment | neck | epic | 25 | shieldStrengthPercent +15 | drop: `the_white_corridor`; drop: `the_road_under` |

### Thunderspire Peaks (`thunderspire_peaks`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `hum_quartz` | Hum Quartz | material |  | uncommon | 1 |  | gather: `tp_humming_face`; drop: `humming_ore`; drop: `ionwake`; drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; +2 more (see content.json) |
| `iron_ingot` | Iron Ingot | material |  | common | 1 |  | craft: `craft_iron_ingot` |
| `iron_ore` | Iron Ore | material |  | common | 1 |  | gather: `tp_iron_seam`; drop: `flashcount`; drop: `ionwake`; drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; +2 more (see content.json) |
| `rowan_log` | Rowan Log | material |  | common | 1 |  | gather: `tp_rowan_stand`; drop: `stormcrest_roc`; drop: `updraft_wisp`; drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; +2 more (see content.json) |
| `rowan_knot` | Rowan Knot | equipment | offHand | common | 19 | accuracyBonus +6, critChance +2 | craft: `craft_rowan_knot` |
| `rowan_quarterstaff` | Rowan Quarterstaff | equipment | mainHand | common | 19 | accuracyBonus +8, critChance +3, critDamage +8, damagePerCharge +4 | craft: `craft_rowan_quarterstaff` |
| `rowan_wand` | Rowan Wand | equipment | mainHand | common | 19 | accuracyBonus +3, critChance +4, critDamage +6, damagePerCast +5 | craft: `craft_rowan_wand` |
| `countstone_pendant` | Countstone Pendant | equipment | neck | rare | 20 | critChance +10, critDamage +12 | drop: `crown_fire`; drop: `anvilhead`; drop: `thunder_roc`; drop: `the_shortening`; drop: `the_storm_that_passes`; drop: `the_strike_that_lands` |
| `groundfault_grips` | Groundfault Grips | equipment | gloves | epic | 22 | accuracyBonus +5, damagePerCast +4 | drop: `the_storm_that_passes`; drop: `the_strike_that_lands` |

### The Molten Deep (`the_molten_deep`) — 8 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `emberhide` | Emberhide | material |  | common | 1 |  | drop: `molten_warden`; drop: `crustwalker`; drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt`; +2 more (see content.json) |
| `firesalt` | Firesalt | material |  | common | 1 |  | gather: `md_firesalt_crust`; drop: `slagswimmer`; drop: `ember_vent`; drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt` |
| `obsidian` | Obsidian | material |  | uncommon | 1 |  | gather: `md_obsidian_flow`; drop: `ember_vent`; drop: `cooling_thing`; drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt`; +2 more (see content.json) |
| `emberhide_belt` | Emberhide Belt | equipment | belt | common | 27 | beltSlots +4, consumablePotencyPercent +20 | craft: `craft_emberhide_belt` |
| `obsidian_pendant` | Obsidian Pendant | equipment | neck | common | 27 | critDamage +8 | craft: `craft_obsidian_pendant` |
| `obsidian_ring` | Obsidian Ring | equipment | ring | common | 27 | maxHpBonus +10 | craft: `craft_obsidian_ring` |
| `firstmelt_loop` | Firstmelt Loop | equipment | ring | rare | 28 | critChance +5, critDamage +25 | drop: `the_floor`; drop: `magma_behemoth`; drop: `pyroclast`; drop: `firstmelt`; drop: `the_slow_stone`; drop: `efreet` |
| `the_long_cooling` | The Long Cooling | equipment | hat | epic | 29 | critDamage +15, deflectChance +12, deflectAmount +25, maxHpBonus +22 | drop: `the_slow_stone`; drop: `efreet` |

### The Kiln Desert (`the_kiln_desert`) — 13 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `glasswort` | Glasswort | material |  | common | 1 |  | gather: `kd_glasspan_flat`; drop: `shadeless`; drop: `sunstruck_pilgrim`; drop: `kiln_moth`; drop: `sun_templar`; drop: `prism_sentinel`; drop: `saltmarch_wraith`; +3 more (see content.json) |
| `glasswort_draught` | Glasswort Draught | beltable |  | common | 1 |  | craft: `craft_glasswort_draught`; drop: `undershine`; drop: `lowwater_thing`; drop: `sky_iron_husk` |
| `ironwood_log` | Ironwood Log | material |  | common | 1 |  | gather: `kd_ironwood_stand`; drop: `glasspan_crawler`; drop: `sun_templar`; drop: `prism_sentinel`; drop: `saltmarch_wraith`; drop: `the_shadeless_hour`; drop: `the_cold_shadow`; +1 more (see content.json) |
| `pilgrims_ration` | Pilgrim's Ration | consumable |  | common | 1 |  | drop: `ripplecut`; drop: `the_second_you`; drop: `herald_of_the_waxing`; drop: `stalker_of_the_new_moon`; drop: `the_waning_wraith`; drop: `armature`; +21 more (see content.json) |
| `solar_crystal` | Solar Crystal | mote |  | uncommon | 1 |  | craft: `refine_solar_crystal`; craft: `transmute_solar_crystal`; drop: `sun_templar`; drop: `prism_sentinel`; drop: `saltmarch_wraith`; drop: `the_shadeless_hour`; drop: `the_cold_shadow`; drop: `solar_deity`; +14 more (see content.json) |
| `solar_dust` | Solar Dust | mote |  | common | 1 |  | craft: `transmute_solar_dust`; drop: `shadeless`; drop: `sunstruck_pilgrim`; drop: `glasspan_crawler`; drop: `mirage`; drop: `kiln_moth`; drop: `sun_templar`; +34 more (see content.json) |
| `solar_essence` | Solar Essence | material |  | rare | 1 |  | drop: `the_cold_shadow`; drop: `solar_deity` |
| `solar_shard` | Solar Shard | mote |  | common | 1 |  | craft: `refine_solar_shard`; craft: `transmute_solar_shard`; drop: `shadeless`; drop: `glasspan_crawler`; drop: `mirage`; drop: `kiln_moth`; drop: `sun_templar`; drop: `prism_sentinel`; +23 more (see content.json) |
| `ironwood_knot` | Ironwood Knot | equipment | offHand | common | 30 | accuracyBonus +5, critChance +3 | craft: `craft_ironwood_knot` |
| `ironwood_quarterstaff` | Ironwood Quarterstaff | equipment | mainHand | common | 30 | accuracyBonus +9, critChance +4, critDamage +10, damagePerCharge +5 | craft: `craft_ironwood_quarterstaff` |
| `ironwood_wand` | Ironwood Wand | equipment | mainHand | common | 30 | accuracyBonus +4, critChance +5, critDamage +8, damagePerCast +6 | craft: `craft_ironwood_wand` |
| `the_shadeless_band` | The Shadeless Band | equipment | ring | rare | 32 | accuracyBonus +6, maxHpBonus +18 | drop: `sun_templar`; drop: `prism_sentinel`; drop: `saltmarch_wraith`; drop: `the_shadeless_hour`; drop: `the_cold_shadow`; drop: `solar_deity` |
| `the_hardest_edge` | The Hardest Edge | equipment | mainHand | epic | 34 | accuracyBonus +11, critChance +8, critDamage +18, damagePerCharge +7 | drop: `the_cold_shadow`; drop: `solar_deity` |

### The Mirrormere (`the_mirrormere`) — 16 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `bloodwood_log` | Bloodwood Log | material |  | common | 1 |  | gather: `mm_bloodwood_grove`; drop: `stillface`; drop: `ripplecut`; drop: `the_second_you`; drop: `herald_of_the_waxing`; drop: `stalker_of_the_new_moon`; drop: `the_waning_wraith`; +2 more (see content.json) |
| `lunar_crystal` | Lunar Crystal | mote |  | uncommon | 1 |  | craft: `refine_lunar_crystal`; craft: `transmute_lunar_crystal`; drop: `the_second_you`; drop: `herald_of_the_waxing`; drop: `stalker_of_the_new_moon`; drop: `the_waning_wraith`; drop: `the_moon_below`; drop: `luna_plena_the_full_moon`; +14 more (see content.json) |
| `lunar_dust` | Lunar Dust | mote |  | common | 1 |  | craft: `transmute_lunar_dust`; drop: `mirror_wraith`; drop: `stillface`; drop: `undershine`; drop: `ripplecut`; drop: `palefish_shoal`; drop: `the_second_you`; +35 more (see content.json) |
| `lunar_essence` | Lunar Essence | material |  | rare | 1 |  | drop: `the_moon_below`; drop: `luna_plena_the_full_moon` |
| `lunar_shard` | Lunar Shard | mote |  | common | 1 |  | craft: `refine_lunar_shard`; craft: `transmute_lunar_shard`; drop: `mirror_wraith`; drop: `stillface`; drop: `ripplecut`; drop: `palefish_shoal`; drop: `the_second_you`; drop: `herald_of_the_waxing`; +23 more (see content.json) |
| `mirrorflax` | Mirrorflax | material |  | common | 1 |  | gather: `mm_mirrorflax_shallows`; drop: `mirror_wraith`; drop: `undershine`; drop: `palefish_shoal`; drop: `the_second_you`; drop: `herald_of_the_waxing`; drop: `stalker_of_the_new_moon`; +3 more (see content.json) |
| `mirrorflax_boots` | Mirrorflax Boots | equipment | boots | common | 34 | dodge +4, maxHpBonus +5 | craft: `craft_mirrorflax_boots` |
| `mirrorflax_gloves` | Mirrorflax Gloves | equipment | gloves | common | 34 | deflectChance +10, deflectAmount +20, maxHpBonus +5 | craft: `craft_mirrorflax_gloves` |
| `mirrorflax_hood` | Mirrorflax Hood | equipment | hat | common | 34 | accuracyBonus +5 | craft: `craft_mirrorflax_hood` |
| `mirrorflax_leggings` | Mirrorflax Leggings | equipment | robeBottom | common | 34 | maxHpBonus +16 | craft: `craft_mirrorflax_leggings` |
| `mirrorflax_robe` | Mirrorflax Robe | equipment | robeTop | common | 34 | maxHpBonus +23 | craft: `craft_mirrorflax_robe` |
| `bloodwood_knot` | Bloodwood Knot | equipment | offHand | common | 35 | accuracyBonus +6, critChance +4 | craft: `craft_bloodwood_knot` |
| `bloodwood_quarterstaff` | Bloodwood Quarterstaff | equipment | mainHand | common | 35 | accuracyBonus +10, critChance +5, critDamage +12, damagePerCharge +6 | craft: `craft_bloodwood_quarterstaff` |
| `bloodwood_wand` | Bloodwood Wand | equipment | mainHand | common | 35 | accuracyBonus +4, critChance +6, critDamage +10, damagePerCast +7 | craft: `craft_bloodwood_wand` |
| `the_waning_charm` | The Waning Charm | equipment | ring | rare | 35 | dodge +9, maxHpBonus +16 | drop: `the_second_you`; drop: `herald_of_the_waxing`; drop: `stalker_of_the_new_moon`; drop: `the_waning_wraith`; drop: `the_moon_below`; drop: `luna_plena_the_full_moon` |
| `the_larger_reflection` | The Larger Reflection | equipment | robeTop | epic | 37 | dodge +6, maxHpBonus +40 | drop: `the_moon_below`; drop: `luna_plena_the_full_moon` |

### Starfall Basin (`starfall_basin`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `astral_crystal` | Astral Crystal | mote |  | uncommon | 1 |  | craft: `refine_astral_crystal`; craft: `transmute_astral_crystal`; drop: `sidereal_fault`; drop: `escapement`; drop: `long_division`; drop: `the_remainder`; drop: `the_calculation`; drop: `the_answer`; +12 more (see content.json) |
| `astral_dust` | Astral Dust | mote |  | common | 1 |  | craft: `transmute_astral_dust`; drop: `orrery_automaton`; drop: `gear_ghost`; drop: `armature`; drop: `arcflock`; drop: `errant_ring`; drop: `sidereal_fault`; +32 more (see content.json) |
| `astral_essence` | Astral Essence | material |  | rare | 1 |  | drop: `the_next_one`; drop: `what_landed` |
| `astral_shard` | Astral Shard | mote |  | common | 1 |  | craft: `refine_astral_shard`; craft: `transmute_astral_shard`; drop: `orrery_automaton`; drop: `gear_ghost`; drop: `arcflock`; drop: `sidereal_fault`; drop: `escapement`; drop: `long_division`; +21 more (see content.json) |
| `fallstone` | Fallstone | material |  | uncommon | 1 |  | gather: `sb_fallstone_crater`; drop: `crater_revenant`; drop: `sky_iron_husk`; drop: `fallpoint`; drop: `the_zodiac_ascendant`; drop: `constellation_warden`; drop: `rift_walker`; +3 more (see content.json) |
| `skyiron_ore` | Sky-Iron Ore | material |  | common | 1 |  | gather: `sb_skyiron_field`; drop: `sky_iron_husk`; drop: `scatterling`; drop: `cold_ejecta`; drop: `the_zodiac_ascendant`; drop: `constellation_warden`; drop: `rift_walker`; +3 more (see content.json) |
| `skysteel_ingot` | Skysteel Ingot | material |  | common | 1 |  | craft: `craft_skysteel_ingot` |
| `zodiac_pendant` | Zodiac Pendant | equipment | neck | rare | 37 | critChance +10, critDamage +12 | drop: `the_zodiac_ascendant`; drop: `constellation_warden`; drop: `rift_walker`; drop: `echo_of_the_between`; drop: `the_next_one`; drop: `what_landed` |
| `the_aimed_sky` | The Aimed Sky | equipment | neck | epic | 39 | critChance +10, critDamage +18, damagePerCast +9 | drop: `the_next_one`; drop: `what_landed` |

### Tidewrack Shoals (`tidewrack_shoals`) — 11 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `drownling_hide` | Drownling Hide | material |  | common | 1 |  | drop: `tidewrack_drowned`; drop: `gullbone_flock`; drop: `tidal_empress`; drop: `leviathan`; drop: `maelstrom_horror`; drop: `the_turning`; +2 more (see content.json) |
| `nacre` | Nacre | material |  | uncommon | 1 |  | gather: `ts_nacre_bed`; drop: `lowwater_thing`; drop: `tidal_empress`; drop: `leviathan`; drop: `maelstrom_horror`; drop: `the_turning`; drop: `kraken`; +1 more (see content.json) |
| `wrackcotton` | Wrackcotton | material |  | common | 1 |  | gather: `ts_wrackcotton_flat`; drop: `wrackcrab`; drop: `spindrift`; drop: `tidal_empress`; drop: `leviathan`; drop: `maelstrom_horror`; drop: `the_turning`; +2 more (see content.json) |
| `drownling_belt` | Drownling Belt | equipment | belt | common | 38 | beltSlots +5, consumablePotencyPercent +25 | craft: `craft_drownling_belt` |
| `the_turning_tide` | The Turning Tide | equipment | neck | rare | 38 | dodge +6, shieldStrengthPercent +12 | drop: `tidal_empress`; drop: `leviathan`; drop: `maelstrom_horror`; drop: `the_turning`; drop: `kraken`; drop: `the_undertow` |
| `wrackcotton_boots` | Wrackcotton Boots | equipment | boots | common | 39 | dodge +5, maxHpBonus +6 | craft: `craft_wrackcotton_boots` |
| `wrackcotton_gloves` | Wrackcotton Gloves | equipment | gloves | common | 39 | deflectChance +14, deflectAmount +24, maxHpBonus +7 | craft: `craft_wrackcotton_gloves` |
| `wrackcotton_hood` | Wrackcotton Hood | equipment | hat | common | 39 | accuracyBonus +5 | craft: `craft_wrackcotton_hood` |
| `wrackcotton_leggings` | Wrackcotton Leggings | equipment | robeBottom | common | 39 | maxHpBonus +22 | craft: `craft_wrackcotton_leggings` |
| `wrackcotton_robe` | Wrackcotton Robe | equipment | robeTop | common | 39 | maxHpBonus +32 | craft: `craft_wrackcotton_robe` |
| `lowwater_tread` | Lowwater Tread | equipment | boots | epic | 40 | dodge +7, maxHpBonus +24, shieldStrengthPercent +10 | drop: `kraken`; drop: `the_undertow` |

### The Sunless Reach (`the_sunless_reach`) — 11 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `duskcap` | Duskcap | material |  | common | 1 |  | gather: `sr_duskcap_shelf`; drop: `eclipse_herald`; drop: `shadowpitch_stalker`; drop: `solar_archon`; drop: `the_crest`; drop: `both_sided_thing`; drop: `duskmarch`; +2 more (see content.json) |
| `duskcap_tonic` | Duskcap Tonic | beltable |  | common | 1 |  | craft: `craft_duskcap_tonic`; drop: `crestline_warden` |
| `ebony_log` | Ebony Log | material |  | common | 1 |  | gather: `sr_ebony_stand`; drop: `nightglare`; drop: `coldlight_swarm`; drop: `solar_archon`; drop: `the_crest`; drop: `both_sided_thing`; drop: `duskmarch`; +2 more (see content.json) |
| `eclipse_opal` | Eclipse Opal | material |  | uncommon | 1 |  | gather: `sr_opal_seam`; drop: `crestline_warden`; drop: `solar_archon`; drop: `the_crest`; drop: `both_sided_thing`; drop: `duskmarch`; drop: `the_last_light`; +1 more (see content.json) |
| `opal_pendant` | Eclipse Opal Pendant | equipment | neck | common | 39 | accuracyBonus +3 | craft: `craft_opal_pendant` |
| `opal_ring` | Eclipse Opal Ring | equipment | ring | common | 39 | maxHpBonus +14 | craft: `craft_opal_ring` |
| `crestline_ring` | Crestline Ring | equipment | ring | rare | 40 | accuracyBonus +5, dodge +5, maxHpBonus +20 | drop: `solar_archon`; drop: `the_crest`; drop: `both_sided_thing`; drop: `duskmarch`; drop: `the_last_light`; drop: `the_first_dark` |
| `ebony_knot` | Ebony Knot | equipment | offHand | common | 40 | accuracyBonus +6, critChance +5 | craft: `craft_ebony_knot` |
| `ebony_quarterstaff` | Ebony Quarterstaff | equipment | mainHand | common | 40 | accuracyBonus +11, critChance +6, critDamage +14, damagePerCharge +7 | craft: `craft_ebony_quarterstaff` |
| `ebony_wand` | Ebony Wand | equipment | mainHand | common | 40 | accuracyBonus +5, critChance +7, critDamage +12, damagePerCast +8 | craft: `craft_ebony_wand` |
| `the_dividing_line` | The Dividing Line | equipment | mainHand | epic | 42 | accuracyBonus +6, critChance +10, critDamage +20, damagePerCast +12 | drop: `the_last_light`; drop: `the_first_dark` |

### The Shattered Orrery (`the_shattered_orrery`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `arcsalt` | Arcsalt | material |  | common | 1 |  | gather: `so_arcsalt_earthing`; drop: `gear_ghost`; drop: `arcflock`; drop: `sidereal_fault`; drop: `escapement`; drop: `long_division`; drop: `the_remainder`; +2 more (see content.json) |
| `arcsalt_draught` | Arcsalt Draught | beltable |  | common | 1 |  | craft: `craft_arcsalt_draught`; drop: `orrery_automaton`; drop: `glasswright` |
| `orrery_scrap` | Orrery Scrap | material |  | common | 1 |  | gather: `so_scrap_ring`; drop: `armature`; drop: `errant_ring`; drop: `sidereal_fault`; drop: `escapement`; drop: `long_division`; drop: `the_remainder`; +2 more (see content.json) |
| `sidereal_glass` | Sidereal Glass | material |  | uncommon | 1 |  | gather: `so_lens_shatter`; drop: `orrery_automaton`; drop: `sidereal_fault`; drop: `escapement`; drop: `long_division`; drop: `the_remainder`; drop: `the_calculation`; +1 more (see content.json) |
| `starbrass_ingot` | Starbrass Ingot | material |  | common | 1 |  | craft: `craft_starbrass_ingot` |
| `sidereal_pendant` | Sidereal Glass Pendant | equipment | neck | common | 42 | critChance +4 | craft: `craft_sidereal_pendant` |
| `sidereal_ring` | Sidereal Glass Ring | equipment | ring | common | 42 | maxHpBonus +16 | craft: `craft_sidereal_ring` |
| `sidereal_signet` | Sidereal Signet | equipment | ring | rare | 42 | accuracyBonus +4, critChance +10 | drop: `sidereal_fault`; drop: `escapement`; drop: `long_division`; drop: `the_remainder`; drop: `the_calculation`; drop: `the_answer` |
| `the_running_count` | The Running Count | equipment | gloves | epic | 44 | accuracyBonus +5, critChance +8, damagePerCast +10 | drop: `the_calculation`; drop: `the_answer` |

### Hallowmarch (`hallowmarch`) — 13 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `climbers_ration` | Climber's Ration | consumable |  | common | 1 |  | drop: `stratum_warden`; drop: `constellate`; drop: `fadelight`; drop: `deadreckoner`; drop: `stairhead`; drop: `chalkwraith`; +31 more (see content.json) |
| `goldenrood` | Goldenrood | material |  | common | 1 |  | gather: `hm_goldenrood_verge`; drop: `marker_sworn`; drop: `meltwater_choir`; drop: `pilgrims_remnant`; drop: `milestone`; drop: `vestal_warden`; drop: `seraph_judicant`; +3 more (see content.json) |
| `goldenrood_draught` | Goldenrood Draught | beltable |  | common | 1 |  | craft: `craft_goldenrood_draught`; drop: `corebiter`; drop: `umbral_devourer` |
| `sanctus_crystal` | Sanctus Crystal | mote |  | uncommon | 1 |  | craft: `refine_sanctus_crystal`; craft: `transmute_sanctus_crystal`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; drop: `what_was_consecrated`; drop: `what_did_not_leave_it_alone`; +13 more (see content.json) |
| `sanctus_dust` | Sanctus Dust | mote |  | common | 1 |  | craft: `transmute_sanctus_dust`; drop: `reliquary_keeper`; drop: `censer_wraith`; drop: `the_unleft`; drop: `bone_reliquary`; drop: `corridor_crawler`; drop: `antechoir`; +33 more (see content.json) |
| `sanctus_shard` | Sanctus Shard | mote |  | common | 1 |  | craft: `refine_sanctus_shard`; craft: `transmute_sanctus_shard`; drop: `reliquary_keeper`; drop: `bone_reliquary`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; +21 more (see content.json) |
| `spiritwood_log` | Spiritwood Log | material |  | common | 1 |  | gather: `hm_spiritwood_stand`; drop: `causeway_warden`; drop: `votive`; drop: `milestone`; drop: `vestal_warden`; drop: `seraph_judicant`; drop: `the_upkeep`; +2 more (see content.json) |
| `the_kept_third` | The Kept Third | key |  | rare | 1 |  | drop: `the_keeper_of_the_road`; drop: `the_hierophant_eternal` |
| `spiritwood_knot` | Spiritwood Knot | equipment | offHand | common | 45 | accuracyBonus +7, critChance +6 | craft: `craft_spiritwood_knot` |
| `spiritwood_quarterstaff` | Spiritwood Quarterstaff | equipment | mainHand | common | 45 | accuracyBonus +12, critChance +7, critDamage +16, damagePerCharge +8 | craft: `craft_spiritwood_quarterstaff` |
| `spiritwood_wand` | Spiritwood Wand | equipment | mainHand | common | 45 | accuracyBonus +5, critChance +8, critDamage +14, damagePerCast +9 | craft: `craft_spiritwood_wand` |
| `votive_pendant` | Votive Pendant | equipment | neck | rare | 47 | shieldStrengthPercent +18, healingReceivedPercent +12 | drop: `milestone`; drop: `vestal_warden`; drop: `seraph_judicant`; drop: `the_upkeep`; drop: `the_keeper_of_the_road`; drop: `the_hierophant_eternal` |
| `the_maintained_road` | The Maintained Road | equipment | neck | epic | 49 | maxHpBonus +45, shieldStrengthPercent +20, healingReceivedPercent +15 | drop: `the_keeper_of_the_road`; drop: `the_hierophant_eternal` |

### The Umbral Wastes (`the_umbral_wastes`) — 13 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `the_dark_third` | The Dark Third | key |  | rare | 1 |  | drop: `nightbringer`; drop: `what_was_thought_about` |
| `thoughtglass` | Thoughtglass | material |  | uncommon | 1 |  | gather: `uw_thoughtglass_face`; drop: `edgewalker`; drop: `thoughtform`; drop: `umbral_knight`; drop: `the_edge`; drop: `void_stalker`; drop: `eclipse_weaver`; +2 more (see content.json) |
| `umbra_crystal` | Umbra Crystal | mote |  | uncommon | 1 |  | craft: `refine_umbra_crystal`; craft: `transmute_umbra_crystal`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; drop: `what_was_consecrated`; drop: `what_did_not_leave_it_alone`; +14 more (see content.json) |
| `umbra_dust` | Umbra Dust | mote |  | common | 1 |  | craft: `transmute_umbra_dust`; drop: `reliquary_keeper`; drop: `censer_wraith`; drop: `the_unleft`; drop: `bone_reliquary`; drop: `corridor_crawler`; drop: `antechoir`; +35 more (see content.json) |
| `umbra_shard` | Umbra Shard | mote |  | common | 1 |  | craft: `refine_umbra_shard`; craft: `transmute_umbra_shard`; drop: `censer_wraith`; drop: `the_unleft`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; +23 more (see content.json) |
| `umbralweave` | Umbralweave | material |  | common | 1 |  | gather: `uw_umbralweave_drift`; gather: `uw_shoulder_drift`; drop: `umbral_devourer`; drop: `considered_ice`; drop: `nightspill`; drop: `umbral_knight`; drop: `the_edge`; drop: `void_stalker`; +3 more (see content.json) |
| `umbralweave_boots` | Umbralweave Boots | equipment | boots | common | 48 | dodge +6, maxHpBonus +8 | craft: `craft_umbralweave_boots` |
| `umbralweave_gloves` | Umbralweave Gloves | equipment | gloves | common | 48 | deflectChance +16, deflectAmount +22, maxHpBonus +9 | craft: `craft_umbralweave_gloves` |
| `umbralweave_hood` | Umbralweave Hood | equipment | hat | common | 48 | accuracyBonus +6 | craft: `craft_umbralweave_hood` |
| `umbralweave_leggings` | Umbralweave Leggings | equipment | robeBottom | common | 48 | maxHpBonus +29 | craft: `craft_umbralweave_leggings` |
| `umbralweave_robe` | Umbralweave Robe | equipment | robeTop | common | 48 | maxHpBonus +42 | craft: `craft_umbralweave_robe` |
| `the_considered_ring` | The Considered Ring | equipment | ring | rare | 49 | critChance +8, critDamage +34 | drop: `umbral_knight`; drop: `the_edge`; drop: `void_stalker`; drop: `eclipse_weaver`; drop: `nightbringer`; drop: `what_was_thought_about` |
| `the_deliberate_dark` | The Deliberate Dark | equipment | ring | epic | 51 | critChance +6, critDamage +28, maxHpBonus +20 | drop: `nightbringer`; drop: `what_was_thought_about` |

### The Reliquary Deep (`the_reliquary_deep`) — 12 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `censer_draught` | Censer Draught | beltable |  | common | 1 |  | craft: `craft_censer_draught`; drop: `corridor_crawler`; drop: `erratum` |
| `censer_resin` | Censer Resin | material |  | common | 1 |  | gather: `rd_censer_run`; drop: `censer_wraith`; drop: `the_unleft`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; +2 more (see content.json) |
| `reliquary_gold` | Reliquary Gold | material |  | uncommon | 1 |  | gather: `rd_gilt_fitting`; drop: `corridor_crawler`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; drop: `what_was_consecrated`; +1 more (see content.json) |
| `unleft_linen` | Unleft Linen | material |  | common | 1 |  | gather: `rd_altar_linen`; drop: `reliquary_keeper`; drop: `bone_reliquary`; drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; +2 more (see content.json) |
| `aetherglass_locket` | Aetherglass Locket | equipment | neck | common | 53 | maxHpBonus +45, shieldStrengthPercent +12, healingReceivedPercent +10 | craft: `craft_aetherglass_locket` |
| `unleft_boots` | Unleft Linen Boots | equipment | boots | common | 53 | dodge +7, maxHpBonus +10 | craft: `craft_unleft_boots` |
| `unleft_gloves` | Unleft Linen Gloves | equipment | gloves | common | 53 | deflectChance +18, deflectAmount +26, maxHpBonus +12 | craft: `craft_unleft_gloves` |
| `unleft_hood` | Unleft Linen Hood | equipment | hat | common | 53 | accuracyBonus +6 | craft: `craft_unleft_hood` |
| `unleft_leggings` | Unleft Linen Leggings | equipment | robeBottom | common | 53 | maxHpBonus +38 | craft: `craft_unleft_leggings` |
| `unleft_robe` | Unleft Linen Robe | equipment | robeTop | common | 53 | maxHpBonus +55 | craft: `craft_unleft_robe` |
| `censer_pendant` | Censer Pendant | equipment | neck | rare | 54 | critDamage +20, shieldStrengthPercent +15, healingReceivedPercent +15 | drop: `antechoir`; drop: `reliquary_colossus`; drop: `the_second_hand`; drop: `warm_middle`; drop: `what_was_consecrated`; drop: `what_did_not_leave_it_alone` |
| `the_unconsecrated` | The Unconsecrated | equipment | boots | epic | 56 | dodge +6, maxHpBonus +32, healingReceivedPercent +10 | drop: `what_was_consecrated`; drop: `what_did_not_leave_it_alone` |

### The Sealed Garden (`the_sealed_garden`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `orchard_amber` | Orchard Amber | material |  | uncommon | 1 |  | gather: `sg_amber_bough`; drop: `windfall`; drop: `the_last_gardener`; drop: `root_matriarch`; drop: `cherub_of_the_turning_blade`; drop: `the_kept_vow`; drop: `guardian_of_the_world_tree`; +1 more (see content.json) |
| `thornpenitent_hide` | Thornpenitent Hide | material |  | common | 1 |  | drop: `whisperling`; drop: `thornpenitent`; drop: `the_last_gardener`; drop: `root_matriarch`; drop: `cherub_of_the_turning_blade`; drop: `the_kept_vow`; +2 more (see content.json) |
| `worldroot` | Worldroot | material |  | common | 1 |  | gather: `sg_worldroot_undercut`; gather: `sg_wallside_root`; drop: `orchard_warden`; drop: `chorister_vine`; drop: `the_last_gardener`; drop: `root_matriarch`; drop: `cherub_of_the_turning_blade`; drop: `the_kept_vow`; +2 more (see content.json) |
| `worldroot_tonic` | Worldroot Tonic | beltable |  | common | 1 |  | craft: `craft_worldroot_tonic`; drop: `windfall` |
| `eclipse_signet` | Eclipse Opal Signet | equipment | ring | common | 50 | accuracyBonus +3, dodge +3, critChance +6, critDamage +10 | craft: `craft_eclipse_signet` |
| `the_gardeners_loop` | The Gardener's Loop | equipment | ring | rare | 51 | maxHpBonus +25, healingReceivedPercent +18, regrowPercent +2 | drop: `the_last_gardener`; drop: `root_matriarch`; drop: `cherub_of_the_turning_blade`; drop: `the_kept_vow`; drop: `guardian_of_the_world_tree`; drop: `the_serpent_in_the_branches` |
| `penitent_belt` | Thornpenitent Belt | equipment | belt | common | 52 | beltSlots +8, consumablePotencyPercent +30 | craft: `craft_penitent_belt` |
| `the_season_at_once` | The Season At Once | equipment | robeTop | epic | 53 | maxHpBonus +60, healingReceivedPercent +15, regrowPercent +3 | drop: `guardian_of_the_world_tree`; drop: `the_serpent_in_the_branches` |
| `orchard_loop` | Orchard Amber Loop | equipment | ring | common | 54 | maxHpBonus +25, healingReceivedPercent +15, regrowPercent +1 | craft: `craft_orchard_loop` |

### The Glass Archive (`the_glass_archive`) — 11 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `aetherglass` | Aetherglass | material |  | uncommon | 1 |  | gather: `ga_roof_spoil`; gather: `ga_noon_shelf`; drop: `glasswright`; drop: `the_last_reader`; drop: `aperture`; drop: `burnt_index`; drop: `the_marginalia`; drop: `what_was_written`; +1 more (see content.json) |
| `arcane_crystal` | Arcane Crystal | mote |  | uncommon | 1 |  | craft: `refine_arcane_crystal`; craft: `transmute_arcane_crystal`; drop: `the_last_reader`; drop: `aperture`; drop: `burnt_index`; drop: `the_marginalia`; drop: `what_was_written`; drop: `what_is_left_of_it`; +13 more (see content.json) |
| `arcane_dust` | Arcane Dust | mote |  | common | 1 |  | craft: `transmute_arcane_dust`; drop: `glasswright`; drop: `noonmark`; drop: `palimpsest`; drop: `readerless`; drop: `lensfly`; drop: `the_last_reader`; +33 more (see content.json) |
| `arcane_shard` | Arcane Shard | mote |  | common | 1 |  | craft: `refine_arcane_shard`; craft: `transmute_arcane_shard`; drop: `palimpsest`; drop: `readerless`; drop: `the_last_reader`; drop: `aperture`; drop: `burnt_index`; drop: `the_marginalia`; +21 more (see content.json) |
| `celestial_totem` | Celestial Totem | key |  | rare | 1 |  | craft: `craft_celestial_totem` |
| `palimpsest_vellum` | Palimpsest Vellum | material |  | common | 1 |  | drop: `palimpsest`; drop: `readerless`; drop: `the_last_reader`; drop: `aperture`; drop: `burnt_index`; drop: `the_marginalia`; +2 more (see content.json) |
| `sunbleach_lichen` | Sunbleach Lichen | material |  | common | 1 |  | gather: `ga_shadeline_lichen`; drop: `noonmark`; drop: `lensfly`; drop: `the_last_reader`; drop: `aperture`; drop: `burnt_index`; drop: `the_marginalia`; +2 more (see content.json) |
| `sunbleach_tonic` | Sunbleach Tonic | beltable |  | common | 1 |  | craft: `craft_sunbleach_tonic`; drop: `palimpsest`; drop: `readerless` |
| `palimpsest_belt` | Palimpsest Belt | equipment | belt | common | 45 | beltSlots +6, consumablePotencyPercent +25 | craft: `craft_palimpsest_belt` |
| `the_last_reading` | The Last Reading | equipment | neck | rare | 45 | accuracyBonus +5, critDamage +20, maxHpBonus +30 | drop: `the_last_reader`; drop: `aperture`; drop: `burnt_index`; drop: `the_marginalia`; drop: `what_was_written`; drop: `what_is_left_of_it` |
| `the_noon_hour` | The Noon Hour | equipment | hat | epic | 47 | critDamage +20, deflectChance +12, deflectAmount +14, maxHpBonus +55 | drop: `what_was_written`; drop: `what_is_left_of_it` |

### The Buried Sky (`the_buried_sky`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `corebiter_hide` | Corebiter Hide | material |  | common | 1 |  | drop: `fadelight`; drop: `deadreckoner`; drop: `stonefall_herald`; drop: `bedrock_colossus`; drop: `nadir`; drop: `the_long_count`; +2 more (see content.json) |
| `deepsteel_ingot` | Deepsteel Ingot | material |  | common | 1 |  | craft: `craft_deepsteel_ingot` |
| `deepstratum_ore` | Deepstratum Ore | material |  | common | 1 |  | gather: `bs_stratum_seam`; gather: `hm_causeway_quarry`; drop: `stratum_warden`; drop: `constellate`; drop: `stonefall_herald`; drop: `bedrock_colossus`; drop: `nadir`; drop: `the_long_count`; +2 more (see content.json) |
| `nadir_garnet` | Nadir Garnet | material |  | uncommon | 1 |  | gather: `bs_nadir_pocket`; drop: `corebiter`; drop: `stonefall_herald`; drop: `bedrock_colossus`; drop: `nadir`; drop: `the_long_count`; drop: `the_overburden`; +1 more (see content.json) |
| `everice_band` | Everice Band | equipment | ring | common | 45 | dodge +3, maxHpBonus +15, shieldStrengthPercent +12 | craft: `craft_everice_band` |
| `nacre_pendant` | Nacre Pendant | equipment | neck | common | 46 | dodge +6, maxHpBonus +25, shieldStrengthPercent +8 | craft: `craft_nacre_pendant` |
| `corebiter_belt` | Corebiter Belt | equipment | belt | common | 48 | beltSlots +7, consumablePotencyPercent +30 | craft: `craft_corebiter_belt` |
| `stonefall_signet` | Stonefall Signet | equipment | ring | rare | 48 | critChance +6, deflectChance +18, maxHpBonus +22 | drop: `stonefall_herald`; drop: `bedrock_colossus`; drop: `nadir`; drop: `the_long_count`; drop: `the_overburden`; drop: `the_buried_constellation` |
| `bedrock_greaves` | Bedrock Greaves | equipment | robeBottom | epic | 50 | deflectChance +10, deflectAmount +10, maxHpBonus +45 | drop: `the_overburden`; drop: `the_buried_constellation` |

### The Collapsed Academy (`the_collapsed_academy`) — 9 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `aethersteel_ingot` | Aethersteel Ingot | material |  | common | 1 |  | craft: `craft_aethersteel_ingot` |
| `aetherwood_log` | Aetherwood Log | material |  | common | 1 |  | gather: `ca_aetherwood_stair`; drop: `stairhead`; drop: `chalkwraith`; drop: `the_fourth_item`; drop: `mana_golem`; drop: `arcane_chimera`; drop: `spell_weaver`; +2 more (see content.json) |
| `mana_slag` | Mana Slag | material |  | common | 1 |  | gather: `ca_slag_vault`; drop: `unfinished_scholar`; drop: `marginal_note`; drop: `emeritus`; drop: `the_fourth_item`; drop: `mana_golem`; drop: `arcane_chimera`; +3 more (see content.json) |
| `the_written_third` | The Written Third | key |  | rare | 1 |  | drop: `the_archmage`; drop: `the_last_three_items` |
| `aetherwood_knot` | Aetherwood Knot | equipment | offHand | common | 50 | accuracyBonus +7, critChance +7 | craft: `craft_aetherwood_knot` |
| `aetherwood_quarterstaff` | Aetherwood Quarterstaff | equipment | mainHand | common | 50 | accuracyBonus +12, critChance +8, critDamage +18, damagePerCharge +9 | craft: `craft_aetherwood_quarterstaff` |
| `aetherwood_wand` | Aetherwood Wand | equipment | mainHand | common | 50 | accuracyBonus +5, critChance +9, critDamage +16, damagePerCast +10 | craft: `craft_aetherwood_wand` |
| `chalkline_signet` | Chalkline Signet | equipment | ring | rare | 52 | critChance +8, deflectChance +18, deflectAmount +8 | drop: `the_fourth_item`; drop: `mana_golem`; drop: `arcane_chimera`; drop: `spell_weaver`; drop: `the_archmage`; drop: `the_last_three_items` |
| `the_unbuilt_stair` | The Unbuilt Stair | equipment | mainHand | epic | 54 | accuracyBonus +13, critChance +8, critDamage +16, damagePerCharge +10 | drop: `the_archmage`; drop: `the_last_three_items` |

### The Unwritten Library (`the_unwritten_library`) — 7 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `blankspine_vellum` | Blankspine Vellum | material |  | common | 1 |  | drop: `the_dictating_hand`; drop: `ink_drinker`; drop: `the_index`; drop: `colophon`; drop: `redaction`; drop: `the_amanuensis`; +2 more (see content.json) |
| `colophon_stone` | Colophon Stone | material |  | uncommon | 1 |  | gather: `ul_colophon_shelf`; drop: `erratum`; drop: `the_index`; drop: `colophon`; drop: `redaction`; drop: `the_amanuensis`; drop: `the_record`; +1 more (see content.json) |
| `nightink` | Nightink | material |  | common | 1 |  | gather: `ul_nightink_well`; drop: `blankspine`; drop: `footnote`; drop: `the_index`; drop: `colophon`; drop: `redaction`; drop: `the_amanuensis`; +2 more (see content.json) |
| `nightink_draught` | Nightink Draught | beltable |  | common | 1 |  | craft: `craft_nightink_draught`; drop: `the_dictating_hand`; drop: `ink_drinker`; drop: `the_held_door`; drop: `ashlight`; drop: `the_kept_watch`; drop: `nightcurrent`; +5 more (see content.json) |
| `blankspine_belt` | Blankspine Belt | equipment | belt | common | 56 | beltSlots +9, consumablePotencyPercent +30 | craft: `craft_blankspine_belt` |
| `colophon_signet` | Colophon Signet | equipment | ring | rare | 56 | accuracyBonus +3, critChance +12, critDamage +30 | drop: `the_index`; drop: `colophon`; drop: `redaction`; drop: `the_amanuensis`; drop: `the_record`; drop: `the_author` |
| `the_open_colophon` | The Open Colophon | equipment | offHand | epic | 58 | accuracyBonus +9, critChance +8, damagePerCast +12 | drop: `the_record`; drop: `the_author` |

### The Eclipsed Citadel (`the_eclipsed_citadel`) — 7 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `corona_pearl` | Corona Pearl | material |  | uncommon | 1 |  | drop: `the_held_door`; drop: `ashlight`; drop: `the_kept_watch`; drop: `nightcurrent`; drop: `the_last_applicant`; drop: `the_basin`; +5 more (see content.json) |
| `eclipse_iron` | Eclipse Iron | material |  | uncommon | 1 |  | drop: `the_held_door`; drop: `ashlight`; drop: `the_kept_watch`; drop: `nightcurrent`; drop: `the_last_applicant`; drop: `the_basin`; +5 more (see content.json) |
| `corona_torc` | Corona Pearl Torc | equipment | neck | common | 58 | accuracyBonus +3, critChance +5, maxHpBonus +45 | craft: `craft_corona_torc` |
| `the_eclipsed_band` | The Eclipsed Band | equipment | ring | rare | 58 | dodge +6, critChance +8, maxHpBonus +60 | drop: `the_basin`; drop: `the_range`; drop: `the_shelf`; drop: `the_climb`; drop: `totality`; drop: `procarius_the_eclipsed` |
| `eclipse_ring` | Eclipse Iron Ring | equipment | ring | common | 60 | critChance +6, critDamage +12, damagePerCast +7 | craft: `craft_eclipse_ring` |
| `the_corona` | The Corona | equipment | hat | epic | 60 | deflectChance +16, deflectAmount +14, maxHpBonus +70, shieldStrengthPercent +12 | drop: `totality`; drop: `procarius_the_eclipsed` |
| `the_last_thing_in_the_way` | The Last Thing in the Way | equipment | gloves | epic | 60 | accuracyBonus +6, critChance +10, critDamage +10, damagePerCast +14 | drop: `totality`; drop: `procarius_the_eclipsed` |

### Made, never found (`refined`) — 24 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `aqua_core` | Aqua Core | mote |  | rare | 1 |  | craft: `refine_aqua_core` |
| `aqua_heart` | Aqua Heart | mote |  | epic | 1 |  | craft: `refine_aqua_heart` |
| `pyro_core` | Pyro Core | mote |  | rare | 1 |  | craft: `refine_pyro_core` |
| `pyro_heart` | Pyro Heart | mote |  | epic | 1 |  | craft: `refine_pyro_heart` |
| `flora_core` | Flora Core | mote |  | rare | 1 |  | craft: `refine_flora_core` |
| `flora_heart` | Flora Heart | mote |  | epic | 1 |  | craft: `refine_flora_heart` |
| `electro_core` | Electro Core | mote |  | rare | 1 |  | craft: `refine_electro_core` |
| `electro_heart` | Electro Heart | mote |  | epic | 1 |  | craft: `refine_electro_heart` |
| `aero_core` | Aero Core | mote |  | rare | 1 |  | craft: `refine_aero_core` |
| `aero_heart` | Aero Heart | mote |  | epic | 1 |  | craft: `refine_aero_heart` |
| `geo_core` | Geo Core | mote |  | rare | 1 |  | craft: `refine_geo_core` |
| `geo_heart` | Geo Heart | mote |  | epic | 1 |  | craft: `refine_geo_heart` |
| `solar_core` | Solar Core | mote |  | rare | 1 |  | craft: `refine_solar_core` |
| `solar_heart` | Solar Heart | mote |  | epic | 1 |  | craft: `refine_solar_heart` |
| `lunar_core` | Lunar Core | mote |  | rare | 1 |  | craft: `refine_lunar_core` |
| `lunar_heart` | Lunar Heart | mote |  | epic | 1 |  | craft: `refine_lunar_heart` |
| `astral_core` | Astral Core | mote |  | rare | 1 |  | craft: `refine_astral_core` |
| `astral_heart` | Astral Heart | mote |  | epic | 1 |  | craft: `refine_astral_heart` |
| `sanctus_core` | Sanctus Core | mote |  | rare | 1 |  | craft: `refine_sanctus_core` |
| `sanctus_heart` | Sanctus Heart | mote |  | epic | 1 |  | craft: `refine_sanctus_heart` |
| `umbra_core` | Umbra Core | mote |  | rare | 1 |  | craft: `refine_umbra_core` |
| `umbra_heart` | Umbra Heart | mote |  | epic | 1 |  | craft: `refine_umbra_heart` |
| `arcane_core` | Arcane Core | mote |  | rare | 1 |  | craft: `refine_arcane_core` |
| `arcane_heart` | Arcane Heart | mote |  | epic | 1 |  | craft: `refine_arcane_heart` |

### Made, never found (`gems`) — 36 items

| Id | Name | Kind | Slot | Rarity | Equip Lv | Stats | Obtained |
|---|---|---|---|---|---|---|---|
| `gem_aqua_lesser` | Lesser Aqua Gem | gem |  | uncommon | 1 | shieldStrengthPercent +4 | craft: `cut_aqua_lesser` |
| `gem_aqua_standard` | Standard Aqua Gem | gem |  | rare | 1 | shieldStrengthPercent +8 | craft: `cut_aqua_standard` |
| `gem_aqua_greater` | Greater Aqua Gem | gem |  | epic | 1 | shieldStrengthPercent +9 | craft: `cut_aqua_greater` |
| `gem_pyro_lesser` | Lesser Pyro Gem | gem |  | uncommon | 1 | critDamage +4 | craft: `cut_pyro_lesser` |
| `gem_pyro_standard` | Standard Pyro Gem | gem |  | rare | 1 | critDamage +8 | craft: `cut_pyro_standard` |
| `gem_pyro_greater` | Greater Pyro Gem | gem |  | epic | 1 | critDamage +9 | craft: `cut_pyro_greater` |
| `gem_flora_lesser` | Lesser Flora Gem | gem |  | uncommon | 1 | healingReceivedPercent +4 | craft: `cut_flora_lesser` |
| `gem_flora_standard` | Standard Flora Gem | gem |  | rare | 1 | healingReceivedPercent +8 | craft: `cut_flora_standard` |
| `gem_flora_greater` | Greater Flora Gem | gem |  | epic | 1 | healingReceivedPercent +9 | craft: `cut_flora_greater` |
| `gem_electro_lesser` | Lesser Electro Gem | gem |  | uncommon | 1 | critChance +1 | craft: `cut_electro_lesser` |
| `gem_electro_standard` | Standard Electro Gem | gem |  | rare | 1 | critChance +2 | craft: `cut_electro_standard` |
| `gem_electro_greater` | Greater Electro Gem | gem |  | epic | 1 | critChance +3 | craft: `cut_electro_greater` |
| `gem_aero_lesser` | Lesser Aero Gem | gem |  | uncommon | 1 | dodge +1 | craft: `cut_aero_lesser` |
| `gem_aero_standard` | Standard Aero Gem | gem |  | rare | 1 | dodge +1 | craft: `cut_aero_standard` |
| `gem_aero_greater` | Greater Aero Gem | gem |  | epic | 1 | dodge +2 | craft: `cut_aero_greater` |
| `gem_geo_lesser` | Lesser Geo Gem | gem |  | uncommon | 1 | deflectChance +3 | craft: `cut_geo_lesser` |
| `gem_geo_standard` | Standard Geo Gem | gem |  | rare | 1 | deflectChance +6 | craft: `cut_geo_standard` |
| `gem_geo_greater` | Greater Geo Gem | gem |  | epic | 1 | deflectChance +7 | craft: `cut_geo_greater` |
| `gem_solar_lesser` | Lesser Solar Gem | gem |  | uncommon | 1 | accuracyBonus +3 | craft: `cut_solar_lesser` |
| `gem_solar_standard` | Standard Solar Gem | gem |  | rare | 1 | accuracyBonus +6 | craft: `cut_solar_standard` |
| `gem_solar_greater` | Greater Solar Gem | gem |  | epic | 1 | accuracyBonus +7 | craft: `cut_solar_greater` |
| `gem_lunar_lesser` | Lesser Lunar Gem | gem |  | uncommon | 1 | dodge +1 | craft: `cut_lunar_lesser` |
| `gem_lunar_standard` | Standard Lunar Gem | gem |  | rare | 1 | dodge +1 | craft: `cut_lunar_standard` |
| `gem_lunar_greater` | Greater Lunar Gem | gem |  | epic | 1 | dodge +2 | craft: `cut_lunar_greater` |
| `gem_astral_lesser` | Lesser Astral Gem | gem |  | uncommon | 1 | critChance +1 | craft: `cut_astral_lesser` |
| `gem_astral_standard` | Standard Astral Gem | gem |  | rare | 1 | critChance +2 | craft: `cut_astral_standard` |
| `gem_astral_greater` | Greater Astral Gem | gem |  | epic | 1 | critChance +3 | craft: `cut_astral_greater` |
| `gem_sanctus_lesser` | Lesser Sanctus Gem | gem |  | uncommon | 1 | shieldStrengthPercent +2, healingReceivedPercent +2 | craft: `cut_sanctus_lesser` |
| `gem_sanctus_standard` | Standard Sanctus Gem | gem |  | rare | 1 | shieldStrengthPercent +4, healingReceivedPercent +4 | craft: `cut_sanctus_standard` |
| `gem_sanctus_greater` | Greater Sanctus Gem | gem |  | epic | 1 | shieldStrengthPercent +5, healingReceivedPercent +5 | craft: `cut_sanctus_greater` |
| `gem_umbra_lesser` | Lesser Umbra Gem | gem |  | uncommon | 1 | critDamage +4 | craft: `cut_umbra_lesser` |
| `gem_umbra_standard` | Standard Umbra Gem | gem |  | rare | 1 | critDamage +8 | craft: `cut_umbra_standard` |
| `gem_umbra_greater` | Greater Umbra Gem | gem |  | epic | 1 | critDamage +9 | craft: `cut_umbra_greater` |
| `gem_arcane_lesser` | Lesser Arcane Gem | gem |  | uncommon | 1 | deflectChance +3 | craft: `cut_arcane_lesser` |
| `gem_arcane_standard` | Standard Arcane Gem | gem |  | rare | 1 | deflectChance +6 | craft: `cut_arcane_standard` |
| `gem_arcane_greater` | Greater Arcane Gem | gem |  | epic | 1 | deflectChance +7 | craft: `cut_arcane_greater` |


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
| `heartwood` | Heartwood | Boss | Juggernaut | flora | 1-5 | ×2.8 | ×1.4 | Oak Log, Bindweed Fibre, Sporecap Mantle, Heartwood Staff |
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
| `the_cold_below` | The Cold Below | Boss | Juggernaut | aqua | 3-8 | ×2.8 | ×1.4 | Fawnhide, Sapwort, Brookstone Pendant, Forager's Ration |

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
| `the_breathing_stone` | The Breathing Stone | Boss | Juggernaut | pyro | 6-11 | ×2.8 | ×1.4 | Tuskhide, Copper Ore, Cinder Loop, Pyro Shard, Pyro Dust |

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
| `mirethroat` | Mirethroat | Boss | Juggernaut | flora/aqua | 8-13 | ×2.8 | ×1.4 | Bogflax Fibre, Fenroot, Wickerbound Ring, Amber |
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
| `mountain_heart` | Mountain Heart | Boss | Juggernaut | geo | 15-19 | ×2.8 | ×1.4 | Tin Ore, Quarry Jasper, Overseer's Seal, The Given Weight |
| `the_empty_course` | The Empty Course | Boss | Tyrant | geo | 15-19 | ×2.6 | ×1.7 | Tin Ore, Quarry Jasper, Overseer's Seal, The Given Weight |

### Stormcliff Coast (`stormcliff_coast`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `fulgurite_crawler` | Fulgurite Crawler | Wild | Sentinel | electro | 23-28 | ×1.25 | ×0.7 | Seawrack Fibre, Electro Shard, Electro Dust, Saltwort Draught |
| `groundling` | Groundling | Wild | Skirmisher | electro | 23-28 | ×0.7 | ×1.15 | Seawrack Fibre, Electro Shard, Electro Dust, Hardtack |
| `sparkwing` | Sparkwing | Wild | Glasswing | electro | 23-28 | ×0.5 | ×1.7 | Saltwort, Electro Shard, Electro Dust |
| `static_shoal` | Static Shoal | Wild | Lasher | electro | 23-28 | ×0.85 | ×1.0 | Seawrack Fibre, Electro Shard, Electro Dust |
| `stormcliff_tidecaller` | Stormcliff Tidecaller | Wild | Adept | electro | 23-28 | ×1.0 | ×0.9 | Saltwort, Hardtack |
| `brinecharge` | Brinecharge | Mini-boss | Champion | electro | 23-28 | ×1.7 | ×1.2 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `storm_shaman` | Storm Shaman | Mini-boss | Hexer | electro | 23-28 | ×1.6 | ×0.75 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `the_long_line` | The Long Line | Mini-boss | Redoubt | electro | 23-28 | ×2.2 | ×0.85 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `voltgeist` | Voltgeist | Mini-boss | Executioner | electro | 23-28 | ×1.2 | ×1.9 | Seawrack Fibre, Saltwort, Saltwort Draught, Fulgurite Pendant |
| `storm_lord` | Storm Lord | Boss | Tyrant | electro | 23-28 | ×2.6 | ×1.7 | Seawrack Fibre, Saltwort, Fulgurite Pendant, Uplight |
| `the_return_stroke` | The Return Stroke | Boss | Aspect | electro | 23-28 | ×2.6 | ×1.5 | Seawrack Fibre, Saltwort, Fulgurite Pendant, Uplight |

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
| `the_unbroken_blow` | The Unbroken Blow | Boss | Juggernaut | aero | 19-24 | ×2.8 | ×1.4 | Yew Log, Tussock Flax, Leanstone Charm, The Long Lean |

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
| `the_white_corridor` | The White Corridor | Boss | Juggernaut | aqua/aero | 21-26 | ×2.8 | ×1.4 | Rimepelt, Hoarlichen, Everice, Rimebound Ring, The Holdfast |

### Thunderspire Peaks (`thunderspire_peaks`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `flashcount` | Flashcount | Wild | Lasher | electro | 17-22 | ×0.85 | ×1.0 | Iron Ore, Electro Shard, Electro Dust |
| `humming_ore` | Humming Ore | Wild | Sentinel | electro | 17-22 | ×1.25 | ×0.7 | Hum Quartz, Electro Shard, Electro Dust, Hardtack |
| `ionwake` | Ionwake | Wild | Adept | electro/aero | 17-22 | ×1.0 | ×0.9 | Iron Ore, Hum Quartz |
| `stormcrest_roc` | Stormcrest Roc | Wild | Bruiser | aero | 17-22 | ×1.15 | ×1.1 | Rowan Log, Electro Shard, Electro Dust, Hardtack |
| `updraft_wisp` | Updraft Wisp | Wild | Glasswing | aero | 17-22 | ×0.5 | ×1.7 | Rowan Log, Aero Shard, Aero Dust |
| `anvilhead` | Anvilhead | Mini-boss | Redoubt | electro/aero | 17-22 | ×2.2 | ×0.85 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `crown_fire` | Crown Fire | Mini-boss | Champion | electro | 17-22 | ×1.7 | ×1.2 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `the_shortening` | The Shortening | Mini-boss | Hexer | electro | 17-22 | ×1.6 | ×0.75 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `thunder_roc` | Thunder Roc | Mini-boss | Executioner | electro | 17-22 | ×1.2 | ×1.9 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant |
| `the_storm_that_passes` | The Storm That Passes | Boss | Juggernaut | electro/aero | 17-22 | ×2.8 | ×1.4 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant, Groundfault Grips |
| `the_strike_that_lands` | The Strike That Lands | Boss | Aspect | electro | 17-22 | ×2.6 | ×1.5 | Iron Ore, Rowan Log, Hum Quartz, Countstone Pendant, Groundfault Grips |

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
| `the_slow_stone` | The Slow Stone | Boss | Juggernaut | geo | 25-29 | ×2.8 | ×1.4 | Emberhide, Obsidian, Firstmelt Loop, The Long Cooling |

### The Kiln Desert (`the_kiln_desert`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `glasspan_crawler` | Glasspan Crawler | Wild | Bruiser | solar | 30-34 | ×1.15 | ×1.1 | Ironwood Log, Solar Shard, Solar Dust, Pilgrim's Ration |
| `kiln_moth` | Kiln Moth | Wild | Lasher | solar | 30-34 | ×0.85 | ×1.0 | Glasswort, Solar Shard, Solar Dust |
| `mirage` | Mirage | Wild | Glasswing | solar | 30-34 | ×0.5 | ×1.7 | Solar Shard, Solar Dust |
| `shadeless` | Shadeless | Wild | Adept | solar | 30-34 | ×1.0 | ×0.9 | Glasswort, Solar Shard, Solar Dust |
| `sunstruck_pilgrim` | Sunstruck Pilgrim | Wild | Blighter | solar | 30-34 | ×1.0 | ×0.6 | Glasswort, Pilgrim's Ration |
| `prism_sentinel` | Prism Sentinel | Mini-boss | Redoubt | solar | 30-34 | ×2.2 | ×0.85 | Ironwood Log, Glasswort, Pilgrim's Ration, The Shadeless Band |
| `saltmarch_wraith` | Saltmarch Wraith | Mini-boss | Executioner | solar | 30-34 | ×1.2 | ×1.9 | Ironwood Log, Glasswort, Pilgrim's Ration, The Shadeless Band |
| `sun_templar` | Sun Templar | Mini-boss | Champion | solar | 30-34 | ×1.7 | ×1.2 | Ironwood Log, Glasswort, Pilgrim's Ration, The Shadeless Band |
| `the_shadeless_hour` | The Shadeless Hour | Mini-boss | Hexer | solar | 30-34 | ×1.6 | ×0.75 | Ironwood Log, Glasswort, Pilgrim's Ration, The Shadeless Band |
| `solar_deity` | Solar Deity | Boss | Aspect | solar | 30-34 | ×2.6 | ×1.5 | Ironwood Log, Glasswort, The Shadeless Band, The Hardest Edge |
| `the_cold_shadow` | The Cold Shadow | Boss | Juggernaut | solar | 30-34 | ×2.8 | ×1.4 | Ironwood Log, Glasswort, The Shadeless Band, The Hardest Edge |

### The Mirrormere (`the_mirrormere`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `mirror_wraith` | Mirror Wraith | Wild | Adept | lunar | 32-37 | ×1.0 | ×0.9 | Mirrorflax, Lunar Shard, Lunar Dust |
| `palefish_shoal` | Palefish Shoal | Wild | Lasher | lunar | 32-37 | ×0.85 | ×1.0 | Mirrorflax, Lunar Shard, Lunar Dust |
| `ripplecut` | Ripplecut | Wild | Skirmisher | lunar | 32-37 | ×0.7 | ×1.15 | Bloodwood Log, Lunar Shard, Lunar Dust, Pilgrim's Ration |
| `stillface` | Stillface | Wild | Blighter | lunar | 32-37 | ×1.0 | ×0.6 | Bloodwood Log, Lunar Shard, Lunar Dust |
| `undershine` | Undershine | Wild | Glasswing | lunar | 32-37 | ×0.5 | ×1.7 | Mirrorflax, Glasswort Draught |
| `herald_of_the_waxing` | Herald of the Waxing | Mini-boss | Redoubt | lunar | 32-37 | ×2.2 | ×0.85 | Bloodwood Log, Mirrorflax, Pilgrim's Ration, The Waning Charm |
| `stalker_of_the_new_moon` | Stalker of the New Moon | Mini-boss | Executioner | lunar | 32-37 | ×1.2 | ×1.9 | Bloodwood Log, Mirrorflax, Pilgrim's Ration, The Waning Charm |
| `the_second_you` | The Second You | Mini-boss | Champion | lunar | 32-37 | ×1.7 | ×1.2 | Bloodwood Log, Mirrorflax, Pilgrim's Ration, The Waning Charm |
| `the_waning_wraith` | The Waning Wraith | Mini-boss | Hexer | lunar | 32-37 | ×1.6 | ×0.75 | Bloodwood Log, Mirrorflax, Pilgrim's Ration, The Waning Charm |
| `luna_plena_the_full_moon` | Luna Plena, the Full Moon | Boss | Aspect | lunar | 32-37 | ×2.6 | ×1.5 | Bloodwood Log, Mirrorflax, The Waning Charm, The Larger Reflection |
| `the_moon_below` | The Moon Below | Boss | Tyrant | lunar | 32-37 | ×2.6 | ×1.7 | Bloodwood Log, Mirrorflax, The Waning Charm, The Larger Reflection |

### Starfall Basin (`starfall_basin`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `cold_ejecta` | Cold Ejecta | Wild | Skirmisher | astral | 34-39 | ×0.7 | ×1.15 | Sky-Iron Ore, Astral Shard, Astral Dust, Pilgrim's Ration |
| `crater_revenant` | Crater Revenant | Wild | Adept | astral | 34-39 | ×1.0 | ×0.9 | Fallstone, Astral Shard, Astral Dust |
| `fallpoint` | Fallpoint | Wild | Glasswing | astral | 34-39 | ×0.5 | ×1.7 | Fallstone, Astral Shard, Astral Dust |
| `scatterling` | Scatterling | Wild | Lasher | astral | 34-39 | ×0.85 | ×1.0 | Sky-Iron Ore, Astral Shard, Astral Dust, Pilgrim's Ration |
| `sky_iron_husk` | Sky-Iron Husk | Wild | Sentinel | astral | 34-39 | ×1.25 | ×0.7 | Sky-Iron Ore, Fallstone, Glasswort Draught |
| `constellation_warden` | Constellation Warden | Mini-boss | Redoubt | astral | 34-39 | ×2.2 | ×0.85 | Sky-Iron Ore, Fallstone, Pilgrim's Ration, Zodiac Pendant |
| `echo_of_the_between` | Echo of the Between | Mini-boss | Hexer | astral | 34-39 | ×1.6 | ×0.75 | Sky-Iron Ore, Fallstone, Pilgrim's Ration, Zodiac Pendant |
| `rift_walker` | Rift Walker | Mini-boss | Executioner | astral | 34-39 | ×1.2 | ×1.9 | Sky-Iron Ore, Fallstone, Pilgrim's Ration, Zodiac Pendant |
| `the_zodiac_ascendant` | The Zodiac Ascendant | Mini-boss | Champion | astral | 34-39 | ×1.7 | ×1.2 | Sky-Iron Ore, Fallstone, Pilgrim's Ration, Zodiac Pendant |
| `the_next_one` | The Next One | Boss | Juggernaut | astral | 34-39 | ×2.8 | ×1.4 | Sky-Iron Ore, Fallstone, Zodiac Pendant, The Aimed Sky |
| `what_landed` | What Landed | Boss | Tyrant | astral | 34-39 | ×2.6 | ×1.7 | Sky-Iron Ore, Fallstone, Zodiac Pendant, The Aimed Sky |

### Tidewrack Shoals (`tidewrack_shoals`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `gullbone_flock` | Gullbone Flock | Wild | Lasher | lunar | 36-40 | ×0.85 | ×1.0 | Drownling Hide, Aqua Shard, Aqua Dust, Pilgrim's Ration |
| `lowwater_thing` | Lowwater Thing | Wild | Blighter | aqua | 36-40 | ×1.0 | ×0.6 | Nacre, Glasswort Draught |
| `spindrift` | Spindrift | Wild | Skirmisher | aqua | 36-40 | ×0.7 | ×1.15 | Wrackcotton, Lunar Shard, Lunar Dust, Pilgrim's Ration |
| `tidewrack_drowned` | Tidewrack Drowned | Wild | Adept | lunar/aqua | 36-40 | ×1.0 | ×0.9 | Drownling Hide, Aqua Shard, Aqua Dust, Pilgrim's Ration |
| `wrackcrab` | Wrackcrab | Wild | Sentinel | aqua | 36-40 | ×1.25 | ×0.7 | Wrackcotton, Lunar Shard, Lunar Dust, Pilgrim's Ration |
| `leviathan` | Leviathan | Mini-boss | Redoubt | aqua | 36-40 | ×2.2 | ×0.85 | Drownling Hide, Wrackcotton, Nacre, The Turning Tide |
| `maelstrom_horror` | Maelstrom Horror | Mini-boss | Executioner | aqua | 36-40 | ×1.2 | ×1.9 | Drownling Hide, Wrackcotton, Nacre, The Turning Tide |
| `the_turning` | The Turning | Mini-boss | Hexer | lunar | 36-40 | ×1.6 | ×0.75 | Drownling Hide, Wrackcotton, Nacre, The Turning Tide |
| `tidal_empress` | Tidal Empress | Mini-boss | Champion | lunar/aqua | 36-40 | ×1.7 | ×1.2 | Drownling Hide, Wrackcotton, Nacre, The Turning Tide |
| `kraken` | Kraken | Boss | Juggernaut | aqua | 36-40 | ×2.8 | ×1.4 | Drownling Hide, Wrackcotton, Nacre, The Turning Tide, Lowwater Tread |
| `the_undertow` | The Undertow | Boss | Aspect | lunar | 36-40 | ×2.6 | ×1.5 | Drownling Hide, Wrackcotton, Nacre, The Turning Tide, Lowwater Tread |

### The Sunless Reach (`the_sunless_reach`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `coldlight_swarm` | Coldlight Swarm | Wild | Lasher | lunar | 38-42 | ×0.85 | ×1.0 | Ebony Log, Lunar Shard, Lunar Dust, Pilgrim's Ration |
| `crestline_warden` | Crestline Warden | Wild | Bruiser | solar | 38-42 | ×1.15 | ×1.1 | Eclipse Opal, Solar Shard, Solar Dust, Duskcap Tonic |
| `eclipse_herald` | Eclipse Herald | Wild | Adept | solar/lunar | 38-42 | ×1.0 | ×0.9 | Duskcap, Solar Shard, Solar Dust |
| `nightglare` | Nightglare | Wild | Blighter | solar | 38-42 | ×1.0 | ×0.6 | Ebony Log, Lunar Shard, Lunar Dust, Pilgrim's Ration |
| `shadowpitch_stalker` | Shadowpitch Stalker | Wild | Skirmisher | lunar | 38-42 | ×0.7 | ×1.15 | Duskcap, Solar Shard, Solar Dust |
| `both_sided_thing` | Both-Sided Thing | Mini-boss | Executioner | solar/lunar | 38-42 | ×1.2 | ×1.9 | Ebony Log, Duskcap, Eclipse Opal, Crestline Ring |
| `duskmarch` | Duskmarch | Mini-boss | Hexer | lunar | 38-42 | ×1.6 | ×0.75 | Ebony Log, Duskcap, Eclipse Opal, Crestline Ring |
| `solar_archon` | Solar Archon | Mini-boss | Champion | solar | 38-42 | ×1.7 | ×1.2 | Ebony Log, Duskcap, Eclipse Opal, Crestline Ring |
| `the_crest` | The Crest | Mini-boss | Redoubt | solar/lunar | 38-42 | ×2.2 | ×0.85 | Ebony Log, Duskcap, Eclipse Opal, Crestline Ring |
| `the_first_dark` | The First Dark | Boss | Aspect | lunar | 38-42 | ×2.6 | ×1.5 | Ebony Log, Duskcap, Eclipse Opal, Crestline Ring, The Dividing Line |
| `the_last_light` | The Last Light | Boss | Aspect | solar | 38-42 | ×2.6 | ×1.5 | Ebony Log, Duskcap, Eclipse Opal, Crestline Ring, The Dividing Line |

### The Shattered Orrery (`the_shattered_orrery`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `arcflock` | Arcflock | Wild | Lasher | electro | 40-44 | ×0.85 | ×1.0 | Arcsalt, Astral Shard, Astral Dust |
| `armature` | Armature | Wild | Bruiser | electro | 40-44 | ×1.15 | ×1.1 | Orrery Scrap, Electro Shard, Electro Dust, Pilgrim's Ration |
| `errant_ring` | Errant Ring | Wild | Skirmisher | astral | 40-44 | ×0.7 | ×1.15 | Orrery Scrap, Electro Shard, Electro Dust, Pilgrim's Ration |
| `gear_ghost` | Gear-Ghost | Wild | Glasswing | astral | 40-44 | ×0.5 | ×1.7 | Arcsalt, Astral Shard, Astral Dust |
| `orrery_automaton` | Orrery Automaton | Wild | Adept | astral/electro | 40-44 | ×1.0 | ×0.9 | Sidereal Glass, Astral Shard, Astral Dust, Arcsalt Draught |
| `escapement` | Escapement | Mini-boss | Redoubt | electro | 40-44 | ×2.2 | ×0.85 | Orrery Scrap, Arcsalt, Sidereal Glass, Sidereal Signet |
| `long_division` | Long Division | Mini-boss | Executioner | astral/electro | 40-44 | ×1.2 | ×1.9 | Orrery Scrap, Arcsalt, Sidereal Glass, Sidereal Signet |
| `sidereal_fault` | Sidereal Fault | Mini-boss | Champion | astral | 40-44 | ×1.7 | ×1.2 | Orrery Scrap, Arcsalt, Sidereal Glass, Sidereal Signet |
| `the_remainder` | The Remainder | Mini-boss | Hexer | astral | 40-44 | ×1.6 | ×0.75 | Orrery Scrap, Arcsalt, Sidereal Glass, Sidereal Signet |
| `the_answer` | The Answer | Boss | Tyrant | astral | 40-44 | ×2.6 | ×1.7 | Orrery Scrap, Arcsalt, Sidereal Glass, Sidereal Signet, The Running Count |
| `the_calculation` | The Calculation | Boss | Juggernaut | electro | 40-44 | ×2.8 | ×1.4 | Orrery Scrap, Arcsalt, Sidereal Glass, Sidereal Signet, The Running Count |

### Hallowmarch (`hallowmarch`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `causeway_warden` | Causeway Warden | Wild | Sentinel | sanctus | 45-49 | ×1.25 | ×0.7 | Spiritwood Log, Sanctus Shard, Sanctus Dust, Climber's Ration |
| `marker_sworn` | Marker-Sworn | Wild | Adept | sanctus | 45-49 | ×1.0 | ×0.9 | Goldenrood, Sanctus Shard, Sanctus Dust |
| `meltwater_choir` | Meltwater Choir | Wild | Lasher | sanctus | 45-49 | ×0.85 | ×1.0 | Goldenrood, Sanctus Shard, Sanctus Dust |
| `pilgrims_remnant` | Pilgrim's Remnant | Wild | Bruiser | sanctus | 45-49 | ×1.15 | ×1.1 | Goldenrood, Climber's Ration |
| `votive` | Votive | Wild | Glasswing | sanctus | 45-49 | ×0.5 | ×1.7 | Spiritwood Log, Sanctus Shard, Sanctus Dust, Climber's Ration |
| `milestone` | Milestone | Mini-boss | Champion | sanctus | 45-49 | ×1.7 | ×1.2 | Spiritwood Log, Goldenrood, Climber's Ration, Votive Pendant |
| `seraph_judicant` | Seraph Judicant | Mini-boss | Executioner | sanctus | 45-49 | ×1.2 | ×1.9 | Spiritwood Log, Goldenrood, Climber's Ration, Votive Pendant |
| `the_upkeep` | The Upkeep | Mini-boss | Hexer | sanctus | 45-49 | ×1.6 | ×0.75 | Spiritwood Log, Goldenrood, Climber's Ration, Votive Pendant |
| `vestal_warden` | Vestal Warden | Mini-boss | Redoubt | sanctus | 45-49 | ×2.2 | ×0.85 | Spiritwood Log, Goldenrood, Climber's Ration, Votive Pendant |
| `the_hierophant_eternal` | The Hierophant Eternal | Boss | Tyrant | sanctus | 45-49 | ×2.6 | ×1.7 | Spiritwood Log, Goldenrood, Votive Pendant, The Maintained Road |
| `the_keeper_of_the_road` | The Keeper of the Road | Boss | Juggernaut | sanctus | 45-49 | ×2.8 | ×1.4 | Spiritwood Log, Goldenrood, Votive Pendant, The Maintained Road |

### The Umbral Wastes (`the_umbral_wastes`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `considered_ice` | Considered Ice | Wild | Sentinel | umbra | 47-51 | ×1.25 | ×0.7 | Umbralweave, Umbra Shard, Umbra Dust, Climber's Ration |
| `edgewalker` | Edgewalker | Wild | Adept | umbra | 47-51 | ×1.0 | ×0.9 | Thoughtglass, Umbra Shard, Umbra Dust |
| `nightspill` | Nightspill | Wild | Blighter | umbra | 47-51 | ×1.0 | ×0.6 | Umbralweave, Umbra Shard, Umbra Dust, Climber's Ration |
| `thoughtform` | Thoughtform | Wild | Glasswing | umbra | 47-51 | ×0.5 | ×1.7 | Thoughtglass, Umbra Shard, Umbra Dust |
| `umbral_devourer` | Umbral Devourer | Wild | Siphon | umbra | 47-51 | ×0.95 | ×0.85 | Umbralweave, Goldenrood Draught |
| `eclipse_weaver` | Eclipse Weaver | Mini-boss | Hexer | umbra | 47-51 | ×1.6 | ×0.75 | Umbralweave, Thoughtglass, Climber's Ration, The Considered Ring |
| `the_edge` | The Edge | Mini-boss | Redoubt | umbra | 47-51 | ×2.2 | ×0.85 | Umbralweave, Thoughtglass, Climber's Ration, The Considered Ring |
| `umbral_knight` | Umbral Knight | Mini-boss | Champion | umbra | 47-51 | ×1.7 | ×1.2 | Umbralweave, Thoughtglass, Climber's Ration, The Considered Ring |
| `void_stalker` | Void Stalker | Mini-boss | Executioner | umbra | 47-51 | ×1.2 | ×1.9 | Umbralweave, Thoughtglass, Climber's Ration, The Considered Ring |
| `nightbringer` | Nightbringer | Boss | Tyrant | umbra | 47-51 | ×2.6 | ×1.7 | Umbralweave, Thoughtglass, The Considered Ring, The Deliberate Dark |
| `what_was_thought_about` | What Was Thought About | Boss | Aspect | umbra | 47-51 | ×2.6 | ×1.5 | Umbralweave, Thoughtglass, The Considered Ring, The Deliberate Dark |

### The Reliquary Deep (`the_reliquary_deep`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `bone_reliquary` | Bone-Reliquary | Wild | Bruiser | sanctus | 52-56 | ×1.15 | ×1.1 | Unleft Linen, Sanctus Shard, Sanctus Dust, Climber's Ration |
| `censer_wraith` | Censer-Wraith | Wild | Blighter | umbra | 52-56 | ×1.0 | ×0.6 | Censer Resin, Umbra Shard, Umbra Dust |
| `corridor_crawler` | Corridor Crawler | Wild | Skirmisher | sanctus/umbra | 52-56 | ×0.7 | ×1.15 | Reliquary Gold, Censer Draught |
| `reliquary_keeper` | Reliquary Keeper | Wild | Adept | sanctus | 52-56 | ×1.0 | ×0.9 | Unleft Linen, Sanctus Shard, Sanctus Dust, Climber's Ration |
| `the_unleft` | The Unleft | Wild | Glasswing | umbra | 52-56 | ×0.5 | ×1.7 | Censer Resin, Umbra Shard, Umbra Dust |
| `antechoir` | Antechoir | Mini-boss | Champion | sanctus | 52-56 | ×1.7 | ×1.2 | Unleft Linen, Censer Resin, Reliquary Gold, Censer Pendant |
| `reliquary_colossus` | Reliquary Colossus | Mini-boss | Redoubt | sanctus | 52-56 | ×2.2 | ×0.85 | Unleft Linen, Censer Resin, Reliquary Gold, Censer Pendant |
| `the_second_hand` | The Second Hand | Mini-boss | Executioner | umbra | 52-56 | ×1.2 | ×1.9 | Unleft Linen, Censer Resin, Reliquary Gold, Censer Pendant |
| `warm_middle` | Warm Middle | Mini-boss | Hexer | sanctus/umbra | 52-56 | ×1.6 | ×0.75 | Unleft Linen, Censer Resin, Reliquary Gold, Censer Pendant |
| `what_did_not_leave_it_alone` | What Did Not Leave It Alone | Boss | Tyrant | umbra | 52-56 | ×2.6 | ×1.7 | Unleft Linen, Censer Resin, Reliquary Gold, Censer Pendant, The Unconsecrated |
| `what_was_consecrated` | What Was Consecrated | Boss | Juggernaut | sanctus | 52-56 | ×2.8 | ×1.4 | Unleft Linen, Censer Resin, Reliquary Gold, Censer Pendant, The Unconsecrated |

### The Sealed Garden (`the_sealed_garden`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `chorister_vine` | Chorister Vine | Wild | Adept | flora/sanctus | 49-53 | ×1.0 | ×0.9 | Worldroot, Sanctus Shard, Sanctus Dust, Climber's Ration |
| `orchard_warden` | Orchard Warden | Wild | Sentinel | sanctus | 49-53 | ×1.25 | ×0.7 | Worldroot, Sanctus Shard, Sanctus Dust, Climber's Ration |
| `thornpenitent` | Thornpenitent | Wild | Bruiser | flora/sanctus | 49-53 | ×1.15 | ×1.1 | Thornpenitent Hide, Flora Shard, Flora Dust, Climber's Ration |
| `whisperling` | Whisperling | Wild | Blighter | flora | 49-53 | ×1.0 | ×0.6 | Thornpenitent Hide, Flora Shard, Flora Dust, Climber's Ration |
| `windfall` | Windfall | Wild | Siphon | flora | 49-53 | ×0.95 | ×0.85 | Orchard Amber, Worldroot Tonic |
| `cherub_of_the_turning_blade` | Cherub of the Turning Blade | Mini-boss | Executioner | sanctus/solar | 49-53 | ×1.2 | ×1.9 | Thornpenitent Hide, Worldroot, Orchard Amber, The Gardener's Loop |
| `root_matriarch` | Root Matriarch | Mini-boss | Redoubt | flora | 49-53 | ×2.2 | ×0.85 | Thornpenitent Hide, Worldroot, Orchard Amber, The Gardener's Loop |
| `the_kept_vow` | The Kept Vow | Mini-boss | Hexer | sanctus | 49-53 | ×1.6 | ×0.75 | Thornpenitent Hide, Worldroot, Orchard Amber, The Gardener's Loop |
| `the_last_gardener` | The Last Gardener | Mini-boss | Champion | flora/sanctus | 49-53 | ×1.7 | ×1.2 | Thornpenitent Hide, Worldroot, Orchard Amber, The Gardener's Loop |
| `guardian_of_the_world_tree` | Guardian of the World Tree | Boss | Juggernaut | sanctus | 49-53 | ×2.8 | ×1.4 | Thornpenitent Hide, Worldroot, Orchard Amber, The Gardener's Loop, The Season At Once |
| `the_serpent_in_the_branches` | The Serpent in the Branches | Boss | Tyrant | flora | 49-53 | ×2.6 | ×1.7 | Thornpenitent Hide, Worldroot, Orchard Amber, The Gardener's Loop, The Season At Once |

### The Glass Archive (`the_glass_archive`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `glasswright` | Glasswright | Wild | Adept | solar/arcane | 43-47 | ×1.0 | ×0.9 | Aetherglass, Arcsalt Draught |
| `lensfly` | Lensfly | Wild | Skirmisher | solar | 43-47 | ×0.7 | ×1.15 | Sunbleach Lichen, Solar Shard, Solar Dust, Pilgrim's Ration |
| `noonmark` | Noonmark | Wild | Glasswing | solar | 43-47 | ×0.5 | ×1.7 | Sunbleach Lichen, Solar Shard, Solar Dust, Pilgrim's Ration |
| `palimpsest` | Palimpsest | Wild | Blighter | arcane | 43-47 | ×1.0 | ×0.6 | Palimpsest Vellum, Arcane Shard, Arcane Dust, Sunbleach Tonic |
| `readerless` | Readerless | Wild | Lasher | arcane | 43-47 | ×0.85 | ×1.0 | Palimpsest Vellum, Arcane Shard, Arcane Dust, Sunbleach Tonic |
| `aperture` | Aperture | Mini-boss | Redoubt | solar | 43-47 | ×2.2 | ×0.85 | Palimpsest Vellum, Sunbleach Lichen, Aetherglass, The Last Reading |
| `burnt_index` | Burnt Index | Mini-boss | Executioner | solar/pyro | 43-47 | ×1.2 | ×1.9 | Palimpsest Vellum, Sunbleach Lichen, Aetherglass, The Last Reading |
| `the_last_reader` | The Last Reader | Mini-boss | Champion | solar/arcane | 43-47 | ×1.7 | ×1.2 | Palimpsest Vellum, Sunbleach Lichen, Aetherglass, The Last Reading |
| `the_marginalia` | The Marginalia | Mini-boss | Hexer | arcane | 43-47 | ×1.6 | ×0.75 | Palimpsest Vellum, Sunbleach Lichen, Aetherglass, The Last Reading |
| `what_is_left_of_it` | What Is Left Of It | Boss | Aspect | solar | 43-47 | ×2.6 | ×1.5 | Palimpsest Vellum, Sunbleach Lichen, Aetherglass, The Last Reading, The Noon Hour |
| `what_was_written` | What Was Written | Boss | Tyrant | arcane | 43-47 | ×2.6 | ×1.7 | Palimpsest Vellum, Sunbleach Lichen, Aetherglass, The Last Reading, The Noon Hour |

### The Buried Sky (`the_buried_sky`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `constellate` | Constellate | Wild | Lasher | astral | 46-50 | ×0.85 | ×1.0 | Deepstratum Ore, Astral Shard, Astral Dust, Climber's Ration |
| `corebiter` | Corebiter | Wild | Bruiser | geo | 46-50 | ×1.15 | ×1.1 | Nadir Garnet, Goldenrood Draught |
| `deadreckoner` | Deadreckoner | Wild | Adept | geo/astral | 46-50 | ×1.0 | ×0.9 | Corebiter Hide, Geo Shard, Geo Dust, Climber's Ration |
| `fadelight` | Fadelight | Wild | Glasswing | astral | 46-50 | ×0.5 | ×1.7 | Corebiter Hide, Geo Shard, Geo Dust, Climber's Ration |
| `stratum_warden` | Stratum Warden | Wild | Sentinel | geo | 46-50 | ×1.25 | ×0.7 | Deepstratum Ore, Astral Shard, Astral Dust, Climber's Ration |
| `bedrock_colossus` | Bedrock Colossus | Mini-boss | Redoubt | geo | 46-50 | ×2.2 | ×0.85 | Corebiter Hide, Deepstratum Ore, Nadir Garnet, Stonefall Signet |
| `nadir` | Nadir | Mini-boss | Executioner | geo | 46-50 | ×1.2 | ×1.9 | Corebiter Hide, Deepstratum Ore, Nadir Garnet, Stonefall Signet |
| `stonefall_herald` | Stonefall Herald | Mini-boss | Champion | geo/astral | 46-50 | ×1.7 | ×1.2 | Corebiter Hide, Deepstratum Ore, Nadir Garnet, Stonefall Signet |
| `the_long_count` | The Long Count | Mini-boss | Hexer | astral | 46-50 | ×1.6 | ×0.75 | Corebiter Hide, Deepstratum Ore, Nadir Garnet, Stonefall Signet |
| `the_buried_constellation` | The Buried Constellation | Boss | Aspect | astral | 46-50 | ×2.6 | ×1.5 | Corebiter Hide, Deepstratum Ore, Nadir Garnet, Stonefall Signet, Bedrock Greaves |
| `the_overburden` | The Overburden | Boss | Juggernaut | geo | 46-50 | ×2.8 | ×1.4 | Corebiter Hide, Deepstratum Ore, Nadir Garnet, Stonefall Signet, Bedrock Greaves |

### The Collapsed Academy (`the_collapsed_academy`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `chalkwraith` | Chalkwraith | Wild | Skirmisher | arcane | 50-54 | ×0.7 | ×1.15 | Aetherwood Log, Arcane Shard, Arcane Dust, Climber's Ration |
| `emeritus` | Emeritus | Wild | Glasswing | arcane | 50-54 | ×0.5 | ×1.7 | Mana Slag, Climber's Ration |
| `marginal_note` | Marginal Note | Wild | Blighter | arcane | 50-54 | ×1.0 | ×0.6 | Mana Slag, Arcane Shard, Arcane Dust |
| `stairhead` | Stairhead | Wild | Bruiser | arcane | 50-54 | ×1.15 | ×1.1 | Aetherwood Log, Arcane Shard, Arcane Dust, Climber's Ration |
| `unfinished_scholar` | Unfinished Scholar | Wild | Adept | arcane | 50-54 | ×1.0 | ×0.9 | Mana Slag, Arcane Shard, Arcane Dust |
| `arcane_chimera` | Arcane Chimera | Mini-boss | Executioner | arcane | 50-54 | ×1.2 | ×1.9 | Aetherwood Log, Mana Slag, Climber's Ration, Chalkline Signet |
| `mana_golem` | Mana Golem | Mini-boss | Redoubt | arcane | 50-54 | ×2.2 | ×0.85 | Aetherwood Log, Mana Slag, Climber's Ration, Chalkline Signet |
| `spell_weaver` | Spell Weaver | Mini-boss | Hexer | arcane | 50-54 | ×1.6 | ×0.75 | Aetherwood Log, Mana Slag, Climber's Ration, Chalkline Signet |
| `the_fourth_item` | The Fourth Item | Mini-boss | Champion | arcane/astral | 50-54 | ×1.7 | ×1.2 | Aetherwood Log, Mana Slag, Climber's Ration, Chalkline Signet |
| `the_archmage` | The Archmage | Boss | Tyrant | arcane | 50-54 | ×2.6 | ×1.7 | Aetherwood Log, Mana Slag, Chalkline Signet, The Unbuilt Stair |
| `the_last_three_items` | The Last Three Items | Boss | Aspect | arcane | 50-54 | ×2.6 | ×1.5 | Aetherwood Log, Mana Slag, Chalkline Signet, The Unbuilt Stair |

### The Unwritten Library (`the_unwritten_library`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `blankspine` | Blankspine | Wild | Glasswing | umbra | 54-58 | ×0.5 | ×1.7 | Nightink, Umbra Shard, Umbra Dust, Climber's Ration |
| `erratum` | Erratum | Wild | Skirmisher | arcane | 54-58 | ×0.7 | ×1.15 | Colophon Stone, Censer Draught |
| `footnote` | Footnote | Wild | Lasher | arcane | 54-58 | ×0.85 | ×1.0 | Nightink, Umbra Shard, Umbra Dust, Climber's Ration |
| `ink_drinker` | Ink-Drinker | Wild | Siphon | umbra | 54-58 | ×0.95 | ×0.85 | Blankspine Vellum, Arcane Shard, Arcane Dust, Nightink Draught |
| `the_dictating_hand` | The Dictating Hand | Wild | Adept | umbra/arcane | 54-58 | ×1.0 | ×0.9 | Blankspine Vellum, Arcane Shard, Arcane Dust, Nightink Draught |
| `colophon` | Colophon | Mini-boss | Redoubt | arcane | 54-58 | ×2.2 | ×0.85 | Blankspine Vellum, Nightink, Colophon Stone, Colophon Signet |
| `redaction` | Redaction | Mini-boss | Executioner | umbra | 54-58 | ×1.2 | ×1.9 | Blankspine Vellum, Nightink, Colophon Stone, Colophon Signet |
| `the_amanuensis` | The Amanuensis | Mini-boss | Hexer | umbra/arcane | 54-58 | ×1.6 | ×0.75 | Blankspine Vellum, Nightink, Colophon Stone, Colophon Signet |
| `the_index` | The Index | Mini-boss | Champion | arcane | 54-58 | ×1.7 | ×1.2 | Blankspine Vellum, Nightink, Colophon Stone, Colophon Signet |
| `the_author` | The Author | Boss | Aspect | umbra | 54-58 | ×2.6 | ×1.5 | Blankspine Vellum, Nightink, Colophon Stone, Colophon Signet, The Open Colophon |
| `the_record` | The Record | Boss | Juggernaut | arcane | 54-58 | ×2.8 | ×1.4 | Blankspine Vellum, Nightink, Colophon Stone, Colophon Signet, The Open Colophon |

### The Eclipsed Citadel (`the_eclipsed_citadel`) — 11 creatures

| Id | Name | Rank | Archetype | Element | Level | HP scale | Power scale | Notable drops |
|---|---|---|---|---|---|---|---|---|
| `ashlight` | Ashlight | Wild | Blighter | pyro/umbra | 58-60 | ×1.0 | ×0.6 | Eclipse Iron, Corona Pearl, Nightink Draught, Climber's Ration |
| `nightcurrent` | Nightcurrent | Wild | Lasher | lunar/electro | 58-60 | ×0.85 | ×1.0 | Eclipse Iron, Corona Pearl, Nightink Draught, Climber's Ration |
| `the_held_door` | The Held Door | Wild | Sentinel | geo/flora | 58-60 | ×1.25 | ×0.7 | Eclipse Iron, Corona Pearl, Nightink Draught, Climber's Ration |
| `the_kept_watch` | The Kept Watch | Wild | Bruiser | sanctus/solar | 58-60 | ×1.15 | ×1.1 | Eclipse Iron, Corona Pearl, Nightink Draught, Climber's Ration |
| `the_last_applicant` | The Last Applicant | Wild | Adept | aqua/aero/astral/arcane | 58-60 | ×1.0 | ×0.9 | Eclipse Iron, Corona Pearl, Nightink Draught, Climber's Ration |
| `the_basin` | The Basin | Mini-boss | Champion | flora/aqua/pyro | 58-60 | ×1.7 | ×1.2 | Eclipse Iron, Corona Pearl, Nightink Draught, The Eclipsed Band |
| `the_climb` | The Climb | Mini-boss | Hexer | sanctus/umbra/arcane | 58-60 | ×1.6 | ×0.75 | Eclipse Iron, Corona Pearl, Nightink Draught, The Eclipsed Band |
| `the_range` | The Range | Mini-boss | Redoubt | geo/electro/aero | 58-60 | ×2.2 | ×0.85 | Eclipse Iron, Corona Pearl, Nightink Draught, The Eclipsed Band |
| `the_shelf` | The Shelf | Mini-boss | Executioner | solar/lunar/astral | 58-60 | ×1.2 | ×1.9 | Eclipse Iron, Corona Pearl, Nightink Draught, The Eclipsed Band |
| `procarius_the_eclipsed` | Procarius, the Eclipsed | Boss | Tyrant | arcane/umbra/lunar/electro/pyro | 58-60 | ×2.6 | ×1.7 | Eclipse Iron, Corona Pearl, The Eclipsed Band, The Last Thing in the Way, The Corona |
| `totality` | Totality | Boss | Juggernaut | aqua/pyro/flora/electro/aero/geo/solar/lunar/astral/sanctus/umbra/arcane | 58-60 | ×2.8 | ×1.4 | Eclipse Iron, Corona Pearl, The Eclipsed Band, The Last Thing in the Way, The Corona |


## Recipes by skill

### Woodcarving — 27 recipes

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
| `craft_ironwood_knot` | 36 | 2x Ironwood Log | 1x Ironwood Knot | 152 |
| `craft_ironwood_quarterstaff` | 36 | 3x Ironwood Log, 1x Iron Ingot | 1x Ironwood Quarterstaff | 304 |
| `craft_ironwood_wand` | 36 | 2x Ironwood Log, 1x Iron Ingot | 1x Ironwood Wand | 228 |
| `craft_bloodwood_knot` | 40 | 2x Bloodwood Log | 1x Bloodwood Knot | 168 |
| `craft_bloodwood_quarterstaff` | 40 | 3x Bloodwood Log, 1x Skysteel Ingot | 1x Bloodwood Quarterstaff | 336 |
| `craft_bloodwood_wand` | 40 | 2x Bloodwood Log, 1x Skysteel Ingot | 1x Bloodwood Wand | 252 |
| `craft_ebony_knot` | 44 | 2x Ebony Log | 1x Ebony Knot | 184 |
| `craft_ebony_quarterstaff` | 44 | 3x Ebony Log, 1x Starbrass Ingot | 1x Ebony Quarterstaff | 368 |
| `craft_ebony_wand` | 44 | 2x Ebony Log, 1x Starbrass Ingot | 1x Ebony Wand | 276 |
| `craft_spiritwood_knot` | 46 | 2x Spiritwood Log | 1x Spiritwood Knot | 192 |
| `craft_spiritwood_quarterstaff` | 46 | 3x Spiritwood Log, 1x Deepsteel Ingot | 1x Spiritwood Quarterstaff | 384 |
| `craft_spiritwood_wand` | 46 | 2x Spiritwood Log, 1x Deepsteel Ingot | 1x Spiritwood Wand | 288 |
| `craft_aetherwood_knot` | 50 | 2x Aetherwood Log | 1x Aetherwood Knot | 208 |
| `craft_aetherwood_quarterstaff` | 50 | 3x Aetherwood Log, 1x Aethersteel Ingot | 1x Aetherwood Quarterstaff | 416 |
| `craft_aetherwood_wand` | 50 | 2x Aetherwood Log, 1x Aethersteel Ingot | 1x Aetherwood Wand | 312 |

### Tailoring — 49 recipes

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
| `craft_mirrorflax_boots` | 36 | 3x Mirrorflax | 1x Mirrorflax Boots | 228 |
| `craft_mirrorflax_gloves` | 36 | 3x Mirrorflax | 1x Mirrorflax Gloves | 228 |
| `craft_mirrorflax_hood` | 36 | 3x Mirrorflax | 1x Mirrorflax Hood | 228 |
| `craft_mirrorflax_leggings` | 36 | 5x Mirrorflax | 1x Mirrorflax Leggings | 380 |
| `craft_mirrorflax_robe` | 36 | 6x Mirrorflax | 1x Mirrorflax Robe | 456 |
| `craft_drownling_belt` | 38 | 2x Drownling Hide, 1x Mirrorflax | 1x Drownling Belt | 240 |
| `craft_wrackcotton_boots` | 40 | 3x Wrackcotton | 1x Wrackcotton Boots | 252 |
| `craft_wrackcotton_gloves` | 40 | 3x Wrackcotton | 1x Wrackcotton Gloves | 252 |
| `craft_wrackcotton_hood` | 40 | 3x Wrackcotton | 1x Wrackcotton Hood | 252 |
| `craft_wrackcotton_leggings` | 40 | 5x Wrackcotton | 1x Wrackcotton Leggings | 420 |
| `craft_wrackcotton_robe` | 40 | 6x Wrackcotton | 1x Wrackcotton Robe | 504 |
| `craft_palimpsest_belt` | 44 | 2x Palimpsest Vellum, 1x Wrackcotton | 1x Palimpsest Belt | 276 |
| `craft_umbralweave_boots` | 44 | 3x Umbralweave | 1x Umbralweave Boots | 276 |
| `craft_umbralweave_gloves` | 44 | 3x Umbralweave | 1x Umbralweave Gloves | 276 |
| `craft_umbralweave_hood` | 44 | 3x Umbralweave | 1x Umbralweave Hood | 276 |
| `craft_umbralweave_leggings` | 44 | 5x Umbralweave | 1x Umbralweave Leggings | 460 |
| `craft_umbralweave_robe` | 44 | 6x Umbralweave | 1x Umbralweave Robe | 552 |
| `craft_corebiter_belt` | 46 | 2x Corebiter Hide, 1x Umbralweave | 1x Corebiter Belt | 288 |
| `craft_penitent_belt` | 48 | 2x Thornpenitent Hide, 1x Umbralweave | 1x Thornpenitent Belt | 300 |
| `craft_unleft_boots` | 48 | 3x Unleft Linen | 1x Unleft Linen Boots | 300 |
| `craft_unleft_gloves` | 48 | 3x Unleft Linen | 1x Unleft Linen Gloves | 300 |
| `craft_unleft_hood` | 48 | 3x Unleft Linen | 1x Unleft Linen Hood | 300 |
| `craft_unleft_leggings` | 48 | 5x Unleft Linen | 1x Unleft Linen Leggings | 500 |
| `craft_unleft_robe` | 48 | 6x Unleft Linen | 1x Unleft Linen Robe | 600 |
| `craft_blankspine_belt` | 50 | 2x Blankspine Vellum, 1x Unleft Linen | 1x Blankspine Belt | 312 |

### Metalworking — 6 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_bronze_ingot` | 1 | 2x Copper Ore, 1x Tin Ore, 1x Charcoal | 1x Bronze Ingot | 24 |
| `craft_iron_ingot` | 10 | 3x Iron Ore, 2x Charcoal | 1x Iron Ingot | 120 |
| `craft_skysteel_ingot` | 36 | 3x Sky-Iron Ore, 2x Charcoal | 1x Skysteel Ingot | 380 |
| `craft_starbrass_ingot` | 44 | 3x Orrery Scrap, 2x Charcoal | 1x Starbrass Ingot | 460 |
| `craft_deepsteel_ingot` | 46 | 3x Deepstratum Ore, 2x Charcoal | 1x Deepsteel Ingot | 480 |
| `craft_aethersteel_ingot` | 50 | 3x Mana Slag, 2x Charcoal | 1x Aethersteel Ingot | 520 |

### Potions & Alchemy — 11 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_sapwort_draught` | 1 | 2x Sapwort | 1x Sapwort Draught | 12 |
| `craft_brookmint_tonic` | 10 | 2x Brookmint | 1x Brookmint Tonic | 48 |
| `craft_saltwort_draught` | 20 | 2x Saltwort | 1x Saltwort Draught | 88 |
| `craft_glasswort_draught` | 34 | 2x Glasswort | 1x Glasswort Draught | 144 |
| `craft_duskcap_tonic` | 38 | 2x Duskcap | 1x Duskcap Tonic | 160 |
| `craft_arcsalt_draught` | 42 | 3x Arcsalt | 1x Arcsalt Draught | 264 |
| `craft_sunbleach_tonic` | 44 | 3x Sunbleach Lichen | 1x Sunbleach Tonic | 276 |
| `craft_goldenrood_draught` | 46 | 3x Goldenrood | 1x Goldenrood Draught | 288 |
| `craft_censer_draught` | 48 | 4x Censer Resin | 1x Censer Draught | 400 |
| `craft_worldroot_tonic` | 48 | 3x Worldroot | 1x Worldroot Tonic | 300 |
| `craft_nightink_draught` | 50 | 4x Nightink | 1x Nightink Draught | 416 |

### Enchanting — 85 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_celestial_totem` | 1 | 1x Solar Essence, 1x Lunar Essence, 1x Astral Essence, 3x Hum Quartz, 2x Fallstone | 1x Celestial Totem | 48 |
| `refine_aero_shard` | 1 | 50x Aero Dust | 1x Aero Shard | 300 |
| `refine_aqua_shard` | 1 | 50x Aqua Dust | 1x Aqua Shard | 300 |
| `refine_arcane_shard` | 1 | 50x Arcane Dust | 1x Arcane Shard | 300 |
| `refine_astral_shard` | 1 | 50x Astral Dust | 1x Astral Shard | 300 |
| `refine_electro_shard` | 1 | 50x Electro Dust | 1x Electro Shard | 300 |
| `refine_flora_shard` | 1 | 50x Flora Dust | 1x Flora Shard | 300 |
| `refine_geo_shard` | 1 | 50x Geo Dust | 1x Geo Shard | 300 |
| `refine_lunar_shard` | 1 | 50x Lunar Dust | 1x Lunar Shard | 300 |
| `refine_pyro_shard` | 1 | 50x Pyro Dust | 1x Pyro Shard | 300 |
| `refine_sanctus_shard` | 1 | 50x Sanctus Dust | 1x Sanctus Shard | 300 |
| `refine_solar_shard` | 1 | 50x Solar Dust | 1x Solar Shard | 300 |
| `refine_umbra_shard` | 1 | 50x Umbra Dust | 1x Umbra Shard | 300 |
| `transmute_aero_crystal` | 1 | 4x Geo Crystal | 1x Aero Crystal | 24 |
| `transmute_aero_dust` | 1 | 4x Geo Dust | 1x Aero Dust | 24 |
| `transmute_aero_shard` | 1 | 4x Geo Shard | 1x Aero Shard | 24 |
| `transmute_aqua_crystal` | 1 | 4x Pyro Crystal | 1x Aqua Crystal | 24 |
| `transmute_aqua_dust` | 1 | 4x Pyro Dust | 1x Aqua Dust | 24 |
| `transmute_aqua_shard` | 1 | 4x Pyro Shard | 1x Aqua Shard | 24 |
| `transmute_arcane_crystal` | 1 | 4x Aqua Crystal | 1x Arcane Crystal | 24 |
| `transmute_arcane_dust` | 1 | 4x Aqua Dust | 1x Arcane Dust | 24 |
| `transmute_arcane_shard` | 1 | 4x Aqua Shard | 1x Arcane Shard | 24 |
| `transmute_astral_crystal` | 1 | 4x Sanctus Crystal | 1x Astral Crystal | 24 |
| `transmute_astral_dust` | 1 | 4x Sanctus Dust | 1x Astral Dust | 24 |
| `transmute_astral_shard` | 1 | 4x Sanctus Shard | 1x Astral Shard | 24 |
| `transmute_electro_crystal` | 1 | 4x Aero Crystal | 1x Electro Crystal | 24 |
| `transmute_electro_dust` | 1 | 4x Aero Dust | 1x Electro Dust | 24 |
| `transmute_electro_shard` | 1 | 4x Aero Shard | 1x Electro Shard | 24 |
| `transmute_flora_crystal` | 1 | 4x Electro Crystal | 1x Flora Crystal | 24 |
| `transmute_flora_dust` | 1 | 4x Electro Dust | 1x Flora Dust | 24 |
| `transmute_flora_shard` | 1 | 4x Electro Shard | 1x Flora Shard | 24 |
| `transmute_geo_crystal` | 1 | 4x Solar Crystal | 1x Geo Crystal | 24 |
| `transmute_geo_dust` | 1 | 4x Solar Dust | 1x Geo Dust | 24 |
| `transmute_geo_shard` | 1 | 4x Solar Shard | 1x Geo Shard | 24 |
| `transmute_lunar_crystal` | 1 | 4x Astral Crystal | 1x Lunar Crystal | 24 |
| `transmute_lunar_dust` | 1 | 4x Astral Dust | 1x Lunar Dust | 24 |
| `transmute_lunar_shard` | 1 | 4x Astral Shard | 1x Lunar Shard | 24 |
| `transmute_pyro_crystal` | 1 | 4x Flora Crystal | 1x Pyro Crystal | 24 |
| `transmute_pyro_dust` | 1 | 4x Flora Dust | 1x Pyro Dust | 24 |
| `transmute_pyro_shard` | 1 | 4x Flora Shard | 1x Pyro Shard | 24 |
| `transmute_sanctus_crystal` | 1 | 4x Umbra Crystal | 1x Sanctus Crystal | 24 |
| `transmute_sanctus_dust` | 1 | 4x Umbra Dust | 1x Sanctus Dust | 24 |
| `transmute_sanctus_shard` | 1 | 4x Umbra Shard | 1x Sanctus Shard | 24 |
| `transmute_solar_crystal` | 1 | 4x Lunar Crystal | 1x Solar Crystal | 24 |
| `transmute_solar_dust` | 1 | 4x Lunar Dust | 1x Solar Dust | 24 |
| `transmute_solar_shard` | 1 | 4x Lunar Shard | 1x Solar Shard | 24 |
| `transmute_umbra_crystal` | 1 | 4x Arcane Crystal | 1x Umbra Crystal | 24 |
| `transmute_umbra_dust` | 1 | 4x Arcane Dust | 1x Umbra Dust | 24 |
| `transmute_umbra_shard` | 1 | 4x Arcane Shard | 1x Umbra Shard | 24 |
| `refine_aero_crystal` | 10 | 20x Aero Shard | 1x Aero Crystal | 480 |
| `refine_aqua_crystal` | 10 | 20x Aqua Shard | 1x Aqua Crystal | 480 |
| `refine_arcane_crystal` | 10 | 20x Arcane Shard | 1x Arcane Crystal | 480 |
| `refine_astral_crystal` | 10 | 20x Astral Shard | 1x Astral Crystal | 480 |
| `refine_electro_crystal` | 10 | 20x Electro Shard | 1x Electro Crystal | 480 |
| `refine_flora_crystal` | 10 | 20x Flora Shard | 1x Flora Crystal | 480 |
| `refine_geo_crystal` | 10 | 20x Geo Shard | 1x Geo Crystal | 480 |
| `refine_lunar_crystal` | 10 | 20x Lunar Shard | 1x Lunar Crystal | 480 |
| `refine_pyro_crystal` | 10 | 20x Pyro Shard | 1x Pyro Crystal | 480 |
| `refine_sanctus_crystal` | 10 | 20x Sanctus Shard | 1x Sanctus Crystal | 480 |
| `refine_solar_crystal` | 10 | 20x Solar Shard | 1x Solar Crystal | 480 |
| `refine_umbra_crystal` | 10 | 20x Umbra Shard | 1x Umbra Crystal | 480 |
| `refine_aero_core` | 25 | 12x Aero Crystal | 1x Aero Core | 648 |
| `refine_aqua_core` | 25 | 12x Aqua Crystal | 1x Aqua Core | 648 |
| `refine_arcane_core` | 25 | 12x Arcane Crystal | 1x Arcane Core | 648 |
| `refine_astral_core` | 25 | 12x Astral Crystal | 1x Astral Core | 648 |
| `refine_electro_core` | 25 | 12x Electro Crystal | 1x Electro Core | 648 |
| `refine_flora_core` | 25 | 12x Flora Crystal | 1x Flora Core | 648 |
| `refine_geo_core` | 25 | 12x Geo Crystal | 1x Geo Core | 648 |
| `refine_lunar_core` | 25 | 12x Lunar Crystal | 1x Lunar Core | 648 |
| `refine_pyro_core` | 25 | 12x Pyro Crystal | 1x Pyro Core | 648 |
| `refine_sanctus_core` | 25 | 12x Sanctus Crystal | 1x Sanctus Core | 648 |
| `refine_solar_core` | 25 | 12x Solar Crystal | 1x Solar Core | 648 |
| `refine_umbra_core` | 25 | 12x Umbra Crystal | 1x Umbra Core | 648 |
| `refine_aero_heart` | 40 | 4x Aero Core | 1x Aero Heart | 336 |
| `refine_aqua_heart` | 40 | 4x Aqua Core | 1x Aqua Heart | 336 |
| `refine_arcane_heart` | 40 | 4x Arcane Core | 1x Arcane Heart | 336 |
| `refine_astral_heart` | 40 | 4x Astral Core | 1x Astral Heart | 336 |
| `refine_electro_heart` | 40 | 4x Electro Core | 1x Electro Heart | 336 |
| `refine_flora_heart` | 40 | 4x Flora Core | 1x Flora Heart | 336 |
| `refine_geo_heart` | 40 | 4x Geo Core | 1x Geo Heart | 336 |
| `refine_lunar_heart` | 40 | 4x Lunar Core | 1x Lunar Heart | 336 |
| `refine_pyro_heart` | 40 | 4x Pyro Core | 1x Pyro Heart | 336 |
| `refine_sanctus_heart` | 40 | 4x Sanctus Core | 1x Sanctus Heart | 336 |
| `refine_solar_heart` | 40 | 4x Solar Core | 1x Solar Heart | 336 |
| `refine_umbra_heart` | 40 | 4x Umbra Core | 1x Umbra Heart | 336 |

### Jewelry — 55 recipes

| Id | Gate | Inputs | Output | XP |
|---|---|---|---|---|
| `craft_amber_band` | 1 | 1x Bronze Ingot, 1x Amber | 1x Amber Band | 12 |
| `craft_amber_drop` | 1 | 1x Bronze Ingot, 2x Amber | 1x Amber Drop | 18 |
| `craft_everice_band` | 1 | 2x Everice, 2x Quarry Jasper, 1x Nadir Garnet | 1x Everice Band | 30 |
| `craft_amber_pendant` | 5 | 1x Bronze Ingot, 4x Amber | 1x Amber Pendant | 70 |
| `craft_amber_ring` | 5 | 1x Bronze Ingot, 3x Amber | 1x Amber Ring | 56 |
| `craft_nacre_pendant` | 10 | 3x Nacre, 2x Obsidian, 1x Deepsteel Ingot | 1x Nacre Pendant | 144 |
| `cut_aero_lesser` | 10 | 1x Everice, 1x Aero Crystal | 1x Lesser Aero Gem | 48 |
| `cut_aqua_lesser` | 10 | 1x Nacre, 1x Aqua Crystal | 1x Lesser Aqua Gem | 48 |
| `cut_arcane_lesser` | 10 | 1x Colophon Stone, 1x Arcane Crystal | 1x Lesser Arcane Gem | 48 |
| `cut_astral_lesser` | 10 | 1x Sidereal Glass, 1x Astral Crystal | 1x Lesser Astral Gem | 48 |
| `cut_electro_lesser` | 10 | 1x Hum Quartz, 1x Electro Crystal | 1x Lesser Electro Gem | 48 |
| `cut_flora_lesser` | 10 | 1x Amber, 1x Flora Crystal | 1x Lesser Flora Gem | 48 |
| `cut_geo_lesser` | 10 | 1x Quarry Jasper, 1x Geo Crystal | 1x Lesser Geo Gem | 48 |
| `cut_lunar_lesser` | 10 | 1x Eclipse Opal, 1x Lunar Crystal | 1x Lesser Lunar Gem | 48 |
| `cut_pyro_lesser` | 10 | 1x Obsidian, 1x Pyro Crystal | 1x Lesser Pyro Gem | 48 |
| `cut_sanctus_lesser` | 10 | 1x Reliquary Gold, 1x Sanctus Crystal | 1x Lesser Sanctus Gem | 48 |
| `cut_solar_lesser` | 10 | 1x Aetherglass, 1x Solar Crystal | 1x Lesser Solar Gem | 48 |
| `cut_umbra_lesser` | 10 | 1x Thoughtglass, 1x Umbra Crystal | 1x Lesser Umbra Gem | 48 |
| `craft_jasper_pendant` | 12 | 1x Iron Ingot, 3x Quarry Jasper | 1x Jasper Pendant | 112 |
| `craft_jasper_ring` | 12 | 1x Iron Ingot, 2x Quarry Jasper | 1x Jasper Ring | 84 |
| `craft_obsidian_pendant` | 18 | 1x Iron Ingot, 3x Obsidian | 1x Obsidian Pendant | 160 |
| `craft_obsidian_ring` | 18 | 1x Iron Ingot, 2x Obsidian | 1x Obsidian Ring | 120 |
| `craft_eclipse_signet` | 20 | 3x Eclipse Opal, 2x Sidereal Glass, 2x Thoughtglass | 1x Eclipse Opal Signet | 308 |
| `craft_opal_pendant` | 24 | 1x Skysteel Ingot, 3x Eclipse Opal | 1x Eclipse Opal Pendant | 208 |
| `craft_opal_ring` | 24 | 1x Skysteel Ingot, 2x Eclipse Opal | 1x Eclipse Opal Ring | 156 |
| `cut_aero_standard` | 25 | 1x Everice, 1x Aero Core | 1x Standard Aero Gem | 108 |
| `cut_aqua_standard` | 25 | 1x Nacre, 1x Aqua Core | 1x Standard Aqua Gem | 108 |
| `cut_arcane_standard` | 25 | 1x Colophon Stone, 1x Arcane Core | 1x Standard Arcane Gem | 108 |
| `cut_astral_standard` | 25 | 1x Sidereal Glass, 1x Astral Core | 1x Standard Astral Gem | 108 |
| `cut_electro_standard` | 25 | 1x Hum Quartz, 1x Electro Core | 1x Standard Electro Gem | 108 |
| `cut_flora_standard` | 25 | 1x Amber, 1x Flora Core | 1x Standard Flora Gem | 108 |
| `cut_geo_standard` | 25 | 1x Quarry Jasper, 1x Geo Core | 1x Standard Geo Gem | 108 |
| `cut_lunar_standard` | 25 | 1x Eclipse Opal, 1x Lunar Core | 1x Standard Lunar Gem | 108 |
| `cut_pyro_standard` | 25 | 1x Obsidian, 1x Pyro Core | 1x Standard Pyro Gem | 108 |
| `cut_sanctus_standard` | 25 | 1x Reliquary Gold, 1x Sanctus Core | 1x Standard Sanctus Gem | 108 |
| `cut_solar_standard` | 25 | 1x Aetherglass, 1x Solar Core | 1x Standard Solar Gem | 108 |
| `cut_umbra_standard` | 25 | 1x Thoughtglass, 1x Umbra Core | 1x Standard Umbra Gem | 108 |
| `craft_aetherglass_locket` | 30 | 3x Aetherglass, 2x Reliquary Gold | 1x Aetherglass Locket | 320 |
| `craft_sidereal_pendant` | 30 | 1x Skysteel Ingot, 3x Sidereal Glass | 1x Sidereal Glass Pendant | 256 |
| `craft_sidereal_ring` | 30 | 1x Skysteel Ingot, 2x Sidereal Glass | 1x Sidereal Glass Ring | 192 |
| `craft_orchard_loop` | 35 | 3x Orchard Amber, 1x Reliquary Gold, 1x Aethersteel Ingot | 1x Orchard Amber Loop | 370 |
| `cut_aero_greater` | 40 | 1x Everice, 1x Aero Heart | 1x Greater Aero Gem | 168 |
| `cut_aqua_greater` | 40 | 1x Nacre, 1x Aqua Heart | 1x Greater Aqua Gem | 168 |
| `cut_arcane_greater` | 40 | 1x Colophon Stone, 1x Arcane Heart | 1x Greater Arcane Gem | 168 |
| `cut_astral_greater` | 40 | 1x Sidereal Glass, 1x Astral Heart | 1x Greater Astral Gem | 168 |
| `cut_electro_greater` | 40 | 1x Hum Quartz, 1x Electro Heart | 1x Greater Electro Gem | 168 |
| `cut_flora_greater` | 40 | 1x Amber, 1x Flora Heart | 1x Greater Flora Gem | 168 |
| `cut_geo_greater` | 40 | 1x Quarry Jasper, 1x Geo Heart | 1x Greater Geo Gem | 168 |
| `cut_lunar_greater` | 40 | 1x Eclipse Opal, 1x Lunar Heart | 1x Greater Lunar Gem | 168 |
| `cut_pyro_greater` | 40 | 1x Obsidian, 1x Pyro Heart | 1x Greater Pyro Gem | 168 |
| `cut_sanctus_greater` | 40 | 1x Reliquary Gold, 1x Sanctus Heart | 1x Greater Sanctus Gem | 168 |
| `cut_solar_greater` | 40 | 1x Aetherglass, 1x Solar Heart | 1x Greater Solar Gem | 168 |
| `cut_umbra_greater` | 40 | 1x Thoughtglass, 1x Umbra Heart | 1x Greater Umbra Gem | 168 |
| `craft_corona_torc` | 44 | 2x Corona Pearl, 2x Colophon Stone, 1x Aethersteel Ingot | 1x Corona Pearl Torc | 460 |
| `craft_eclipse_ring` | 50 | 3x Eclipse Iron, 2x Colophon Stone | 1x Eclipse Iron Ring | 520 |


