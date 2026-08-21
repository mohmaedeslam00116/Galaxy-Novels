package com.galaxynovels.app

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.content.pm.PackageManager
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import java.io.ByteArrayOutputStream

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val MAX_JSON_DOCUMENT_BYTES = 1024 * 1024
        private const val JSON_DOCUMENT_REQUEST_CODE = 7014
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 7015
        private const val INLINE_NATIVE_AD_FACTORY_ID = "galaxyInlineNativeAd"
    }

    private var pendingJsonDocumentResult: MethodChannel.Result? = null
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != JSON_DOCUMENT_REQUEST_CODE) return
        val pendingResult = pendingJsonDocumentResult ?: return
        pendingJsonDocumentResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pendingResult.success(null)
            return
        }
        readJsonDocument(uri, pendingResult)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST_CODE) return
        val pendingResult = pendingNotificationPermissionResult ?: return
        pendingNotificationPermissionResult = null
        pendingResult.success(
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        )
    }

    private fun readJsonDocument(uri: Uri, pendingResult: MethodChannel.Result) {
        Thread {
            try {
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    var total = 0
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        total += read
                        if (total > MAX_JSON_DOCUMENT_BYTES) {
                            throw JsonDocumentTooLargeException()
                        }
                        output.write(buffer, 0, read)
                    }
                    output.toByteArray()
                } ?: throw IllegalStateException("Unable to open selected document")
                runOnUiThread { pendingResult.success(bytes) }
            } catch (_: JsonDocumentTooLargeException) {
                runOnUiThread {
                    pendingResult.error(
                        "file_too_large",
                        "The selected JSON document exceeds 1 MB.",
                        null
                    )
                }
            } catch (error: Exception) {
                runOnUiThread {
                    pendingResult.error(
                        "read_failed",
                        error.message ?: "Unable to read selected document.",
                        null
                    )
                }
            }
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            INLINE_NATIVE_AD_FACTORY_ID,
            GalaxyInlineNativeAdFactory(this),
        )
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "galaxy_novels/app_settings"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> result.success(openNotificationSettings())
                "openTextToSpeechSettings" -> result.success(openTextToSpeechSettings())
                "requestNotificationPermission" -> requestNotificationPermission(result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "galaxy_novels/document_picker"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickJsonDocument" -> openJsonDocument(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            INLINE_NATIVE_AD_FACTORY_ID,
        )
        super.cleanUpFlutterEngine(flutterEngine)
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

    private fun openNotificationSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
            )
            true
        } catch (_: ActivityNotFoundException) {
            openApplicationDetails()
        } catch (_: SecurityException) {
            openApplicationDetails()
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingNotificationPermissionResult != null) {
            result.error("permission_busy", "A permission request is already active.", null)
            return
        }
        pendingNotificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    private fun openApplicationDetails(): Boolean {
        return try {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName")
                )
            )
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun openTextToSpeechSettings(): Boolean {
        return try {
            startActivity(Intent("android.settings.TTS_SETTINGS"))
            true
        } catch (_: ActivityNotFoundException) {
            installTextToSpeechData()
        } catch (_: SecurityException) {
            installTextToSpeechData()
        }
    }

    private fun installTextToSpeechData(): Boolean {
        return try {
            startActivity(Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA))
            true
        } catch (_: ActivityNotFoundException) {
            openApplicationDetails()
        } catch (_: SecurityException) {
            openApplicationDetails()
        }
    }

    private fun openJsonDocument(result: MethodChannel.Result) {
        if (pendingJsonDocumentResult != null) {
            result.error("picker_busy", "A document picker is already open.", null)
            return
        }
        pendingJsonDocumentResult = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/json"
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf(
                    "application/json",
                    "text/json",
                    "text/plain",
                    "application/octet-stream"
                    )
                )
            }
            startActivityForResult(intent, JSON_DOCUMENT_REQUEST_CODE)
        } catch (_: ActivityNotFoundException) {
            pendingJsonDocumentResult = null
            result.error("picker_unavailable", "No document picker is available.", null)
        } catch (_: SecurityException) {
            pendingJsonDocumentResult = null
            result.error("picker_unavailable", "The document picker is unavailable.", null)
        }
    }

    private class JsonDocumentTooLargeException : Exception()
}
