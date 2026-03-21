import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../services/app_provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final _authService = AuthService();

  // ── Controllers login ──
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;

  // ── Controllers register ──
  final _regFirstNameCtrl = TextEditingController();
  final _regLastNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  final _regResidenceCtrl = TextEditingController();
  final _regDistrictCtrl = TextEditingController();
  DateTime _regDateOfBirth = DateTime(1990, 1, 1);
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regFirstNameCtrl.dispose();
    _regLastNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _regResidenceCtrl.dispose();
    _regDistrictCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loginEmailCtrl.text.trim().isEmpty ||
          _loginPassCtrl.text.trim().isEmpty) {
        _showMessage('Veuillez remplir tous les champs', isError: true);
        return;
      }

      if (!_loginEmailCtrl.text.contains('@')) {
        _showMessage('Email invalide', isError: true);
        return;
      }

    setState(() => _isLoading = true);
    final result = await _authService.loginWithEmail(
      email: _loginEmailCtrl.text,
      password: _loginPassCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      _showMessage(result.message ?? 'Connexion réussie !', isError: false);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.read<AppProvider>().initWithUser(result.user!);
    } else {
      _showMessage(result.message ?? 'Erreur de connexion', isError: true);
    }
  }

  Future<void> _handleRegister() async {
    if (_regFirstNameCtrl.text.trim().isEmpty ||
          _regLastNameCtrl.text.trim().isEmpty ||
          _regEmailCtrl.text.trim().isEmpty ||
          _regPhoneCtrl.text.trim().isEmpty ||
          _regPassCtrl.text.trim().isEmpty ||
          _regConfirmPassCtrl.text.trim().isEmpty) {
        _showMessage('Veuillez remplir tous les champs obligatoires', isError: true);
        return;
      }

      if (!_regEmailCtrl.text.contains('@')) {
        _showMessage('Email invalide', isError: true);
        return;
      }

      if (_regPassCtrl.text.length < 6) {
        _showMessage('Mot de passe trop court (min 6 caractères)', isError: true);
        return;
      }

      if (_regPassCtrl.text != _regConfirmPassCtrl.text) {
        _showMessage('Les mots de passe ne correspondent pas', isError: true);
        return;
      }

      if (_regPhoneCtrl.text.length < 8) {
        _showMessage('Numéro de téléphone invalide', isError: true);
        return;
      }

    setState(() => _isLoading = true);
    final result = await _authService.register(
      firstName: _regFirstNameCtrl.text,
      lastName: _regLastNameCtrl.text,
      email: _regEmailCtrl.text,
      phone: _regPhoneCtrl.text,
      password: _regPassCtrl.text,
      confirmPassword: _regConfirmPassCtrl.text,
      dateOfBirth: _regDateOfBirth,
      residence: _regResidenceCtrl.text,
      district: _regDistrictCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      _showMessage(result.message ?? 'Compte créé !', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.read<AppProvider>().initWithUser(result.user!);
    } else {
      _showMessage(result.message ?? 'Erreur lors de l\'inscription', isError: true);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    final result = await _authService.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.success && result.user != null) {
      _showMessage(result.message ?? 'Connexion réussie !', isError: false);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.read<AppProvider>().initWithUser(result.user!);
    } else {
      _showMessage(result.message ?? 'Erreur Google', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 100;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header — masqué quand le clavier est ouvert ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: keyboardVisible ? 0 : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: keyboardVisible ? 0 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.monitor_heart,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text('Lamesse Dama',
                            style: AppTextStyles.h1.copyWith(
                                color: Colors.white, fontSize: 24)),
                        const SizedBox(height: 4),
                        Text('Prévenir et mieux guérir',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Form card — prend tout l'espace restant ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBackground : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      28,
                      28,
                      MediaQuery.of(context).viewInsets.bottom + 28,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _isRegisterMode
                          ? _buildRegisterForm(isDark)
                          : _buildLoginForm(isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Formulaire de connexion ───
  // ════════════════════════════════════════════════════════════
  Widget _buildLoginForm(bool isDark) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.login, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text('Connectez-vous à votre compte', style: AppTextStyles.bodySmall),
        const SizedBox(height: 28),

        // Email
        _inputField(
          controller: _loginEmailCtrl,
          label: 'Email',
          hint: 'exemple@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        // Password
        _passwordField(
          controller: _loginPassCtrl,
          label: 'Mot de passe',
          obscure: _loginObscure,
          onToggle: () => setState(() => _loginObscure = !_loginObscure),
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showForgotPasswordSheet(),
            child: Text(AppStrings.forgotPassword,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 16),

        PrimaryButton(
          label: _isLoading ? 'Connexion en cours...' : AppStrings.login,
          onPressed: _handleLogin,
          icon: _isLoading ? null : Icons.login,
          color: _isLoading ? AppColors.textHint : AppColors.primary ,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),

        // Séparateur
        _divider(),
        const SizedBox(height: 16),

        // Google
        _googleButton(),
        const SizedBox(height: 15),

        // Switch vers inscription
        _switchModeRow(),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Formulaire d'inscription ───
  // ════════════════════════════════════════════════════════════
  Widget _buildRegisterForm(bool isDark) {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.register, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text('Créez votre compte santé', style: AppTextStyles.bodySmall),
        const SizedBox(height: 24),

        // Prénom + Nom
        Row(
          children: [
            Expanded(
              child: _inputField(
                controller: _regFirstNameCtrl,
                label: 'Prénom *',
                hint: 'Jean',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _regLastNameCtrl,
                label: 'Nom *',
                hint: 'Dupont',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Email
        _inputField(
          controller: _regEmailCtrl,
          label: 'Email *',
          hint: 'exemple@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // Téléphone
        _inputField(
          controller: _regPhoneCtrl,
          label: 'Téléphone *',
          hint: '+228 90 00 00 00',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        // Date de naissance
        _dateOfBirthPicker(isDark),
        const SizedBox(height: 14),

        // Ville + Quartier
        Row(
          children: [
            Expanded(
              child: _inputField(
                controller: _regResidenceCtrl,
                label: 'Ville',
                hint: 'Lomé',
                icon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _regDistrictCtrl,
                label: 'Quartier',
                hint: 'Bè Kpota',
                icon: Icons.map_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Mot de passe
        _passwordField(
          controller: _regPassCtrl,
          label: 'Mot de passe *',
          hint: 'Min. 6 caractères',
          obscure: _regObscure,
          onToggle: () => setState(() => _regObscure = !_regObscure),
        ),
        const SizedBox(height: 14),

        // Confirmer mot de passe
        _passwordField(
          controller: _regConfirmPassCtrl,
          label: 'Confirmer le mot de passe *',
          hint: '••••••',
          obscure: _regConfirmObscure,
          onToggle: () =>
              setState(() => _regConfirmObscure = !_regConfirmObscure),
        ),
        const SizedBox(height: 24),

        PrimaryButton(
          label: AppStrings.register,
          onPressed: _handleRegister,
          isLoading: _isLoading,
          icon: Icons.person_add_outlined,
        ),
        const SizedBox(height: 16),

        _divider(),
        const SizedBox(height: 16),

        _googleButton(),
        const SizedBox(height: 20),

        _switchModeRow(),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Widgets réutilisables ───
  // ════════════════════════════════════════════════════════════

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    String hint = '••••••',
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateOfBirthPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date de naissance *',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _regDateOfBirth,
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
              helpText: 'Date de naissance',
            );
            if (picked != null) setState(() => _regDateOfBirth = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_regDateOfBirth),
                  style: AppTextStyles.body,
                ),
                const Spacer(),
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AppColors.border),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Google SVG simplifié
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4285F4),
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(AppStrings.signInWithGoogle,
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.textPrimary)),
                ],
              ),
      ),
    );
  }

  Widget _switchModeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegisterMode
              ? AppStrings.alreadyHaveAccount
              : AppStrings.noAccount,
          style: AppTextStyles.bodySmall,
        ),
        TextButton(
          onPressed: () => setState(() {
            _isRegisterMode = !_isRegisterMode;
            ScaffoldMessenger.of(context).clearSnackBars();
          }),
          child: Text(
            _isRegisterMode ? AppStrings.login : AppStrings.register,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mot de passe oublié ───
  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ForgotPasswordSheet(
        onMessage: (msg, isError) => _showMessage(msg, isError: isError),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ════════════════════════════════════════════════════════════
// ─── Mot de passe oublié ───
// ════════════════════════════════════════════════════════════
class _ForgotPasswordSheet extends StatefulWidget {
  final void Function(String, bool) onMessage;
  const _ForgotPasswordSheet({required this.onMessage});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_emailCtrl.text.trim().isEmpty) {
      widget.onMessage('Veuillez entrer votre adresse email.', true);
      return;
    }
    // En prod → envoyer un email de réinitialisation
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: _sent
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.email_outlined,
                            color: AppColors.success, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text('Email envoyé !', style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Si un compte existe pour ${_emailCtrl.text}, '
                        'vous recevrez un lien de réinitialisation.',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Fermer',
                        onPressed: () => Navigator.pop(context),
                        color: AppColors.accent,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock_reset,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mot de passe oublié',
                                    style: AppTextStyles.h4),
                                Text(
                                    'Recevez un lien de réinitialisation',
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
                      const SizedBox(height: 20),
                      Text('Adresse email',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'exemple@email.com',
                          prefixIcon:
                              Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Envoyer le lien',
                        onPressed: _send,
                        icon: Icons.send_outlined,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}