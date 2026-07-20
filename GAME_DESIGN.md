# Masters of Magic 2 — Game Design

A remake/sequel of Masters of Magic (MoM1). Flutter app targeting phones, tablets, and browsers.

Legend: ✅ decided · 📝 draft (needs review) · 💡 idea bank (later) · ❓ open question

---

## 1. Core Combat ("Mage Duel")

✅ Turn-based 1v1 duel with **simultaneous turns** — both players lock in a move,
then the round resolves. Prediction/mind-games are the heart of the game.

### Turn flow
1. If you have **0 charge**, you first choose a **Magic Element** for this casting cycle.
2. Each turn you either:
   - **Charge** ("begin casting" — final term TBD): +1 charge, no attack or defense this turn. Max charge = 5.
   - **Cast a spell** with `charge cost <= current charge`.
3. ✅ Casting a spell **consumes ALL charge** (even leftover above the spell's cost) and ends the cycle — next turn you pick a new element.
4. ✅ You must keep the **same element** for an entire charging cycle (baseline rule).
5. ✅ 0-cost spells (e.g. Flick) can always be cast, even at 0 charge — you're never forced to charge.

### Resolution order — Priority
✅ Formalized, transparent **Priority 1–10** property on every spell (priority 1 acts first):

| Priority | Category |
|---|---|
| 1 | Instant attacks |
| 3 | Shields |
| 4 | **Channel** (charging) |
| 5 | Quick attacks (Flick, Jolt) |
| 7 | Other defensive / aux spells |
| 9 | Regular spells |
| — | End-of-turn effects (burn ticks, etc.) |

- 📝 Aux spells may modify priority (e.g. "your next spell acts X sooner").
- ✅ **Channel has priority 4** (after shields, before quick attacks). This is why a
  faster Discharge (7) or Overload (7) interacts with a same-turn channel — see below.
- ✅ Charge-scaling spells (Barrage, Overload) read charge **live at resolution**, so a
  faster Discharge fizzles a same-turn Barrage, and channeling right before an Overload
  makes the hit bigger.
- ✅ A mage defeated at an earlier priority step does **not** resolve casts at later
  steps (e.g. a Quickened kill at priority 2 prevents the victim's priority-9 attack).

### Haste (initiative tiebreaker)
✅ A single **Haste** token — held by nobody, you, or your opponent — breaks
same-priority collisions: **the holder's spell resolves first**, so a lethal hit lands
before the opponent can fire back. This replaces the old "same-priority mutual kills are
a draw" rule (draws dropped from ~12% to ~0% in AI-vs-AI sims once Haste was added).
- Only consulted for same-priority ties, using the **start-of-turn** holder.
- **While unheld:** the first non-channel cast grabs it; if both cast, the faster one
  grabs it; a same-priority pair leaves it unheld.
- **Once held:** only a Haste-granting spell (Hasty, Jolt) moves it, and it goes to the
  **last grant to resolve**. So a same-priority pair **flips it to the opponent** (the
  holder resolves first via the tiebreak, so the other's grant lands last and steals
  it); among different-priority grants the slower one wins. Ordinary spells don't move it.
- Channeling never grants or moves Haste.

### Health
- MoM1: everyone started at 100 HP.
- ✅ MoM2: base HP modified by **equipment**.

---

## 2. Elements

✅ Elements matter **only for shield math** (double damage vs countered shields) — attacks
against a player's bare health are element-neutral. The element is information/bluffing:
your shield's color reveals its element.

✅ Launch roster (8): Earth, Fire, Water, Air, Electric, Ice, Light, Shadow.
💡 More elements may be added later as unlockables.

📝 **Superseding proposal:** [TYPE_EFFECTS_DESIGN.md](TYPE_EFFECTS_DESIGN.md)
— a 9-element roster in three tiers with per-element side-effects. Renames:
Water→Aqua, Fire→Pyro, Electric→Electro, Air→Aero, Earth→Geo, Light→Radiant,
Shadow→Umbra; adds Flora and Arcane; drops Ice. Not yet implemented; see that
doc for the balance review and open questions.

### Counter wheel — 📝 DRAFT proposal (variable volatility)

✅ Rule: elements need not all have 2 strengths / 2 weaknesses. The only invariant is
**per-element balance**: # strengths == # weaknesses. Different counts = different
"volatility", which is itself a strategic identity. Mutual counters are legal under
this rule (each adds one to both columns) but the current draft uses none.

| Element | Volatility | Strong against (2× to their shields) | Weak against |
|---|---|---|---|
| Air | 0/0 | — | — |
| Fire | 2/2 | Ice, Shadow | Water, Light |
| Water | 2/2 | Fire, Light | Electric, Shadow |
| Earth | 2/2 | Electric, Light | Ice, Shadow |
| Electric | 2/2 | Water, Shadow | Earth, Light |
| Ice | 2/2 | Earth, Light | Fire, Shadow |
| Light | 3/3 | Shadow, Fire, Electric | Water, Earth, Ice |
| Shadow | 3/3 | Water, Earth, Ice | Light, Fire, Electric |

Flavor / mnemonics:
- **Air** — "the untouchable wind": counters nothing, countered by nothing. Its shields
  can never be double-broken (safest, zero info leaked), but its attacks never crack
  shields. The poker player's element.
- **Light outshines every other light source** (Fire, Electric, Shadow) but is swallowed
  by the dark places (deep Water, stone Earth, entombing Ice).
- **Shadow claims the dark places** (the depths, the caverns, the long cold night) but is
  banished by everything that glows (Light, firelight, lightning).
- Classics keep intuitive pairings: Water douses Fire; Fire melts Ice; permafrost
  shatters stone; Ice cracks under flame; Earth grounds Electric; Electric conducts
  through Water.
- ⚖️ Balance watch: if Air's "never double-broken shield" proves dominant, tune with
  slightly weaker Air shields or juicier side effects on volatile elements (verify via
  AI-vs-AI simulation).

### Elemental side effects — 📝 draft, per-element status effects
- Fire → **Burn** (damage over time)
- Ice → **Freeze**
- Shadow → accuracy loss
- ❓ Others TBD (Electric → stun/paralyze? Water → ? Earth → ? Air → ? Light → ?)

---

## 3. Spells

✅ Spells are **element-agnostic** — any spell takes on your currently charged element
(a Bolt can be a Fire Bolt or Water Bolt, etc.).

✅ **Damage variance**: every damaging spell rolls within an explicit min–max range
(~10–15% around its center, e.g. 4–6, 11–14, 20–26). Each hit of a multi-hit spell
rolls independently. **Shields roll too**, with a **tiny overlap** between a max-roll
attack and a min-roll shield at the same charge level.

✅ **Information rules**: the opponent **can see the element you're charging** (and your
charge count). 💡 A future **Concealed** status (a Shadow side-effect) will hide the
charging element again — the "mystery ?" code path is kept for it. Shields always
visibly carry their element ("the shield's color reveals it").

✅ Loadout: before a match you choose which elements and spells you bring.
MoM2 adds **spell slots** unlocked via leveling.

### Flat-damage offensive
| Spell | Charge | Notes |
|---|---|---|
| Flick | 0 | very low damage |
| Bolt | 1 | low damage |
| Blast | 2 | medium damage |
| *(a few mid-tier spells)* | 3–4 | TBD |
| Cataclysm | 5 | very high damage |

### Multi-hit offensive
| Spell | Charge | Notes |
|---|---|---|
| Flurry | 1 | small damage ×3 |
| Volley | 3 | medium damage ×4 |
| Barrage | X | damage per charge spent (consumes all charge) |

### Lifesteal offensive (heal = damage actually dealt to enemy **health**, not shields)
| Spell | Charge | Notes |
|---|---|---|
| Sap | 1 | small damage |
| Leech | 3 | medium damage |
| Drain | 5 | high damage |

### Defensive
- ✅ One elemental shield per charge level. Shield strength scales **linearly with
  charge** (midpoint 15 × charge: a 4-charge shield is exactly 2× a 2-charge shield);
  attacks scale super-linearly, so offense slowly catches up to defense at high charge.
- ✅ Shields resolve **before** regular attacks (priority 3 vs 9).
- ✅ Counter-element attacks deal **2× damage to the shield**; overflow damage passes
  through to the player at normal (1×) rate. (e.g. 30-dmg water attack vs 50-pt fire
  shield: 25 of the 30 breaks the shield at 2×, remaining 5 hits the player.)
- ✅ **Barrier** (2-charge): blocks 100% of all damage, destroyed after the first hit.
- ✅ **Shield persistence**: players start with **one shield slot**. A cast shield persists
  across turns until depleted or overwritten by casting a new shield.
- 💡 Unlockable 2nd and 3rd shield tiers (multiple simultaneous shields) later.
- 💡 Shield duration types: **permanent** (more expensive) vs **decaying over time**
  (cheaper, good in a pinch). Engine should model shield lifetime from day 1.

### Aux (priority 7 unless noted)
- **Empower** (3) — next offensive spell deals double damage
- **Quicken** (2) — next offensive spell executes before enemy defensives
- **Phase** (3) — next offensive spell ignores shields
- **Hasty** (0) — seizes Haste, nothing else
- **Discharge** (3) — removes ALL of the opponent's charge, no damage (fizzles a
  same-turn Barrage since it's faster)
- **Overload** (2) — a full attack (respects shields, benefits from Empower/Phase)
  dealing ~8–12 damage × the **enemy's** charge, read live at resolution
- **Jolt** is a quick attack (priority 5) that also **grants Haste**
- **Flick** is now a quick attack (priority 5)

---

## 4. Progression & Meta

- ✅ **Levels & XP** — more XP unlocks more spells and spell slots. Single-player is the
  primary source of XP, gold, and loot.
- 📝 **Superseding spec:** [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) — L1–50
  curve (level 40 = halfway XP point), the L1–L50 unlock schedule (charge caps,
  element tiers, spells), non-combat XP, and the **unified slot pool** below.
- 📝 **Spell unlocking**: likely a "studying" timer per spell, skippable with premium
  currency (exact mechanism TBD). Managed from the Spellbook tab. **Temporarily all
  spells are unlocked** until the leveling/unlock schedule is implemented.
- ✅ **Loadout capacity (reworked)**: one pool of **slots shared between elements and
  spells** (5 total at L1, growing with level) — 4 elements + 1 spell or 1 element +
  4 spells are both legal splits. Presets must include ≥1 element and ≥1 offensive
  spell. Supersedes the old "3 element slots + 5 spell slots" split. (Keybinds still
  support up to 8 elements / 10 spells.)
- ✅ **Loadout presets**: named spell/element presets in the Spellbook tab. 1 preset
  slot initially, up to 5 unlocked by leveling.
- ✅ **Loadout switching rules**: in 1-player mode, loadouts can only be changed at a
  dedicated location in town; in PvP, the player picks a loadout before each match.
- ✅ **Equipment** — items affect stats including max HP. Dropped as loot.
  - ✅ Slots: **Hat, Top, Bottom, Boots, Hands, Neck, Ring, Left hand, Right hand**.
    - Hands = worn gear (gloves or bracers), separate from held items.
    - Held items: one-handed weapons (wand) pair with an off-hand (orb, book,
      shield); **two-handed weapons (staves) occupy both hand slots**.
  - ❓ Rarity tiers TBD (e.g. common → legendary).
  - ❓ Are held items restricted by slot (wand = right only?) or freely assignable?
- ✅ **Luck** — a stat influenced by items/enchantments that increases gold quantity
  and the likelihood of rare drops.
- 🎨 Creative north star: **RuneScape 3** — take inspiration from its equipment/skilling/
  economy feel without plagiarizing or copying assets/names.
- 💡 **Consumables** — potions purchasable/usable.
- 💡 **Enchantments** — enhance equipment.
- 💡 **Crafting** — craft equipment from raw materials.
- ✅ **Daily & weekly quests** for bonus XP.

### Economy / freemium
- ✅ Gold = primary currency (earned in-game).
- ✅ Secondary (premium) currency, primarily from microtransactions.
- ✅ Time-gated processes (crafting, enchanting) skippable with premium currency.

---

## 5. Game Modes

- ✅ **Online 1v1 PvP** with **Elo + ranking system** — the foundation of the game,
  though single-player is built first.
- ✅ **Single-player campaign**: battle increasingly difficult monsters that drop
  increasingly good loot. Primary XP/gold/loot source.
  - ✅ Monsters fight by the **exact same rules** as players (elements, charges, spells,
    shields) with an AI brain.

### Adventure loop (push-your-luck)
- ✅ **HP persists between encounters** within an adventure. After each encounter the
  player chooses **"return to town"** (bank the loot) or **"keep going"**.
- ✅ Rewards improve the deeper you push into a single run — and so does the competition.
- ✅ Each area has **5–7 monster types**, a **mini-boss** roughly halfway, and a **boss**
  at the end.
- ✅ **Defeat penalty**: lose the run and **all loot earned during it**, plus a
  **respawn timer** that escalates with each sequential death. Death-timer reset is a
  freemium option.
  - 📝 Escalation details TBD (how fast it grows, how it cools down over time).
- 📝 Assumption to confirm: charge/shields reset between encounters; only HP carries.
- ✅ **No energy/stamina gate for v1** — deliberately deferred.
  - 💡 Gentler "take a break" alternatives to consider later: rested bonus (first N runs
    per day get bonus XP/luck), daily-quest cadence as the natural session shape,
    diminishing returns after many consecutive runs.

### World structure
- ✅ Pokemon-style topology: safe **hub towns** connected by **dangerous routes**, plus
  offshoot dangerous areas branching from towns/paths. All players start in one home
  town; difficulty scales with distance from home.
- ✅ **No walking/terrain simulation** — simple menu-based travel ("Travel to X",
  "Venture into the forest").
- ✅ Each adventure/route shows its **encounter count** up front so progress is visible
  (e.g. "encounter 3 of 7").
- ✅ Areas are **element-themed** (volcano = fire+earth monsters, icy pass = ice+air,
  shadowlands = shadow, etc.).

### World map — 📝 DRAFT region brainstorm (names/levels all tunable)

| Ring | Region | Type | Elements | Lv |
|---|---|---|---|---|
| 0 | **Aldermere** | home town | — | — |
| 1 | Whispering Woods | route | Earth, Air | 1–5 |
| 1 | Glimmerbrook | route | Water, Light | 2–6 |
| 1 | Old Quarry | offshoot of Whispering Woods | Earth | 4–8 |
| 2 | **Forgeholm** | mining town | — | — |
| 2 | Cinderpeak Foothills | route (Aldermere→Forgeholm) | Fire, Earth | 8–14 |
| 2 | **Galehaven** | port town | — | — |
| 2 | Stormcliff Coast | route (Aldermere→Galehaven) | Water, Electric | 8–14 |
| 3 | The Caldera | offshoot of Forgeholm | Fire | 15–22 |
| 3 | Crystal Caverns | offshoot of Forgeholm | Earth, Light | 16–24 |
| 3 | Frostfell Pass | route (Forgeholm→Rimeholt) | Ice, Air | 18–26 |
| 4 | **Rimeholt** | mountain village | — | — |
| 4 | The Mirrormere | offshoot of Rimeholt (frozen lake) | Water, Ice | 26–34 |
| 4 | Thunderspire Peaks | route (Galehaven→Rimeholt) | Electric, Air | 26–34 |
| 4 | Radiant Sanctum | offshoot of Rimeholt | Light | 30–38 |
| 5 | Nightfen Marsh | route (Rimeholt→wastes) | Water, Shadow | 38–46 |
| 5 | The Umbral Wastes | far-edge region | Shadow | 45–55 |
| 5 | The Eclipsed Citadel | final dungeon | Shadow, Light | 55+ |

---

## 5b. Accounts & Backend

- ✅ **Firebase** is the backend (Auth + Firestore; Cloud Functions later for PvP
  resolution and Elo).
- ✅ Even single-player saves persist to the cloud (with local cache for offline play).
- ✅ Account creation requires: **validated email**, **password**, **character name**,
  and a **captcha**.
  - 📝 Implementation: Firebase Auth (email/password + email verification link);
    bot protection via Firebase App Check — reCAPTCHA on web, Play Integrity (Android)
    / App Attest (iOS) on mobile, so mobile users don't see a visible captcha.
  - ❓ Character name uniqueness rules & change policy.
- 📝 PvP integrity: simultaneous turns require server-authoritative resolution
  (or commit-reveal) via Cloud Functions so a client can't peek at the opponent's move.

---

## 6. Duel screen UI (v1)

- ✅ **Landscape phone layout** ("arena" direction): your mage on the left, enemy on
  the right, status panels in the top corners, spell bar along the bottom.
- ✅ **Not card/deck based** — spells are icon buttons.
- ✅ **Character graphics**: fine-pixel (32x44) statically drawn mages with shading;
  apparel (hat, robe, boots, staff...) is visible and palette-swaps with equipment.
  (Upgraded from 16x22 after playtest feedback that it read as too blocky.)
- ✅ **Spell animations**: charge swirls, projectiles in the cast element's color,
  shield domes, hit flashes, floating damage numbers, defeat animation.
- ✅ **Tooltips** on spell icons: cost, priority (with category name), damage range,
  description. Element icons show strengths/weaknesses.
- ✅ **Action bar layout**: element slots on top, then two rows of five spell slots so
  the QWERT and ASDFG shortcut rows align like a keyboard; Channel to the right.
- ✅ **Keyboard shortcuts** bind to SLOTS, not contents: 1-8 = element slots,
  QWERT/ASDFG = spell slots 1-10, C = channel. Slots are unlockable later.
- ✅ **Surrender** (PvP) / **Flee** (campaign): forfeits the match as a loss, behind a
  confirmation dialog. Engine support: `DuelEngine.concede()`.
- ✅ Turn resolution plays events in priority order as an animated sequence whose
  intensity scales with charge spent (bigger projectiles, more impact rings, screen
  shake at 3+ charge, full-screen flash at Cataclysm tier).

---

## 7. 💡 Idea Bank (banked for later — do not build yet)

1. **Multi-element charging** — an upgrade allowing charging different elements in one
   cycle and dealing damage of multiple types.
2. **Charge retention** — upgrade/ability to keep unused charge after casting.
3. **Element conversion** — a 2-charge spell converting remaining charge to a new element.
4. **Elemental attunement / transformation** — a spell that makes the caster "become" an
   element (fire elemental, shadow demon...): +X% to attacks of that type, but your own
   health becomes subject to shield-cracking counter logic.
5. **Unlockable elements** beyond the launch 8.
6. **Priority-boosting aux spells** (priority +X per charge or similar).
7. **Duel-mechanic stats on hand slots** — make the one-hand-plus-off-hand vs
   two-hand choice a playstyle decision, not just a stat trade: e.g. wand boosts
   1–2 charge spells; staff boosts 4–5 charge spells but costs the off-hand;
   off-hand shield strengthens shield spells; tome improves aux buffs.
8. **Tiamonds** — a consumable/currency that instantly **skips time-gated
   processes** (travel, crafting, researching/studying). ❓ Relationship to the
   existing premium currency ("gems") TBD — Tiamonds may BE the premium currency
   renamed, or a distinct time-skip item earned/bought separately.
9. **Timed travel** — traveling between locations takes real time. Early legs
   ~10–15s; scales up to hours for distant regions. Skippable with [8] Tiamonds.
   (Pairs with the crafting/research timers as the core freemium time-gate loop.)
10. **First-visit town gate** — unlocking a town for the first time requires
    completing a one-time **required adventure** (a gating encounter) before the
    town's services open. ❓ Design: towns currently have no adventure of their
    own — likely a boss encounter on the approaching route, or a special
    town-intro fight.

---

## 8. App structure & roadmap

### Navigation (phone-first)
- ✅ Five tabs: **Map · Inventory · Home · Spellbook · Social**.
  - **Map**: current location, travel, location-specific actions (shop, etc.);
    campaign adventures launch from here.
  - **Inventory**: items + crafting (transmute / craft / salvage). Unlimited space.
  - **Home** (center): dashboard — quests, resume adventure, PvP queue, timers,
    currencies, events.
  - **Spellbook**: spell collection, unlocks (studying timers), loadout presets.
  - **Social**: friends & challenges (stub for now).
- ✅ Duels are landscape; menu orientation decided via mockups (avoid forcing the
  player to flip back and forth).

### Data model
- ✅ `PlayerProfile` and friends are shaped as Firestore documents from day 1, but
  persisted locally until the Firebase project is initialized.

### Phase 1 — ✅ SHIPPED
Live at **https://mastersofmagic2.web.app** (Firebase project `mastersofmagic2`).
Five-tab nav (Option C: raised center Home button with a **magic-wand** icon;
bottom bar in portrait, left rail in landscape), map travel + location actions
("visit shop" placeholder), campaign adventures with XP/gold rewards and
level-ups, inventory placeholder, spellbook with presets, rotate-to-duel guard
(menus any orientation, duels landscape). Find-a-duel is a pinned bottom CTA.
- ✅ **Firebase Auth** (email/password): create-account (character name, email,
  password, confirm), sign-in, email-verification send, sign-out — reachable
  from the Social tab; guest play preserved (no gate). Email/password worked
  out of the box (client init provisioned the Auth config); no console toggle
  needed. **Captcha via App Check is still pending** a reCAPTCHA key.
- ✅ Loadout caps: **3 element + 5 spell slots**; **all spells unlocked** for now;
  old saves auto-clamped on load.
- ✅ Hosting cache: app-shell files (`index.html`, `flutter_bootstrap.js`,
  `flutter_service_worker.js`, `main.dart.js`) serve `Cache-Control: no-cache`
  so returning players always get the latest build.
- ✅ Stale-build fix: builds use `--pwa-strategy=none` (no service worker), and a
  **kill-switch service worker** ships at the old worker's URL to purge caches,
  unregister, and reload clients that installed the early offline-first worker.
  (`web/flutter_service_worker.js` must be copied into `build/web/` post-build —
  the build empties that reserved filename.)
- ✅ **About panel** (app name + version) on the Account screen near Sign out;
  version constant lives in `lib/game/app_version.dart` (keep in sync with
  pubspec). Currently **v0.2.0 (2)**.
- ✅ **Pixel wizard-hat favicon** + PWA icons (generated, in `web/`); page title
  and manifest branded "Masters of Magic 2".
- ✅ Desktop layout: tab content is centered in a **720px max-width column**;
  the spellbook grid uses fixed-size tiles (no more giant cards on monitors).
- ⚠️ A throwaway test account (`zephyr@example.com`) exists from verifying signup;
  delete from the console if desired.
Deploy:
```
flutter build web --release --pwa-strategy=none
cp web/flutter_service_worker.js build/web/flutter_service_worker.js
firebase deploy --only hosting
```

### Multiplayer architecture (v0.8.0)
- ✅ **Matchmaking is separate from dueling**: quick match / friendly room codes /
  practice roster all just produce an `OpponentDriver`; the duel screen and engine
  never know whether the opponent is human or AI.
- ✅ **Commit-reveal over Firestore** (trustless): per turn both clients write
  `sha256(move|nonce)`, then reveal; each verifies the other and resolves the turn
  locally on the shared deterministic engine, seeded by `deriveTurnSeed(master, turn,
  moveA, moveB)` — proven by a lockstep engine test.
- ✅ **Quick match**: claims a waiting queue ticket (Firestore transaction) or posts
  one; if no human answers within ~10s, an **AI persona stands in** (nearest level).
- ✅ **AI roster**: Wick(1), Brightgale(3), Thornwall(5), Morwen(8), Procarius(12) —
  distinct loadouts, apparel, and TunableAi skill dials (mistakeChance/aggression/
  caution). Campaign foes reuse the nearest persona re-skinned with the monster name.
- ✅ **Disconnects**: the 10s move timer forfeits unmade moves; a vanished remote
  opponent is auto-forfeited each turn until they lose.
- 📝 v1 trust model: room codes are secrets, rules require sign-in; server-authoritative
  arbitration deferred until ranked play.

### Phase 2 (next)
Starts with the inventory/crafting/item-catalog design session: align on level
tiers, build tiers 1–2, playtest, then extend tiers as the game matures.

---

## 9. ❓ Open Questions

1. Counter wheel assignments (variable-volatility draft above needs sign-off).
2. Status-effect roster for the remaining elements.
3. Exact damage/shield numbers table (engine + simulator now exist; needs a balance pass).
4. Equipment rarity tiers.
5. Respawn-timer escalation curve (growth per sequential death, cooldown).
6. Do charge/shields reset between encounters within a run? (assumed yes)
7. Character name uniqueness & change policy.
