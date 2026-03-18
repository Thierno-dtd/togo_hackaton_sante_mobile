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

