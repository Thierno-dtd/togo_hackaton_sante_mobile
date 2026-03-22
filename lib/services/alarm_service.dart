import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const _alarmChannel = MethodChannel('com.example.lamesse_dama_mobile/alarm');

class AlarmService {
  static bool _isRinging = false;
  static bool get isRinging => _isRinging;

  // ── Son natif via MethodChannel ──
  static Future<void> startNativeAlarm({
    required String title,
    required String body,
    required String type,
  }) async {
    _isRinging = true;
    try {
      await _alarmChannel.invokeMethod('startAlarm', {
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      // ignore
    }
  }

  // ── Arrêter ──
  static Future<void> stopAlarm() async {
    _isRinging = false;
    try {
      await _alarmChannel.invokeMethod('stopAlarm');
    } catch (e) {
      // ignore
    }
    //await FlutterLocalNotificationsPlugin().cancelAll();
  }

  // ── Snooze ──
  static Future<void> snoozeAlarm(
      int originalId, Map<String, dynamic> params) async {
    await stopAlarm();
    // Le snooze est géré via NotificationService
  }

  // ── Params (pour compatibilité) ──
  static Future<Map<String, dynamic>?> getAlarmParams(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('alarm_params_$id');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }
}