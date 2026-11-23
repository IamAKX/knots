import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/ui.dart';
import 'welcome.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon, this.selIcon);
  final String path, label;
  final IconData icon, selIcon;
}

const navItems = [
  NavItem('/', 'Home', Icons.home_outlined, Icons.home_rounded),
  NavItem(
    '/expenses',
    'Expenses',
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
  ),
  NavItem(
    '/budget',
    'Budget',
    Icons.pie_chart_outline_rounded,
    Icons.pie_chart_rounded,
  ),
  NavItem(
    '/tasks',
    'To-do',
    Icons.checklist_rounded,
    Icons.checklist_rtl_rounded,
  ),
  NavItem('/guests', 'Guests', Icons.groups_outlined, Icons.groups_rounded),
  NavItem('/food', 'Food', Icons.restaurant_outlined, Icons.restaurant_rounded),
  NavItem(
    '/gifts',
    'Gifts',
    Icons.card_giftcard_outlined,
    Icons.card_giftcard_rounded,
  ),
  NavItem(
    '/vendors',
    'Vendors',
    Icons.storefront_outlined,
    Icons.storefront_rounded,
  ),
  NavItem(
    '/shopping',
    'Shopping',
    Icons.shopping_bag_outlined,
    Icons.shopping_bag_rounded,
  ),
  NavItem(
    '/settings',
    'Settings',
    Icons.settings_outlined,
    Icons.settings_rounded,
  ),
];

const _mobileMain = ['/', '/expenses', '/tasks', '/guests'];

class Shell extends StatelessWidget {
  const Shell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final w = MediaQuery.sizeOf(context).width;

    if (w >= 720) {
      final expanded = w >= 1080;
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(loc: loc, expanded: expanded),
            Expanded(child: ClipRect(child: child)),
          ],
        ),
      );
    }

    final idx = _mobileMain.indexOf(loc);
    final sel = idx >= 0 ? idx : 4;
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.card,
          border: Border(top: BorderSide(color: context.line)),
        ),
        child: SafeArea(
          child: NavigationBar(
            height: 66,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: context.accent.withValues(alpha: .12),
            selectedIndex: sel,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) =>
                context.go(i == 4 ? '/more' : _mobileMain[i]),
            destinations: [
              for (final p in _mobileMain)
                () {
                  final n = navItems.firstWhere((e) => e.path == p);
                  return NavigationDestination(
                    icon: Icon(n.icon),
                    selectedIcon: Icon(n.selIcon),
                    label: n.label,
                  );
                }(),
              const NavigationDestination(
                icon: Icon(Icons.apps_rounded),
                selectedIcon: Icon(Icons.apps_rounded),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.loc, required this.expanded});
  final String loc;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 240 : 84,
      decoration: BoxDecoration(
        color: context.card,
        border: Border(right: BorderSide(color: context.line)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 28),
            child: Row(
              children: [
                const KnotsMark(size: 32),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Text('Knots', style: context.tt.headlineSmall),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final n in navItems.where((e) => e.path != '/settings'))
                  _Item(n, loc == n.path, expanded),
              ],
            ),
          ),
          _Item(navItems.last, loc == '/settings', expanded),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.n, this.sel, this.expanded);
  final NavItem n;
  final bool sel, expanded;
  @override
  Widget build(BuildContext context) {
    final fg = sel ? Theme.of(context).colorScheme.onPrimary : context.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: expanded ? '' : n.label,
        child: Material(
          color: sel ? context.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            hoverColor: context.soft,
            onTap: () => context.go(n.path),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 14 : 0,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(sel ? n.selIcon : n.icon, size: 22, color: fg),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Text(
                      n.label,
                      style: context.tt.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile "More" grid.
class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = navItems.where((n) => !_mobileMain.contains(n.path)).toList();
    return PageFrame(
      title: 'More',
      subtitle: 'Everything else for the big day',
      children: [
        Tiles(
          min: 150,
          children: [
            for (final n in items)
              AppCard(
                onTap: () => context.go(n.path),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.soft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(n.selIcon, color: context.accent),
                    ),
                    const SizedBox(height: 28),
                    Text(n.label, style: context.tt.titleMedium),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
