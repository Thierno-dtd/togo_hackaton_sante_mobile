import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../services/app_provider.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/advice/presentation/pages/advice_page.dart';
import '../features/self_assessment/presentation/pages/self_assessment_page.dart';
import '../features/events/presentation/pages/events_page.dart';
import '../features/reminders/presentation/pages/reminders_page.dart';
import '../features/followup/presentation/pages/followup_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final int? initialReminderTab;

  const MainNavigation({super.key, this.initialIndex = 0, this.initialReminderTab,});

   static _MainNavigationState? _instance;
  static void goToTab(int index, {int? subTabIndex}) {
    _instance?._navigateTo(index, subTabIndex: subTabIndex);
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int? _reminderTab;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _reminderTab = widget.initialReminderTab;
    MainNavigation._instance = this;
  }

  @override
  void dispose() {
    if (MainNavigation._instance == this) {
      MainNavigation._instance = null;
    }
    super.dispose();
  }

  void _navigateTo(int index, {int? subTabIndex}) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _reminderTab = subTabIndex;
    });
  }

  List<_NavItem> _buildNavItems(bool isPatient) {
    return [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Accueil',
        page: const DashboardPage(),
      ),
      _NavItem(
        icon: Icons.lightbulb_outline,
        activeIcon: Icons.lightbulb_rounded,
        label: 'Conseils',
        page: const AdvicePage(),
      ),
      _NavItem(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded,
        label: 'Évaluation',
        page: const SelfAssessmentPage(),
      ),
      _NavItem(
        icon: Icons.event_outlined,
        activeIcon: Icons.event_rounded,
        label: 'Événements',
        page: const EventsPage(),
      ),
      _NavItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: 'Rappels',
        page: RemindersPage(
          key: ValueKey(_reminderTab),
          initialTab: _reminderTab ?? 0,
        ),
      ),
      if (isPatient)
        _NavItem(
          icon: Icons.monitor_heart_outlined,
          activeIcon: Icons.monitor_heart_rounded,
          label: 'Suivi',
          page: const FollowUpPage(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isPatient = provider.currentUser?.isPatient ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navItems = _buildNavItems(isPatient);

    // Clamp index when Follow-up tab disappears
    final safeIndex = _selectedIndex.clamp(0, navItems.length - 1);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: IndexedStack(
        index: safeIndex,
        children: navItems.map((e) => e.page).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GNav(
              selectedIndex: safeIndex,
              onTabChange: (index) =>
                  setState(() => _selectedIndex = index),
              gap: 4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textHint,
              activeColor: AppColors.white,
              tabBackgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 10),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tabs: navItems
                  .map((item) => GButton(
                        icon: item.icon,
                        text: item.label,
                        iconActiveColor: AppColors.white,
                        textStyle: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ))
                  .toList(),
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
  final String label;
  final Widget page;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}