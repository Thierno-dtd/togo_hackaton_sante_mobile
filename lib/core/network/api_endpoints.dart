
class ApiEndpoints {
  // ── Base URL — changer selon l'environnement ──
  static const String baseUrl = 'https://api.lamessedama.tg/v1';

  // ── Auth ──
  static const String login          = '/auth/login';
  static const String register       = '/auth/register';
  static const String refreshToken   = '/auth/refresh';
  static const String logout         = '/auth/logout';
  static const String googleAuth     = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';

  // ── User ──
  static const String me             = '/users/me';
  static const String updateProfile  = '/users/me';
  static const String updateLocation = '/users/me/location';
  static const String uploadDocument = '/users/me/documents';
  static const String activatePatient = '/users/me/patient-request';

  // ── Measurements ──
  static const String hypertension       = '/measurements/hypertension';
  static const String diabetes           = '/measurements/diabetes';

  // ── Reminders ──
  static const String screeningReminders  = '/reminders/screening';
  static const String medicationReminders = '/reminders/medications';
  static const String simpleReminders     = '/reminders/simple';

  // ── Prescriptions ──
  static const String prescriptions       = '/prescriptions';
  static String prescriptionById(String id) => '/prescriptions/$id';
  static String prescriptionImage(String id) => '/prescriptions/$id/image';

  // ── Advice ──
  static const String dailyAdvice  = '/advice/daily';
  static const String allAdvice    = '/advice';

  // ── Events ──
  static const String events                    = '/events';
  static String eventRegister(String id)        => '/events/$id/register';
  static String eventUnregister(String id)      => '/events/$id/unregister';

  // ── Notifications ──
  static const String notifications             = '/notifications';
  static String notificationRead(String id)     => '/notifications/$id/read';
  static const String notificationsReadAll      = '/notifications/read-all';
  static String deleteNotification(String id)   => '/notifications/$id';

  // ── Self Assessment ──
  static const String assessmentQuestions = '/assessment/questions';
  static const String assessmentSubmit    = '/assessment/submit';

  // ── Medication Intakes ──
  static String medicationIntakes(String id) => '/medications/$id/intakes';
}