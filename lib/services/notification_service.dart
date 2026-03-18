import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../data/models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Channels Android ──
  static const _medChannel = AndroidNotificationChannel(
    'medication_channel',
    'Rappels médicaments',
    description: 'Notifications pour les prises de médicaments',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _renewChannel = AndroidNotificationChannel(
    'renewal_channel',
    'Renouvellement médicaments',
    description: 'Alertes stock faible',
    importance: Importance.high,
    playSound: true,
  );

  static const _screeningChannel = AndroidNotificationChannel(
    'screening_channel',
    'Dépistages',
    description: 'Rappels de dépistage',
    importance: Importance.high,
    playSound: true,
  );

  static const _reminderChannel = AndroidNotificationChannel(
    'reminder_channel',
    'Rappels simples',
    description: 'Rappels personnalisés',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    // ── Fuseau horaire Togo (GMT+0, même timezone que Londres hiver) ──
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Lome'));

    // ── Settings Android ──
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── Settings iOS ──
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ── Créer les channels Android (requis Android 8+) ──
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_medChannel);
    await androidPlugin?.createNotificationChannel(_renewChannel);
    await androidPlugin?.createNotificationChannel(_screeningChannel);
    await androidPlugin?.createNotificationChannel(_reminderChannel);

    // ── Demander permission Android 13+ ──
    await androidPlugin?.requestNotificationsPermission();
    // ── Demander permission alarmes exactes Android 12+ ──
    await androidPlugin?.requestExactAlarmsPermission();

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );

    _initialized = true;
  }

  // ── Tap sur notification (app ouverte) ──
  void _onNotificationTapped(NotificationResponse response) {
    // La navigation est gérée via payload dans app_provider
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ── Tap sur notification (app en arrière-plan) ──
  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse response) {
    debugPrint('Background notification: ${response.payload}');
  }

  // ════════════════════════════════════════════════════════════
  // ─── Rappel médicament — répétition quotidienne ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleMedicationReminder(
    MedicationReminder medication,
    TimeOfDay time,
  ) async {
    await initialize();

    // ID unique par médicament + index de l'heure
    final timeIndex = medication.intakeTimes.indexOf(time);
    final notifId = _medNotifId(medication.id, timeIndex);

    await _notifications.zonedSchedule(
      notifId,
      '💊 Prise de médicament',
      '${medication.medicationName} ${medication.dosage}',
      _nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _medChannel.id,
          _medChannel.name,
          channelDescription: _medChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF163344),
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            '${medication.medicationName} ${medication.dosage}\nNe pas oublier votre traitement.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // répète chaque jour
      payload: 'medication_${medication.id}',
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Alerte renouvellement ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleRenewalAlert(MedicationReminder medication) async {
    await initialize();
    if (!medication.needsRenewal) return;

    await _notifications.show(
      _renewNotifId(medication.id),
      '⚠ Stock faible — ${medication.medicationName}',
      'Il vous reste ${medication.stock} unité(s). Pensez à renouveler votre ordonnance.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _renewChannel.id,
          _renewChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFF59E0B),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'renewal_${medication.id}',
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Rappel simple (alarme à date/heure fixe) ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleSimpleReminder(SimpleReminder reminder) async {
    await initialize();

    final scheduledDate = tz.TZDateTime(
      tz.local,
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    // Ne pas planifier une date passée
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      _simpleNotifId(reminder.id),
      '🔔 Rappel',
      reminder.label,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannel.id,
          _reminderChannel.name,
          channelDescription: _reminderChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF10B981),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'simple_${reminder.id}',
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Rappel dépistage ───
  // ════════════════════════════════════════════════════════════
  Future<void> scheduleScreeningReminder(ScreeningReminder reminder) async {
    await initialize();

    final daysUntil = reminder.dueDate.difference(DateTime.now()).inDays;
    if (daysUntil < 0 || reminder.isCompleted) return;

    // Notifier 7 jours avant, 1 jour avant, et le jour J
    final notifyDays = [7, 1, 0].where((d) => daysUntil >= d);

    for (final daysOffset in notifyDays) {
      final notifDate = tz.TZDateTime(
        tz.local,
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day - daysOffset,
        9,
        0,
        0,
      );

      if (notifDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final suffix = daysOffset == 0
          ? "Aujourd'hui"
          : daysOffset == 1
              ? 'Demain'
              : 'Dans $daysOffset jours';

      await _notifications.zonedSchedule(
        _screeningNotifId(reminder.id, daysOffset),
        '🏥 Dépistage — $suffix',
        '${reminder.title}: ${reminder.description}',
        notifDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _screeningChannel.id,
            _screeningChannel.name,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF3B82F6),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'screening_${reminder.id}',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Annulation ───
  // ════════════════════════════════════════════════════════════

  /// Annuler toutes les notifications d'un médicament
  Future<void> cancelMedicationReminders(MedicationReminder medication) async {
    for (var i = 0; i < medication.intakeTimes.length; i++) {
      await _notifications.cancel(_medNotifId(medication.id, i));
    }
    await _notifications.cancel(_renewNotifId(medication.id));
  }

  /// Annuler le rappel simple
  Future<void> cancelSimpleReminder(String reminderId) async {
    await _notifications.cancel(_simpleNotifId(reminderId));
  }

  /// Annuler les notifications d'un dépistage
  Future<void> cancelScreeningReminder(String reminderId) async {
    for (final d in [0, 1, 7]) {
      await _notifications.cancel(_screeningNotifId(reminderId, d));
    }
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Helpers ───
  // ════════════════════════════════════════════════════════════

  /// Prochaine occurrence d'une heure (aujourd'hui si pas encore passée, demain sinon)
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // IDs déterministes pour pouvoir annuler par médicament/rappel
  int _medNotifId(String medicationId, int timeIndex) =>
      medicationId.hashCode + timeIndex;

  int _renewNotifId(String medicationId) =>
      medicationId.hashCode + 1000;

  int _simpleNotifId(String reminderId) =>
      reminderId.hashCode + 2000;

  int _screeningNotifId(String reminderId, int dayOffset) =>
      reminderId.hashCode + 3000 + dayOffset;
}