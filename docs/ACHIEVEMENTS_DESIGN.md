# Masters of Magic 2 — Achievements & Character Progress

Status: 🔨 **stage 1 built (2026-10-01)** — the model, the four lifetime
counters and Claim (see the rulings below and §11). ✅ **Stage 2's catalogue
is built** — 171 entries (§5). 📝 The screen redesign is the rest of stage 2.
Requested 2026-07-28, revised with Christian's rulings the same day.

Two systems, documented together because one is useless without the other:

1. **Character progress** (§2) — the record of what a character has done.
   Worth building on its own merits; achievements are only its first consumer.
2. **Achievements** (§4 onward) — named milestones read *from* that record.

---

## ✅ Rulings 2026-10-01

Christian's rulings for the stage-1 build. Each amends the section named.

1. ✅ **Rewards are CLAIMED, not auto-granted** (amends §6, §7.3). Earning
   marks the entry earned and toasts, as before; the player then presses
   **Claim** on the Achievements screen (or **Claim all**) to receive the
   reward. ✅ Built: `PlayerProfile.claimedAchievements` (the ids claimed),
   `GameState.claimAchievement(id)` / `claimAllAchievements()` — each one
   write. ⭐ The load-time sweep still *earns* silently and pays nothing, so a
   returning player finds a pile to claim. ⚠️ Every save from before the
   ruling reads as "claimed nothing", so everything already earned is owed
   once.
2. ✅ **Reward table = §6 as written**, keyed on points: 5 pt → 100 XP · 50
   gold; 10 → 250 XP · 150 gold; 25 → 750 XP · 500 gold · 1 RP; 50 → 2,000
   XP · 1,500 gold · 5 RP; 100+ → 5,000 XP · 5,000 gold · 25 RP (a 150-pt
   entry pays the 100+ row). RP = `PlayerProfile.resonancePrisms`. 🚫 No
   titles or cosmetics this pass — titles are deferred and §6.1 stands
   untouched. ✅ Built: `Reward.forPoints` in `achievements.dart`; claimed
   gold goes through `earnGold`, so it counts toward Wealth.
3. ✅ **Mastery thresholds: 250 / 1,000 / 5,000 / 10,000 / 25,000 charges**
   per element, tiers I–V (amends §3.1's provisional table; a duel is 30–40
   charges). Consts, for Christian to tune:
   `Achievements.masteryThresholds`.
4. ✅ **The lifetime counters live on the CHARACTER document**, not in a
   `progress/` subcollection — §2.3's amendment, extended. See **§2.4** for
   each counter's bound.
5. ✅ **Hidden entries exist**: `hidden: true` shows `???` and no blurb
   until earned. 📝 The catalogue *content* (≈160 entries) is stage 2; stage
   1 built the shape (`points`, `family` + `tier`, `hidden`) and migrated the
   twelve shipped entries (ids unchanged — they are on disk since release 9).
6. ✅ **Wealth is four entries** (amends §5.3): **Young Money** 10,000 gold
   earned · 5 pt (new) · **Fat Stacks** 100,000 · 10 pt (was 1,000 · 5) ·
   **Big Money** 1,000,000 · 25 pt · **Tres Commas** 1,000,000,000 · 100 pt
   (its ❓ in §10 stands). 📝 Doc only — the entries are stage-2 content.

---

7. ✅ **Academy charges count toward mastery** (Christian, 2026-10-01, on
   stage 1's flag). An Academy bout still pays no XP, gold or win — the
   character stays untouched in every other respect — but its charge tally
   is banked through `GameState.bankCharges` in one write. What you lean on
   is what you lean on, whichever room you were in.

## 1. What achievements are for

⭐ **An achievement names something the player already did and makes it
legible.** It is a record, not a quest. That decides everything downstream: an
achievement must never send a player off to do something they would not
otherwise do, or the campaign is competing with a checklist for their
attention.

⚠️ **Non-goal: retention mechanics.** No dailies, no login streaks. Those are a
different system with a different purpose, and mixing them in turns a record of
play into a job.

⚠️ **One deliberate exception to "record, not quest":** the grindy completion
achievements (§5.3) *are* meant to be chased. They are the long tail for
players who have finished everything else, and they are marked as such.

---

## 2. Character progress — the data model

✅ **Ruling: progress is CHARACTER-level, never account-level.** If an account
ever holds multiple characters, they are **100% separate** — separate
progress, separate achievements, separate everything. A character is the unit
of play; an account is just the login.

⚠️ **This is a bigger architectural point than it looks, and today the code
does not make the distinction at all**: `PlayerProfile` is loaded from
`players/{uid}` and *is* both the account and the character. Nothing needs to
change yet, but the split should be designed before anything else writes to
that document, because retrofitting it later means migrating every save.

### 2.1 Shape

```
players/{uid}/characters/{characterId}          <- the character (today: the profile)
players/{uid}/characters/{characterId}/progress/{docId}   <- subcollection
```

⭐ **A subcollection, not fields on the character.** Three reasons:

- **Write volume.** Charge counts and kill tallies change constantly; the
  character document is read on every app open. Keeping the hot, chunky
  counters out of it stops every save from rewriting them.
- **Unbounded growth.** Kill counts are one entry *per enemy type* and the
  bestiary is not written yet. A document has a 1 MiB ceiling; a
  subcollection does not.
- **Partial reads.** The duel screen never needs the kill tally. The
  achievements screen does.

Proposed documents inside `progress/`:

| Doc | Holds |
|---|---|
| `zones` | per-location: cleared, times cleared, enemies seen/defeated, drops seen |
| `charges` | per-element lifetime charge count (§2.2) |
| `kills` | per-enemy-type defeat count 📝 (needs the bestiary) |
| `totals` | lifetime gold earned, duels, travel time, XP |

### 2.2 Charges — the real elemental mastery

⭐ **Christian's framing, adopted: mastery is charges, not wins.** "Won a duel
using Pyro" is a formality you can satisfy once and forget. **Charges
accumulated** is a genuine record of what a player actually leans on, and it
cannot be gamed by a single throwaway duel.

```
charges: { pyro: 4820, aqua: 1200, umbra: 0, ... }   // lifetime, per element
```

⚠️ **Do not write per charge.** A charge happens several times per duel per
player; a Firestore write each time would be both slow and expensive.
**Accumulate in memory during the duel and flush once at the end**, alongside
the existing XP/gold write. A duel abandoned mid-way loses its charges —
acceptable, and far better than the write amplification.

### 2.3 Zone progress

Per location, three independent facts — because §5.2 makes three separate
achievements out of them:

```
zones: {
  whispering_woods: {
    cleared: true,              // beaten at least once
    clearCount: 7,
    enemiesDefeated: { ... },   // which distinct enemy types 📝 needs bestiary
    dropsSeen: [ ... ],         // which distinct items have dropped 📝 needs items
  },
}
```

#### ✅ Amendment (2026-08-02) — `cleared` lives on the CHARACTER, the rest does not

✅ **Built:** `PlayerProfile.zoneClears` is a `Map<String, int>` of zone id →
times cleared, with `hasCleared()` and `clearCountFor()`. Written by
`GameState.recordDuelResult(bossDefeated: …)`.

⚠️ **That contradicts §2.1's "a subcollection, not fields on the character" —
deliberately, and only for this one field.** §2.1 gives three reasons to move
zone progress off the character, and clear counts fail all three:

| §2.1's reason | Does `zoneClears` trigger it? |
|---|---|
| **Write volume** | ❌ At most once per clear — about 106 writes over a whole playthrough, piggybacked on the XP/gold write that already happens |
| **Unbounded growth** | ❌ Hard-bounded at **26 entries**, one per combat zone. A few hundred bytes |
| **Partial reads** | ❌ Inverted — the **map wants this on every app open**, so a subcollection would mean a second read on the hottest path |

⭐ **`enemiesDefeated` and `dropsSeen` still belong in `progress/`** — those are
the unbounded ones §2.1 was written for (275 creature types, and an item log
with no ceiling at all). ⚠️ **The precedent to guard is exactly that:** the
danger is someone adding `enemiesDefeated` next to `zoneClears` because that is
where clears already live.

⭐ **A count, not a flag**, because two features need the number: this doc's
`clearCount`, and ENEMIES §2e's repeat-clear encounters.

⚠️ **Nothing sets it yet.** `bossDefeated` is a caller-supplied parameter and
no caller passes `true`, because Phase-1 adventures are a single ordinary duel
with no boss. Wiring it to "won any duel here" would have been wrong — see
IMPLEMENTATION_PLAN.

#### ⭐ What the pool structure costs a completionist (measured)

A zone holds **11 creature types**: 5 commons, 4 mini-bosses, 2 bosses. But a
run draws only **2 of the 4 minis and 1 of the 2 bosses** (GAME_DESIGN §3d), so
Purge cannot be done in one visit:

| Target | Expected clears |
|---|---|
| Both bosses | **3.0** |
| All four mini-bosses | **3.8** |
| ⭐ **Every elevated enemy in one zone** | **4.2** |
| Purge across all 25 rostered zones | **~106 clears** |

⭐ **This is what makes the random pool matter.** Without a completionist
reason the pool is only variety; with Purge it becomes a target, and the
"come back and run it again" loop the resource areas already want (WORLD_DESIGN
§4b) gets a second reason to exist. ✅ ~4 clears per zone is a real ask without
being a wall.

⚠️ **The Collector tier is still fully blocked** — "every possible drop" needs
items, drop tables, and a permanent *seen* log that is separate from inventory
(you can sell a thing and must not lose the credit). None of that exists.
📝 (2026-10-01: the *seen* log now exists — `itemsSeen`, §2.4 — though it is
per character, not per zone.)

### 2.4 ✅ Amendment (2026-10-01) — the lifetime counters live on the CHARACTER

✅ **Built**, ruling 4 above. Five fields on `PlayerProfile`, each always
written (even empty or zero), each absent-reads-as-empty on an older save:

| Field | Holds | Bound | Written by |
|---|---|---|---|
| `charges` | element id → lifetime charges, the local player's only | **12 keys**, one per element | the duel's result write (`recordDuelResult`; `fleeEncounter` for an escape) — ⭐ once per duel, never per charge |
| `goldEarned` | lifetime gold **gained** (duel rewards, vendor sales, claims) | **one int** | `PlayerProfile.earnGold`, the only way gold is gained |
| `itemsSeen` | every item def id that has ever dropped for this character | **≤265 ids** — the item catalogue | `winEncounter`, when the loot is rolled |
| `travelSeconds` | lifetime seconds on the road | **one int** | `settleTravel` (the whole trip, on arrival); `cancelTravel` (the part walked) |
| `claimedAchievements` | ids whose reward has been taken | **≤ the catalogue** (171) | `claimAchievement` / `claimAllAchievements` |
| `biggestWinLevelGap` | the most levels a beaten opponent stood above this character (stage 2, for Giant Slayer §5.4) | **one int** | `recordDuelResult`, on a win — never down |

The same three tests §2.3 applied, and the same answer:

| §2.1's reason | Do these trigger it? |
|---|---|
| **Write volume** | ❌ Each rides a write that already happens — the duel result, the shop settle, the loot roll, the arrival, the claim. None adds a write of its own |
| **Unbounded growth** | ❌ Every one is bounded (table above) — a few KiB at the very most, against a 1 MiB ceiling |
| **Partial reads** | ❌ The Profile reads `itemsSeen` and the claimable count on every open; a subcollection would be a second read there |

⚠️ **The precedent still to guard is §2.3's:** per-*enemy* kill tallies and
per-*zone* drop logs (`enemiesDefeated`, `dropsSeen`) remain unbounded in
shape and do not belong next to these. `itemsSeen` is safe only because it is
one flat set over a finite catalogue.

⭐ **Gold earned, not gold held** — §5.3's reason. A purchase is a plain
`gold -=` and never lowers `goldEarned`; the shop settle splits the basket's
net into the sale (earned) and the purchase (spent), so the purse still moves
by exactly the quoted net.

---

## 3. The shape of an achievement

```
Achievement {
  id            stable string, never reused        'clear_whispering_woods'
  family        groups a tiered set (§3.1)         'pyro_mastery'
  tier          1-5 within a family, else null     3
  name          player-facing                      'Pyro Mastery III'
  description   what earns it                      'Charge Pyro 5,000 times'
  category      grouping for the list              Category.mastery
  target        for progressive achievements       5000
  progress      (CharacterProgress) -> int         (p) => p.charges[pyro]
  reward        §6                                 Reward(xp: 500, gold: 500, rp: 1)
  hidden        spoilers stay hidden               false
  points        arcade-style weight                25
}
```

**Earned state** lives on the character: `Map<String, DateTime> unlocked` —
id → when.

⭐ **Store the timestamp, not a bool.** Same cost, and it buys "earned on your
third day" plus a chronological feed later. A bool forecloses both and cannot
be recovered retroactively.

⚠️ **Progress is derived from `progress/`, never stored on the achievement.** A
stored counter beside the truth it mirrors can only drift, and a drifted
counter is unfixable without a migration.

### 3.1 Tiers ✅

Tiered families are **N discrete achievements sharing a `family`**, not one
achievement with a level. That is what both platform stores expect, it lets
each tier carry its own reward, and it keeps "earned" a simple set.

**Example — Pyro Mastery** (numbers 📝 provisional, to be tuned in a later
session — ✅ **superseded 2026-10-01**: the thresholds are 250 / 1,000 /
5,000 / 10,000 / 25,000, ruling 3 above; ✅ points 5 / 10 / 25 / 25 / 50,
built in stage 2 — §5.2):

| Tier | Charges | Points |
|---|---|---|
| I | 500 | 5 |
| II | 2,000 | 10 |
| III | 5,000 | 25 |
| IV | 15,000 | 25 |
| V | 50,000 | 50 |

⚠️ **Twelve elements × 5 tiers = 60 achievements from this family alone**, and
the catalogue is ~140 in total. Two consequences worth deciding on before
building: the list UI must **collapse a family to its current tier** rather
than listing all five, and §8's platform mirroring cost (each entered by hand,
twice, with art) becomes the dominant cost of this feature.

---

## 4. Triggers

⭐ **One evaluation pass over pure predicates, not scattered `unlock()` calls.**
After any progress mutation, test every unearned achievement against the
character's progress.

- No unlock can be *missed* because a code path forgot to call it.
- Achievements added later are **earned retroactively** by existing
  characters — a strong property, impossible with scattered calls.
- Each rule is one testable pure function.

⚠️ **Some triggers need duel-scoped facts** the progress record does not keep
("win without taking damage"). Those need a `DuelSummary` passed into the
result handler. Deferred to a second pass — everything else works without it.

---

## 5. The catalogue ✅ built (stage 2, 2026-10-01)

✅ **Built: 171 entries.** `Achievements.all` (`lib/game/achievements.dart`)
stitches them together in this section's order; the content lives in
`lib/game/achievements/`, one file per section (`campaign.dart`,
`mastery.dart`, `wealth.dart`, `duelling.dart`, `world.dart`). The twelve
entries shipped in release 9 keep their ids and meanings and sit where they
fit. Laws: `test/achievement_catalogue_test.dart`.

⭐ **Generated where the shape is uniform.** The 78 campaign entries come
from `World.locations` (every location with an adventure) and the 60
mastery tiers from `MagicElement.values` × `Achievements.masteryThresholds`;
only their **names** are hand-written (§5.1a). A combat zone added without a
names row fails at load.

| Category | Entries | Arithmetic |
|---|---|---|
| Campaign | **86** | 5 shipped + 26 zones × 3 + 3 capstones |
| Mastery | **62** | 12 elements × 5 tiers + Twelvefold + Elementalist |
| Wealth | **4** | Young Money … Tres Commas |
| Dueling | **11** | 3 shipped + Champion, Giant Slayer, Procarius Falls + Vanquisher I–V |
| World | **4** | Wayfarer, Cartographer, The Empyrean, Ten Hours on the Road |
| Craft | **2** | shipped (Journeyman, Artisan) |
| Ladder | **2** | shipped (On the Ladder, Regular) |
| **Total** | **171** | |

**Hidden** (§7.1, `???` until earned) — exactly four: `extinction`,
`nothing_left_to_find`, `tres_commas`, `procarius_falls`.

**Families** (§3.1) — fourteen: `mastery_<element>` × 12 (tiers 1–5),
`wealth` (1–4), `vanquisher` (1–5). Every family's tiers run 1..n.

### 5.1 Campaign — three achievements per zone ✅ built

✅ **Ruling: "cleared" is three separate things, not one.** Per zone:

| Achievement | Id | Earned by | Points |
|---|---|---|---|
| **Clear** — "Woods Walker" | `clear_<zone>` | The zone cleared once (`zoneClears`) | 10 |
| **Purge** — "Nothing Left Standing" | `purge_<zone>` | **Every creature** of the zone slain at least once (`bestiary`), progress n/11 | 25 |
| **Collector** — "Everything the Woods Gave" | `collect_<zone>` | **Every possible drop** of the zone seen (`itemsSeen`), progress n/total | 50 |

⭐ **Collector's set is the zone's drop TABLES**: `DropTable.possibleDrops`
across the zone's eleven creatures, motes included. ⚠️ **`KeyDef`s are
excluded** — the proofs and the Ethereal thirds are quest items; a character
who carried one before `itemsSeen` existed could never see it drop again.
📝 The boss's guaranteed zone gear and the empty-roll consolation are not in
any table (`rollKill` adds them), so Collector does not ask for them.

⚠️ **Purge counts that zone's roster only** — a kill anywhere else never
moves another zone's bar — and counts creatures, not kills.

⚠️ **The Collector tier is intentionally grindy and genuinely hard**, and is
the one place this system knowingly breaks the "record, not quest" rule (§1).
It is the long tail. ⚠️ It is **hostage to drop rates**: the rates and this
achievement must be tuned *together*, or it becomes the reason someone quits.

26 zones × 3 = **78 achievements**, plus capstones:

| Achievement | Id | Earned by | Points |
|---|---|---|---|
| **The Known World** | `the_known_world` | All 26 cleared | 100 |
| **Extinction** 🔒 | `extinction` | All 26 purged | 100 |
| **Nothing Left to Find** 🔒 | `nothing_left_to_find` | All 26 collected | 150 |

📝 Titles and cosmetics on the capstones wait on §6.1 (ruling 2, 2026-10-01).

### 5.1a The 78 names ✅

Blurbs follow one pattern per kind: Clear "*Zone* cleared to its boss.",
Purge "Every creature of *zone* slain at least once.", Collector
"Everything *zone* can drop, seen at least once." **Total** is the
Collector's drop-set size, keys excluded.

| Zone (id) | Clear | Purge | Collector | Total |
|---|---|---|---|---|
| `whispering_woods` | Woods Walker | Nothing Left Standing | Everything the Woods Gave | 9 |
| `glimmerbrook` | Brook Wader | The Brook Runs Quiet | All That Glimmers | 8 |
| `cinderpeak_foothills` | Foothill Climber | Cold Ashes | Picked from the Cinders | 6 |
| `thornmire` | Mire Strider | The Mire Lies Still | Dredged from the Mire | 10 |
| `ashfall_vale` | Vale Wanderer | The Vale Swept Clean | Sifted from the Ash | 11 |
| `old_quarry` | Quarry Scrambler | Not a Stone Stirring | Quarried Clean | 8 |
| `stormcliff_coast` | Coast Runner | The Storm Breaks | Storm Salvage | 9 |
| `windward_steppe` | Steppe Rider | Nothing on the Wind | Gathered on the Wind | 8 |
| `frostfell_pass` | Frost Treader | Nothing Left but Snow | Dug from the Snow | 12 |
| `thunderspire_peaks` | Spire Scaler | The Thunder Stops | Struck Lucky | 12 |
| `the_molten_deep` | Deep Delver | Nothing Left but Slag | Pulled from the Fire | 12 |
| `the_kiln_desert` | Dune Crosser | Only Sand Remains | Fired in the Kiln | 9 |
| `the_mirrormere` | Mere Skimmer | Nothing in the Mirror | Everything the Mere Reflected | 10 |
| `starfall_basin` | Basin Roamer | The Stars Go Out | Every Fallen Star | 10 |
| `tidewrack_shoals` | Shoal Sailor | The Tide Goes Out | Flotsam and Jetsam | 13 |
| `the_sunless_reach` | Sunless Rambler | Nothing in the Dark | Found in the Dark | 13 |
| `the_shattered_orrery` | Orrery Drifter | The Gears Stop Turning | Every Last Cog | 13 |
| `hallowmarch` | March Pilgrim | The March Ends | Every Offering | 8 |
| `the_umbral_wastes` | Shadow Trekker | Not a Shadow Moves | Everything the Shadows Held | 9 |
| `the_reliquary_deep` | Vault Descender | Nothing Left to Guard | Every Relic | 13 |
| `the_sealed_garden` | Garden Trespasser | The Garden Weeded | The Full Harvest | 13 |
| `the_glass_archive` | Glass Stepper | Nothing Behind the Glass | The Archive Catalogued | 14 |
| `the_buried_sky` | Sky Burrower | The Sky Stays Buried | Everything the Sky Buried | 13 |
| `the_collapsed_academy` | Rubble Crawler | Class Dismissed | Full Marks | 8 |
| `the_unwritten_library` | Stack Rover | Not a Page Turns | Every Unwritten Page | 14 |
| `the_eclipsed_citadel` | Eclipse Chaser | The Citadel Empty | Everything the Eclipse Hid | 35 |

⚠️ **A combat zone's id is now an achievement id too.** `World.renamedIds`
rescues a stored location, not an earned `clear_<zone>`; never rename a
combat zone.

### 5.2 Mastery — charges ✅ built

- **`<Element>` Mastery I–V** — 12 elements × 5 tiers (§3.1). **60**. Id
  `mastery_<element>_<tier>`, family `mastery_<element>`, blurb
  "*Element* charged *n* times.", progress charges/threshold.

| Tier | Charges (ruling 3) | Points |
|---|---|---|
| I | 250 | 5 |
| II | 1,000 | 10 |
| III | 5,000 | 25 |
| IV | 10,000 | 25 |
| V | 25,000 | 50 |

- **"Twelvefold"** (`twelvefold`) — Tier I in **all twelve**. 100 points.
  ⭐ The flagship: the one achievement that asks a player to leave the loadout
  they are comfortable in, which is exactly what the twelve-element design
  most wants.
- **"Elementalist"** (`elementalist`) — all 5 element slots unlocked. 25.
  ⚠️ Read off the **schedule** (`Progression.elementsAtLevel`, the fifth slot
  at level 40), not the usable count: slots are not enforced yet, so
  `usableElementsAtLevel` is five at level 1 and would give it away.

### 5.3 Wealth ✅ built

✅ **Four entries (ruling 6, 2026-10-01).** Family `wealth`, tiers 1–4,
progress `goldEarned`/threshold.

| Achievement | Id | Earned by | Points |
|---|---|---|---|
| **Young Money** | `young_money` | Earn 10,000 gold | 5 |
| **Fat Stacks** | `fat_stacks` | Earn 100,000 gold | 10 |
| **Big Money** | `big_money` | Earn 1,000,000 gold | 25 |
| **Tres Commas** 🔒 | `tres_commas` | Earn 1,000,000,000 gold | 100 |

⚠️ **Lifetime gold *earned*, not gold *held*.** Held balance would punish
spending — a player who invests in gear would watch progress go backwards, and
the achievement would quietly discourage engaging with the economy.
✅ `PlayerProfile.goldEarned`, on the character (§2.4).

❓ **Is a billion reachable?** That depends entirely on an economy that does
not exist yet. If end-game income is ~10k/hour, Tres Commas is 100,000 hours
and is not an achievement but a joke. Keep the name, set the number once the
economy is real. 📝 Hidden meanwhile.

### 5.4 Dueling ✅ built

| Achievement | Id | Earned by | Points |
|---|---|---|---|
| **First Blood** | `first_blood` | Win one duel (shipped) | 5 |
| **Tenfold** | `tenfold` | Win 10 (shipped; §5.4's "Duellist") | 10 |
| **Centurion** | `centurion` | Win 100 (shipped; §5.4's "Veteran") | 25 |
| **Champion** | `champion` | Win 500 | 50 |
| **Giant Slayer** | `giant_slayer` | Beat an opponent 10+ levels above you | 25 |
| **Procarius Falls** 🔒 | `procarius_falls` | Slay Procarius in the Eclipsed Citadel | 50 |
| **Vanquisher I–V** | `vanquisher_1` … `_5` | 50 / 250 / 1,000 / 2,500 / 5,000 creatures slain | 5 / 10 / 25 / 25 / 50 |

⚠️ Wins are `duelsWon` — the geared and campaign record. Academy wins are a
separate record and do not count.

⭐ **Giant Slayer has the one new counter**:
`PlayerProfile.biggestWinLevelGap` — the best (opponent level − own level
going in) over every win, written by `GameState.recordDuelResult`. ⚠️
Measured against the level **before** the win's XP, so a win that levels you
up still counts its full gap. 📝 Not retroactive: wins before the field
existed left no gap behind.

⚠️ **Procarius Falls reads the bestiary id `procarius_the_eclipsed`** — the
Citadel's last boss — not the duelling persona id `procarius`. A practice
bout against the persona is not the finale.

Vanquisher counts **every kill** (`bestiary[*].slain` summed, repeats
included); family `vanquisher`.

### 5.5 World ✅ built

| Achievement | Id | Earned by | Points |
|---|---|---|---|
| **Wayfarer** | `wayfarer` | 10 places discovered | 10 |
| **Cartographer** | `cartographer` | Every `World.locations` id discovered (35 today) | 50 |
| **The Empyrean** | `the_empyrean` | Zenith discovered | 25 |
| **Ten Hours on the Road** | `ten_hours_on_the_road` | `travelSeconds` ≥ 36,000 (progress in whole hours) | 25 |

⚠️ **Two of the names first written here were already taken** by stage-1
Campaign entries with other meanings — `beyond_the_veil` is Rimeholt's gate
and `the_long_road` is fifteen clears. Their World counterparts are **The
Empyrean** and **Ten Hours on the Road**. ⚠️ Discovery counts only ids that
name a real place, so a retired id on an old save never counts.

### 5.6 Craft and Ladder (shipped)

**Journeyman** (`journeyman`, one craft at level 5, 10) · **Artisan**
(`artisan`, level 10, 25) · **On the Ladder** (`rated`, one rated duel, 5) ·
**Regular** (`ladder_regular`, ten rated duels, 10). Unchanged by stage 2.

---

## 6. Rewards ✅

**Rewards are XP, gold, RP, titles and cosmetics — never power.**

✅ **XP is a reward type** (Christian's ruling). ⭐ This is more useful than it
looks: it lets **enemy XP stay flat** while a *first-clear achievement*
supplies the "you beat something new" bonus. The reward for novelty then lives
in the achievement system rather than in the combat reward formula, which
keeps the grind curve and the discovery curve independently tunable.

✅ **Ruling (2026-07-28): the two are complementary, not duplicative.** They
answer different questions.

| | Question it answers | Repeatable? |
|---|---|---|
| `xpForDuel` (`winXp + 10 × level`) | *How tough was that fight?* | ✅ every time |
| Achievement XP | *Was that the FIRST time?* | 🚫 once, ever |

Grinding a level-20 foe pays the same every time — that is the steady income
curve. The achievement fires **once**, the first time a *major* enemy falls
(mini-boss, boss, or a named duelling AI).

⭐ **The intended consequence: clearing an area for the first time pays out
several achievements at once** — first clear of the area, first defeat of its
boss, likely a mastery tier and a purge tier alongside. That spike is the
point. Finishing a region should feel like a milestone, and stacking the
one-time rewards on the same moment is what makes it one.

| Tier | Reward |
|---|---|
| 5 pt | 100 XP · 50 gold |
| 10 pt | 250 XP · 150 gold |
| 25 pt | 750 XP · 500 gold · 1 RP |
| 50 pt | 2,000 XP · 1,500 gold · 5 RP |
| 100 pt+ | 5,000 XP · 5,000 gold · 25 RP · **often** a title or cosmetic |

✅ **Big achievements do not *always* carry a title or cosmetic** — those are
supplemental, reserved for the ones that deserve to be seen.

⚠️ **RP as a reward is consistent with the monetization rule** (ITEMS §3.6:
nothing bought with RP may be
unobtainable with gold — and achievement RP is a *grant*, not a purchase). Giving non-payers a taste
of the acceleration tier argues *for* the purchase. Amounts stay small enough
that they cannot substitute for buying.

🚫 **Never rewarded:** equipment, materials, elements, spells, slots. Anything
touching power belongs to the campaign and the crafting economy.

### 6.1 Titles ✅

✅ **A title is a prefix or a suffix, and a player may equip one of each at
once.**

```
Character { String? titlePrefix; String? titleSuffix; }
→  "Archmage Corvin the Unbroken"
```

- Titles are **earned then chosen** — earning one adds it to a wardrobe, it
  does not overwrite what is equipped.
- Both slots are optional; a bare name is always valid.
- ⚠️ Titles are **player-visible text attached to a player-chosen name**, so
  they go through the same moderation path as names. Earned titles are a fixed
  vocabulary, which makes this easy — keep it that way rather than ever
  allowing free text.

---

## 7. Where the player sees them

### 7.1 Privacy ✅

✅ **Ruling: your points are public; your individual achievements are not.**

| Visible to others | Private |
|---|---|
| Total points · equipped titles | Which achievements you hold, and which you don't |

⭐ This is a good call and worth stating the reason: a public list turns
achievements into a comparison of completeness, which is exactly the
completionist pressure §1 is trying to avoid. A single number reads as
seniority rather than as a checklist someone is behind on. It also means
**hidden/spoiler achievements stay hidden** — nobody learns the ending from a
friend's profile.

### 7.2 The list

A dedicated **Achievements screen** off the profile/social area — not a
bottom-tab. Five tabs is already the limit of that bar, and this is somewhere
you *visit*, not somewhere you work.

```
┌─────────────────────────────────────┐
│  Achievements          1,240 points │
│  ▓▓▓▓▓▓▓░░░░░░░░░░░░   38 / 140     │
├─────────────────────────────────────┤
│  Campaign                   19 / 72 │
│   ✅ Woods Walker      +250xp +150g │
│      Earned 3 Aug 2026              │
│   ⬜ Nothing Left Standing   ▓▓░ 6/9│
│   🔒 ???                            │
├─────────────────────────────────────┤
│  Mastery                    11 / 61 │
│   🔥 Pyro Mastery III   ▓▓▓░ 4.8k/5k│  <- family collapsed to current tier
└─────────────────────────────────────┘
```

- A **tiered family shows one row** — its current tier and progress toward the
  next — not five rows (§3.1).
- Earned rows show the date and what they paid.

### 7.3 The moment of earning

A **toast**, not a modal — it lands mid-flow, often right after a duel, and a
modal there interrupts the thing that earned it. Queue them if several land
together; never show one during a duel, hold until the result screen.

⚠️ **Reuse the existing level-up celebration path** (`pendingLevelUp` on
`GameState`) rather than inventing a second one. Two notification systems
competing for the same moment is how you get one drawn on top of the other.

---

## 8. Platform achievements (Google Play Games / Apple Game Center)

**Yes, integratable — and the model above already fits**: id, name,
description, points, hidden and incremental progress are exactly what both
platforms take.

**Recommendation: build ours first, mirror to platform later.**

- ✅ **Ours is the source of truth.** Platform achievements carry no reward,
  cannot be read back reliably, and **do not exist on web** — currently the
  primary way this game is played.
- ✅ **Mirroring is a thin adapter** — `unlock(id)` / `increment(id, steps)` at
  the same point we grant ours.
- ⚠️ **Ids must be mapped, not shared.** Both consoles mint opaque ids; keep a
  nullable `platformId`.
- ⚠️ **~140 achievements entered by hand, twice, each with art.** This is the
  dominant cost of the feature and an argument for trimming the catalogue —
  particularly the 60-entry mastery family, which could mirror only tiers
  III–V.
- 🚫 **Never gate a reward on the platform call.** Sign-in is optional, often
  declined, and offline. Grant locally, fire-and-forget the mirror.

---

## 9. 📝 Related: alternate character modes — to consider, not designed

Raised by the character/account split (§2). Recorded here so it is not lost;
these belong in GAME_DESIGN §5 if adopted.

- ✅ **Discordant** — no trading, no shops, no Concord Market; everything must
  be found or crafted.
- ✅ **Mortal** — one life; defeat ends the character permanently.
- ✅ **Discordant Mortal** — both at once.

⭐ **These are the strongest argument for the character/account split.** A
permadeath character has to be separate from your main, and "separate
character" only means something if progress and achievements travel with the
character rather than the account — which §2 already rules.

⚠️ Achievements need a **mode flag**: the same achievement earned as
**Discordant** is a different accomplishment from one earned with a market
behind you, and the two should be distinguishable rather than silently merged.
Deciding that *after* the achievement schema ships is a migration.

⭐ **Mode names double as titles** (§6.1) — "Corvin the Discordant" needs no
extra vocabulary, which is a point in favour of the names chosen.

---

## 10. Open questions

- ❓ **Tier thresholds** (§3.1) and the **Tres Commas number** (§5.3) both
  need a real economy before they can be set.
- ❓ **Should the mastery family mirror to platform at all**, given 60 entries
  of hand-entry (§8)?
- ❓ Does a **tier family award its lower tiers retroactively** if a player
  crosses several thresholds at once (e.g. importing an old save)? Leaning
  yes — grant every tier passed, so the wardrobe and points are consistent.

---

## 11. What must exist before this can be built

| # | Prerequisite | Blocks |
|---|---|---|
| 1 | ✅ **Character progress** (§2) — built on the character document, not a subcollection (§2.3, §2.4) | everything |
| 2 | ✅ **Zone `cleared` state** (§2.3) — `PlayerProfile.zoneClears` | 23 campaign achievements |
| 3 | ✅ **Per-element charge counters** (§2.2) — `PlayerProfile.charges` | 61 mastery achievements |
| 4 | ✅ **Lifetime gold earned** (§5.3) — `PlayerProfile.goldEarned` | wealth achievements |
| 5 | ✅ **Bestiary** — `PlayerProfile.bestiary` (seen/slain per creature) | purge + vanquisher achievements |
| 6 | ✅ **Item catalogue + drop tables** — `DropTable.possibleDrops`, `itemsSeen` | collector achievements |
| 7 | 📝 **`DuelSummary`** (§4) | conditional duel achievements only |

📝 Built alongside 1–4 (2026-10-01): `PlayerProfile.itemsSeen` (the
permanent *seen* log #6 needs) and `PlayerProfile.travelSeconds` (§5.5's The
Long Road).

⭐ **1–4 are small and worth doing regardless of achievements.** "Which zones
have I cleared", "what do I actually play", and "how much have I earned" are
facts the game should know about itself whether or not a badge is ever drawn.
