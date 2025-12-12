package com.example.focus_os_ghost

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ghost.focusos/kiosk"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startKiosk") {
                try {
                    startLockTask()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("KIOSK_ERROR", e.message, null)
                }
            } else if (call.method == "stopKiosk") {
                try {
                    stopLockTask()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("KIOSK_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
