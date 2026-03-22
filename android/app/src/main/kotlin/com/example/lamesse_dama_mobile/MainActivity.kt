package com.example.lamesse_dama_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

class MainActivity : FlutterActivity() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    companion object {
        // Stocke les payloads reçus en background pour les transmettre à Flutter au réveil
        val pendingPayloads = mutableListOf<String>()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Channel batterie ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.lamesse_dama_mobile/battery"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "openAutoStart" -> {
                    try {
                        val intent = Intent().apply {
                            component = android.content.ComponentName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.autostart.AutoStartManagementActivity"
                            )
                        }
                        startActivity(intent)
                    } catch (_: Exception) {}
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ── Channel alarme ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.lamesse_dama_mobile/alarm"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> { startAlarm(); result.success(null) }
                "stopAlarm"  -> { stopAlarm();  result.success(null) }
                else -> result.notImplemented()
            }
        }

        // ── Channel pour transmettre les payloads background en attente ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.lamesse_dama_mobile/pending_payloads"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingPayloads" -> {
                    result.success(pendingPayloads.toList())
                    pendingPayloads.clear()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        when (intent.action) {
            "STOP_ALARM" -> stopAlarm()
            "START_ALARM" -> startAlarm()
        }
    }

    // Appelé quand l'app revient au premier plan depuis background
    override fun onResume() {
        super.onResume()
        // Notifier Flutter que l'app est revenue au premier plan
        // flutter_local_notifications va re-vérifier les notifications en attente
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, "com.example.lamesse_dama_mobile/lifecycle")
                .invokeMethod("onResume", null)
        }
    }

    private fun startAlarm() {
        stopAlarm()
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(applicationContext, alarmUri)
                isLooping = true
                prepare()
                start()
            }
        } catch (_: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibrator = vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        }
        val pattern = longArrayOf(0, 500, 200, 500, 200, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopAlarm() {
        mediaPlayer?.apply { if (isPlaying) stop(); release() }
        mediaPlayer = null
        vibrator?.cancel()
        vibrator = null
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }
}