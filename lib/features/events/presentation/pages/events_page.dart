import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/app_appbar.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final events = provider.events;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppAppBar(title: const Text('Événements'), ispatient: provider.currentUser?.isPatient ?? false,),
      body: events.isEmpty
          ? const EmptyState(icon: Icons.event, title: 'Aucun événement')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) =>
                  _buildEventCard(context, events[i], isDark, provider),
            ),
    );
  }

  Widget _buildEventCard(
      BuildContext ctx, EventModel event, bool dark, AppProvider provider) {
    final catColor = _categoryColor(event.category);
    final isUpcoming = event.date.isAfter(DateTime.now());
    final daysLeft = event.date.difference(DateTime.now()).inDays;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image (si disponible) ──
          if (event.hasImage) _buildImage(event),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!event.hasImage)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_categoryIcon(event.category),
                            color: catColor, size: 24),
                      ),
                    if (!event.hasImage) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusBadge(
                                  label: _categoryLabel(event.category),
                                  color: catColor),
                              const Spacer(),
                              if (isUpcoming && daysLeft <= 7)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    daysLeft == 0
                                        ? "Aujourd'hui"
                                        : 'J-$daysLeft',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // ── Titre avec couleur dark mode (ta version) ──
                          Text(
                            event.title,
                            style: AppTextStyles.h4.copyWith(
                                color: dark
                                    ? AppColors.white
                                    : Colors.black),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const AppDivider(),
                const SizedBox(height: 12),

                // ── Description (si disponible) ──
                if (event.hasDescription) ...[
                  _ExpandableDescription(
                      description: event.description!, dark: dark),
                  const SizedBox(height: 14),
                ],

                // ── Infos ──
                _infoChip(Icons.calendar_today,
                    AppUtils.formatDate(event.date), dark),
                const SizedBox(height: 6),
                _infoChip(
                    Icons.access_time,
                    '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}',
                    dark),
                const SizedBox(height: 6),
                _infoChip(
                    Icons.location_on_outlined, event.location, dark),
                const SizedBox(height: 6),
                _infoChip(Icons.group_outlined, event.organizer, dark),
                if (event.maxParticipants != null) ...[
                  const SizedBox(height: 6),
                  _infoChip(Icons.people,
                      '${event.maxParticipants} places maximum', dark),
                ],

                const SizedBox(height: 16),

                // ── Bouton inscription ──
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          event.isRegistered ? AppColors.success : catColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () =>
                        provider.toggleEventRegistration(event.id),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            event.isRegistered
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            size: 18,
                            color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          event.isRegistered ? 'Inscrit(e)' : 'Je participe',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Image de l'événement ──
  Widget _buildImage(EventModel event) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showFullImage(context, event),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _imageWidget(event),
          ),
        ),
      ),
    );
  }

  Widget _imageWidget(EventModel event) {
    if (event.imageLocalPath != null) {
      return Image.file(
        File(event.imageLocalPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(event),
      );
    }
    if (event.imageUrl != null) {
      return Image.network(
        event.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.border,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imagePlaceholder(event),
      );
    }
    return _imagePlaceholder(event);
  }

  Widget _imagePlaceholder(EventModel event) {
    final color = _categoryColor(event.category);
    return Container(
      color: color.withOpacity(0.08),
      child: Center(
        child: Icon(_categoryIcon(event.category),
            size: 48, color: color.withOpacity(0.4)),
      ),
    );
  }

  void _showFullImage(BuildContext context, EventModel event) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullImageView(event: event),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool dark) {
    return Row(
      children: [
        Icon(icon,
            size: 15,
            color: dark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'sport':
        return AppColors.accent;
      case 'health':
        return AppColors.hypertension;
      case 'cleaning':
        return AppColors.info;
      case 'awareness':
        return AppColors.warning;
      case 'campaign':
        return AppColors.primary;
      default:
        return AppColors.textHint;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'sport':
        return Icons.directions_run;
      case 'health':
        return Icons.local_hospital;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'awareness':
        return Icons.campaign;
      case 'campaign':
        return Icons.volunteer_activism;
      default:
        return Icons.event;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'sport':
        return 'Sport & bien-être';
      case 'health':
        return 'Santé';
      case 'cleaning':
        return 'Salubrité';
      case 'awareness':
        return 'Sensibilisation';
      case 'campaign':
        return 'Campagne';
      default:
        return 'Événement';
    }
  }
}

// ════════════════════════════════════════════════════════════
// ─── Description avec "Voir plus / Voir moins" ───
// ════════════════════════════════════════════════════════════

class _ExpandableDescription extends StatefulWidget {
  final String description;
  final bool dark;

  const _ExpandableDescription(
      {required this.description, required this.dark});

  @override
  State<_ExpandableDescription> createState() =>
      _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.description,
            style: AppTextStyles.body.copyWith(
              color: widget.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
           
          ),
          secondChild: Text(
            widget.description,
            style: AppTextStyles.body.copyWith(
              color: widget.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        // Bouton voir plus / moins — uniquement si le texte est long
        if (_isLong())
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Voir moins' : 'Voir plus',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _isLong() {
    // Estimation : plus de ~150 caractères → potentiellement plus de 3 lignes
    return widget.description.length > 150;
  }
}

// ════════════════════════════════════════════════════════════
// ─── Vue plein écran de l'image ───
// ════════════════════════════════════════════════════════════

class _FullImageView extends StatelessWidget {
  final EventModel event;
  const _FullImageView({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Fond noir semi-transparent
            Container(color: Colors.black87),

            // Image centrée
            Center(
              child: Hero(
                tag: 'event_image_${event.id}',
                child: InteractiveViewer(
                  child: event.imageLocalPath != null
                      ? Image.file(File(event.imageLocalPath!))
                      : event.imageUrl != null
                          ? Image.network(event.imageUrl!)
                          : const SizedBox.shrink(),
                ),
              ),
            ),

            // Bouton fermer
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),

            // Titre en bas
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.title,
                  style: AppTextStyles.body
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}