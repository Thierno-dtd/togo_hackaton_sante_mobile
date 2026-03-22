// ═══════════════════════════════════════════════════════════
// FICHIER : lib/main.dart
// CORRECTIONS :
//   1. checkAutoLogin wrappé dans try/catch global pour éviter
//      que l'app reste bloquée sur le splash en release
//   2. SplashScreen avec timeout de sécurité (5 secondes max)
//   3. isLoggedIn/hasUser lus APRÈS checkAutoLogin via watch
//      pour que le widget se rebuild quand l'état change
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/app_provider.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/reminders/presentation/pages/reminders_page.dart';
import 'features/followup/presentation/pages/followup_page.dart';
import 'features/events/presentation/pages/events_page.dart';
import 'navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final provider = AppProvider();

  // FIX : wrap dans try/catch pour éviter crash silencieux en release
  try {
    await provider.initAppSettings();
  } catch (e) {
    debugPrint('initAppSettings error: $e');
  }

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const LamesseDamaApp(),
    ),
  );
}

class LamesseDamaApp extends StatelessWidget {
  const LamesseDamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppProvider, ThemeMode>(
      (p) => p.themeMode,
    );

    return MaterialApp(
      title: 'Lamesse Dama',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      navigatorKey: AppProvider.navigatorKey,
      routes: {
        '/settings': (_) => const SettingsPage(),
        '/notifications': (_) => const NotificationsPage(),
        '/reminders': (_) => const RemindersPage(),
        '/followup': (_) => const FollowUpPage(),
        '/events': (_) => const EventsPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const MainNavigation(),
      },
      // FIX : utiliser _AuthGate qui gère checkAutoLogin de façon sécurisée
      home: const _AuthGate(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── Auth Gate : gère le checkAutoLogin de façon robuste ───
// ════════════════════════════════════════════════════════════
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _isChecking = true;
  bool _autoLoginSuccess = false;

  @override
  void initState() {
    super.initState();
    _doAutoLogin();
  }

  Future<void> _doAutoLogin() async {
    final provider = context.read<AppProvider>();

    // Timeout de sécurité : 5 secondes max pour éviter le splash infini
    bool timedOut = false;
    final timeout = Future.delayed(const Duration(seconds: 5), () {
      timedOut = true;
    });

    bool success = false;
    try {
      // Race entre checkAutoLogin et le timeout
      await Future.any([
        provider.checkAutoLogin().then((v) => success = v),
        timeout,
      ]);
    } catch (e) {
      debugPrint('checkAutoLogin error (release): $e');
      success = false;
    }

    if (timedOut) {
      debugPrint('⚠️ checkAutoLogin timeout — redirection vers login');
    }

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _autoLoginSuccess = success && !timedOut;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le check → splash minimaliste
    if (_isChecking) {
      return const _SplashScreen();
    }

    // Une fois le check terminé
    if (_autoLoginSuccess) {
      return const _AppLockGate();
    }
    return const LoginPage();
  }
}

// ════════════════════════════════════════════════════════════
// ─── Splash Screen ───
// ════════════════════════════════════════════════════════════
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.monitor_heart,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lamesse Dama',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ─── App Lock Gate ───
// ════════════════════════════════════════════════════════════
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Demander l'exemption batterie
      try {
        NotificationService.requestBatteryOptimizationExemption();
      } catch (_) {}

      final provider = context.read<AppProvider>();
      if (provider.appLockEnabled) {
        setState(() => _isLocked = true);
      }

      // Vérifier si l'app a été lancée depuis une notification
      try {
        final plugin = FlutterLocalNotificationsPlugin();
        final details = await plugin.getNotificationAppLaunchDetails();
        if (details?.didNotificationLaunchApp == true) {
          final response = details!.notificationResponse;
          if (response != null) {
            _handleNotificationResponse(response);
          }
        }
      } catch (e) {
        debugPrint('notification launch details error: $e');
      }
    });
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '';
    final actionId = response.actionId ?? '';

    if (payload.isNotEmpty) {
      final model = payloadToNotificationModel(payload);
      if (model != null) {
        final ctx = AppProvider.navigatorKey.currentContext;
        if (ctx != null) {
          ctx.read<AppProvider>().addNotification(model);
        }
      }
    }

    if (actionId == 'stop_alarm' ||
        actionId == 'taken' ||
        actionId == 'done') {
      AlarmService.stopAlarm();
      return;
    }

    if (actionId == 'snooze' || actionId == 'snooze_alarm') return;

    if (payload.isNotEmpty) _routeFromPayload(payload);
  }

  void _routeFromPayload(String payload) {
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';

    switch (type) {
      case 'medication':
      case 'medication_reminder':
        MainNavigation.goToTab(4, subTabIndex: 1);
        break;
      case 'simple':
      case 'simple_reminder':
        MainNavigation.goToTab(4, subTabIndex: 2);
        break;
      case 'screening':
        MainNavigation.goToTab(4, subTabIndex: 0);
        break;
      case 'renewal':
        MainNavigation.goToTab(4, subTabIndex: 1);
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final provider = context.read<AppProvider>();

    if (state == AppLifecycleState.resumed) {
      try {
        provider.consumePendingBackgroundNotifications();
      } catch (e) {
        debugPrint('consumePending error: $e');
      }
    }
    if (!provider.appLockEnabled) return;
    if (state == AppLifecycleState.paused && provider.appLockEnabled) {
      setState(() => _isLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (_isLocked && provider.appLockEnabled) {
      return _AppLockScreen(onUnlock: () => setState(() => _isLocked = false));
    }
    return const MainNavigation();
  }
}

// ════════════════════════════════════════════════════════════
// ─── App Lock Screen ───
// ════════════════════════════════════════════════════════════
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
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                32,
                32,
                32,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                      child: const Icon(
                        Icons.monitor_heart_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Application verrouillée',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.textPrimary,
                      ),
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
                            size: 18,
                          ),
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                      onPressed: () =>
                          context.read<AppProvider>().logout(),
                      child: Text(
                        'Se déconnecter',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}