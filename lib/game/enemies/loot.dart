/// Rolling a kill into actual things.
///
/// ⚠️ **Not lockstep-critical.** Loot is PvE and resolves on one client, so it
/// draws from an ordinary `Random` rather than the duel's shared per-turn seed.
/// ⭐ Keep it that way — routing loot through the duel seed would make every
/// drop a netcode concern for no benefit.
library;

import 'dart:math';

import '../items/item_catalogue.dart';
import '../items/item_instance.dart';
import 'drop_table.dart';

/// **The one generator every production loot roll draws from.**
///
/// ⭐ One long-lived stream rather than a fresh `Random()` per kill. Both are
/// sound on both backends — see below — but a single stream is the version
/// that stays sound no matter what a future SDK does with unseeded seeding,
/// and it removes the need to reason about the question at all. Tests keep
/// passing their own seeded `Random`; only the unseeded production path lands
/// here.
///
/// 📝 **The web-seeding audit (2026-08-17), so nobody has to redo it.** The
/// reported "boss Epic three runs running" was suspected to be a dart2js
/// seeding artefact — many `Random()` built inside one millisecond sharing a
/// clock-derived seed. That cannot happen on either backend we ship:
///
/// - **dart2js**: `Random()` with no seed returns `const _JSRandom()` — a
///   *const* singleton with no state and no seed at all, delegating every draw
///   straight to JS `Math.random()`. There is nothing to correlate: every
///   `Random()` in the program is literally the same object, and the clock is
///   never consulted. `nextInt(max)` is `(Math.random() * max) >>> 0`, an exact
///   floor for every `max` these tables use (all ≤ 100, and `_mintId`'s 16), so
///   ⚠️ the 32-bit `>>> 0` truncation is not a bias source either — it only
///   becomes one above 2^32, which `nextInt` rejects outright.
/// - **Dart VM**: `Random()` with no seed takes `_setupSeed(_nextSeed())`, and
///   `_nextSeed()` *advances a global PRNG* seeded from the VM entropy source.
///   No clock in that path either, so same-millisecond construction still
///   yields decorrelated streams.
///
/// So the streak was luck (0.1³ = 1 in 1000 per three-boss window, and the
/// player has killed many bosses). The weight stays 10 by ruling; this shared
/// stream is hygiene, not a fix.
final Random lootRng = Random();

/// What one kill produced.
class Loot {
  /// One entry per *slot* it will occupy — ⭐ three logs are three entries,
  /// because the backpack is slots rather than stacks (ITEMS §10.3a).
  final List<InventorySlot> slots;

  /// Instances minted for the non-fungibles above, by id.
  final Map<String, ItemInstance> instances;

  const Loot(this.slots, this.instances);

  static const empty = Loot([], {});

  bool get isEmpty => slots.isEmpty;
  int get count => slots.length;
}

/// Rolls [table] into items.
///
/// The three tiers behave differently on purpose (see `DropTable`):
/// - `always` — every entry gets a roll every kill, subject to its own
///   `chance` (which defaults to 1, i.e. genuinely guaranteed).
/// - `main` — ⭐ **exactly one** entry, by weight. This is what bounds what a
///   kill can be worth and makes drop rates readable as percentages.
/// - `bonus` — each rolled independently, on top.
///
/// ⚠️ **Omitting [rng] is the production call** — it draws from [lootRng], the
/// one shared stream. Pass a seeded `Random` only to pin a test; a caller that
/// hands over a fresh `Random()` per kill re-creates exactly the per-kill
/// construction [lootRng] exists to retire.
Loot rollDrops(DropTable table, [Random? rng]) {
  rng ??= lootRng;
  final ids = <String>[];

  for (final e in table.always) {
    // ⚠️ `chance` is honoured HERE too, not just in `bonus`. "always" names
    // *when* the bucket is consulted — every kill, one roll per entry — not
    // that every entry pays. Ignoring it silently made every authored rate in
    // this bucket a lie: `flora_crystal` at `chance: 0.25` on the mini-boss
    // table dropped on 100% of kills, and `content_export.dart` published the
    // 0.25 to the wiki under the promise that "a wiki that prints 12% got it
    // from the roller."
    //
    // ⭐ The `< 1` guard is load-bearing, not a micro-optimisation: a
    // guaranteed entry must not consume a number from [rng], so a table whose
    // `always` slots are all certain (both bosses) rolls the exact same
    // sequence it always did. Only tables that actually asked for a chance
    // shift.
    if (e.chance < 1 && rng.nextDouble() >= e.chance) continue;
    ids.addAll(_expand(e, rng));
  }

  final picked = _drawOne(table.main, rng);
  if (picked != null) ids.addAll(_expand(picked, rng));

  for (final e in table.bonus) {
    if (rng.nextDouble() < e.chance) ids.addAll(_expand(e, rng));
  }

  final slots = <InventorySlot>[];
  final instances = <String, ItemInstance>{};
  for (final id in ids) {
    // ⚠️ Throws on an unknown id rather than skipping. A drop table naming an
    // item that does not exist is a content bug, and swallowing it here would
    // turn a loud failure into a player quietly getting nothing.
    final def = ItemCatalogue.byId(id);
    if (def.isFungible) {
      slots.add(InventorySlot(defId: id));
    } else {
      final instanceId = _mintId(rng);
      instances[instanceId] = ItemInstance(instanceId: instanceId, defId: id);
      slots.add(InventorySlot(defId: id, instanceId: instanceId));
    }
  }
  return Loot(slots, instances);
}

/// One entry's ids, repeated by its rolled quantity.
List<String> _expand(DropEntry e, Random rng) {
  if (e.defId == null) return const [];
  final n = e.min + (e.max > e.min ? rng.nextInt(e.max - e.min + 1) : 0);
  return [for (var i = 0; i < n; i++) e.defId!];
}

/// Weighted draw of exactly one entry. Returns null when the "nothing" slot
/// wins, which is a legitimate and common result.
DropEntry? _drawOne(List<DropEntry> entries, Random rng) {
  if (entries.isEmpty) return null;
  final total = entries.fold<int>(0, (a, e) => a + e.weight);
  if (total <= 0) return null;
  var roll = rng.nextInt(total);
  for (final e in entries) {
    roll -= e.weight;
    if (roll < 0) return e.defId == null ? null : e;
  }
  return null;
}

/// A unique id for one physical item.
///
/// ⚠️ Random rather than sequential on purpose: a counter would collide the
/// moment the same character is open on two devices, which is exactly the case
/// the whole instance model exists to support.
String _mintId(Random rng) {
  const hex = '0123456789abcdef';
  return List.generate(24, (_) => hex[rng.nextInt(16)]).join();
}
