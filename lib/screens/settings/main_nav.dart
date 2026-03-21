import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../shield/shield_screen.dart';
import '../cycle/cycle_screen.dart';
import '../energy/energy_screen.dart';
import '../journal/journal_screen.dart';
import '../companion/companion_screen.dart';
import '../companion/companion_screen.dart';
import '../points/points_screen.dart';
import 'settings_screen.dart';

class MainNav extends ConsumerStatefulWidget {
  const MainNav({super.key});

  @override
  ConsumerState<MainNav> createState() => _MainNavState();
}

class _MainNavState extends ConsumerState<MainNav> {
  int _index = 0;

  // ── 5 bottom nav items — Journal replaces Sakhi ───────────────────────────
  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,       label: 'Home'),
    _NavItem(icon: Icons.shield_outlined,     activeIcon: Icons.shield_rounded,     label: 'Shield'),
    _NavItem(icon: Icons.water_drop_outlined, activeIcon: Icons.water_drop_rounded, label: 'Cycle'),
    _NavItem(icon: Icons.book_outlined,       activeIcon: Icons.book_rounded,       label: 'Journal'),
    _NavItem(icon: Icons.bolt_outlined,       activeIcon: Icons.bolt_rounded,       label: 'Energy'),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    ShieldScreen(),
    CycleScreen(),
    JournalScreen(),
    EnergyScreen(),
  ];

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const _ChatOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final initial  = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';

    return Scaffold(
      drawer: _SideDrawer(initial: initial, userName: userName),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),

          // ── Floating menu button (top left) ──────────────────────────────
          Positioned(
            top:  MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Builder(
              builder: (ctx) => Material(
                color:       Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color:        SakhiColors.deep.withOpacity(0.85),
                      shape:        BoxShape.circle,
                      border:       Border.all(
                          color: SakhiColors.gold.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.menu_rounded,
                        color: SakhiColors.gold, size: 18),
                  ),
                ),
              ),
            ),
          ),

          // ── Floating Sakhi chat button (bottom right) ─────────────────────
          Positioned(
            bottom: 76, // sits above the nav bar
            right:  16,
            child: Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => _openChat(ctx),
                child: Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: [SakhiColors.drose, SakhiColors.rose],
                    ),
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color:        SakhiColors.rose.withOpacity(0.55),
                        blurRadius:   18,
                        spreadRadius: 2,
                        offset:       const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('S',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom nav ────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SakhiColors.deep,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -1)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _index;
                final item     = _items[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? SakhiColors.rose.withOpacity(0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected
                                  ? SakhiColors.gold
                                  : const Color(0xFF9A7090),
                              size: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(item.label,
                            style: TextStyle(
                              fontSize:   10,
                              fontWeight: selected
                                  ? FontWeight.w700 : FontWeight.w400,
                              color: selected
                                  ? SakhiColors.gold
                                  : const Color(0xFF9A7090),
                            )),
                      ],
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

// ── Chat overlay (full screen modal) ─────────────────────────────────────────
class _ChatOverlay extends StatelessWidget {
  const _ChatOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color:        SakhiColors.vblush,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle + header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            decoration: const BoxDecoration(
              color:        SakhiColors.deep,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:  SakhiColors.rose.withOpacity(0.3),
                    shape:  BoxShape.circle,
                    border: Border.all(color: SakhiColors.gold.withOpacity(0.4)),
                  ),
                  child: const Center(
                      child: Text('S', style: TextStyle(
                          color: SakhiColors.gold,
                          fontSize: 14, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sakhi',
                          style: TextStyle(color: Colors.white,
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Your AI companion',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Full companion screen content (minus its own app bar)
          const Expanded(child: CompanionBody()),
        ],
      ),
    );
  }
}

// ── Side drawer ───────────────────────────────────────────────────────────────
class _SideDrawer extends StatelessWidget {
  final String initial;
  final String userName;

  const _SideDrawer({required this.initial, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: SakhiColors.vblush,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user initial
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                  colors: [SakhiColors.deep, Color(0xFF5A1A40)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color:  SakhiColors.rose.withOpacity(0.3),
                      shape:  BoxShape.circle,
                      border: Border.all(
                          color: SakhiColors.gold.withOpacity(0.5)),
                    ),
                    child: Center(
                        child: Text(initial,
                            style: const TextStyle(
                                color:      SakhiColors.gold,
                                fontSize:   20,
                                fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(height: 12),
                  Text(userName.isNotEmpty ? userName : 'Sakhi',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const Text('Your AI companion',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Points
            _DrawerTile(
              icon:  Icons.star_outline_rounded,
              label: 'Resilience Points',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PointsScreen()));
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(color: SakhiColors.petal),
            ),

            _DrawerTile(
              icon:  Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: const Text('Sakhi v1.0.0',
                  style: TextStyle(fontSize: 11, color: SakhiColors.lgray)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:         Icon(icon, color: SakhiColors.rose, size: 22),
      title:           Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: SakhiColors.deep)),
      trailing:        const Icon(Icons.chevron_right,
          color: SakhiColors.lgray, size: 18),
      onTap:           onTap,
      shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      contentPadding:  const EdgeInsets.symmetric(
          horizontal: 16, vertical: 2),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}