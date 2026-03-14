import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/ui_helpers.dart';
import 'inbox_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'today_page.dart';
import 'upcoming_page.dart';
import 'archive_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // 0=Inbox, 1=Kalender, 2=Profil

  static const List<Widget> _pages = [
    InboxPage(),
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<TaskProvider>().loadTasks();
      if (!mounted) return;
      await context.read<ProfileProvider>().loadProfile();
    });
  }

  void _onNavTap(int index) {
    if (index == 2) {
      hapticLight();
      _openMoreSheet();
      return;
    }
    final pageIdx = index < 2 ? index : index - 1;
    if (pageIdx != _currentIndex) {
      hapticSelect();
      setState(() => _currentIndex = pageIdx);
    }
  }

  int get _navBarIndex => _currentIndex < 2 ? _currentIndex : _currentIndex + 1;

  void _openMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,        // tap luar = tutup
      enableDrag: true,           // drag ke bawah = tutup
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const _MoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = context
        .watch<TaskProvider>()
        .todayTasks
        .where((t) => !t.completed)
        .length;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navBarIndex,
        onDestinationSelected: _onNavTap,
        animationDuration: const Duration(milliseconds: 200),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: _BadgeIcon(
                count: todayCount, child: const Icon(Icons.grid_view_outlined)),
            selectedIcon: _BadgeIcon(
                count: todayCount,
                child: const Icon(Icons.grid_view_rounded)),
            label: 'Lainnya',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final int count;
  final Widget child;
  const _BadgeIcon({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -7,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xff111827)
                    : Colors.white,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TaskProvider>();
    final todayCount = provider.todayTasks.where((t) => !t.completed).length;
    final upcomingCount = provider.upcomingTasks.where((t) => !t.completed).length;
    final archivedCount = provider.archivedTasks.length;

    void go(Widget page) {
      Navigator.pop(context);
      Navigator.push(context, smoothRoute(page));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.44,
      minChildSize: 0.01,   // bisa drag sampai hampir hilang
      maxChildSize: 0.68,
      snap: true,            // snap ke posisi terdekat
      snapSizes: const [0.44, 0.68],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Text(
                  'Menu Lainnya',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 24, endIndent: 24),
              const SizedBox(height: 4),
              _SheetTile(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xff3b82f6),
                label: 'Hari Ini',
                subtitle: 'Tugas dengan deadline hari ini',
                badge: todayCount,
                badgeColor: Colors.red,
                onTap: () => go(const TodayPage()),
              ),
              _SheetTile(
                icon: Icons.rocket_launch_rounded,
                iconColor: const Color(0xfff97316),
                label: 'Mendatang',
                subtitle: 'Tugas yang akan datang',
                badge: upcomingCount,
                badgeColor: const Color(0xfff97316),
                onTap: () => go(const UpcomingPage()),
              ),
              _SheetTile(
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xffa855f7),
                label: 'Arsip',
                subtitle: 'Tugas yang telah diarsipkan',
                badge: archivedCount,
                badgeColor: Colors.grey,
                onTap: () => go(const ArchivePage()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final int badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        hapticLight();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600)),
                ],
              ),
            ),
            if (badge > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
