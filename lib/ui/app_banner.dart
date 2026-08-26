/// Transient notices, moved off the bottom of the screen.
///
/// ⭐ **The designer's ruling (2026-08-26): bottom SnackBars are in the way.**
/// Every action area in this game lives at the BOTTOM — the settle bar, the
/// craft button, the belt row, the duel's spell tray — and a SnackBar parks
/// itself on top of exactly those, so a notice about what you just did hides
/// the thing you press next. Every notice was re-triaged under one rule:
///
/// * the screen already shows the outcome → say nothing (gold and stock move
///   on their own; a deposited item leaves the grid),
/// * info-bearing but transient → [showAppBanner], which floats under the app
///   bar, expires on its own, and never touches the bottom half,
/// * a refusal the player must not miss → [showAppAlert], which stops them.
///
/// ⚠️ **This file replaces `ScaffoldMessenger` app-wide.** A SnackBar added
/// back anywhere re-opens the bug — see the banner tests, which assert not
/// only that a notice appears but that it appears in the TOP half with no
/// SnackBar anywhere in the tree.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// How long a banner is readable before it retires itself.
const Duration kAppBannerHold = Duration(milliseconds: 2500);

/// The fade at each end. Short enough that [kAppBannerHold] is the number a
/// reader has to reason about, long enough not to pop.
const Duration kAppBannerFade = Duration(milliseconds: 160);

/// ⭐ **One at a time, module-wide.** Two notices stacked at the top would
/// re-create the very obstruction this component exists to remove, and a
/// player who taps twice wants the SECOND answer — so a new banner replaces
/// its predecessor rather than queueing behind it.
_LiveBanner? _current;

/// Raise a banner over [context]'s route.
///
/// [color] tints the border (and only the border — the message itself stays
/// [AppColors.text] so a red notice is no harder to read than a plain one).
void showAppBanner(BuildContext context, String text, {Color? color}) =>
    appBannerOf(context).show(text, color: color);

/// ⭐ The `ScaffoldMessenger.of(context)`-before-the-await idiom, kept.
/// Several callers pop a dialog or a route and THEN report the outcome, at
/// which point their own `context` is gone. Capturing the root overlay first
/// is how those sites stayed correct before, and it is how they stay correct
/// now.
AppBannerMessenger appBannerOf(BuildContext context) =>
    AppBannerMessenger._(Overlay.of(context, rootOverlay: true));

/// A captured handle to the overlay a banner will be raised in.
class AppBannerMessenger {
  final OverlayState _overlay;

  const AppBannerMessenger._(this._overlay);

  void show(String text, {Color? color}) {
    // ⚠️ Retire the incumbent BEFORE inserting, so the two never overlap for
    // even one frame.
    _current?.remove();
    late final _LiveBanner live;
    final entry = OverlayEntry(
      builder: (_) => _AppBannerHost(
        text: text,
        color: color,
        onRetire: () => live.remove(),
      ),
    );
    live = _LiveBanner(entry);
    _current = live;
    _overlay.insert(entry);
  }
}

/// ⚠️ `OverlayEntry.remove()` throws if it is called twice, and the entry can
/// be retired from either end (its own timer, or a replacement arriving). A
/// plain bool is the whole guard — `OverlayEntry.mounted` is NOT, because an
/// entry inserted but not yet built reports `false` while still needing
/// removal.
class _LiveBanner {
  final OverlayEntry entry;
  bool _removed = false;

  _LiveBanner(this.entry);

  void remove() {
    if (_removed) return;
    _removed = true;
    if (identical(_current, this)) _current = null;
    entry.remove();
  }
}

class _AppBannerHost extends StatefulWidget {
  final String text;
  final Color? color;
  final VoidCallback onRetire;

  const _AppBannerHost({
    required this.text,
    required this.color,
    required this.onRetire,
  });

  @override
  State<_AppBannerHost> createState() => _AppBannerHostState();
}

class _AppBannerHostState extends State<_AppBannerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: kAppBannerFade,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOut,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fade.forward();
    // ⚠️ **The timer belongs to the STATE, not to `showAppBanner`.** A timer
    // owned by the caller outlives the widget tree, and every widget test
    // that raises a banner and ends inside 2.5s then fails with "a Timer is
    // still pending". Cancelled in [dispose], so teardown is clean.
    _timer = Timer(kAppBannerHold, _retire);
  }

  Future<void> _retire() async {
    if (!mounted) return;
    await _fade.reverse();
    if (!mounted) return;
    widget.onRetire();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      // ⭐ **Below the app bar, never over it.** The status bar inset plus a
      // toolbar puts the banner in the first band of free content on every
      // screen that has a bar, and comfortably near the top on those that
      // do not.
      top: media.padding.top + kToolbarHeight + 10,
      left: 12,
      right: 12,
      child: IgnorePointer(
        // ⭐ No interaction required, and — deliberately — none possible:
        // taps fall through to the screen underneath, so a banner cannot
        // swallow the button a player is already reaching for.
        child: FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(_curve),
            child: Center(child: AppBanner(text: widget.text, color: color)),
          ),
        ),
      ),
    );
  }

  Color? get color => widget.color;
}

/// The banner itself, split out so tests can find it by type and pin where it
/// sits without reaching into the overlay's plumbing.
class AppBanner extends StatelessWidget {
  final String text;
  final Color? color;

  const AppBanner({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: GamePanel(
        color: AppColors.panel,
        borderColor: color ?? AppColors.border,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text, fontSize: 13.5),
        ),
      ),
    ),
  );
}

/// ⭐ **The escalation.** Reserved for the refusals a banner could be missed
/// at a cost: a basket refused mid-settle (the player staged a dozen steppers
/// and is owed the reason), and a travel that did not persist (the screen
/// says you moved; the save says otherwise). Everything else is a banner —
/// a modal for "your pack is full" would be worse than the SnackBar was.
Future<void> showAppAlert(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    backgroundColor: AppColors.panel,
    title: Text(
      title,
      style: const TextStyle(color: AppColors.text, fontSize: 17),
    ),
    content: Text(
      message,
      style: const TextStyle(color: AppColors.textDim, fontSize: 13),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Right'),
      ),
    ],
  ),
);
