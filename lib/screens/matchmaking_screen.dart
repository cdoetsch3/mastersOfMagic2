import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../game/academy.dart';
import '../game/ai_personas.dart';
import '../game/auth_service.dart';
import '../game/duel_launcher.dart';
import '../game/game_state.dart';
import '../game/loadout.dart';
import '../game/matchmaking.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import '../ui/search_narration.dart';
import 'account_screen.dart';

/// The matchmaking lobby: quick match (one rated queue of humans and ladder
/// bots — LADDER_DESIGN §3), friendly duels by room code, and the AI practice
/// roster. ⚠️ Law 3 (§1): nothing player-facing here may say a queue opponent
/// might be a bot. The practice roster is the one place "AI" is said out
/// loud, because there the player picks the persona on purpose. Whatever
/// path is taken, the duel that follows is identical.
class MatchmakingScreen extends StatefulWidget {
  final Loadout loadout;

  /// The Academy queue (academy.dart): level 50, no gear, no belt, no
  /// reward, open to guests. [loadout] is then the Academy loadout.
  final bool academy;

  /// A room code arriving from a scanned QR link (main.dart's ?join=
  /// handling). Prefilled AND submitted — the person scanning has already
  /// expressed the intent; asking them to press Join again is a step nobody
  /// wants.
  final String? initialJoinCode;

  const MatchmakingScreen({
    super.key,
    required this.loadout,
    this.academy = false,
    this.initialJoinCode,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

enum _Busy { none, searching, hosting, joining }

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  _Busy _busy = _Busy.none;
  String? _roomCode;
  String? _error;
  final _codeField = TextEditingController();

  /// When the current search began — the anchor `_SearchingView` measures
  /// against before a match exists (LADDER §3). Lazily stamped by
  /// [_searchingView] and cleared by [build] whenever the search isn't
  /// running, so the *next* search gets a fresh timestamp instead of
  /// inheriting this one.
  DateTime? _searchStartedAt;

  /// When `quickMatch` returned a result (human or bot) — the anchor for the
  /// 1.2s "Found someone!" hold. Set by [_foundHold]; cleared the same way as
  /// [_searchStartedAt].
  DateTime? _matchedAt;

  @override
  void initState() {
    super.initState();
    final code = widget.initialJoinCode;
    if (code != null && code.isNotEmpty) {
      _codeField.text = code.toUpperCase();
      WidgetsBinding.instance.addPostFrameCallback((_) => _joinRoom());
    }
  }

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

  String get _mode => widget.academy ? Academy.mode : Academy.gearedMode;

  Future<void> _quickMatch() async {
    final id = _identity();
    if (id == null) return _needAccount(_quickMatch);
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
        // ⭐ PvP is the geared ladder (ITEMS §7.4): our totals go out so the
        // opponent's client can build us as we actually are.
        gear: game.equipmentTotals,
        mode: _mode,
      );
      await _foundHold();
      if (!mounted) return;
      setState(() => _busy = _Busy.none);
      if (result.isHuman) {
        await launchDuel(
          context,
          loadout: widget.loadout,
          driver: result.remote!,
          campaign: false,
          academy: widget.academy,
        );
      } else {
        final persona = result.persona!;
        _showStandInNote(persona);
        await launchAiDuel(
          context,
          loadout: widget.loadout,
          persona: persona,
          campaign: false,
          academy: widget.academy,
        );
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

  /// ⭐ LADDER §3's no-leak rule: stamps [_matchedAt] so `_SearchingView`
  /// switches to "Found someone!", then holds for a fixed 1.2s before
  /// `_quickMatch` is allowed to move on to loading the duel — the same
  /// pause for a bot's instant driver build as for a human handshake.
  /// The ONLY thing `_quickMatch` calls into this file for.
  Future<void> _foundHold() async {
    if (!mounted) return;
    setState(() => _matchedAt = DateTime.now());
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }

  /// ⭐ Banner: nothing on the duel screen that follows says the opponent is
  /// a stand-in rather than the human the player queued for. Raised in the
  /// root overlay, so it survives the push into the duel.
  void _showStandInNote(AiPersona persona) => showAppBanner(
    context,
    'No mages answered the call — ${persona.name} steps in!',
  );

  Future<void> _hostRoom() async {
    final id = _identity();
    if (id == null) return _needAccount(_hostRoom);
    setState(() {
      _busy = _Busy.hosting;
      _error = null;
    });
    try {
      final game = GameStateScope.read(context);
      final room = await Matchmaking.createRoom(
        uid: id.uid,
        name: id.name,
        level: game.profile.level,
        gear: game.equipmentTotals,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() => _roomCode = room.code);
      final driver = await Matchmaking.waitForGuest(
        code: room.code,
        seed: room.seed,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() {
        _busy = _Busy.none;
        _roomCode = null;
      });
      if (driver != null) {
        await launchDuel(
          context,
          loadout: widget.loadout,
          driver: driver,
          campaign: false,
          academy: widget.academy,
        );
      } else {
        await Matchmaking.cancel(uid: id.uid, roomCode: room.code);
        setState(() => _error = 'Nobody joined. Room closed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = _Busy.none;
          _roomCode = null;
          _error = 'Room error: $e';
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final id = _identity();
    if (id == null) return _needAccount(_joinRoom);
    final code = _codeField.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Enter the room code your friend shared.');
      return;
    }
    setState(() {
      _busy = _Busy.joining;
      _error = null;
    });
    final game = GameStateScope.read(context);
    try {
      final driver = await Matchmaking.joinRoom(
        code: code,
        uid: id.uid,
        name: id.name,
        level: game.profile.level,
        gear: game.equipmentTotals,
      );
      if (!mounted) return;
      setState(() => _busy = _Busy.none);
      // ⭐ A room is the HOST's duel: a guest who arrives by code (or by a
      // scanned QR, with whatever loadout the shell handed them) fights the
      // room's mode with the loadout that mode calls for.
      final academy = driver.academy;
      final loadout = academy == widget.academy
          ? widget.loadout
          : academy
          ? game.profile.academyPreset.toLoadout()
          : game.profile.activePreset.toLoadout();
      await launchDuel(
        context,
        loadout: loadout,
        driver: driver,
        campaign: false,
        academy: academy,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = _Busy.none;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  /// No uid yet. An account is the full answer; ⭐ for the Academy a guest
  /// sign-in is enough (academy.dart) — an anonymous uid satisfies the
  /// matchmaking rules, and [retry] resumes whatever they pressed.
  void _needAccount(Future<void> Function() retry) {
    final auth = AuthScope.maybeOf(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(
          widget.academy ? 'Who are you?' : 'Account needed',
          style: const TextStyle(color: AppColors.text, fontSize: 17),
        ),
        content: Text(
          widget.academy
              ? 'The Academy is open to guests — play under a temporary '
                    'name, or sign in to keep a character.'
              : 'Dueling other players needs an account so they know who '
                    'beat them. Practice duels vs AI work without one.',
          style: const TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
          if (widget.academy && auth != null)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final error = await auth.signInAsGuest();
                if (!mounted) return;
                if (error != null) {
                  setState(() => _error = error);
                  return;
                }
                await retry();
              },
              child: const Text('Play as guest'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              );
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Cleared whenever a search isn't in flight, so the *next* quick match
    // stamps a fresh `_searchStartedAt` in [_searchingView] rather than
    // reusing this one's — mutated outside setState because this only ever
    // narrows a rebuild that's already happening, never triggers one.
    if (_busy != _Busy.searching) {
      _searchStartedAt = null;
      _matchedAt = null;
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(widget.academy ? 'The Academy' : 'Find a duel'),
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
    final startedAt = _searchStartedAt ??= DateTime.now();
    return _SearchingView(startedAt: startedAt, matchedAt: _matchedAt);
  }

  Widget _hostingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Share this code with your friend',
          style: TextStyle(color: AppColors.textDim, fontSize: 14),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _roomCode!));
            // ⭐ Banner: the clipboard is invisible. Without a notice a tap
            // on the code does nothing observable at all.
            showAppBanner(context, 'Code copied');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.panelHi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Text(
              _roomCode!,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 32,
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ⭐ Scannable with the phone's own camera — the QR is just a join
        // URL, so the friend needs no in-app scanner: scan, tap, the app
        // opens and auto-joins (main.dart reads ?join= at boot).
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: QrImageView(
            data: 'https://mastersofmagic2.web.app/?join=${_roomCode!}',
            version: QrVersions.auto,
            size: 150,
            // ⚠️ Solid white quiet zone + black modules — QR contrast is not
            // the place for the app palette.
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'or scan to join',
          style: TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Waiting for them to join...',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
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
        if (widget.academy) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.panelHi,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gem),
            ),
            child: const Row(
              children: [
                Icon(Icons.school, color: AppColors.gem, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Everyone duels at level 50 with no gear and no potions. '
                    'Nothing is gained or lost — bring your Academy loadout.',
                    style: TextStyle(color: AppColors.text, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
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
                    Text(
                      'Quick match',
                      style: TextStyle(color: AppColors.text, fontSize: 15),
                    ),
                    Text(
                      'Face another mage from the queue',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
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
                child: Text(
                  'Create a room code',
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                ),
              ),
              if (_busy == _Busy.hosting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
                    color: AppColors.text,
                    letterSpacing: 3,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'ROOM CODE',
                    hintStyle: TextStyle(
                      color: AppColors.textFaint,
                      letterSpacing: 3,
                    ),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.ember, fontSize: 13),
          ),
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
                    child: Text(
                      persona.name[0],
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${persona.name} · Lv ${persona.level}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          persona.title,
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (persona.level <= game.profile.level + 1)
                    const Icon(Icons.chevron_right, color: AppColors.textFaint)
                  else
                    const Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.gold,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The quick-match waiting screen: a status line that advances with the
/// search (LADDER_DESIGN §3), plus one gameplay tip so the ~10s wait teaches
/// a mechanic instead of feeling dead. A single tip (varied per search) —
/// they're long enough that one is a comfortable read in the time available.
///
/// ⭐ [startedAt]/[matchedAt] are constructor-injected rather than read from
/// `DateTime.now()` internally, so a widget test can pin both and assert an
/// exact phase instead of racing the wall clock (LADDER §3).
class _SearchingView extends StatefulWidget {
  final DateTime startedAt;
  final DateTime? matchedAt;

  const _SearchingView({required this.startedAt, this.matchedAt});

  @override
  State<_SearchingView> createState() => _SearchingViewState();
}

class _SearchingViewState extends State<_SearchingView> {
  static const List<({String title, String body})> _tips = [
    (
      title: 'Haste',
      body:
          'Casting first seizes Haste — it wins any tie when you both play the same-speed spell.',
    ),
    (
      title: 'Priority',
      body:
          'Shields (3) go up before regular attacks (9). A Quickened attack (2) can beat a shield.',
    ),
    (
      title: 'Elements',
      body:
          'Elements only matter for shields: a countering attack deals DOUBLE to a shield of the element it beats.',
    ),
    (
      title: 'Channel',
      body:
          'Channeling resolves at priority 4 — a faster Discharge or Overload can punish you mid-charge.',
    ),
    (
      title: 'Discharge',
      body:
          'Discharge (7) wipes all enemy charge and, being faster, fizzles a same-turn Barrage (9).',
    ),
    (
      title: 'Overload',
      body:
          "Overload deals damage per point of the enemy's charge — brutal against a fully-charged mage.",
    ),
    (
      title: 'Air',
      body:
          'Air is the untouchable wind: its shields can never be double-broken, but its attacks never crack shields.',
    ),
    (
      title: 'Bluffing',
      body:
          "You can see what your opponent is charging — but not whether they'll strike, shield, or keep charging.",
    ),
    (
      title: 'Barrier',
      body:
          'Barrier blocks one hit completely, then shatters — a great answer to a big incoming Cataclysm.',
    ),
    (
      title: 'Lifesteal',
      body:
          'Sap, Leech, and Drain heal you for the damage that reaches health — not damage soaked by a shield.',
    ),
  ];

  // Deterministic-but-varied tip pick without dart:math in the widget.
  late final int _i = DateTime.now().microsecondsSinceEpoch % _tips.length;

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_i];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 18),
          // ⭐ The ticking phase label lives in ui/search_narration.dart
          // (LADDER §3) so it can be pumped and asserted on by itself.
          SearchStatusLine(
            startedAt: widget.startedAt,
            matchedAt: widget.matchedAt,
          ),
          const SizedBox(height: 28),
          GamePanel(
            color: AppColors.panel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tip · ${tip.title}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tip.body,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
