package com.example.dominoes

import android.os.Build
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dominoes/haptics")
            .setMethodCallHandler { call, result ->
                if (call.method == "isSupported") {
                    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        getSystemService(VibratorManager::class.java)?.defaultVibrator
                    } else {
                        @Suppress("DEPRECATION")
                        getSystemService(Vibrator::class.java)
                    }
                    result.success(vibrator?.hasVibrator() == true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
