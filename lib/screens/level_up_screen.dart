import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

import '../game/progression.dart';
import '../ui/app_theme.dart';

/// Shown when a character gains a level.
///
/// ⭐ **It says what actually changed**, not just the number. A level-up that
/// only reports "you are now level 4" makes the player go and look for what
/// they got — and if the answer is "nothing visible", it reads as a hollow
/// reward rather than a quiet one.
///
/// ⚠️ Levels that unlock nothing are common by design (the schedules are
/// sparse), so the health gain is always shown: there is always *something*.
class LevelUpScreen extends StatelessWidget {
  final int from;
  final int to;

  const LevelUpScreen({super.key, required this.from, required this.to});

  /// Everything gained crossing from [from] to [to].
  ///
  /// ⭐ Derived from `Progression`, never hand-listed — a schedule changed in
  /// one place must not need this screen edited too.
  static List<LevelGain> gainsBetween(int from, int to) {
    final gains = <LevelGain>[];

    final hpBefore = MageState.scaledMaxHp(from);
    final hpAfter = MageState.scaledMaxHp(to);
    if (hpAfter > hpBefore) {
      gains.add(
        LevelGain(
          Icons.favorite,
          'Health',
          '$hpBefore → $hpAfter',
          AppColors.ember,
        ),
      );
    }

    final elements =
        Progression.elementsAtLevel(to) - Progression.elementsAtLevel(from);
    if (elements > 0) {
      gains.add(
        LevelGain(
          Icons.auto_awesome,
          elements == 1 ? 'An element slot' : '$elements element slots',
          'You can carry ${Progression.elementsAtLevel(to)} elements',
          AppColors.gem,
        ),
      );
    }

    final spells =
        Progression.spellsAtLevel(to) - Progression.spellsAtLevel(from);
    if (spells > 0) {
      gains.add(
        LevelGain(
          Icons.menu_book,
          spells == 1 ? 'A spell slot' : '$spells spell slots',
          'You can carry ${Progression.spellsAtLevel(to)} spells',
          AppColors.sky,
        ),
      );
    }

    final presets =
        Progression.presetSlotsAtLevel(to) -
        Progression.presetSlotsAtLevel(from);
    if (presets > 0) {
      gains.add(
        LevelGain(
          Icons.bookmarks,
          presets == 1 ? 'A loadout' : '$presets loadouts',
          '${Progression.presetSlotsAtLevel(to)} saved loadouts',
          AppColors.teal,
        ),
      );
    }

    return gains;
  }

  @override
  Widget build(BuildContext context) {
    final gains = gainsBetween(from, to);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_circle_up,
                  color: AppColors.gold,
                  size: 56,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Level up',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  to - from > 1 ? 'Level $from → $to' : 'You are now level $to',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                for (final g in gains) ...[
                  _GainRow(gain: g),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LevelGain {
  final IconData icon;
  final String title;
  final String detail;
  final Color colour;

  const LevelGain(this.icon, this.title, this.detail, this.colour);
}

class _GainRow extends StatelessWidget {
  final LevelGain gain;

  const _GainRow({required this.gain});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: GamePanel(
      child: Row(
        children: [
          Icon(gain.icon, color: gain.colour, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gain.title,
                  style: const TextStyle(color: AppColors.text, fontSize: 15),
                ),
                Text(
                  gain.detail,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
