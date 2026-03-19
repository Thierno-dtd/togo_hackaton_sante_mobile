import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../data/models/models.dart';
import '../../../../navigation/main_navigation.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // ── Helper navigation vers un onglet ──
  void _goToTab(BuildContext context, int index, {int? subTabIndex}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigation(initialIndex: index, initialReminderTab: subTabIndex),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Garde-fou logout
    if (provider.currentUser == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
      );
    }

    final user = provider.currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = AppUtils.calculateAge(user.dateOfBirth);
    final unreadCount = provider.unreadNotificationsCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─ Hero App Bar — ta version originale conservée ─
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF1E4060)],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(user.initials,
                                style: AppTextStyles.h4.copyWith(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bonjour, ${user.firstName} 👋',
                                    style: AppTextStyles.h3.copyWith(color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('$age ans • ${user.district}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                          ),
                          if(user.isPatient)
                          Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                                  icon: const Icon(Icons.notifications_outlined,
                                      size: 22, color: Colors.white),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                          minWidth: 16, minHeight: 16),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 1),
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                            icon: const Icon(Icons.settings_outlined,
                                size: 22, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (user.isPatient && user.diseaseType != null)
                        DiseaseTag(diseaseType: user.diseaseType!),
                      const SizedBox(height: 11),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ─ Patient metrics ─
                if (user.isPatient) ...[
                  _buildPatientMetrics(context, provider, isDark),
                  const SizedBox(height: 24),
                ],

                // ─ Overdue reminders alert ─
                if (provider.overdueScreening.isNotEmpty) ...[
                  _buildOverdueAlert(context, provider),
                  const SizedBox(height: 24),
                ],

                // ─ Daily advice ─
                SectionHeader(
                  title: '💡 Conseils du jour',
                  actionLabel: 'Voir tout ›',
                  onAction: () => _goToTab(context, 1),
                ),
                const SizedBox(height: 12),
                ...provider.dailyAdvice.map((a) => _buildAdviceCard(context, a, isDark)),
                const SizedBox(height: 24),

                // ─ Today reminders ─
                SectionHeader(
                  title: "📋 Rappels d'aujourd'hui",
                  actionLabel: 'Voir tout ›',
                  onAction: () => _goToTab(context, 4),
                ),
                const SizedBox(height: 12),
                _buildTodayReminders(context, provider, isDark),
                const SizedBox(height: 24),

                // ─ Upcoming events ≤ J+3 ─
                _buildUpcomingEvents(context, provider, isDark),

                // ─ Quick actions ─
                const SectionHeader(title: '⚡ Actions rapides'),
                const SizedBox(height: 12),
                _buildQuickActions(context, user),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Patient metrics — ta version originale ───
  Widget _buildPatientMetrics(BuildContext context, AppProvider provider, bool isDark) {
    final isHypertension = provider.currentUser!.diseaseType == 'hypertension';

    if (isHypertension && provider.hypertensionRecords.isNotEmpty) {
      final latest = provider.hypertensionRecords.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: ' Dernières mesures'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'TENSION',
                  value: '${latest.systolic.toInt()}/${latest.diastolic.toInt()}',
                  unit: 'mmHg',
                  status: AppUtils.bpStatus(latest.systolic, latest.diastolic),
                  statusColor: AppUtils.bpColor(latest.systolic, latest.diastolic),
                  icon: Icons.favorite,
                  iconColor: AppColors.hypertension,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'FRÉQUENCE',
                  value: latest.heartRate.toInt().toString(),
                  unit: 'bpm',
                  status: AppUtils.heartRateStatus(latest.heartRate),
                  statusColor: AppUtils.heartRateColor(latest.heartRate),
                  icon: Icons.monitor_heart,
                  iconColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(
            label: 'TEMPÉRATURE',
            value: latest.temperature.toStringAsFixed(1),
            unit: '°C',
            status: AppUtils.temperatureStatus(latest.temperature),
            statusColor: AppUtils.temperatureColor(latest.temperature),
            icon: Icons.thermostat,
            iconColor: AppColors.warning,
          ),
        ],
      );
    }

    if (!isHypertension && provider.diabetesRecords.isNotEmpty) {
      final latest = provider.diabetesRecords.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '📊 Dernières mesures'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'GLYCÉMIE',
                  value: latest.glucoseLevel.toStringAsFixed(2),
                  unit: 'g/L',
                  status: AppUtils.glucoseStatus(latest.glucoseLevel),
                  statusColor: AppUtils.glucoseColor(latest.glucoseLevel),
                  icon: Icons.water_drop,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'FRÉQUENCE',
                  value: latest.heartRate.toInt().toString(),
                  unit: 'bpm',
                  status: AppUtils.heartRateStatus(latest.heartRate),
                  statusColor: AppUtils.heartRateColor(latest.heartRate),
                  icon: Icons.monitor_heart,
                  iconColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(
            label: 'TEMPÉRATURE',
            value: latest.temperature.toStringAsFixed(1),
            unit: '°C',
            status: AppUtils.temperatureStatus(latest.temperature),
            statusColor: AppUtils.temperatureColor(latest.temperature),
            icon: Icons.thermostat,
            iconColor: AppColors.warning,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Overdue alert — cliquable ───
  Widget _buildOverdueAlert(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => _goToTab(context, 4),
      child: AppCard(
        color: AppColors.error.withOpacity(0.08),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.overdueScreening.length} rappel(s) en retard',
                    style: AppTextStyles.h4.copyWith(color: AppColors.error),
                  ),
                  Text('Appuyez pour consulter vos dépistages',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  // ─── Advice card — cliquable avec icône › ───
  Widget _buildAdviceCard(BuildContext context, AdviceModel advice, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _goToTab(context, 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: advice.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.lightbulb_outline, color: advice.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(advice.title, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(
                    advice.content,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(
                    label: advice.diseaseType == 'all'
                        ? 'Général'
                        : advice.diseaseType == 'hypertension'
                            ? 'Hypertension'
                            : 'Diabète',
                    color: advice.color,
                  ),
                ],
              ),
            ),
            // ── Icône › ──
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // ─── Today reminders — cliquables ───
  Widget _buildTodayReminders(BuildContext context, AppProvider provider, bool isDark) {
    final todayMeds = provider.medicationReminders.where((m) => m.isActive).toList();
    final todaySimple = provider.simpleReminders.where(
      (r) => !r.isCompleted && r.date.day == DateTime.now().day,
    ).toList();

    if (todayMeds.isEmpty && todaySimple.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Text("Aucun rappel pour aujourd'hui", style: AppTextStyles.body),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...todayMeds.take(2).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _goToTab(context, 4, subTabIndex: 1),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.medicationName, style: AppTextStyles.h4),
                            Text(
                              '${m.dosage} • ${m.intakeTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (m.needsRenewal)
                        const StatusBadge(
                            label: 'Renouveler', color: AppColors.warning),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            )),
        ...todaySimple.take(2).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _goToTab(context, 4, subTabIndex: 2),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.label, style: AppTextStyles.h4),
                            Text(AppUtils.formatTime(r.time),
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // ─── Upcoming events ≤ J+3 ───
  Widget _buildUpcomingEvents(BuildContext context, AppProvider provider, bool isDark) {
    final now = DateTime.now();
    final upcoming = provider.events
        .where((e) =>
            e.date.isAfter(now) && e.date.difference(now).inDays <= 3)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '📅 Événements à venir',
          actionLabel: 'Voir tout ›',
          onAction: () => _goToTab(context, 3),
        ),
        const SizedBox(height: 12),
        ...upcoming.map((event) {
          final daysLeft = event.date.difference(now).inDays;
          final catColor = _categoryColor(event.category);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _goToTab(context, 3),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon(event.category),
                          color: catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: AppTextStyles.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: daysLeft == 0
                            ? AppColors.error.withOpacity(0.12)
                            : AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft == 0 ? "Auj." : 'J-$daysLeft',
                        style: AppTextStyles.caption.copyWith(
                          color: daysLeft == 0
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Quick actions — ta structure avec onTap ───
  Widget _buildQuickActions(BuildContext context, UserModel user) {
    final actions = [
      if (user.isPatient) ...[
        _QuickAction(
          icon: Icons.add_chart,
          label: 'Mesure',
          color: AppColors.hypertension,
          onTap: () => _goToTab(context, 5),
        ),
        _QuickAction(
          icon: Icons.history,
          label: 'Historique',
          color: AppColors.primary,
          onTap: () => _goToTab(context, 5),
        ),
      ],
      _QuickAction(
        icon: Icons.quiz,
        label: 'Bilan',
        color: AppColors.warning,
        onTap: () => _goToTab(context, 2),
      ),
      _QuickAction(
        icon: Icons.event,
        label: 'Événements',
        color: AppColors.accent,
        onTap: () => _goToTab(context, 3),
      ),
      _QuickAction(
        icon: Icons.alarm_add,
        label: 'Rappel',
        color: AppColors.info,
        onTap: () => _goToTab(context, 4),
      ),
      if (!user.isPatient)
        _QuickAction(
          icon: Icons.medical_information,
          label: 'Patient',
          color: AppColors.success,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) => _buildQuickActionItem(context, a)).toList(),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, _QuickAction action) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'sport': return AppColors.accent;
      case 'health': return AppColors.hypertension;
      case 'cleaning': return AppColors.info;
      case 'awareness': return AppColors.warning;
      case 'campaign': return AppColors.primary;
      default: return AppColors.textHint;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'sport': return Icons.directions_run;
      case 'health': return Icons.local_hospital;
      case 'cleaning': return Icons.cleaning_services;
      case 'awareness': return Icons.campaign;
      case 'campaign': return Icons.volunteer_activism;
      default: return Icons.event;
    }
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}