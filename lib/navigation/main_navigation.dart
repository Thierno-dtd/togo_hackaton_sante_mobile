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

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.initialReminderTab,
  });

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

    // Vérifier si un dialog de bienvenue post-validation doit s'afficher
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkValidationWelcome();
    });
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

  /// Affiche le dialog de bienvenue si le flag est positionné dans le provider.
  void _checkValidationWelcome() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (!provider.pendingValidationWelcome) return;

    // Consommer le flag immédiatement pour éviter tout double affichage
    provider.consumeValidationWelcome();

    _showValidationWelcomeDialog();
  }

  void _showValidationWelcomeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône animée
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Demande validée ! 🎉',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Votre demande patient a été acceptée par votre médecin.',
                style: AppTextStyles.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Étape à faire
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complétez votre profil',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Définissez votre localisation, poids et taille dans les Paramètres.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bouton → Paramètres
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // fermer le dialog
                    Navigator.pushNamed(context, '/settings');
                  },
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(
                    'Aller dans les Paramètres',
                    style:
                        AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Lien "Plus tard"
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Plus tard',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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