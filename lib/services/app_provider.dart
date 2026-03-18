// lib/services/app_provider.dart
// Version fusionnée : mock + repositories + alarmes + notifications

import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/mock/mock_data.dart';
import '../core/constants/app_constants.dart';
import '../core/network/token_storage.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/measurement_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/prescription_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/advice_repository.dart';
import 'notification_service.dart';
import 'alarm_service.dart';

enum LoadState { idle, loading, success, error }

class AppProvider extends ChangeNotifier {

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ── Repositories ──
  final _authRepo        = AuthRepository();
  final _userRepo        = UserRepository();
  final _measureRepo     = MeasurementRepository();
  final _reminderRepo    = ReminderRepository();
  final _prescriptionRepo = PrescriptionRepository();
  final _eventRepo       = EventRepository();
  final _adviceRepo      = AdviceRepository();
  final _tokenStorage    = TokenStorage();
  final _notif           = NotificationService();

  // ════════════════════════════════════════════════════════════
  // ─── Theme ───
  // ════════════════════════════════════════════════════════════
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  void setThemeMode(ThemeMode mode) { _themeMode = mode; notifyListeners(); }

  // ════════════════════════════════════════════════════════════
  // ─── Auth ───
  // ════════════════════════════════════════════════════════════
  UserModel? _currentUser;
  bool _isLoggedIn    = false;
  bool _appLockEnabled = false;
  String? _localPassword;

  UserModel? get currentUser    => _currentUser;
  bool get isLoggedIn           => _isLoggedIn;
  bool get appLockEnabled       => _appLockEnabled;
  bool get isPatient            => _currentUser?.isPatient ?? false;

  // ─── Loading states ───
  LoadState _measurementsState = LoadState.idle;
  LoadState _remindersState    = LoadState.idle;
  LoadState _eventsState       = LoadState.idle;
  LoadState _adviceState       = LoadState.idle;

  LoadState get measurementsState => _measurementsState;
  LoadState get remindersState    => _remindersState;
  LoadState get eventsState       => _eventsState;
  LoadState get adviceState       => _adviceState;

  String? _measurementsError;
  String? _eventsError;
  String? get measurementsError => _measurementsError;
  String? get eventsError       => _eventsError;

  // ════════════════════════════════════════════════════════════
  // ─── Auto-login au démarrage ───
  // ════════════════════════════════════════════════════════════
  Future<bool> checkAutoLogin() async {
    final hasTokens = await _tokenStorage.hasValidTokens();
    if (!hasTokens) return false;
    final res = await _authRepo.getMe();
    if (res.success && res.data != null) {
      await initWithUser(res.data!);
      return true;
    }
    await _tokenStorage.clearAll();
    return false;
  }

  // ════════════════════════════════════════════════════════════
  // ─── Init après login ───
  // ════════════════════════════════════════════════════════════
  Future<void> initWithUser(UserModel user) async {
    _currentUser = user;
    _isLoggedIn  = true;

    // ── Initialiser les services ──
    await _notif.initialize();
    await AlarmService.initialize();

    // ── Brancher le callback foreground → page in-app ──
    _notif.onNotificationReceived = (model) => addNotification(model);

    // ── Récupérer les notifs reçues app fermée ──
    final pending = await _notif.consumePendingNotifications();
    for (final n in pending) _notifications.insert(0, n);

    // ── Charger toutes les données ──
    await Future.wait([
      _loadMeasurements(),
      _loadReminders(),
      _loadDailyAdvice(user.diseaseType ?? 'all'),
      _loadEvents(),
    ]);
    _loadMockNotifications(); // notifications in-app mockées

    // ── Programmer toutes les alarmes + rappels ──
    await _scheduleAll();

    notifyListeners();
  }

  // ─── Login simple (sans API) ───
  void login(UserModel user) {
    _currentUser = user;
    _isLoggedIn  = true;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Logout ───
  // ════════════════════════════════════════════════════════════
  Future<void> logout() async {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    try { await _authRepo.logout(); } catch (_) {}
    await _notif.cancelAll();
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _currentUser         = null;
    _isLoggedIn          = false;
    _appLockEnabled      = false;
    _localPassword       = null;
    _hypertensionRecords = [];
    _diabetesRecords     = [];
    _screeningReminders  = [];
    _medicationReminders = [];
    _simpleReminders     = [];
    _prescriptions       = [];
    _dailyAdvice         = [];
    _events              = [];
    _notifications       = [];
    _lastAssessmentResult = null;
    _measurementsState   = LoadState.idle;
    _remindersState      = LoadState.idle;
    _eventsState         = LoadState.idle;
    _adviceState         = LoadState.idle;
  }

  // ════════════════════════════════════════════════════════════
  // ─── User ───
  // ════════════════════════════════════════════════════════════
  Future<void> updateUser(UserModel user) async {
    _currentUser = user;
    notifyListeners();
    try { await _userRepo.updateProfile(user); } catch (_) {}
  }

  void updateUserSync(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateUserLocation(String gpsLocation) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(gpsLocation: gpsLocation);
    notifyListeners();
    try { await _userRepo.updateLocation(gpsLocation); } catch (_) {}
  }

  void setAppLock(bool enabled, {String? password}) {
    _appLockEnabled = enabled;
    if (password != null) _localPassword = password;
    notifyListeners();
  }

  bool verifyPassword(String password) => _localPassword == password;

  void activatePatient(String diseaseType) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      healthStatus: AppConstants.patient,
      diseaseType: diseaseType,
    );
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Measurements ───
  // ════════════════════════════════════════════════════════════
  List<HypertensionRecord> _hypertensionRecords = [];
  List<DiabetesRecord>     _diabetesRecords     = [];

  List<HypertensionRecord> get hypertensionRecords => _hypertensionRecords;
  List<DiabetesRecord>     get diabetesRecords     => _diabetesRecords;

  Future<void> _loadMeasurements() async {
    if (_currentUser == null || !_currentUser!.isPatient) return;
    _measurementsState = LoadState.loading;

    final isHypertension = _currentUser!.diseaseType == 'hypertension';
    if (isHypertension) {
      final res = await _measureRepo.getHypertensionRecords();
      if (res.success && res.data != null) {
        _hypertensionRecords = res.data!;
        _measurementsState = LoadState.success;
      } else {
        _hypertensionRecords = MockData.hypertensionRecords(_currentUser!.id);
        _measurementsState = LoadState.error;
        _measurementsError = res.error?.message;
      }
    } else {
      final res = await _measureRepo.getDiabetesRecords();
      if (res.success && res.data != null) {
        _diabetesRecords = res.data!;
        _measurementsState = LoadState.success;
      } else {
        _diabetesRecords = MockData.diabetesRecords(_currentUser!.id);
        _measurementsState = LoadState.error;
        _measurementsError = res.error?.message;
      }
    }
    notifyListeners();
  }

  // Méthode mock conservée pour rétro-compatibilité
  void loadMockMeasurements() {
    if (_currentUser == null) return;
    _hypertensionRecords = MockData.hypertensionRecords(_currentUser!.id);
    _diabetesRecords     = MockData.diabetesRecords(_currentUser!.id);
  }

  Future<void> addHypertensionRecord(HypertensionRecord record) async {
    _hypertensionRecords.insert(0, record);
    notifyListeners();
    try {
      final res = await _measureRepo.addHypertensionRecord(record);
      if (res.success && res.data != null) {
        _hypertensionRecords[0] = res.data!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> addDiabetesRecord(DiabetesRecord record) async {
    _diabetesRecords.insert(0, record);
    notifyListeners();
    try {
      final res = await _measureRepo.addDiabetesRecord(record);
      if (res.success && res.data != null) {
        _diabetesRecords[0] = res.data!;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════
  // ─── Reminders ───
  // ════════════════════════════════════════════════════════════
  List<ScreeningReminder>  _screeningReminders  = [];
  List<MedicationReminder> _medicationReminders = [];
  List<SimpleReminder>     _simpleReminders     = [];

  List<ScreeningReminder>  get screeningReminders  => _screeningReminders;
  List<MedicationReminder> get medicationReminders => _medicationReminders;
  List<SimpleReminder>     get simpleReminders     => _simpleReminders;

  List<ScreeningReminder> get overdueScreening => _screeningReminders
      .where((r) => !r.isCompleted && r.dueDate.isBefore(DateTime.now()))
      .toList();

  Future<void> _loadReminders() async {
    _remindersState = LoadState.loading;

    // Screening
    try {
      final res = await _reminderRepo.getScreeningReminders();
      _screeningReminders = res.success && res.data != null
          ? res.data!
          : MockData.defaultScreeningReminders;
    } catch (_) {
      _screeningReminders = MockData.defaultScreeningReminders;
    }

    if (isPatient) {
      // Prescriptions
      try {
        final res = await _prescriptionRepo.getPrescriptions();
        _prescriptions = res.success && res.data != null
            ? res.data!
            : MockData.mockPrescriptions;
      } catch (_) {
        _prescriptions = MockData.mockPrescriptions;
      }

      // Médicaments
      try {
        final res = await _reminderRepo.getMedicationReminders();
        _medicationReminders = res.success && res.data != null
            ? res.data!
            : MockData.defaultMedicationReminders;
      } catch (_) {
        _medicationReminders = MockData.defaultMedicationReminders;
      }

      // Rappels simples
      try {
        final res = await _reminderRepo.getSimpleReminders();
        _simpleReminders = res.success && res.data != null
            ? res.data!
            : MockData.defaultSimpleReminders;
      } catch (_) {
        _simpleReminders = MockData.defaultSimpleReminders;
      }
    }

    _remindersState = LoadState.success;
    notifyListeners();
  }

  // Méthode mock conservée pour rétro-compatibilité
  void loadMockReminders() {
    _screeningReminders = MockData.defaultScreeningReminders;
    if (isPatient) {
      _prescriptions       = MockData.mockPrescriptions;
      _medicationReminders = MockData.defaultMedicationReminders;
      _simpleReminders     = MockData.defaultSimpleReminders;
    }
  }

  // ─── Screening ───
  void toggleScreeningReminder(String id) {
    final idx = _screeningReminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _screeningReminders[idx].isCompleted = !_screeningReminders[idx].isCompleted;
    if (_screeningReminders[idx].isCompleted) _notif.cancelScreeningReminder(id);
    notifyListeners();
    try { _reminderRepo.toggleScreeningReminder(id, _screeningReminders[idx].isCompleted); } catch (_) {}
  }

  // ─── Medication ───
  Future<void> addMedicationReminder(MedicationReminder reminder) async {
    _medicationReminders.add(reminder);
    notifyListeners();
    // Programmer rappel + alarme
    await _scheduleMedicationAlarms(reminder);
    try { await _reminderRepo.addMedicationReminder(reminder); } catch (_) {}
  }

  Future<void> updateMedicationReminder(MedicationReminder updated) async {
    final idx = _medicationReminders.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return;
    await _cancelMedicationAlarms(_medicationReminders[idx]);
    _medicationReminders[idx] = updated;
    notifyListeners();
    await _scheduleMedicationAlarms(updated);
    try { await _reminderRepo.updateMedicationReminder(updated); } catch (_) {}
  }

  Future<void> deleteMedicationReminder(String id) async {
    final idx = _medicationReminders.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    await _cancelMedicationAlarms(_medicationReminders[idx]);
    _medicationReminders.removeAt(idx);
    notifyListeners();
    try { await _reminderRepo.deleteMedicationReminder(id); } catch (_) {}
  }

  // ─── Simple ───
  Future<void> addSimpleReminder(SimpleReminder reminder) async {
  _simpleReminders.add(reminder);

  await _scheduleSimpleAlarm(reminder);

  try {
    await _reminderRepo.addSimpleReminder(reminder);
  } catch (_) {}

  notifyListeners(); // ✅ à la FIN
}

  Future<void> deleteSimpleReminder(String id) async {
    await _cancelSimpleAlarm(id);
    _simpleReminders.removeWhere((r) => r.id == id);
    notifyListeners();
    try { await _reminderRepo.deleteSimpleReminder(id); } catch (_) {}
  }

  void toggleSimpleReminder(String id) {
    final idx = _simpleReminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _simpleReminders[idx].isCompleted = !_simpleReminders[idx].isCompleted;
    if (_simpleReminders[idx].isCompleted) _cancelSimpleAlarm(id);
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Logique alarme vs notification ───
  //
  // J-7, J-1     → notification silencieuse de rappel
  // Le jour J    → notification + ALARME (son persistant)
  // ════════════════════════════════════════════════════════════

  Future<void> _scheduleMedicationAlarms(MedicationReminder med) async {
    for (var i = 0; i < med.intakeTimes.length; i++) {
      final time = med.intakeTimes[i];
      // J-1 matin → notification de rappel
      await _notif.scheduleMedicationReminderNotification(med, time, advanceDays: 1);
      // À l'heure exacte → ALARME persistante
      await AlarmService().scheduleMedicationAlarm(med, time, i);
    }
    if (med.needsRenewal) await _notif.scheduleRenewalAlert(med);
  }

  Future<void> _cancelMedicationAlarms(MedicationReminder med) async {
    await _notif.cancelMedicationReminders(med);
    await AlarmService().cancelMedicationAlarms(med);
  }

  Future<void> _scheduleSimpleAlarm(SimpleReminder reminder) async {
    // 1h avant → notification de rappel
    await _notif.scheduleSimpleReminderNotification(reminder, advanceMinutes: 60);
    // À l'heure exacte → ALARME persistante
    await AlarmService().scheduleSimpleAlarm(reminder);
  }

  Future<void> _cancelSimpleAlarm(String id) async {
    await _notif.cancelSimpleReminder(id);
    await AlarmService().cancelSimpleAlarm(id);
  }

  Future<void> _scheduleAll() async {
    await _notif.cancelAll();
    for (final med in _medicationReminders) {
      await _scheduleMedicationAlarms(med);
    }
    for (final s in _screeningReminders) {
      if (!s.isCompleted) await _notif.scheduleScreeningReminder(s);
    }
    for (final r in _simpleReminders) {
      if (!r.isCompleted) await _scheduleSimpleAlarm(r);
    }
  }

  // Alias rétro-compatible
  Future<void> scheduleAllReminders() => _scheduleAll();

  // ════════════════════════════════════════════════════════════
  // ─── Advice ───
  // ════════════════════════════════════════════════════════════
  List<AdviceModel> _dailyAdvice = [];
  List<AdviceModel> get dailyAdvice => _dailyAdvice;

  Future<void> _loadDailyAdvice(String diseaseType) async {
    _adviceState = LoadState.loading;
    try {
      final res = await _adviceRepo.getDailyAdvice(diseaseType: diseaseType);
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        _dailyAdvice = res.data!;
        _adviceState = LoadState.success;
      } else {
        _fallbackAdvice(diseaseType);
      }
    } catch (_) {
      _fallbackAdvice(diseaseType);
    }
    notifyListeners();
  }

  void _fallbackAdvice(String diseaseType) {
    final all = MockData.adviceList
        .where((a) => a.diseaseType == 'all' || a.diseaseType == diseaseType)
        .toList()..shuffle();
    _dailyAdvice = all.take(AppConstants.advicePerDay).toList();
    _adviceState = LoadState.error;
  }

  // Mock conservé
  void loadDailyAdvice(String diseaseType) => _fallbackAdvice(diseaseType);

  // ════════════════════════════════════════════════════════════
  // ─── Events ───
  // ════════════════════════════════════════════════════════════
  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  Future<void> _loadEvents() async {
    _eventsState = LoadState.loading;
    try {
      final res = await _eventRepo.getEvents();
      if (res.success && res.data != null) {
        _events = res.data!;
        _eventsState = LoadState.success;
      } else {
        _events = MockData.events;
        _eventsState = LoadState.error;
        _eventsError = res.error?.message;
      }
    } catch (_) {
      _events = MockData.events;
      _eventsState = LoadState.error;
    }
    notifyListeners();
  }

  void loadEvents() => _events = MockData.events;

  Future<void> toggleEventRegistration(String eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final was = _events[idx].isRegistered;
    _events[idx].isRegistered = !was;
    notifyListeners();
    try {
      if (was) await _eventRepo.unregisterFromEvent(eventId);
      else     await _eventRepo.registerForEvent(eventId);
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════
  // ─── Prescriptions ───
  // ════════════════════════════════════════════════════════════
  List<Prescription> _prescriptions = [];
  List<Prescription> get prescriptions => _prescriptions;

  List<MedicationReminder> getMedicationsByPrescription(String id) =>
      _medicationReminders.where((m) => m.prescriptionId == id).toList();

  Prescription? getPrescriptionForMedication(MedicationReminder med) {
    if (med.prescriptionId == null) return null;
    try { return _prescriptions.firstWhere((p) => p.id == med.prescriptionId); }
    catch (_) { return null; }
  }

  void loadMockPrescriptions() {
    _prescriptions = MockData.mockPrescriptions;
    notifyListeners();
  }

  void addPrescription(Prescription prescription) {
    _prescriptions.insert(0, prescription);
    notifyListeners();
  }

  Future<void> deletePrescription(String prescriptionId) async {
    final meds = getMedicationsByPrescription(prescriptionId);
    for (final med in meds) await _cancelMedicationAlarms(med);
    _prescriptions.removeWhere((p) => p.id == prescriptionId);
    _medicationReminders.removeWhere((m) => m.prescriptionId == prescriptionId);
    notifyListeners();
    try { await _prescriptionRepo.deletePrescription(prescriptionId); } catch (_) {}
  }

  Map<String, List<MedicationReminder>> get medicationsByPrescription {
    final grouped = <String, List<MedicationReminder>>{};
    for (final med in _medicationReminders) {
      grouped.putIfAbsent(med.prescriptionId ?? 'no_prescription', () => []).add(med);
    }
    return grouped;
  }

  // ════════════════════════════════════════════════════════════
  // ─── Self Assessment ───
  // ════════════════════════════════════════════════════════════
  SelfAssessmentResult? _lastAssessmentResult;
  SelfAssessmentResult? get lastAssessmentResult => _lastAssessmentResult;

  void saveAssessmentResult(SelfAssessmentResult result) {
    _lastAssessmentResult = result;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Notifications in-app ───
  // ════════════════════════════════════════════════════════════
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  void _loadMockNotifications() {
    // Insérer après les pending (déjà ajoutés dans initWithUser)
    final mock = MockData.generateMockNotifications();
    _notifications.addAll(mock);
    notifyListeners();
  }

  void loadMockNotifications() => _loadMockNotifications();

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }
}