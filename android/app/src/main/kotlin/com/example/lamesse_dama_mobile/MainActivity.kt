package com.example.lamesse_dama_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

class MainActivity : FlutterActivity() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    companion object {
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
                     val intentsToTry = listOf(
                        // Tecno / Infinix / itel (même groupe Transsion)
                        Intent().apply {
                            component = android.content.ComponentName(
                                "com.transsion.powersave",
                                "com.transsion.powersave.activity.PowerSaveWhiteListActivity"
                            )
                        },
                        Intent().apply {
                            component = android.content.ComponentName(
                                "com.infinix.security",
                                "com.infinix.security.MainActivity"
                            )
                        },
                        // Fallback générique
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                    )
                    var opened = false
                    for (intent in intentsToTry) {
                        try {
                            startActivity(intent)
                            opened = true
                            break
                        } catch (_: Exception) {}
                    }
                    if (!opened) {
                        startActivity(Intent(Settings.ACTION_SETTINGS))
                    }
                    result.success(null)

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

        // ── Channel alarme (son natif + scheduling background) ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.lamesse_dama_mobile/alarm"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> {
                    startAlarm()
                    result.success(null)
                }
                "stopAlarm" -> {
                    stopAlarm()
                    result.success(null)
                }
                "scheduleBackgroundAlarm" -> {
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val notifId = call.argument<Int>("notifId") ?: 0
                    val notifType = call.argument<Int>("notifType") ?: 0
                    scheduleBackgroundAlarm(title, body, triggerAtMillis, notifId, notifType)
                    result.success(null)
                }
                "cancelBackgroundAlarm" -> {
                    val notifId = call.argument<Int>("notifId") ?: 0
                    cancelBackgroundAlarm(notifId)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ── Channel payloads en attente ──
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

    // ── Retour au premier plan ──
    override fun onResume() {
        super.onResume()
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, "com.example.lamesse_dama_mobile/lifecycle")
                .invokeMethod("onResume", null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        when (intent.action) {
            "STOP_ALARM"  -> stopAlarm()
            "START_ALARM" -> startAlarm()
        }
    }

    // ════════════════════════════════════════════════════════
    // ─── Alarme native background via AlarmManager ───
    // ════════════════════════════════════════════════════════
    private fun scheduleBackgroundAlarm(
        title: String,
        body: String,
        triggerAtMillis: Long,
        notifId: Int,
        notifType: Int
    ) {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager

        val intent = Intent(this, BackgroundAlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("notif_id", notifId)
            putExtra("notif_type", notifType)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            notifId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // setAlarmClock = même comportement que AndroidScheduleMode.alarmClock
        // Réveille l'appareil même en Doze mode, affiche l'icône horloge
        val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent)
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
    }

    private fun cancelBackgroundAlarm(notifId: Int) {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, BackgroundAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            notifId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    // ════════════════════════════════════════════════════════
    // ─── Son d'alarme natif (depuis Flutter) ───
    // ════════════════════════════════════════════════════════
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