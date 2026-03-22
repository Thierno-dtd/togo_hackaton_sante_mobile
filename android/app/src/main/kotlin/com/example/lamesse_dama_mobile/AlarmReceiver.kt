package com.example.lamesse_dama_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "STOP_ALARM" -> {
                // Stopper le son via le MainActiviy n'est pas possible ici
                // On envoie juste un intent à l'app si elle est ouverte
                val stopIntent = Intent(context, MainActivity::class.java).apply {
                    action = "STOP_ALARM"
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(stopIntent)
            }
            "START_ALARM" -> {
                val startIntent = Intent(context, MainActivity::class.java).apply {
                    action = "START_ALARM"
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(startIntent)
            }
        }
    }
}