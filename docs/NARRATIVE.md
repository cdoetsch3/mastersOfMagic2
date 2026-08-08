# The story

**The overarching narrative.** Per-zone beats live in
[CONTENT_CHECKLIST.md](CONTENT_CHECKLIST.md) column 17; the Primal quarter's
own arc is [GAME_DESIGN.md](GAME_DESIGN.md) §5. This is the spine they hang on.

⭐ **Almost none of this was invented.** It was assembled out of things already
written for other reasons — a gate description, a blurb, one line in an arrival
passage. Where a detail here contradicts nothing, that is because it was
already load-bearing somewhere else.

---

## 1. The premise, in one paragraph

The twelve elements do not naturally agree. Left alone they drift, and where
they meet they contend. ⭐ **Every few generations someone assembles a
Concordant Crown — twelve elemental gems, twelve Cores — and brings them back
into accord.** Those who succeed are admitted to **Zenith**, the summit, and so
are their families. Fifteen years ago the most recent crown-holder tried to end
the cycle for good. It went badly enough that Zenith shut its doors, and they
have not opened since.

You are the child of someone who was inside when they closed.

---

## 2. The past

### 2.1 ✅ The accord decays; Crowns repair it

⭐ **This is the load-bearing fact, and it resolves a timeline problem.** The
Sealed Garden's oath has outlived its faith by *centuries*
(WORLD_DESIGN §4c.1a), so the accord cannot have first broken fifteen years
ago. It has broken and been repaired many times.

⚠️ **The Crown is therefore not a legend — it is an office.** Zenith is full of
families descended from people who each fixed the world once. That is why it is
hereditary, and why the Buried Sky's *"this has all happened before"* is
literal rather than atmospheric.

### 2.2 ✅ Procarius, and what he actually did

Procarius earned his Crown the ordinary way: twelve elements, one at a time,
across a whole world. He got in.

⭐ **And he was still an outsider — a self-made man in a room full of heirs.**
Everyone else in Zenith was born to it.

⭐ **So he tried to make the accord permanent.** Not to seize anything: to fix
the twelve in agreement *forever*, so that no one would ever have to climb
again and no one would ever again be let in on sufferance. It is the act of a
man proving he deserved the room.

⚠️ **The elements are parties, not forces** (GAME_DESIGN §5). Forcing permanent
agreement is coercion, and they have been contending ever since *precisely
because they were once made not to*. The discord in every hybrid zone is not
damage. It is a reaction.

⭐ **It is also why Arcane left.** Arcane is the one element with no natural
referent and no ground of its own (WORLD_DESIGN §1.2). Told to be fixed in
place, it had nothing to be fixed *to* — so it went up through the Veil rather
than be bound. **The Glass Archive is the door it went out of.**

### 2.3 ✅ The sealing

The binding failed and Procarius was driven out. ⚠️ **Zenith then sealed itself
against his return** — not against the world, against *him*. That is what
Zenith's own arrival text has always meant:

> *"The doors were never locked from the inside."*

⭐ He has been standing outside the **Eclipsed Citadel** ever since: *"the door
back into the world, and the thing standing in it."* He is not guarding it
against you. **He is still trying to get back in, and you have what he needs.**

---

## 3. The family

### 3.1 ✅ The father — one of Zenith's rulers

A senior mage and a member of Zenith's council. In the weeks before the
sealing he could feel something going wrong and feared his wife would be taken
as leverage, so **he sent her down out of the city to the quietest place he
knew** and stayed to steady things.

⭐ **He did not abandon anyone.** The citizens shut the doors against his will —
or he chose to stay out of duty and left it too late. ⚠️ **Which of those it was
is deliberately unresolved**, and the game should not answer it until the
player is through the door. It is the reason the ending is *about* something
rather than merely won.

### 3.2 ✅ The mother — fifteen years in Aldermere

⭐ **The quiet place he chose is Aldermere**, *"a wooded river valley where
every mage begins."* The starting town is not arbitrary. It is a refuge, picked
because nothing happens there, and you were raised in it without being told
why.

⭐ **She knows the beginning and none of the middle.** She can tell you what
Zenith was, what a Crown is for, and what your father feared — but she has been
outside for fifteen years, the roads have changed, and she has no idea what the
world has become in the meantime. ⚠️ **That is the right shape for a tutorial
voice:** she is authoritative about the past and unreliable about the present,
so she can explain the rules without solving the game.

She has been waiting the whole time.

---

## 4. What the player is doing

Assembling a Crown. ⭐ **Twelve elements, one at a time, across a whole
world — which is exactly what Procarius did, and exactly how he did it.**

⭐⭐ **The method is the moral.** His Crown failed because at the summit he
tried to *command* the accord. Yours works because you spent sixty levels
earning agreement from twelve elements individually, in their own places, on
their terms. **Same object, opposite act.** That is what the entire climb has
been, and it is why beating Procarius resolves anything at all.

⚠️ **This is the trap the ending must not fall into.** If your Crown restores
the accord by the same coercion his did, you have repeated his mistake and the
game has no thesis. The difference is not power. It is consent.

---

## 4b. ✅ Why the player goes anywhere

⭐ **Three kinds of reason, and two of them already exist in `world.dart`.**

### 4b.1 The twelve pure zones ARE the Crown

⭐⭐ **Twelve elements. Twelve pure zones. Twelve gems.** The map already has
exactly one pure zone per element — `world_test.dart` asserts it — so the
critical path is the right length without inventing anything.

⭐ **A pure zone is the only place its element exists undiluted**, which is why
it is the only place you can ask that element for agreement. Everywhere else it
is already arguing with something.

⚠️ **The player does not start knowing this.** The mother knows a Crown is
twelve elements; she does not know where any of them are, or that "earning
agreement" now means going and asking. Discovery is the first act.

### 4b.2 The five gates are the intermediate waypoints

⚠️ **These are already written and have never been given a reason to exist.**

| Gate | At | Wants |
|---|---|---|
| Three ordinary proofs | Aldermere → the north road | 1 per Primal zone, incl. `proof_of_the_woods` ✅ **built** |
| The Kinetic Sigil, in three parts | Concordance (30) | The Kinetic quarter |
| A Celestial Totem — Solar, Lunar, Astral essences | above Rimeholt (45) | The three Celestial pure zones |
| Three Ethereal key fragments | The Eclipsed Citadel | The Ethereal quarter |
| **The Concordant Crown** | Zenith (60) | All twelve |

⭐ **The reason: the gates are how Zenith's descendants control the climb.**
Each was set by crown-holding families to stop anyone reaching the summit
unprepared — and after Procarius, *unprepared* was redefined as *untested*.
⚠️ **Every gate is the aristocracy vetting you**, which is why they escalate
and why the last one is the Crown itself.

⭐ That gives the whole climb a shape the player can feel: four checkpoints,
each demanding you prove you have been somewhere, before the fifth demands you
prove you have been everywhere.

### 4b.3 The thirteen hybrids are optional, and they are the story

⭐ **The Crown is made from agreement; the story is found in disagreement.** A
hybrid zone is where two elements meet and contend — so it is where the discord
is *visible*, and where its cause can be learned.

⭐⭐ **A player who skips every hybrid finishes the game exactly the way
Procarius did: with the power and none of the understanding.** That is the
reason hybrids can be optional and still matter. They are not side content —
they are the difference between winning and knowing what you won.

⚠️ **So they must be highly valuable without being required.** They already
hold the Tier III/IV Bound set components (ITEMS §3.5), which is the mechanical
half. The narrative half is that each one explains a piece of what happened.

### 4b.4 ⭐ The chain that ends the game

**The Unwritten Library → the Citadel → Zenith.**

📝 **The Library is where you learn what Procarius actually did.** Something
there is writing, by nobody, and *"it would like your name for the record"* —
⭐ **it has the record.** Every Crown, every holder, every sealing. It is the
last optional zone in the game and it holds the deepest answer, which is the
right place for it.

⚠️ **It is a hybrid, so it is skippable** — deliberately. You can walk into the
Citadel having never learned why Procarius is standing there.

---

## 5. How each quarter carries it

| Quarter | What the player learns | Where |
|---|---|---|
| **Primal** 1–14 | ⭐ Elements are **parties**, not forces. They want things, and where they meet they contend | The five zone themes, GAME_DESIGN §5 |
| **Kinetic** 15–29 | The discord is **recent and worsening** — old people remember when it was not like this | 📝 Needs writing |
| **Celestial** 30–44 | It has **happened before**, many times, and someone has always fixed it | The Buried Sky; the Crown as an office |
| **Ethereal** 45–60 | ⭐ It was **made** to happen. The Garden is what accord looked like; the Archive is the door Arcane left by; the Citadel is the man who did it | Sealed Garden, Glass Archive, Citadel |

⭐ **The Primal quarter gains a reason it did not have.** It teaches that
elements have wills; forty levels later you learn someone tried to override
those wills. The lesson and its payoff are separated by the whole game.

📝 **The Kinetic quarter is the thin one** — it currently carries no story beat
at all, and it is the natural home for "this is recent." Six zones with nothing
to say is the biggest narrative gap in the game.

---

## 6. The ending

You reach the Citadel with a finished Crown. Procarius wants it — not to rule,
but because it is the only thing that opens the door he has been locked out of
for fifteen years. ⚠️ **He is a warning, not a monster:** he is what happens to
someone who does exactly what you are doing and then cannot stop.

Beyond him is Zenith, and your father, and the answer to whether he was trapped
or chose to stay.

❓ **Open: does the world visibly heal?** A restored accord should be *felt* —
⭐ perhaps the hybrid zones stop contending, which would be a mechanical change
the player can see rather than a cutscene claim. Unspecified for now.

---

## 7. Constraints anything written here must respect

- ⚠️ **Zones are re-run**, for materials and for the Purge achievement. No beat
  may destroy a place or close it off (ITEMS, ACHIEVEMENTS §2.3).
- ⚠️ **Discordant mode** has no trading and no shops; **Mortal mode** ends the
  character on defeat (GAME_DESIGN §5). ⭐ Nothing in this story may require
  either of those, so no beat can hinge on buying something or on surviving a
  scripted death.
- ⚠️ **Tier-1 narrative must be skippable.** A returning player who cannot
  dismiss a story screen comes to resent it (GAME_DESIGN §5).
- ⭐ **Everything above is assembled from committed text.** Changing Zenith's
  gate, the Citadel's blurb, or Aldermere's arrival changes the story.

---

## 8. ❓ Still open

- **What Zenith is actually like inside**, and whether the player stays.
- **The Kinetic quarter's beat** — six zones, nothing to say yet.
- **Whether the mother is a recurring voice** or only a prologue.
- **How the player learns any of this.** Tier-1 narrative screens are designed
  but unbuilt (GAME_DESIGN §5), and this story currently has nowhere to appear.
- ⛔ **Four of the five gates are prose with no items behind them.** Only
  `proof_of_the_woods` exists. The Kinetic Sigil, the Celestial Totem, the
  Ethereal fragments and the Crown are all still just strings — and §4b.2 now
  makes them the backbone of the climb.
- **What each hybrid explains.** Thirteen zones, thirteen pieces of the story,
  none written.
- **Whether the world visibly heals** at the end (§6).
