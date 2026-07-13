import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mom_engine/mom_engine.dart';

/// Milestone 1 capstone: proves the combat engine works end-to-end inside the
/// app by running AI-vs-AI duels and rendering the turn log. This screen is
/// temporary scaffolding — the real duel UI replaces it in a later milestone.
class EngineDemoScreen extends StatefulWidget {
  const EngineDemoScreen({super.key});

  @override
  State<EngineDemoScreen> createState() => _EngineDemoScreenState();
}

class _EngineDemoScreenState extends State<EngineDemoScreen> {
  final List<_TurnLog> _turns = [];
  String _outcome = '';
  int _duelCount = 0;

  @override
  void initState() {
    super.initState();
    _runDuel();
  }

  void _runDuel() {
    final rng = Random(_duelCount++);
    final aldric = MageState(name: 'Aldric');
    final morwen = MageState(name: 'Morwen');
    final duel = DuelEngine(aldric, morwen, rng: rng);
    final ai1 = GreedyAi();
    final ai2 = GreedyAi();
    final turns = <_TurnLog>[];
    while (!duel.isOver && duel.turnNumber < 200) {
      final result = duel.resolveTurn(
        ai1.chooseAction(aldric, morwen, rng),
        ai2.chooseAction(morwen, aldric, rng),
      );
      turns.add(_TurnLog(
        turn: result.turn,
        hp1: aldric.hp,
        hp2: morwen.hp,
        lines: result.events.map((e) => e.toString()).toList(),
      ));
    }
    setState(() {
      _turns
        ..clear()
        ..addAll(turns);
      _outcome = duel.isDraw
          ? 'Draw — both mages fall!'
          : '${duel.winner!.name} wins on turn ${duel.turnNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masters of Magic 2 — engine demo'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runDuel,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('New duel'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_outcome, style: theme.textTheme.titleLarge),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _turns.length,
              itemBuilder: (context, i) {
                final t = _turns[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Turn ${t.turn}   —   Aldric ${t.hp1} hp · '
                          'Morwen ${t.hp2} hp',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        for (final line in t.lines)
                          Text(line, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnLog {
  final int turn;
  final int hp1;
  final int hp2;
  final List<String> lines;

  const _TurnLog({
    required this.turn,
    required this.hp1,
    required this.hp2,
    required this.lines,
  });
}
