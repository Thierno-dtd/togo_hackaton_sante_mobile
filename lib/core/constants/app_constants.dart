class AppConstants {
  static const String appName = 'Lamesse Dama';
  static const String appTagline = 'Votre santé, notre priorité';

  // Shared Prefs keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyCurrentUser = 'current_user';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyLocalPassword = 'local_password';
  static const String keyLastAdviceDate = 'last_advice_date';
  static const String keyDailyAdviceIds = 'daily_advice_ids';

  // Disease types
  static const String hypertension = 'hypertension';
  static const String diabetes = 'diabetes';

  // User health status
  static const String nonPatient = 'non_patient';
  static const String patient = 'patient';
  static const String pendingValidation = 'pending_validation';

  // Risk levels
  static const String riskLow = 'low';
  static const String riskModerate = 'moderate';
  static const String riskHigh = 'high';

  // Normal ranges
  static const double normalSystolicMin = 90;
  static const double normalSystolicMax = 120;
  static const double normalDiastolicMin = 60;
  static const double normalDiastolicMax = 80;
  static const double normalGlucoseMin = 0.70;
  static const double normalGlucoseMax = 1.10;
  static const double normalTempMin = 36.1;
  static const double normalTempMax = 37.5;
  static const double normalHeartRateMin = 60;
  static const double normalHeartRateMax = 100;

  // Pagination
  static const int advicePerDay = 3;
  static const int recentMeasurementsCount = 10;
}