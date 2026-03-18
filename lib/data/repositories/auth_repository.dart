import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/token_storage.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();
  final TokenStorage _tokens = TokenStorage();

  // ── Login email/password ──
  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<UserModel>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
      fromJson: (data) {
        // Sauvegarder les tokens
        _tokens.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: data['user']['id'],
        );
        return UserModel.fromJson(data['user']);
      },
    );
    return res;
  }

  // ── Login Google ──
  Future<ApiResponse<UserModel>> loginWithGoogle({
    required String idToken,
  }) async {
    final res = await _api.post<UserModel>(
      ApiEndpoints.googleAuth,
      data: {'id_token': idToken},
      fromJson: (data) {
        _tokens.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: data['user']['id'],
        );
        return UserModel.fromJson(data['user']);
      },
    );
    return res;
  }

  // ── Inscription ──
  Future<ApiResponse<UserModel>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required DateTime dateOfBirth,
    required String residence,
    required String district,
  }) async {
    final res = await _api.post<UserModel>(
      ApiEndpoints.register,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'residence': residence,
        'district': district,
      },
      fromJson: (data) {
        _tokens.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: data['user']['id'],
        );
        return UserModel.fromJson(data['user']);
      },
    );
    return res;
  }

  // ── Logout ──
  Future<void> logout() async {
    await _api.post(ApiEndpoints.logout);
    await _tokens.clearAll();
  }

  // ── Récupérer le profil courant ──
  Future<ApiResponse<UserModel>> getMe() async {
    return _api.get<UserModel>(
      ApiEndpoints.me,
      fromJson: (data) => UserModel.fromJson(data['user'] ?? data),
    );
  }
}