# Image prompts — arena backgrounds

⭐ **One per combat zone. 26 backdrops against 275 creatures** — an order of
magnitude less work for arguably more visual impact, because the background is
most of the screen.

⭐ **The prompts are the zones' own `arrival` passages.** They were written as
atmosphere, in second person, and happen to be exactly what an image generator
needs: a claim about what a place looks like. Nothing was invented here.

⚠️ **A background must LOSE to the sprites.** The failure mode is a beautiful
backdrop that makes the creature standing on it unreadable, and creature
legibility is what the fight depends on. The style line asks for dark, muted
and low-contrast, and `--mode background` darkens and desaturates again on top.

⚠️ **"No creatures" is in every prompt on purpose.** A generator given a forest
description will put a deer in it, and that deer will fight the sprite standing
in front of it.

**Generate at 1920×1080** (16:9 — the pipeline cover-crops, so anything wider
is fine and anything squarer gets cut).

Save as `art/source/backgrounds/<zone_id>.png`, then:

```sh
python3 tool/pixelate.py --zone <zone_id> --mode background
```

⚠️ Text comes from `arrival` in `lib/game/world.dart`. Change it there and
regenerate this file, or the two drift.

---

## Whispering Woods

`whispering_woods.png` — *Lv 1–5*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Sun-dappled woods that murmur when nothing is moving them. The murmur is not wind. It comes from the ground, from the roots crossing under the path, and it stops the moment you stand still to listen.
```

## Glimmerbrook

`glimmerbrook.png` — *Lv 3–8*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Springs and shallows east of Aldermere, bright enough to hurt. The brook runs over pale stones and throws the light back at you in pieces. Fish hang in the current without swimming. The water is colder than the season should allow.
```

## Cinderpeak Foothills

`cinderpeak_foothills.png` — *Lv 6–11*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The first rise north, where the ground is warm through your boots. The grass gives out and the slope turns to grey grit that shifts under you. Somewhere above, the mountain is breathing. The air tastes of struck flint.
```

## Thornmire

`thornmire.png` — *Lv 8–13*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Where the woods drown in the brook's outflow. The path becomes a suggestion, then a rumour, then water. Trees stand in it up to their knees and have made peace with that. Everything green here is winning.
```

## Ashfall Vale

`ashfall_vale.png` — *Lv 10–14*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Downwind of the cone: the burn scar where ash falls on forest. Grey settles on every leaf until the whole valley looks like a charcoal drawing of itself. New shoots are already pushing up through it. Fire came through here, and something is arguing about whether it won.
```

## Old Quarry

`old_quarry.png` — *Lv 15–19*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Cut into the range's southern flank, and cut too deep. Terraces step down into shadow, each one squarer than anything nature makes. The tool marks are old. Whatever was quarried out of here left a shape, and the shape has started to move.
```

## Stormcliff Coast

`stormcliff_coast.png` — *Lv 17–22*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Where the western ocean's weather hits a wall and has nowhere to go. The cliffs take the whole weight of it. Spray comes up further than it should and your hair lifts before you hear the crack. The rock is scorched in long vertical lines.
```

## Windward Steppe

`windward_steppe.png` — *Lv 19–24*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A high tableland east of the crest, scoured flat. Nothing here is taller than your knee, and everything leans the same way. The wind does not gust; it simply blows, and has been blowing since before there was anyone to notice.
```

## Frostfell Pass

`frostfell_pass.png` — *Lv 21–26*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The way through. Sea air lifted over the crest and frozen there. The pass is a white corridor between two black walls. Your breath goes up and does not come down. The road is under here somewhere, and other people have been sure of that too.
```

## Thunderspire Peaks

`thunderspire_peaks.png` — *Lv 23–28*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The summit line where coastal storm meets steppe wind. You are inside the weather rather than under it. The cloud is lit from within at intervals, and the intervals are getting shorter. Metal hums.
```

## The Molten Deep

`the_molten_deep.png` — *Lv 25–29*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Under the quarry, under the mountain, under the sea's level. The quarry's deepest gallery keeps going after the tool marks stop. The rock gets warm, then hot, then lit from below. There is a floor down here that moves like water because it is not water.
```

## The Kiln Desert

`the_kiln_desert.png` — *Lv 30–34*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A cold high desert in the range's rain shadow, and the sunniest ground in the world. The air is too thin to hold heat, so the sun burns while the wind bites. There is no shade anywhere and no water for a day\
```

## The Mirrormere

`the_mirrormere.png` — *Lv 32–37*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A high still lake that holds the moon better than the sky does. Not a ripple. The surface gives you back the mountains, the stars, and the moon at a size the moon has no right to be. Walking the shore, you are careful not to look down for too long.
```

## Starfall Basin

`starfall_basin.png` — *Lv 34–39*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A crater field, preserved because nothing grows to cover it. Bowl after bowl in the pale ground, each with something at the bottom that is not from here. Nothing has grown over them because nothing grows. At night the sky is so clear it looks like a threat.
```

## Tidewrack Shoals

`tidewrack_shoals.png` — *Lv 36–40*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Tides that obey the moon exactly, on the northern shore. The water goes out further than seems survivable and comes back faster. What it uncovers has been down there a long time. Everything is timed to something overhead.
```

## The Sunless Reach

`the_sunless_reach.png` — *Lv 38–42*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The Scarp's north face. Direct sun never reaches the floor. You come over the crest out of glare into a valley that has never been lit. The rock is the same rock. The desert is a thousand feet away and on the other side of the world.
```

## The Shattered Orrery

`the_shattered_orrery.png` — *Lv 40–44*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A broken model of the heavens, still trying to run. Rings the size of bridges, half of them fallen, and the fallen half still turning. The arcing is not weather; it is the mechanism. Something is being calculated and has been for a very long time.
```

## Hallowmarch

`hallowmarch.png` — *Lv 45–49*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The Vault's south flank: a consecrated causeway up the only side that thaws. A raised road, and someone built it. The sun reaches this face for a few hours and the meltwater runs beside you the whole way. Every mile or so there is a marker, and every marker has been maintained.
```

## The Umbral Wastes

`the_umbral_wastes.png` — *Lv 47–51*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The Vault's north face. No direct sun at any hour of any day. You round the shoulder and the light stops. Not dusk — an absence with an edge to it. The ice here has never melted and holds its shape like something that has been thought about.
```

## The Reliquary Deep

`the_reliquary_deep.png` — *Lv 52–56*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A vault bored through the mountain from the lit side to the dark. The door is on the warm flank and the far end opens onto the ice. In between, a corridor that someone consecrated and someone else did not leave alone. It is warmer in the middle than at either end.
```

## The Sealed Garden

`the_sealed_garden.png` — *Lv 49–53*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A garden nobody has been let into for a very long time. The wall is low enough to see over and that is the whole cruelty of it. Inside, everything is in leaf and in season at once. The gate is shut, the guard is still at the gate, and the faith that posted him has been gone for centuries.
```

## The Glass Archive

`the_glass_archive.png` — *Lv 43–47*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. They wrote it in light, and light does not keep. Lenses on every roof, and all of them still aimed. Around midday the hillside fills with writing you can almost read, and by the time your eyes adjust it has moved on. Whatever they recorded here, they recorded onto the one thing that will not hold still.
```

## The Buried Sky

`the_buried_sky.png` — *Lv 46–50*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The oldest rock in the world, and it is full of stars. You climb to the top of everything in order to go down. The shaft cuts through band after band of stone, and every band holds a scatter of light in it. None of the patterns match the sky you walked in under.
```

## The Collapsed Academy

`the_collapsed_academy.png` — *Lv 50–54*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. A school that read too far, and left. It is not ruined so much as unfinished in the wrong direction. Staircases arrive at rooms that were never built. The syllabus is still on the wall and the last three items on it are not in any language you have.
```

## The Unwritten Library

`the_unwritten_library.png` — *Lv 54–58*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. Knowledge that eats its keeper. The shelves are still filling. Every book here is being written right now, by nobody. The shelves go up past where a ceiling would be. Something is taking dictation and it would like your name for the record.
```

## The Eclipsed Citadel

`the_eclipsed_citadel.png` — *Lv 58–60*

```
Wide cinematic landscape illustration, painterly, environment only. Muted and desaturated, low contrast, dark overall value so that figures placed in front of it remain clearly readable. Deep shadow in the foreground, light held in the middle distance. NO creatures, NO people, NO characters, NO text, NO borders, NO UI. Empty scene. The door back into the world, and the thing standing in it. Below it, through a gap in nothing, is the summit of the mountain you could not climb. The Citadel is between you and it. That is what the name has always meant.
```
