import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../ui/app_banner.dart';
import '../ui/app_theme.dart';
import 'gate_screen.dart';
import 'matchmaking_screen.dart';
import 'profile_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/social_tab.dart';
import 'tabs/spellbook_tab.dart';

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}

const List<_TabDef> _tabs = [
  _TabDef(Icons.map, 'Map'),
  _TabDef(Icons.backpack, 'Items'),
  _TabDef(Icons.auto_fix_high, 'Home'), // center (raised) — magic wand
  _TabDef(Icons.menu_book, 'Spells'),
  _TabDef(Icons.groups, 'Social'),
];

const int _centerIndex = 2;

/// The five-tab shell. Portrait: bottom bar with a raised center play button.
/// Landscape: a left nav rail (also with an emphasized center) so a player can
/// stay in landscape through menus and combat without flipping the phone.
class HomeShell extends StatefulWidget {
  /// A room code from a scanned QR link — pushed straight to the
  /// matchmaking screen on first frame (main.dart reads ?join= at boot).
  final String? pendingJoinCode;

  const HomeShell({super.key, this.pendingJoinCode});

  /// Cross-route tab requests (routes pushed above the shell can't reach its
  /// state through context). Setting a tab index here switches the shell to
  /// it; [goHome] is the common case, e.g. after signing in.
  static final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

  static void goHome() => tabRequest.value = _centerIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = _centerIndex;

  void _select(int i) => setState(() => _index = i);

  /// The game whose [GameState.notice] this shell shows — captured once, so
  /// [dispose] can unhook the same notifier it hooked.
  GameState? _noticeSource;

  @override
  void initState() {
    super.initState();
    HomeShell.tabRequest.addListener(_onTabRequest);
    // ⭐ Save-level news (a sync conflict, a repair) has no screen of its own;
    // the shell is the one surface alive for every such moment. Post-frame,
    // because the banner needs the overlay — and a notice raised during boot
    // is already waiting by then, so it is shown straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _noticeSource = GameStateScope.read(context)
        ..notice.addListener(_onNotice);
      _onNotice();
    });
    final code = widget.pendingJoinCode;
    if (code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final game = GameStateScope.read(context);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchmakingScreen(
              loadout: game.profile.activePreset.toLoadout(),
              initialJoinCode: code,
            ),
          ),
        );
      });
    }
  }

  void _onTabRequest() {
    final requested = HomeShell.tabRequest.value;
    if (requested != null && mounted) {
      _select(requested);
      HomeShell.tabRequest.value = null;
    }
  }

  /// Shows a pending notice once, then clears it so a rebuild never repeats it.
  void _onNotice() {
    final source = _noticeSource;
    final text = source?.notice.value;
    if (source == null || text == null || !mounted) return;
    source.notice.value = null;
    showAppBanner(context, text);
  }

  @override
  void dispose() {
    HomeShell.tabRequest.removeListener(_onTabRequest);
    _noticeSource?.notice.removeListener(_onNotice);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MapTab(onSelectTab: _select),
      const InventoryTab(),
      HomeTab(onSelectTab: _select),
      const SpellbookTab(),
      const SocialTab(),
    ];
    // Phone-first content: on wide screens (desktop / landscape tablets),
    // centre the shell in a phone-ish column instead of letting cards and
    // grids balloon to fill the width.
    //
    // ⚠️ The constraint wraps the **whole shell**, not just the content —
    // see below. Constraining only the content left the nav bar wider than
    // the thing it navigates.
    final body = IndexedStack(index: _index, children: tabs);

    // ⭐ Standing at a shut gate replaces the whole shell with the gate
    // screen (ruling 2026-09-25) — see [GateCheckpoint]. The tab index lives
    // in this State, above the checkpoint, so it survives the visit.
    return GateCheckpoint(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          // ⭐ One column for content AND chrome, so the bar can never drift
          // wider than what it navigates.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: MaxWidth.shellWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final landscape =
                      constraints.maxWidth > constraints.maxHeight;
                  if (landscape) {
                    return Row(
                      children: [
                        _NavRail(index: _index, onSelect: _select),
                        Expanded(child: body),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: body),
                      _BottomBar(index: _index, onSelect: _select),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _BottomBar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.borderDim)),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: i == _centerIndex
                  ? _CenterButton(active: index == i, onTap: () => onSelect(i))
                  : _BarTab(
                      def: _tabs[i],
                      active: index == i,
                      onTap: () => onSelect(i),
                    ),
            ),
        ],
      ),
    );
  }
}

class _BarTab extends StatelessWidget {
  final _TabDef def;
  final bool active;
  final VoidCallback onTap;
  const _BarTab({required this.def, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textFaint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(def.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(def.label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _CenterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold,
                border: Border.all(color: AppColors.bg, width: 3),
              ),
              alignment: Alignment.center,
              child: const WizardHatIcon(size: 28, color: AppColors.bg),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -14),
            child: Text(
              'Home',
              style: TextStyle(
                color: active ? AppColors.gold : AppColors.textDim,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _NavRail({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(right: BorderSide(color: AppColors.borderDim)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: i == _centerIndex
                  ? _RailCenter(active: index == i, onTap: () => onSelect(i))
                  : _RailTab(
                      def: _tabs[i],
                      active: index == i,
                      onTap: () => onSelect(i),
                    ),
            ),
        ],
      ),
    );
  }
}

class _RailTab extends StatelessWidget {
  final _TabDef def;
  final bool active;
  final VoidCallback onTap;
  const _RailTab({
    required this.def,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textFaint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(def.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(def.label, style: TextStyle(color: color, fontSize: 9.5)),
          ],
        ),
      ),
    );
  }
}

class _RailCenter extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _RailCenter({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              border: Border.all(color: AppColors.bg, width: 3),
            ),
            alignment: Alignment.center,
            child: const WizardHatIcon(size: 24, color: AppColors.bg),
          ),
          const SizedBox(height: 2),
          Text(
            'Home',
            style: TextStyle(
              color: active ? AppColors.gold : AppColors.textDim,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared header used by the tab screens: the Profile pill, and the
/// currencies. Reads live from [GameState].
///
/// ⭐ The name-and-level pill is a **button** (ruling 2026-09-21, mockup
/// option A): it opens [ProfileScreen], so every tab that already draws this
/// header carries the way into the profile for free — and no tab has to
/// spend a card on Skills or the rules.
///
/// 📝 Ruling 2026-09-25: no screen title. The bottom nav already says which
/// tab is open, so the 'Home'/'Inventory'/… line above the pill was a
/// duplicate — its height went to the pill instead, "so it's more obviously
/// clickable". The `title` parameter went with it (every caller was a
/// `const PlayerHeader(title: …)`, so they all simply lost the argument).
class PlayerHeader extends StatelessWidget {
  const PlayerHeader({super.key});

  /// The header's exact height, pinned rather than left to the content.
  ///
  /// ⭐ **Press-stability.** A header that measured itself would move every
  /// tab's first control down whenever its content changed — and move it
  /// again for a name long enough to wrap. One number, one y, whatever the
  /// name and whatever the font.
  ///
  /// ⚠️ 52 is what the two-line text header measured before the pill (18px
  /// title + 12px line + 10/6 padding), so nothing below it moved on the day
  /// the pill shipped — nor on the day the title left (2026-09-25): the
  /// bigger pill (≈38px: a 28px avatar + 4/4 padding + the edge) sits inside
  /// the same 52. Grow the pill past it and this overflows rather than
  /// silently growing back.
  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final p = GameStateScope.of(context).profile;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // ⚠️ Align, not a bare child: the pill keeps its own width (a
            // button the size of the whole row would read as a banner, not
            // a control) and can still shrink for a long name.
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ProfilePill(name: p.name, level: p.level),
              ),
            ),
            const SizedBox(width: 8),
            _Currency(leading: const CoinIcon(size: 15), value: p.gold),
            const SizedBox(width: 8),
            _Currency(
              leading: const Icon(
                Icons.diamond,
                size: 14,
                color: AppColors.gem,
              ),
              value: p.resonancePrisms,
            ),
          ],
        ),
      ),
    );
  }
}

/// The header's Profile button: badge, name, level, chevron.
///
/// ⚠️ Looks like a control on purpose — the panel fill, the edge and the
/// chevron are what say "this is tappable"; the same two facts as plain text
/// would have read as a caption, which is what shipped.
///
/// 📝 Sizes (ruling 2026-09-25, when the screen title left): avatar 28,
/// name 17 semibold, 'Lv N' 14 dim, chevron 20.
class _ProfilePill extends StatelessWidget {
  final String name;
  final int level;
  const _ProfilePill({required this.name, required this.level});

  @override
  Widget build(BuildContext context) {
    // ⚠️ Its **own** [Material], not a bare InkWell: the header is drawn by
    // five tabs and by anything that pumps one, and an InkWell with no
    // Material above it is an assertion, not a missing splash. The fill and
    // the edge live on the Material's shape so the ink lands on top of them
    // rather than behind an opaque Container.
    return Material(
      color: AppColors.panel,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(name: name, size: 28),
              const SizedBox(width: 8),
              // ⚠️ Flexible + ellipsis: a long name shortens, it does not
              // wrap — a second line would break the pinned header height.
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lv $level',
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 14,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Currency extends StatelessWidget {
  final Widget leading;
  final int value;
  const _Currency({required this.leading, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 5),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
