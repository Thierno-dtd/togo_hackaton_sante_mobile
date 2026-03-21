import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import '../data/models/models.dart';
import '../data/models/notification_model.dart';

const _pendingNotifKey = 'pending_notifications';

// ── Callback background — top-level obligatoire ──
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

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  void Function(NotificationModel)? onNotificationReceived;

  // ── Channels ──
  static const _alarmMedChannel = AndroidNotificationChannel(
    'alarm_medication_channel',
    'Alarmes médicaments',
    description: 'Rappels de prise de médicaments',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFF163344),
  );

  static const _alarmReminderChannel = AndroidNotificationChannel(
    'alarm_reminder_channel',
    'Alarmes rappels',
    description: 'Rappels et alarmes personnalisés',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFF10B981),
  );

  static const _notifChannel = AndroidNotificationChannel(
    'notif_channel',
    'Notifications santé',
    description: 'Notifications générales de santé',
    importance: Importance.high,
    playSound: true,
  );

  // ════════════════════════════════════════════════════════════
  // ─── Initialisation ───
  // ════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Lome'));

    // ── Paramètres Android ──
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── Paramètres iOS ──
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onForeground,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotification,
    );

    // ── Créer les channels Android ──
    final ap = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await ap?.createNotificationChannel(_alarmMedChannel);
    await ap?.createNotificationChannel(_alarmReminderChannel);
    await ap?.createNotificationChannel(_notifChannel);

    // ── Demander permissions ──
    final granted = await ap?.requestNotificationsPermission();
    debugPrint('🔔 Permission notifications: $granted');

    await ap?.requestExactAlarmsPermission();

    _initialized = true;
    debugPrint('✅ NotificationService initialisé');
  }

  // ── Handler foreground ──
  void _onForeground(NotificationResponse response) {
    debugPrint('📲 Notif foreground: ${response.payload}');
    if (response.payload == null) return;
    final model = _payloadToNotificationModel(response.payload!);
    if (model != null) onNotificationReceived?.call(model);
  }

  // ════════════════════════════════════════════════════════════
  // ─── Optimisation batterie ───
  // ════════════════════════════════════════════════════════════
  static Future<void> requestBatteryOptimizationExemption() async {
    try {
      const platform =
          MethodChannel('com.example.lamesse_dama_mobile/battery');
      await platform.invokeMethod('requestIgnoreBatteryOptimization');
      debugPrint('✅ Exemption batterie demandée');
    } catch (e) {
      debugPrint('Battery optimization error: $e');
    }
  }

  static Future<void> openAutoStartSettings() async {
    try {
      const platform =
          MethodChannel('com.example.lamesse_dama_mobile/battery');
      await platform.invokeMethod('openAutoStart');
    } catch (e) {
      debugPrint('AutoStart error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Notifications en attente (app fermée) ───
  // ════════════════════════════════════════════════════════════
  Future<List<NotificationModel>> consumePendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingNotifKey);
    if (raw == null) return [];
    await prefs.remove(_pendingNotifKey);
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw))
          .map(_mapToNotifModel)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Test ───
  // ════════════════════════════════════════════════════════════
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      999,
      '🔔 Test notification',
      'Les notifications fonctionnent !',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _notifChannel.id,
          _notifChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Médicament ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleMedicationReminder(
    MedicationReminder medication, TimeOfDay time, int timeIndex) async {
  await initialize();

  final now = DateTime.now();
  DateTime alarmTime = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );

  if (alarmTime.isBefore(now)) {
    alarmTime = alarmTime.add(const Duration(days: 1));
  }

  final tzTime = tz.TZDateTime.from(alarmTime, tz.local);

  await _plugin.zonedSchedule(
    _medId(medication.id, timeIndex),
    '💊 Prise de médicament',
    '${medication.medicationName} ${medication.dosage}',
    tzTime,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _alarmReminderChannel.id,
        _alarmReminderChannel.name,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF163344),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        autoCancel: true,
        actions: const [
          AndroidNotificationAction(
            'taken', 'Pris ✓',
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'snooze', 'Snooze 10 min',
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.alarmClock,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,

    matchDateTimeComponents: DateTimeComponents.time,
    payload:
        'medication|${medication.id}|${medication.medicationName}|${medication.dosage}',
  );

  debugPrint(
      '✅ Médicament schedulé: ${medication.medicationName} à ${time.hour}:${time.minute.toString().padLeft(2, '0')} — prochaine alarme: $alarmTime');
}


  // ════════════════════════════════════════════════════════════
  // ─── Rappel simple ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleSimpleReminder(SimpleReminder reminder) async {
    await initialize();

    final alarmTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (alarmTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Rappel passé ignoré: ${reminder.label}');
      return;
    }

    final tzTime = tz.TZDateTime.from(alarmTime, tz.local);

    await _plugin.zonedSchedule(
      _simpleId(reminder.id),
      '🔔 Rappel',
      reminder.label,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alarmReminderChannel.id,
          _alarmReminderChannel.name,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF10B981),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          autoCancel: true,
          actions: const [
            AndroidNotificationAction(
              'done', 'OK ✓',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'simple|${reminder.id}|${reminder.label}',
    );

    debugPrint('✅ Rappel simple schedulé: ${reminder.label} à $alarmTime');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Dépistage ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleScreeningReminder(ScreeningReminder reminder) async {
    await initialize();

    final daysUntil = reminder.dueDate.difference(DateTime.now()).inDays;
    if (daysUntil < 0 || reminder.isCompleted) return;

    for (final offset in [7, 1, 0]) {
      if (daysUntil < offset) continue;

      final notifDate = tz.TZDateTime(
        tz.local,
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day,
        9,
        0,
      ).subtract(Duration(days: offset));

      if (notifDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final label = offset == 0
          ? "Aujourd'hui"
          : offset == 1
              ? 'Demain'
              : 'Dans $offset jours';

      await _plugin.zonedSchedule(
        _screeningId(reminder.id, offset),
        '🏥 Dépistage — $label',
        '${reminder.title} : ${reminder.description}',
        notifDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notifChannel.id,
            _notifChannel.name,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF3B82F6),
            playSound: true,
            enableVibration: true,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'screening|${reminder.id}|${reminder.title}',
      );

      debugPrint(
          '✅ Dépistage schedulé: ${reminder.title} dans $offset jours');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Renouvellement ───
  // ════════════════════════════════════════════════════════════
 Future<void> scheduleRenewalAlert(MedicationReminder med) async {
  await initialize();
  if (!med.needsRenewal) return;

  // Vérifier si déjà montré aujourd'hui
  final prefs = await SharedPreferences.getInstance();
  final key = 'renewal_shown_${med.id}';
  final lastShown = prefs.getString(key);
  final today = DateTime.now().toIso8601String().split('T')[0];
  if (lastShown == today) return; // déjà montré aujourd'hui

  await prefs.setString(key, today);

  await _plugin.show(
    _renewId(med.id),
    '⚠️ Stock faible — ${med.medicationName}',
    'Il reste ${med.stock} unité(s). Pensez à renouveler.',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _notifChannel.id,
        _notifChannel.name,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFF59E0B),
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    ),
    payload: 'renewal|${med.id}|${med.medicationName}',
  );
}
  // ════════════════════════════════════════════════════════════
  // ─── Annulation ───
  // ════════════════════════════════════════════════════════════
  Future<void> cancelMedicationReminders(MedicationReminder med) async {
  for (var i = 0; i < med.intakeTimes.length; i++) {
    await _plugin.cancel(_medId(med.id, i));
  }
  await _plugin.cancel(_renewId(med.id));
}

  Future<void> cancelSimpleReminder(String id) async {
    await _plugin.cancel(_simpleId(id));
    await _plugin.cancel(_simpleId(id) + 500);
  }

  Future<void> cancelScreeningReminder(String id) async {
    for (final d in [0, 1, 7]) {
      await _plugin.cancel(_screeningId(id, d));
    }
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();

  // ════════════════════════════════════════════════════════════
  // ─── Helpers ───
  // ════════════════════════════════════════════════════════════
  tz.TZDateTime _nextTime(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var s = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (s.isBefore(now)) s = s.add(const Duration(days: 1));
    return s;
  }

  int _medId(String id, int i) => (id.hashCode.abs() % 10000) * 10 + i;
  int _renewId(String id) => id.hashCode.abs() % 90000 + 1000;
  int _simpleId(String id) => id.hashCode.abs() % 90000 + 2000;
  int _screeningId(String id, int d) => id.hashCode.abs() % 90000 + 3000 + d;
}

// ════════════════════════════════════════════════════════════
// ─── Helpers payload ───
// ════════════════════════════════════════════════════════════
NotificationModel? _payloadToNotificationModel(String payload) {
  final p = payload.split('|');
  if (p.isEmpty) return null;
  final now = DateTime.now();
  final uid = '${payload}_${now.millisecondsSinceEpoch}';

  switch (p[0]) {
    case 'medication':
    case 'medication_reminder':
      final name = p.length > 2 ? p[2] : '';
      final dose = p.length > 3 ? p[3] : '';
      return NotificationModel(
        id: uid,
        title: 'Prise de médicament',
        body: name.isNotEmpty
            ? '$name $dose'
            : 'Il est temps de prendre votre médicament.',
        type: NotificationType.medicationReminder,
        createdAt: now,
      );
    case 'renewal':
      final name = p.length > 2 ? p[2] : '';
      return NotificationModel(
        id: uid,
        title: 'Stock faible — $name',
        body: 'Votre stock de $name est faible. Pensez à renouveler.',
        type: NotificationType.medicationRenewal,
        createdAt: now,
      );
    case 'simple':
    case 'simple_reminder':
      final label = p.length > 2 ? p[2] : 'Rappel';
      return NotificationModel(
        id: uid,
        title: 'Rappel',
        body: label,
        type: NotificationType.generalInfo,
        createdAt: now,
      );
    case 'screening':
      final title = p.length > 2 ? p[2] : 'Dépistage';
      return NotificationModel(
        id: uid,
        title: 'Dépistage',
        body: '$title prévu prochainement.',
        type: NotificationType.screeningReminder,
        createdAt: now,
      );
    default:
      return null;
  }
}

Map<String, dynamic> _notifModelToMap(NotificationModel n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'type': n.type.index,
      'createdAt': n.createdAt.toIso8601String(),
    };

NotificationModel _mapToNotifModel(Map<String, dynamic> m) =>
    NotificationModel(
      id: m['id'] ?? '',
      title: m['title'] ?? '',
      body: m['body'] ?? '',
      type: NotificationType.values[m['type'] ?? 0],
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    );