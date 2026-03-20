import 'dart:typed_data';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import '../data/models/models.dart';

const _alarmsKey = 'scheduled_alarms';
const _alarmChannel =
    MethodChannel('com.example.lamesse_dama_mobile/alarm');

// ════════════════════════════════════════════════════════════
// Callback global — s'exécute même app fermée
// DOIT être top-level
// ════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  // Log immédiat pour confirmer l'exécution
  print('🚨 alarmCallback EXÉCUTÉ id=$id');
  
  final prefs = await SharedPreferences.getInstance();
  // Marque que le callback a été appelé
  await prefs.setString('last_alarm_triggered', 
      'id=$id at ${DateTime.now()}');
  
  final params = await AlarmService.getAlarmParams(id);
  if (params == null) {
    print('❌ Params null pour id=$id');
    return;
  }
  
  print('📦 Params: $params');
  await AlarmService.showAlarmNotification(id, params);
  print('✅ showAlarmNotification terminé');
}


class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static bool _isRinging = false;
  static bool get isRinging => _isRinging;

  // ════════════════════════════════════════════════════════════
  // ─── Afficher la notification (appelé depuis le callback) ──
  // ════════════════════════════════════════════════════════════
  static Future<void> showAlarmNotification(
      int id, Map<String, dynamic> params) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final ap = plugin.resolvePlatformSpecificImplementation< AndroidFlutterLocalNotificationsPlugin>();

    await ap?.createNotificationChannel(const AndroidNotificationChannel(
      'alarm_channel',
      'Alarmes',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
    ));

    await plugin.show(
      id,
      params['title'] ?? 'Alarme',
      params['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarmes',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
          vibrationPattern:
              Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          actions: [
            const AndroidNotificationAction(
              'stop_alarm', '⏹ Arrêter',
              cancelNotification: true,
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'snooze_alarm', '⏰ Snooze 10min',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: 'alarm.mp3',
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'alarm|${params['type']}|$id',
    );

    _isRinging = true;
    debugPrint('🔔 Notification alarme affichée: ${params['title']}');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Programmer alarme médicament ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleMedicationAlarm(
    MedicationReminder medication,
    TimeOfDay time,
    int timeIndex,
  ) async {
    final now = DateTime.now();
    var alarmTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final alarmId = _medAlarmId(medication.id, timeIndex);
    final params = {
      'type': 'medication',
      'title': '💊 Prise de médicament',
      'body': '${medication.medicationName} ${medication.dosage}',
      'medication_id': medication.id,
    };

    await _saveAlarmParams(alarmId, params);

    // Répétition quotidienne via AlarmManager
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      alarmId,
      alarmCallback,
      startAt: alarmTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    debugPrint(
        '✅ Alarme médicament: ${medication.medicationName} à ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Programmer alarme rappel simple ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleSimpleAlarm(SimpleReminder reminder) async {
    final alarmTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (alarmTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Rappel dans le passé ignoré: ${reminder.label}');
      return;
    }

    final alarmId = _simpleAlarmId(reminder.id);
    final params = {
      'type': 'simple',
      'title': '🔔 Rappel',
      'body': reminder.label,
      'reminder_id': reminder.id,
    };

    await _saveAlarmParams(alarmId, params);

    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    debugPrint(
        '✅ Alarme simple: ${reminder.label} à $alarmTime');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Son natif ───
  // ════════════════════════════════════════════════════════════
  static Future<void> startNativeAlarm({
    required String title,
    required String body,
    required String type,
  }) async {
    _isRinging = true;
    try {
      await _alarmChannel.invokeMethod('startAlarm', {
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      debugPrint('startNativeAlarm error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Arrêter ───
  // ════════════════════════════════════════════════════════════
  static Future<void> stopAlarm() async {
    _isRinging = false;
    try {
      await _alarmChannel.invokeMethod('stopAlarm');
    } catch (e) {
      debugPrint('stopAlarm error: $e');
    }
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancelAll();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Snooze ───
  // ════════════════════════════════════════════════════════════
  static Future<void> snoozeAlarm(
      int originalId, Map<String, dynamic> params) async {
    await stopAlarm();
    final snoozeTime =
        DateTime.now().add(const Duration(minutes: 10));
    final snoozeId = originalId + 9000;

    await _saveAlarmParamsStatic(snoozeId, params);

    await AndroidAlarmManager.oneShotAt(
      snoozeTime,
      snoozeId,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
    debugPrint('⏰ Snooze dans 10 minutes');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Annulation ───
  // ════════════════════════════════════════════════════════════
  Future<void> cancelMedicationAlarms(MedicationReminder medication) async {
    for (var i = 0; i < medication.intakeTimes.length; i++) {
      await AndroidAlarmManager.cancel(_medAlarmId(medication.id, i));
    }
  }

  Future<void> cancelSimpleAlarm(String reminderId) async {
    await AndroidAlarmManager.cancel(_simpleAlarmId(reminderId));
  }

  // ════════════════════════════════════════════════════════════
  // ─── Helpers ───
  // ════════════════════════════════════════════════════════════
  Future<void> _saveAlarmParams(
      int id, Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_alarmsKey);
    final ids = existing != null
        ? List<int>.from(jsonDecode(existing))
        : <int>[];
    if (!ids.contains(id)) ids.add(id);
    await prefs.setString(_alarmsKey, jsonEncode(ids));
    await prefs.setString('alarm_params_$id', jsonEncode(params));
  }

  static Future<void> _saveAlarmParamsStatic(
      int id, Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_params_$id', jsonEncode(params));
  }

  static Future<Map<String, dynamic>?> getAlarmParams(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('alarm_params_$id');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  int _medAlarmId(String id, int idx) =>
      (id.hashCode.abs() % 80000) + idx;
  int _simpleAlarmId(String id) =>
      (id.hashCode.abs() % 80000) + 2000;
}