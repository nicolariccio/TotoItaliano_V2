import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold persistente con bottom navigation a 5 sezioni. Ogni branch di
/// [StatefulShellRoute] mantiene il proprio stack di navigazione, cosi'
/// tornare su un tab non perde la posizione di scroll/navigazione.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_NavItem> _items = [
    _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home'),
    _NavItem(
        icon: Icons.sports_soccer_outlined,
        selectedIcon: Icons.sports_soccer_rounded,
        label: 'Pronostici'),
    _NavItem(
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events_rounded,
        label: 'Classifica'),
    _NavItem(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
        label: 'Leghe'),
    _NavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profilo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      // Sfondo sfocato dietro la nav bar (effetto "glass" delle app native
      // minimal), il colore semi-trasparente arriva dal navigationBarTheme.
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              for (final item in _items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(
      {required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
