// lib/features/alarm/alarm_screen.dart
// Écran plein écran qui s'affiche quand l'alarme sonne

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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late Timer _timeTimer;
  String _currentTime = '';
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();

    // Garder l'écran allumé
    WakelockPlus.enable();

    // Forcer l'orientation portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Masquer la barre de statut
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Animation pulsation
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Heure courante
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _stopAlarm() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);
    await AlarmService.stopAlarm();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);
    await AlarmService.snoozeAlarm(widget.alarmId, widget.params);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timeTimer.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMedication = widget.params['type'] == 'medication';

    return WillPopScope(
      onWillPop: () async => false, // Bloquer le bouton retour
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

              // ── Titre ──
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

              // ── Description ──
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
                    // Snooze
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

                    // Arrêter — bouton principal
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

              // Indication swipe
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