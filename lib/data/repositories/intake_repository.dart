import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

class IntakeRepository {
  final ApiClient _api = ApiClient();

  Future<ApiResponse<void>> confirmIntake(MedicationIntake intake) async {
    return _api.post(
      ApiEndpoints.medicationIntakes(intake.medicationId),
      data: intake.toJson(),
    );
  }

  Future<ApiResponse<List<MedicationIntake>>> getIntakes(String medicationId) async {
    return _api.get<List<MedicationIntake>>(
      ApiEndpoints.medicationIntakes(medicationId),
      fromJson: (data) => (data['intakes'] as List)
          .map((i) => MedicationIntake.fromJson(i))
          .toList(),
    );
  }
}