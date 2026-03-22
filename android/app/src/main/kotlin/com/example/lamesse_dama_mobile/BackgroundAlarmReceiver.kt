package com.example.lamesse_dama_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class BackgroundAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.d("BGAlarmReceiver", "✅ onReceive déclenché!")

        // ── WakeLock : empêche Tecno/HiOS d'endormir le CPU ──
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "LamesseDama:AlarmWakeLock"
        )
        wakeLock.acquire(10_000L) // 10 secondes max

        try {
            val title   = intent.getStringExtra("title")    ?: "Rappel"
            val body    = intent.getStringExtra("body")     ?: ""
            val notifId = intent.getIntExtra("notif_id", 0)
            val channelId = "bg_alarm_channel"

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // ── Créer le channel ──
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                val audioAttr = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                val channel = NotificationChannel(
                    channelId,
                    "Alarmes background",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                    setSound(alarmSound, audioAttr)
                    setBypassDnd(true)      // ← passe le mode Ne pas déranger
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(channel)
            }

            // ── Intent pour ouvrir l'app au tap ──
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                action = "NOTIFICATION_TAP_$notifId"
            }
            val pendingIntent = PendingIntent.getActivity(
                context, notifId, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // ── Construire la notification ──
            val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            val notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setSound(alarmSound)
                .setVibrate(longArrayOf(0, 500, 200, 500, 200, 500))
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setFullScreenIntent(pendingIntent, true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .build()

            nm.notify(notifId, notification)
            android.util.Log.d("BGAlarmReceiver", "✅ Notification affichée: $title")

            // ── Sauvegarder dans SharedPreferences pour Flutter ──
            saveToSharedPrefs(context, notifId, title, body, intent.getIntExtra("notif_type", 0))

        } finally {
            // Toujours relâcher le WakeLock
            if (wakeLock.isHeld) wakeLock.release()
        }
    }

    private fun saveToSharedPrefs(
        context: Context,
        notifId: Int,
        title: String,
        body: String,
        notifType: Int
    ) {
        try {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val key = "flutter.pending_notifications"
            val existing = prefs.getString(key, null)
            val list = if (existing != null) {
                org.json.JSONArray(existing)
            } else {
                org.json.JSONArray()
            }
            val obj = org.json.JSONObject().apply {
                put("id", "${notifId}_bg_${System.currentTimeMillis()}")
                put("title", title)
                put("body", body)
                put("type", notifType)
                put("createdAt", if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    java.time.Instant.now().toString()
                } else {
                    java.util.Date().toString()
                })
            }
            list.put(obj)
            prefs.edit().putString(key, list.toString()).apply()
            android.util.Log.d("BGAlarmReceiver", "✅ Sauvegardé dans SharedPrefs")
        } catch (e: Exception) {
            android.util.Log.e("BGAlarmReceiver", "❌ Erreur SharedPrefs: $e")
        }
    }
}