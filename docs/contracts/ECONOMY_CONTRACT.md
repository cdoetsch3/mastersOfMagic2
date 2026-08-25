# General Shops (NPC, Personal) — Economy Content Contract

Status: 📝 **draft, for red-pen.** Written 2026-08-25 against the shipped
Q1+Q2 (Primal+Kinetic) implementation. ⚠️ **Nothing here is built.** This
document is the single source builder agents implement from, and the merge
coordinator verifies code against — same role as `KINETIC_CONTRACT.md`, same
marks, same discipline.

**Scope:** the per-character NPC general shop — one per town, nine towns —
its pricing curve, its stock schema, its server-tunable knobs, and the
value-conservation audit that falls out of finally putting a gold price on
every fungible item in the game. **Not in scope:** shop UI, the player-to-
player Concord Market, currency changes (§12 states this precisely).

> ### How to read this
>
> | Mark | Meaning |
> |---|---|
> | 📝 | **A number the designer is expected to want to tune.** Every 📝 is a knob; nothing structural hangs on its exact value |
> | ⭐ | The reasoning worth preserving through a rewrite |
> | ⚠️ | A trap, an invariant, or a place a builder will get it wrong |
> | ✅ | Canon — taken from a doc or from shipped code, not invented here |
>
> ⚠️ **Christian ruled every design decision listed below on 2026-08-24/25.**
> This contract encodes those rulings; it does not reopen them. The
> **Decisions needed** section (§14) is reserved for gaps the rulings did not
> anticipate — mostly, "the content these rules need doesn't exist yet."

---

## 0. What is canon and what is proposed

### 0.1 Canon — do not change without changing the source doc

| Fact | Source |
|---|---|
| Nine towns, ids and stations | `lib/game/world.dart` — `World.townIds` |
| Town↔zone adjacency (the travel graph) | `lib/game/world.dart` — `GameLocation.edges` |
| `ItemDef` kinds, `Tradability`, `Quality.statPercent` | `lib/game/items/item_def.dart` |
| Which items are fungible (materials, motes, consumables, gems, keys — never equipment or tools) | `ItemDef.isFungible` |
| The 110 shipped item definitions across 11 built zones (5 Primal + 6 Kinetic) | `lib/game/items/item_catalogue.dart` (`ItemCatalogue.byZone`) |
| The 41 shipped recipes (20 Primal + 21 Kinetic) | `lib/game/items/recipe_book.dart` |
| `Skills.xpForRecipe`, `Skills.xpToNext` | `lib/game/skills.dart` |
| Duel gold reward = flat 30, no per-level scaling; loss pays 0 in PvE | `lib/game/progression.dart` |
| The login content-version gate and the `config/content` public-read pattern | `lib/game/content_version.dart`, `firestore.rules` |
| Discordant mode: *"No trading, no shops, no Concord Market. Everything found or crafted."* | GAME_DESIGN §5 |
| The balance-probe pattern (seeded, headless, `tool/*_test.dart`, env-var-gated deep mode) | `tool/balance_probe_test.dart` |
| The 1 MiB Firestore document ceiling, and the bounded-vs-unbounded profile-field rule | IMPLEMENTATION_PLAN, "the `progress/` subcollection" |

### 0.2 The thirteen standing rulings this contract encodes (Christian, 2026-08-24/25)

1. Shops are **personal** — per-character stock state, never a shared pool. The player market is a separate future wave; this contract specs only its seams.
2. **One general shop per town**, all nine towns.
3. Stock catalogue is **materials + consumables only** — gear is never stocked. Non-stocked items (including gear) may still be vendored *to* the shop at a flat 0.6× base value, no stock tracking, a pure sink.
4. Pricing formula, marginal per-unit, ±10% buy/sell spread.
5. Location modifier tiers: −25% / −10% / 0 / +10% / +25%.
6. Equilibrium stock category defaults: zone-native materials 60, imported materials 20, consumables 30.
7. Nightly UTC-midnight reset, `RESUPPLY_RATE` default 0.5, deterministic daily events.
8. Server-tunable constants in `config/economy`, fail-open to compiled defaults, **legal only because shops are PvE-personal**.
9. Value conservation through crafting: `Standard < Σ(input values) < Ornate`, crafted vendor value scales on the stat quality ladder.
10. No hard daily caps in v1; **Discordant mode gets no shops.**
11. Anti-exploit verification is a required spec, not a required build, this wave.
12. Schema: per-character shop state on the profile document, bounded.
13. Out of scope: shop UI, the player market, currency changes.

### 0.3 What this contract deliberately does NOT specify

- **Shop UI** — the designer reviews screens separately.
- **The player-to-player Concord Market** — only its enforcement seams (§2.5).
- **New `ItemEffect` vocabulary, new recipes, or new zone content.** Where a
  town's shop has nothing to sell because its neighbouring zone hasn't
  shipped, that gap is named, not filled (§14 Decision 2).
- **Exact belt/backpack UI for buying/selling** — a data and rules contract,
  not a screen flow.

---

## 1. The shop model

⭐ **The load-bearing constraint, stated once so nothing downstream forgets
it:** the Firestore backend is **client-authoritative** (ITEMS §10.1 — item
*definitions* live in code so both clients agree without a server round
trip; the client also currently just writes `players/{uid}` directly,
`firestore.rules` §"Each player owns exactly their own profile document").
A **shared, globally-mutable shop stock document** would be exactly the kind
of state two clients can race, desync, or (worse) a modified client can
simply overwrite — there is no Cloud Function layer arbitrating writes. ⚠️
**A shop that reads or writes shared state is not buildable safely on this
backend today.** Making stock *personal* — one player's own document, no
different from their inventory — sidesteps the whole problem: nothing about
it is contested, so nothing about it needs a server referee.

✅ **This is why ruling 1 is not a taste call, it is the only version that
fits the shipped architecture.** The player-to-player Concord Market
(GAME_DESIGN's own future term, confirmed live in the `docs/GAME_DESIGN.md`
Discordant-mode row) is a genuinely different problem — shared listings are
inherently contested state — and is explicitly **not** this contract's to
solve. This contract specs only the seams a future market implementation
must respect (§2.5).

### 1.1 What "personal" means, concretely

Each character has their own copy of every town's shop — their own stock
counts, their own last-reset day. Visiting Hearthwood does not change what
any other character sees at Hearthwood. A character who never visits
Forgeholm never advances Forgeholm's clock; §6's catch-up loop is what makes
that safe (arriving after 40 days away resolves in one closed-form step, not
40 iterations of drift).

⚠️ **This means locationMod and eventMod are the only things every player
agrees on** (they are pure functions of `(townId, itemId, UTC date)`, not
stored state) — stock and its resulting scarcity multiplier are the one part
of the price that is genuinely personal. Two characters standing in the same
shop on the same day can see different prices for the same item, because
their own stock has drained or flooded differently. This is intended, not a
bug to converge away.

---

## 2. Towns and catalogues

### 2.1 The nine towns, their stations, and their adjacent zones

✅ From `lib/game/world.dart`. "Adjacent zone" = a non-town `GameLocation`
directly connected by a `TravelEdge` (i.e. the zones a shop's "native" stock
is drawn from, per ruling 3).

| Town | Tier | Station | Adjacent zones | Shipped? |
|---|---|---|---|---|
| Hearthwood | Primal | Woodcarving | whispering_woods, glimmerbrook, thornmire, cinderpeak_foothills | ✅ all 4 |
| Pennycross | Primal | Tailoring | glimmerbrook, old_quarry | ✅ both |
| Forgeholm | Kinetic | Metalworking | old_quarry, thunderspire_peaks | ✅ both |
| Galehaven | Kinetic | Potions & Alchemy | stormcliff_coast, frostfell_pass, *tidewrack_shoals (sea)* | ✅ 2 of 3 |
| Concordance | Celestial | *none — the trade capital* | frostfell_pass, windward_steppe, *the_kiln_desert, the_mirrormere* | ✅ 2 of 4 |
| Meridian | Celestial | Enchanting | *the_kiln_desert, the_mirrormere, starfall_basin, the_sunless_reach* | ⛔ **0 of 4** |
| Rimeholt | Ethereal | Jewelry | *the_mirrormere, hallowmarch* | ⛔ **0 of 2** |
| Vespergate | Ethereal | *none* | *hallowmarch, the_umbral_wastes, the_buried_sky, the_collapsed_academy* | ⛔ **0 of 4** |
| Zenith | Ethereal | *all six* | *the_eclipsed_citadel* | ⛔ **0 of 1** |

*Italic* zones have no `ItemCatalogue.byZone` entry yet — only the 5 Primal
and 6 Kinetic zones are built. ⚠️ **This is the single largest scope
constraint on this contract**, and it is load-bearing enough to be Decision 2
(§14): four of nine towns (Meridian, Rimeholt, Vespergate, Zenith) and half
of Concordance have **zero shippable native stock** today. §2.3 proposes a
resolution; it is still flagged as a decision because it changes what
"launch" means for those shops.

### 2.2 What's stockable: the 34-item fungible pool

⭐ Per ruling 3, stock = `MaterialDef` + `ConsumableDef` + `BeltableDef` only.
`ItemCatalogue.byZone` holds 110 defs across the 11 built zones — of those,
55 are fungible (`isFungible == true`: materials, motes, consumables, keys)
and 55 are equipment. Of the 55 fungible defs, 18 are motes (⚠️ **motes are
never shop stock** — they are kill/node-only currency, ITEMS §6.0) and 3 are
gate keys (bound, value 0, never sellable). That leaves the stockable pool:

| Kind | Count | Notes |
|---|---|---|
| `MaterialDef` | 29 | 2 per pure zone, 3 per hybrid (✅ ITEMS §9b.8 ruling 7), minus the two kill-only hides that still count as materials |
| `ConsumableDef` | 2 | `foragers_ration`, `hardtack` — both drop-only in design intent, but nothing marks them untradeable, so nothing stops a shop stocking them |
| `BeltableDef` | 3 | `sapwort_draught`, `brookmint_tonic`, `saltwort_draught` |
| **Total** | **34** | the pool every town's catalogue draws from |

📝 **Proposed exclusion, flagged for red-pen, not a ruling:** `bronze_ingot`
and `iron_ingot` are `MaterialDef`s too (Metalworking's crafted
intermediates) but this contract proposes **excluding them from shop
stock** — they are Woodcarving's *inputs*, not a gathered commodity, and
letting a shop sell them lets a player skip Metalworking (and the ore/
charcoal haul) entirely for every downstream weapon. This mirrors "gear is
never stocked" in spirit: a shop sells raw goods and finished consumables,
never a step of someone else's crafting chain. If overturned, add both to
Forgeholm's native catalogue at the values in §8.2.

### 2.3 Catalogue composition and the four-town gap

Each catalogue = **its town's native stock** (materials/consumables from
adjacent, *shipped* zones) **+ a small imported selection** (📝 2–8 items,
sized to the town's role). Where native stock is empty (§2.1's four towns),
the catalogue is **imports only** — proposed here, not a ruling, exactly
because it is Decision 2.

| Town | Native items | Proposed imports | **Catalogue size** | Import rationale |
|---|---|---|---|---|
| Hearthwood | 11 (oak_log, bindweed_fibre, foragers_ration, fawnhide, sapwort, sapwort_draught, bogflax_fibre, fenroot, amber, copper_ore, tuskhide) | 2 (birch_log — one tier ahead, a taste of Ashfall) | **13** | tutorial hub, biggest native pool by construction (4 adjacent zones) |
| Pennycross | 6 (fawnhide, sapwort, sapwort_draught, tin_ore, quarry_jasper, hardtack) | 2 (oak_log, bindweed_fibre — bridges Hearthwood) | **8** | "the first market" |
| Forgeholm | 6 (tin_ore, quarry_jasper, hardtack, rowan_log, iron_ore, hum_quartz) | 2 (**copper_ore, charcoal** — Bronze's other two-thirds, neither native here) | **8** | ⭐ the Metalworking hub importing exactly what its own signature recipe needs |
| Galehaven | 6 (seawrack_fibre, saltwort, saltwort_draught, rimepelt, hoarlichen, everice) | 2 (hardtack, brookmint_tonic — generic travel stock, the port sells what comes off the boats) | **8** | Potions & Alchemy hub |
| Concordance | 5 (rimepelt, hoarlichen, everice, yew_log, tussock_flax) | 7 (oak_log, fawnhide, bogflax_fibre, birch_log, tin_ore, seawrack_fibre, rowan_log — one representative per built zone) | **12** | ⭐ **lore-mandated:** *"value MOVES here, it is not made"* — the trade capital should visibly be the one place that sells a taste of everywhere |
| Meridian | 0 | 4 (**hum_quartz** — its own station's material, banked and waiting; saltwort_draught, hardtack, brookmint_tonic) | **4** | ⛔ placeholder pending Celestial content; Hum Quartz's presence is the one deliberate exception |
| Rimeholt | 0 | 5 (**quarry_jasper, everice, obsidian, amber** — all four banked jewel materials, per §8.1's promise; hardtack) | **5** | ⭐ Jewelry unlocks *here* — a player who didn't hoard should still be able to buy in |
| Vespergate | 0 | 4 (hardtack, sapwort_draught, brookmint_tonic, saltwort_draught — every shipped consumable) | **4** | "the last place with a supply line" — a frontier outpost sells what keeps, not what's local |
| Zenith | 0 | 9 (a representative sample spanning the 11 built zones) | **9** | ⭐ the only town with all six stations is the only shop that should be able to feed any of them |

**Total stock-entries across all nine catalogues: 71** (with intentional
overlap — `hardtack`, `oak_log`, etc. legitimately appear in more than one
town's list; §11's size math treats each town's list independently, which is
the number that actually matters for document size).

⚠️ **This table is illustrative, not exhaustive** — a builder should treat
the *native* columns as fixed by §2.1's graph and the *imports* as the
red-pen target. Nothing here is load-bearing except the Forgeholm/Rimeholt
worked examples, which exist to prove the import mechanism does something
useful rather than being arbitrary.

### 2.4 Tradability enforcement at the vendor seam

✅ From `Tradability` (`item_def.dart`): `tradeable`, `untradeable`, `bound`.

| Tradability | Buy from shop | Sell/vendor to shop |
|---|---|---|
| `tradeable` | ✅ (if stocked) | ✅ |
| `untradeable` | n/a (never stocked — no shipped `MaterialDef`/`ConsumableDef` is untradeable today, but the rule must hold if one ever is) | ✅ — converting to gold is not the same act as handing it to another player, and nothing in ITEMS §6c's "freed by an unbinding enchant" language forbids destroying it for gold |
| `bound` | n/a | ⛔ **never** — `ComponentDef` and `KeyDef` are `bound` by construction (ITEMS §6c); a bound→gold path is a laundering route around the exact bulk-crafting/gate-collectible restriction binding exists to enforce |

⚠️ **This is the enforcement point ruling 1 asks this contract to name for
the future player market too**, even though the market itself is out of
scope: a listing must be refused for anything `bound`, exactly as a shop
sale is.

### 2.5 Seams for the future player market (spec only, not built)

1. **Tradability gate**: identical to §2.4 — a market listing is legal only
   for `tradeable` items (an `untradeable` item cannot be listed *between
   players* even though it can be vendor-sold, per ITEMS §6c's design; only
   an unbinding enchant changes that).
2. **Listing-price floor**: 📝 propose a listing must price at or above the
   item's *current vendor-sell value* at the listing town. Below that floor,
   the NPC shop is strictly better than the player market, which defeats the
   market's purpose *and* opens a wash-trading path (list absurdly low,
   buy it back yourself, manufacture a paper loss/gain). ⚠️ This floor must
   be checked against the seller's own local *sell* price, not the buyer's
   local *buy* price — those differ by the ±10% spread (§3) before
   locationMod is even applied.

---

## 3. Pricing

### 3.1 The formula

```
price(item) = base × clamp((E / stock)^0.5, 0.4, 2.5) × locationMod × eventMod
```

- `base` = the item def's `value` field (gold). ⚠️ **See §8 — most of these
  are currently unauthored.** `ItemDef.value`'s own doc comment already
  calls it *"a tuning knob — a candidate for server-side config later, since
  nothing the duel resolves depends on it"* — this contract is that
  candidate arriving.
- `E` = the item's equilibrium stock (§5).
- `stock` = this character's current stock of the item at this town.
- `locationMod` = §4.
- `eventMod` = §6.2, ±20% on ~2 items/shop/day, deterministic.

The player pays `price × 1.10` to buy, receives `price × 0.90` to sell —
✅ ruled spread. A same-day, same-stock round trip (buy then immediately
sell back) loses `1 − 0.90/1.10 ≈ 18%` — the ✅ ruled "local round trip loses
~18%" figure. Combined with the ±25% location-modifier range, buying at a
−25% town and selling at a +25% town nets `1.25×0.90 / (0.75×1.10) ≈ 1.364`,
✅ the ruled **"~36% gross"** hauling margin — deliberately Phase 5b's trade
gameplay, not an oversight to close.

### 3.2 ⚠️ The hard invariant: per-unit marginal pricing

**Batch-priced-at-current-stock is the classic MMO-economy exploit, and it
must be named as such.** A trade of *N* units is *N* separate unit-prices,
each computed against the stock level *as it stands after the previous unit
in the same transaction* — buying drains stock unit-by-unit as it prices;
selling floods it unit-by-unit as it prices. The wrong implementation prices
the whole batch once, at the stock level the transaction *started* at.

⭐ **Worked example of the exploit, so a builder can see what "wrong" costs.**
Take `saltwort_draught` (E=30, base=30, buy spread ×1.10, sell spread ×0.90)
at a shop that happens to be nearly sold out — `stock = 2`:

| Method | What happens selling 50 units at once |
|---|---|
| **Correct (marginal)** | Unit 1 sells at `stock=2` (`mult=clamp(√(30/2),0.4,2.5)=2.5`, capped); by unit 20 `stock≈22` (`mult=√(30/22)≈1.17`); by unit 50 `stock=52` (`mult=√(30/52)≈0.76`) — the price craters as the sale itself floods the market, because that is what a sale of 50 units into a shop that only wanted 2 *should* do. |
| **Wrong (batch)** | All 50 units price at the **stock=2** rate (`mult=2.5`, the pre-transaction snapshot) — `30 × 2.5 × 0.90 = 67.50` gold **each**, `3,375` gold total, for dumping fifty potions on a market that could absorb two. |

The gap between those two numbers **is** the exploit. ⚠️ **A required test**
(§10, §14) must assert that a large single-transaction trade's total cost
strictly brackets the sum of its own per-unit marginal prices — i.e. prove
the implementation cannot regress to the batch shortcut, not merely that
some number came out reasonable.

### 3.3 Zero-stock guard

`E / stock` is undefined at `stock = 0`. ⚠️ **Implementation note, not a
design point:** treat `stock == 0` as the clamp's own ceiling (`mult = 2.5`)
rather than dividing by zero — an empty shelf is maximum scarcity, which is
exactly what the formula already means at its cap; it needs an explicit
branch, not a literal division.

---

## 4. Location modifiers

### 4.1 The rule (the shape, not a hand-filled 9×34 table)

📝 **Proposed, mechanically derivable from the travel graph** — not hand-
authored per cell, because 306 cells hand-tuned individually is exactly the
kind of table that drifts the moment one zone's adjacency changes. For a
town `T` and an item whose native zone is `Z`:

| Relationship of `Z` to `T` | Mod | Rule |
|---|---|---|
| `Z` is one of `T`'s own adjacent zones | **−25%** | native — "discounted where it comes from" |
| `Z` is adjacent to a zone that is adjacent to `T` (2-hop, zone-to-zone) | **−10%** | regional |
| Same `MagicTier` band as `T`, neither native nor regional | **0%** | baseline |
| `Z`'s tier is one band away from `T`'s | **+10%** | cross-tier import |
| `Z`'s tier is two or more bands away | **+25%** | exotic, capped |

⚠️ **Applies per (town, item), not per (town, category)** — two items from
the same zone can differ if one is also separately native somewhere else
(no shipped case today, but the rule must not assume otherwise).

### 4.2 Native/regional zone sets, computed from §2.1's graph

| Town | Native (−25%) | Regional (−10%) |
|---|---|---|
| Hearthwood | whispering_woods, glimmerbrook, thornmire, cinderpeak_foothills | ashfall_vale, the_molten_deep |
| Pennycross | glimmerbrook, old_quarry | thornmire, the_molten_deep |
| Forgeholm | old_quarry, thunderspire_peaks | the_molten_deep, stormcliff_coast, windward_steppe, frostfell_pass |
| Galehaven | stormcliff_coast, frostfell_pass | thunderspire_peaks, windward_steppe |
| Concordance | frostfell_pass, windward_steppe | thunderspire_peaks |
| Meridian / Rimeholt / Vespergate / Zenith | *none shipped* | *none shipped* |

⭐ **Worked consequence, worth seeing rather than just stating:** Forgeholm's
imported Copper Ore and Charcoal (§2.3) are neither native nor regional
there (their zones are Primal, two tiers back) — they price at **+10%**
(one-tier import), so the very first Kinetic recipe a player meets costs a
small, legible premium for the two ingredients they didn't carry themselves.
Rimeholt's imported jewel materials (quarry_jasper, everice, obsidian —
Kinetic, two tiers back from Ethereal) price at **+25%**, the exotic cap —
⭐ **a deliberate piece of tension, not a rough edge**: banking those
materials yourself and hauling them to Rimeholt beats buying them fresh once
you arrive, which is exactly the "hauling is worth ~36% gross" lesson of §3.1
paying off a second time, at the seam where Jewelry finally opens.

---

## 5. Equilibrium stock (E)

### 5.1 Category defaults

✅ Ruled: **zone-native materials 60 · imported materials 20 · consumables
30**, with 📝 per-item overrides. "Zone-native" here means native to *this
shop's* town (§4.2), independent of the item's own catalogue-file zone — an
imported material is `E=20` everywhere it is sold as an import, `E=60` at
its native town.

### 5.2 Worked price tables — 3 representative items

Chosen to cover the three real states a base value can be in: **proposed**
(currently unauthored, §8), **shipped and correct**, and **shipped
consumable**. All three at their **native** town (`locationMod = 0%` — no
discount, no import surcharge — isolating the stock curve). `eventMod = 1`
(no event that day). Buy = `price × 1.10`; Sell = `price × 0.90`.

**`oak_log`** — material, `E = 60` (native at Hearthwood), `base = 25` 📝
(Christian's instructed worked-table anchor — see §8.3 for why this
conflicts with the conservation-audit-derived value of 13):

| Stock | Multiplier | Price | Buy | Sell |
|---|---|---|---|---|
| 0 | 2.50 (clamped, §3.3) | 62.50 | 68.75 | 56.25 |
| 10 | 2.449 | 61.24 | 67.36 | 55.12 |
| 30 | 1.414 | 35.36 | 38.89 | 31.82 |
| 60 (=E) | 1.000 | 25.00 | 27.50 | 22.50 |
| 100 | 0.775 | 19.36 | 21.30 | 17.43 |
| 200 | 0.548 | 13.69 | 15.06 | 12.32 |
| 500 | 0.400 (clamped) | 10.00 | 11.00 | 9.00 |

**`rimepelt`** — material, `E = 60` (native at Galehaven/Concordance),
`base = 12` ✅ shipped, unchanged (⚠️ but see §8.4 — this value fails its own
recipe's conservation check; it is still the right number for *this* pricing
table because it is what the game currently ships):

| Stock | Multiplier | Price | Buy | Sell |
|---|---|---|---|---|
| 0 | 2.50 | 30.00 | 33.00 | 27.00 |
| 10 | 2.449 | 29.39 | 32.33 | 26.45 |
| 30 | 1.414 | 16.97 | 18.66 | 15.27 |
| 60 (=E) | 1.000 | 12.00 | 13.20 | 10.80 |
| 100 | 0.775 | 9.30 | 10.23 | 8.37 |
| 200 | 0.548 | 6.57 | 7.23 | 5.91 |
| 500 | 0.400 | 4.80 | 5.28 | 4.32 |

**`saltwort_draught`** — consumable, `E = 30` (native at Galehaven),
`base = 30` ✅ shipped, unchanged:

| Stock | Multiplier | Price | Buy | Sell |
|---|---|---|---|---|
| 0 | 2.50 | 75.00 | 82.50 | 67.50 |
| 10 | 1.732 | 51.96 | 57.15 | 46.76 |
| 30 (=E) | 1.000 | 30.00 | 33.00 | 27.00 |
| 60 | 0.707 | 21.21 | 23.33 | 19.09 |
| 100 | 0.548 | 16.43 | 18.07 | 14.79 |
| 200 | 0.400 (clamped) | 12.00 | 13.20 | 10.80 |
| 500 | 0.400 (clamped) | 12.00 | 13.20 | 10.80 |

⚠️ **Note the floor collapses `stock=200` and `stock=500` to the same
price** for a consumable's smaller `E`. That is the clamp doing its job —
without it, a sufficiently flooded stock would eventually price the item at
literally nothing, which is the free-goods failure mode §8.1 already warns
about for a different reason (unauthored `base`, not an unclamped curve).

---

## 6. Nightly reset and daily events

### 6.1 The resupply loop

✅ Ruled, per elapsed UTC day, per (town, item):

```
stock += (E − stock) × RESUPPLY_RATE
```

`RESUPPLY_RATE` defaults **0.5** 📝 (may tune to 1.0). ⭐ **Catch-up, not a
40-iteration replay**: a character who returns after `n` days away resolves
`n` applications of the recurrence in one closed-form pass at load time
(`stock_n = E − (E − stock_0)(1 − rate)^n`), not a loop that re-simulates
every missed midnight turn-by-turn in the UI. Worked example — `stock=0`,
`E=60`, `rate=0.5`, 5 days away:

| Day | Stock |
|---|---|
| 0 (start) | 0.00 |
| 1 | 30.00 |
| 2 | 45.00 |
| 3 | 52.50 |
| 4 | 56.25 |
| 5 | 58.13 |

### 6.2 Daily events

📝 **~2 affected items per shop per day, `eventMod = ±20%`, deterministic
from `(UTC date, shopId)`** — a seeded hash, not server state, so every
player sees the same spike/glut days with zero writes and zero server
authority beyond the RNG seed itself (which is a compiled constant, not a
config value — changing it would be a content-version bump like anything
else two clients must agree on). ⚠️ **Deterministic means the seed is part
of what `ContentVersion.current` covers** — a client on an old build computes
different event days than a client on a new one, which is exactly the kind
of drift the login gate exists to catch (§0.1).

---

## 7. Server-tunable config (`config/economy`)

✅ Ruled, mirroring `config/content` (`content_version.dart`,
`firestore.rules`) exactly:

```
config/economy
  resupplyRate: number       (default 0.5)
  eventMagnitudePercent: number   (default 20)
  eventItemsPerShopPerDay: number (default 2)
  locationModOverrides: map  (townId.itemId -> percent, sparse)
  equilibriumOverrides: map  (itemId -> integer, sparse; category defaults apply when absent)
```

**`firestore.rules` addition** (text only — no code changes ship from this
contract):

```
match /config/{doc} {
  allow read: if true;
  allow write: if false;
}
```

— this rule *already exists* verbatim and already matches `config/{doc}`
as a wildcard, so `config/economy` needs **no rules change at all**, only
the new document. ⚠️ Read at boot, cached client-side, exactly like content
version; **fail-open to the compiled defaults above** if the doc is missing,
unreachable, or times out — the same fail-open reasoning
`checkContentVersion` already documents (an outage must never be worse than
the number it is protecting).

⚠️ **The guardrail to state verbatim, because it is the whole reason this is
allowed to be server-tunable at all:** this is the game's **first**
server-tunable gameplay data. It is legal *only* because shops are
PvE-personal (§1) — nothing here is read by anything lockstep-resolved.
**Nothing that touches `DuelEngine`, `DuelController`, or any duel-affecting
`ItemModifiers` may ever read this document.** A future feature that wants
server-tunable *combat* numbers needs its own argument from scratch; this
guardrail does not extend to it by precedent.

---

## 8. Value conservation through crafting — the audit

### 8.1 ⚠️ The headline finding: base values mostly don't exist yet

Of the 34 stockable fungible items (§2.2), **26 materials have no `value`
field at all** — `ItemDef.value` defaults to `0`, and 26 of 29 shipped
`MaterialDef`s (every Primal one, and all but three Kinetic ones) rely on
that default. Only `rimepelt` (12), `hoarlichen` (11) and `everice` (26)
carry an authored value. All 5 consumables (`foragers_ration`, `hardtack`,
`sapwort_draught`, `brookmint_tonic`, `saltwort_draught`) are authored.

⚠️ **This is not a cosmetic gap — it blocks the shop outright.** `price(item)
= base × …` with `base = 0` prices the item at **zero, forever, at every
stock level and every location modifier**, because every multiplier in the
formula is applied to zero. A shop cannot ship with 26 of its 29 possible
materials priced as a permanent giveaway. Authoring this table is this
contract's largest deliverable, not a footnote.

### 8.2 Proposed material base values

📝 Derived by back-solving each material's **cheapest single-material
recipe** (fewest input units, no secondary ingredient) for the value that
makes `Σ(inputs) ≈` that recipe's Standard output value, then checked
against every other recipe using the same material. Where checked, **prefer
never falling under Standard** (falling under Standard is the direction that
is actually exploitable — a risk-free buy→craft→vendor loop — falling over
Ornate is merely bad crafting EV, not a hole). ✅ The 3 shipped values
(`rimepelt`, `hoarlichen`, `everice`) are kept as ground truth for this table
even though §8.4 shows one of them still fails its own recipe.

| id | Tier | Rarity | Shipped | **Proposed** |
|---|---|---|---|---|
| `oak_log` | 1 | common | 0 | **13** ⚠️ see §8.3 |
| `bindweed_fibre` | 1 | common | 0 | **10** |
| `fawnhide` | 1 | common | 0 | **17** |
| `sapwort` | 1 | common | 0 | **7** |
| `copper_ore` | 2 | common | 0 | **7** |
| `charcoal` | 2 | common | 0 | **7** |
| `fenroot` | 2 | common | 0 | **8** |
| `amber` | 2 | uncommon | 0 | **14** |
| `tuskhide` | 2 | common | 0 | **46** |
| `bogflax_fibre` | 2 | common | 0 | **28** |
| `birch_log` | 2 | common | 0 | **38** |
| `brookmint` | 2 | common | 0 | **13** |
| `tin_ore` | 3 | common | 0 | **9** |
| `quarry_jasper` | 3 | uncommon | 0 | **15** |
| `bronze_ingot` (intermediate) | 3 | common | 0 | **32** |
| `seawrack_fibre` | 3 | common | 0 | **30** |
| `saltwort` | 3 | common | 0 | **16** |
| `yew_log` | 3 | common | 0 | **58** |
| `tussock_flax` | 4 | common | 0 | **37** |
| `rimepelt` | 4 | common | 12 | **95** ⚠️ see §8.4 |
| `hoarlichen` | 4 | common | 11 | 11 (no recipe consumer — kept as-is) |
| `rowan_log` | 4 | common | 0 | **120** |
| `iron_ore` | 4 | common | 0 | **12** |
| `hum_quartz` | 4 | uncommon | 0 | **20** |
| `iron_ingot` (intermediate) | 4 | common | 0 | **52** |
| `obsidian` | 4 | uncommon | 0 | **20** |
| `everice` | 5 | uncommon | 26 | 26 (no recipe consumer — kept as-is) |
| `firesalt` | 5 | common | 0 | **15** |
| `emberhide` | 5 | common | 0 | **190** ⚠️ see §8.5 |

⭐ **A pattern worth stating once rather than per-row:** materials do **not**
scale like equipment. Equipment value roughly triples per wood tier (Oak
quarterstaff 30 → Birch 90); the three shipped material anchors (11, 12, 26)
are almost flat across tiers 4–5. This is thematically right — raw
commodities stay cheap; value accrues in the crafting labour and the quality
roll — and it is why a naive "scale materials like gear" formula would have
been wrong to propose here.

### 8.3 ⚠️ The oak_log conflict, named rather than silently resolved

Christian's worked-table instruction anchors `oak_log` at **25** (§5.2's
table uses it verbatim, as instructed). The conservation audit independently
derives **13** from the shipped Oak Quarterstaff/Wand/Knot value ladder. At
25, three logs of Oak Quarterstaff cost 75 against a 30-value Standard item
(150% over Ornate) — not a minor overage, a structurally broken recipe. This
contract uses 25 where explicitly instructed (§5.2) and 13 everywhere the
conservation math is load-bearing (§8.6's audit table). **The two numbers
should not both ship** — see Decision 1 (§14).

### 8.4 ⚠️ Worst offender: a material that already has a shipped value still fails

`rimepelt_belt` (Standard 220, Ornate 264) consumes `rimepelt ×2 +
tussock_flax ×1`. At the **currently shipped** `rimepelt = 12` and this
contract's own `tussock_flax = 37`: `Σ = 2×12 + 37 = 61` — **28% of
Standard**, a risk-free buy-craft-vendor loop nearly four times over, using
a material that *is already authored*. Authoring some value is not
sufficient; it has to be authored against the recipe that spends it. This
contract's proposed fix raises `rimepelt` to **95** (§8.2), which brings the
same recipe to `Σ = 227`, inside `[220, 264]`.

### 8.5 The emberhide outlier, explained rather than just flagged

`emberhide = 190` (§8.2) looks wildly out of step with `firesalt = 15` at
the same tier — both tier 5, both common. It is not a mistake: `emberhide`
feeds only `emberhide_belt` (Standard 380 — the top belt in the game, 4 belt
slots, equip 27), and it is **kill-only, no gather node** (ITEMS §9b.7b),
same scarcity class as `rimepelt` and `tuskhide`. A hide priced to conserve
against its belt's already-high, already-shipped value is not a formula
artifact; it is the formula correctly pricing a scarce, high-tier hide.

### 8.6 The full recipe audit — 41 recipes, proposed values applied

⚠️ **Under currently shipped values, 39 of 41 recipes are trivial
violations** (`Σ(inputs) = 0` against a nonzero Standard value) because
their materials are unauthored (§8.1); the remaining 2 (`craft_bronze_ingot`,
`craft_iron_ingot`) are degenerate `0 = 0` — not passes, just "no data yet."
The table below re-runs the audit with §8.2's **proposed** values (`oak_log
= 13`, per §8.3) and reports what's left:

| Result | Count | Recipes |
|---|---|---|
| ✅ Clean pass (`Standard < Σ < Ornate`) | 20 | oak_wand, birch_wand, bindweed_hood, fawnhide_belt, tuskhide_belt, bogflax_hood, sapwort_draught, brookmint_tonic, yew_wand, yew_knot, rowan_wand, rowan_knot, seawrack_boots, seawrack_gloves, rimepelt_belt*, tussock_hood, tussock_boots, tussock_gloves, emberhide_belt*, saltwort_draught (*only pass because §8.2's raised rimepelt/emberhide are applied) |
| ⚠️ Boundary (exactly at Standard or Ornate) | 3 | seawrack_hood (60=Standard), craft_bronze_ingot, craft_iron_ingot (both Σ=output, zero headroom — propose +2 on each ingot's value) |
| 📝 Minor overage (4–12% over Ornate; still Master-profitable) | 14 | oak_quarterstaff, oak_knot, birch_quarterstaff, birch_knot, bindweed_robe, bindweed_leggings, bindweed_boots, bindweed_gloves, bogflax_boots, bogflax_gloves, yew_quarterstaff, rowan_quarterstaff, tussock_robe, tussock_leggings |
| 🔴 **Major violation** (Master-tier still a loss) | 4 | **bogflax_robe** (+37%), **bogflax_leggings** (+33%), **seawrack_robe** (+32%), **seawrack_leggings** (+28%) |

⭐ **The 🔴 row is a real, shipped structural pattern, not a one-off:** in
every Tailoring family that has shipped so far, the **robe and leggings** —
the two highest-material-count pieces — are the ones whose output value
doesn't scale with their material count. The knot/hood/boots/gloves
recipes (2–3 units, no secondary ingredient) all fit the band comfortably;
the moment a recipe needs 4–6 units, the flat per-unit material price this
contract proposes overshoots. **This will recur in every future zone's
Tailoring set** unless a future set's robe/leggings values are set with unit
count in mind, not just the desired HP stat. Proposed corrections:

| Recipe | Shipped output value | Σ(proposed inputs) | Proposed corrected output |
|---|---|---|---|
| `bogflax_robe` | 85 | 140 | **120** (Std 120 / Ornate 144, fits) |
| `bogflax_leggings` | 70 | 112 | **95** (Std 95 / Ornate 114, fits) |
| `seawrack_robe` | 95 | 150 | **135** (Std 135 / Ornate 162, fits) |
| `seawrack_leggings` | 78 | 120 | **105** (Std 105 / Ornate 126, fits) |

### 8.7 Gold faucets

✅ Grepped: the **only** gold faucet in the shipped game is
`Progression.winGold = 30`, awarded flat on any duel win
(`GameState.recordDuelResult`), **PvE loss and flee pay 0** (ruled
2026-08-17, farming-by-losing closed). ⚠️ **Gold does not scale with
opponent level at all** — only XP does (`xpPerOpponentLevel = 5`). No other
faucet exists: no quest gold, no first-clear bonus, no gold in any drop
table, no gold-for-salvage.

⭐ **This is already a deliberate ruling, not an oversight** —
`recordDuelResult`'s own comment says so verbatim: *"Gold is deliberately
still flat — scaling both would make the economy climb as steeply as the
power curve."* Written before any shop existed, it was a bet that gold
wouldn't need to keep pace with anything. A level-60 duel win still pays the
same 30g as a level-1 win, while this contract's Kinetic-tier equipment
values (160–820g) run 5–30× Primal-tier ones (15–30g). That bet is what
this contract's price curve now has to make good on: with no income ramp,
**the shop is the first system that has to absorb the entire tier mismatch
alone**, via location/tier modifiers and Ornate/Master crafting margins,
with no assist from the faucet side. Whether that original bet still holds
now that real prices exist is Decision 4 (§14) — not because the flat design
looks wrong, but because it was never tested against a price curve before.

**Gold/day bounds:** there is no stamina/energy system and no daily gold
cap (✅ ruling 10 — "the curve is the governor"). A Primal zone clear is 9
duels (`commonsPerSectionFor(primal)=2` × 3 sections + 2 minis + 1 boss); a
Kinetic clear is 12 (KINETIC_CONTRACT §1.6). At 30g/win, all-wins: **~270g
per Primal clear, ~360g per Kinetic clear**, with income theoretically
unbounded by anything but real playtime. 📝 For the anti-exploit probe
(§10), a reasonable ceiling to sanity-check against: a sustained, dedicated
session (~80 duels) tops out near **2,400g/day** before any travel-time
overhead — the number the probe's "bounded gold/day" assertion should be
checked against, not a number this contract fixes.

---

## 9. No hard caps; Discordant mode

✅ Ruled: **no hard daily sell/buy caps in v1** — the price curve (§3) is the
governor; a determined player can always trade, but the price moves against
them unit by unit. 📝 Note for the backstop, not built: a hard per-day sell
cap per item stays available as a reserve lever if the curve alone proves
insufficient in practice.

✅ **Discordant mode gets no shops**, verbatim from GAME_DESIGN §5: *"No
trading, no shops, no Concord Market. Everything found or crafted."*
⚠️ **Implementation point:** the shop screen/action must gate on the
character's mode flag, not merely be "unlisted" — a Discordant character
must be structurally unable to reach a buy/sell call, the same way §7's
guardrail keeps `config/economy` out of duel resolution: an optional feature
that merely isn't surfaced in the UI is one API call away from a mode
violation.

---

## 10. Anti-exploit verification (spec only — a build-wave deliverable)

📝 **Spec, per the balance-probe pattern** (`tool/balance_probe_test.dart`):
a new `tool/economy_probe_test.dart`, headless, seeded, gated by an env var
for its deep run (`ECONOMY_PROBE_DEEP=1`), built through the real production
seam (`ItemCatalogue`, `RecipeBook`, the shop pricing function itself — not
a reimplementation of it).

**What it simulates:** a greedy-bot strategy across **1,000 simulated
player-days**: each day, buy the cheapest available materials at every
reachable town (respecting §3.2's marginal pricing), craft whatever recipe
is currently most profitable given owned materials and skill level, vendor
the output (§2.4) or hold it, and haul goods between towns where the
location-modifier spread (§4) makes it profitable (respecting travel time,
§0.1's `TravelTimes`). Deterministic: fixed seed, fixed starting gold/level,
so a re-run reproduces the same report byte-for-byte, exactly like the
balance probe's own contract.

**What it must assert:**
- Gold-per-day, averaged over the run, stays **bounded** — 📝 a ceiling
  near §8.7's ~2,400g/day sanity number, tuned once real numbers exist, not
  invented here.
- No single (buy, craft, vendor) loop is **risk-free positive-EV at
  Standard quality** — i.e. §8's conservation invariant holds in aggregate,
  not just per-recipe-on-paper.
- The marginal-pricing invariant (§3.2): a large single trade's total cost
  must equal the sum of its own per-unit prices, never the batch shortcut.
- Hauling profit stays within the ruled ~36% gross ceiling (§3.1) — if the
  probe finds a route beating that, either the location-modifier table or
  the travel-time model has a hole.

This is a **required deliverable of the build wave**, specced here so the
builder implementing shops writes the probe as part of the same PR, not a
follow-up ticket that never gets picked up.

---

## 11. Schema

### 11.1 Shape

Per ruling 12 and mirroring `PlayerProfile.storerooms` (`Map<String,
Storeroom>`, keyed by town id, ITEMS §10.3c's exact precedent — "one per
city, never a shared pool"):

```dart
/// Per-character shop state, one entry per town this character has visited
/// (or been given a default for). Keyed by town id, matching `storerooms`.
Map<String, TownShopState> shopStock;

class TownShopState {
  /// itemId -> current stock count.
  Map<String, int> stock;
  /// UTC day number (epoch days) this town's stock was last resolved to,
  /// for §6.1's catch-up loop. One clock per town, not per item.
  int lastResetDay;
}
```

`toJson`/`fromJson` mirror `storerooms`' existing shape exactly (a nested
map of maps), including the same `if (!e.value.isEmpty)` sparse-write
pattern already used there — a town the character has never visited need
not appear at all; §6.1's catch-up loop treats an absent entry as "reset
fresh from `E`" the same as a very-stale one.

### 11.2 ⚠️ Belongs directly on `PlayerProfile`, not a subcollection

This is the same argument IMPLEMENTATION_PLAN already made for
`zoneClears` (bounded at 26, needed on every app open, kept off the
`progress/` subcollection reserved for *unbounded* trackers like
`enemiesDefeated`/`dropsSeen`). Shop stock is **more** bounded than
`zoneClears`, not less:

- Town count is fixed at **9 forever** (`World.townIds`) — no new towns are
  a scope item for this game the way new zones are.
- Per-town catalogue size is bounded by that town's shipped item count
  (§2.3: 4–13 today, plausibly 15–30 at full content).
- ⚠️ **It does not grow with player behaviour**, only with shipped content —
  the exact property that makes `dropsSeen` dangerous (grows without bound
  as a player keeps playing) does not apply here.

### 11.3 Size math

At today's catalogue sizes (§2.3's total of 71 stock-entries across 9
towns): each `{itemId: stock}` entry costs roughly 25–30 bytes serialized
(a ~15-character id, an integer, JSON punctuation); each town adds a
`lastResetDay` int and its own key/brace overhead, ~15–20 bytes. **Total:
71 × 28 + 9 × 18 ≈ 2,150 bytes, call it 2.5 KB.**

Against the 1 MiB (1,048,576-byte) ceiling: **≈ 0.24%**. Even a 10×
over-estimate for a fully-content-complete game (every one of 25+ zones
shipped, every town's catalogue grown to 30 items) lands under 25 KB — still
under 2.5% of budget. ⚠️ **No subcollection is warranted, now or at full
content.** This conclusion is the opposite of the `progress/` subcollection
finding for exactly the reason §11.2 gives: this field's size is capped by
*content*, that one's by *play time*.

---

## 12. Out of scope, restated

Per ruling 13: **shop UI** (screens are the designer's separate review),
**the player-to-player Concord Market** (§2.5 specs only its enforcement
seams), and **currency changes** (gold and Resonance Prisms are untouched —
this contract adds a gold *sink* and, indirectly via §8, the first real gold
*prices*, but invents no new currency and changes no existing one's role).

---

## 13. Cross-checks appendix

### 13.1 Counts

| Thing | Count | Check |
|---|---|---|
| Towns | 9 | ✅ `World.townIds.length` |
| Stockable fungible pool | 34 | 29 `MaterialDef` + 2 `ConsumableDef` + 3 `BeltableDef`, minus 0 excluded (§2.2's ingot exclusion is *proposed*, not yet reflected in this count's source data) |
| Shop catalogues fully native-sourceable | 5 of 9 | Hearthwood, Pennycross, Forgeholm, Galehaven, Concordance (partially) |
| Shop catalogues import-only | 4 of 9 | Meridian, Rimeholt, Vespergate, Zenith — §14 Decision 2 |
| Recipes audited | 41 | 20 Primal + 21 Kinetic, ✅ `RecipeBook.all` |
| Materials with an authored value pre-this-contract | 3 of 29 | `rimepelt`, `hoarlichen`, `everice` |
| Recipes passing conservation under proposed values, clean | 20 of 41 | §8.6 |
| Recipes failing conservation even at Master quality | 4 of 41 | §8.6 — all four are the bulkiest piece in a Tailoring set |

### 13.2 Every id this contract names resolves

Every material/consumable id in §2.2–§2.3, §8.2 and §8.6 is checked against
`ItemCatalogue.byId` — this contract invents no new item ids (unlike
KINETIC_CONTRACT, which authored new content; this one only prices and
sells what already exists). The one net-new identifier this contract
introduces is the schema's own `TownShopState` class and the
`config/economy` document path — neither collides with anything shipped.

### 13.3 What the shipped test suite will need

- A pricing-formula unit test pinning §3.1's formula and §3.3's zero-stock
  guard.
- The marginal-vs-batch test named in §3.2.
- A conservation test asserting `Standard < Σ(inputs) < Ornate` for every
  recipe in `RecipeBook.all` once §8.2's values are authored — ⚠️ this test
  **cannot exist yet** against current shipped values (39 of 41 would fail
  on day one); it is a test to add *alongside* the value authoring, not
  before it.
- `tool/economy_probe_test.dart` per §10.
- A Discordant-mode gate test per §9.
- A schema round-trip test for `TownShopState`, mirroring
  `test/` coverage already existing for `Storeroom`.

---

## 14b. ✅ ALL FOUR RULED (Christian, 2026-08-25) — plus two confirmations

1. **Material values are AUDIT-DERIVED** — the conservation invariant governs;
   `oak_log = 13` (the 25 in the worked table was an illustration, kept there
   as an illustration). §8's proposed values incl. the four Tailoring
   robe/leggings corrections are hereby the authored values.
2. **The four content-empty towns are CLOSED at launch** ("the caravans
   haven't come this season") — no import placeholder shelves; each opens
   with its quarter.
3. **Ingots are NOT stocked** — smelting is Metalworking's reason to exist.
   Vendorable, never on a shelf.
4. **Flat 30g/win STANDS** — the anti-inflation ruling survives; the
   greedy-bot probe and playtest own any future revision, with §9's
   2,400g/day ceiling as the probe's assertion.
✅ Also confirmed: the MECHANICALLY-DERIVED location modifiers (§4's
travel-graph rule) — no hand-filled 306-cell table.
📝 Build-wave addition (coordinator, follows from shipped systems): in-town
trades move goods directly shop⇄Storeroom (no backpack constraint locally);
HAULING between towns rides the 20-slot backpack — carry capacity is the
arbitrage governor until Phase 5b mounts add cargo.

## 14c. ✅ Mote ruling (Christian, 2026-08-25)

Motes are **regular tradable items with one vendor value per TIER, uniform
across all elements**: Dust 2g · Shard 25g · Crystal 150g (Core 900g when it
ships). Deliberately LOSSY against §6.1's refinement ladder at every rung
(25 < 50×2, 150 < 20×25, 900 < 12×150) so refine-and-vendor never profits —
pinned by test. **Sell-only at NPC shops**: vendorable, never stocked — the
gather-node ruling ("a mote node would uncouple Enchanting from fighting")
generalizes to an NPC shelf; player-to-player trade is exempt because it is
zero-sum in motes. ⚠️ **Hearts are the one exception**: craft-only (§6.0) is
load-bearing, so Hearts get no value, no vendor path, and Bound tradability
when they ship. The player market inherits all of this unchanged.

## 14. Decisions needed (superseded — see 14b)

⚠️ **Four items. Each is a genuine gap this contract cannot close by
re-reading more code** — either the content doesn't exist yet, or two
instructions this contract received point at different numbers.

### Decision 1 — What governs the base-value scale: 13, or 25?

§8.2's back-solved, conservation-consistent value for `oak_log` is **13**.
The worked-table instruction this contract was given anchors it at **25**
(used verbatim in §5.2, as instructed). These are not close — 25 would make
Oak Quarterstaff and Oak Knot's material cost 150%+ of their Ornate resale
value, a structurally broken recipe rather than a "squeak." **Which number
is the real target for `oak_log`'s shipped `value` field** — and, more
importantly, which *methodology* (conservation-derived, or a flat, higher
per-tier scale like 25) should govern all 26 currently-unauthored materials?
This changes shop prices, the entire §8.2 table, and gold-sink pacing by
close to an order of magnitude, so it is worth Christian's explicit call
rather than this contract silently picking one.

### Decision 2 — What do the four content-empty towns sell at launch?

Meridian, Rimeholt, Vespergate and Zenith border **zero** shipped zones
(§2.1) — their shop catalogues can only be import-only placeholders (§2.3)
until Celestial/Ethereal content ships. Three options, none chosen here:

- **(a)** Ship the shop system uniformly across all 9 towns now; these four
  open with import-only catalogues (as proposed in §2.3) and grow their
  native column automatically as each town's adjacent zones ship — no
  further engine work needed, just future catalogue entries.
- **(b)** Defer opening these four towns' shops until their zone content
  exists — but this contradicts ruling 2's "one general shop per town, all
  nine towns" as a launch-day fact.
- **(c)** Ship placeholder catalogues that are explicitly reduced/no-op
  (e.g. consumables only, no materials) until real content lands.

This contract's tables assume **(a)**, because it requires no future
schema or engine change, but it is Christian's call whether a four-item
Meridian shop reads as charming ("basecamp economy, thin but real") or
broken ("why does this town's shop have nothing").

### Decision 3 — Are crafted intermediates (Bronze/Iron Ingot) shop stock?

§2.2 *proposes* excluding `bronze_ingot`/`iron_ingot` from vendor stock —
they are Metalworking's own output, not a gathered commodity, and stocking
them lets a player buy past the ore-and-charcoal haul entirely. This is a
📝 knob, not a ruling; if overturned, §8.2 already has both ingots' proposed
values (32, 52) ready to use as shop `base` prices.

### Decision 4 — Does the flat-gold ruling still hold now that a price curve exists?

§8.7 finds `winGold = 30` is **flat at every level**, by an existing,
documented ruling (`recordDuelResult`'s own comment: *"scaling both would
make the economy climb as steeply as the power curve"*) made before any shop
existed to spend gold in. Now that this contract prices Kinetic-tier gear at
5–30× Primal values with no income ramp to match, the shop alone carries the
entire tier-pacing burden via location modifiers and crafting margins. That
may still be exactly right — a flat faucet against a curved sink is a
perfectly coherent design — but it was never evaluated against a real price
curve before, and it directly sets what §10's anti-exploit probe should
treat as "normal" vs. "exploit" accumulation. Worth a deliberate reaffirm-or-
revise before the shop ships, not a discovery during balance testing.

---

## Changelog

**2026-08-25 — first draft.** Written against Q1+Q2 shipped content (11
built zones, 110 items, 41 recipes). All thirteen 2026-08-24/25 rulings
encoded. The value-conservation audit is computed from the actual `value`
fields in `ItemCatalogue.byZone` and `RecipeBook.all`, not estimated — and
found that 26 of 29 materials have none, which became this draft's central
finding rather than a footnote.
