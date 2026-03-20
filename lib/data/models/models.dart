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
  String? diseaseType; // hypertension | diabetes | both
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

  bool get hasHypertension => diseaseType == 'hypertension' || diseaseType == 'both';
  bool get hasDiabetes => diseaseType == 'diabetes' || diseaseType == 'both';
  bool get hasBoth => diseaseType == 'both';

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

  static UserModel fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '',
    firstName: j['first_name'] ?? j['firstName'] ?? '',
    lastName: j['last_name'] ?? j['lastName'] ?? '',
    email: j['email'] ?? '',
    phone: j['phone'] ?? '',
    dateOfBirth: DateTime.tryParse(j['date_of_birth'] ?? j['dateOfBirth'] ?? '') ?? DateTime(1990),
    residence: j['residence'] ?? '',
    district: j['district'] ?? '',
    healthStatus: j['health_status'] ?? j['healthStatus'] ?? 'non_patient',
    diseaseType: j['disease_type'] ?? j['diseaseType'],
    weight: j['weight'] != null ? double.tryParse(j['weight'].toString()) : null,
    height: j['height'] != null ? double.tryParse(j['height'].toString()) : null,
    gpsLocation: j['gps_location'] ?? j['gpsLocation'],
    avatarUrl: j['avatar_url'] ?? j['avatarUrl'],
    isGoogleUser: j['is_google_user'] ?? j['isGoogleUser'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
    'residence': residence,
    'district': district,
    'health_status': healthStatus,
    if (diseaseType != null) 'disease_type': diseaseType,
    if (weight != null) 'weight': weight,
    if (height != null) 'height': height,
    if (gpsLocation != null) 'gps_location': gpsLocation,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
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

  static AdviceModel fromJson(Map<String, dynamic> j) => AdviceModel(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    content: j['content'] ?? '',
    category: j['category'] ?? 'lifestyle',
    diseaseType: j['disease_type'] ?? j['diseaseType'] ?? 'all',
    iconName: j['icon_name'] ?? j['iconName'] ?? 'lightbulb',
    color: Color(int.tryParse(
      (j['color'] ?? '0xFF10B981').replaceAll('#', '0xFF'),
    ) ?? 0xFF10B981),
  );

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
  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  static EventModel fromJson(Map<String, dynamic> j) {
    final timeStr = (j['time'] ?? '08:00') as String;
    final parts = timeStr.split(':');
    return EventModel(
      id: j['id'] ?? '',
      title: j['title'] ?? '',
      description: j['description'],
      imageUrl: j['image_url'] ?? j['imageUrl'],
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      time: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
      location: j['location'] ?? '',
      organizer: j['organizer'] ?? '',
      category: j['category'] ?? 'health',
      maxParticipants: j['max_participants'] ?? j['maxParticipants'],
      isRegistered: j['is_registered'] ?? j['isRegistered'] ?? false,
    );
  }
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

  static ScreeningReminder fromJson(Map<String, dynamic> j) => ScreeningReminder(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    dueDate: DateTime.tryParse(j['due_date'] ?? j['dueDate'] ?? '') ?? DateTime.now(),
    isCompleted: j['is_completed'] ?? j['isCompleted'] ?? false,
    frequency: j['frequency'] ?? 'annual',
  );

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

  static MedicationReminder fromJson(Map<String, dynamic> j) {
    final times = (j['intake_times'] ?? j['intakeTimes'] ?? []) as List;
    return MedicationReminder(
      id: j['id'] ?? '',
      medicationName: j['medication_name'] ?? j['medicationName'] ?? '',
      dosage: j['dosage'] ?? '',
      intakeTimes: times.map((t) {
        if (t is String) {
          final parts = t.split(':');
          return TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 7,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
        return const TimeOfDay(hour: 7, minute: 0);
      }).toList(),
      stock: j['stock'] ?? 0,
      renewalAlertThreshold: j['renewal_alert_threshold'] ?? j['renewalAlertThreshold'] ?? 7,
      diseaseType: j['disease_type'] ?? j['diseaseType'] ?? 'all',
      prescriptionId: j['prescription_id'] ?? j['prescriptionId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'medication_name': medicationName,
    'dosage': dosage,
    'intake_times': intakeTimes
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList(),
    'stock': stock,
    'renewal_alert_threshold': renewalAlertThreshold,
    'disease_type': diseaseType,
    if (prescriptionId != null) 'prescription_id': prescriptionId,
  };

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

  static SimpleReminder fromJson(Map<String, dynamic> j) {
    final timeStr = (j['time'] ?? '07:00') as String;
    final parts = timeStr.split(':');
    return SimpleReminder(
      id: j['id'] ?? '',
      label: j['label'] ?? '',
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      time: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 7,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
      isCompleted: j['is_completed'] ?? j['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'date': '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
    'time': '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
  };
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

  static Prescription fromJson(Map<String, dynamic> j) => Prescription(
    id: j['id'] ?? '',
    reference: j['reference'] ?? '',
    imageUrl: j['image_url'] ?? j['imageUrl'],
    prescriptionDate: DateTime.tryParse(j['prescription_date'] ?? j['prescriptionDate'] ?? '') ?? DateTime.now(),
    doctorName: j['doctor_name'] ?? j['doctorName'] ?? '',
    hospital: j['hospital'],
    createdAt: DateTime.tryParse(j['created_at'] ?? j['createdAt'] ?? '') ?? DateTime.now(),
  );

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

  static HypertensionRecord fromJson(Map<String, dynamic> j) => HypertensionRecord(
    id: j['id'] ?? '',
    userId: j['user_id'] ?? j['userId'] ?? '',
    systolic: double.tryParse(j['systolic'].toString()) ?? 0,
    diastolic: double.tryParse(j['diastolic'].toString()) ?? 0,
    temperature: double.tryParse(j['temperature'].toString()) ?? 37.0,
    heartRate: double.tryParse(j['heart_rate']?.toString() ?? j['heartRate'].toString()) ?? 72,
    measuredAt: DateTime.tryParse(j['measured_at'] ?? j['measuredAt'] ?? '') ?? DateTime.now(),
    comment: j['comment'],
    context: j['context'] ?? 'repos',
  );

  Map<String, dynamic> toJson() => {
    'systolic': systolic,
    'diastolic': diastolic,
    'temperature': temperature,
    'heart_rate': heartRate,
    'measured_at': measuredAt.toIso8601String(),
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
    'context': context,
  };
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

  static DiabetesRecord fromJson(Map<String, dynamic> j) => DiabetesRecord(
    id: j['id'] ?? '',
    userId: j['user_id'] ?? j['userId'] ?? '',
    glucoseLevel: double.tryParse(j['glucose_level']?.toString() ?? j['glucoseLevel'].toString()) ?? 0,
    temperature: double.tryParse(j['temperature'].toString()) ?? 37.0,
    heartRate: double.tryParse(j['heart_rate']?.toString() ?? j['heartRate'].toString()) ?? 72,
    measuredAt: DateTime.tryParse(j['measured_at'] ?? j['measuredAt'] ?? '') ?? DateTime.now(),
    comment: j['comment'],
    context: j['context'] ?? 'a_jeun',
  ); 

  Map<String, dynamic> toJson() => {
    'glucose_level': glucoseLevel,
    'temperature': temperature,
    'heart_rate': heartRate,
    'measured_at': measuredAt.toIso8601String(),
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
    'context': context,
  };
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