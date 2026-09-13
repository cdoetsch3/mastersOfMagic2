# The Ladder — rated matchmaking and the bot pool

**Status: draft for red-pen (2026-09-13).** Rulings from Christian folded in
where marked ✅; everything ❓ is a decision still needed; 📝 is a build note.

Supersedes the "AI persona nearest my level stands in" fallback in
`Matchmaking.quickMatch`. Extends ITEMS_DESIGN §7.4 (two ladders) and
GAME_DESIGN §5 with the actual numbers.

---

## 1. Laws

1. ✅ **One rating system, two ladders.** Geared and Academy each carry their
   own rating on every player *and* every bot. Same formula, same K schedule,
   same bands. Nothing crosses between them.
2. ✅ **Bots and humans are the same thing to the queue.** One search, one
   band, one widening schedule. The *only* asymmetry: when a human and a bot
   both fit the band, the human wins. A bot is what the search settles for,
   never what it prefers.
3. ✅ **No disclosure.** A bot has a name, a title, a look, a level, a rating,
   a win/loss record, and a think-time. Nothing player-facing says "AI". This
   holds in both ladders.
4. ✅ **Bot matches count for everything** a human match would: rating, record,
   XP, gold, quest credit on the geared ladder; rating and record on Academy.
5. ✅ **Bots are mages, not monsters.** They reuse the campaign archetypes for
   intelligence and kit *shape* only. `hpScale`/`damageScale` are ignored
   (1.0/1.0) — the driver already forbids archetype stats in PvP, and that
   rule stands. A bot's power comes from level, kit and gear, like a person's.
6. ✅ **Kits are hand-written and legal for their level.** The roster test
   already enforces element gates (Kinetic 15 · Celestial 30 · Ethereal 45)
   and pool size; it extends to spell unlock levels once the campaign locks
   them. Until then, bank spells are placed by the ruled §4 plan.
7. **Bot state is tiny and shared.** Rating, wins, losses, updatedAt — per
   ladder — in Firestore. Everything else is definitions-in-code.

## 2. Rating (✅ "just copy chess")

- Formula: `expected = 1 / (1 + 10^((Rb − Ra) / 400))`,
  `ΔRa = K × (score − expected)`, score ∈ {1, 0}. No draws exist (a duel
  always ends with one mage at 0).
- **K schedule (FIDE):** 40 for a player's first 30 rated games on that
  ladder; 20 after; 10 once the player has ever reached 2400 on it.
- **Bots** use the same schedule and are treated as having played their 30:
  K = 20. ❓ **One proposed deviation:** clamp a bot's rating to ±300 of its
  seed so a single grinder can't drive one to the floor and farm it. Not
  chess — it's a guard against the pool being a one-person population for a
  while. Recommend yes; easily removed once there are enough players.
- Bot vs bot never happens, so bot ratings only move against humans.
- **Starting ratings.**
  - Academy: everyone, human or bot, is level 50 with no gear, so skill is the
    only variable. Players start at **1200**. Bots seed from intelligence
    alone: `1200 + 60 × (intelligence − 5)`.
  - Geared: a level-30 player who has never queued is not a 1200 opponent for
    a level-3 player, and the §7.4 note already says gear/level should seed
    matchmaking rather than waiting for Elo to sort it. Players seed on first
    rated match at `1080 + 12 × level + 75` (i.e. the bot formula at
    intelligence 5, no gear term). Bots seed at
    `1080 + 12 × level + 15 × intelligence + gearTerm`
    (gear: Bare 0 · Worn 15 · Kitted 30 · Prized 45 · Peak 60).
    ❓ Alternative: everyone starts at 1200 regardless of level and the band
    search filters by level instead. Rejected in draft because Law 2 wants
    one search, not a search plus a level fence; the seed formula does the
    fence's job once and then gets out of the way.
- **Where it's written.** Rating math lives in `mom_engine` as a pure class
  (`Elo.update(ra, rb, score, ka, kb)`), mutation-tested. Player fields on
  the profile: `ratingGeared`, `ratingAcademy`, `ratedGamesGeared`,
  `ratedGamesAcademy`, `peakGeared`, `peakAcademy` (the 2400 rule needs the
  peak). Cloud sync carries them like everything else.

## 3. The search (✅ one queue, widening bands, humans first)

The ticket gains `rating` (the player's rating on the queue's ladder). The
search runs a widening schedule against **both** populations:

| Phase | Elapsed | Band | Looks at |
|---|---|---|---|
| 1 | 0–3 s | ±100 | human tickets only |
| 2 | 3–6 s | ±200 | human tickets only |
| 3 | 6–10 s | ±400 | human tickets only |
| 4 | 10 s | ±100, widening ×2 until non-empty | bots |

- A human ticket is claimable when **either** side's current band contains
  the other's rating (bands are symmetric in practice, but the check uses the
  claimer's band so a late arrival with a narrow band doesn't refuse someone
  who waited). Oldest claimable first, as today.
- Phase 4 picks **weighted-random** from bots in the band (weight = inverse
  rating distance), excluding the player's previous opponent. Two people
  online at once may still both meet Brightgale; that's fine at this
  population (see §5).
- Room-code duels are unrated. ❓ Confirm — friends inviting friends by QR
  should not be a rating farm, and it's also where the tournament use case
  lives.
- 📝 The 10-second patience is unchanged. What changes is that the wait now
  *ends in a match* rather than "nobody came, here's Wick".

## 4. What a bot is

`AiPersona` grows into a `LadderBot`:

| Field | Source | Notes |
|---|---|---|
| id, name, title, apparel | code | as today |
| level | code | 1–50 (Procarius stays a campaign boss at 60; not in the pool) |
| archetype | code | supplies **intelligence** and the offensive core's shape (move count, cost band) |
| loadout | code, hand-written | roster test: legal for level; offensive core matches archetype cost band; rest of the pool is shields/aux by tier |
| gear | code: item ids + Quality | derived to `ItemModifiers` exactly as a player's equipment is, so bots track item balance for free |
| thinkTime | code: mean 3 s, σ 0.8, clamp 1–5 (✅) | per move, redrawn each turn |
| seed rating (×2) | formula §2 | written to Firestore on first read |
| rating, wins, losses (×2) | **Firestore** `bots/{id}` | the only mutable state |

The `aggression`/`caution` dials on `AiPersona` are dormant (LadderAi never
reads them) and get deleted. The archetype's cost band **is** the playstyle
(ENEMIES §2.5: tempo lean is the cost band).

### 4.1 Concurrency (✅ many matches at once)

A duel runs entirely on the player's client against `LocalAiDriver`. Nothing
about a match is stored per bot, so any number of players can fight the same
bot simultaneously. The only shared writes are the post-match rating and
record updates, and those are **additive**: each client computes its Δ from
the rating it read at match start and applies a Firestore field-transform
increment (`+Δ`, `wins +1` or `losses +1`). Two simultaneous finishes both
land; the bot's rating is off by the staleness of one read, which Elo
absorbs next match. No locks, no "bot is busy".

📝 `FirestoreRest` has no increment today — add a `commit` call with
`fieldTransforms`. Firestore rules for `bots/{id}`: readable by any signed-in
user (anonymous included, for Academy); writable only on the six mutable
fields, with `|Δrating| ≤ 40` (the max a K-40 game can move) and record
fields +1 only.

### 4.2 Think time (✅ 1–5 s around 3)

`LocalAiDriver` draws a delay per move from a clamped normal (mean 3.0,
σ 0.8, floor 1.0, ceiling 5.0) before committing. The duel screen shows the
same "waiting for opponent" state it shows for a human. ❓ Should the delay
correlate with the position (longer when the bot is low or the player sits on
a big charge)? Cheap to add later; draft says flat.

## 5. The roster (❓ red-pen this)

Twenty-seven bots. Level spread ~one per two levels, three faces at the cap.
Intelligence comes from the archetype and is deliberately *not* monotonic in
level: two mid-ladder bots are the **gear-check** (dumb, well dressed) and
the **skill-check** (sharp, under-dressed), because those are the two things
the geared ladder is supposed to reward. Six existing personas keep their
names and titles.

Gear tiers: **Bare** none · **Worn** common/standard · **Kitted** uncommon–
rare/standard · **Prized** rare–epic/ornate · **Peak** mythic–legendary/master.
Item ids are chosen at build time from the catalogue at the bot's level.

| # | Name | Title | Lvl | Archetype | Int | Gear | Seed geared | Seed Academy | Note |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Wick | Candle Apprentice | 1 | drudge | 1 | Bare | 1107 | 960 | the tutorial dummy; keeps its slot |
| 2 | Pim | Hedge Sprout | 3 | skirmisher | 3 | Bare | 1161 | 1080 | first opponent who charges past 1 |
| 3 | Tansy | Puddle Witch | 5 | lasher | 3 | Worn | 1200 | 1080 | two attacks, one cheap one not |
| 4 | Orrin | Lantern Bearer | 7 | sentinel | 4 | Worn | 1239 | 1140 | first shield-first opponent |
| 5 | Marlow | Marsh Dabbler | 9 | glasswing | 4 | Worn | 1263 | 1140 | hits hard, folds fast (kit, not HP) |
| 6 | Sable | Moth Priestess | 11 | blighter | 5 | Worn | 1302 | 1200 | first DoT kit on the ladder |
| 7 | Dunstan | Quarry Hand | 13 | bruiser | 3 | Kitted | 1311 | 1080 | over-geared for his rating; wins on stats |
| 8 | Brightgale | Storm Skirmisher | 15 | skirmisher | 3 | Worn | 1320 | 1080 | existing; Kinetic unlocks here |
| 9 | Quill | Archive Novice | 17 | adept | 5 | Worn | 1374 | 1200 | balanced three-attack kit |
| 10 | Hesper | Tidewatcher | 19 | siphon | 5 | Kitted | 1413 | 1200 | drain-and-mend line |
| 11 | Rook | Cinder Duelist | 21 | lasher | 3 | Kitted | 1407 | 1080 | cheap pressure, blunders |
| 12 | Isolde | Frost Warden | 23 | sentinel | 4 | Kitted | 1446 | 1140 | Steadfast + Divert turtle |
| 13 | Garrick | Ridge Bruiser | 25 | bruiser | 3 | Prized | 1470 | 1080 | **the gear-check**: dumb and dressed |
| 14 | Thornwall | Warden of the Quarry | 28 | adept | 5 | Kitted | 1521 | 1200 | existing |
| 15 | Nettle | Hex Weaver | 30 | blighter | 5 | Kitted | 1545 | 1200 | Celestial unlocks here |
| 16 | Corvane | Gale Reaver | 32 | glasswing | 4 | Prized | 1569 | 1140 | Execute + Death Wish gambler |
| 17 | Lisbet | Hollow Chanter | 34 | hexer | 8 | Worn | 1623 | 1380 | **the skill-check**: sharp and under-dressed |
| 18 | Ashbourne | Bastion Mage | 36 | redoubt | 6 | Prized | 1647 | 1260 | Shatter-bait; teaches shield-breaking |
| 19 | Vale | Blade Scholar | 38 | executioner | 7 | Kitted | 1671 | 1320 | 3–5 charge crits |
| 20 | Morwen | Duelist of the Deep | 40 | champion | 7 | Prized | 1710 | 1320 | existing |
| 21 | Tarquin | Ledger Duelist | 42 | siphon | 5 | Prized | 1704 | 1200 | Meditate/Composure sustain |
| 22 | Seraphel | Dawn Herald | 44 | champion | 7 | Prized | 1758 | 1320 | Purify + Reflect counterplay |
| 23 | Halvard | Iron Redoubt | 46 | redoubt | 6 | Peak | 1782 | 1260 | Ethereal unlocks at 45 |
| 24 | Nyx | Void Adept | 48 | aspect | 8 | Peak | 1836 | 1380 | full 15-slot pool |
| 25 | Al'Dorian | Warden of the Last Gate | 50 | tyrant | 9 | Peak | 1875 | 1440 | existing; ladder ceiling |
| 26 | Ysolde | Grand Magus | 50 | aspect | 8 | Peak | 1860 | 1380 | second face at the cap |
| 27 | Bramwell | Old Master | 50 | executioner | 7 | Worn | 1800 | 1320 | skill over kit at the cap |

Notes on the spread:
- Intelligence 10 is absent on purpose. `LadderAi` at 10 is optimal play; the
  ladder's ceiling should be beatable by a good human, and Procarius already
  owns "10" as the Citadel boss.
- Nobody is intelligence 2. The archetype table has no 2; if a rung between
  Wick and Pim is wanted, it's a new archetype, not a bot override.
- Academy seeds collapse to five values (1080/1140/1200/…) because only
  intelligence varies there. That's correct — Academy asks who plays better,
  and twenty-seven bots at level 50 with the same kit *shape* would be
  indistinguishable but for skill. Kits still differ, which is where the
  variety lives.

## 6. Self-correction (the free telemetry)

Because bot ratings move, a mis-tuned bot drifts to where it belongs and
tells us so: a bot sitting 200 above its seed has a kit or gear set that's
stronger than its intelligence suggests; one 200 below is over-rated. A
weekly read of `bots/*` against §5 seeds is a balance report nobody has to
write. 📝 The sim harness should gain a `--ladder` mode that plays every bot
against every bot 200× and prints implied ratings, so the seeds can be sanity-
checked *before* players do it for us.

## 7. Build shape (✅ "sounds fine")

Lanes, engine-first:

1. **Engine:** `Elo` (pure, mutation-tested). `LadderAi` unchanged — the
   dials were never live.
2. **Bots:** `LadderBot` definitions with archetype + gear ids; roster test
   extended (legality, cost band, gear at level, seed formula); `LocalAiDriver`
   returns real gear for bots and draws think-time.
3. **Ratings plumbing:** profile fields; `FirestoreRest.increment`; `bots/*`
   seeding on first read; rating update at duel end for both ladders; rules.
4. **Search:** ticket `rating`; widening schedule; bot pick with weighting and
   no-repeat; tests for every phase boundary.
5. **UI (Christian verifies):** opponent card shows rating + record for
   everyone; profile shows both ratings; no "AI" anywhere. Lobby wording.
6. **Docs:** GAME_DESIGN §5 and ITEMS §7.4 point here; IMPLEMENTATION_PLAN
   ledger.

Roughly one batch. Lanes 1–4 are subagent-shaped; 5–6 are mine.

## 8. Decisions still open ❓

1. The ±300 bot clamp (§2) — keep, or pure chess?
2. Geared starting rating from level (§2) — or flat 1200 with a level fence?
3. Room-code duels unrated (§3)?
4. The roster (§5): names, titles, archetype choices, gear tiers.
5. Bot think-time flat, or position-aware (§4.2)?
6. Does a player's rating show on the *home* tab or only on the profile?
