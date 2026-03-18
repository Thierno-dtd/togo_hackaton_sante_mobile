import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/mock/mock_data.dart';
import '../core/constants/app_constants.dart';
import '../data/models/notification_model.dart';
import 'notification_service.dart';

class AppProvider extends ChangeNotifier {

  // ── NavigatorKey global ──
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final NotificationService _notif = NotificationService();

  // ─── Theme ───
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // ─── Auth ───
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _appLockEnabled = false;
  String? _localPassword;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get appLockEnabled => _appLockEnabled;
  bool get isPatient => _currentUser?.isPatient ?? false;

  void login(UserModel user) {
    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _notif.cancelAll();
    _currentUser = null;
    _isLoggedIn = false;
    _appLockEnabled = false;
    _localPassword = null;
    _hypertensionRecords = [];
    _diabetesRecords = [];
    _screeningReminders = [];
    _medicationReminders = [];
    _simpleReminders = [];
    _prescriptions = [];
    _dailyAdvice = [];
    _events = [];
    _notifications = [];
    _lastAssessmentResult = null;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateUserLocation(String gpsLocation) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(gpsLocation: gpsLocation);
      notifyListeners();
    }
  }

  void setAppLock(bool enabled, {String? password}) {
    _appLockEnabled = enabled;
    if (password != null) _localPassword = password;
    notifyListeners();
  }

  bool verifyPassword(String password) => _localPassword == password;

  void activatePatient(String diseaseType) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        healthStatus: AppConstants.patient,
        diseaseType: diseaseType,
      );
      notifyListeners();
    }
  }

  // ─── Measurements ───
  List<HypertensionRecord> _hypertensionRecords = [];
  List<DiabetesRecord> _diabetesRecords = [];

  List<HypertensionRecord> get hypertensionRecords => _hypertensionRecords;
  List<DiabetesRecord> get diabetesRecords => _diabetesRecords;

  void loadMockMeasurements() {
    if (_currentUser != null) {
      _hypertensionRecords = MockData.hypertensionRecords(_currentUser!.id);
      _diabetesRecords = MockData.diabetesRecords(_currentUser!.id);
    }
  }

  void addHypertensionRecord(HypertensionRecord record) {
    _hypertensionRecords.insert(0, record);
    notifyListeners();
  }

  void addDiabetesRecord(DiabetesRecord record) {
    _diabetesRecords.insert(0, record);
    notifyListeners();
  }

  // ─── Screening Reminders ───
  List<ScreeningReminder> _screeningReminders = [];
  List<ScreeningReminder> get screeningReminders => _screeningReminders;

  List<ScreeningReminder> get overdueScreening => _screeningReminders
      .where((r) => !r.isCompleted && r.dueDate.isBefore(DateTime.now()))
      .toList();

  /// Toggle complété + annule l'alarme si complété
  void toggleScreeningReminder(String id) {
    final idx = _screeningReminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _screeningReminders[idx].isCompleted =
        !_screeningReminders[idx].isCompleted;
    if (_screeningReminders[idx].isCompleted) {
      _notif.cancelScreeningReminder(id);
    }
    notifyListeners();
  }

  // ─── Medication Reminders ───
  List<MedicationReminder> _medicationReminders = [];
  List<MedicationReminder> get medicationReminders => _medicationReminders;

  /// Ajoute + programme les alarmes
  void addMedicationReminder(MedicationReminder reminder) {
    _medicationReminders.add(reminder);
    for (final time in reminder.intakeTimes) {
      _notif.scheduleMedicationReminder(reminder, time);
    }
    if (reminder.needsRenewal) {
      _notif.scheduleRenewalAlert(reminder);
    }
    notifyListeners();
  }

  /// Met à jour + reprogramme les alarmes
  void updateMedicationReminder(MedicationReminder updated) {
    final idx = _medicationReminders.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return;
    _notif.cancelMedicationReminders(_medicationReminders[idx]);
    _medicationReminders[idx] = updated;
    for (final time in updated.intakeTimes) {
      _notif.scheduleMedicationReminder(updated, time);
    }
    if (updated.needsRenewal) {
      _notif.scheduleRenewalAlert(updated);
    }
    notifyListeners();
  }

  /// Supprime + annule les alarmes
  void deleteMedicationReminder(String id) {
    final idx = _medicationReminders.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _notif.cancelMedicationReminders(_medicationReminders[idx]);
    _medicationReminders.removeAt(idx);
    notifyListeners();
  }

  // ─── Simple Reminders ───
  List<SimpleReminder> _simpleReminders = [];
  List<SimpleReminder> get simpleReminders => _simpleReminders;

  /// Ajoute + programme l'alarme à date/heure fixe
  void addSimpleReminder(SimpleReminder reminder) {
    _simpleReminders.add(reminder);
    _notif.scheduleSimpleReminder(reminder);
    notifyListeners();
  }

  /// Supprime + annule l'alarme
  void deleteSimpleReminder(String id) {
    _notif.cancelSimpleReminder(id);
    _simpleReminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// Marque complété + annule l'alarme
  void toggleSimpleReminder(String id) {
    final idx = _simpleReminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _simpleReminders[idx].isCompleted = !_simpleReminders[idx].isCompleted;
    if (_simpleReminders[idx].isCompleted) {
      _notif.cancelSimpleReminder(id);
    }
    notifyListeners();
  }

  // ─── Daily Advice ───
  List<AdviceModel> _dailyAdvice = [];
  List<AdviceModel> get dailyAdvice => _dailyAdvice;

  void loadDailyAdvice(String diseaseType) {
    final all = MockData.adviceList
        .where((a) => a.diseaseType == 'all' || a.diseaseType == diseaseType)
        .toList();
    all.shuffle();
    _dailyAdvice = all.take(AppConstants.advicePerDay).toList();
  }

  // ─── Self Assessment ───
  SelfAssessmentResult? _lastAssessmentResult;
  SelfAssessmentResult? get lastAssessmentResult => _lastAssessmentResult;

  void saveAssessmentResult(SelfAssessmentResult result) {
    _lastAssessmentResult = result;
    notifyListeners();
  }

  // ─── Events ───
  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  void loadEvents() => _events = MockData.events;

  void toggleEventRegistration(String eventId) {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _events[idx].isRegistered = !_events[idx].isRegistered;
      notifyListeners();
    }
  }

  // ─── Notifications in-app ───
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  void loadMockNotifications() {
    _notifications = MockData.generateMockNotifications();
    notifyListeners();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAllAsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  // ─── Prescriptions ───
  List<Prescription> _prescriptions = [];
  List<Prescription> get prescriptions => _prescriptions;

  List<MedicationReminder> getMedicationsByPrescription(String prescriptionId) =>
      _medicationReminders
          .where((m) => m.prescriptionId == prescriptionId)
          .toList();

  Prescription? getPrescriptionForMedication(MedicationReminder medication) {
    if (medication.prescriptionId == null) return null;
    try {
      return _prescriptions
          .firstWhere((p) => p.id == medication.prescriptionId);
    } catch (_) {
      return _prescriptions.isNotEmpty ? _prescriptions.first : null;
    }
  }

  void loadMockPrescriptions() {
    _prescriptions = MockData.mockPrescriptions;
    notifyListeners();
  }

  void addPrescription(Prescription prescription) {
    _prescriptions.insert(0, prescription);
    notifyListeners();
  }

  /// Supprime ordonnance + annule alarmes de tous ses médicaments
  void deletePrescription(String prescriptionId) {
    final meds = getMedicationsByPrescription(prescriptionId);
    for (final med in meds) {
      _notif.cancelMedicationReminders(med);
    }
    _prescriptions.removeWhere((p) => p.id == prescriptionId);
    _medicationReminders
        .removeWhere((m) => m.prescriptionId == prescriptionId);
    notifyListeners();
  }

  Map<String, List<MedicationReminder>> get medicationsByPrescription {
    final Map<String, List<MedicationReminder>> grouped = {};
    for (final med in _medicationReminders) {
      grouped.putIfAbsent(med.prescriptionId ?? 'no_prescription', () => [])
          .add(med);
    }
    return grouped;
  }

  // ─── Chargement des reminders mock ───
  void loadMockReminders() {
    _screeningReminders = MockData.defaultScreeningReminders;
    if (isPatient) {
      loadMockPrescriptions();
      _medicationReminders = MockData.defaultMedicationReminders;
      _simpleReminders = MockData.defaultSimpleReminders;
    }
  }

  Future<void> scheduleAllReminders() async {
    // 🔁 Annule toutes les anciennes notifications (évite doublons)
    await _notif.cancelAll();

    // ─── Médicaments ───
    for (final med in _medicationReminders) {
      for (final time in med.intakeTimes) {
        await _notif.scheduleMedicationReminder(med, time);
      }
      if (med.needsRenewal) {
        await _notif.scheduleRenewalAlert(med);
      }
    }

    // ─── Dépistage ───
    for (final s in _screeningReminders) {
      if (!s.isCompleted) {
        await _notif.scheduleScreeningReminder(s);
      }
    }

    // ─── Rappels simples ───
    for (final r in _simpleReminders) {
      if (!r.isCompleted) {
        await _notif.scheduleSimpleReminder(r);
      }
    }
  }

  // ─── Init ───
  void initWithUser(UserModel user) async {
    _currentUser = user;
    _isLoggedIn = true;

    await _notif.initialize();

    // ← Brancher le callback foreground → page in-app
    _notif.onNotificationReceived = (NotificationModel model) {
      addNotification(model);
    };

    // ← Récupérer les notifications reçues pendant que l'app était fermée
    final pending = await _notif.consumePendingNotifications();
    for (final n in pending) {
      _notifications.insert(0, n);
    }

    loadMockMeasurements();
    loadMockReminders();
    loadMockNotifications();
    loadDailyAdvice(user.diseaseType ?? 'all');
    loadEvents();
    await scheduleAllReminders();
    notifyListeners();
  }

  /// Programme toutes les alarmes existantes au démarrage
  Future<void> _scheduleAllExistingAlarms() async {
    for (final med in _medicationReminders) {
      for (final time in med.intakeTimes) {
        await _notif.scheduleMedicationReminder(med, time);
      }
      if (med.needsRenewal) await _notif.scheduleRenewalAlert(med);
    }
    for (final s in _screeningReminders) {
      if (!s.isCompleted) await _notif.scheduleScreeningReminder(s);
    }
    for (final r in _simpleReminders) {
      if (!r.isCompleted) await _notif.scheduleSimpleReminder(r);
    }
  }
}