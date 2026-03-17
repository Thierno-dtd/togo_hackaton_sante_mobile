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

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification
    // Navigation vers la page appropriée
  }

  Future<void> scheduleMedicationReminder(
    MedicationReminder medication,
    TimeOfDay time,
  ) async {
    for (var i = 0; i < medication.intakeTimes.length; i++) {
      final intakeTime = medication.intakeTimes[i];
      
      await _notifications.zonedSchedule(
        medication.id.hashCode + i,
        'Prise de médicament',
        '${medication.medicationName} - ${medication.dosage}',
        _nextInstanceOfTime(intakeTime),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Rappels de médicaments',
            channelDescription: 'Notifications pour les prises de médicaments',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> scheduleRenewalAlert(MedicationReminder medication) async {
    if (!medication.needsRenewal) return;

    await _notifications.show(
      medication.id.hashCode + 1000,
      'Renouvellement nécessaire',
      'Stock faible pour ${medication.medicationName}. '
          'Il vous reste ${medication.stock} unité(s).',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'renewal_channel',
          'Renouvellement médicaments',
          channelDescription: 'Alertes de renouvellement',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFF59E0B),
        ),
      ),
    );
  }

  Future<void> scheduleMissedMeasurementNotification() async {
    await _notifications.show(
      9999,
      'Mesure manquée',
      'Vous n\'avez pas effectué votre mesure de ce matin',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'measurement_channel',
          'Rappels de mesures',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }

  Future<void> scheduleDoctorAppointment({
    required String doctorName,
    required DateTime appointmentDate,
    required String hospital,
    String? contactInfo,
  }) async {
    final daysUntil = appointmentDate.difference(DateTime.now()).inDays;
    
    String body = 'Rendez-vous avec Dr. $doctorName le '
        '${appointmentDate.day}/${appointmentDate.month} à $hospital.';
    
    if (contactInfo != null) {
      body += ' Contact: $contactInfo';
    }

    // Notification 2 jours avant
    if (daysUntil >= 2) {
      await _notifications.zonedSchedule(
        appointmentDate.hashCode,
        'Rendez-vous médical imminent',
        body,
        tz.TZDateTime.from(
          appointmentDate.subtract(const Duration(days: 2)),
          tz.local,
        ),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_channel',
            'Rendez-vous médicaux',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF10B981),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> scheduleScreeningReminder(ScreeningReminder reminder) async {
    final daysUntil = reminder.dueDate.difference(DateTime.now()).inDays;

    if (daysUntil <= 7 && daysUntil >= 0) {
      await _notifications.zonedSchedule(
        reminder.id.hashCode,
        'Dépistage à venir',
        '${reminder.title} - ${reminder.description}',
        tz.TZDateTime.from(reminder.dueDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'screening_channel',
            'Rappels de dépistage',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF3B82F6),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}