import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../shield/shield_screen.dart';
import '../cycle/cycle_screen.dart';
import '../companion/companion_screen.dart';
import '../journal/journal_screen.dart';
import '../points/points_screen.dart';
import '../energy/energy_screen.dart';
import 'settings_screen.dart';

class MainNav extends ConsumerStatefulWidget {
  const MainNav({super.key});

  @override
  ConsumerState<MainNav> createState() => _MainNavState();
}

class _MainNavState extends ConsumerState<MainNav> {
  int _index = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        label: 'Home'),
    _NavItem(icon: Icons.shield_outlined,       activeIcon: Icons.shield_rounded,      label: 'Shield'),
    _NavItem(icon: Icons.water_drop_outlined,   activeIcon: Icons.water_drop_rounded,  label: 'Cycle'),
    _NavItem(icon: Icons.chat_bubble_outline,   activeIcon: Icons.chat_bubble_rounded, label: 'Sakhi'),
    _NavItem(icon: Icons.bolt_outlined,         activeIcon: Icons.bolt_rounded,        label: 'Energy'),
    _NavItem(icon: Icons.book_outlined,         activeIcon: Icons.book_rounded,        label: 'Journal'),
    _NavItem(icon: Icons.star_outline_rounded,  activeIcon: Icons.star_rounded,        label: 'Points'),
    _NavItem(icon: Icons.settings_outlined,     activeIcon: Icons.settings_rounded,    label: 'Settings'),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    ShieldScreen(),
    CycleScreen(),
    CompanionScreen(),
    EnergyScreen(),
    JournalScreen(),
    PointsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SakhiColors.deep,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item     = _items[i];
                final selected = i == _index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? SakhiColors.rose.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Shield gets special icon
                          i == 1
                              ? Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color:  selected ? SakhiColors.rose : const Color(0xFF5A1A40),
                                shape:  BoxShape.circle,
                              ),
                              child: Icon(Icons.shield_rounded,
                                  color: selected ? Colors.white : const Color(0xFF9A7090),
                                  size: 13))
                              : Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected ? SakhiColors.gold : const Color(0xFF9A7090),
                              size: 20),
                          const SizedBox(height: 2),
                          Text(item.label,
                            style: TextStyle(
                              fontSize:   8,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              color:      selected ? SakhiColors.gold : const Color(0xFF9A7090),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}