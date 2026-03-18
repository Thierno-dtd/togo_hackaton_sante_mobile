import 'package:lamesse_dama_mobile/core/network/api_client.dart';
import 'package:lamesse_dama_mobile/core/network/api_endpoints.dart';

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