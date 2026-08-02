# Masters of Magic 2 — Achievements & Character Progress

Status: 📝 **draft — designed here, nothing built.** Requested 2026-07-28,
revised with Christian's rulings the same day.

Two systems, documented together because one is useless without the other:

1. **Character progress** (§2) — the record of what a character has done.
   Worth building on its own merits; achievements are only its first consumer.
2. **Achievements** (§4 onward) — named milestones read *from* that record.

---

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

⚠️ **`cleared` does not exist anywhere today.** `GameLocation.hasAdventure`
says a zone *has* an encounter, not that you beat it. This is a
campaign-progression feature that achievements merely depend on.

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
session):

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

## 5. The catalogue

### 5.1 Campaign — three achievements per zone ✅

✅ **Ruling: "cleared" is three separate things, not one.** Per zone:

| Achievement | Earned by | Points |
|---|---|---|
| **Clear** — "Woods Walker" | Beat the zone once | 10 |
| **Purge** — "Nothing Left Standing" | Defeat **every enemy type** in it | 25 |
| **Collector** — "Everything the Woods Gave" | See **every possible drop**, rares included | 50 |

⚠️ **The Collector tier is intentionally grindy and genuinely hard**, and is
the one place this system knowingly breaks the "record, not quest" rule (§1).
It is the long tail. Two risks to accept openly:

- It is **hostage to drop rates**. A 0.5% rare across a 40-item table is tens
  of hours per zone. The rates and this achievement must be tuned *together*,
  or it becomes the reason someone quits.
- It **cannot be built before the item catalogue and drop tables exist**
  (Phases 7–8), and it should be revisited once they do.

23 zones × 3 = **69 achievements**, plus capstones:

- **"The Known World"** — clear all 23. 100 points, + title.
- **"Extinction"** — purge all 23. 100 points.
- **"Nothing Left to Find"** — collect all 23. 150 points, + title + cosmetic.

### 5.2 Mastery — charges ✅

- **`<Element>` Mastery I–V** — 12 elements × 5 tiers (§3.1). **60**.
- **"Twelvefold"** — reach Tier I in **all twelve**. 100 points, + title.
  ⭐ The flagship: the one achievement that asks a player to leave the loadout
  they are comfortable in, which is exactly what the twelve-element design
  most wants.
- **"Elementalist"** — all 5 element slots unlocked. 25.

### 5.3 Wealth ✅ (requested)

| Achievement | Earned by | Points |
|---|---|---|
| **Fat Stacks** | Earn 1,000 gold | 5 |
| **Big Money** | Earn 1,000,000 gold | 25 |
| **Tres Commas** | Earn 1,000,000,000 gold | 100 |

⚠️ **Lifetime gold *earned*, not gold *held*.** Held balance would punish
spending — a player who invests in gear would watch progress go backwards, and
the achievement would quietly discourage engaging with the economy. `totals`
(§2.1) tracks the lifetime figure.

❓ **Is a billion reachable?** That depends entirely on an economy that does
not exist yet. If end-game income is ~10k/hour, Tres Commas is 100,000 hours
and is not an achievement but a joke. Keep the name, set the number once the
economy is real.

### 5.4 Duelling

| Achievement | Earned by | Points |
|---|---|---|
| **First Blood** | Win one duel | 5 |
| **Duellist / Veteran / Champion** | Win 10 / 100 / 500 | 10 / 25 / 50 |
| **Giant Slayer** | Beat an opponent 10+ levels above you | 25 |
| **Procarius Falls** | Beat Procarius | 50, + title |
| 📝 **Vanquisher I–V** | Defeat N enemies total | tiered (needs bestiary) |

### 5.5 World

**Wayfarer** (visit 10) · **Cartographer** (visit all 32, + title) ·
**Beyond the Veil** (reach the Empyrean) · **The Long Road** (10 hours
travelled).

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
| 1 | ⛔ **Character progress subcollection** (§2) | everything |
| 2 | ⛔ **Zone `cleared` state** (§2.3) | 23 campaign achievements |
| 3 | ⛔ **Per-element charge counters** (§2.2) | 61 mastery achievements |
| 4 | ⛔ **Lifetime gold earned** (§5.3) | wealth achievements |
| 5 | 📝 **Bestiary** (Phase 6) | purge + vanquisher achievements |
| 6 | 📝 **Item catalogue + drop tables** (Phases 7–8) | collector achievements |
| 7 | 📝 **`DuelSummary`** (§4) | conditional duel achievements only |

⭐ **1–4 are small and worth doing regardless of achievements.** "Which zones
have I cleared", "what do I actually play", and "how much have I earned" are
facts the game should know about itself whether or not a badge is ever drawn.
