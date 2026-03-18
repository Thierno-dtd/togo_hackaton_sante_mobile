import 'package:flutter/material.dart';

// ─── User Model ───
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String residence;
  final String district;
  String healthStatus; // non_patient | patient | pending_validation
  String? diseaseType; // hypertension | diabetes
  double? weight;
  double? height;
  String? gpsLocation;
  String? avatarUrl;
  bool isGoogleUser;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.residence,
    required this.district,
    this.healthStatus = 'non_patient',
    this.diseaseType,
    this.weight,
    this.height,
    this.gpsLocation,
    this.avatarUrl,
    this.isGoogleUser = false,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  bool get isPatient => healthStatus == 'patient';
  bool get isPendingValidation => healthStatus == 'pending_validation';

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? residence,
    String? district,
    String? healthStatus,
    String? diseaseType,
    double? weight,
    double? height,
    String? gpsLocation,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      residence: residence ?? this.residence,
      district: district ?? this.district,
      healthStatus: healthStatus ?? this.healthStatus,
      diseaseType: diseaseType ?? this.diseaseType,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGoogleUser: this.isGoogleUser,
    );
  }
}

// ─── Advice Model ───
class AdviceModel {
  final String id;
  final String title;
  final String content;
  final String category; // nutrition | activity | medication | prevention | lifestyle
  final String diseaseType; // all | hypertension | diabetes
  final String iconName;
  final Color color;

  const AdviceModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.diseaseType,
    required this.iconName,
    required this.color,
  });
}

// ─── Event Model ───
class EventModel {
  final String id;
  final String title;
  final String? description;       // texte de description (optionnel)
  final String? imageUrl;          // image depuis une URL réseau
  final String? imageLocalPath;    // image depuis le stockage local
  final DateTime date;
  final TimeOfDay time;
  final String location;
  final String organizer;
  final String category;           // sport | health | cleaning | awareness | campaign
  final int? maxParticipants;
  bool isRegistered;
 
  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.imageLocalPath,
    required this.date,
    required this.time,
    required this.location,
    required this.organizer,
    required this.category,
    this.maxParticipants,
    this.isRegistered = false,
  });
 
  /// True si l'événement a une image (locale ou réseau)
  bool get hasImage => imageUrl != null || imageLocalPath != null;
 
  /// True si l'événement a une description textuelle non vide
  bool get hasDescription =>
      description != null && description!.trim().isNotEmpty;
}


// ─── Reminder Models ───
class ScreeningReminder {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final String frequency; // annual | biannual | quarterly | monthly
  ScreeningReminder({
  required this.id,
  required this.title,
  required this.description,
  required this.dueDate,
  this.isCompleted = false,
  required this.frequency,
  });
}
class MedicationReminder {
  final String id;
  final String medicationName;
  final String dosage;
  final List<TimeOfDay> intakeTimes;
  int stock;
  final int renewalAlertThreshold;
  final bool isActive;
  final String diseaseType;
  String? prescriptionId; 
  
  MedicationReminder({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.intakeTimes,
    required this.stock,
    required this.renewalAlertThreshold,
    this.isActive = true,
    required this.diseaseType,
    this.prescriptionId, 
  });
    bool get needsRenewal => stock <= renewalAlertThreshold;
    int get daysRemaining {
    final dailyConsumption = intakeTimes.length;
    if (dailyConsumption == 0) return 0;
    return (stock / dailyConsumption).floor();
  }
}
class SimpleReminder {
  final String id;
  final String label;
  final DateTime date;
  final TimeOfDay time;
  bool isCompleted;

  SimpleReminder({
    required this.id,
    required this.label,
    required this.date,
    required this.time,
    this.isCompleted = false,
  });
}

// ─── NOUVEAU MODÈLE ───
class Prescription {
  final String id;
  final String reference;
  final String? imageUrl;
  final String? imageLocalPath;
  final DateTime prescriptionDate;
  final String doctorName;
  final String? hospital;
  final DateTime createdAt;

  const Prescription({
    required this.id,
    required this.reference,
    this.imageUrl,
    this.imageLocalPath,
    required this.prescriptionDate,
    required this.doctorName,
    this.hospital,
    required this.createdAt,
  });

  bool get hasImage => imageUrl != null || imageLocalPath != null;
}

// ─── Self Assessment Models ───
class SelfAssessmentQuestion {
  final String id;
  final String question;
  final List<SelfAssessmentOption> options;
  final String category;

  const SelfAssessmentQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.category,
  });
}

class SelfAssessmentOption {
  final String id;
  final String label;
  final int riskScore; // 0 = no risk, 1 = low, 2 = moderate, 3 = high

  const SelfAssessmentOption({
    required this.id,
    required this.label,
    required this.riskScore,
  });
}

class SelfAssessmentResult {
  final String id;
  final DateTime date;
  final int totalScore;
  final String riskLevel; // low | moderate | high
  final Map<String, int> categoryScores;
  final List<String> recommendations;

  SelfAssessmentResult({
    required this.id,
    required this.date,
    required this.totalScore,
    required this.riskLevel,
    required this.categoryScores,
    required this.recommendations,
  });
}

// ─── Patient Request Model ───
class PatientRequest {
  final String id;
  final String userId;
  final String diseaseType;
  final String doctorEmail;
  final String hospital;
  String status; // pending | approved | rejected
  final DateTime submittedAt;
  String? rejectionReason;

  PatientRequest({
    required this.id,
    required this.userId,
    required this.diseaseType,
    required this.doctorEmail,
    required this.hospital,
    this.status = 'pending',
    required this.submittedAt,
    this.rejectionReason,
  });
}

// ─── Medical Records ───
class HypertensionRecord {
  final String id;
  final String userId;
  final double systolic;
  final double diastolic;
  final double temperature;
  final double heartRate;
  final DateTime measuredAt;
  final String? comment;
  final String context; // repos | apres_sport | stress | matin | soir

  HypertensionRecord({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    required this.temperature,
    required this.heartRate,
    required this.measuredAt,
    this.comment,
    this.context = 'repos',
  });
}

class DiabetesRecord {
  final String id;
  final String userId;
  final double glucoseLevel;
  final double temperature;
  final double heartRate;
  final DateTime measuredAt;
  final String? comment;
  final String context; // a_jeun | post_prandial | apres_sport | aleatoire

  DiabetesRecord({
    required this.id,
    required this.userId,
    required this.glucoseLevel,
    required this.temperature,
    required this.heartRate,
    required this.measuredAt,
    this.comment,
    this.context = 'a_jeun',
  });
}

// ─── Hospital Model ───
class Hospital {
  final String id;
  final String name;
  final String address;
  final String district;
  final String phone;

  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.phone,
  });
}