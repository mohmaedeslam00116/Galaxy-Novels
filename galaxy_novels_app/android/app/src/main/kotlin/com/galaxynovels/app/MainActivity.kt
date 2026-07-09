package com.galaxynovels.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "galaxy_novels/download_notifications"
        ).setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *>
            when (call.method) {
                "startOrUpdate" -> {
                    ensureNotificationPermission()
                    startDownloadService(DownloadForegroundService.ACTION_START_OR_UPDATE, args)
                    result.success(null)
                }
                "complete" -> {
                    startDownloadService(DownloadForegroundService.ACTION_COMPLETE, args)
                    result.success(null)
                }
                "fail" -> {
                    startDownloadService(DownloadForegroundService.ACTION_FAIL, args)
                    result.success(null)
                }
                "clear" -> {
                    startDownloadService(DownloadForegroundService.ACTION_CLEAR, args)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "galaxy_novels/reader_display"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenBrightness" -> {
                    val args = call.arguments as? Map<*, *>
                    val value = floatArg(args, "value").coerceIn(0.2f, 1.0f)
                    setReaderScreenBrightness(value)
                    result.success(null)
                }
                "clearScreenBrightness" -> {
                    setReaderScreenBrightness(WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            return
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7021)
    }

    private fun startDownloadService(action: String, args: Map<*, *>?) {
        val intent = Intent(this, DownloadForegroundService::class.java).apply {
            this.action = action
            putExtra("novelTitle", stringArg(args, "novelTitle"))
            putExtra("novelCover", stringArg(args, "novelCover"))
            putExtra("message", stringArg(args, "message"))
            putExtra("total", intArg(args, "total"))
            putExtra("completed", intArg(args, "completed"))
            putExtra("failed", intArg(args, "failed"))
            putExtra("isPaused", boolArg(args, "isPaused"))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stringArg(args: Map<*, *>?, key: String): String {
        return args?.get(key)?.toString() ?: ""
    }

    private fun intArg(args: Map<*, *>?, key: String): Int {
        return (args?.get(key) as? Number)?.toInt() ?: 0
    }

    private fun boolArg(args: Map<*, *>?, key: String): Boolean {
        return args?.get(key) as? Boolean ?: false
    }

    private fun floatArg(args: Map<*, *>?, key: String): Float {
        return (args?.get(key) as? Number)?.toFloat() ?: WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
    }

    private fun setReaderScreenBrightness(value: Float) {
        runOnUiThread {
            val params = window.attributes
            params.screenBrightness = value
            window.attributes = params
        }
    }
}
