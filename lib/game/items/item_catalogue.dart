/// Every item definition in the game, addressable by id.
///
/// ⭐ **The lookup that makes string-keyed drop tables safe.** Dart forbids
/// field access inside a const expression, so drop tables and recipes must
/// name items by string; this registry is what lets a test prove every one of
/// those strings resolves.
library;

import 'catalogue/ashfall_vale_items.dart';
import 'catalogue/cinderpeak_items.dart';
import 'catalogue/frostfell_pass_items.dart';
import 'catalogue/gems.dart';
import 'catalogue/glimmerbrook_items.dart';
import 'catalogue/hallowmarch_items.dart';
import 'catalogue/old_quarry_items.dart';
import 'catalogue/refined_motes.dart';
import 'catalogue/starfall_basin_items.dart';
import 'catalogue/stormcliff_coast_items.dart';
import 'catalogue/the_mirrormere_items.dart';
import 'catalogue/the_kiln_desert_items.dart';
import 'catalogue/the_buried_sky_items.dart';
import 'catalogue/the_collapsed_academy_items.dart';
import 'catalogue/the_glass_archive_items.dart';
import 'catalogue/the_reliquary_deep_items.dart';
import 'catalogue/the_sealed_garden_items.dart';
import 'catalogue/the_eclipsed_citadel_items.dart';
import 'catalogue/the_molten_deep_items.dart';
import 'catalogue/the_shattered_orrery_items.dart';
import 'catalogue/the_sunless_reach_items.dart';
import 'catalogue/the_umbral_wastes_items.dart';
import 'catalogue/the_unwritten_library_items.dart';
import 'catalogue/thornmire_items.dart';
import 'catalogue/thunderspire_peaks_items.dart';
import 'catalogue/tidewrack_shoals_items.dart';
import 'catalogue/whispering_woods_items.dart';
import 'catalogue/windward_steppe_items.dart';
import 'item_def.dart';
import 'item_instance.dart';
import 'item_naming.dart';

abstract final class ItemCatalogue {
  /// ⚠️ **Every zone catalogue must be listed here.** An unlisted one compiles
  /// fine and simply never resolves, which is exactly the silent failure the
  /// id test exists to catch.
  ///
  /// ⭐ **Keyed by zone id, and that key is load-bearing** — it is the only
  /// place in the game that records *which zone defines an item*, which is
  /// what [zoneOf] and therefore `assets/items/<zone>/<id>.png` are built on.
  /// ⚠️ The key must be a real `World.locations` id, not a display name or a
  /// class name; a test asserts it.
  ///
  /// ⭐ **A cross-zone recipe output belongs to the file that DEFINES it**, not
  /// to the zone whose materials it eats — the Tuskhide Belt is Cinderpeak's
  /// even though Thornmire supplies its thread. That is the same rule the
  /// catalogue files already follow for motes ("the mote lives with the zone
  /// that first yields it"), so nothing falls between two zones.
  static const Map<String, List<ItemDef>> byZone = <String, List<ItemDef>>{
    'whispering_woods': WhisperingWoodsItems.all,
    'glimmerbrook': GlimmerbrookItems.all,
    'cinderpeak_foothills': CinderpeakItems.all,
    'thornmire': ThornmireItems.all,
    'ashfall_vale': AshfallValeItems.all,
    'old_quarry': OldQuarryItems.all,
    'windward_steppe': WindwardSteppeItems.all,
    'stormcliff_coast': StormcliffCoastItems.all,
    'frostfell_pass': FrostfellPassItems.all,
    'thunderspire_peaks': ThunderspirePeaksItems.all,
    'the_molten_deep': TheMoltenDeepItems.all,
    'the_mirrormere': MirrormereItems.all,
    'the_shattered_orrery': ShatteredOrreryItems.all,
    'the_kiln_desert': KilnDesertItems.all,
    'tidewrack_shoals': TidewrackShoalsItems.all,
    'starfall_basin': StarfallBasinItems.all,
    'the_sunless_reach': SunlessReachItems.all,
    'the_glass_archive': GlassArchiveItems.all,
    'the_buried_sky': BuriedSkyItems.all,
    'the_collapsed_academy': CollapsedAcademyItems.all,
    'the_reliquary_deep': ReliquaryDeepItems.all,
    'the_umbral_wastes': UmbralWastesItems.all,
    'the_unwritten_library': UnwrittenLibraryItems.all,
    'hallowmarch': HallowmarchItems.all,
    'the_sealed_garden': SealedGardenItems.all,
    'the_eclipsed_citadel': EclipsedCitadelItems.all,
  };

  /// ⭐ **Defs no zone yields** — made at a bench, never found — keyed by a
  /// workshop name that is deliberately NOT a place (ENCHANTING_DESIGN §3.1,
  /// §5.1): the Core and Heart motes (`refined`) and the cut gems (`gems`).
  ///
  /// ⚠️ **Kept out of [byZone] on purpose.** [zoneOf] answers "which zone
  /// defines this", and shop sourcing, rank gear and the native-zone pricing
  /// all read it as geography; a `'refined'` key there would be a zone that
  /// does not exist (and `item_icon_test` pins that every [byZone] key is a
  /// real `World` location). [homeOf] is the question the icon path asks,
  /// and it answers for both maps.
  static final Map<String, List<ItemDef>> byWorkshop = <String, List<ItemDef>>{
    'refined': RefinedMotes.all,
    'gems': Gems.all,
  };

  /// ⚠️ **Derived from [byZone] and [byWorkshop], not written out again.**
  /// Two hand-kept lists of the same catalogues is exactly how an item ends
  /// up resolvable by id but owned by no file — an icon that can never load,
  /// with nothing failing to say so.
  static final List<ItemDef> all = <ItemDef>[
    for (final defs in byZone.values) ...defs,
    for (final defs in byWorkshop.values) ...defs,
  ];

  static final Map<String, ItemDef> _byId = {for (final d in all) d.id: d};

  static final Map<String, String> _zoneById = {
    for (final e in byZone.entries)
      for (final d in e.value) d.id: e.key,
  };

  static final Map<String, String> _workshopById = {
    for (final e in byWorkshop.entries)
      for (final d in e.value) d.id: e.key,
  };

  /// The folder [defId] is filed under — its zone, or for a made-not-found
  /// def its [byWorkshop] key. ⭐ What `itemIconFor` builds
  /// `assets/items/<home>/<id>.png` from. Null only for an id nothing claims.
  static String? homeOf(String defId) =>
      _zoneById[defId] ?? _workshopById[defId];

  /// Which zone's catalogue file defines [defId].
  ///
  /// ⭐ **A lookup rather than a field on [ItemDef].** A `zoneId` on every def
  /// would be a fact stated twice — once by which file the `static const`
  /// lives in and once by the string beside it — and the two can disagree.
  /// Here the file placement *is* the answer, so it cannot.
  ///
  /// ⚠️ Null means no ZONE claims the id — a save written before a content
  /// patch, which callers must treat the way `tryById` does, or a
  /// [byWorkshop] def (a Core, a gem), which no zone yields by design.
  static String? zoneOf(String defId) => _zoneById[defId];

  /// Null when nothing owns [id] — callers should treat that as a bug, not a
  /// missing item.
  static ItemDef? tryById(String id) => _byId[id];

  /// The player-facing name, ⭐ **composed from the facts** rather than stored
  /// (ITEMS §9b.5a): aspect prefix + quality + material + form.
  ///
  /// ⚠️ Only equipment has a grammar. Everything else uses its own written
  /// name, which is why [ItemDef] carries no `name` field for them to drift
  /// against.
  static String displayName(ItemDef def, [ItemInstance? instance]) {
    if (def is! EquipmentDef) return def.properName ?? def.id;
    // ⭐ Named equipment — boss uniques and the drop-only jewelry — keeps its
    // bespoke name (§9b.5): "Heartwood Staff", never "Heartwood Quarterstaff".
    if (def.properName != null) return def.properName!;
    return composeItemName(
      aspectPrefix: instance?.aspect == null
          ? null
          : aspectPrefixes[instance!.aspect!.name],
      quality: instance?.quality,
      material: def.material,
      form: def.form,
    );
  }

  static ItemDef byId(String id) {
    final d = _byId[id];
    if (d == null) throw ArgumentError('no item definition for "$id"');
    return d;
  }

  static bool contains(String id) => _byId.containsKey(id);

  static Iterable<T> ofKind<T extends ItemDef>() => all.whereType<T>();
}
