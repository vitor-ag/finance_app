package br.com.vitoraguiar.financeapp

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var appBiometrics: AppBiometrics? = null
    private var googleDrive: GoogleDriveBridge? = null

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
        googleDrive = GoogleDriveBridge(this, flutterEngine.dartExecutor.binaryMessenger, this)
    }

    @Deprecated("Called by Google Play services account and authorization UI")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (googleDrive?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onStop() {
        DriveSyncWorker.foreground = false
        appBiometrics?.cancel()
        super.onStop()
    }

    override fun onStart() {
        super.onStart()
        DriveSyncWorker.foreground = true
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appBiometrics?.close()
        appBiometrics = null
        googleDrive?.close()
        googleDrive = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
