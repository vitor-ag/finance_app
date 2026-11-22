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
        val local = inputData.getBoolean("local", false)
        val driveBridge = if (local) null else GoogleDriveBridge(applicationContext, engine.dartExecutor.binaryMessenger) {
            completion.complete(it)
        }
        val localBridge = if (!local) null else LocalBackupBridge(applicationContext, engine.dartExecutor.binaryMessenger) {
            completion.complete(it)
        }
        try {
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), if (local) "localBackupWorker" else "driveSyncWorker"),
            )
            if (withTimeoutOrNull(TimeUnit.MINUTES.toMillis(8)) { completion.await() } == "done") {
                Result.success()
            } else {
                Result.retry()
            }
        } finally {
            driveBridge?.close()
            localBridge?.close()
            engine.destroy()
        }
    }

    companion object {
        private const val NAME = "finance-drive-sync"
        @Volatile var foreground = false

        fun schedule(context: Context, enabled: Boolean, local: Boolean = false) {
            val manager = WorkManager.getInstance(context)
            val name = if (local) "finance-local-backup" else NAME
            if (enabled) {
                val builder = PeriodicWorkRequestBuilder<DriveSyncWorker>(if (local) 6 else 15, if (local) TimeUnit.HOURS else TimeUnit.MINUTES)
                if (local) {
                    builder.setInputData(androidx.work.workDataOf("local" to true))
                } else {
                    builder.setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                }
                manager.enqueueUniquePeriodicWork(name, ExistingPeriodicWorkPolicy.KEEP, builder.build())
            } else {
                manager.cancelUniqueWork(name)
            }
        }
    }
}
