import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/bestiary_record.dart';
import '../game/element_style.dart';
import '../game/enemies/bestiary.dart';
import '../game/enemies/drop_table.dart';
import '../game/enemies/enemy_def.dart';
import '../game/game_state.dart';
import '../game/items/item_catalogue.dart';
import '../game/items/item_def.dart';
import '../game/provenance.dart';
import '../game/world.dart';
import '../ui/app_theme.dart';
import '../ui/creature_art.dart';

/// The Bestiary: every creature in the game as a field guide, chaptered by
/// zone, with a search box (ruling, Christian playtest 2026-09-30, note 8 —
/// mockup "A field guide + C's search box").
///
/// ⭐ **Unmet creatures are listed, not hidden** — as `???` with their rank
/// pill, so a chapter says how much of the zone is left to meet and which
/// ranks are still out there. Only met creatures open an entry page.
///
/// ⭐ **The search never reveals the unmet** ([BestiaryListing.build]): an
/// unmet creature matches only by its zone's name, so searching a drop finds
/// the creatures you have met that drop it — never one you have not.
///
/// ⭐ **Press-stable search** — the field sits above the list, outside the
/// scroll view, so typing changes what is below it and never where it is.
class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(EnemyDef def) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BestiaryEntryScreen(def: def)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = GameStateScope.of(context).profile.bestiary;
    final listing = BestiaryListing.build(_query, record);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Bestiary'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _Pill(
                '${bestiaryMetCount(record)} / ${Bestiary.all.length}',
                color: AppColors.textDim,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: _searchField(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                children: _results(listing, record),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(
    BestiaryListing listing,
    Map<String, BestiaryEntry> record,
  ) {
    if (listing.chapters.isEmpty) {
      return const [_DimLine('Nothing matches.')];
    }
    final dropLine = listing.dropLine;
    return [
      if (dropLine != null) _DimLine(dropLine),
      for (final chapter in listing.chapters) ...[
        _Label(chapter.label),
        for (final def in chapter.rows)
          BestiaryRow(
            def: def,
            entry: record[def.id] ?? const BestiaryEntry(),
            onTap: _open,
          ),
        const SizedBox(height: 8),
      ],
      if (listing.gatheredAt.isNotEmpty) ...[
        const _Label('Also gathered at'),
        for (final zone in listing.gatheredAt) _DimLine(zone.name),
      ],
    ];
  }

  Widget _searchField() => TextField(
    controller: _search,
    onChanged: (q) => setState(() => _query = q),
    style: const TextStyle(color: AppColors.text, fontSize: 13),
    cursorColor: AppColors.gold,
    decoration: InputDecoration(
      isDense: true,
      hintText: 'Search creatures or drops…',
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 12.5),
      prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textDim),
      prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      filled: true,
      fillColor: AppColors.panelHi,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    ),
  );
}

/// How many creatures [record] has met. ⭐ Counts only ids the roster still
/// knows, so a retired creature cannot push the count past the total — the
/// Profile row and the AppBar pill both read this.
int bestiaryMetCount(Map<String, BestiaryEntry> record) =>
    Bestiary.all.where((d) => record[d.id]?.met ?? false).length;

/// The Profile row's trailing text, `'n seen'`.
String bestiarySeenLabel(Map<String, BestiaryEntry> record) =>
    '${bestiaryMetCount(record)} seen';

/// A rank as the Bestiary prints it.
///
/// ⚠️ **Not [EnemyRank.label]** ('Wild' / 'Mini-boss' / 'Boss', the encounter
/// card's wording): the field guide's pill says `Common` / `Mini` / `Boss`,
/// as ruled (playtest 2026-09-30, note 8).
String bestiaryRankLabel(EnemyRank rank) => switch (rank) {
  EnemyRank.common => 'Common',
  EnemyRank.mini => 'Mini',
  EnemyRank.boss => 'Boss',
};

/// A drop chance as a whole percent: `45%`, `100%`, and `<1%` for anything
/// above nothing but under one.
String bestiaryRate(double chance) {
  final pct = chance * 100;
  if (pct > 0 && pct < 1) return '<1%';
  return '${pct.round()}%';
}

/// `'1 charge'`, `'2 charges'`, `'X charge'` — the move row's cost.
String bestiaryChargeLabel(Spell move) {
  if (move.xCost) return 'X charge';
  final n = move.chargeCost;
  return '$n charge${n == 1 ? '' : 's'}';
}

/// One zone's chapter of the listing.
class BestiaryChapter {
  final GameLocation zone;

  /// The rows shown — the whole roster, or what matched the query.
  final List<EnemyDef> rows;

  /// `Zone Name · Lv a–b · met/total`. ⚠️ The tally is the whole zone's,
  /// even when a query has narrowed [rows] — it is what is left to meet.
  final String label;

  const BestiaryChapter(this.zone, this.rows, this.label);
}

/// What the Bestiary list shows for a query — pure, so the search law is
/// testable without a widget.
class BestiaryListing {
  final List<BestiaryChapter> chapters;

  /// `'n creatures drop <Item>'` when the query names a drop exactly; else
  /// null.
  final String? dropLine;

  /// Zones where a matched drop can also be gathered, in map order.
  final List<GameLocation> gatheredAt;

  const BestiaryListing(this.chapters, this.dropLine, this.gatheredAt);

  /// ⭐ **The search law** (ruling 2026-09-30): a non-empty query matches,
  /// case-insensitively as a substring,
  /// - every creature in a zone whose **name** matches — met or not, so
  ///   "thunderspire" lists that zone's `???` rows too;
  /// - a **met** creature by its own name, or by the display name of any def
  ///   its drop table can yield.
  ///
  /// ⚠️ An unmet creature matches by its zone and nothing else: matching it
  /// by a drop would answer "who drops Rowan Log" with a creature the player
  /// has never seen. For the same reason the drop line and the gathered
  /// footer are built from met creatures' tables only.
  static BestiaryListing build(
    String query,
    Map<String, BestiaryEntry> record,
  ) {
    final q = query.trim().toLowerCase();
    bool met(EnemyDef d) => record[d.id]?.met ?? false;
    bool hit(String text) => text.toLowerCase().contains(q);

    final chapters = <BestiaryChapter>[];
    final matchedDrops = <ItemDef>{};
    for (final zone in World.locations) {
      final roster = Bestiary.forZone(zone.id);
      if (roster.isEmpty) continue;
      final List<EnemyDef> rows;
      if (q.isEmpty) {
        rows = roster;
      } else {
        final zoneHit = hit(zone.name);
        rows = [];
        for (final d in roster) {
          var matched = zoneHit;
          if (met(d)) {
            if (hit(d.name)) matched = true;
            for (final item in _dropDefs(d)) {
              if (!hit(ItemCatalogue.displayName(item))) continue;
              matchedDrops.add(item);
              matched = true;
            }
          }
          if (matched) rows.add(d);
        }
      }
      if (rows.isEmpty) continue;
      final metHere = roster.where(met).length;
      chapters.add(
        BestiaryChapter(
          zone,
          rows,
          '${zone.name} · Lv ${zone.minLevel}–${zone.maxLevel} · '
          '$metHere/${roster.length}',
        ),
      );
    }

    String? dropLine;
    for (final item in matchedDrops) {
      final name = ItemCatalogue.displayName(item);
      if (name.toLowerCase() != q) continue;
      final n = Bestiary.all
          .where((d) => met(d) && d.drops.possibleDrops.contains(item.id))
          .length;
      dropLine = n == 1 ? '1 creature drops $name' : '$n creatures drop $name';
      break;
    }

    final gatheredIds = {
      for (final item in matchedDrops)
        for (final s in Provenance.sourcesOf(item.id))
          if (s.gathered) s.location.id,
    };
    final gatheredAt = [
      for (final zone in World.locations)
        if (gatheredIds.contains(zone.id)) zone,
    ];

    return BestiaryListing(chapters, dropLine, gatheredAt);
  }

  /// Every def [d]'s table can yield that the catalogue still knows.
  static Iterable<ItemDef> _dropDefs(EnemyDef d) =>
      d.drops.possibleDrops.map(ItemCatalogue.tryById).nonNulls;
}

/// One creature in the list.
///
/// ⭐ **One shape for met and unmet** — a fixed 40px sprite cell, a name line
/// with the rank pill, one line under it — so meeting a creature never
/// re-lays its row or the rows below it.
class BestiaryRow extends StatelessWidget {
  final EnemyDef def;
  final BestiaryEntry entry;

  /// Called for a met creature only. ⚠️ An unmet row is inert: no ink, no
  /// route — there is nothing behind `???` to show.
  final ValueChanged<EnemyDef> onTap;

  const BestiaryRow({
    super.key,
    required this.def,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final met = entry.met;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: met
                // ⚠️ TickerMode off: a list of bobbing sprites is noise, and
                // a frozen frame is the same creature at rest.
                ? TickerMode(
                    enabled: false,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CreatureView(def: def, height: 36),
                    ),
                  )
                : const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        met ? def.name : '???',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: met ? AppColors.text : AppColors.textFaint,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      bestiaryRankLabel(def.rank),
                      color: _rankColor(def.rank),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (met)
                  Row(
                    children: [
                      ElementDots(def.elements),
                      if (def.elements.isNotEmpty) const SizedBox(width: 8),
                      Text(
                        'slain ${entry.slain}',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Not yet met',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 12),
                  ),
              ],
            ),
          ),
          // ⭐ The chevron cell is reserved on every row, drawn only when the
          // row opens something — the pill never shifts when a creature is met.
          SizedBox(
            width: 20,
            child: met
                ? const Icon(
                    Icons.chevron_right,
                    color: AppColors.textFaint,
                    size: 18,
                  )
                : null,
          ),
        ],
      ),
    );
    if (!met) return row;
    return InkWell(onTap: () => onTap(def), child: row);
  }
}

Color _rankColor(EnemyRank rank) => switch (rank) {
  EnemyRank.common => AppColors.textDim,
  EnemyRank.mini => AppColors.sky,
  EnemyRank.boss => AppColors.gold,
};

/// One creature's page: who it is, how it fights, what it leaves behind.
class BestiaryEntryScreen extends StatelessWidget {
  final EnemyDef def;

  const BestiaryEntryScreen({super.key, required this.def});

  /// The sprite's height — ⭐ `CreatureSprite`'s own default, the size the
  /// creature art is drawn for.
  static const double spriteHeight = 160;

  @override
  Widget build(BuildContext context) {
    final entry = GameStateScope.of(context).profile.bestiaryEntryFor(def.id);
    final zone = World.byId(def.zoneId);
    final drops = bestiaryDropRows(def.drops);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.panel, title: Text(def.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            GamePanel(
              child: Column(
                children: [
                  // ⚠️ A fixed box: the art arrives (or fails over to its
                  // fallback) after the first frame, and must not push the
                  // text below it down when it does.
                  SizedBox(
                    height: spriteHeight + 8,
                    child: Center(
                      child: CreatureView(def: def, height: spriteHeight),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${zone.name} · ${bestiaryRankLabel(def.rank)} · '
                    '${def.archetype.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElementDots(def.elements),
                      if (def.elements.isNotEmpty) const SizedBox(width: 8),
                      Text(
                        'seen ${entry.seen} · slain ${entry.slain}',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              def.lore,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            // ⭐ A mage fights with a spellbook loadout, not a creature kit
            // (`EnemyDef.isMage`) — the section says which it is reading.
            _Label(def.isMage ? 'Spells' : 'Moves'),
            for (final move in def.moves) _MoveRow(move),
            if (drops.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _Label('Drops'),
              // 📝 **The table, and only the table.** A boss or mini also
              // earns a guaranteed piece of its zone's gear for its rank
              // (`loot.dart`); that is a rule of the rank, not a line of this
              // creature's table, so it is not listed here.
              for (final d in drops) _DropRow(d.name, d.rate),
            ],
          ],
        ),
      ),
    );
  }
}

/// One drop line of an entry page.
typedef BestiaryDropRow = ({String name, String rate});

/// A table's drops as the entry page lists them: `always` (each at its own
/// chance — `100%` when guaranteed), then `main` by weight, heaviest first
/// (as its share of the draw), then `bonus` (each at its own chance).
///
/// ⚠️ The "nothing" slot of `main` is not a drop and is not listed; an id
/// the catalogue no longer knows is skipped rather than printed raw. Motes
/// are listed — they are this creature's own table.
List<BestiaryDropRow> bestiaryDropRows(DropTable table) {
  BestiaryDropRow? row(String? id, double chance) {
    final def = id == null ? null : ItemCatalogue.tryById(id);
    if (def == null) return null;
    return (name: ItemCatalogue.displayName(def), rate: bestiaryRate(chance));
  }

  // Main: one row per def, its weights summed; ties keep table order.
  final weights = <String, int>{};
  for (final e in table.main) {
    final id = e.defId;
    if (id != null) weights[id] = (weights[id] ?? 0) + e.weight;
  }
  final order = weights.keys.toList();
  final mainIds = [...order]
    ..sort((a, b) {
      final byWeight = weights[b]!.compareTo(weights[a]!);
      return byWeight != 0
          ? byWeight
          : order.indexOf(a).compareTo(order.indexOf(b));
    });

  return [
    for (final e in table.always) ?row(e.defId, e.chance),
    for (final id in mainIds) ?row(id, table.mainChanceOf(id)),
    for (final e in table.bonus) ?row(e.defId, e.chance),
  ];
}

class _MoveRow extends StatelessWidget {
  final Spell move;

  const _MoveRow(this.move);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          move.name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${bestiaryChargeLabel(move)} · ${spellEffectLine(move)}',
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      ],
    ),
  );
}

class _DropRow extends StatelessWidget {
  final String name;
  final String rate;

  const _DropRow(this.name, this.rate);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rate,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

/// A creature's elements as small coloured dots — the colour each element
/// wears everywhere else.
class ElementDots extends StatelessWidget {
  final List<MagicElement> elements;

  const ElementDots(this.elements, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, e) in elements.indexed) ...[
        if (i > 0) const SizedBox(width: 3),
        Semantics(
          label: e.style.label,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: e.style.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ],
  );
}

/// A rounded tag — the AppBar's tally and each row's rank.
class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}

/// A section label in the house style (`SectionLabel`'s size and colour),
/// ⚠️ but printed as written rather than upper-cased — a chapter label
/// carries a zone name and `Lv`, which capitals would garble.
class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textDim,
        fontSize: 12,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _DimLine extends StatelessWidget {
  final String text;

  const _DimLine(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
    ),
  );
}
