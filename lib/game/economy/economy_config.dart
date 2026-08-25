import '../content_version.dart' show ContentDocReader;
import '../firestore_rest.dart';

/// Server-tunable knobs for the general-shop economy
/// (`docs/contracts/ECONOMY_CONTRACT.md` §7).
///
/// ⚠️ **This is the game's first server-tunable gameplay data. It is legal
/// only because shops are PvE-personal (§1) — nothing here is read by
/// anything lockstep-resolved. Nothing that touches `DuelEngine`,
/// `DuelController`, or any duel-affecting `ItemModifiers` may ever read
/// this document. A future feature that wants server-tunable *combat*
/// numbers needs its own argument from scratch; this guardrail does not
/// extend to it by precedent.**
///
/// ⭐ Mirrors `content_version.dart`'s gate exactly, with one deliberate
/// difference: the content-version gate *must* block boot on a mismatch, so
/// it holds the spinner. This config is a pure tuning knob — no shop price
/// is ever wrong enough to justify making every player wait at a spinner for
/// it — so its fetch is **non-blocking**: [current] starts at
/// [EconomyConfig.defaults] and is swapped in place once [fetchAndCache]
/// resolves. See the boot seam in `main.dart`, kicked off beside the
/// content-version gate future, never awaited by it.
class EconomyConfig {
  /// Nightly resupply fraction applied per elapsed UTC day, per
  /// `(town, item)`: `stock += (E - stock) * resupplyRate` (§6.1).
  final double resupplyRate;

  /// Daily event swing, as a percent (±) applied to an affected item's price
  /// (§6.2).
  final double eventMagnitudePercent;

  /// How many items per shop get a daily event (§6.2).
  final double eventItemsPerShopPerDay;

  /// Sparse per-`(town, item)` location-modifier overrides, keyed
  /// `'$townId.$itemId'` -> percent (e.g. `-25`, `25`). A key absent here
  /// means §4's travel-graph-derived rule applies unmodified.
  final Map<String, num> locationModOverrides;

  /// Sparse per-item equilibrium-stock overrides, keyed by `itemId` ->
  /// integer stock. An item absent here uses the category default
  /// ([equilibriumNative], [equilibriumImported], or
  /// [equilibriumConsumable]) instead.
  final Map<String, int> equilibriumOverrides;

  const EconomyConfig({
    this.resupplyRate = defaultResupplyRate,
    this.eventMagnitudePercent = defaultEventMagnitudePercent,
    this.eventItemsPerShopPerDay = defaultEventItemsPerShopPerDay,
    this.locationModOverrides = const {},
    this.equilibriumOverrides = const {},
  });

  // ---- Compiled defaults (§6, §7) ---------------------------------------

  static const double defaultResupplyRate = 0.5;
  static const double defaultEventMagnitudePercent = 20;
  static const double defaultEventItemsPerShopPerDay = 2;

  /// ✅ Equilibrium-stock category defaults (§5.1): zone-native materials,
  /// imported materials, consumables. ⚠️ These are compiled constants, **not**
  /// part of `config/economy`'s schema — the contract (§7) only exposes
  /// per-item overrides ([equilibriumOverrides]) as server-tunable; the
  /// bucket-level defaults themselves are not.
  static const int equilibriumNative = 60;
  static const int equilibriumImported = 20;
  static const int equilibriumConsumable = 30;

  /// The all-compiled-defaults config, used whenever the server doc is
  /// missing, unreachable, or fails to parse.
  static const EconomyConfig defaults = EconomyConfig();

  // ---- Fetch plumbing, mirroring content_version.dart -------------------

  /// ⭐ Public-read, no auth (`firestore.rules`' `config/{doc}` wildcard
  /// already covers this path — see ECONOMY_CONTRACT §7; no rules change
  /// ships with this file).
  static const String docPath = 'config/economy';

  /// ⚠️ A slow network must not hold up anything. Past this the fetch gives
  /// up and falls back to [defaults] — same reasoning as
  /// `ContentVersion.fetchTimeout`, just never wired to a spinner here.
  static const Duration fetchTimeout = Duration(seconds: 6);

  /// The config shop code reads. Starts at [defaults]; [fetchAndCache]
  /// swaps it in place once the fetch resolves. Never null, never partially
  /// updated — always one complete, internally-consistent [EconomyConfig].
  static EconomyConfig current = defaults;

  /// Parses a partial Firestore doc into an [EconomyConfig], field by field.
  ///
  /// ⚠️ **Every field falls back to its own compiled default independently.**
  /// A doc missing a field, or carrying one with the wrong type, must not
  /// poison the fields that *did* parse correctly — there is no single
  /// try/catch around the whole doc here on purpose; each field is read with
  /// its own type-safe helper that returns null (never throws) on a mismatch.
  static EconomyConfig _fromFields(Map<String, dynamic> fields) {
    return EconomyConfig(
      resupplyRate: _asDouble(fields['resupplyRate']) ?? defaultResupplyRate,
      eventMagnitudePercent:
          _asDouble(fields['eventMagnitudePercent']) ??
          defaultEventMagnitudePercent,
      eventItemsPerShopPerDay:
          _asDouble(fields['eventItemsPerShopPerDay']) ??
          defaultEventItemsPerShopPerDay,
      locationModOverrides: _asNumMap(fields['locationModOverrides']),
      equilibriumOverrides: _asIntMap(fields['equilibriumOverrides']),
    );
  }

  static double? _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : null;

  /// A map field is only trusted if it decoded as a `Map` at all — anything
  /// else (wrong type on the whole field) falls back to empty, i.e. "no
  /// overrides", which is exactly what an absent field would also mean.
  /// Individual malformed entries inside an otherwise-good map are skipped
  /// rather than poisoning the entries that did parse.
  static Map<String, num> _asNumMap(dynamic value) {
    if (value is! Map) return const {};
    final out = <String, num>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key is String && val is num) out[key] = val;
    }
    return out;
  }

  static Map<String, int> _asIntMap(dynamic value) {
    if (value is! Map) return const {};
    final out = <String, int>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key is String && val is num) out[key] = val.toInt();
    }
    return out;
  }

  /// Fetches `config/economy` and parses it into an [EconomyConfig].
  ///
  /// ⚠️ Every failure path — exception, timeout, missing document — collapses
  /// to [defaults]. A malformed *field* (as opposed to a wholesale fetch
  /// failure) is handled inside [_fromFields] and never reaches this
  /// try/catch, so the fields that did parse are preserved even when the
  /// document as a whole is malformed.
  static Future<EconomyConfig> fetch({
    ContentDocReader read = FirestoreRest.get,
    Duration timeout = fetchTimeout,
  }) async {
    try {
      final fields = await read(docPath).timeout(timeout);
      if (fields == null) return defaults;
      return _fromFields(fields);
    } catch (_) {
      return defaults;
    }
  }

  /// Fetches and swaps [current] in place. ⚠️ **Non-blocking by contract:**
  /// call this and let it run — never `await` it before building UI, and
  /// never gate a `FutureBuilder` on it the way the content-version gate
  /// gates on `checkContentVersion()`. Shop code reads [current] directly and
  /// simply sees [defaults] until this resolves.
  static Future<void> fetchAndCache({
    ContentDocReader read = FirestoreRest.get,
    Duration timeout = fetchTimeout,
  }) async {
    current = await fetch(read: read, timeout: timeout);
  }
}
