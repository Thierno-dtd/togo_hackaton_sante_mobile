import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class MedicationTab extends StatelessWidget {
  const MedicationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final prescriptions = provider.prescriptions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Statistiques
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.accent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _buildStatItem(
                icon: Icons.description,
                label: 'Ordonnances',
                value: prescriptions.length.toString(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                icon: Icons.medication,
                label: 'Médicaments',
                value: provider.medicationReminders.length.toString(),
                color: AppColors.accent,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                icon: Icons.warning_amber,
                label: 'À renouveler',
                value: provider.medicationReminders
                    .where((m) => m.needsRenewal)
                    .length
                    .toString(),
                color: AppColors.warning,
              ),
            ],
          ),
        ),

        // Liste des ordonnances
        Expanded(
          child: prescriptions.isEmpty
              ? EmptyState(
                  icon: Icons.description,
                  title: 'Aucune ordonnance',
                  subtitle: 'Ajoutez votre première ordonnance',
                  action: ElevatedButton.icon(
                    onPressed: () => _showAddPrescriptionSheet(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: prescriptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _buildPrescriptionCard(
                    context,
                    prescriptions[i],
                    provider,
                    isDark,
                  ),
                ),
        ),

        // Bouton d'ajout
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: PrimaryButton(
            label: 'Ajouter une ordonnance',
            onPressed: () => _showAddPrescriptionSheet(context),
            icon: Icons.add,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    Prescription prescription,
    AppProvider provider,
    bool isDark,
  ) {
    final medications = provider.getMedicationsByPrescription(prescription.id);
    final hasRenewal = medications.any((m) => m.needsRenewal);

    return AppCard(
      border: hasRenewal
          ? Border.all(color: AppColors.warning.withOpacity(0.5), width: 1.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prescription.reference, style: AppTextStyles.h4),
                    Text('Dr. ${prescription.doctorName}', style: AppTextStyles.bodySmall),
                    Text(
                      AppUtils.formatDate(prescription.prescriptionDate),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (prescription.hasImage)
                IconButton(
                  onPressed: () => _showPrescriptionImage(context, prescription),
                  icon: const Icon(Icons.image, color: AppColors.accent),
                ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'add_med',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('Ajouter un médicament'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'add_med') {
                    _showAddMedicationSheet(context, prescription);
                  } else if (value == 'delete') {
                    _confirmDelete(context, provider, prescription);
                  }
                },
              ),
            ],
          ),

          if (medications.isNotEmpty) ...[
            const SizedBox(height: 12),
            const AppDivider(),
            const SizedBox(height: 12),

            // Liste des médicaments
            ...medications.asMap().entries.map((entry) {
              final isLast = entry.key == medications.length - 1;
              return _buildMedicationItem(
                context,
                entry.value,
                provider,
                isDark,
                isLast: isLast,
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showAddMedicationSheet(context, prescription),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un médicament'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(
    BuildContext context,
    MedicationReminder medication,
    AppProvider provider,
    bool isDark, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: medication.isActive
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.textHint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication,
                color: medication.isActive ? AppColors.accent : AppColors.textHint,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          medication.medicationName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: medication.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (medication.needsRenewal)
                        const StatusBadge(label: 'Renouveler', color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosage} • ${medication.intakeTimes.length}x/jour',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: medication.needsRenewal ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${medication.stock} • ${medication.daysRemaining}j restants',
                        style: AppTextStyles.caption.copyWith(
                          color: medication.needsRenewal ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showMedicationDetails(context, medication, provider),
              icon: const Icon(Icons.settings, size: 20),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showAddPrescriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPrescriptionSheet(outerContext: context),
    );
  }

  void _showAddMedicationSheet(BuildContext context, Prescription prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(
        outerContext: context,
        prescription: prescription,
      ),
    );
  }

  void _showMedicationDetails(
    BuildContext context,
    MedicationReminder medication,
    AppProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicationDetailsSheet(
        outerContext: context,
        medication: medication,
      ),
    );
  }

  void _showPrescriptionImage(BuildContext context, Prescription prescription) {
    AppUtils.showSnackBar(context, 'Affichage de l\'ordonnance');
  }

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    Prescription prescription,
  ) {
    final medications = provider.getMedicationsByPrescription(prescription.id);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'ordonnance'),
        content: Text(
          'Supprimer ${prescription.reference} et ses ${medications.length} médicament(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePrescription(prescription.id);
              Navigator.pop(context);
              AppUtils.showSnackBar(context, 'Ordonnance supprimée');
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}



class _AddMedicationSheet extends StatefulWidget {
  final BuildContext outerContext;
  const _AddMedicationSheet({required this.outerContext});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '7');
  List<TimeOfDay> _intakeTimes = [const TimeOfDay(hour: 7, minute: 30)];

  void _addTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (t != null) setState(() => _intakeTimes.add(t));
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _dosageCtrl.text.isEmpty) return;
    final med = MedicationReminder(
      id: const Uuid().v4(),
      medicationName: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      intakeTimes: _intakeTimes,
      stock: int.tryParse(_stockCtrl.text) ?? 30,
      renewalAlertThreshold: int.tryParse(_thresholdCtrl.text) ?? 7,
      diseaseType: widget.outerContext.read<AppProvider>().currentUser?.diseaseType ?? 'all',
    );
    widget.outerContext.read<AppProvider>().addMedicationReminder(med);
    AppUtils.showSnackBar(widget.outerContext, 'Médicament ajouté');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
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
                const Icon(Icons.medication, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('Nouveau médicament', style: AppTextStyles.h4),
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
                  TextField(controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du médicament', prefixIcon: Icon(Icons.medication, size: 20))),
                  const SizedBox(height: 14),
                  TextField(controller: _dosageCtrl,
                    decoration: const InputDecoration(labelText: 'Dosage (ex: 5mg)', prefixIcon: Icon(Icons.scale, size: 20))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _stockCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock actuel', prefixIcon: Icon(Icons.inventory, size: 20)))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _thresholdCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Alerte renouvellement', prefixIcon: Icon(Icons.notifications, size: 20)))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Horaires de prise', style: AppTextStyles.h4),
                  const SizedBox(height: 10),
                  ..._intakeTimes.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(AppUtils.formatTime(e.value), style: AppTextStyles.body),
                          ]),
                        )),
                        if (_intakeTimes.length > 1)
                          IconButton(
                            onPressed: () => setState(() => _intakeTimes.removeAt(e.key)),
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                          ),
                      ],
                    ),
                  )),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add_alarm, size: 18),
                    label: const Text('Ajouter une heure de prise'),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Enregistrer', onPressed: _save, icon: Icons.save_outlined),
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


