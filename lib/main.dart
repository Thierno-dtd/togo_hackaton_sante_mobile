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
  await provider.initAppSettings();
  await provider.checkAutoLogin();

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
    final isLoggedIn = context.read<AppProvider>().isLoggedIn;
    final hasUser = context.read<AppProvider>().currentUser != null;

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
      home: isLoggedIn && hasUser
          ? const _AppLockGate()  
          : const LoginPage(),
    );
  }
}

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
    //_initNotificationListener();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationService.requestBatteryOptimizationExemption();

    final provider = context.read<AppProvider>();
    if (provider.appLockEnabled) {
      setState(() => _isLocked = true);
    }

    final plugin = FlutterLocalNotificationsPlugin();
    final details = await plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final response = details!.notificationResponse;
      if (response != null) {
        _handleNotificationResponse(response);
      }
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

    if (actionId == 'stop_alarm' || actionId == 'taken' || actionId == 'done') {
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
        provider.consumePendingBackgroundNotifications();
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔷 ICON
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

                    // 🔷 TITRE
                    Text(
                      'Application verrouillée',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 🔷 DESCRIPTION
                    Text(
                      'Entrez votre mot de passe pour continuer',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // 🔷 INPUT
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

                    // 🔷 BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _tryUnlock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.lock_open_outlined,
                          size: 18,
                        ),
                        label: Text(
                          'Déverrouiller',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔷 LOGOUT
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