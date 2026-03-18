import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

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