package br.com.vitoraguiar.financeapp

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.TimeUnit

internal class DriveSyncWorker(context: Context, parameters: WorkerParameters) :
    CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result = withContext(Dispatchers.Main) {
        if (foreground) return@withContext Result.success()
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val engine = FlutterEngine(applicationContext)
        val completion = CompletableDeferred<String>()
        val bridge = GoogleDriveBridge(applicationContext, engine.dartExecutor.binaryMessenger) {
            completion.complete(it)
        }
        try {
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "driveSyncWorker"),
            )
            if (withTimeoutOrNull(TimeUnit.MINUTES.toMillis(8)) { completion.await() } == "done") {
                Result.success()
            } else {
                Result.retry()
            }
        } finally {
            bridge.close()
            engine.destroy()
        }
    }

    companion object {
        private const val NAME = "finance-drive-sync"
        @Volatile var foreground = false

        fun schedule(context: Context, enabled: Boolean) {
            val manager = WorkManager.getInstance(context)
            if (enabled) {
                val work = PeriodicWorkRequestBuilder<DriveSyncWorker>(15, TimeUnit.MINUTES)
                    .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                    .build()
                manager.enqueueUniquePeriodicWork(NAME, ExistingPeriodicWorkPolicy.KEEP, work)
            } else {
                manager.cancelUniqueWork(NAME)
            }
        }
    }
}
