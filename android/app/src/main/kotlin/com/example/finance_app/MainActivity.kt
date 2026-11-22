package com.example.finance_app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var appBiometrics: AppBiometrics? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
        } else {
            // Earlier Android versions have no separate control for task previews.
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appBiometrics = AppBiometrics(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onStop() {
        appBiometrics?.cancel()
        super.onStop()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appBiometrics?.close()
        appBiometrics = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
