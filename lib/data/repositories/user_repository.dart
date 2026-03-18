import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

class UserRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<UserModel>> updateProfile(UserModel user) async {
    return _api.put<UserModel>(
      ApiEndpoints.updateProfile,
      data: {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'phone': user.phone,
        'residence': user.residence,
        'district': user.district,
        if (user.weight != null) 'weight': user.weight,
        if (user.height != null) 'height': user.height,
      },
      fromJson: (data) => UserModel.fromJson(data['user'] ?? data),
    );
  }

  Future<ApiResponse<void>> updateLocation(String gpsLocation) async {
    return _api.patch(
      ApiEndpoints.updateLocation,
      data: {'gps_location': gpsLocation},
    );
  }

  Future<ApiResponse<void>> submitPatientRequest({
    required String diseaseType,
    required String doctorEmail,
    required String hospital,
    required File receiptFile,
    required File carnetFile,
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'disease_type': diseaseType,
      'doctor_email': doctorEmail,
      'hospital': hospital,
      'receipt': await MultipartFile.fromFile(
        receiptFile.path,
        filename: 'receipt.jpg',
      ),
      'carnet': await MultipartFile.fromFile(
        carnetFile.path,
        filename: 'carnet.jpg',
      ),
    });

    return _api.upload(
      ApiEndpoints.activatePatient,
      formData,
      onProgress: onProgress,
    );
  }
}

// ════════════════════════════════════════════════════════════
// lib/data/repositories/measurement_repository.dart
// ════════════════════════════════════════════════════════════
class MeasurementRepository {
  final ApiClient _api = ApiClient();

  // ── Hypertension ──
  Future<ApiResponse<List<HypertensionRecord>>> getHypertensionRecords({
    int page = 1,
    int limit = 20,
  }) async {
    return _api.get<List<HypertensionRecord>>(
      ApiEndpoints.hypertension,
      queryParams: {'page': page, 'limit': limit},
      fromJson: (data) => (data['records'] as List)
          .map((r) => HypertensionRecord.fromJson(r))
          .toList(),
    );
  }

  Future<ApiResponse<HypertensionRecord>> addHypertensionRecord(
      HypertensionRecord record) async {
    return _api.post<HypertensionRecord>(
      ApiEndpoints.hypertension,
      data: record.toJson(),
      fromJson: (data) => HypertensionRecord.fromJson(data['record'] ?? data),
    );
  }

  // ── Diabète ──
  Future<ApiResponse<List<DiabetesRecord>>> getDiabetesRecords({
    int page = 1,
    int limit = 20,
  }) async {
    return _api.get<List<DiabetesRecord>>(
      ApiEndpoints.diabetes,
      queryParams: {'page': page, 'limit': limit},
      fromJson: (data) => (data['records'] as List)
          .map((r) => DiabetesRecord.fromJson(r))
          .toList(),
    );
  }

  Future<ApiResponse<DiabetesRecord>> addDiabetesRecord(
      DiabetesRecord record) async {
    return _api.post<DiabetesRecord>(
      ApiEndpoints.diabetes,
      data: record.toJson(),
      fromJson: (data) => DiabetesRecord.fromJson(data['record'] ?? data),
    );
  }
}

// ════════════════════════════════════════════════════════════
// lib/data/repositories/reminder_repository.dart
// ════════════════════════════════════════════════════════════
class ReminderRepository {
  final ApiClient _api = ApiClient();

  // ── Dépistages ──
  Future<ApiResponse<List<ScreeningReminder>>> getScreeningReminders() async {
    return _api.get<List<ScreeningReminder>>(
      ApiEndpoints.screeningReminders,
      fromJson: (data) => (data['reminders'] as List)
          .map((r) => ScreeningReminder.fromJson(r))
          .toList(),
    );
  }

  Future<ApiResponse<void>> toggleScreeningReminder(
      String id, bool completed) async {
    return _api.patch(
      '${ApiEndpoints.screeningReminders}/$id',
      data: {'completed': completed},
    );
  }

  // ── Médicaments ──
  Future<ApiResponse<List<MedicationReminder>>> getMedicationReminders() async {
    return _api.get<List<MedicationReminder>>(
      ApiEndpoints.medicationReminders,
      fromJson: (data) => (data['reminders'] as List)
          .map((r) => MedicationReminder.fromJson(r))
          .toList(),
    );
  }

  Future<ApiResponse<MedicationReminder>> addMedicationReminder(
      MedicationReminder reminder) async {
    return _api.post<MedicationReminder>(
      ApiEndpoints.medicationReminders,
      data: reminder.toJson(),
      fromJson: (data) => MedicationReminder.fromJson(data['reminder'] ?? data),
    );
  }

  Future<ApiResponse<MedicationReminder>> updateMedicationReminder(
      MedicationReminder reminder) async {
    return _api.put<MedicationReminder>(
      '${ApiEndpoints.medicationReminders}/${reminder.id}',
      data: reminder.toJson(),
      fromJson: (data) => MedicationReminder.fromJson(data['reminder'] ?? data),
    );
  }

  Future<ApiResponse<void>> deleteMedicationReminder(String id) async {
    return _api.delete('${ApiEndpoints.medicationReminders}/$id');
  }

  // ── Rappels simples ──
  Future<ApiResponse<List<SimpleReminder>>> getSimpleReminders() async {
    return _api.get<List<SimpleReminder>>(
      ApiEndpoints.simpleReminders,
      fromJson: (data) => (data['reminders'] as List)
          .map((r) => SimpleReminder.fromJson(r))
          .toList(),
    );
  }

  Future<ApiResponse<SimpleReminder>> addSimpleReminder(
      SimpleReminder reminder) async {
    return _api.post<SimpleReminder>(
      ApiEndpoints.simpleReminders,
      data: reminder.toJson(),
      fromJson: (data) => SimpleReminder.fromJson(data['reminder'] ?? data),
    );
  }

  Future<ApiResponse<void>> deleteSimpleReminder(String id) async {
    return _api.delete('${ApiEndpoints.simpleReminders}/$id');
  }
}

// ════════════════════════════════════════════════════════════
// lib/data/repositories/prescription_repository.dart
// ════════════════════════════════════════════════════════════
class PrescriptionRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<List<Prescription>>> getPrescriptions() async {
    return _api.get<List<Prescription>>(
      ApiEndpoints.prescriptions,
      fromJson: (data) => (data['prescriptions'] as List)
          .map((p) => Prescription.fromJson(p))
          .toList(),
    );
  }

  Future<ApiResponse<Prescription>> addPrescription(
    Prescription prescription, {
    File? imageFile,
    void Function(int, int)? onProgress,
  }) async {
    if (imageFile != null) {
      final formData = FormData.fromMap({
        'reference': prescription.reference,
        'doctor_name': prescription.doctorName,
        if (prescription.hospital != null) 'hospital': prescription.hospital,
        'prescription_date':
            prescription.prescriptionDate.toIso8601String().split('T')[0],
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'prescription.jpg',
        ),
      });
      return _api.upload<Prescription>(
        ApiEndpoints.prescriptions,
        formData,
        fromJson: (data) => Prescription.fromJson(data['prescription'] ?? data),
        onProgress: onProgress,
      );
    } else {
      return _api.post<Prescription>(
        ApiEndpoints.prescriptions,
        data: {
          'reference': prescription.reference,
          'doctor_name': prescription.doctorName,
          if (prescription.hospital != null) 'hospital': prescription.hospital,
          'prescription_date':
              prescription.prescriptionDate.toIso8601String().split('T')[0],
        },
        fromJson: (data) => Prescription.fromJson(data['prescription'] ?? data),
      );
    }
  }

  Future<ApiResponse<void>> deletePrescription(String id) async {
    return _api.delete(ApiEndpoints.prescriptionById(id));
  }
}

// ════════════════════════════════════════════════════════════
// lib/data/repositories/event_repository.dart
// ════════════════════════════════════════════════════════════
class EventRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<List<EventModel>>> getEvents() async {
    return _api.get<List<EventModel>>(
      ApiEndpoints.events,
      fromJson: (data) =>
          (data['events'] as List).map((e) => EventModel.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<void>> registerForEvent(String eventId) async {
    return _api.post(ApiEndpoints.eventRegister(eventId));
  }

  Future<ApiResponse<void>> unregisterFromEvent(String eventId) async {
    return _api.delete(ApiEndpoints.eventUnregister(eventId));
  }
}

// ════════════════════════════════════════════════════════════
// lib/data/repositories/advice_repository.dart
// ════════════════════════════════════════════════════════════
class AdviceRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<List<AdviceModel>>> getDailyAdvice({
    required String diseaseType,
  }) async {
    return _api.get<List<AdviceModel>>(
      ApiEndpoints.dailyAdvice,
      queryParams: {'disease_type': diseaseType},
      fromJson: (data) =>
          (data['advice'] as List).map((a) => AdviceModel.fromJson(a)).toList(),
    );
  }

  Future<ApiResponse<List<AdviceModel>>> getAllAdvice({
    String? category,
    String? diseaseType,
  }) async {
    return _api.get<List<AdviceModel>>(
      ApiEndpoints.allAdvice,
      queryParams: {
        if (category != null) 'category': category,
        if (diseaseType != null) 'disease_type': diseaseType,
      },
      fromJson: (data) =>
          (data['advice'] as List).map((a) => AdviceModel.fromJson(a)).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// lib/data/repositories/notification_repository.dart
// ════════════════════════════════════════════════════════════
class NotificationRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<List<dynamic>>> getNotifications() async {
    return _api.get(
      ApiEndpoints.notifications,
      fromJson: (data) => data['notifications'] as List,
    );
  }

  Future<ApiResponse<void>> markAsRead(String id) async {
    return _api.patch(ApiEndpoints.notificationRead(id));
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    return _api.patch(ApiEndpoints.notificationsReadAll);
  }

  Future<ApiResponse<void>> delete(String id) async {
    return _api.delete(ApiEndpoints.deleteNotification(id));
  }

  // ── Enregistrer le token FCM pour les push notifications ──
  Future<ApiResponse<void>> registerFcmToken(String fcmToken) async {
    return _api.post(
      '/users/me/fcm-token',
      data: {'fcm_token': fcmToken},
    );
  }
}