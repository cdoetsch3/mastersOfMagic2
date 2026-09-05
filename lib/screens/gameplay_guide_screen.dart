import 'package:flutter/material.dart';

import 'package:mom_engine/mom_engine.dart';

import '../game/element_style.dart';
import '../game/status_fx.dart';
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
                  body:
                      'Both mages lock in a move at the same time, then the '
                      'round resolves — so every turn is a mind-game. You '
                      'either charge (+1, up to 5) or cast a spell you can '
                      'afford. Casting spends ALL your charge and ends the '
                      'cycle; next turn you pick a new element. The dots in '
                      'the corner of a spell tab are its charge cost.',
                ),
                SizedBox(height: 18),
                _PriorityLadder(),
                SizedBox(height: 8),
                _Section(
                  title: 'Haste breaks ties',
                  body:
                      'When both mages act at the same priority, the Haste '
                      'holder resolves first — so a lethal hit can land before '
                      'the reply. Grab Haste with Jolt or Hasty (or ride an '
                      'Aero Tailwind streak).',
                ),
                SizedBox(height: 18),
                _PhaseStrip(),
                SizedBox(height: 18),
                _Section(
                  title: 'When a spell does not go off',
                  body:
                      'A spell FIZZLES if your charge is pulled below its '
                      'cost before it resolves (Discharge, or an Electro '
                      'Static Feedback proc) — nothing is cast and you keep '
                      'the charge you have left. An ATTACK can MISS: your '
                      'Accuracy is weighed against their Dodge (and a Blind '
                      'on you), but the hit chance never drops below 10% — '
                      'nobody is unhittable. A miss spends the charge for '
                      'nothing. Shields, stances and aux-offense spells never '
                      'roll to hit; Unerring makes your next attack simply '
                      'not roll. Neither a fizzle nor a miss advances an '
                      'element streak or procs an effect.',
                ),
                SizedBox(height: 18),
                _Section(
                  title: 'Hits, crits and deflection',
                  body:
                      'Six numbers shape every hit, from gear, enemy kits and '
                      'stances alike: Accuracy and Dodge decide whether it '
                      'lands; Crit chance and Crit damage decide whether it '
                      'lands HARD (a crit multiplies by 100% + your crit '
                      'damage; Composure on the defender turns any crit back '
                      'into a plain hit, whatever earned it — Keen, Execute, '
                      'even Death Wish); Deflect chance and amount shave a '
                      'share off before the shield, capped at 90% and 90% so '
                      'a sliver always lands. Reflect sends the deflected '
                      'share straight back. Pierce makes your next attack '
                      'un-deflectable; Shatter clears their shield, Barriers '
                      'and Divert stance at once.',
                ),
                SizedBox(height: 18),
                _Section(
                  title: 'Stances replace, never stack',
                  body:
                      'A stance is a status you cast on yourself — Lightfoot, '
                      'Keen, Steadfast, Mending — that lasts a stretch of '
                      'turns. Each covers one axis, and casting another '
                      'granter of the same axis REPLACES it, strength and '
                      'clock together: Twinkle Toes over Lightfoot is a new '
                      'Lightfoot, not a bigger one. Gear and element effects '
                      'are separate lanes and stack alongside. Meditate adds '
                      'five turns to every stance you hold; Dispel strips '
                      'the enemy\'s; Cleanse and Purify remove debuffs from '
                      'you (Cleanse asks which, when you have more than one).',
                ),
                SizedBox(height: 18),
                _Section(
                  title: 'Burns and bleeds',
                  body:
                      'Ignite, Agony and Torment tick at the end of every '
                      'turn. A tick is damage, not a hit: your shield eats it '
                      'first and Divert can deflect it, but it never misses '
                      'and never crits. Recasting a burn refreshes it rather '
                      'than stacking. Fester adds three ticks to every burn '
                      'on them; Scour makes every burn pay out all at once as '
                      'one hit and clears them; Wither halves the healing they '
                      'receive, and Blight turns their heals into damage — '
                      'potions and lifesteal included.',
                ),
                SizedBox(height: 18),
                _StatusList(),
                SizedBox(height: 18),
                _Section(
                  title: 'Elements carry effects',
                  body:
                      'Every element has a side-effect that fires as you '
                      'cast it — burns, charge theft, blinding, and more. Each '
                      'also beats one element in its tier: you hit that '
                      'shield for DOUBLE, and only HALF into the element that '
                      'beats you. Across tiers the swing is gentler — 1.5× or '
                      '¾× — and opposite tiers are even. Open any element in '
                      'the Spellbook for its full rules.',
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
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// The resolution-order ladder: what happens first within a turn.
class _PriorityLadder extends StatelessWidget {
  const _PriorityLadder();

  static const _bands = <({int p, String name, String what, Color color})>[
    (
      p: 1,
      name: 'Instant',
      what: 'the rare instant strikes',
      color: AppColors.ember,
    ),
    (
      p: 3,
      name: 'Shields',
      what: 'Ward, Aegis, Barrier — up before the hits',
      color: AppColors.sky,
    ),
    (
      p: 4,
      name: 'Channel',
      what: 'charging resolves here',
      color: AppColors.textDim,
    ),
    (
      p: 5,
      name: 'Quick',
      what: 'Flick, Jolt — beat regular attacks',
      color: AppColors.teal,
    ),
    (
      p: 7,
      name: 'Aux-self',
      what: 'what you do to yourself — Empower, Lightfoot, Cleanse, Phase',
      color: AppColors.gold,
    ),
    (
      p: 8,
      name: 'Aux-offense',
      what: 'pressure without a hit roll — Discharge, Murk, Wither, Dispel',
      color: AppColors.gem,
    ),
    (
      p: 9,
      name: 'Regular',
      what: 'most attacks — Bolt, Blast, Agony, Overload, Cataclysm',
      color: AppColors.ember,
    ),
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
          const Text(
            'RESOLUTION ORDER',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Lower priority acts first. This is why a shield goes up '
            'before the attack it blocks.',
            style: TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
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
                Icon(
                  Icons.local_fire_department,
                  size: 15,
                  color: AppColors.ember,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'End of turn: heals land FIRST, then burns tick '
                    '— so a Mending or Photosynthesis heal resolves before '
                    'an Ignite or Torment burn can finish you.',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
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
          child: Text(
            '$priority',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                what,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11.5,
                ),
              ),
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
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A turn in three beats',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // IntrinsicHeight bounds the cross axis: a bare `stretch` Row inside
        // the scrolling list would demand infinite height.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              phase('Start', 'pre-move effects', AppColors.sky),
              const SizedBox(width: 8),
              phase('Main', 'your locked-in moves', AppColors.gold),
              const SizedBox(width: 8),
              phase('End', 'burns & heals', AppColors.ember),
            ],
          ),
        ),
      ],
    );
  }
}

/// Every status in the game, straight from [StatusCatalog] — so the guide can
/// never fall out of step with what the engine actually applies.
class _StatusList extends StatelessWidget {
  const _StatusList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Every status',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Conditions you carry show as pips beside your health. Moments are '
          'things that happen in passing — a cleanse, a strip, a block.',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (final group in [
          ('Lasting conditions', StatusCatalog.lasting.toList()),
          ('Moments', StatusCatalog.moments.toList()),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(
              group.$1.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final info in group.$2) _StatusRow(info),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final StatusInfo info;
  const _StatusRow(this.info);

  @override
  Widget build(BuildContext context) {
    final color = statusColor(info);
    final kindLabel = switch (info.kind) {
      StatusKind.buff => 'buff',
      StatusKind.debuff => 'debuff',
      StatusKind.moment => 'moment',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.panelHi,
        borderRadius: BorderRadius.circular(9),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                info.element == null
                    ? kindLabel
                    : '${info.element!.style.label} · $kindLabel',
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            info.description,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How: ${info.trigger}',
            style: const TextStyle(
              color: AppColors.textFaint,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
