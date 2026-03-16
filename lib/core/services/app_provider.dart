import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/mock/mock_data.dart';
import '../core/constants/app_constants.dart';

class AppProvider extends ChangeNotifier {
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
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
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

  // ─── Reminders ───
  List<ScreeningReminder> _screeningReminders = [];
  List<MedicationReminder> _medicationReminders = [];
  List<SimpleReminder> _simpleReminders = [];

  List<ScreeningReminder> get screeningReminders => _screeningReminders;
  List<MedicationReminder> get medicationReminders => _medicationReminders;
  List<SimpleReminder> get simpleReminders => _simpleReminders;

  List<ScreeningReminder> get overdueScreening =>
      _screeningReminders.where((r) => !r.isCompleted && r.dueDate.isBefore(DateTime.now())).toList();

  void loadMockReminders() {
    _screeningReminders = MockData.defaultScreeningReminders;
    if (isPatient) {
      _medicationReminders = MockData.defaultMedicationReminders;
      _simpleReminders = MockData.defaultSimpleReminders;
    }
  }

  void toggleScreeningReminder(String id) {
    final idx = _screeningReminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _screeningReminders[idx].isCompleted = !_screeningReminders[idx].isCompleted;
      notifyListeners();
    }
  }

  void addMedicationReminder(MedicationReminder reminder) {
    _medicationReminders.add(reminder);
    notifyListeners();
  }

  void addSimpleReminder(SimpleReminder reminder) {
    _simpleReminders.add(reminder);
    notifyListeners();
  }

  void deleteSimpleReminder(String id) {
    _simpleReminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void toggleSimpleReminder(String id) {
    final idx = _simpleReminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _simpleReminders[idx].isCompleted = !_simpleReminders[idx].isCompleted;
      notifyListeners();
    }
  }

  // ─── Daily Advice ───
  List<AdviceModel> _dailyAdvice = [];
  List<AdviceModel> get dailyAdvice => _dailyAdvice;

  void loadDailyAdvice(String diseaseType) {
    final all = MockData.adviceList.where((a) =>
        a.diseaseType == 'all' || a.diseaseType == diseaseType).toList();
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

  void loadEvents() {
    _events = MockData.events;
  }

  void toggleEventRegistration(String eventId) {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _events[idx].isRegistered = !_events[idx].isRegistered;
      notifyListeners();
    }
  }

  // ─── Init ───
  void initWithUser(UserModel user) {
    _currentUser = user;
    _isLoggedIn = true;
    loadMockMeasurements();
    loadMockReminders();
    loadDailyAdvice(user.diseaseType ?? 'all');
    loadEvents();
    notifyListeners();
  }
}