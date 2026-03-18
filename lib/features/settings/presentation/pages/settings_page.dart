import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // ── Numéros d'urgence Togo ──
  static const String _samu = '8200';
  static const String _pompiers = '118';
  static const String _police = '117';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      );
    }

    final user = provider.currentUser!;
    



    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        elevation: 0,
        title: const Text('Paramètres'),
        titleTextStyle: AppTextStyles.h4.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(
            color: Colors.white,
          ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 🚨 Urgence ──
          _buildEmergencyCard(context, isDark),
          const SizedBox(height: 20),

          // ── Profile header ──
          _buildProfileCard(context, provider, user, isDark),
          const SizedBox(height: 20),

          // ── Appearance ──
          _SectionTitle(label: 'Apparence'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: AppColors.warning,
                  title: 'Thème clair',
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: provider.themeMode,
                    activeColor: AppColors.primary,
                    onChanged: (v) => provider.setThemeMode(v!),
                  ),
                  onTap: () => provider.setThemeMode(ThemeMode.light),
                ),
                const AppDivider(indent: 56),
                _SettingsTile(
                  icon: Icons.nights_stay_outlined,
                  iconColor: AppColors.primary,
                  title: 'Thème sombre',
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: provider.themeMode,
                    activeColor: AppColors.primary,
                    onChanged: (v) => provider.setThemeMode(v!),
                  ),
                  onTap: () => provider.setThemeMode(ThemeMode.dark),
                ),
                const AppDivider(indent: 56),
                _SettingsTile(
                  icon: Icons.phone_android_outlined,
                  iconColor: AppColors.textSecondary,
                  title: 'Système',
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: provider.themeMode,
                    activeColor: AppColors.primary,
                    onChanged: (v) => provider.setThemeMode(v!),
                  ),
                  onTap: () => provider.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Security ──
          _SectionTitle(label: 'Sécurité'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline,
                  iconColor: AppColors.info,
                  title: 'Verrouillage de l\'application',
                  subtitle: provider.appLockEnabled ? 'Activé' : 'Désactivé',
                  trailing: Switch(
                    value: provider.appLockEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (v) => _handleAppLock(context, provider, v),
                  ),
                ),
                if (provider.appLockEnabled) ...[
                  const AppDivider(indent: 56),
                  _SettingsTile(
                    icon: Icons.key_outlined,
                    iconColor: AppColors.warning,
                    title: 'Changer le mot de passe',
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textHint),
                    onTap: () => _showChangePasswordSheet(context, provider),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Health Status ──
          _SectionTitle(label: 'Statut de santé'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (!user.isPatient && !user.isPendingValidation)
                  _SettingsTile(
                    icon: Icons.medical_services_outlined,
                    iconColor: AppColors.accent,
                    title: 'Activer le mode patient',
                    subtitle: 'Soumettre une demande de validation',
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textHint),
                    onTap: () =>
                        _showPatientActivationSheet(context, provider),
                  )
                else if (user.isPendingValidation)
                  _SettingsTile(
                    icon: Icons.hourglass_top_outlined,
                    iconColor: AppColors.warning,
                    title: 'Demande en cours',
                    subtitle: 'En attente de validation par votre médecin',
                    trailing: StatusBadge(
                        label: 'En attente', color: AppColors.warning),
                  )
                else ...[
                  _SettingsTile(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.accent,
                    title: 'Statut patient',
                    subtitle: user.diseaseType == 'hypertension'
                        ? 'Hypertension'
                        : 'Diabète',
                    trailing:
                        const StatusBadge(label: 'Actif', color: AppColors.accent),
                  ),

                  // Données corporelles
                  const AppDivider(indent: 56),
                  _SettingsTile(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: AppColors.primary,
                    title: 'Données corporelles',
                    subtitle: _bodyDataSubtitle(user),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.textHint),
                      onPressed: () => _showBodyDataSheet(context, provider),
                    ),
                  ),

                  // Localisation GPS
                  const AppDivider(indent: 56),
                  _SettingsTile(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.error,
                    title: 'Ma localisation',
                    subtitle: user.gpsLocation != null
                        ? '📍 Localisation définie'
                        : 'Non définie — requis pour le suivi',
                    trailing: user.gpsLocation != null
                        ? IconButton(
                            icon: const Icon(Icons.refresh,
                                size: 18, color: AppColors.accent),
                            onPressed: () =>
                                _showLocationSheet(context, provider),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Définir',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                    onTap: () => _showLocationSheet(context, provider),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Account ──
          _SectionTitle(label: 'Compte'),
          AppCard(
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.logout,
              iconColor: AppColors.error,
              title: 'Déconnexion',
              titleColor: AppColors.error,
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textHint),
              onTap: () => _confirmLogout(context, provider),
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('Lamesse Dama v1.0.0',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Urgence card ──
  Widget _buildEmergencyCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEmergencySheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appel d\'urgence',
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '117 — Urgences Togo',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile card ──
  Widget _buildProfileCard(BuildContext context, AppProvider provider,
      dynamic user, bool isDark) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Text(user.initials,
                    style: AppTextStyles.h3.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: AppTextStyles.h4.copyWith(color: isDark ? AppColors.darkText : Colors.black)),
                    Text(user.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusBadge(
                          label: user.isPatient
                              ? 'Patient'
                              : user.isPendingValidation
                                  ? 'En attente'
                                  : 'Non-patient',
                          color: user.isPatient
                              ? AppColors.accent
                              : user.isPendingValidation
                                  ? AppColors.warning
                                  : AppColors.textHint,
                        ),
                        if (user.isPatient && user.diseaseType != null)
                          DiseaseTag(diseaseType: user.diseaseType!),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileSheet(context, provider),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),

          // Données corporelles si patient
          if (user.isPatient) ...[
            const SizedBox(height: 12),
            const AppDivider(),
            const SizedBox(height: 12),
            Row(
              children: [
                _profileDataChip(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Poids',
                  value: user.weight != null
                      ? '${user.weight!.toStringAsFixed(1)} kg'
                      : '— kg',
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _profileDataChip(
                  icon: Icons.height,
                  label: 'Taille',
                  value: user.height != null
                      ? '${user.height!.toStringAsFixed(0)} cm'
                      : '— cm',
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _profileDataChip(
                  icon: Icons.location_on_outlined,
                  label: 'GPS',
                  value: user.gpsLocation != null ? 'Défini ✓' : 'Non défini',
                  isDark: isDark,
                  valueColor: user.gpsLocation != null
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _profileDataChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ??
                    (isDark ? AppColors.darkText : AppColors.textPrimary),
              ),
              textAlign: TextAlign.center,
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _bodyDataSubtitle(dynamic user) {
    final w = user.weight != null
        ? '${user.weight!.toStringAsFixed(1)} kg'
        : '— kg';
    final h = user.height != null
        ? '${user.height!.toStringAsFixed(0)} cm'
        : '— cm';
    return '$w  •  $h';
  }

  // ─── Méthodes d'action ───

  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmergencySheet(),
    );
  }

  void _handleAppLock(BuildContext context, AppProvider provider, bool enable) {
    if (enable) {
      _showSetPasswordSheet(context, provider);
    } else {
      provider.setAppLock(false);
      AppUtils.showSnackBar(context, 'Verrouillage désactivé');
    }
  }

  void _showEditProfileSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(provider: provider),
    );
  }

  void _showSetPasswordSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SetPasswordSheet(provider: provider, isChange: false),
    );
  }

  void _showChangePasswordSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SetPasswordSheet(provider: provider, isChange: true),
    );
  }

  void _showPatientActivationSheet(
      BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientActivationSheet(provider: provider),
    );
  }

  void _showBodyDataSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BodyDataSheet(provider: provider),
    );
  }

  void _showLocationSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(provider: provider),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnexion', style: AppTextStyles.h4),
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
               
               provider.logout();
            },
            child: Text('Déconnexion',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Emergency Sheet ───
// ════════════════════════════════════════════════════════════

class _EmergencySheet extends StatelessWidget {
  static const _numbers = [
    _EmergencyNumber(
      label: 'Urgences — Police',
      subtitle: 'Police secours & urgences',
      number: '117',
      icon: Icons.local_police,
      color: Color(0xFF3B82F6),
    ),
    _EmergencyNumber(
      label: 'Urgences — Secours',
      subtitle: 'Pompiers & secours d\'urgence',
      number: '117',
      icon: Icons.emergency,
      color: Color(0xFFEF4444),
    ),
    _EmergencyNumber(
      label: 'CHU Sylvanus Olympio',
      subtitle: 'Hôpital principal — Lomé',
      number: '+22822212501',
      icon: Icons.local_hospital,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // hauteur fixe pour que le scroll fonctionne
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header — fixe, ne scrolle pas
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appel d\'urgence', style: AppTextStyles.h4),
                      Text('Sélectionnez un service à appeler',
                          style: AppTextStyles.bodySmall),
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

          // Warning banner — fixe, ne scrolle pas
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'En cas d\'urgence, composez le 117. L\'application téléphone s\'ouvrira avec le numéro pré-composé.',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Liste scrollable
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              itemCount: _numbers.length,
              itemBuilder: (_, i) => _EmergencyTile(data: _numbers[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyNumber {
  final String label;
  final String subtitle;
  final String number;
  final IconData icon;
  final Color color;

  const _EmergencyNumber({
    required this.label,
    required this.subtitle,
    required this.number,
    required this.icon,
    required this.color,
  });
}

class _EmergencyTile extends StatelessWidget {
  final _EmergencyNumber data;
  const _EmergencyTile({required this.data});

  Future<void> _call(BuildContext context) async {
    // Dialog de confirmation avant d'ouvrir l'app téléphone
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone, color: data.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Appeler ${data.label}', style: AppTextStyles.h4),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'application téléphone va s\'ouvrir avec le numéro déjà composé.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: data.color.withOpacity(0.2)),
              ),
              child: Text(
                data.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  color: data.color,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(data.subtitle, style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: data.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.phone_forwarded, size: 16),
            label: const Text('Ouvrir le téléphone'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Ouvre l'app téléphone native avec le numéro pré-composé
      final uri = Uri(scheme: 'tel', path: data.number);
      try {
        final launched = await launchUrl(uri);
        if (!launched && context.mounted) {
          AppUtils.showSnackBar(
            context,
            'Impossible d\'ouvrir le téléphone. Composez le ${data.number}',
            isError: true,
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppUtils.showSnackBar(
            context,
            'Impossible d\'ouvrir le téléphone. Composez le ${data.number}',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _call(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: data.color.withOpacity(0.25), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.label,
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700)),
                      Text(data.subtitle,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        data.number,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Patient Activation Sheet (updated) ───
// ════════════════════════════════════════════════════════════

class _PatientActivationSheet extends StatefulWidget {
  final AppProvider provider;
  const _PatientActivationSheet({required this.provider});

  @override
  State<_PatientActivationSheet> createState() =>
      _PatientActivationSheetState();
}

class _PatientActivationSheetState extends State<_PatientActivationSheet> {
  String _disease = 'hypertension';
  final _doctorEmailCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  int _step = 1; // 1=form, 2=uploading, 3=pending, 4=approved

  // Documents
  File? _receiptFile;       // reçu de consultation
  File? _carnetFile;        // carnet de santé (partie médecin)
  bool _isUploadingReceipt = false;
  bool _isUploadingCarnet  = false;
  bool _isSubmitting       = false;

  // Body data (step 4)
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _isGettingLocation = false;
  String? _locationPreview;

  @override
  void dispose() {
    _doctorEmailCtrl.dispose();
    _hospitalCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  // ── Sélection d'un fichier — dialog au lieu de bottom sheet imbriqué ──
  Future<File?> _pickFile(BuildContext ctx) async {
    final source = await showDialog<ImageSource>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_file,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Selectionner',),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _sourceBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Prendre\nen photo',
                    color: AppColors.primary,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Depuis\nla galerie',
                    color: AppColors.accent,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (source == null) return null;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      if (ctx.mounted) {
        AppUtils.showSnackBar(ctx, 'Impossible d\'accéder à la caméra/galerie',
            isError: true);
      }
    }
    return null;
  }

  Widget _sourceBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceipt(BuildContext ctx) async {
    setState(() => _isUploadingReceipt = true);
    try {
      final file = await _pickFile(ctx);
      if (file != null) setState(() => _receiptFile = file);
    } finally {
      setState(() => _isUploadingReceipt = false);
    }
  }

  Future<void> _pickCarnet(BuildContext ctx) async {
    setState(() => _isUploadingCarnet = true);
    try {
      final file = await _pickFile(ctx);
      if (file != null) setState(() => _carnetFile = file);
    } finally {
      setState(() => _isUploadingCarnet = false);
    }
  }

  void _submit(BuildContext ctx) {
    if (_doctorEmailCtrl.text.trim().isEmpty) {
      AppUtils.showSnackBar(ctx, 'L\'email du médecin est obligatoire',
          isError: true);
      return;
    }
    if (_receiptFile == null) {
      AppUtils.showSnackBar(ctx, 'Veuillez joindre le reçu de consultation',
          isError: true);
      return;
    }
    if (_carnetFile == null) {
      AppUtils.showSnackBar(
          ctx, 'Veuillez joindre la page du carnet de santé',
          isError: true);
      return;
    }

    // Simuler un upload
    setState(() { _isSubmitting = true; });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() { _isSubmitting = false; _step = 3; });
    });
  }

  void _simulateValidation() {
    setState(() => _step = 4);
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        AppUtils.showSnackBar(
            context, 'Autorisation de localisation refusée',
            isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationStr =
          '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';

      setState(() {
        _locationPreview =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
        widget.provider.updateUserLocation(locationStr);
      });

      AppUtils.showSnackBar(context, 'Localisation enregistrée ✓');
    } catch (e) {
      AppUtils.showSnackBar(context, 'Impossible d\'obtenir la localisation',
          isError: true);
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _saveBodyDataAndFinish(BuildContext ctx) {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);

    if (w == null || h == null) {
      AppUtils.showSnackBar(ctx, 'Poids et taille sont obligatoires',
          isError: true);
      return;
    }
    if (w < 20 || w > 300) {
      AppUtils.showSnackBar(ctx, 'Poids invalide (20-300 kg)',
          isError: true);
      return;
    }
    if (h < 50 || h > 250) {
      AppUtils.showSnackBar(ctx, 'Taille invalide (50-250 cm)',
          isError: true);
      return;
    }

    final updated = widget.provider.currentUser!.copyWith(
      weight: w,
      height: h,
    );
    widget.provider.updateUser(updated);
    widget.provider.activatePatient(_disease);
    AppUtils.showSnackBar(ctx, 'Mode patient activé ! Bienvenue 🎉');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: _step == 4
          ? 'Compléter votre profil'
          : 'Activation mode patient',
      icon: _step == 4
          ? Icons.person_outline
          : Icons.medical_services_outlined,
      iconColor: AppColors.accent,
      child: _step == 1
          ? _buildForm(context)
          : _step == 3
              ? _buildPending(context)
              : _step == 4
                  ? _buildProfileCompletion(context)
                  : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Votre médecin recevra votre dossier par email et validera votre demande depuis l\'interface web.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Maladie
        _fieldLabel('Maladie concernée'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _diseaseOption('hypertension', 'Hypertension',
                Icons.favorite, AppColors.hypertension)),
            const SizedBox(width: 10),
            Expanded(child: _diseaseOption('diabetes', 'Diabète',
                Icons.water_drop_outlined, AppColors.primary)),
          ],
        ),
        const SizedBox(height: 16),

        // Email médecin
        _fieldLabel('Email du médecin *'),
        const SizedBox(height: 6),
        TextField(
          controller: _doctorEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'medecin@exemple.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),

        // Hôpital
        _fieldLabel('Hôpital / Clinique'),
        const SizedBox(height: 6),
        TextField(
          controller: _hospitalCtrl,
          decoration: const InputDecoration(
            hintText: 'Ex: CHU Sylvanus Olympio',
            prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 24),

        // ── Documents à uploader ──
        Row(
          children: [
            Container(
              width: 3, height: 16,
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('DOCUMENTS REQUIS *',
                style: AppTextStyles.label.copyWith(color: AppColors.warning)),
          ],
        ),
        const SizedBox(height: 12),

        // Reçu de consultation
        _docUploadTile(
          ctx: ctx,
          icon: Icons.receipt_long_outlined,
          label: 'Reçu de consultation',
          description: 'Photo ou scan du reçu de paiement de votre consultation',
          file: _receiptFile,
          isLoading: _isUploadingReceipt,
          onTap: () => _pickReceipt(ctx),
          onRemove: () => setState(() => _receiptFile = null),
        ),
        const SizedBox(height: 12),

        // Carnet de santé
        _docUploadTile(
          ctx: ctx,
          icon: Icons.menu_book_outlined,
          label: 'Carnet de santé — partie médecin',
          description: 'Photo de la page remplie par votre médecin',
          file: _carnetFile,
          isLoading: _isUploadingCarnet,
          onTap: () => _pickCarnet(ctx),
          onRemove: () => setState(() => _carnetFile = null),
        ),

        const SizedBox(height: 24),
        PrimaryButton(
          label: _isSubmitting ? 'Envoi en cours...' : 'Soumettre la demande',
          onPressed: _isSubmitting ? null : () => _submit(ctx),
          icon: _isSubmitting ? null : Icons.send_outlined,
          color: (_receiptFile != null && _carnetFile != null)
              ? AppColors.accent
              : AppColors.textHint,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _docUploadTile({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required String description,
    required File? file,
    required bool isLoading,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bool isDone = file != null;

    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.success.withOpacity(0.06)
              : (isDark ? AppColors.darkBackground : AppColors.background),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.success.withOpacity(0.4)
                : AppColors.warning.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icône ou preview
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isDone
                  ? Stack(
                      children: [
                        Image.file(file!,
                            width: 52, height: 52, fit: BoxFit.cover),
                        Positioned.fill(
                          child: Container(color: Colors.black12),
                        ),
                        const Positioned.fill(
                          child: Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.warning),
                            )
                          : Icon(icon,
                              color: AppColors.warning, size: 26),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? AppColors.success
                            : (isDark
                                ? AppColors.darkText
                                : AppColors.textPrimary),
                      )),
                  const SizedBox(height: 3),
                  Text(
                    isDone ? '✓ Document ajouté' : description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDone
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bouton action
            if (isDone)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.error, size: 16),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Ajouter',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    )),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label,
        style: AppTextStyles.caption
            .copyWith(color: AppColors.textSecondary));
  }

  Widget _buildPending(BuildContext ctx) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Résumé documents uploadés
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_done_outlined,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('Documents envoyés au médecin',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              _uploadedDocRow(Icons.receipt_long_outlined, 'Reçu de consultation'),
              const SizedBox(height: 6),
              _uploadedDocRow(Icons.menu_book_outlined, 'Carnet de santé'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_top,
              color: AppColors.warning, size: 34),
        ),
        const SizedBox(height: 14),
        Text('Demande soumise !', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          'Dossier envoyé à ${_doctorEmailCtrl.text}.\nVous serez notifié(e) dès validation.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        _stepItem('1', 'Demande & documents envoyés', true),
        _stepItem('2', 'Vérification par le médecin', false),
        _stepItem('3', 'Validation du médecin', false),
        _stepItem('4', 'Activation du mode patient', false),

        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Simuler une validation (démo)',
          onPressed: _simulateValidation,
          icon: Icons.verified_user_outlined,
          color: AppColors.accent,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _uploadedDocRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: AppColors.success),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w500)),
        ),
        const Icon(Icons.check_circle, color: AppColors.success, size: 16),
      ],
    );
  }

  Widget _buildProfileCompletion(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.success.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demande validée !',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(
                        'Complétez votre profil pour finaliser l\'activation.',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Localisation — highlight important
        _sectionLabel('📍 Votre localisation à domicile', AppColors.error),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pour recevoir une aide médicale à domicile, nous avons besoin de votre position GPS. Assurez-vous d\'être chez vous au moment de la définir.',
                style: AppTextStyles.bodySmall.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              if (_locationPreview != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationPreview!,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: _getLocation,
                        child: const Icon(Icons.refresh,
                            size: 16, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _locationPreview != null
                        ? AppColors.success
                        : AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isGettingLocation ? null : _getLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(
                          _locationPreview != null
                              ? Icons.my_location
                              : Icons.location_searching,
                          size: 18),
                  label: Text(
                    _isGettingLocation
                        ? 'Localisation en cours...'
                        : _locationPreview != null
                            ? 'Mettre à jour la localisation'
                            : 'Définir ma localisation actuelle',
                    style: AppTextStyles.button
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Données corporelles
        _sectionLabel('Données corporelles', AppColors.primary),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _bodyField('Poids (kg) *', _weightCtrl, '72.5',
                  icon: Icons.monitor_weight_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bodyField('Taille (cm) *', _heightCtrl, '170',
                  icon: Icons.height),
            ),
          ],
        ),
        const SizedBox(height: 24),

        PrimaryButton(
          label: 'Finaliser l\'activation',
          onPressed: () => _saveBodyDataAndFinish(ctx),
          icon: Icons.check_circle_outline,
          color: AppColors.accent,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bodyField(
      String label, TextEditingController ctrl, String hint,
      {required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _stepItem(String num, String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text(num,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      )),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: done ? AppColors.success : AppColors.textSecondary,
              fontWeight:
                  done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _diseaseOption(
      String value, String label, IconData icon, Color color) {
    final isSelected = _disease == value;
    return GestureDetector(
      onTap: () => setState(() => _disease = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? color : AppColors.textHint),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.body.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _docItem(
      {required IconData icon,
      required String label,
      required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.warning),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600)),
              Text(description, style: AppTextStyles.bodySmall),
            ],
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
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: color)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Location Sheet (standalone) ───
// ════════════════════════════════════════════════════════════

class _LocationSheet extends StatefulWidget {
  final AppProvider provider;
  const _LocationSheet({required this.provider});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  bool _isLoading = false;
  String? _locationPreview;

  @override
  void initState() {
    super.initState();
    if (widget.provider.currentUser?.gpsLocation != null) {
      final parts = widget.provider.currentUser!.gpsLocation!.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        if (lat != null && lon != null) {
          _locationPreview =
              'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
        }
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        AppUtils.showSnackBar(
            context, 'Permission de localisation refusée',
            isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final locationStr =
          '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';

      widget.provider.updateUserLocation(locationStr);
      setState(() {
        _locationPreview =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });
      AppUtils.showSnackBar(context, 'Localisation mise à jour ✓');
    } catch (e) {
      AppUtils.showSnackBar(
          context, 'Impossible d\'obtenir la localisation',
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _BottomSheetWrapper(
      title: 'Ma localisation à domicile',
      icon: Icons.location_on_outlined,
      iconColor: AppColors.error,
      child: Column(
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assurez-vous d\'être à votre domicile avant de définir votre localisation. Cette information permet à votre équipe médicale de vous localiser en cas d\'urgence.',
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Current location display
          if (_locationPreview != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Localisation actuelle',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_locationPreview!,
                      style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Aucune localisation définie',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _locationPreview != null
                    ? AppColors.accent
                    : AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _getLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(
                      _locationPreview != null
                          ? Icons.my_location
                          : Icons.location_searching,
                      size: 20),
              label: Text(
                _isLoading
                    ? 'Localisation en cours...'
                    : _locationPreview != null
                        ? 'Actualiser ma position'
                        : 'Définir ma localisation',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),

          if (_locationPreview != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fermer',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Shared Widgets & Utilities ───
// ════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label.copyWith(
            color: AppColors.textHint, letterSpacing: 1.2, fontSize: 11),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: titleColor ??
                          (isDark
                              ? AppColors.darkText
                              : AppColors.textPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─── Edit Profile Sheet ───
class _EditProfileSheet extends StatefulWidget {
  final AppProvider provider;
  const _EditProfileSheet({required this.provider});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _residenceCtrl;
  late final TextEditingController _districtCtrl;

  @override
  void initState() {
    super.initState();
    final u = widget.provider.currentUser!;
    _firstNameCtrl = TextEditingController(text: u.firstName);
    _lastNameCtrl = TextEditingController(text: u.lastName);
    _phoneCtrl = TextEditingController(text: u.phone);
    _residenceCtrl = TextEditingController(text: u.residence);
    _districtCtrl = TextEditingController(text: u.district);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _residenceCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext ctx) {
    if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) {
      AppUtils.showSnackBar(ctx, 'Le nom et prénom sont obligatoires',
          isError: true);
      return;
    }
    final updated = widget.provider.currentUser!.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      residence: _residenceCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
    );
    widget.provider.updateUser(updated);
    AppUtils.showSnackBar(ctx, 'Profil mis à jour');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Modifier le profil',
      icon: Icons.person_outline,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          _fieldRow('Prénom', _firstNameCtrl, 'Jean'),
          const SizedBox(height: 14),
          _fieldRow('Nom', _lastNameCtrl, 'Dupont'),
          const SizedBox(height: 14),
          _fieldRow('Téléphone', _phoneCtrl, '+228 90 00 00 00',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _fieldRow('Ville / Commune', _residenceCtrl, 'Lomé'),
          const SizedBox(height: 14),
          _fieldRow('Quartier', _districtCtrl, 'Bè Kpota'),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Enregistrer',
            onPressed: () => _save(context),
            icon: Icons.save_outlined,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
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
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ─── Set Password Sheet ───
class _SetPasswordSheet extends StatefulWidget {
  final AppProvider provider;
  final bool isChange;
  const _SetPasswordSheet({required this.provider, required this.isChange});

  @override
  State<_SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends State<_SetPasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext ctx) {
    if (widget.isChange &&
        !widget.provider.verifyPassword(_currentCtrl.text)) {
      AppUtils.showSnackBar(ctx, 'Mot de passe actuel incorrect',
          isError: true);
      return;
    }
    if (_newCtrl.text.length < 6) {
      AppUtils.showSnackBar(
          ctx, 'Le mot de passe doit faire au moins 6 caractères',
          isError: true);
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      AppUtils.showSnackBar(ctx, 'Les mots de passe ne correspondent pas',
          isError: true);
      return;
    }
    widget.provider.setAppLock(true, password: _newCtrl.text);
    AppUtils.showSnackBar(ctx,
        widget.isChange ? 'Mot de passe modifié' : 'Verrouillage activé');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: widget.isChange
          ? 'Changer le mot de passe'
          : 'Définir un mot de passe',
      icon: Icons.lock_outline,
      iconColor: AppColors.info,
      child: Column(
        children: [
          if (widget.isChange) ...[
            _passField('Mot de passe actuel', _currentCtrl,
                _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 14),
          ],
          _passField('Nouveau mot de passe', _newCtrl, _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 14),
          _passField('Confirmer le mot de passe', _confirmCtrl,
              _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 24),
          PrimaryButton(
            label: widget.isChange ? 'Modifier' : 'Activer le verrouillage',
            onPressed: () => _save(context),
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  Widget _passField(String label, TextEditingController ctrl, bool obscure,
      VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Body Data Sheet ───
class _BodyDataSheet extends StatefulWidget {
  final AppProvider provider;
  const _BodyDataSheet({required this.provider});

  @override
  State<_BodyDataSheet> createState() => _BodyDataSheetState();
}

class _BodyDataSheetState extends State<_BodyDataSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  @override
  void initState() {
    super.initState();
    final u = widget.provider.currentUser!;
    _weightCtrl =
        TextEditingController(text: u.weight?.toStringAsFixed(1) ?? '');
    _heightCtrl =
        TextEditingController(text: u.height?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext ctx) {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w == null || h == null) {
      AppUtils.showSnackBar(ctx, 'Valeurs invalides', isError: true);
      return;
    }
    widget.provider.updateUser(
        widget.provider.currentUser!.copyWith(weight: w, height: h));
    AppUtils.showSnackBar(ctx, 'Données corporelles enregistrées');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Données corporelles',
      icon: Icons.monitor_weight_outlined,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _field('Poids (kg)', _weightCtrl, '72.5')),
              const SizedBox(width: 12),
              Expanded(child: _field('Taille (cm)', _heightCtrl, '170')),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Enregistrer',
            onPressed: () => _save(context),
            icon: Icons.save_outlined,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _field(
      String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ─── Reusable Bottom Sheet Wrapper ───
class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BottomSheetWrapper({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: AppTextStyles.h4)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          const AppDivider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}