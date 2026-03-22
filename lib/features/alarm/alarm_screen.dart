// ═══════════════════════════════════════════════════════════
// FICHIER : lib/features/alarm/alarm_screen.dart
// CORRECTION : écouter AppLifecycleState pour relâcher le
// wakelock et l'immersive mode quand le tel se verrouille
// ═══════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../services/alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  final String title;
  final String body;
  final int alarmId;
  final Map<String, dynamic> params;

  const AlarmScreen({
    super.key,
    required this.title,
    required this.body,
    required this.alarmId,
    required this.params,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late Timer _timeTimer;
  String _currentTime = '';
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();

    // FIX : observer pour détecter le verrouillage
    WidgetsBinding.instance.addObserver(this);

    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    AlarmService.startNativeAlarm(
      title: widget.title,
      body: widget.body,
      type: widget.params['type'] ?? 'simple',
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _updateTime();
    _timeTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  // FIX : écouter les changements de cycle de vie
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Le téléphone se verrouille ou l'app passe en arrière-plan
      // → relâcher l'immersive mode et le wakelock
      _releaseScreen();
    } else if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan (ex: alarme toujours active)
      if (!_isStopping) {
        WakelockPlus.enable();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }
  }

  void _releaseScreen() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _stopAlarm() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);
    _releaseScreen();
    await AlarmService.stopAlarm();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);
    _releaseScreen();
    await AlarmService.snoozeAlarm(widget.alarmId, widget.params);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose();
    _timeTimer.cancel();
    _releaseScreen(); // toujours relâcher au dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMedication = widget.params['type'] == 'medication';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isMedication
            ? const Color(0xFF0D2030)
            : const Color(0xFF0A2218),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Heure ──
              Text(
                _currentTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _dayLabel(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),

              const Spacer(),

              // ── Icône pulsante ──
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: _pulse.value,
                  child: child,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isMedication
                            ? AppColors.hypertension
                            : AppColors.accent)
                        .withOpacity(0.15),
                    border: Border.all(
                      color: (isMedication
                              ? AppColors.hypertension
                              : AppColors.accent)
                          .withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isMedication ? Icons.medication : Icons.alarm,
                    color: isMedication
                        ? AppColors.hypertension
                        : AppColors.accent,
                    size: 52,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                widget.body,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Boutons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _snooze,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.snooze,
                                  color: Colors.white, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                'Snooze',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                '10 min',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _stopAlarm,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: isMedication
                                ? AppColors.hypertension
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isMedication
                                        ? AppColors.hypertension
                                        : AppColors.accent)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.alarm_off,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Arrêter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              Text(
                'Appuyez sur Arrêter pour stopper l\'alarme',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _dayLabel() {
    final now = DateTime.now();
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }
}