import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../services/app_provider.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController(text: 'bima.afi@email.com');
  final _passCtrl = TextEditingController(text: 'password123');
  bool _obscure = true;
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      final user = _emailCtrl.text.contains('bima') ? MockData.mockUser : MockData.mockNonPatientUser;
      context.read<AppProvider>().initWithUser(user);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight, AppColors.primary.withOpacity(0.9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.monitor_heart, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text('Lamesse Dama', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 26)),
                    const SizedBox(height: 6),
                    Text('Votre santé, notre priorité', style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),

              // Form card
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRegisterMode ? AppStrings.register : AppStrings.login,
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRegisterMode ? 'Créez votre compte santé' : 'Connectez-vous à votre compte',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 28),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (!_isRegisterMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(AppStrings.forgotPassword, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                            ),
                          ),
                        const SizedBox(height: 20),

                        PrimaryButton(
                          label: _isRegisterMode ? AppStrings.register : AppStrings.login,
                          onPressed: _login,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Google sign in
                        OutlinedButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: Text(AppStrings.signInWithGoogle, style: AppTextStyles.button),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isRegisterMode ? AppStrings.alreadyHaveAccount : AppStrings.noAccount,
                              style: AppTextStyles.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                              child: Text(
                                _isRegisterMode ? AppStrings.login : AppStrings.register,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}