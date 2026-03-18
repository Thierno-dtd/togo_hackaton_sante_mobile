import 'dart:isolate';
import 'dart:typed_data';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/models.dart';

// ════════════════════════════════════════════════════════════
// Callback global — appelé par AlarmManager même app fermée
// DOIT être top-level (pas dans une classe)
// ════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> params) async {
  // Déclencher le son et la notification plein écran
  await AlarmService._triggerAlarm(id, params);
}

// ════════════════════════════════════════════════════════════
// Service d'alarme
// ════════════════════════════════════════════════════════════
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const _alarmsKey = 'scheduled_alarms';
  static AudioPlayer? _audioPlayer;
  static bool _isRinging = false;

  // ── Initialisation ──
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Programmer une alarme médicament ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleMedicationAlarm(
    MedicationReminder medication,
    TimeOfDay time,
    int timeIndex,
  ) async {
    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year, now.month, now.day,
      time.hour, time.minute,
    );
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final alarmId = _medAlarmId(medication.id, timeIndex);
    final params = {
      'type': 'medication',
      'title': '💊 Prise de médicament',
      'body': '${medication.medicationName} ${medication.dosage}',
      'medication_id': medication.id,
      'medication_name': medication.medicationName,
      'dosage': medication.dosage,
    };

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      alarmId,
      alarmCallback,
      startAt: alarmTime,
      exact: true,
      wakeup: true,         // ← réveille l'appareil même en veille
      rescheduleOnReboot: true, // ← reprogramme après redémarrage
      params: params,
    );

    await _saveAlarmParams(alarmId, params);
    debugPrint('Alarme médicament programmée: ${medication.medicationName} à ${time.hour}:${time.minute}');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Programmer une alarme rappel simple ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleSimpleAlarm(SimpleReminder reminder) async {
    final alarmTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (alarmTime.isBefore(DateTime.now())) return;

    final alarmId = _simpleAlarmId(reminder.id);
    final params = {
      'type': 'simple',
      'title': '🔔 Rappel',
      'body': reminder.label,
      'reminder_id': reminder.id,
      'label': reminder.label,
    };

    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: params,
    );

    await _saveAlarmParams(alarmId, params);
    debugPrint('Alarme simple programmée: ${reminder.label} à $alarmTime');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Déclencher l'alarme (appelé depuis le callback) ───
  // ════════════════════════════════════════════════════════════
  static Future<void> _triggerAlarm(
      int id, Map<String, dynamic> params) async {
    _isRinging = true;

    // 1. Afficher une notification plein écran
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await plugin.show(
      id,
      params['title'] ?? 'Alarme',
      params['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel_persistent',
          'Alarmes',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,      // ← ouvre l'écran d'alarme
          ongoing: true,               // ← ne peut pas être swipée
          autoCancel: false,           // ← reste jusqu'à action
          playSound: false,            // on gère le son nous-mêmes
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 300, 500, 300, 500]),
          actions: [
            AndroidNotificationAction(
              'stop_alarm',
              'Arrêter',
              cancelNotification: true,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'snooze_alarm',
              'Snooze 10 min',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'alarm_${params['type']}_$id',
    );

    // 2. Démarrer le son persistant
    await _startSound();

    // 3. Vibration continue pendant max 5 minutes
    _startVibrationLoop();
  }

  static Future<void> _startSound() async {
    _audioPlayer?.dispose();
    _audioPlayer = AudioPlayer();

    // Utilise le son d'alarme du système ou un fichier local
    await _audioPlayer!.setReleaseMode(ReleaseMode.loop); // ← boucle infinie
    await _audioPlayer!.setVolume(1.0);

    try {
      // Son d'alarme local (à placer dans assets/sounds/alarm.mp3)
      await _audioPlayer!.play(AssetSource('sounds/alarm.mp3'));
    } catch (_) {
      // Fallback : son de notification système
      try {
        await _audioPlayer!.play(
          UrlSource('android.resource://com.example.lamesse_dama_mobile/raw/alarm'),
        );
      } catch (_) {
        // Dernier fallback : AudioPlayer avec un bip répété
        debugPrint('Son d\'alarme non trouvé — vibration uniquement');
      }
    }
  }

  static void _startVibrationLoop() async {
    // Vibration continue toutes les 2 secondes (max 5 min = 300s)
    int elapsed = 0;
    while (_isRinging && elapsed < 300) {
      await Future.delayed(const Duration(seconds: 2));
      elapsed += 2;
    }
    // Auto-stop après 5 minutes
    if (_isRinging) await stopAlarm();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Arrêter l'alarme ───
  // ════════════════════════════════════════════════════════════
  static Future<void> stopAlarm() async {
    _isRinging = false;
    await _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;

    // Annuler toutes les notifications d'alarme actives
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancelAll();
    debugPrint('Alarme arrêtée');
  }

  // ── Snooze 10 minutes ──
  static Future<void> snoozeAlarm(int originalId, Map<String, dynamic> params) async {
    await stopAlarm();
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

    await AndroidAlarmManager.oneShotAt(
      snoozeTime,
      originalId + 9000, // ID différent pour le snooze
      alarmCallback,
      exact: true,
      wakeup: true,
      params: params,
    );
    debugPrint('Snooze programmé à $snoozeTime');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Annulation ───
  // ════════════════════════════════════════════════════════════
  Future<void> cancelMedicationAlarms(MedicationReminder medication) async {
    for (var i = 0; i < medication.intakeTimes.length; i++) {
      await AndroidAlarmManager.cancel(_medAlarmId(medication.id, i));
    }
    debugPrint('Alarmes annulées: ${medication.medicationName}');
  }

  Future<void> cancelSimpleAlarm(String reminderId) async {
    await AndroidAlarmManager.cancel(_simpleAlarmId(reminderId));
  }

  Future<void> cancelAllAlarms() async {
    // Lire toutes les alarmes sauvegardées et les annuler
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alarmsKey);
    if (raw != null) {
      final ids = List<int>.from(jsonDecode(raw));
      for (final id in ids) {
        await AndroidAlarmManager.cancel(id);
      }
      await prefs.remove(_alarmsKey);
    }
    await stopAlarm();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Helpers ───
  // ════════════════════════════════════════════════════════════
  static bool get isRinging => _isRinging;

  Future<void> _saveAlarmParams(int id, Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_alarmsKey);
    final ids = existing != null
        ? List<int>.from(jsonDecode(existing))
        : <int>[];
    if (!ids.contains(id)) ids.add(id);
    await prefs.setString(_alarmsKey, jsonEncode(ids));

    // Sauvegarder aussi les params pour les actions (stop/snooze)
    await prefs.setString('alarm_params_$id', jsonEncode(params));
  }

  static Future<Map<String, dynamic>?> getAlarmParams(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('alarm_params_$id');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  int _medAlarmId(String id, int idx) => (id.hashCode.abs() % 90000) + idx;
  int _simpleAlarmId(String id) => (id.hashCode.abs() % 90000) + 2000;
}