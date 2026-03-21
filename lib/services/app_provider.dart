import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lamesse_dama_mobile/data/repositories/intake_repository.dart';
import 'package:lamesse_dama_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:lamesse_dama_mobile/services/auth_service.dart';
import 'package:uuid/uuid.dart';
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
import 'local_storage.dart'; // ← NOUVEAU

enum LoadState { idle, loading, success, error }

class AppProvider extends ChangeNotifier {

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ── Repositories ──
  final _authRepo         = AuthRepository();
  final _userRepo         = UserRepository();
  final _measureRepo      = MeasurementRepository();
  final _reminderRepo     = ReminderRepository();
  final _prescriptionRepo = PrescriptionRepository();
  final _eventRepo        = EventRepository();
  final _adviceRepo       = AdviceRepository();
  final _tokenStorage     = TokenStorage();
  final _notif            = NotificationService();
  final _localStorage     = LocalStorage(); 
  final _intakeRepo       = IntakeRepository();

  // ════════════════════════════════════════════════════════════
  // ─── Theme ───
  // ════════════════════════════════════════════════════════════
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _localStorage.saveThemeMode(mode); // ← persisté
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Auth ───
  // ════════════════════════════════════════════════════════════
  UserModel? _currentUser;
  bool _isLoggedIn     = false;
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
  // ─── Initialisation au démarrage de l'app ───
  // Charger le thème et le verrou AVANT même de savoir si connecté
  // ════════════════════════════════════════════════════════════
  Future<void> initAppSettings() async {
    _themeMode = await _localStorage.loadThemeMode();
    final lock = await _localStorage.loadAppLock();
    _appLockEnabled = lock.enabled;
    _localPassword  = lock.password;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Auto-login au démarrage ───
  // ════════════════════════════════════════════════════════════
  Future<bool> checkAutoLogin() async {
    // 1. Essayer depuis le stockage local d'abord (offline)
    final savedUser = await _localStorage.loadUser();
    if (savedUser != null) {
      await initWithUser(savedUser, fromLocal: true);
      _refreshFromApi();
      return true;
    }

    // 2. Sinon essayer les tokens API
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

  // Rafraîchissement silencieux depuis l'API (sans bloquer l'UI)
  Future<void> _refreshFromApi() async {
    try {
      final hasTokens = await _tokenStorage.hasValidTokens();
      if (!hasTokens) return;
      final res = await _authRepo.getMe();
      if (res.success && res.data != null) {
        _currentUser = res.data!;
        await _localStorage.saveUser(res.data!);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════
  // ─── Init après login ───
  // ════════════════════════════════════════════════════════════
  Future<void> initWithUser(UserModel user, {bool fromLocal = false}) async {
    _currentUser = user;
    _isLoggedIn  = true;
    notifyListeners();

    // ── Initialiser les services ──
    await _notif.initialize();
    await NotificationService.requestBatteryOptimizationExemption();

    // ── Brancher le callback foreground → page in-app ──
    _notif.onNotificationReceived = (model) => addNotification(model);

    // ── Récupérer les notifs reçues app fermée ──
    final pending = await _notif.consumePendingNotifications();
    for (final n in pending) _notifications.insert(0, n);

    // ── Charger les données ──
    if (fromLocal) {
      // Chargement local rapide (offline-first)
      await _loadFromLocal(user);
    } else {
      // Chargement depuis l'API (avec fallback local puis mock)
      await Future.wait([
        _loadMeasurements(),
        _loadReminders(),
        _loadDailyAdvice(user.diseaseType ?? 'all'),
        _loadEvents(),
      ]);
      // Sauvegarder ce qui vient de l'API en local
      await _persistAll();
    }

    // Charger les notifs persistées
    await _loadPersistedNotifications();

    // ── Programmer toutes les alarmes ──
    await _scheduleAll();
    _startNotificationChecker();

    notifyListeners();
  }

  // ─── Chargement local (offline-first) ───
  Future<void> _loadFromLocal(UserModel user) async {
    _measurementsState = LoadState.loading;
    _remindersState    = LoadState.loading;

    final diseaseType = user.diseaseType ?? 'hypertension';

    // Mesures
    if (diseaseType == 'hypertension' || diseaseType == 'both') {
      _hypertensionRecords = await _localStorage.loadHypertensionRecords();
      if (_hypertensionRecords.isEmpty) {
        _hypertensionRecords = MockData.hypertensionRecords(user.id);
      }
    }
    if (diseaseType == 'diabetes' || diseaseType == 'both') {
      _diabetesRecords = await _localStorage.loadDiabetesRecords();
      if (_diabetesRecords.isEmpty) {
        _diabetesRecords = MockData.diabetesRecords(user.id);
      }
    }

    // Rappels
    _screeningReminders = await _localStorage.loadScreeningReminders();
    if (_screeningReminders.isEmpty) {
      _screeningReminders = MockData.defaultScreeningReminders;
    }

    if (user.isPatient) {
      _prescriptions = await _localStorage.loadPrescriptions();
      if (_prescriptions.isEmpty) {
        _prescriptions = MockData.mockPrescriptions;
      }

      _medicationReminders = await _localStorage.loadMedicationReminders();
      if (_medicationReminders.isEmpty) {
        _medicationReminders = MockData.defaultMedicationReminders;
      }

      _simpleReminders = await _localStorage.loadSimpleReminders();
      if (_simpleReminders.isEmpty) {
        _simpleReminders = MockData.defaultSimpleReminders;
      }
    }

    // Événements : charger les IDs inscrits et les appliquer aux mock
    _events = MockData.events;
    final registeredIds = await _localStorage.loadRegisteredEventIds();
    for (final e in _events) {
      e.isRegistered = registeredIds.contains(e.id);
    }

    // Conseil du jour (mock)
    _fallbackAdvice(user.diseaseType ?? 'all');

    // Dernier bilan
    _lastAssessmentResult = await _localStorage.loadAssessmentResult();

    _measurementsState = LoadState.success;
    _remindersState    = LoadState.success;
    _eventsState       = LoadState.success;
    _adviceState       = LoadState.success;

    notifyListeners();
  }

  // ─── Charger les notifs persistées sans dupliquer les mock ───
  Future<void> _loadPersistedNotifications() async {
    final persisted = await _localStorage.loadNotifications();
    if (persisted.isEmpty) {
      // Première ouverture : charger les mock
      _loadMockNotifications();
    } else {
      _notifications = persisted;
    }
    notifyListeners();
  }

  // ─── Persister toutes les données en local après chargement API ───
  Future<void> _persistAll() async {
    await _localStorage.saveAll(
      user: _currentUser,
      hypertensionRecords: _hypertensionRecords,
      diabetesRecords: _diabetesRecords,
      screeningReminders: _screeningReminders,
      medicationReminders: _medicationReminders,
      simpleReminders: _simpleReminders,
      prescriptions: _prescriptions,
      registeredEventIds: _events.where((e) => e.isRegistered).map((e) => e.id).toList(),
    );
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
  _notif.onNotificationReceived = null;
  _notif.cancelAll();
  _authRepo.logout().catchError((_) {});

  // Naviguer AVANT de toucher au state
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );

  // Attendre que Flutter détache tous les widgets
  await Future.delayed(const Duration(milliseconds: 500));

  // Seulement maintenant, reset et notify
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
    await _localStorage.saveUser(user); 
     AuthService().updateStoredUser(user); // ← mettre à jour le stockage global des utilisateurs
    notifyListeners();
    try { await _userRepo.updateProfile(user); } catch (_) {}
  }

  void updateUserSync(UserModel user) {
    _currentUser = user;
    _localStorage.saveUser(user);
    notifyListeners();
  }

  Future<void> updateUserLocation(String gpsLocation) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(gpsLocation: gpsLocation);
    await _localStorage.saveUser(_currentUser!); // ← persisté
    notifyListeners();
    try { await _userRepo.updateLocation(gpsLocation); } catch (_) {}
  }

  void setAppLock(bool enabled, {String? password}) {
    _appLockEnabled = enabled;
    if (password != null) _localPassword = password;
    _localStorage.saveAppLock(enabled, password: password); // ← persisté
    notifyListeners();
  }

  bool verifyPassword(String password) => _localPassword == password;

  Future<void> activatePatient(String diseaseType) async {
  if (_currentUser == null) return;
  _currentUser = _currentUser!.copyWith(
    healthStatus: AppConstants.patient,
    diseaseType: diseaseType,
  );
  await _localStorage.saveUser(_currentUser!);
  await AuthService().updateStoredUser(_currentUser!);
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

    final diseaseType = _currentUser!.diseaseType ?? 'hypertension';
    final loadHta = diseaseType == 'hypertension' || diseaseType == 'both';
    final loadDia = diseaseType == 'diabetes' || diseaseType == 'both';

    if (loadHta) {
      final res = await _measureRepo.getHypertensionRecords();
      if (res.success && res.data != null) {
        _hypertensionRecords = res.data!;
      } else {
        // Fallback local, puis mock
        _hypertensionRecords = await _localStorage.loadHypertensionRecords();
        if (_hypertensionRecords.isEmpty) {
          _hypertensionRecords = MockData.hypertensionRecords(_currentUser!.id);
        }
        _measurementsError = res.error?.message;
      }
    }

    if (loadDia) {
      final res = await _measureRepo.getDiabetesRecords();
      if (res.success && res.data != null) {
        _diabetesRecords = res.data!;
      } else {
        _diabetesRecords = await _localStorage.loadDiabetesRecords();
        if (_diabetesRecords.isEmpty) {
          _diabetesRecords = MockData.diabetesRecords(_currentUser!.id);
        }
      }
    }

    _measurementsState = LoadState.success;
    notifyListeners();
  }

  void loadMockMeasurements() {
    if (_currentUser == null) return;
    _hypertensionRecords = MockData.hypertensionRecords(_currentUser!.id);
    _diabetesRecords     = MockData.diabetesRecords(_currentUser!.id);
  }

  Future<void> addHypertensionRecord(HypertensionRecord record) async {
    _hypertensionRecords.insert(0, record);
    await _localStorage.saveHypertensionRecords(_hypertensionRecords); // ← persisté
    notifyListeners();
    try {
      final res = await _measureRepo.addHypertensionRecord(record);
      if (res.success && res.data != null) {
        _hypertensionRecords[0] = res.data!;
        await _localStorage.saveHypertensionRecords(_hypertensionRecords);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> addDiabetesRecord(DiabetesRecord record) async {
    _diabetesRecords.insert(0, record);
    await _localStorage.saveDiabetesRecords(_diabetesRecords); // ← persisté
    notifyListeners();
    try {
      final res = await _measureRepo.addDiabetesRecord(record);
      if (res.success && res.data != null) {
        _diabetesRecords[0] = res.data!;
        await _localStorage.saveDiabetesRecords(_diabetesRecords);
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
  List<SimpleReminder> get simpleReminders => _simpleReminders
    ..sort((a, b) {
      final aTime = DateTime(a.date.year, a.date.month, a.date.day, a.time.hour, a.time.minute);
      final bTime = DateTime(b.date.year, b.date.month, b.date.day, b.time.hour, b.time.minute);
      return bTime.compareTo(aTime); 
  });


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
          : (await _localStorage.loadScreeningReminders()).isNotEmpty
              ? await _localStorage.loadScreeningReminders()
              : MockData.defaultScreeningReminders;
    } catch (_) {
      _screeningReminders = await _localStorage.loadScreeningReminders();
      if (_screeningReminders.isEmpty) {
        _screeningReminders = MockData.defaultScreeningReminders;
      }
    }

    if (isPatient) {
      // Prescriptions
      try {
        final res = await _prescriptionRepo.getPrescriptions();
        _prescriptions = res.success && res.data != null
            ? res.data!
            : (await _localStorage.loadPrescriptions()).isNotEmpty
                ? await _localStorage.loadPrescriptions()
                : MockData.mockPrescriptions;
      } catch (_) {
        _prescriptions = await _localStorage.loadPrescriptions();
        if (_prescriptions.isEmpty) _prescriptions = MockData.mockPrescriptions;
      }

      // Médicaments
      try {
        final res = await _reminderRepo.getMedicationReminders();
        _medicationReminders = res.success && res.data != null
            ? res.data!
            : (await _localStorage.loadMedicationReminders()).isNotEmpty
                ? await _localStorage.loadMedicationReminders()
                : MockData.defaultMedicationReminders;
      } catch (_) {
        _medicationReminders = await _localStorage.loadMedicationReminders();
        if (_medicationReminders.isEmpty) {
          _medicationReminders = MockData.defaultMedicationReminders;
        }
      }

      // Rappels simples
      try {
        final res = await _reminderRepo.getSimpleReminders();
        _simpleReminders = res.success && res.data != null
            ? res.data!
            : (await _localStorage.loadSimpleReminders()).isNotEmpty
                ? await _localStorage.loadSimpleReminders()
                : MockData.defaultSimpleReminders;
      } catch (_) {
        _simpleReminders = await _localStorage.loadSimpleReminders();
        if (_simpleReminders.isEmpty) {
          _simpleReminders = MockData.defaultSimpleReminders;
        }
      }
    }

    _remindersState = LoadState.success;
    notifyListeners();
  }

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
    _localStorage.saveScreeningReminders(_screeningReminders); // ← persisté
    notifyListeners();
    try { _reminderRepo.toggleScreeningReminder(id, _screeningReminders[idx].isCompleted); } catch (_) {}
  }

  // ─── Medication ───
  Future<void> addMedicationReminder(MedicationReminder reminder) async {
    _medicationReminders.add(reminder);
    await _localStorage.saveMedicationReminders(_medicationReminders); // ← persisté
    notifyListeners();
    await _scheduleMedicationAlarms(reminder);
    try { await _reminderRepo.addMedicationReminder(reminder); } catch (_) {}
  }

  Future<void> updateMedicationReminder(MedicationReminder updated) async {
    final idx = _medicationReminders.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return;
    await _cancelMedicationAlarms(_medicationReminders[idx]);
    _medicationReminders[idx] = updated;
    await _localStorage.saveMedicationReminders(_medicationReminders); // ← persisté
    notifyListeners();
    await _scheduleMedicationAlarms(updated);
    try { await _reminderRepo.updateMedicationReminder(updated); } catch (_) {}
  }

  Future<void> deleteMedicationReminder(String id) async {
    final idx = _medicationReminders.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    await _cancelMedicationAlarms(_medicationReminders[idx]);
    _medicationReminders.removeAt(idx);
    await _localStorage.saveMedicationReminders(_medicationReminders); // ← persisté
    notifyListeners();
    try { await _reminderRepo.deleteMedicationReminder(id); } catch (_) {}
  }

  // ─── Simple ───
  Future<void> addSimpleReminder(SimpleReminder reminder) async {
    _simpleReminders.add(reminder);
    await _localStorage.saveSimpleReminders(_simpleReminders); // ← persisté
    await _scheduleSimpleAlarm(reminder);
    try { await _reminderRepo.addSimpleReminder(reminder); } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteSimpleReminder(String id) async {
    await _cancelSimpleAlarm(id);
    _simpleReminders.removeWhere((r) => r.id == id);
    await _localStorage.saveSimpleReminders(_simpleReminders); // ← persisté
    notifyListeners();
    try { await _reminderRepo.deleteSimpleReminder(id); } catch (_) {}
  }

  void toggleSimpleReminder(String id) {
    final idx = _simpleReminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _simpleReminders[idx].isCompleted = !_simpleReminders[idx].isCompleted;
    if (_simpleReminders[idx].isCompleted) _cancelSimpleAlarm(id);
    _localStorage.saveSimpleReminders(_simpleReminders); // ← persisté
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ─── Logique alarme / notification ───
  // ════════════════════════════════════════════════════════════
  Future<void> _scheduleMedicationAlarms(MedicationReminder med) async {
    for (var i = 0; i < med.intakeTimes.length; i++) {
      await _notif.scheduleMedicationReminder(med, med.intakeTimes[i], i);
    }
    if (med.needsRenewal) await _notif.scheduleRenewalAlert(med);
  }

  Future<void> _scheduleSimpleAlarm(SimpleReminder reminder) async {
    await _notif.scheduleSimpleReminder(reminder);
  }

  Future<void> _cancelMedicationAlarms(MedicationReminder med) async {
    await _notif.cancelMedicationReminders(med);
  }

  Future<void> _cancelSimpleAlarm(String id) async {
    await _notif.cancelSimpleReminder(id);
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
    // Persistre les IDs inscrits
    await _localStorage.saveRegisteredEventIds(
      _events.where((e) => e.isRegistered).map((e) => e.id).toList(),
    );
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
    _localStorage.savePrescriptions(_prescriptions); // ← persisté
    notifyListeners();
  }

  Future<void> deletePrescription(String prescriptionId) async {
    final meds = getMedicationsByPrescription(prescriptionId);
    for (final med in meds) await _cancelMedicationAlarms(med);
    _prescriptions.removeWhere((p) => p.id == prescriptionId);
    _medicationReminders.removeWhere((m) => m.prescriptionId == prescriptionId);
    await _localStorage.savePrescriptions(_prescriptions);           // ← persisté
    await _localStorage.saveMedicationReminders(_medicationReminders); // ← persisté
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
    _localStorage.saveAssessmentResult(result); // ← persisté
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
    final mock = MockData.generateMockNotifications();
    _notifications.addAll(mock);
    _localStorage.saveNotifications(_notifications);
    notifyListeners();
  }

  void loadMockNotifications() => _loadMockNotifications();

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _localStorage.saveNotifications(_notifications); // ← persisté
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _localStorage.saveNotifications(_notifications); // ← persisté
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _localStorage.saveNotifications(_notifications); // ← persisté
    notifyListeners();
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _localStorage.saveNotifications(_notifications); // ← persisté
    notifyListeners();
  }


  List<MedicationIntake> _medicationIntakes = [];
List<MedicationIntake> get medicationIntakes => _medicationIntakes;

// Charger les prises dans initWithUser / _loadFromLocal
// Dans _loadFromLocal ajoute :
// _medicationIntakes = await _localStorage.loadMedicationIntakes();

Future<void> confirmMedicationIntake(MedicationReminder med) async {
  if (med.stock <= 0) return;

  final intake = MedicationIntake(
    id: const Uuid().v4(),
    medicationId: med.id,
    medicationName: med.medicationName,
    dosage: med.dosage,
    takenAt: DateTime.now(),
  );

  // Décrémenter le stock
  final updated = MedicationReminder(
    id: med.id,
    medicationName: med.medicationName,
    dosage: med.dosage,
    intakeTimes: med.intakeTimes,
    stock: med.stock - 1,
    renewalAlertThreshold: med.renewalAlertThreshold,
    diseaseType: med.diseaseType,
    prescriptionId: med.prescriptionId,
  );

  // Mettre à jour le médicament
  await updateMedicationReminder(updated);

  // Sauvegarder la prise
  _medicationIntakes.insert(0, intake);
  await _localStorage.saveMedicationIntakes(_medicationIntakes);

  // Envoyer à l'API (pour notifier le médecin)
  try {
  await _intakeRepo.confirmIntake(intake);
} catch (_) {}

  notifyListeners();
}

// Vérifier si déjà pris aujourd'hui à cette heure
bool isTakenToday(String medicationId, TimeOfDay time) {
  final now = DateTime.now();
  return _medicationIntakes.any((i) =>
    i.medicationId == medicationId &&
    i.takenAt.year == now.year &&
    i.takenAt.month == now.month &&
    i.takenAt.day == now.day &&
    i.takenAt.hour == time.hour,
  );
}

  Timer? _notifChecker;

void _startNotificationChecker() {
  _notifChecker?.cancel();
  _notifChecker = Timer.periodic(const Duration(minutes: 1), (_) {
    _checkTriggeredReminders();
  });
}


@override
void dispose() {
  _notifChecker?.cancel();
  super.dispose();
}

void _checkTriggeredReminders() {
  final now = DateTime.now();

  // Rappels simples
  for (final r in _simpleReminders) {
    if (r.isCompleted) continue;
    final reminderTime = DateTime(
      r.date.year, r.date.month, r.date.day,
      r.time.hour, r.time.minute,
    );
    if (reminderTime.year == now.year &&
        reminderTime.month == now.month &&
        reminderTime.day == now.day &&
        reminderTime.hour == now.hour &&
        reminderTime.minute == now.minute) {
      
      // Ajouter à la page notifications
      addNotification(NotificationModel(
        id: '${r.id}_${now.millisecondsSinceEpoch}',
        title: 'Rappel',
        body: r.label,
        type: NotificationType.generalInfo,
        createdAt: now,
      ));

      // Marquer automatiquement comme fait
      toggleSimpleReminder(r.id);
    }
  }

  // Médicaments — inchangé
  for (final med in _medicationReminders) {
    if (!med.isActive || med.stock <= 0) continue;
    for (final t in med.intakeTimes) {
      if (t.hour == now.hour && t.minute == now.minute) {
        addNotification(NotificationModel(
          id: '${med.id}_${t.hour}_${t.minute}_${now.millisecondsSinceEpoch}',
          title: 'Prise de médicament',
          body: '${med.medicationName} ${med.dosage}',
          type: NotificationType.medicationReminder,
          createdAt: now,
        ));
      }
    }
  }
}
}