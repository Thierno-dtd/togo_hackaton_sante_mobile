import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

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