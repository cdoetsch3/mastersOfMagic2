/// Every fact the game knows about its own content, as plain JSON.
///
/// ⭐ **This is the contract between the code and everything that reads it** —
/// the design docs' generated tables, and eventually the public wiki. The code
/// is canonical (ITEMS §10.1, ENEMIES §1.2); nothing downstream may hold a
/// second copy of a number.
///
/// ⚠️ **Deterministic, and it must stay that way.** No timestamps, no
/// `Random`, no map iteration whose order depends on insertion elsewhere.
/// `content_export_test.dart` builds it twice and compares the encodings, so
/// any non-determinism turns into a test failure rather than diff noise in
/// `docs/wiki/content.json`.
///
/// ⭐ **Reverse indexes are DERIVED, never authored.** *"Where does Oak Log
/// come from"* and *"what uses Oak Log"* are the two questions every wiki page
/// asks, and a hand-written answer is stale the first time a drop table moves.
library;

import 'enemies/bestiary.dart';
import 'enemies/drop_table.dart';
import 'enemies/enemy_def.dart';
import 'items/item_catalogue.dart';
import 'items/item_def.dart';
import 'items/recipe_book.dart';
import 'items/recipe_def.dart';
import 'world.dart';

abstract final class ContentExport {
  /// ⚠️ **Bump on any breaking shape change**, so a wiki build that expects an
  /// older layout fails loudly instead of rendering blanks.
  static const int schemaVersion = 1;

  static Map<String, Object?> build() {
    final zones = World.locations.map(_zone).toList();
    final creatures = Bestiary.all.map(_creature).toList();
    final items = ItemCatalogue.all.map(_item).toList();
    final recipes = RecipeBook.all.map(_recipe).toList();
    return {
      'schemaVersion': schemaVersion,
      'counts': {
        'zones': zones.where((z) => z['kind'] != 'town').length,
        'towns': zones.where((z) => z['kind'] == 'town').length,
        'creatures': creatures.length,
        'items': items.length,
        'recipes': recipes.length,
      },
      'zones': zones,
      'creatures': creatures,
      'items': items,
      'recipes': recipes,
      'index': _index(),
    };
  }

  // ---- entities ----------------------------------------------------------

  static Map<String, Object?> _zone(GameLocation l) => {
    'id': l.id,
    'name': l.name,
    'kind': l.kind.name,
    'plane': l.plane.name,
    'tier': l.tier?.name,
    'elements': [for (final e in l.elements) e.name],
    'minLevel': l.minLevel,
    'maxLevel': l.maxLevel,
    'opensAtLevel': l.opensAtLevel,
    'station': l.station,
    'gate': l.gate,
    'blurb': l.blurb,
    'arrival': l.arrival,
    'beats': l.beats,
    'epilogue': l.epilogue,
    'edges': [
      for (final e in l.edges)
        {'to': e.to, 'minutes': e.minutes, 'kind': e.kind.name},
    ],
    'teleportsTo': l.teleportsTo,
  };

  static Map<String, Object?> _creature(EnemyDef e) => {
    'id': e.id,
    'name': e.name,
    'zoneId': e.zoneId,
    'rank': e.rank.name,
    'archetype': e.archetype.name,
    'elements': [for (final el in e.elements) el.name],
    'lore': e.lore,
    // ⚠️ **A move carries no element** — spells take the element the caster is
    // charged with (`spell.dart`). The wiki must read a move's element off the
    // creature's `elements`, never off the move.
    'moves': [
      for (final m in e.moves)
        {
          'id': m.id,
          'name': m.name,
          'chargeCost': m.chargeCost,
          'xCost': m.xCost,
          'accuracy': m.accuracy,
          'priority': m.priority,
          'effect': m.effect.runtimeType.toString(),
          'offensive': m.isOffensive,
        },
    ],
    'drops': _drops(e.drops),
  };

  /// ⭐ Every rate is exported as a **fraction**, computed by the same code the
  /// game rolls against. A wiki that prints "12%" got it from the roller.
  static Map<String, Object?> _drops(DropTable t) => {
    'always': [
      for (final d in t.always)
        {'itemId': d.defId, 'min': d.min, 'max': d.max, 'chance': d.chance},
    ],
    'main': [
      for (final d in t.main)
        {
          'itemId': d.defId,
          'min': d.min,
          'max': d.max,
          'weight': d.weight,
          'chance': t.totalWeight == 0 ? 0.0 : d.weight / t.totalWeight,
        },
    ],
    'bonus': [
      for (final d in t.bonus)
        {'itemId': d.defId, 'min': d.min, 'max': d.max, 'chance': d.chance},
    ],
  };

  static Map<String, Object?> _item(ItemDef d) {
    final m = <String, Object?>{
      'id': d.id,
      // ⚠️ Equipment has no stored name — it is composed from material + form
      // (ITEMS §9b.5a). Exporting the composed value is right; storing one
      // back in Dart would be the drift that rule exists to prevent.
      'name': ItemCatalogue.displayName(d),
      'kind': _kindOf(d),
      'rarity': d.rarity.name,
      'tradability': d.tradability.name,
      'equipLevel': d.equipLevel,
      'value': d.value,
      'fungible': d.isFungible,
      'lore': d.lore,
    };
    switch (d) {
      case EquipmentDef():
        m['slot'] = d.slot.name;
        m['form'] = d.form;
        m['material'] = d.material;
        m['socketCount'] = d.socketCount;
        m['setId'] = d.setId;
        m['setTier'] = d.setTier;
        m['modifiers'] = _modifiers(d.modifiers);
      case MaterialDef():
        m['skill'] = d.skill.name;
        m['tier'] = d.tier;
      case ToolDef():
        m['skill'] = d.skill.name;
        m['tier'] = d.tier;
      case MoteDef():
        m['element'] = d.element?.name;
        m['moteTier'] = d.tier.name;
      case GemDef():
        m['element'] = d.element?.name;
        m['modifiers'] = _modifiers(d.modifiers);
      case ComponentDef():
        m['sourceId'] = d.sourceId;
      case KeyDef():
        m['gates'] = d.gates;
      case ConsumableDef():
      case BeltableDef():
        break;
    }
    if (d is Usable) m['effect'] = _effect((d as Usable).effect);
    if (d is Salvageable) {
      m['salvage'] = [
        for (final s in (d as Salvageable).salvage)
          {'itemId': s.defId, 'min': s.min, 'max': s.max},
      ];
    }
    return m;
  }

  static String _kindOf(ItemDef d) => switch (d) {
    EquipmentDef() => 'equipment',
    ConsumableDef() => 'consumable',
    BeltableDef() => 'beltable',
    MaterialDef() => 'material',
    MoteDef() => 'mote',
    ComponentDef() => 'component',
    ToolDef() => 'tool',
    GemDef() => 'gem',
    KeyDef() => 'key',
  };

  /// ⚠️ **Only non-zero modifiers are emitted.** A wiki page listing
  /// "critDamage: 0" reads as a real property of the item rather than a
  /// default, and every page would carry the full vocabulary forever.
  static Map<String, Object?> _modifiers(ItemModifiers m) => {
    if (m.accuracyBonus != 0) 'accuracyBonus': m.accuracyBonus,
    if (m.dodge != 0) 'dodge': m.dodge,
    if (m.critChance != 0) 'critChance': m.critChance,
    if (m.critDamage != 0) 'critDamage': m.critDamage,
    if (m.deflectChance != 0) 'deflectChance': m.deflectChance,
    if (m.deflectAmount != 0) 'deflectAmount': m.deflectAmount,
    if (m.beltSlots != 0) 'beltSlots': m.beltSlots,
  };

  static Map<String, Object?> _effect(ItemEffect e) => {
    if (e.healPercent != 0) 'healPercent': e.healPercent,
  };

  static Map<String, Object?> _recipe(RecipeDef r) => {
    'id': r.id,
    'outputId': r.outputId,
    'outputCount': r.outputCount,
    'skill': r.skill.name,
    'skillLevel': r.skillLevel,
    'stationRequired': r.stationRequired,
    'inputs': [
      for (final i in r.inputs) {'itemId': i.defId, 'count': i.count},
    ],
  };

  // ---- derived indexes ---------------------------------------------------

  /// The two questions a wiki page must answer about any item.
  ///
  /// ⭐ **Both are computed by walking the same tables the game rolls**, so
  /// they cannot disagree with the game. `sources` is *where it comes from*;
  /// `usedBy` is *what consumes it*.
  static Map<String, Object?> _index() {
    final sources = <String, List<Map<String, Object?>>>{};
    final usedBy = <String, List<Map<String, Object?>>>{};

    void source(String? itemId, Map<String, Object?> entry) {
      if (itemId == null) return;
      (sources[itemId] ??= []).add(entry);
    }

    for (final e in Bestiary.all) {
      for (final (bucket, list) in [
        ('always', e.drops.always),
        ('main', e.drops.main),
        ('bonus', e.drops.bonus),
      ]) {
        for (final d in list) {
          source(d.defId, {
            'type': 'drop',
            'from': e.id,
            'zoneId': e.zoneId,
            'bucket': bucket,
            'chance': bucket == 'main'
                ? (e.drops.totalWeight == 0
                      ? 0.0
                      : d.weight / e.drops.totalWeight)
                : d.chance,
          });
        }
      }
    }

    for (final d in ItemCatalogue.all) {
      if (d is! Salvageable) continue;
      for (final s in (d as Salvageable).salvage) {
        source(s.defId, {'type': 'salvage', 'from': d.id});
        (usedBy[d.id] ??= []).add({'type': 'salvageInto', 'itemId': s.defId});
      }
    }

    for (final r in RecipeBook.all) {
      source(r.outputId, {
        'type': 'craft',
        'recipeId': r.id,
        'skill': r.skill.name,
        'skillLevel': r.skillLevel,
      });
      for (final i in r.inputs) {
        (usedBy[i.defId] ??= []).add({
          'type': 'recipeInput',
          'recipeId': r.id,
          'outputId': r.outputId,
        });
      }
    }

    // ⚠️ Sorted, because insertion order here follows catalogue order and a
    // reordered catalogue would otherwise show up as a spurious diff.
    Map<String, Object?> sorted(Map<String, List<Map<String, Object?>>> m) => {
      for (final k in m.keys.toList()..sort()) k: m[k]!,
    };

    return {'itemSources': sorted(sources), 'itemUses': sorted(usedBy)};
  }
}
