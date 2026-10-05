import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/view_models/account_view_model.dart';

/// The frame around the tabs: a bottom navigation bar on narrow screens
/// (phones), a navigation rail on the left on wide ones (Windows and the
/// browser).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  /// Comes from go_router; knows which tab is open and how to switch.
  final StatefulNavigationShell navigationShell;

  /// The position of the Profil tab.
  static const _profileTab = 2;

  void _openTab(BuildContext context, int index) {
    // Opening Profil loads the account again, so that an admin's change (a
    // new role, a suspension) shows without restarting the app.
    final account = context.read<AccountViewModel>();
    if (index == _profileTab && account.isAvailable) account.refresh();
    // Tapping the tab that is already open goes back to its first page.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final l10n = context.l10n;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _openTab(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map),
                  label: Text(l10n.tabExplore),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.chat_bubble_outline),
                  selectedIcon: const Icon(Icons.chat_bubble),
                  label: Text(l10n.tabAssistant),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: Text(l10n.tabProfile),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _openTab(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.tabExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.tabAssistant,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
