package com.example.dominoes

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val soundStatus by lazy { SystemSoundStatus(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "dominoes/systemSound")
            .setStreamHandler(soundStatus)
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

    override fun onResume() {
        super.onResume()
        soundStatus.refresh()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        soundStatus.onCancel(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

private class SystemSoundStatus(private val context: Context) : EventChannel.StreamHandler {
    private val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var sink: EventChannel.EventSink? = null
    private val ringerChanges = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = refresh()
    }
    private val volumeChanges = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) = refresh()
    }

    fun refresh() {
        val listener = sink ?: return
        val status = when {
            audio.ringerMode == AudioManager.RINGER_MODE_SILENT -> "silent"
            audio.ringerMode == AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            audio.isStreamMute(AudioManager.STREAM_SYSTEM) ||
                audio.getStreamVolume(AudioManager.STREAM_SYSTEM) == 0 -> "zeroVolume"
            else -> "normal"
        }
        listener.success(status)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        context.registerReceiver(ringerChanges, IntentFilter(AudioManager.RINGER_MODE_CHANGED_ACTION))
        context.contentResolver.registerContentObserver(Settings.System.CONTENT_URI, true, volumeChanges)
        refresh()
    }

    override fun onCancel(arguments: Any?) {
        if (sink == null) return
        sink = null
        context.unregisterReceiver(ringerChanges)
        context.contentResolver.unregisterContentObserver(volumeChanges)
    }
}
