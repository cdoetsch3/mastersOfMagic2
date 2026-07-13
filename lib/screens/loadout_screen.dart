import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/element_style.dart';
import '../game/loadout.dart';
import 'duel_screen.dart';

/// Pre-duel loadout selection: which elements and spells fill your ordered
/// slots. Selection order = slot order (slot number shown on each pick).
/// Equipment joins this screen later.
class LoadoutScreen extends StatefulWidget {
  const LoadoutScreen({super.key});

  @override
  State<LoadoutScreen> createState() => _LoadoutScreenState();
}

class _LoadoutScreenState extends State<LoadoutScreen> {
  final List<MagicElement> _elements = List.of(Loadout.starter.elements);
  final List<Spell> _spells = List.of(Loadout.starter.spells);

  static const _spellKeys = 'QWERTASDFG';

  void _toggleElement(MagicElement element) {
    setState(() {
      if (_elements.contains(element)) {
        _elements.remove(element);
      } else if (_elements.length < Loadout.maxElementSlots) {
        _elements.add(element);
      }
    });
  }

  void _toggleSpell(Spell spell) {
    setState(() {
      if (_spells.contains(spell)) {
        _spells.remove(spell);
      } else if (_spells.length < Loadout.maxSpellSlots) {
        _spells.add(spell);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _elements.isNotEmpty && _spells.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF141021),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Choose your loadout',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    'Elements ${_elements.length}/${Loadout.maxElementSlots}'
                    '   ·   Spells ${_spells.length}/${Loadout.maxSpellSlots}',
                    style: const TextStyle(
                        color: Color(0xFF9C93C4), fontSize: 12),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: ready
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DuelScreen(
                                  loadout: Loadout(
                                      elements: List.of(_elements),
                                      spells: List.of(_spells)),
                                ),
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Enter the arena'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE25822),
                      foregroundColor: const Color(0xFF141021),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 230,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ELEMENT SLOTS  (keys 1-8)',
                              style: TextStyle(
                                  color: Color(0xFF9C93C4),
                                  fontSize: 11,
                                  letterSpacing: 1.1)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final element in MagicElement.values)
                                _elementTile(element),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'SPELL SLOTS  (keys Q W E R T / A S D F G)',
                              style: TextStyle(
                                  color: Color(0xFF9C93C4),
                                  fontSize: 11,
                                  letterSpacing: 1.1)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 6,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.28,
                              children: [
                                for (final spell in Spellbook.all)
                                  _spellTile(spell),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _elementTile(MagicElement element) {
    final style = element.style;
    final slot = _elements.indexOf(element);
    final selected = slot >= 0;
    final strong = element.strongAgainst.map((e) => e.style.label).join(', ');
    final weak = element.weakAgainst.map((e) => e.style.label).join(', ');
    return Tooltip(
      message: element.volatility == 0
          ? '${style.label} — counters nothing, countered by nothing'
          : '${style.label} — strong vs $strong · weak vs $weak',
      child: InkWell(
        onTap: () => _toggleElement(element),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 103,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? style.color.withValues(alpha: 0.18)
                : const Color(0xFF1E1836),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? style.color : const Color(0xFF373060),
                width: selected ? 1.6 : 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(style.icon, size: 18, color: style.color),
                  const SizedBox(width: 6),
                  Text(style.label,
                      style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF9C93C4),
                          fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 3),
              Text(selected ? 'Slot ${slot + 1}' : '—',
                  style: TextStyle(
                      color: selected ? style.color : const Color(0xFF443A6A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spellTile(Spell spell) {
    final slot = _spells.indexOf(spell);
    final selected = slot >= 0;
    return Tooltip(
      message: spellTooltip(spell),
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        onTap: () => _toggleSpell(spell),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2B2150)
                : const Color(0xFF1E1836),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    selected ? const Color(0xFFE8C547) : const Color(0xFF373060),
                width: selected ? 1.6 : 1),
          ),
          padding: const EdgeInsets.all(4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spellIcons[spell.id] ?? Icons.auto_fix_high,
                  size: 16,
                  color: selected
                      ? const Color(0xFFE8C547)
                      : const Color(0xFF9C93C4)),
              const SizedBox(height: 2),
              Text(spell.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFB9B2D6),
                      fontSize: 10.5)),
              Text(
                selected
                    ? '${_spellKeys[slot]} · cost ${spell.xCost ? 'X' : spell.chargeCost}'
                    : 'cost ${spell.xCost ? 'X' : spell.chargeCost}',
                style: TextStyle(
                    color: selected
                        ? const Color(0xFFE8C547)
                        : const Color(0xFF6E6A7A),
                    fontSize: 9.5),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
