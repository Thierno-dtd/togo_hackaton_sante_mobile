import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
                 AppColors.textHint.withOpacity(0.1),
                AppColors.accent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _buildStatItem(
                icon: Icons.description,
                label: 'Ordonnances',
                value: prescriptions.length.toString(),
                color: isDark ? AppColors.white : AppColors.primary,
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
                  subtitle: 'Ajoutez votre première ordonnance pour gérer vos médicaments',
                  
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
            color: AppColors.accent,
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
              // Vignette image ou icône
              GestureDetector(
                onTap: prescription.hasImage
                    ? () => _showPrescriptionImage(context, prescription)
                    : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: prescription.hasImage
                        ? Colors.transparent
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textHint.withOpacity(0.2),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: prescription.imageLocalPath != null
                      ? Image.file(
                          File(prescription.imageLocalPath!),
                          fit: BoxFit.cover,
                        )
                      : prescription.imageUrl != null
                          ? Image.network(
                              prescription.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.description,
                                color: AppColors.textHint,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.description,
                              color: AppColors.textHint,
                              size: 28,
                            ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prescription.reference, style: AppTextStyles.h4.copyWith(
                      color: isDark ? AppColors.white : Colors.black,
                    )),
                    const SizedBox(height: 2),
                    Text(
                      'Dr. ${prescription.doctorName}',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (prescription.hospital != null)
                      Text(
                        prescription.hospital!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          AppUtils.formatDate(prescription.prescriptionDate),
                          style: AppTextStyles.caption,
                        ),
                        if (prescription.hasImage) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.image_outlined,
                              size: 11, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text('Photo',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'add_med',
                    child: Row(
                      children: [
                        Icon(Icons.medication, size: 20,
                            color: AppColors.accent),
                        SizedBox(width: 10),
                        Text('Ajouter un médicament'),
                      ],
                    ),
                  ),
                  if (prescription.hasImage)
                    const PopupMenuItem(
                      value: 'view_image',
                      child: Row(
                        children: [
                          Icon(Icons.image_search, size: 20,
                              color: AppColors.primary),
                          SizedBox(width: 10),
                          Text('Voir l\'ordonnance'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20,
                            color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Supprimer',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'add_med') {
                    _showAddMedicationSheet(context, prescription);
                  } else if (value == 'view_image') {
                    _showPrescriptionImage(context, prescription);
                  } else if (value == 'delete') {
                    _confirmDelete(context, provider, prescription);
                  }
                },
              ),
            ],
          ),

          if (medications.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.textHint.withOpacity(0.04) : AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.medication_outlined,
                      size: 14, color: AppColors.primary.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    '${medications.length} médicament${medications.length > 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.white : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasRenewal) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⚠ Renouvellement requis',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () => _showAddMedicationSheet(context, prescription),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Ajouter un médicament',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: medication.isActive
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.textHint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication,
                color: medication.isActive
                    ? AppColors.accent
                    : AppColors.textHint,
                size: 20,
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
                          '${medication.medicationName} ${medication.dosage}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: medication.isActive
                                ? null
                                : TextDecoration.lineThrough,
                            color: medication.isActive
                                ? (isDark ? AppColors.white : Colors.black)
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (medication.needsRenewal)
                        const StatusBadge(
                            label: '⚠ Renouveler',
                            color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Horaires de prise
                  Wrap(
                    spacing: 4,
                    children: medication.intakeTimes
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.textHint.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  // Stock
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 13,
                        color: medication.needsRenewal
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          'Stock: ${medication.stock} unité(s) • ${medication.daysRemaining}j restant(s)',
                          style: AppTextStyles.caption.copyWith(
                            color: medication.needsRenewal
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  _showMedicationDetails(context, medication, provider),
              icon: const Icon(Icons.settings_outlined,
                  size: 20, color: AppColors.textHint),
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

  void _showAddMedicationSheet(
      BuildContext context, Prescription prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(
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

  void _showPrescriptionImage(
      BuildContext context, Prescription prescription) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: prescription.imageLocalPath != null
              ? Image.file(File(prescription.imageLocalPath!))
              : prescription.imageUrl != null
                  ? Image.network(prescription.imageUrl!)
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    Prescription prescription,
  ) {
    final medications =
        provider.getMedicationsByPrescription(prescription.id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Supprimer l\'ordonnance'),
          ],
        ),
        content: Text(
          medications.isNotEmpty
              ? 'Cette action supprimera l\'ordonnance "${prescription.reference}" et ses ${medications.length} médicament(s) associé(s). Cette action est irréversible.'
              : 'Supprimer l\'ordonnance "${prescription.reference}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deletePrescription(prescription.id);
              Navigator.pop(context);
              AppUtils.showSnackBar(context, 'Ordonnance supprimée');
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── AddPrescriptionSheet ───
// ════════════════════════════════════════════════════════════

class AddPrescriptionSheet extends StatefulWidget {
  final BuildContext outerContext;
  const AddPrescriptionSheet({super.key, required this.outerContext});

  @override
  State<AddPrescriptionSheet> createState() => _AddPrescriptionSheetState();
}

class _AddPrescriptionSheetState extends State<AddPrescriptionSheet> {
  final _referenceCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  DateTime _prescriptionDate = DateTime.now();
  File? _imageFile;
  bool _isPickingImage = false;
  String? _message;
  bool _isError = false;

  // Step management: 1 = prescription info, 2 = add medications
  int _step = 1;
  Prescription? _createdPrescription;

  // Medications being added in this session
  final List<_TempMedication> _medications = [];
  
  final List<String> hospitals = [
  'CHU Sylvanus Olympio - Lomé',
  'Hôpital de Bè - Lomé',
  'Hôpital de Tokoin - Lomé',
  'Hôpital Régional Agoè-Nyivé - Lomé',
  'Clinique Agoè - Lomé',
  'Hôpital Général Lomé Commune - Lomé',
  'Clinique Gbossimé - Lomé',
  'Hôpital Régional Kara - Kara',
  'Hôpital Régional Sokodé - Sokodé',
  'Hôpital de Tsévié - Tsévié',
  'Clinique de Lomé-Est - Lomé',
  'Hôpital de Kpalimé - Kpalimé',
  'Clinique Atakpamé - Atakpamé',
  'Hôpital de Dapaong - Dapaong',
  'Clinique de Mango - Mango',
  'Hôpital de Sotouboua - Sotouboua',
  'Clinique de Tabligbo - Tabligbo',
  'Hôpital de Bassar - Bassar',
  'Hôpital de Blitta - Blitta',
  'Hôpital de Pagouda - Pagouda',
  'Hôpital de Aného - Aného',
  'Hôpital de Tsévié Sud - Tsévié',
  'Clinique de Kévé - Kévé',
  'Clinique de Lomé-Centre - Lomé',
  'Hôpital de Niamtougou - Niamtougou',
  'Clinique de Sokodé Sud - Sokodé',
  'Hôpital de Tchamba - Tchamba',
  'Hôpital de Bassar Nord - Bassar',
  'Clinique de Kara Ouest - Kara',
  'Hôpital de Dapaong Nord - Dapaong',
];

  void _showMessage(String msg, {required bool isError}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _doctorCtrl.dispose();
    _hospitalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      AppUtils.showSnackBar(
          context, 'Erreur lors de la sélection de l\'image',
          isError: true);
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Ajouter une photo', style: AppTextStyles.h4),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Appareil photo',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Galerie',
                      color: AppColors.accent,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePrescription() {
    if (_referenceCtrl.text.trim().isEmpty) {
      _showMessage('La référence est obligatoire', isError: true);
      return;
    }
    if (_doctorCtrl.text.trim().isEmpty) {
      _showMessage('Le nom du médecin est obligatoire', isError: true);
      return;
    }

    final prescription = Prescription(
      id: const Uuid().v4(),
      reference: _referenceCtrl.text.trim(),
      imageLocalPath: _imageFile?.path,
      prescriptionDate: _prescriptionDate,
      doctorName: _doctorCtrl.text.trim(),
      hospital: _hospitalCtrl.text.trim().isNotEmpty
          ? _hospitalCtrl.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    // Save to provider immediately
    widget.outerContext.read<AppProvider>().addPrescription(prescription);

    setState(() {
      _createdPrescription = prescription;
      _step = 2;
    });
  }

  void _finalize() {
    // Save all medications
    final provider = widget.outerContext.read<AppProvider>();
    for (final tempMed in _medications) {
      final med = MedicationReminder(
        id: const Uuid().v4(),
        medicationName: tempMed.name,
        dosage: tempMed.dosage,
        intakeTimes: tempMed.intakeTimes,
        stock: tempMed.stock,
        renewalAlertThreshold: tempMed.renewalThreshold,
        diseaseType: provider.currentUser?.diseaseType ?? 'all',
        prescriptionId: _createdPrescription!.id,
      );
      provider.addMedicationReminder(med);
    }

    AppUtils.showSnackBar(
      widget.outerContext,
      _medications.isEmpty
          ? 'Ordonnance ajoutée avec succès'
          : 'Ordonnance et ${_medications.length} médicament(s) ajouté(s)',
    );
    Navigator.pop(context);
  }

  void _showAddMedDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddMedicationDialog(
        onAdd: (tempMed) {
          setState(() => _medications.add(tempMed));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _sheetHandle(isDark),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 1
                            ? 'Nouvelle ordonnance'
                            : 'Ajouter des médicaments',
                        style: AppTextStyles.h4,
                      ),
                      Text(
                        _step == 1
                            ? 'Informations et photo de l\'ordonnance'
                            : _createdPrescription?.reference ?? '',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Step indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Étape $_step/2',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _step / 2,
                backgroundColor:
                    isDark ? AppColors.darkBorder : AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 4,
              ),
            ),
          ),

          const AppDivider(),

          Expanded(
            child: _step == 1
                ? _buildStep1(isDark)
                : _buildStep2(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_message != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          
          // Référence
          _sectionLabel('Référence *', AppColors.primary),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Ex: ORD-2024-001',
              prefixIcon: Icon(Icons.tag, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Médecin
          _sectionLabel('Médecin *', AppColors.primary),
          const SizedBox(height: 8),
          TextField(
            controller: _doctorCtrl,
            decoration: const InputDecoration(
              hintText: 'Nom du médecin',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Hôpital
          _sectionLabel('Établissement', AppColors.textSecondary),
          const SizedBox(height: 8),

          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return hospitals.where((h) => h.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {

              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) {
                  _hospitalCtrl.text = value; 
                  print("Hospital input: $value");
                },
                decoration: const InputDecoration(
                  hintText: 'Hôpital ou clinique (optionnel)',
                  prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
                ),
              );
            },
            onSelected: (selection) {
              _hospitalCtrl.text = selection; 
              FocusScope.of(context).unfocus(); 
              setState(() {}); 
            },
          ),
              const SizedBox(height: 16),

          // Date
          _sectionLabel('Date de l\'ordonnance', AppColors.primary),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _prescriptionDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _prescriptionDate = picked);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(AppUtils.formatDate(_prescriptionDate),
                      style: AppTextStyles.body),
                  const Spacer(),
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Photo de l'ordonnance
          _sectionLabel('Photo de l\'ordonnance', AppColors.primary),
          const SizedBox(height: 8),

          if (_imageFile != null) ...[
            // Image preview
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _imageFile!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _imageFile = null),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _isPickingImage
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Photographier ou importer l\'ordonnance',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optionnel — mais recommandé',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          PrimaryButton(
            label: ' Ajouter les médicaments',
            onPressed: _savePrescription,
            icon: Icons.arrow_forward,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return Column(
      children: [
        // Recap prescription
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imageFile!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description,
                      color: AppColors.primary, size: 22),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_createdPrescription!.reference,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('Dr. ${_createdPrescription!.doctorName}',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                  label: '✓ Enregistrée', color: AppColors.success),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Medications list
        Expanded(
          child: _medications.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medication_outlined,
                          color: AppColors.accent, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('Aucun médicament ajouté',
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      'Ajoutez les médicaments de cette ordonnance',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _medications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final med = _medications[i];
                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medication,
                                color: AppColors.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${med.name} ${med.dosage}',
                                    style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '${med.intakeTimes.length}x/jour • Stock: ${med.stock}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _medications.removeAt(i)),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.error, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Add medication button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: OutlinedButton.icon(
            onPressed: _showAddMedDialog,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Ajouter un médicament'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: PrimaryButton(
            label: _medications.isEmpty
                ? 'Terminer sans médicament'
                : 'Enregistrer (${_medications.length} médicament${_medications.length > 1 ? 's' : ''})',
            onPressed: _finalize,
            icon: Icons.check_circle_outline,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Dialog interne pour ajouter un médicament (step 2) ───
// ════════════════════════════════════════════════════════════

class _TempMedication {
  String name;
  String dosage;
  int stock;
  int renewalThreshold;
  List<TimeOfDay> intakeTimes;

  _TempMedication({
    required this.name,
    required this.dosage,
    required this.stock,
    required this.renewalThreshold,
    required this.intakeTimes,
  });
}

class _AddMedicationDialog extends StatefulWidget {
  final void Function(_TempMedication) onAdd;
  const _AddMedicationDialog({required this.onAdd});

  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '7');
  bool _hasRenewal = true;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 7, minute: 30)];
  String? _message;
  bool _isError = false;

  void _showMessage(String msg, {required bool isError}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _addTime() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (t != null) setState(() => _times.add(t));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) {
      _showMessage( 'Nom et dosage sont obligatoires',
          isError: true);
      return;
    }
    widget.onAdd(_TempMedication(
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      stock: int.tryParse(_stockCtrl.text) ?? 30,
      renewalThreshold:
          _hasRenewal ? (int.tryParse(_thresholdCtrl.text) ?? 7) : 0,
      intakeTimes: _times,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Nouveau médicament',
                        style: AppTextStyles.h4)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const AppDivider(),
            const SizedBox(height: 16),

             if (_message != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Nom
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du médicament *',
                prefixIcon: Icon(Icons.medication, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Dosage
            TextField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage *',
                hintText: 'Ex: 5mg, 500mg, 1 comprimé...',
                prefixIcon: Icon(Icons.scale, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Stock & seuil
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock actuel',
                      prefixIcon: Icon(Icons.inventory_2, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                    enabled: _hasRenewal,
                    decoration: const InputDecoration(
                      labelText: 'Seuil renouvellement',
                      prefixIcon: Icon(Icons.notifications, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Toggle renouvellement
            Row(
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _hasRenewal,
                    activeColor: AppColors.warning,
                    onChanged: (v) => setState(() => _hasRenewal = v),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Alerte de renouvellement',
                  style: AppTextStyles.body.copyWith(
                    color: _hasRenewal ? AppColors.warning : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Horaires
            Text('Horaires de prise *', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            ..._times.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_times.length > 1)
                        IconButton(
                          onPressed: () =>
                              setState(() => _times.removeAt(e.key)),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.error, size: 20),
                        ),
                    ],
                  ),
                )),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add_alarm, size: 18),
              label: const Text('Ajouter une heure'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent),
            ),

            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Ajouter ce médicament',
              onPressed: _save,
              icon: Icons.add_circle_outline,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── AddMedicationSheet (depuis une ordonnance existante) ───
// ════════════════════════════════════════════════════════════

class AddMedicationSheet extends StatefulWidget {
  final BuildContext outerContext;
  final Prescription prescription;

  const AddMedicationSheet({
    super.key,
    required this.outerContext,
    required this.prescription,
  });

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '7');
  bool _hasRenewal = true;
  List<TimeOfDay> _intakeTimes = [const TimeOfDay(hour: 7, minute: 30)];

  String? _message;
  bool _isError = false;

  void _showMessage(String msg, {required bool isError}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _addTime() async {
    final t = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (t != null) setState(() => _intakeTimes.add(t));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) {
      _showMessage(
          'Le nom et le dosage sont obligatoires',
          isError: true);
      return;
    }

    final med = MedicationReminder(
      id: const Uuid().v4(),
      medicationName: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      intakeTimes: _intakeTimes,
      stock: int.tryParse(_stockCtrl.text) ?? 30,
      renewalAlertThreshold:
          _hasRenewal ? (int.tryParse(_thresholdCtrl.text) ?? 7) : 0,
      diseaseType:
          widget.outerContext.read<AppProvider>().currentUser?.diseaseType ??
              'all',
      prescriptionId: widget.prescription.id,
    );

    widget.outerContext.read<AppProvider>().addMedicationReminder(med);
    AppUtils.showSnackBar(widget.outerContext, 'Médicament ajouté');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _sheetHandle(isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nouveau médicament', style: AppTextStyles.h4),
                      Text(
                        'Ordonnance: ${widget.prescription.reference}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          const AppDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  _field('Nom du médicament *', _nameCtrl, 'Ex: Amlodipine',
                      icon: Icons.medication),
                  const SizedBox(height: 14),

                  // Dosage
                  _field('Dosage *', _dosageCtrl, 'Ex: 5mg',
                      icon: Icons.scale),
                  const SizedBox(height: 14),

                  // Stock & seuil
                  Row(
                    children: [
                      Expanded(
                        child: _field('Stock actuel', _stockCtrl, '30',
                            icon: Icons.inventory_2,
                            keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field('Seuil d\'alerte', _thresholdCtrl, '7',
                            icon: Icons.notifications,
                            keyboardType: TextInputType.number,
                            enabled: _hasRenewal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Toggle renouvellement
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasRenewal
                          ? AppColors.warning.withOpacity(0.06)
                          : (isDark
                              ? AppColors.darkBackground
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasRenewal
                            ? AppColors.warning.withOpacity(0.3)
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_outlined,
                          size: 20,
                          color: _hasRenewal
                              ? AppColors.warning
                              : AppColors.textHint,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerte de renouvellement',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _hasRenewal
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _hasRenewal
                                    ? 'Notification quand stock ≤ ${_thresholdCtrl.text.isEmpty ? '7' : _thresholdCtrl.text} unités'
                                    : 'Pas d\'alerte configurée',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _hasRenewal,
                          activeColor: AppColors.warning,
                          onChanged: (v) => setState(() => _hasRenewal = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Horaires
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Horaires de prise *', style: AppTextStyles.h4),
                      TextButton.icon(
                        onPressed: _addTime,
                        icon: const Icon(Icons.add_alarm, size: 16),
                        label: const Text('Ajouter'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._intakeTimes.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final t = await showTimePicker(
                                      context: context,
                                      initialTime: e.value);
                                  if (t != null) {
                                    setState(
                                        () => _intakeTimes[e.key] = t);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 16,
                                          color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.edit_outlined,
                                          size: 14,
                                          color: AppColors.textHint),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_intakeTimes.length > 1)
                              IconButton(
                                onPressed: () => setState(
                                    () => _intakeTimes.removeAt(e.key)),
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.error, size: 20),
                              ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Enregistrer le médicament',
                    onPressed: _save,
                    icon: Icons.save_outlined,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── MedicationDetailsSheet ───
// ════════════════════════════════════════════════════════════

class MedicationDetailsSheet extends StatefulWidget {
  final BuildContext outerContext;
  final MedicationReminder medication;

  const MedicationDetailsSheet({
    super.key,
    required this.outerContext,
    required this.medication,
  });

  @override
  State<MedicationDetailsSheet> createState() =>
      _MedicationDetailsSheetState();
}

class _MedicationDetailsSheetState extends State<MedicationDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _dosageCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _thresholdCtrl;
  late List<TimeOfDay> _intakeTimes;
  late bool _hasRenewal;
  bool _isEditing = false;
  
  String? _message;
  bool _isError = false;

  void _showMessage(String msg, {required bool isError}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _nameCtrl =
        TextEditingController(text: widget.medication.medicationName);
    _dosageCtrl =
        TextEditingController(text: widget.medication.dosage);
    _stockCtrl =
        TextEditingController(text: widget.medication.stock.toString());
    _thresholdCtrl = TextEditingController(
        text: widget.medication.renewalAlertThreshold.toString());
    _intakeTimes = List.from(widget.medication.intakeTimes);
    _hasRenewal = widget.medication.renewalAlertThreshold > 0;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _updateStock(int delta) {
    final current = int.tryParse(_stockCtrl.text) ?? 0;
    final newVal = (current + delta).clamp(0, 9999);
    setState(() => _stockCtrl.text = newVal.toString());
  }

  void _saveChanges() {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) {
      _showMessage( 'Nom et dosage sont obligatoires',
          isError: true);
      return;
    }

    final updatedMed = MedicationReminder(
      id: widget.medication.id,
      medicationName: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      intakeTimes: _intakeTimes,
      stock: int.tryParse(_stockCtrl.text) ?? widget.medication.stock,
      renewalAlertThreshold: _hasRenewal
          ? (int.tryParse(_thresholdCtrl.text) ?? 7)
          : 0,
      diseaseType: widget.medication.diseaseType,
      prescriptionId: widget.medication.prescriptionId,
    );

    widget.outerContext.read<AppProvider>().updateMedicationReminder(updatedMed);
    AppUtils.showSnackBar(widget.outerContext, 'Médicament mis à jour');
    Navigator.pop(context);
  }

  void _deleteMedication() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce médicament'),
        content: Text(
            'Supprimer "${widget.medication.medicationName} ${widget.medication.dosage}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () {
              widget.outerContext
                  .read<AppProvider>()
                  .deleteMedicationReminder(widget.medication.id);
              Navigator.pop(context); // dialog
              Navigator.pop(context); // sheet
              AppUtils.showSnackBar(
                  widget.outerContext, 'Médicament supprimé');
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _addTime() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (t != null) setState(() => _intakeTimes.add(t));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final med = widget.medication;
    final daysColor = med.needsRenewal ? AppColors.warning : AppColors.success;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _sheetHandle(isDark),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.medicationName, style: AppTextStyles.h4),
                      Text(med.dosage,
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (!_isEditing) ...[
                 
                  IconButton(
                    onPressed: _deleteMedication,
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.error),
                    tooltip: 'Supprimer',
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: Text('Annuler',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            labelStyle:
                AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.accent,
            tabs: const [
              Tab(text: 'Détails'),
              Tab(text: 'Modifier'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Tab 1: Détails ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Stock card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              daysColor.withOpacity(0.12),
                              daysColor.withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: daysColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            // Stock counter
                            Expanded(
                              child: Column(
                                children: [
                                  Text('STOCK',
                                      style: AppTextStyles.label.copyWith(
                                          color: daysColor)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _updateStock(-1),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: daysColor
                                                .withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.remove,
                                              size: 16, color: daysColor),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          _stockCtrl.text.isEmpty
                                              ? med.stock.toString()
                                              : _stockCtrl.text,
                                          style: AppTextStyles.h2.copyWith(
                                              color: daysColor),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _updateStock(1),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: daysColor
                                                .withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.add,
                                              size: 16, color: daysColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('unités restantes',
                                      style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: daysColor.withOpacity(0.2),
                            ),
                            // Days remaining
                            Expanded(
                              child: Column(
                                children: [
                                  Text('DURÉE RESTANTE',
                                      style: AppTextStyles.label.copyWith(
                                          color: daysColor)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${med.daysRemaining}',
                                    style: AppTextStyles.h2
                                        .copyWith(color: daysColor),
                                  ),
                                  Text('jours',
                                      style: AppTextStyles.bodySmall),
                                  if (med.needsRenewal) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '⚠ À renouveler',
                                        style: AppTextStyles.caption
                                            .copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info médicament
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informations', style: AppTextStyles.h4),
                            const SizedBox(height: 14),
                            const AppDivider(),
                            const SizedBox(height: 14),
                            _infoRow(Icons.medication, 'Médicament',
                                med.medicationName),
                            const SizedBox(height: 10),
                            _infoRow(Icons.scale, 'Dosage', med.dosage),
                            const SizedBox(height: 10),
                            _infoRow(
                              Icons.repeat,
                              'Prises par jour',
                              '${med.intakeTimes.length}x/jour',
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              Icons.notifications_outlined,
                              'Seuil de renouvellement',
                              med.renewalAlertThreshold > 0
                                  ? '≤ ${med.renewalAlertThreshold} unités'
                                  : 'Désactivé',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Horaires
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text('Horaires de prise',
                                    style: AppTextStyles.h4),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const AppDivider(),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: med.intakeTimes
                                  .map((t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: AppColors.primary
                                                  .withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                color: AppColors.primary,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick stock update button
                      OutlinedButton.icon(
                        onPressed: () {
                          // Save stock update
                          final updated = MedicationReminder(
                            id: med.id,
                            medicationName: med.medicationName,
                            dosage: med.dosage,
                            intakeTimes: med.intakeTimes,
                            stock: int.tryParse(_stockCtrl.text) ??
                                med.stock,
                            renewalAlertThreshold:
                                med.renewalAlertThreshold,
                            diseaseType: med.diseaseType,
                            prescriptionId: med.prescriptionId,
                          );
                          widget.outerContext
                              .read<AppProvider>()
                              .updateMedicationReminder(updated);
                          AppUtils.showSnackBar(widget.outerContext,
                              'Stock mis à jour');
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Sauvegarder le stock'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side:
                              const BorderSide(color: AppColors.accent),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tab 2: Modifier ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _editField('Nom du médicament', _nameCtrl,
                          icon: Icons.medication),
                      const SizedBox(height: 14),
                      _editField('Dosage', _dosageCtrl, icon: Icons.scale),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _editField('Stock actuel', _stockCtrl,
                                icon: Icons.inventory_2,
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editField(
                                'Seuil d\'alerte', _thresholdCtrl,
                                icon: Icons.notifications,
                                keyboardType: TextInputType.number,
                                enabled: _hasRenewal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Toggle renouvellement
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _hasRenewal
                              ? AppColors.warning.withOpacity(0.06)
                              : (isDark
                                  ? AppColors.darkBackground
                                  : AppColors.background),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasRenewal
                                ? AppColors.warning.withOpacity(0.3)
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.refresh_outlined,
                                size: 20,
                                color: _hasRenewal
                                    ? AppColors.warning
                                    : AppColors.textHint),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Alerte de renouvellement',
                                style: AppTextStyles.body.copyWith(
                                  color: _hasRenewal
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: _hasRenewal,
                              activeColor: AppColors.warning,
                              onChanged: (v) =>
                                  setState(() => _hasRenewal = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Horaires de prise',
                              style: AppTextStyles.h4),
                          TextButton.icon(
                            onPressed: _addTime,
                            icon: const Icon(Icons.add_alarm, size: 16),
                            label: const Text('Ajouter'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._intakeTimes.asMap().entries.map((e) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final t = await showTimePicker(
                                          context: context,
                                          initialTime: e.value);
                                      if (t != null) {
                                        setState(() =>
                                            _intakeTimes[e.key] = t);
                                      }
                                    },
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 13),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withOpacity(0.06),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 16,
                                              color: AppColors.primary),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}',
                                            style:
                                                AppTextStyles.body.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.edit_outlined,
                                              size: 14,
                                              color: AppColors.textHint),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_intakeTimes.length > 1)
                                  IconButton(
                                    onPressed: () => setState(() =>
                                        _intakeTimes.removeAt(e.key)),
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: AppColors.error,
                                        size: 20),
                                  ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      if (_message != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Enregistrer les modifications',
                        onPressed: _saveChanges,
                        icon: Icons.save_outlined,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 12),
                      
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editField(
    String label,
    TextEditingController ctrl, {
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 20)),
        ),
      ],
    );
  }
}

// ─── Sheet handle helper ───
Widget _sheetHandle(bool isDark) {
  return Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBorder : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}