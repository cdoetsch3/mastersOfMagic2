import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ai_personas.dart';
import '../game/auth_service.dart';
import '../game/duel_launcher.dart';
import '../game/game_state.dart';
import '../game/loadout.dart';
import '../game/matchmaking.dart';
import '../ui/app_theme.dart';
import 'account_screen.dart';

/// The matchmaking lobby: quick match (with AI stand-ins when no human is
/// found), friendly duels by room code, and the AI practice roster. Whatever
/// path is taken, the duel that follows is identical.
class MatchmakingScreen extends StatefulWidget {
  final Loadout loadout;

  const MatchmakingScreen({super.key, required this.loadout});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

enum _Busy { none, searching, hosting, joining }

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  _Busy _busy = _Busy.none;
  String? _roomCode;
  String? _error;
  final _codeField = TextEditingController();

  @override
  void dispose() {
    _codeField.dispose();
    super.dispose();
  }

  ({String uid, String name})? _identity() {
    final auth = AuthScope.maybeOf(context);
    final game = GameStateScope.read(context);
    final uid = auth?.user?.uid;
    if (uid == null) return null;
    return (uid: uid, name: game.profile.name);
  }

  Future<void> _quickMatch() async {
    final id = _identity();
    if (id == null) return _needAccount();
    final game = GameStateScope.read(context);
    setState(() {
      _busy = _Busy.searching;
      _error = null;
    });
    try {
      final result = await Matchmaking.quickMatch(
        uid: id.uid,
        name: id.name,
        level: game.profile.level,
      );
      if (!mounted) return;
      setState(() => _busy = _Busy.none);
      if (result.isHuman) {
        await launchDuel(context,
            loadout: widget.loadout, driver: result.remote!, campaign: false);
      } else {
        final persona = result.persona!;
        _showStandInNote(persona);
        await launchAiDuel(context,
            loadout: widget.loadout, persona: persona, campaign: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = _Busy.none;
          _error = 'Matchmaking failed. Try again.';
        });
      }
    }
  }

  void _showStandInNote(AiPersona persona) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.panel,
      content: Text(
          'No mages answered the call — ${persona.name} steps in!',
          style: const TextStyle(color: AppColors.text)),
    ));
  }

  Future<void> _hostRoom() async {
    final id = _identity();
    if (id == null) return _needAccount();
    setState(() {
      _busy = _Busy.hosting;
      _error = null;
    });
    try {
      final room = await Matchmaking.createRoom(uid: id.uid, name: id.name);
      if (!mounted) return;
      setState(() => _roomCode = room.code);
      final driver = await Matchmaking.waitForGuest(
          code: room.code, seed: room.seed);
      if (!mounted) return;
      setState(() {
        _busy = _Busy.none;
        _roomCode = null;
      });
      if (driver != null) {
        await launchDuel(context,
            loadout: widget.loadout, driver: driver, campaign: false);
      } else {
        await Matchmaking.cancel(uid: id.uid, roomCode: room.code);
        setState(() => _error = 'Nobody joined. Room closed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = _Busy.none;
          _roomCode = null;
          _error = 'Could not create a room.';
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final id = _identity();
    if (id == null) return _needAccount();
    final code = _codeField.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Enter the room code your friend shared.');
      return;
    }
    setState(() {
      _busy = _Busy.joining;
      _error = null;
    });
    try {
      final driver =
          await Matchmaking.joinRoom(code: code, uid: id.uid, name: id.name);
      if (!mounted) return;
      setState(() => _busy = _Busy.none);
      await launchDuel(context,
          loadout: widget.loadout, driver: driver, campaign: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = _Busy.none;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _needAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Account needed',
            style: TextStyle(color: AppColors.text, fontSize: 17)),
        content: const Text(
            'Dueling other players needs an account so they know who beat '
            'them. Practice duels vs AI work without one.',
            style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const AccountScreen()));
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Find a duel'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _busy == _Busy.searching
                ? _searchingView()
                : (_busy == _Busy.hosting && _roomCode != null)
                    ? _hostingView()
                    : _menu(),
          ),
        ),
      ),
    );
  }

  Widget _searchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(color: AppColors.gold),
        SizedBox(height: 18),
        Text('Searching for an opponent...',
            style: TextStyle(color: AppColors.text, fontSize: 16)),
        SizedBox(height: 6),
        Text('If no mage answers, a rival steps in.',
            style: TextStyle(color: AppColors.textDim, fontSize: 13)),
      ],
    );
  }

  Widget _hostingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Share this code with your friend',
            style: TextStyle(color: AppColors.textDim, fontSize: 14)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _roomCode!));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: AppColors.panel,
                content: Text('Code copied',
                    style: TextStyle(color: AppColors.text))));
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.panelHi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Text(_roomCode!,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 32,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.textDim),
        ),
        const SizedBox(height: 8),
        const Text('Waiting for them to join...',
            style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () async {
            final id = _identity();
            if (id != null && _roomCode != null) {
              await Matchmaking.cancel(uid: id.uid, roomCode: _roomCode);
            }
            if (mounted) {
              setState(() {
                _busy = _Busy.none;
                _roomCode = null;
              });
            }
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _menu() {
    final game = GameStateScope.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        GamePanel(
          onTap: _quickMatch,
          borderColor: AppColors.ember,
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: AppColors.ember, size: 26),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick match',
                        style:
                            TextStyle(color: AppColors.text, fontSize: 15)),
                    Text('Face another mage — or a rival AI if none answer',
                        style: TextStyle(
                            color: AppColors.textDim, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Friendly duel'),
        GamePanel(
          onTap: _busy == _Busy.none ? _hostRoom : null,
          child: Row(
            children: [
              const Icon(Icons.qr_code, color: AppColors.gold, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Create a room code',
                    style: TextStyle(color: AppColors.text, fontSize: 14)),
              ),
              if (_busy == _Busy.hosting)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GamePanel(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeField,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      color: AppColors.text, letterSpacing: 3),
                  decoration: const InputDecoration(
                    hintText: 'ROOM CODE',
                    hintStyle:
                        TextStyle(color: AppColors.textFaint, letterSpacing: 3),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.bg,
                ),
                onPressed: _busy == _Busy.none ? _joinRoom : null,
                child: _busy == _Busy.joining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join'),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: AppColors.ember, fontSize: 13)),
        ],
        const SizedBox(height: 14),
        const SectionLabel('Practice vs AI'),
        for (final persona in AiRoster.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GamePanel(
              onTap: () => launchAiDuel(
                context,
                loadout: widget.loadout,
                persona: persona,
                campaign: false,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: persona.apparel.robe,
                    child: Text(persona.name[0],
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${persona.name} · Lv ${persona.level}',
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 14)),
                        Text(persona.title,
                            style: const TextStyle(
                                color: AppColors.textDim, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (persona.level <= game.profile.level + 1)
                    const Icon(Icons.chevron_right,
                        color: AppColors.textFaint)
                  else
                    const Icon(Icons.warning_amber,
                        size: 16, color: AppColors.gold),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
