import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

/// "How dueling works" — the general rules reference, built around the
/// priority ladder (the C2 timeline promoted to a gameplay-wide explainer).
class GameplayGuideScreen extends StatelessWidget {
  const GameplayGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('How dueling works'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: const [
                _Section(
                  title: 'The turn',
                  body: 'Both mages lock in a move at the same time, then the '
                      'round resolves — so every turn is a mind-game. You '
                      'either charge (+1, up to 5) or cast a spell you can '
                      'afford. Casting spends ALL your charge and ends the '
                      'cycle; next turn you pick a new element.',
                ),
                SizedBox(height: 18),
                _PriorityLadder(),
                SizedBox(height: 8),
                _Section(
                  title: 'Haste breaks ties',
                  body: 'When both mages act at the same priority, the Haste '
                      'holder resolves first — so a lethal hit can land before '
                      'the reply. Grab Haste with Jolt or Hasty (or ride an '
                      'Aero Tailwind streak).',
                ),
                SizedBox(height: 18),
                _PhaseStrip(),
                SizedBox(height: 18),
                _Section(
                  title: 'Elements carry effects',
                  body: 'Every element has a side-effect that fires as you '
                      'cast it — burns, charge theft, blinding, and more — plus '
                      'a counter it beats (double damage to that shield). Open '
                      'any element in the Spellbook for its full rules.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body,
            style: const TextStyle(
                color: AppColors.textDim, fontSize: 13.5, height: 1.45)),
      ],
    );
  }
}

/// The resolution-order ladder: what happens first within a turn.
class _PriorityLadder extends StatelessWidget {
  const _PriorityLadder();

  static const _bands = <({int p, String name, String what, Color color})>[
    (p: 1, name: 'Instant', what: 'the rare instant strikes', color: AppColors.ember),
    (p: 3, name: 'Shields', what: 'Ward, Aegis, Barrier — up before the hits', color: AppColors.sky),
    (p: 4, name: 'Channel', what: 'charging resolves here', color: AppColors.textDim),
    (p: 5, name: 'Quick', what: 'Flick, Jolt — beat regular attacks', color: AppColors.teal),
    (p: 7, name: 'Aux / control', what: 'Empower, Quicken, Discharge, Overload', color: AppColors.gem),
    (p: 9, name: 'Regular', what: 'most attacks — Bolt, Blast, Cataclysm', color: AppColors.gold),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESOLUTION ORDER',
              style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Lower priority acts first. This is why a shield goes up '
              'before the attack it blocks.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final b in _bands) ...[
            _rung(b.p, b.name, b.what, b.color),
            if (b != _bands.last) _connector(),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panelHi,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department,
                    size: 15, color: AppColors.ember),
                SizedBox(width: 8),
                Expanded(
                  child: Text('End of turn: burns tick and heals land, in that '
                      'order — a Photosynthesis heal beats an Ignite burn.',
                      style: TextStyle(
                          color: AppColors.textDim, fontSize: 12, height: 1.35)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rung(int priority, String name, String what, Color color) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.4),
          ),
          child: Text('$priority',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              Text(what,
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _connector() {
    return const Padding(
      padding: EdgeInsets.only(left: 12),
      child: SizedBox(
        height: 10,
        child: VerticalDivider(
          color: AppColors.borderDim,
          thickness: 1.5,
          width: 2,
        ),
      ),
    );
  }
}

/// The three resolution phases of a turn.
class _PhaseStrip extends StatelessWidget {
  const _PhaseStrip();

  @override
  Widget build(BuildContext context) {
    Widget phase(String name, String detail, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDim),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 11, height: 1.35)),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('A turn in three beats',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            phase('Start', 'pre-move effects', AppColors.sky),
            const SizedBox(width: 8),
            phase('Main', 'your locked-in moves', AppColors.gold),
            const SizedBox(width: 8),
            phase('End', 'burns & heals', AppColors.ember),
          ],
        ),
      ],
    );
  }
}
