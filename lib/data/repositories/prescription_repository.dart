import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/models.dart';

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