package com.example.lamesse_dama_mobile

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ALARM_CHANNEL = "com.example.lamesse_dama_mobile/alarm"
    private val BATTERY_CHANNEL = "com.example.lamesse_dama_mobile/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Channel alarme ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ALARM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> {
                    val title = call.argument<String>("title") ?: "Alarme"
                    val body = call.argument<String>("body") ?: ""
                    val type = call.argument<String>("type") ?: "simple"
                    val intent = Intent(this, AlarmReceiver::class.java).apply {
                        action = "START_ALARM"
                        putExtra("title", title)
                        putExtra("body", body)
                        putExtra("type", type)
                    }
                    sendBroadcast(intent)
                    result.success(true)
                }
                "stopAlarm" -> {
                    AlarmReceiver.stopAlarm()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // ── Channel batterie ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BATTERY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimization" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    val packageName = packageName
                    if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        ).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                else -> result.notImplemented()
            }
        }
    }
}