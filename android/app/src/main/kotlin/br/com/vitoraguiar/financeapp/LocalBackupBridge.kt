package br.com.vitoraguiar.financeapp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal class LocalBackupBridge(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: Activity? = null,
    private val complete: ((String) -> Unit)? = null,
) {
    private val channel = MethodChannel(messenger, "finance_app/local_backup")
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var folderResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "chooseFolder" -> chooseFolder(result)
                "timeZone" -> result.success(java.util.TimeZone.getDefault().id)
                "schedule" -> {
                    DriveSyncWorker.schedule(context, call.arguments == true, local = true)
                    result.success(null)
                }
                "write" -> {
                    val folder = call.argument<String>("folder")
                    val name = call.argument<String>("name")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (folder == null || name == null || bytes == null) {
                        result.error("arguments", "Backup inválido.", null)
                    } else {
                        scope.launch {
                            try {
                                withContext(Dispatchers.IO) { write(Uri.parse(folder), name, bytes) }
                                result.success(null)
                            } catch (failure: Exception) {
                                result.error("write_failed", "Não foi possível salvar o backup na pasta.", null)
                            }
                        }
                    }
                }
                "complete" -> {
                    result.success(null)
                    complete?.invoke(if (call.arguments == true) "retry" else "done")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun chooseFolder(result: MethodChannel.Result) {
        if (activity == null || folderResult != null) {
            result.error("folder_unavailable", "Não foi possível abrir o seletor de pastas.", null)
            return
        }
        folderResult = result
        try {
            activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), REQUEST_FOLDER)
        } catch (failure: Exception) {
            folderResult = null
            result.error("folder_unavailable", "Não foi possível abrir o seletor de pastas.", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_FOLDER) return false
        val result = folderResult
        folderResult = null
        val folder = data?.data
        if (resultCode != Activity.RESULT_OK || folder == null) {
            result?.success(null)
            return true
        }
        try {
            context.contentResolver.takePersistableUriPermission(
                folder, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            result?.success(folder.toString())
        } catch (failure: SecurityException) {
            result?.error("folder_permission", "A pasta não permite gravar backups.", null)
        }
        return true
    }

    private fun write(folder: Uri, name: String, bytes: ByteArray) {
        val resolver = context.contentResolver
        val parent = DocumentsContract.buildDocumentUriUsingTree(folder, DocumentsContract.getTreeDocumentId(folder))
        val file = requireNotNull(DocumentsContract.createDocument(resolver, parent, "application/octet-stream", name))
        try {
            requireNotNull(resolver.openOutputStream(file)).use { it.write(bytes) }
        } catch (failure: Exception) {
            runCatching { DocumentsContract.deleteDocument(resolver, file) }
            throw failure
        }
    }

    fun close() {
        folderResult?.success(null)
        folderResult = null
        scope.cancel()
        channel.setMethodCallHandler(null)
    }

    companion object {
        private const val REQUEST_FOLDER = 6071
    }
}
