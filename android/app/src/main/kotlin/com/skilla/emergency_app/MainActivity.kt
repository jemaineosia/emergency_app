package com.skilla.emergency_app

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.skilla.emergencyApp.VoiceListenerService

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.skilla.emergencyApp/voice_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVoiceService" -> {
                    VoiceListenerService.startService(this)
                    result.success(true)
                }
                "stopVoiceService" -> {
                    VoiceListenerService.stopService(this)
                    result.success(true)
                }
                "showOnLockScreen" -> {
                    // Allow app to show on lock screen
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                        setShowWhenLocked(true)
                        setTurnScreenOn(true)
                    } else {
                        @Suppress("DEPRECATION")
                        window.addFlags(
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        )
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
