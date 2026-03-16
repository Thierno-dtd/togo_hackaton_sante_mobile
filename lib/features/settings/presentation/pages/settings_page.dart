import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        title: Text('Paramètres', style: AppTextStyles.h4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile header ──
          AppCard(
            child: Row(
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
                      Text(user.fullName, style: AppTextStyles.h4),
                      Text(user.email, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      StatusBadge(
                        label: user.isPatient ? 'Patient' : 'Non-patient',
                        color: user.isPatient ? AppColors.accent : AppColors.textHint,
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
          ),

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
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
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
                if (!user.isPatient)
                  _SettingsTile(
                    icon: Icons.medical_services_outlined,
                    iconColor: AppColors.accent,
                    title: 'Activer le mode patient',
                    subtitle: 'Soumettre une demande de validation',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
                    onTap: () => _showPatientActivationSheet(context, provider),
                  )
                else ...[
                  _SettingsTile(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.accent,
                    title: 'Statut patient',
                    subtitle: user.diseaseType == 'hypertension' ? 'Hypertension' : 'Diabète',
                    trailing: StatusBadge(label: 'Actif', color: AppColors.accent),
                  ),
                  if (user.weight != null || user.height != null) ...[
                    const AppDivider(indent: 56),
                    _SettingsTile(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: AppColors.primary,
                      title: 'Données corporelles',
                      subtitle:
                        '${user.weight != null ? "${user.weight!.toStringAsFixed(1)} kg" : "—"}  •  ${user.height != null ? "${user.height!.toStringAsFixed(0)} cm" : "—"}',
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textHint),
                        onPressed: () => _showBodyDataSheet(context, provider),
                      ),
                    ),
                  ],
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
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
              onTap: () => _confirmLogout(context, provider),
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('Lamesse Dama v1.0.0',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── App lock handler ──
  void _handleAppLock(BuildContext context, AppProvider provider, bool enable) {
    if (enable) {
      _showSetPasswordSheet(context, provider);
    } else {
      provider.setAppLock(false);
      AppUtils.showSnackBar(context, 'Verrouillage désactivé');
    }
  }

  // ── Edit profile ──
  void _showEditProfileSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(provider: provider),
    );
  }

  // ── Set / Change password ──
  void _showSetPasswordSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetPasswordSheet(provider: provider, isChange: false),
    );
  }

  void _showChangePasswordSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetPasswordSheet(provider: provider, isChange: true),
    );
  }

  // ── Patient activation ──
  void _showPatientActivationSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientActivationSheet(provider: provider),
    );
  }

  // ── Body data ──
  void _showBodyDataSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BodyDataSheet(provider: provider),
    );
  }

  // ── Logout ──
  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnexion', style: AppTextStyles.h4),
        content: Text('Voulez-vous vraiment vous déconnecter ?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
            },
            child: Text('Déconnexion', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ───
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.textHint, letterSpacing: 1.2, fontSize: 11)),
    );
  }
}

// ─── Settings Tile ───
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
              width: 36, height: 36,
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
                  Text(title, style: AppTextStyles.body.copyWith(
                    color: titleColor ?? (isDark ? AppColors.darkText : AppColors.textPrimary),
                    fontWeight: FontWeight.w600,
                  )),
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
    _lastNameCtrl  = TextEditingController(text: u.lastName);
    _phoneCtrl     = TextEditingController(text: u.phone);
    _residenceCtrl = TextEditingController(text: u.residence);
    _districtCtrl  = TextEditingController(text: u.district);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _phoneCtrl.dispose(); _residenceCtrl.dispose(); _districtCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext ctx) {
    if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) {
      AppUtils.showSnackBar(ctx, 'Le nom et prénom sont obligatoires', isError: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          _fieldRow('Téléphone', _phoneCtrl, '+229 97 00 00 00',
            keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _fieldRow('Ville / Commune', _residenceCtrl, 'Cotonou'),
          const SizedBox(height: 14),
          _fieldRow('Arrondissement', _districtCtrl, '1er arrondissement'),
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
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
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
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext ctx) {
    if (widget.isChange) {
      if (!widget.provider.verifyPassword(_currentCtrl.text)) {
        AppUtils.showSnackBar(ctx, 'Mot de passe actuel incorrect', isError: true);
        return;
      }
    }
    if (_newCtrl.text.length < 6) {
      AppUtils.showSnackBar(ctx, 'Le mot de passe doit faire au moins 6 caractères', isError: true);
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      AppUtils.showSnackBar(ctx, 'Les mots de passe ne correspondent pas', isError: true);
      return;
    }
    widget.provider.setAppLock(true, password: _newCtrl.text);
    AppUtils.showSnackBar(ctx, widget.isChange ? 'Mot de passe modifié' : 'Verrouillage activé');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: widget.isChange ? 'Changer le mot de passe' : 'Définir un mot de passe',
      icon: Icons.lock_outline,
      iconColor: AppColors.info,
      child: Column(
        children: [
          if (widget.isChange) ...[
            _passwordField('Mot de passe actuel', _currentCtrl, _obscureCurrent,
              () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 14),
          ],
          _passwordField('Nouveau mot de passe', _newCtrl, _obscureNew,
            () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 14),
          _passwordField('Confirmer le mot de passe', _confirmCtrl, _obscureConfirm,
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

  Widget _passwordField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Patient Activation Sheet ───
class _PatientActivationSheet extends StatefulWidget {
  final AppProvider provider;
  const _PatientActivationSheet({required this.provider});

  @override
  State<_PatientActivationSheet> createState() => _PatientActivationSheetState();
}

class _PatientActivationSheetState extends State<_PatientActivationSheet> {
  String _disease = 'hypertension';
  final _doctorEmailCtrl = TextEditingController();
  final _hospitalCtrl    = TextEditingController();
  int _step = 1; // 1 = form, 2 = success/pending

  @override
  void dispose() {
    _doctorEmailCtrl.dispose(); _hospitalCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (_doctorEmailCtrl.text.isEmpty) {
      AppUtils.showSnackBar(ctx, 'L\'email du médecin est obligatoire', isError: true);
      return;
    }
    setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Activation mode patient',
      icon: Icons.medical_services_outlined,
      iconColor: AppColors.accent,
      child: _step == 1 ? _buildForm(context) : _buildSuccess(context),
    );
  }

  Widget _buildForm(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Expanded(child: Text(
                'La validation sera effectuée par votre médecin via l\'interface web.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('Maladie concernée', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _diseaseOption('hypertension', 'Hypertension', Icons.favorite, AppColors.hypertension)),
            const SizedBox(width: 10),
            Expanded(child: _diseaseOption('diabetes', 'Diabète', Icons.water_drop_outlined, AppColors.primary)),
          ],
        ),
        const SizedBox(height: 16),

        Text('Email du médecin', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
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

        Text('Hôpital / Clinique', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _hospitalCtrl,
          decoration: const InputDecoration(
            hintText: 'Ex: Hôpital de la Mère et de l\'Enfant',
            prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Documents à fournir', style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _docItem('Résultat de consultation'),
              _docItem('Ordonnance médicale'),
              _docItem('Reçu de consultation'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Soumettre la demande',
          onPressed: () => _submit(ctx),
          icon: Icons.send_outlined,
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext ctx) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 36),
        ),
        const SizedBox(height: 16),
        Text('Demande soumise !', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Text(
          'Votre demande a été envoyée à votre médecin. Vous recevrez une notification dès validation.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // For demo: instantly activate
        PrimaryButton(
          label: 'Simuler validation (démo)',
          onPressed: () {
            widget.provider.activatePatient(_disease);
            AppUtils.showSnackBar(ctx, 'Mode patient activé !');
            Navigator.pop(context);
          },
          icon: Icons.verified_user_outlined,
          color: AppColors.accent,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _diseaseOption(String value, String label, IconData icon, Color color) {
    final isSelected = _disease == value;
    return GestureDetector(
      onTap: () => setState(() => _disease = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textHint),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.body.copyWith(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  Widget _docItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.upload_file_outlined, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
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
    _weightCtrl = TextEditingController(text: u.weight?.toString() ?? '');
    _heightCtrl = TextEditingController(text: u.height?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext ctx) {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final updated = widget.provider.currentUser!.copyWith(weight: w, height: h);
    widget.provider.updateUser(updated);
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

  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
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
                  width: 40, height: 40,
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