/// The quick-match status line: pure phase logic (LADDER_DESIGN §3's
/// narration table) plus the small ticking widget built on top of it.
/// [phaseAt] stays a plain function of elapsed time and nothing else, so it
/// can be pinned at exact millisecond boundaries in a plain `test`, no
/// `testWidgets` pump required.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The four things the search screen can say. Order matches the table in
/// LADDER_DESIGN §3 — searching, then almost there, then found, then
/// loading — but nothing here encodes *why* a phase changed.
enum SearchPhase { searching, almostThere, found, loading }

/// ⭐ **LADDER_DESIGN §1 law 3 / §3's no-leak rule, as pure logic.** The only
/// inputs are elapsed time and whether a match exists yet — there is no
/// "which search phase found it" flag, because threading one through would
/// be exactly the disclosure law 3 forbids. A bot resolves at a fixed clock
/// mark and builds instantly; a human resolves at a random moment and takes
/// a beat to hand back a driver. Both wear the same status line because both
/// are driven by the same two facts.
///
/// [elapsed] means two different things depending on [matched], and the
/// caller is responsible for measuring the right one:
///  - not yet matched: time since the search **started**.
///  - matched: time since the match was **found**.
///
/// ⚠️ Boundaries are half-open on the low end: `elapsed == 6s` (unmatched)
/// is already [SearchPhase.almostThere], and `elapsed == 1200ms` (matched)
/// is already [SearchPhase.loading] — the hold is "at least 1.2s", not
/// "more than 1.2s".
SearchPhase phaseAt(Duration elapsed, {required bool matched}) {
  if (!matched) {
    return elapsed < const Duration(seconds: 6)
        ? SearchPhase.searching
        : SearchPhase.almostThere;
  }
  // ⭐ The fixed 1.2s hold (LADDER §3): a bot's driver build is instant, but
  // the player must never be able to time that against a human's handshake.
  return elapsed < const Duration(milliseconds: 1200)
      ? SearchPhase.found
      : SearchPhase.loading;
}

/// The status line text for each phase (LADDER_DESIGN §3's table, verbatim).
extension SearchPhaseLabel on SearchPhase {
  String get label => switch (this) {
    SearchPhase.searching => 'Searching for an opponent…',
    SearchPhase.almostThere => 'Almost there…',
    SearchPhase.found => 'Found someone!',
    SearchPhase.loading => 'Loading the duel…',
  };
}

/// The quick-match screen's status line, on its own so it can be pumped and
/// asserted on directly instead of only through the whole matchmaking flow.
///
/// ⭐ [startedAt]/[matchedAt] are constructor-injected rather than read from
/// `DateTime.now()` internally, so a widget test can pin both and assert an
/// exact phase instead of racing the wall clock (LADDER §3).
class SearchStatusLine extends StatefulWidget {
  /// When the search began — the anchor before a match exists.
  final DateTime startedAt;

  /// When `quickMatch` returned a result (human or bot), or null while still
  /// searching — the anchor for the 1.2s "Found someone!" hold.
  final DateTime? matchedAt;

  const SearchStatusLine({super.key, required this.startedAt, this.matchedAt});

  @override
  State<SearchStatusLine> createState() => _SearchStatusLineState();
}

class _SearchStatusLineState extends State<SearchStatusLine> {
  /// ⭐ Re-renders every 250ms (LADDER §3) — coarse enough to cost nothing,
  /// fine enough that the 6s/1.2s boundaries never visibly lag. Disposed
  /// below.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// The phase to show right now, read fresh off the wall clock against
  /// whichever anchor applies ([phaseAt]'s doc): elapsed since [startedAt]
  /// before a match exists, elapsed since [matchedAt] once one does.
  SearchPhase get _phase {
    final matchedAt = widget.matchedAt;
    final matched = matchedAt != null;
    final elapsed = matched
        ? DateTime.now().difference(matchedAt)
        : DateTime.now().difference(widget.startedAt);
    return phaseAt(elapsed, matched: matched);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _phase.label,
      style: const TextStyle(color: AppColors.text, fontSize: 16),
    );
  }
}
