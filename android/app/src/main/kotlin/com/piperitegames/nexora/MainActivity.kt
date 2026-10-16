package com.piperitegames.nexora

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Канал с тем же именем создаётся на стороне Dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryStatus" -> {
                        try {
                            result.success(readBatteryStatus())
                        } catch (e: Exception) {
                            result.error("BATTERY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Заряд, зарядка и режим энергосбережения одним словарём
    private fun readBatteryStatus(): Map<String, Any> {
        // Для «липкого» события ACTION_BATTERY_CHANGED получатель не нужен:
        // система сразу отдаёт последнее известное состояние
        val intent: Intent? =
            registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

        val rawLevel = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val percent = if (rawLevel >= 0 && scale > 0) rawLevel * 100 / scale else -1

        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        return mapOf(
            "level" to percent,            // -1, если неизвестно
            "charging" to charging,
            "powerSave" to powerManager.isPowerSaveMode,
        )
    }

    companion object {
        private const val CHANNEL = "com.piperitegames.nexora/device"
    }
}