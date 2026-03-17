import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class AppUtils {
  /// Calculate age from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Format date to dd/MM/yyyy
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format date to dd/MM
  static String formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  /// Format time to HH:mm
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format DateTime to HH:mm
  static String formatTimeFromDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Blood pressure status
  static String bpStatus(double systolic, double diastolic) {
    if (systolic >= 180 || diastolic >= 120) return 'Crise ';
    if (systolic >= 140 || diastolic >= 90) return ' stade 2';
    if (systolic >= 130 || diastolic >= 80) return ' stade 1';
    if (systolic >= 120 && diastolic < 80) return 'Élevée';
    if (systolic < 90 || diastolic < 60) return 'Hypotension';
    return 'Normale';
  }

  static Color bpColor(double systolic, double diastolic) {
    if (systolic >= 140 || diastolic >= 90) return AppColors.error;
    if (systolic >= 130 || diastolic >= 80) return AppColors.warning;
    if (systolic < 90 || diastolic < 60) return AppColors.info;
    return AppColors.success;
  }

  /// Glucose status
  static String glucoseStatus(double gPerL, {bool fasting = true}) {
    if (fasting) {
      if (gPerL < 0.70) return 'Hypoglycémie';
      if (gPerL <= 1.00) return 'Normale';
      if (gPerL <= 1.25) return 'Prédiabète';
      return 'Diabète';
    } else {
      if (gPerL < 0.70) return 'Hypoglycémie';
      if (gPerL <= 1.40) return 'Normale';
      if (gPerL <= 2.00) return 'Élevée';
      return 'Diabète';
    }
  }

  static Color glucoseColor(double gPerL) {
    if (gPerL < 0.70 || gPerL > 1.25) return AppColors.error;
    if (gPerL > 1.00) return AppColors.warning;
    return AppColors.success;
  }

  /// Temperature status
  static String temperatureStatus(double temp) {
    if (temp < 36.0) return 'Hypothermie';
    if (temp <= 37.5) return 'Normale';
    if (temp <= 38.5) return 'Fièvre légère';
    if (temp <= 39.5) return 'Fièvre modérée';
    return 'Fièvre élevée';
  }

  static Color temperatureColor(double temp) {
    if (temp < 36.0 || temp > 39.5) return AppColors.error;
    if (temp > 37.5) return AppColors.warning;
    return AppColors.success;
  }

  /// Heart rate status
  static String heartRateStatus(double bpm) {
    if (bpm < 60) return 'Bradycardie';
    if (bpm <= 100) return 'Normale';
    if (bpm <= 120) return 'Élevée';
    return 'Tachycardie';
  }

  static Color heartRateColor(double bpm) {
    if (bpm < 50 || bpm > 120) return AppColors.error;
    if (bpm < 60 || bpm > 100) return AppColors.warning;
    return AppColors.success;
  }

  /// Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.body.copyWith(color: Colors.white)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Risk color
  static Color riskColor(String risk) {
    switch (risk) {
      case AppConstants.riskLow:
        return AppColors.riskLow;
      case AppConstants.riskModerate:
        return AppColors.riskModerate;
      case AppConstants.riskHigh:
        return AppColors.riskHigh;
      default:
        return AppColors.textHint;
    }
  }

  /// Risk label
  static String riskLabel(String risk) {
    switch (risk) {
      case AppConstants.riskLow:
        return 'Risque faible';
      case AppConstants.riskModerate:
        return 'Risque modéré';
      case AppConstants.riskHigh:
        return 'Risque élevé';
      default:
        return 'Non évalué';
    }
  }
}