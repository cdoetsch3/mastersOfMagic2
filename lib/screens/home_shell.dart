import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../ui/app_theme.dart';
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
  const HomeShell({super.key});

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

  @override
  void initState() {
    super.initState();
    HomeShell.tabRequest.addListener(_onTabRequest);
  }

  void _onTabRequest() {
    final requested = HomeShell.tabRequest.value;
    if (requested != null && mounted) {
      _select(requested);
      HomeShell.tabRequest.value = null;
    }
  }

  @override
  void dispose() {
    HomeShell.tabRequest.removeListener(_onTabRequest);
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
    // center the tab content in a phone-ish column instead of letting cards
    // and grids balloon to fill the width.
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: IndexedStack(index: _index, children: tabs),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
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
                  ? _CenterButton(
                      active: index == i, onTap: () => onSelect(i))
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
  const _BarTab(
      {required this.def, required this.active, required this.onTap});

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
            child: Text('Home',
                style: TextStyle(
                    color: active ? AppColors.gold : AppColors.textDim,
                    fontSize: 11)),
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
  const _RailTab(
      {required this.def, required this.active, required this.onTap});

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
          Text('Home',
              style: TextStyle(
                  color: active ? AppColors.gold : AppColors.textDim,
                  fontSize: 9.5)),
        ],
      ),
    );
  }
}

/// Shared header used by the tab screens: character name, level, and
/// currencies. Reads live from [GameState].
class PlayerHeader extends StatelessWidget {
  final String title;
  const PlayerHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final p = GameStateScope.of(context).profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                Text('${p.name}  ·  Level ${p.level}',
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          _Currency(leading: const CoinIcon(size: 15), value: p.gold),
          const SizedBox(width: 8),
          _Currency(
              leading: const Icon(Icons.diamond, size: 14, color: AppColors.gem),
              value: p.gems),
        ],
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
          Text('$value',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
