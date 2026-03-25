import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../data/models/models.dart';
import '../../../../navigation/main_navigation.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _headerVisible   = false; 
  bool _metricsVisible  = false; 
  late PageController _pageController;
  int _currentIndex = 0;

  void _goToTab(BuildContext context, int index, {int? subTabIndex}) {
    MainNavigation.goToTab(index, subTabIndex: subTabIndex);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.currentUser == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      );
    }

    final user     = provider.currentUser!;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final age      = AppUtils.calculateAge(user.dateOfBirth);
    final unreadCount = provider.unreadNotificationsCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─ Hero App Bar ─
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
                          // ── Avatar + infos masquables ──
                          GestureDetector(
                            onTap: () => setState(() => _headerVisible = !_headerVisible),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: Text(
                                    user.initials,
                                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PrivacyText(
                                      text: 'Bonjour, ${user.firstName} 👋',
                                      visible: _headerVisible,
                                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                                      placeholder: 'Bonjour 👋',
                                    ),
                                    const SizedBox(height: 2),
                                    _PrivacyText(
                                      text: '$age ans • ${user.district}',
                                      visible: _headerVisible,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      placeholder: '••• ans • •••••',
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _headerVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          if (user.isPatient)
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
                                    icon: const Icon(Icons.notifications_outlined, size: 22, color: Colors.white),
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
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Center(
                                          child: Text(
                                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                            icon: const Icon(Icons.settings_outlined, size: 22, color: Colors.white),
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

                // ─ Patient metrics avec privacy ─
                if (user.isPatient) ...[
                  _buildPatientMetrics(context, provider, isDark),
                  const SizedBox(height: 24),
                ],

                // ─ Overdue reminders alert ─
                if (provider.overdueScreening.isNotEmpty) ...[
                  _buildOverdueAlert(context, provider),
                  const SizedBox(height: 24),
                ],

                // ─ Carrousel mixte (conseils + événements) ─
                _buildMixedCarousel(context, provider, isDark),
                const SizedBox(height: 24),

                // ─ Today reminders ─
                SectionHeader(
                  title: "📋 Rappels d'aujourd'hui",
                  actionLabel: 'Voir tout ›',
                  onAction: () => _goToTab(context, 4, subTabIndex: 2),
                ),
                const SizedBox(height: 12),
                _buildTodayReminders(context, provider, isDark),
                const SizedBox(height: 24),

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

  // ─── Patient metrics avec toggle privacy ───
  Widget _buildPatientMetrics(BuildContext context, AppProvider provider, bool isDark) {
    final diseaseType = provider.currentUser!.diseaseType ?? 'hypertension';
    final hasBoth     = diseaseType == 'both';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📊 Dernières mesures', style: TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColors.primary,
            )),
            const Spacer(),
            // Bouton toggle privacy mesures
            GestureDetector(
              onTap: () => setState(() => _metricsVisible = !_metricsVisible),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _metricsVisible
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.textHint.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _metricsVisible
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _metricsVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 13,
                      color: _metricsVisible ? AppColors.primary : AppColors.textHint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _metricsVisible ? 'Masquer' : 'Afficher',
                      style: AppTextStyles.caption.copyWith(
                        color: _metricsVisible ? AppColors.primary : AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if ((diseaseType == 'hypertension' || hasBoth) && provider.hypertensionRecords.isNotEmpty) ...[
          _buildHtaMetrics(provider, isDark),
          if (hasBoth) const SizedBox(height: 12),
        ],
        if ((diseaseType == 'diabetes' || hasBoth) && provider.diabetesRecords.isNotEmpty)
          _buildDiabeteMetrics(provider, isDark),
      ],
    );
  }

  Widget _buildHtaMetrics(AppProvider provider, bool isDark) {
    final latest = provider.hypertensionRecords.first;
    return Row(
      children: [
        Expanded(child: _PrivacyMetricCard(
          label: 'TENSION',
          value: '${latest.systolic.toInt()}/${latest.diastolic.toInt()}',
          unit: 'mmHg',
          status: AppUtils.bpStatus(latest.systolic, latest.diastolic),
          statusColor: AppUtils.bpColor(latest.systolic, latest.diastolic),
          icon: Icons.favorite,
          iconColor: AppColors.hypertension,
          visible: _metricsVisible,
        )),
        const SizedBox(width: 12),
        Expanded(child: _PrivacyMetricCard(
          label: 'FRÉQUENCE',
          value: latest.heartRate.toInt().toString(),
          unit: 'bpm',
          status: AppUtils.heartRateStatus(latest.heartRate),
          statusColor: AppUtils.heartRateColor(latest.heartRate),
          icon: Icons.monitor_heart,
          iconColor: AppColors.error,
          visible: _metricsVisible,
        )),
      ],
    );
  }

  Widget _buildDiabeteMetrics(AppProvider provider, bool isDark) {
    final latest = provider.diabetesRecords.first;
    return Row(
      children: [
        Expanded(child: _PrivacyMetricCard(
          label: 'GLYCÉMIE',
          value: latest.glucoseLevel.toStringAsFixed(2),
          unit: 'g/L',
          status: AppUtils.glucoseStatus(latest.glucoseLevel),
          statusColor: AppUtils.glucoseColor(latest.glucoseLevel),
          icon: Icons.water_drop,
          iconColor: AppColors.info,
          visible: _metricsVisible,
        )),
        const SizedBox(width: 12),
        Expanded(child: _PrivacyMetricCard(
          label: 'FRÉQUENCE',
          value: latest.heartRate.toInt().toString(),
          unit: 'bpm',
          status: AppUtils.heartRateStatus(latest.heartRate),
          statusColor: AppUtils.heartRateColor(latest.heartRate),
          icon: Icons.monitor_heart,
          iconColor: AppColors.error,
          visible: _metricsVisible,
        )),
      ],
    );
  }

  // ─── Carrousel mixte conseils + événements ───
  Widget _buildMixedCarousel(BuildContext context, AppProvider provider, bool isDark) {
    // Construire la liste mixte
    final List<_CarouselItem> items = [];

    // Ajouter les conseils du jour
    for (final advice in provider.dailyAdvice) {
      items.add(_CarouselItem(type: _CarouselType.advice, advice: advice));
    }

    // Ajouter les événements à venir (max 4)
    final now = DateTime.now();
    final upcomingEvents = provider.events
        .where((e) => e.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final event in upcomingEvents.take(4)) {
      items.add(_CarouselItem(type: _CarouselType.event, event: event));
    }

    // Mélanger (interleave) : conseil, événement, conseil, événement…
    final mixed = <_CarouselItem>[];
    final adviceItems = items.where((i) => i.type == _CarouselType.advice).toList();
    final eventItems  = items.where((i) => i.type == _CarouselType.event).toList();
    final maxLen = adviceItems.length > eventItems.length ? adviceItems.length : eventItems.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < adviceItems.length) mixed.add(adviceItems[i]);
      if (i < eventItems.length)  mixed.add(eventItems[i]);
    }

    if (mixed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '✨ Conseils & Événements',
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.primary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _goToTab(context, 1),
              child: Text(
                'Plus ›',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? const Color.fromARGB(255, 167, 163, 163) : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: mixed.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (_, i) {
              final item = mixed[i];
              if (item.type == _CarouselType.advice) {
                return _buildAdviceCarouselCard(context, item.advice!, isDark);
              } else {
                return _buildEventCarouselCard(context, item.event!, isDark);
              }
            },
          ),
        ),

        const SizedBox(height: 10),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(mixed.length, (index) {
    final isActive = index == _currentIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 6,
      height: isActive ? 10 : 6,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : AppColors.primary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }),
),
      ],
    );
  }

  Widget _buildAdviceCarouselCard(BuildContext context, AdviceModel advice, bool isDark) {
  return GestureDetector(
    onTap: () => _goToTab(context, 1),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: advice.color.withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(color: advice.color.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: advice.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_outline, color: advice.color, size: 18),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: advice.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Conseil', style: AppTextStyles.caption.copyWith(
                  color: advice.color, fontWeight: FontWeight.w700, fontSize: 13,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            advice.title,
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 15,
            ),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              advice.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4, fontSize: 12,
              ),
              maxLines: 3, overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: advice.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  advice.diseaseType == 'all' ? 'Général' :
                  advice.diseaseType == 'hypertension' ? 'HTA' : 'Diabète',
                  style: AppTextStyles.caption.copyWith(
                    color: advice.color, fontWeight: FontWeight.w600, fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textHint),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildEventCarouselCard(BuildContext context, EventModel event, bool isDark) {
  final catColor = _categoryColor(event.category);
  final now = DateTime.now();
  final daysLeft = event.date.difference(now).inDays;
  final isToday = daysLeft == 0;
  final hasImg = event.hasImage;

  return GestureDetector(
    onTap: () => _goToTab(context, 3),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: catColor.withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(color: catColor.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImg ? _eventCardWithImage(event, catColor, daysLeft, isToday) : _eventCardNoImage(event, catColor, daysLeft, isToday, isDark),
    ),
  );
}

Widget _eventCardWithImage(EventModel event, Color catColor, int daysLeft, bool isToday) {
  return Stack(
    children: [
      // Image background
      Positioned.fill(
        child: event.imageLocalPath != null
            ? Image.file(File(event.imageLocalPath!), fit: BoxFit.cover)
            : event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: catColor.withOpacity(0.15)),
                  )
                : Container(color: catColor.withOpacity(0.15)),
      ),
      // Gradient overlay
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.75)],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
      // Top color strip
      Positioned(top: 0, left: 0, right: 0, child: Container(height: 4, color: catColor)),
      // Content overlay
      Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _categoryLabel(event.category),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.warning.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isToday ? 'Auj.' : 'J-$daysLeft',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                event.title,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15,
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 10, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      event.location,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8), fontSize: 13,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.access_time, size: 10, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 3),
                  Text(
                    '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')} • ${AppUtils.formatDate(event.date)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8), fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _eventCardNoImage(EventModel event, Color catColor, int daysLeft, bool isToday, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(height: 4, color: catColor),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_categoryIcon(event.category), color: catColor, size: 16),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _categoryLabel(event.category),
                        style: AppTextStyles.caption.copyWith(
                          color: catColor, fontWeight: FontWeight.w700, fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.error.withOpacity(0.12)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isToday ? 'Auj.' : 'J-$daysLeft',
                      style: AppTextStyles.caption.copyWith(
                        color: isToday ? AppColors.error : AppColors.warning,
                        fontWeight: FontWeight.w700, fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                event.title,
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 15,
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(event.location,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.access_time, size: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')} • ${AppUtils.formatDate(event.date)}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (event.isRegistered)
                Row(children: [
                  Icon(Icons.check_circle, size: 11, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('Inscrit(e)', style: AppTextStyles.caption.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13,
                  )),
                ])
              else
                Row(children: [
                  Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('Voir détails', style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint, fontSize: 12,
                  )),
                ]),
            ],
          ),
        ),
      ),
    ],
  );
}

String _categoryLabel(String cat) {
  switch (cat) {
    case 'sport': return 'Sport & bien-être';
    case 'health': return 'Santé';
    case 'cleaning': return 'Salubrité';
    case 'awareness': return 'Sensibilisation';
    case 'campaign': return 'Campagne';
    default: return 'Événement';
  }
}
  // ─── Overdue alert ───
  Widget _buildOverdueAlert(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => _goToTab(context, 4),
      child: AppCard(
        color: AppColors.error.withOpacity(0.08),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
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
                  Text('Appuyez pour consulter vos dépistages', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  // ─── Today reminders ───
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
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.medication,
                            color: isDark ? AppColors.textHint : AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.medicationName, style: AppTextStyles.h4.copyWith(
                              color: isDark ? AppColors.white : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            )),
                            Text(
                              '${m.dosage} • ${m.intakeTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (m.needsRenewal)
                        const StatusBadge(label: 'Renouveler', color: AppColors.warning),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
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
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.label, style: AppTextStyles.h4.copyWith(
                              color: isDark ? AppColors.white : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            )),
                            Text(AppUtils.formatTime(r.time), style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // ─── Quick actions ───
  Widget _buildQuickActions(BuildContext context, UserModel user) {
    final actions = [
      if (user.isPatient) ...[
        _QuickAction(icon: Icons.add_chart, label: 'Mesure', color: AppColors.hypertension, onTap: () => _goToTab(context, 5)),
        _QuickAction(icon: Icons.history, label: 'Historique', color: const Color.fromARGB(255, 46, 85, 122), onTap: () => _goToTab(context, 5)),
      ],
      _QuickAction(icon: Icons.quiz, label: 'Bilan', color: AppColors.warning, onTap: () => _goToTab(context, 2)),
      _QuickAction(icon: Icons.event, label: 'Événements', color: AppColors.accent, onTap: () => _goToTab(context, 3)),
      _QuickAction(icon: Icons.alarm_add, label: 'Rappel', color: AppColors.info, onTap: () => _goToTab(context, 4)),
      if (!user.isPatient)
        _QuickAction(icon: Icons.medical_information, label: 'Patient', color: AppColors.success, onTap: () => Navigator.of(context).pushNamed('/settings')),
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
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
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
      case 'sport':     return AppColors.accent;
      case 'health':    return AppColors.hypertension;
      case 'cleaning':  return AppColors.info;
      case 'awareness': return AppColors.warning;
      case 'campaign':  return AppColors.primary;
      default:          return AppColors.textHint;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'sport':     return Icons.directions_run;
      case 'health':    return Icons.local_hospital;
      case 'cleaning':  return Icons.cleaning_services;
      case 'awareness': return Icons.campaign;
      case 'campaign':  return Icons.volunteer_activism;
      default:          return Icons.event;
    }
  }
}

// ════════════════════════════════════════════════════════════
// ─── Privacy Text Widget ───
// ════════════════════════════════════════════════════════════
class _PrivacyText extends StatelessWidget {
  final String text;
  final String placeholder;
  final bool visible;
  final TextStyle style;

  const _PrivacyText({
    required this.text,
    required this.placeholder,
    required this.visible,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        visible ? text : placeholder,
        key: ValueKey(visible),
        style: style,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Privacy Metric Card ───
// ════════════════════════════════════════════════════════════
class _PrivacyMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final bool visible;

  const _PrivacyMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: visible ? statusColor.withOpacity(0.3) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: visible ? statusColor.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: visible
                    ? Container(
                        key: const ValueKey('status_visible'),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('status_hidden'),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline, size: 10, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '• • •',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: visible
                ? Row(
                    key: const ValueKey('value_visible'),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.textPrimary,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          unit,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('value_hidden'),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '• • •',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textHint,
                          fontSize: 22,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Carousel Item Model ───
// ════════════════════════════════════════════════════════════
enum _CarouselType { advice, event }

class _CarouselItem {
  final _CarouselType type;
  final AdviceModel? advice;
  final EventModel? event;

  const _CarouselItem({required this.type, this.advice, this.event});
}

// ════════════════════════════════════════════════════════════
// ─── Quick Action Model ───
// ════════════════════════════════════════════════════════════
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