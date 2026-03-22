import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';
import '../data/models/notification_model.dart';

/// Service de persistance locale via SharedPreferences.
/// Toutes les clés sont préfixées par "ld_" (Lamesse Dama).
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  // ── Clés ──
  static const _kUser                = 'ld_current_user';
  static const _kThemeMode           = 'ld_theme_mode';
  static const _kAppLockEnabled      = 'ld_app_lock_enabled';
  static const _kLocalPassword       = 'ld_local_password';
  static const _kHypertension        = 'ld_hypertension_records';
  static const _kDiabetes            = 'ld_diabetes_records';
  static const _kScreening           = 'ld_screening_reminders';
  static const _kMedications         = 'ld_medication_reminders';
  static const _kSimpleReminders     = 'ld_simple_reminders';
  static const _kPrescriptions       = 'ld_prescriptions';
  static const _kEvents              = 'ld_events_registered'; // seulement les ids inscrits
  static const _kAssessmentResult    = 'ld_last_assessment';
  static const _kNotifications       = 'ld_notifications';

  // ════════════════════════════════════════════════════════════
  // ─── User ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
  }

  // ════════════════════════════════════════════════════════════
  // ─── Thème & Sécurité ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_kThemeMode) ?? ThemeMode.light.index;
    return ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
  }

  Future<void> saveAppLock(bool enabled, {String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockEnabled, enabled);
    if (password != null) {
      await prefs.setString(_kLocalPassword, password);
    } else if (!enabled) {
      await prefs.remove(_kLocalPassword);
    }
  }

  Future<({bool enabled, String? password})> loadAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_kAppLockEnabled) ?? false,
      password: prefs.getString(_kLocalPassword),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── Mesures HTA ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveHypertensionRecords(List<HypertensionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.map((r) => r.toJson()).toList();
    await prefs.setString(_kHypertension, jsonEncode(list));
  }

  Future<List<HypertensionRecord>> loadHypertensionRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHypertension);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => HypertensionRecord.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Mesures Diabète ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveDiabetesRecords(List<DiabetesRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.map((r) => r.toJson()).toList();
    await prefs.setString(_kDiabetes, jsonEncode(list));
  }

  Future<List<DiabetesRecord>> loadDiabetesRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDiabetes);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => DiabetesRecord.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Rappels dépistage ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveScreeningReminders(List<ScreeningReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final list = reminders.map((r) => {
      'id': r.id,
      'title': r.title,
      'description': r.description,
      'dueDate': r.dueDate.toIso8601String(),
      'isCompleted': r.isCompleted,
      'frequency': r.frequency,
    }).toList();
    await prefs.setString(_kScreening, jsonEncode(list));
  }

  Future<List<ScreeningReminder>> loadScreeningReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kScreening);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ScreeningReminder.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Rappels médicaments ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveMedicationReminders(List<MedicationReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final list = reminders.map((r) => r.toJson()..['id'] = r.id).toList();
    await prefs.setString(_kMedications, jsonEncode(list));
  }

  Future<List<MedicationReminder>> loadMedicationReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMedications);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => MedicationReminder.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Rappels simples ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveSimpleReminders(List<SimpleReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final list = reminders.map((r) => {
      ...r.toJson(),
      'id': r.id,
      'is_completed': r.isCompleted,
    }).toList();
    await prefs.setString(_kSimpleReminders, jsonEncode(list));
  }

  Future<List<SimpleReminder>> loadSimpleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSimpleReminders);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => SimpleReminder.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Ordonnances ───
  // ════════════════════════════════════════════════════════════
  Future<void> savePrescriptions(List<Prescription> prescriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prescriptions.map((p) => {
      'id': p.id,
      'reference': p.reference,
      'imageUrl': p.imageUrl,
      'imageLocalPath': p.imageLocalPath,
      'prescriptionDate': p.prescriptionDate.toIso8601String(),
      'doctorName': p.doctorName,
      'hospital': p.hospital,
      'createdAt': p.createdAt.toIso8601String(),
    }).toList();
    await prefs.setString(_kPrescriptions, jsonEncode(list));
  }

  Future<List<Prescription>> loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrescriptions);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Prescription.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Événements — seulement les IDs inscrits ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveRegisteredEventIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kEvents, ids);
  }

  Future<List<String>> loadRegisteredEventIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kEvents) ?? [];
  }

  // ════════════════════════════════════════════════════════════
  // ─── Dernier bilan ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveAssessmentResult(SelfAssessmentResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAssessmentResult, jsonEncode({
      'id': result.id,
      'date': result.date.toIso8601String(),
      'totalScore': result.totalScore,
      'riskLevel': result.riskLevel,
      'categoryScores': result.categoryScores,
      'recommendations': result.recommendations,
    }));
  }

  Future<SelfAssessmentResult?> loadAssessmentResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAssessmentResult);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SelfAssessmentResult(
        id: m['id'] ?? '',
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        totalScore: m['totalScore'] ?? 0,
        riskLevel: m['riskLevel'] ?? 'low',
        categoryScores: Map<String, int>.from(m['categoryScores'] ?? {}),
        recommendations: List<String>.from(m['recommendations'] ?? []),
      );
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Notifications in-app ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveNotifications(List<NotificationModel> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    // Garder seulement les 50 plus récentes pour ne pas surcharger
    final toSave = notifs.take(50).map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'type': n.type.index,
      'createdAt': n.createdAt.toIso8601String(),
      'isRead': n.isRead,
    }).toList();
    await prefs.setString(_kNotifications, jsonEncode(toSave));
  }

  Future<List<NotificationModel>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotifications);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => NotificationModel(
        id: e['id'] ?? '',
        title: e['title'] ?? '',
        body: e['body'] ?? '',
        type: NotificationType.values[(e['type'] as int).clamp(0, NotificationType.values.length - 1)],
        createdAt: DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now(),
        isRead: e['isRead'] ?? false,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── Reset complet (logout) ───
  // ════════════════════════════════════════════════════════════
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      _kUser, _kHypertension, _kDiabetes, _kScreening,
      _kMedications, _kSimpleReminders, _kPrescriptions,
      _kEvents, _kAssessmentResult, _kNotifications,
      _kAppLockEnabled, _kLocalPassword,
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
    // Conserver le thème
  }

  // ════════════════════════════════════════════════════════════
  // ─── Utilitaire : sauvegarder tout en une passe ───
  // ════════════════════════════════════════════════════════════
  Future<void> saveAll({
    UserModel? user,
    List<HypertensionRecord>? hypertensionRecords,
    List<DiabetesRecord>? diabetesRecords,
    List<ScreeningReminder>? screeningReminders,
    List<MedicationReminder>? medicationReminders,
    List<SimpleReminder>? simpleReminders,
    List<Prescription>? prescriptions,
    List<String>? registeredEventIds,
    SelfAssessmentResult? assessmentResult,
    List<NotificationModel>? notifications,
  }) async {
    await Future.wait([
      if (user != null) saveUser(user),
      if (hypertensionRecords != null) saveHypertensionRecords(hypertensionRecords),
      if (diabetesRecords != null) saveDiabetesRecords(diabetesRecords),
      if (screeningReminders != null) saveScreeningReminders(screeningReminders),
      if (medicationReminders != null) saveMedicationReminders(medicationReminders),
      if (simpleReminders != null) saveSimpleReminders(simpleReminders),
      if (prescriptions != null) savePrescriptions(prescriptions),
      if (registeredEventIds != null) saveRegisteredEventIds(registeredEventIds),
      if (assessmentResult != null) saveAssessmentResult(assessmentResult),
      if (notifications != null) saveNotifications(notifications),
    ]);
  }


  static const _kIntakes = 'ld_medication_intakes';

Future<void> saveMedicationIntakes(List<MedicationIntake> intakes) async {
  final prefs = await SharedPreferences.getInstance();
  final list = intakes.map((i) => i.toJson()).toList();
  await prefs.setString(_kIntakes, jsonEncode(list));
}

Future<List<MedicationIntake>> loadMedicationIntakes() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kIntakes);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List;
    return list.map((e) => MedicationIntake.fromJson(e)).toList();
  } catch (_) {
    return [];
  }
}

static const _scheduledNotifsKey = 'scheduled_notifications';

Future<void> saveScheduledNotification(NotificationModel notif) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_scheduledNotifsKey);
  final list = raw != null
      ? List<Map<String, dynamic>>.from(jsonDecode(raw))
      : <Map<String, dynamic>>[];
  
  // Éviter les doublons par id
  list.removeWhere((m) => m['id'] == notif.id);
  list.add({
    'id': notif.id,
    'title': notif.title,
    'body': notif.body,
    'type': notif.type.index,
    'scheduledFor': notif.createdAt.toIso8601String(),
  });
  await prefs.setString(_scheduledNotifsKey, jsonEncode(list));
}

Future<List<NotificationModel>> consumeTriggeredScheduledNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_scheduledNotifsKey);
  if (raw == null) return [];

  final now = DateTime.now();
  final all = List<Map<String, dynamic>>.from(jsonDecode(raw));
  
  // Séparer celles qui ont été déclenchées (scheduledFor <= maintenant)
  final triggered = all.where((m) {
    final scheduledFor = DateTime.tryParse(m['scheduledFor'] ?? '');
    return scheduledFor != null && scheduledFor.isBefore(now);
  }).toList();
  
  // Garder uniquement les futures
  final remaining = all.where((m) {
    final scheduledFor = DateTime.tryParse(m['scheduledFor'] ?? '');
    return scheduledFor != null && scheduledFor.isAfter(now);
  }).toList();
  
  await prefs.setString(_scheduledNotifsKey, jsonEncode(remaining));
  
  return triggered.map((m) => NotificationModel(
    id: '${m['id']}_triggered_${now.millisecondsSinceEpoch}',
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    type: NotificationType.values[m['type'] ?? 0],
    createdAt: DateTime.tryParse(m['scheduledFor'] ?? '') ?? now,
    isRead: false,
  )).toList();
}
}