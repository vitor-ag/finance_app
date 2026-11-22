package br.com.vitoraguiar.financeapp

import android.accounts.Account
import android.accounts.AccountManager
import android.app.Activity
import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.AuthorizationResult
import com.google.android.gms.auth.api.identity.ClearTokenRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.AccountPicker
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Scope
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Semaphore

internal class GoogleDriveBridge(
    context: Context,
    messenger: BinaryMessenger,
    private val activity: Activity? = null,
    private val workerComplete: ((String) -> Unit)? = null,
) {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, "finance_app/google_drive")
    private var pending: MethodChannel.Result? = null
    private var ownsLock = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> {
                    val acquired = !ownsLock && lock.tryAcquire()
                    if (acquired) ownsLock = true
                    result.success(acquired)
                }
                "release" -> {
                    release()
                    result.success(null)
                }
                "pickAccount" -> pickAccount(result)
                "authorize" -> {
                    val email = call.argument<String>("email")
                    if (email.isNullOrEmpty()) {
                        result.error("authorization", null, null)
                    } else {
                        authorize(email, call.argument<Boolean>("interactive") == true, result)
                    }
                }
                "clearToken" -> {
                    val token = call.arguments as? String
                    if (token == null) {
                        result.success(null)
                    } else {
                        val request = ClearTokenRequest.builder().setToken(token).build()
                        Identity.getAuthorizationClient(appContext).clearToken(request)
                            .addOnCompleteListener { result.success(null) }
                    }
                }
                "schedule" -> {
                    DriveSyncWorker.schedule(appContext, call.arguments == true)
                    result.success(null)
                }
                "workerComplete" -> {
                    result.success(null)
                    workerComplete?.invoke(call.arguments as? String ?: "retry")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playServicesAvailable(result: MethodChannel.Result): Boolean {
        val status = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(appContext)
        if (status == ConnectionResult.SUCCESS) return true
        result.error("play_services", null, null)
        return false
    }

    @Suppress("DEPRECATION")
    private fun pickAccount(result: MethodChannel.Result) {
        val host = activity ?: return result.error("authorization", null, null)
        if (!playServicesAvailable(result)) return
        if (pending != null) return result.error("busy", null, null)
        val options = AccountPicker.AccountChooserOptions.Builder()
            .setAllowableAccountsTypes(listOf(GOOGLE))
            .setAlwaysShowAccountPicker(true)
            .build()
        pending = result
        try {
            host.startActivityForResult(AccountPicker.newChooseAccountIntent(options), PICK_ACCOUNT)
        } catch (_: Exception) {
            finishError("play_services")
        }
    }

    @Suppress("DEPRECATION")
    private fun authorize(email: String, interactive: Boolean, result: MethodChannel.Result) {
        if (!playServicesAvailable(result)) return
        if (pending != null) return result.error("busy", null, null)
        val request = AuthorizationRequest.builder()
            .setAccount(Account(email, GOOGLE))
            .setRequestedScopes(listOf(Scope(DRIVE_SCOPE)))
            .build()
        pending = result
        Identity.getAuthorizationClient(activity ?: appContext).authorize(request)
            .addOnSuccessListener { authorization ->
                val resolution = authorization.pendingIntent
                if (resolution == null) {
                    finishAuthorization(authorization)
                } else if (interactive && activity != null) {
                    try {
                        activity.startIntentSenderForResult(resolution.intentSender, CONSENT, null, 0, 0, 0)
                    } catch (_: Exception) {
                        finishError("authorization")
                    }
                } else {
                    finishError("authorization")
                }
            }
            .addOnFailureListener { finishError(errorCode(it)) }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_ACCOUNT && requestCode != CONSENT) return false
        if (pending == null) return true
        if (resultCode != Activity.RESULT_OK || data == null) {
            finishError("cancelled")
            return true
        }
        if (requestCode == PICK_ACCOUNT) {
            val email = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
            if (email.isNullOrBlank() || data.getStringExtra(AccountManager.KEY_ACCOUNT_TYPE) != GOOGLE) {
                finishError("authorization")
            } else {
                finish(email)
            }
        } else {
            try {
                finishAuthorization(Identity.getAuthorizationClient(appContext).getAuthorizationResultFromIntent(data))
            } catch (error: ApiException) {
                finishError(errorCode(error))
            }
        }
        return true
    }

    private fun finishAuthorization(authorization: AuthorizationResult) {
        val token = authorization.accessToken
        if (token.isNullOrEmpty() || DRIVE_SCOPE !in authorization.grantedScopes) {
            finishError("authorization")
        } else {
            finish(token)
        }
    }

    private fun finish(value: String) {
        val result = pending
        pending = null
        result?.success(value)
    }

    private fun finishError(code: String) {
        val result = pending
        pending = null
        result?.error(code, null, null)
    }

    private fun errorCode(error: Exception) = when ((error as? ApiException)?.statusCode) {
        CommonStatusCodes.NETWORK_ERROR -> "network"
        CommonStatusCodes.DEVELOPER_ERROR -> "oauth_config"
        CommonStatusCodes.CANCELED -> "cancelled"
        else -> "authorization"
    }

    private fun release() {
        if (ownsLock) {
            ownsLock = false
            lock.release()
        }
    }

    fun close() {
        finishError("cancelled")
        release()
        channel.setMethodCallHandler(null)
    }

    companion object {
        private const val GOOGLE = "com.google"
        private const val DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.appdata"
        private const val PICK_ACCOUNT = 9411
        private const val CONSENT = 9412
        private val lock = Semaphore(1)
    }
}
