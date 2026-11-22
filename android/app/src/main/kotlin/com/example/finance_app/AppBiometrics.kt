package com.example.finance_app

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

internal class AppBiometrics(
    private val activity: FragmentActivity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "finance_app/security")
    private val keyAlias = "finance_app.biometric_access.v1"
    private val strong = BiometricManager.Authenticators.BIOMETRIC_STRONG
    private var cancelPrompt: (() -> Unit)? = null

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "enroll" -> authenticate(enroll = true, result)
                    "authenticate" -> authenticate(enroll = false, result)
                    "removeKey" -> {
                        keyStore().deleteEntry(keyAlias)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                result.error("security_error", "Falha no serviço de segurança do Android.", null)
            }
        }
    }

    fun cancel() {
        cancelPrompt?.invoke()
    }

    fun close() {
        cancel()
        channel.setMethodCallHandler(null)
    }

    private fun authenticate(enroll: Boolean, result: MethodChannel.Result) {
        if (cancelPrompt != null || activity.supportFragmentManager.isStateSaved) {
            result.success("canceled")
            return
        }

        val keys = keyStore()
        val status = BiometricManager.from(activity).canAuthenticate(strong)
        if (!enroll && (!keys.containsAlias(keyAlias) ||
                status == BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED)) {
            result.success("invalidated")
            return
        }
        if (status != BiometricManager.BIOMETRIC_SUCCESS) {
            result.success("unavailable")
            return
        }

        val key = if (enroll) {
            keys.deleteEntry(keyAlias)
            generateKey()
        } else {
            keys.getKey(keyAlias, null) as? SecretKey
        }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        try {
            if (key == null) {
                result.success("invalidated")
                return
            }
            cipher.init(Cipher.ENCRYPT_MODE, key)
        } catch (_: KeyPermanentlyInvalidatedException) {
            keys.deleteEntry(keyAlias)
            result.success("invalidated")
            return
        }

        var completed = false
        fun finish(outcome: String) {
            if (completed) return
            completed = true
            cancelPrompt = null
            if (enroll && outcome != "success") runCatching { keys.deleteEntry(keyAlias) }
            result.success(outcome)
        }

        val prompt = BiometricPrompt(
            activity,
            ContextCompat.getMainExecutor(activity),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(auth: BiometricPrompt.AuthenticationResult) {
                    if (completed) return
                    val authorizedCipher = auth.cryptoObject?.cipher
                    if (authorizedCipher == null) {
                        finish("unavailable")
                        return
                    }
                    try {
                        // A Keystore operation confirms that this prompt authorized this key.
                        authorizedCipher.doFinal(byteArrayOf(1))
                        finish("success")
                    } catch (_: KeyPermanentlyInvalidatedException) {
                        finish("invalidated")
                    } catch (_: Exception) {
                        finish("unavailable")
                    }
                }

                override fun onAuthenticationError(code: Int, description: CharSequence) {
                    finish(when (code) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        BiometricPrompt.ERROR_CANCELED -> "canceled"
                        BiometricPrompt.ERROR_NO_BIOMETRICS -> if (enroll) "unavailable" else "invalidated"
                        else -> "unavailable"
                    })
                }
            },
        )
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(if (enroll) "Ativar biometria" else "Desbloquear Finance App")
            .setNegativeButtonText("Cancelar")
            .setAllowedAuthenticators(strong)
            .build()
        cancelPrompt = {
            finish("canceled")
            prompt.cancelAuthentication()
        }
        try {
            prompt.authenticate(info, BiometricPrompt.CryptoObject(cipher))
        } catch (_: Exception) {
            finish("unavailable")
        }
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    @Suppress("DEPRECATION")
    private fun generateKey(): SecretKey {
        val spec = KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            spec.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
        } else {
            spec.setUserAuthenticationValidityDurationSeconds(-1)
        }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(spec.build())
        }.generateKey()
    }
}
