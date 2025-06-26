package com.ilhanidriss.wan_protector

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ilhanidriss.wan_protector/screen"
    private var methodChannel: MethodChannel? = null
    private var screenReceiver: ScreenBroadcastReceiver? = null

    // Inner class to handle screen on/off events
    inner class ScreenBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                // When the screen is turned off
                Intent.ACTION_SCREEN_OFF -> {
                    Log.d("MainActivity", "Screen OFF detected")
                    methodChannel?.invokeMethod("screenOff", null)
                }
                // When the screen is turned on
                Intent.ACTION_SCREEN_ON -> {
                    Log.d("MainActivity", "Screen ON detected")
                    methodChannel?.invokeMethod("screenOn", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the MethodChannel for communication with Flutter
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                // This handler is for methods invoked from Flutter to Android.
                // Currently, no methods are expected from Flutter to Android regarding screen state.
                // The 'initialize' method was likely a placeholder or for other purposes.
                when (call.method) {
                    "initialize" -> {
                        // You can keep this if 'initialize' is used for other purposes,
                        // otherwise, it can be removed.
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
            android.view.WindowManager.LayoutParams.FLAG_SECURE
        )

        //Register the BroadcastReceiver to listen for screen on/off events
        screenReceiver = ScreenBroadcastReceiver()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(screenReceiver, filter)
        Log.d("MainActivity", "ScreenBroadcastReceiver registered")
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // This method detects when the app gains or loses focus.
        // It's useful for detecting when the app goes to background (loses focus)
        // but it doesn't directly indicate screen on/off state.
        // The Flutter lifecycle watcher already handles AppLifecycleState.paused/hidden
        // which covers this scenario for backgrounding the app.
        // The screen on/off is handled by the BroadcastReceiver.
    }

    override fun onDestroy() {
        // Unregister the BroadcastReceiver when the activity is destroyed to prevent memory leaks
        screenReceiver?.let {
            unregisterReceiver(it)
            Log.d("MainActivity", "ScreenBroadcastReceiver unregistered")
        }
        // Remove the MethodCallHandler to clean up resources
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
