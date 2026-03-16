import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final events = provider.events;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: const Text('Événements communautaires'),
      ),
      body: events.isEmpty
          ? const EmptyState(icon: Icons.event, title: 'Aucun événement')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _buildEventCard(context, events[i], isDark, provider),
            ),
    );
  }

  Widget _buildEventCard(BuildContext ctx, EventModel event, bool dark, AppProvider provider) {
    final catColor = _categoryColor(event.category);
    final isUpcoming = event.date.isAfter(DateTime.now());
    final daysLeft = event.date.difference(DateTime.now()).inDays;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_categoryIcon(event.category), color: catColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(label: _categoryLabel(event.category), color: catColor),
                    const SizedBox(height: 4),
                    Text(event.title, style: AppTextStyles.h4, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isUpcoming && daysLeft <= 7)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeft == 0 ? "Aujourd'hui" : 'J-$daysLeft',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const AppDivider(),
          const SizedBox(height: 12),

          // Details
          Text(event.description, style: AppTextStyles.body.copyWith(
            color: dark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.5,
          ), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),

          // Info rows
          _infoChip(Icons.calendar_today, AppUtils.formatDate(event.date), dark),
          const SizedBox(height: 6),
          _infoChip(Icons.access_time, '${event.time.hour.toString().padLeft(2,'0')}:${event.time.minute.toString().padLeft(2,'0')}', dark),
          const SizedBox(height: 6),
          _infoChip(Icons.location_on_outlined, event.location, dark),
          const SizedBox(height: 6),
          _infoChip(Icons.group_outlined, event.organizer, dark),
          if (event.maxParticipants != null) ...[
            const SizedBox(height: 6),
            _infoChip(Icons.people, '${event.maxParticipants} places maximum', dark),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: event.isRegistered ? AppColors.success : catColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => provider.toggleEventRegistration(event.id),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(event.isRegistered ? Icons.check_circle : Icons.add_circle_outline,
                    size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    event.isRegistered ? 'Inscrit(e)' : 'Je participe',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool dark) {
    return Row(
      children: [
        Icon(icon, size: 15, color: dark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
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
}