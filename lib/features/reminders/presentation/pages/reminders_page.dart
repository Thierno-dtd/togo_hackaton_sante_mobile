import 'package:flutter/material.dart';
import 'medication_tab.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/app_appbar.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});
  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _tabCtrl = TabController(length: provider.isPatient ? 3 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPatient = provider.isPatient;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppAppBar(
        title: const Text('Rappels'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Dépistages'),
            if (isPatient) ...[
              const Tab(text: 'Médicaments'),
              const Tab(text: 'Simples'),
            ],
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ScreeningTab(),
          if (isPatient) ...[
            const MedicationTab(),
            _SimpleReminderTab(),
          ],
        ],
      ),
    );
  }
}

// ─── Screening Tab ───
class _ScreeningTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reminders = provider.screeningReminders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return reminders.isEmpty
        ? const EmptyState(icon: Icons.medical_services_outlined, title: 'Aucun dépistage programmé')
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = reminders[i];
              final isOverdue = !r.isCompleted && r.dueDate.isBefore(DateTime.now());
              final daysLeft = r.dueDate.difference(DateTime.now()).inDays;

              return AppCard(
                border: isOverdue
                    ? Border.all(color: AppColors.error.withOpacity(0.4))
                    : r.isCompleted
                        ? Border.all(color: AppColors.success.withOpacity(0.3))
                        : Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => provider.toggleScreeningReminder(r.id),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: r.isCompleted ? AppColors.success : Colors.transparent,
                          border: Border.all(
                            color: r.isCompleted ? AppColors.success : (isOverdue ? AppColors.error : AppColors.border),
                            width: 2,
                          ),
                        ),
                        child: r.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: AppTextStyles.h4.copyWith(
                            decoration: r.isCompleted ? TextDecoration.lineThrough : null,
                            color: r.isCompleted ? AppColors.textHint : null,
                          )),
                          const SizedBox(height: 4),
                          Text(r.description, style: AppTextStyles.bodySmall),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: isOverdue ? AppColors.error : AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(AppUtils.formatDate(r.dueDate), style: AppTextStyles.caption.copyWith(
                                color: isOverdue ? AppColors.error : null,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!r.isCompleted)
                      StatusBadge(
                        label: isOverdue ? 'En retard' : daysLeft <= 7 ? 'Bientôt' : 'Planifié',
                        color: isOverdue ? AppColors.error : daysLeft <= 7 ? AppColors.warning : AppColors.accent,
                      ),
                  ],
                ),
              );
            },
          );
  }
}

// ─── Simple Reminders Tab ───
class _SimpleReminderTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reminders = provider.simpleReminders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: reminders.isEmpty
              ? const EmptyState(icon: Icons.alarm, title: 'Aucun rappel')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = reminders[i];
                    return Dismissible(
                      key: Key(r.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error, borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => provider.deleteSimpleReminder(r.id),
                      child: AppCard(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => provider.toggleSimpleReminder(r.id),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: r.isCompleted ? AppColors.accent : Colors.transparent,
                                  border: Border.all(
                                    color: r.isCompleted ? AppColors.accent : AppColors.border, width: 2,
                                  ),
                                ),
                                child: r.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.label, style: AppTextStyles.h4.copyWith(
                                    decoration: r.isCompleted ? TextDecoration.lineThrough : null,
                                    color: r.isCompleted ? AppColors.textHint : null,
                                  )),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                                      const SizedBox(width: 4),
                                      Text('${AppUtils.formatDate(r.date)} à ${AppUtils.formatTime(r.time)}',
                                        style: AppTextStyles.caption),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.swipe_left, size: 16, color: AppColors.textHint),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
          child: PrimaryButton(
            label: 'Ajouter un rappel',
            onPressed: () => _showAddSheet(context),
            icon: Icons.alarm_add,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddSimpleReminderSheet(outerContext: ctx),
    );
  }
}

// ─── Add Medication Sheet ───

// ─── Add Simple Reminder Sheet ───
class _AddSimpleReminderSheet extends StatefulWidget {
  final BuildContext outerContext;
  const _AddSimpleReminderSheet({required this.outerContext});

  @override
  State<_AddSimpleReminderSheet> createState() => _AddSimpleReminderSheetState();
}

class _AddSimpleReminderSheetState extends State<_AddSimpleReminderSheet> {
  final _labelCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  void _save() {
    if (_labelCtrl.text.isEmpty) return;
    final rem = SimpleReminder(
      id: const Uuid().v4(), label: _labelCtrl.text.trim(),
      date: _date, time: _time,
    );
    widget.outerContext.read<AppProvider>().addSimpleReminder(rem);
    AppUtils.showSnackBar(widget.outerContext, 'Rappel ajouté');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _sheetHandle(isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.alarm_add, color: AppColors.accent),
                const SizedBox(width: 10),
                Text('Nouveau rappel', style: AppTextStyles.h4),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
          ),
          const AppDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(controller: _labelCtrl,
                    decoration: const InputDecoration(labelText: 'Libellé du rappel', prefixIcon: Icon(Icons.label_outline, size: 20))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _date,
                            firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (d != null) setState(() => _date = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(AppUtils.formatDate(_date), style: AppTextStyles.body),
                          ]),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: _time);
                          if (t != null) setState(() => _time = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(AppUtils.formatTime(_time), style: AppTextStyles.body),
                          ]),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Enregistrer le rappel', onPressed: _save, icon: Icons.save_outlined, color: AppColors.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sheetHandle(bool isDark) {
  return Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBorder : AppColors.border, borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}