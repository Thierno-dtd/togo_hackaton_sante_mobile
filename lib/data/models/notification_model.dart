import 'package:flutter/material.dart';
enum NotificationType {
  medicationReminder,
  medicationRenewal,
  missedMeasurement,
  doctorAppointment,
  screeningReminder,
  eventReminder,
  generalInfo,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });

  NotificationModel copyWith({
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );
  }

  IconData get icon {
    switch (type) {
    case NotificationType.medicationReminder:
    return Icons.medication;
    case NotificationType.medicationRenewal:
    return Icons.inventory;
    case NotificationType.missedMeasurement:
    return Icons.warning_amber;
    case NotificationType.doctorAppointment:
    return Icons.local_hospital;
    case NotificationType.screeningReminder:
    return Icons.medical_services;
    case NotificationType.eventReminder:
    return Icons.event;
    case NotificationType.generalInfo:
    return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
    case NotificationType.medicationReminder:
    return const Color(0xFF163344);
    case NotificationType.medicationRenewal:
    return const Color(0xFFF59E0B);
    case NotificationType.missedMeasurement:
    return const Color(0xFFEF4444);
    case NotificationType.doctorAppointment:
    return const Color(0xFF10B981);
    case NotificationType.screeningReminder:
    return const Color(0xFF3B82F6);
    case NotificationType.eventReminder:
    return const Color(0xFF8B5CF6);
    case NotificationType.generalInfo:
    return const Color(0xFF64748B);
    }
  }
}