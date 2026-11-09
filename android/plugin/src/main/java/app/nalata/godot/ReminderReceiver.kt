package app.nalata.godot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/** Mostra o lembrete do dia agendado pelo jogo (título e texto guardados em [PREFS]). Tocar abre o app. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val title = prefs.getString("title", "") ?: ""
        if (title.isEmpty()) return
        val manager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "Lembretes", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val open = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName) ?: return
        val tap = PendingIntent.getActivity(ctx, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val builder = if (Build.VERSION.SDK_INT >= 26) android.app.Notification.Builder(ctx, CHANNEL)
        else @Suppress("DEPRECATION") android.app.Notification.Builder(ctx)
        val n = builder
            .setSmallIcon(ctx.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(prefs.getString("text", "") ?: "")
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(1, n)
        } catch (_: SecurityException) {
            // sem a permissão de avisos: não mostra nada
        }
    }

    companion object {
        const val PREFS = "nalata_reminder"
        const val CHANNEL = "lembretes"

        fun pending(ctx: Context): PendingIntent =
            PendingIntent.getBroadcast(ctx, 0, Intent(ctx, ReminderReceiver::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }
}
