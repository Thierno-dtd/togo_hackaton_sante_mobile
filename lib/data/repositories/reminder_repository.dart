import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

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