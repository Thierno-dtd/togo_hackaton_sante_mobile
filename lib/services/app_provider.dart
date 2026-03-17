import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/mock/mock_data.dart';
import '../core/constants/app_constants.dart';
import '../data/models/notification_model.dart';
import 'notification_service.dart';

class AppProvider extends ChangeNotifier {

  final NotificationService _notificationService = NotificationService();
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
      loadMockPrescriptions();
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
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  // ─── Scheduling automatique ───
  Future<void> scheduleAllReminders() async {
    await _notificationService.initialize();

    // Médicaments
    for (final med in _medicationReminders) {
      for (final time in med.intakeTimes) {
        await _notificationService.scheduleMedicationReminder(med, time);
      }
      if (med.needsRenewal) {
        await _notificationService.scheduleRenewalAlert(med);
      }
    }

    // Dépistages
    for (final screening in _screeningReminders) {
      await _notificationService.scheduleScreeningReminder(screening);
    }
  }

  // ─── Init mis à jour ───
  void initWithUser(UserModel user) async {
    _currentUser = user;
    _isLoggedIn = true;
    loadMockMeasurements();
    loadMockReminders();
    loadMockNotifications();
    loadDailyAdvice(user.diseaseType ?? 'all');
    loadEvents();
    
    // Programmer les notifications
    await scheduleAllReminders();
    
    notifyListeners();
  }

   // ─── Prescriptions ───
  List<Prescription> _prescriptions = [];
  List<Prescription> get prescriptions => _prescriptions;

  // Obtenir les médicaments par ordonnance
  List<MedicationReminder> getMedicationsByPrescription(String prescriptionId) {
    return _medicationReminders
        .where((m) => m.prescriptionId == prescriptionId)
        .toList();
  }

  // Obtenir l'ordonnance d'un médicament
  Prescription? getPrescriptionForMedication(MedicationReminder medication) {
    if (medication.prescriptionId == null) return null;
    return _prescriptions.firstWhere(
      (p) => p.id == medication.prescriptionId,
      orElse: () => _prescriptions.first, // Fallback
    );
  }

  void loadMockPrescriptions() {
    _prescriptions = MockData.mockPrescriptions;
    notifyListeners();
  }

  void addPrescription(Prescription prescription) {
    _prescriptions.insert(0, prescription);
    notifyListeners();
  }

  void deletePrescription(String prescriptionId) {
    _prescriptions.removeWhere((p) => p.id == prescriptionId);
    // Supprimer aussi les médicaments liés
    _medicationReminders.removeWhere((m) => m.prescriptionId == prescriptionId);
    notifyListeners();
  }

    void updateMedicationReminder(MedicationReminder updated) {
    final idx = _medicationReminders.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _medicationReminders[idx] = updated;
      notifyListeners();
    }
  }
 
  void deleteMedicationReminder(String id) {
    _medicationReminders.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // Méthode helper pour grouper les médicaments par ordonnance
  Map<String, List<MedicationReminder>> get medicationsByPrescription {
    final Map<String, List<MedicationReminder>> grouped = {};
    
    for (final med in _medicationReminders) {
      final prescriptionId = med.prescriptionId ?? 'no_prescription';
      if (!grouped.containsKey(prescriptionId)) {
        grouped[prescriptionId] = [];
      }
      grouped[prescriptionId]!.add(med);
    }
    
    return grouped;
  }

}