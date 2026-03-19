import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import '../data/models/models.dart';
import '../data/models/notification_model.dart';

const _pendingNotifKey = 'pending_notifications';

@pragma('vm:entry-point')
void onBackgroundNotification(NotificationResponse response) async {
  if (response.payload == null) return;
  final model = _payloadToNotificationModel(response.payload!);
  if (model == null) return;
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_pendingNotifKey);
  final list = existing != null
      ? List<Map<String, dynamic>>.from(jsonDecode(existing))
      : <Map<String, dynamic>>[];
  list.add(_notifModelToMap(model));
  await prefs.setString(_pendingNotifKey, jsonEncode(list));
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  void Function(NotificationModel)? onNotificationReceived;

  static const _alarmMedChannel = AndroidNotificationChannel(
    'alarm_medication_channel', 'Alarmes médicaments',
    importance: Importance.max, playSound: true, enableVibration: true,
    enableLights: true, ledColor: Color(0xFF163344),
  );
  static const _alarmReminderChannel = AndroidNotificationChannel(
    'alarm_reminder_channel', 'Alarmes rappels',
    importance: Importance.max, playSound: true, enableVibration: true,
    enableLights: true, ledColor: Color(0xFF10B981),
  );
  static const _notifChannel = AndroidNotificationChannel(
    'notif_channel', 'Notifications santé',
    importance: Importance.high, playSound: true,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Lome'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: _onForeground,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotification,
    );

    final ap = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await ap?.createNotificationChannel(_alarmMedChannel);
    await ap?.createNotificationChannel(_alarmReminderChannel);
    await ap?.createNotificationChannel(_notifChannel);
    await ap?.requestNotificationsPermission();
    await ap?.requestExactAlarmsPermission();
    _initialized = true;
  }

  void _onForeground(NotificationResponse response) {
    debugPrint('Foreground notif: ${response.payload}');
    if (response.payload == null) return;
    final model = _payloadToNotificationModel(response.payload!);
    if (model != null) onNotificationReceived?.call(model);
  }

  Future<List<NotificationModel>> consumePendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingNotifKey);
    if (raw == null) return [];
    await prefs.remove(_pendingNotifKey);
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw))
          .map(_mapToNotifModel).toList();
    } catch (_) { return []; }
  }

  Future<NotificationModel?> getAppLaunchNotification() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true &&
        details?.notificationResponse?.payload != null) {
      return _payloadToNotificationModel(details!.notificationResponse!.payload!);
    }
    return null;
  }

  Future<void> scheduleMedicationReminder(MedicationReminder medication, TimeOfDay time) async {
    await initialize();
    final idx = medication.intakeTimes.indexOf(time);
    await _plugin.zonedSchedule(
      _medId(medication.id, idx),
      'Prise de médicament',
      '${medication.medicationName} ${medication.dosage}',
      _nextTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alarmMedChannel.id, _alarmMedChannel.name,
          importance: Importance.max, priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          icon: '@mipmap/ic_launcher', color: const Color(0xFF163344),
          playSound: true, enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 1000]),
          fullScreenIntent: true, autoCancel: true,
          actions: const [
            AndroidNotificationAction('taken', 'Pris ✓', cancelNotification: true),
            AndroidNotificationAction('snooze', 'Snooze 10 min', cancelNotification: true),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication|${medication.id}|${medication.medicationName}|${medication.dosage}',
    );
  }

  Future<void> scheduleSimpleReminder(SimpleReminder reminder) async {
    await initialize();
    final d = tz.TZDateTime(tz.local,
      reminder.date.year, reminder.date.month, reminder.date.day,
      reminder.time.hour, reminder.time.minute,
    );
    if (d.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      _simpleId(reminder.id), 'Rappel', reminder.label, d,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alarmReminderChannel.id, _alarmReminderChannel.name,
          importance: Importance.max, priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          icon: '@mipmap/ic_launcher', color: const Color(0xFF10B981),
          playSound: true, enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 1000]),
          fullScreenIntent: true, autoCancel: true,
          actions: const [AndroidNotificationAction('done', 'OK ✓', cancelNotification: true)],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'simple|${reminder.id}|${reminder.label}',
    );
  }

  Future<void> scheduleRenewalAlert(MedicationReminder med) async {
    await initialize();
    if (!med.needsRenewal) return;
    await _plugin.show(
      _renewId(med.id),
      'Stock faible — ${med.medicationName}',
      'Il vous reste ${med.stock} unité(s). Pensez à renouveler.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _notifChannel.id, _notifChannel.name,
          importance: Importance.high, priority: Priority.high,
          color: const Color(0xFFF59E0B), icon: '@mipmap/ic_launcher', autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: 'renewal|${med.id}|${med.medicationName}',
    );
  }

  Future<void> scheduleScreeningReminder(ScreeningReminder reminder) async {
    await initialize();
    final daysUntil = reminder.dueDate.difference(DateTime.now()).inDays;
    if (daysUntil < 0 || reminder.isCompleted) return;
    for (final offset in [7, 1, 0].where((d) => daysUntil >= d)) {
      final nd = tz.TZDateTime(tz.local,
        reminder.dueDate.year, reminder.dueDate.month,
        reminder.dueDate.day - offset, 9, 0,
      );
      if (nd.isBefore(tz.TZDateTime.now(tz.local))) continue;
      final label = offset == 0 ? "Aujourd'hui" : offset == 1 ? 'Demain' : 'Dans $offset jours';
      await _plugin.zonedSchedule(
        _screeningId(reminder.id, offset),
        'Dépistage — $label',
        '${reminder.title}: ${reminder.description}',
        nd,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notifChannel.id, _notifChannel.name,
            importance: Importance.high, priority: Priority.high,
            color: const Color(0xFF3B82F6), icon: '@mipmap/ic_launcher', autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'screening|${reminder.id}|${reminder.title}',
      );
    }
  }

  Future<void> cancelMedicationReminders(MedicationReminder med) async {
    for (var i = 0; i < med.intakeTimes.length; i++) await _plugin.cancel(_medId(med.id, i));
    await _plugin.cancel(_renewId(med.id));
  }
  Future<void> cancelSimpleReminder(String id) async => await _plugin.cancel(_simpleId(id));
  Future<void> cancelScreeningReminder(String id) async {
    for (final d in [0, 1, 7]) await _plugin.cancel(_screeningId(id, d));
  }
  Future<void> cancelAll() async => await _plugin.cancelAll();

  tz.TZDateTime _nextTime(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var s = tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (s.isBefore(now)) s = s.add(const Duration(days: 1));
    return s;
  }

  int _medId(String id, int i) => id.hashCode.abs() % 90000 + i;
  int _renewId(String id) => id.hashCode.abs() % 90000 + 1000;
  int _simpleId(String id) => id.hashCode.abs() % 90000 + 2000;
  int _screeningId(String id, int d) => id.hashCode.abs() % 90000 + 3000 + d;
}

NotificationModel? _payloadToNotificationModel(String payload) {
  final p = payload.split('|');
  if (p.isEmpty) return null;
  final now = DateTime.now();
  final uid = '${payload}_${now.millisecondsSinceEpoch}';
  switch (p[0]) {
    case 'medication':
      final name = p.length > 2 ? p[2] : '';
      final dose = p.length > 3 ? p[3] : '';
      return NotificationModel(
        id: uid, title: 'Prise de médicament',
        body: name.isNotEmpty ? '$name $dose' : 'Il est temps de prendre votre médicament.',
        type: NotificationType.medicationReminder, createdAt: now,
      );
    case 'renewal':
      final name = p.length > 2 ? p[2] : '';
      return NotificationModel(
        id: uid, title: 'Stock faible — $name',
        body: 'Votre stock de $name est faible. Pensez à renouveler.',
        type: NotificationType.medicationRenewal, createdAt: now,
      );
    case 'simple':
      final label = p.length > 2 ? p[2] : 'Rappel';
      return NotificationModel(
        id: uid, title: 'Rappel', body: label,
        type: NotificationType.generalInfo, createdAt: now,
      );
    case 'screening':
      final title = p.length > 2 ? p[2] : 'Dépistage';
      return NotificationModel(
        id: uid, title: 'Dépistage', body: '$title prévu prochainement.',
        type: NotificationType.screeningReminder, createdAt: now,
      );
    default: return null;
  }
}

Map<String, dynamic> _notifModelToMap(NotificationModel n) => {
  'id': n.id, 'title': n.title, 'body': n.body,
  'type': n.type.index, 'createdAt': n.createdAt.toIso8601String(),
};

NotificationModel _mapToNotifModel(Map<String, dynamic> m) => NotificationModel(
  id: m['id'] ?? '', title: m['title'] ?? '', body: m['body'] ?? '',
  type: NotificationType.values[m['type'] ?? 0],
  createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
);

// ════════════════════════════════════════════════════════════
// ─── NOUVELLES MÉTHODES : rappel anticipé (avant l'alarme) ───
// ════════════════════════════════════════════════════════════

extension NotificationServiceExtension on NotificationService {

  /// Notification de rappel AVANT la prise (J-1 matin)
  /// L'alarme réelle est gérée par AlarmService à l'heure exacte
  Future<void> scheduleMedicationReminderNotification(
    MedicationReminder medication,
    TimeOfDay time, {
    int advanceDays = 1,
  }) async {
    await initialize();
    final idx = medication.intakeTimes.indexOf(time);
    final now = tz.TZDateTime.now(tz.local);

    // Rappel la veille à 9h
    final reminderDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      9, 0,
    ).add(Duration(days: advanceDays == 0 ? 0 : -1 + advanceDays));

    if (reminderDate.isBefore(now)) return;

    await _plugin.zonedSchedule(
      _medId(medication.id, idx) + 500, // ID différent de l'alarme
      '💊 Rappel médicament demain',
      '${medication.medicationName} ${medication.dosage} — à ${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
      reminderDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService._notifChannel.id, NotificationService._notifChannel.name,
          importance: Importance.high, priority: Priority.high,
          color: const Color(0xFF163344),
          icon: '@mipmap/ic_launcher', autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'medication_reminder|${medication.id}|${medication.medicationName}|${medication.dosage}',
    );
  }

  /// Notification de rappel AVANT le rappel simple (60 min avant)
  Future<void> scheduleSimpleReminderNotification(
    SimpleReminder reminder, {
    int advanceMinutes = 60,
  }) async {
    await initialize();

    final targetTime = DateTime(
      reminder.date.year, reminder.date.month, reminder.date.day,
      reminder.time.hour, reminder.time.minute,
    );
    final notifTime = targetTime.subtract(Duration(minutes: advanceMinutes));

    if (notifTime.isBefore(DateTime.now())) return;

    final tzNotifTime = tz.TZDateTime.from(notifTime, tz.local);

    await _plugin.zonedSchedule(
      _simpleId(reminder.id) + 500, // ID différent de l'alarme
      '🔔 Rappel dans ${advanceMinutes}min',
      reminder.label,
      tzNotifTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService._notifChannel.id, NotificationService._notifChannel.name,
          importance: Importance.high, priority: Priority.high,
          color: const Color(0xFF10B981),
          icon: '@mipmap/ic_launcher', autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'simple_reminder|${reminder.id}|${reminder.label}',
    );
  }
}