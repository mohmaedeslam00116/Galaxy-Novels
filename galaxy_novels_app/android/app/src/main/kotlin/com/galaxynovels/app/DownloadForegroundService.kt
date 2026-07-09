package com.galaxynovels.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.IBinder

class DownloadForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()
        when (intent?.action) {
            ACTION_START_OR_UPDATE -> {
                startForeground(NOTIFICATION_ID, buildProgressNotification(intent))
            }
            ACTION_COMPLETE -> {
                notificationManager().notify(NOTIFICATION_ID, buildCompleteNotification(intent))
                stopForegroundCompat(removeNotification = false)
                stopSelf()
            }
            ACTION_FAIL -> {
                notificationManager().notify(NOTIFICATION_ID, buildFailedNotification(intent))
                stopForegroundCompat(removeNotification = false)
                stopSelf()
            }
            ACTION_CLEAR -> {
                notificationManager().cancel(NOTIFICATION_ID)
                stopForegroundCompat(removeNotification = true)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun buildProgressNotification(intent: Intent): Notification {
        val novelTitle = novelTitle(intent)
        val total = intent.getIntExtra("total", 0).coerceAtLeast(0)
        val completed = intent.getIntExtra("completed", 0).coerceAtLeast(0)
        val failed = intent.getIntExtra("failed", 0).coerceAtLeast(0)
        val done = (completed + failed).coerceAtMost(total)
        val isPaused = intent.getBooleanExtra("isPaused", false)
        val status = if (isPaused) "التنزيل متوقف مؤقتا" else "جاري تحميل الفصول"
        val line = if (total > 0) {
            "$status • $done من $total فصل"
        } else {
            status
        }

        val builder = baseBuilder()
            .setContentTitle(novelTitle)
            .setContentText(line)
            .setStyle(Notification.BigTextStyle().bigText(line))
            .setOngoing(!isPaused)
            .setOnlyAlertOnce(true)
            .setPriority(Notification.PRIORITY_LOW)

        if (total > 0) {
            builder.setProgress(total, done, false)
        } else {
            builder.setProgress(0, 0, true)
        }

        return builder.build()
    }

    private fun buildCompleteNotification(intent: Intent): Notification {
        val total = intent.getIntExtra("total", 0).coerceAtLeast(0)
        val completed = intent.getIntExtra("completed", 0).coerceAtLeast(0)
        val failed = intent.getIntExtra("failed", 0).coerceAtLeast(0)
        val line = if (failed > 0) {
            "تم تحميل $completed فصل، وتعذر $failed."
        } else {
            "تم تحميل $completed من $total فصل بنجاح."
        }
        return baseBuilder()
            .setContentTitle("اكتمل تنزيل ${novelTitle(intent)}")
            .setContentText(line)
            .setStyle(Notification.BigTextStyle().bigText(line))
            .setOngoing(false)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_DEFAULT)
            .build()
    }

    private fun buildFailedNotification(intent: Intent): Notification {
        val message = intent.getStringExtra("message")?.takeIf { it.isNotBlank() }
            ?: "تعذر إكمال التنزيل. تحقق من الاتصال ثم أعد المحاولة."
        return baseBuilder()
            .setContentTitle("تعذر تنزيل ${novelTitle(intent)}")
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setOngoing(false)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_DEFAULT)
            .build()
    }

    private fun baseBuilder(): Notification.Builder {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_download_notification)
            .setColor(Color.rgb(93, 201, 249))
            .setSubText("مجرة الروايات")
            .setShowWhen(false)
            .setContentIntent(openAppIntent())
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            "تنزيلات مجرة الروايات",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "متابعة تقدم تحميل فصول الروايات"
            setShowBadge(false)
        }
        notificationManager().createNotificationChannel(channel)
    }

    private fun openAppIntent(): PendingIntent {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun stopForegroundCompat(removeNotification: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(
                if (removeNotification) {
                    STOP_FOREGROUND_REMOVE
                } else {
                    STOP_FOREGROUND_DETACH
                }
            )
        } else {
            @Suppress("DEPRECATION")
            stopForeground(removeNotification)
        }
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun novelTitle(intent: Intent): String {
        return intent.getStringExtra("novelTitle")?.takeIf { it.isNotBlank() }
            ?: "تحميل الفصول"
    }

    companion object {
        const val ACTION_START_OR_UPDATE = "com.galaxynovels.download.START_OR_UPDATE"
        const val ACTION_COMPLETE = "com.galaxynovels.download.COMPLETE"
        const val ACTION_FAIL = "com.galaxynovels.download.FAIL"
        const val ACTION_CLEAR = "com.galaxynovels.download.CLEAR"
        private const val CHANNEL_ID = "galaxy_novels_downloads"
        private const val NOTIFICATION_ID = 7042
    }
}
