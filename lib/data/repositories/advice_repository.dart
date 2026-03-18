import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

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
