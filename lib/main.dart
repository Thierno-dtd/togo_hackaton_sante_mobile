import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lamesse_dama_mobile/features/events/presentation/pages/events_page.dart';
import 'package:lamesse_dama_mobile/features/followup/presentation/pages/followup_page.dart';
import 'package:lamesse_dama_mobile/features/reminders/presentation/pages/reminders_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/app_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'navigation/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const LamesseDamaApp(),
    ),
  );
}

class LamesseDamaApp extends StatelessWidget {
  const LamesseDamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Lamesse Dama',
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routes: {
        '/settings': (_) => const SettingsPage(),
         '/notifications': (_) => const NotificationsPage(),
         '/reminders': (_) => const RemindersPage(),
         '/followup': (_) => const FollowUpPage(),
         '/events': (_) => const EventsPage(),
      },
      home: _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (!provider.isLoggedIn) {
      return const LoginPage();
    }

    return const _AppLockGate();
  }
}

// ─── App Lock Gate ───
class _AppLockGate extends StatefulWidget {
  const _AppLockGate();

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate>
    with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<AppProvider>();
    if (state == AppLifecycleState.paused && provider.appLockEnabled) {
      setState(() => _isLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (_isLocked && provider.appLockEnabled) {
      return _AppLockScreen(
          onUnlock: () => setState(() => _isLocked = false));
    }
    return const MainNavigation();
  }
}

// ─── App Lock Screen ───
class _AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const _AppLockScreen({required this.onUnlock});

  @override
  State<_AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<_AppLockScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _tryUnlock() {
    final provider = context.read<AppProvider>();
    if (provider.verifyPassword(_passwordCtrl.text)) {
      widget.onUnlock();
    } else {
      setState(() {
        _error = 'Mot de passe incorrect';
        _passwordCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1e4060)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Application verrouillée',
                style: AppTextStyles.h3.copyWith(
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre mot de passe pour continuer',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                onSubmitted: (_) => _tryUnlock(),
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon:
                      const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18),
                  ),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _tryUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.lock_open_outlined, size: 18),
                  label: Text(
                    'Déverrouiller',
                    style: AppTextStyles.button
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<AppProvider>().logout(),
                child: Text(
                  'Se déconnecter',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}