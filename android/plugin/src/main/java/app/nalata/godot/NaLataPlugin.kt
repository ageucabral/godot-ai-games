package app.nalata.godot

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import java.util.concurrent.Executors
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Plugin do Na Lata para o Godot (singleton "NaLata").
 * - Login com Google (Credential Manager): devolve o idToken para o servidor conferir (POST /auth/google).
 * - Propaganda premiada do AdMob com SSV: `customData` = rewardId do servidor, `userId` = id do jogador.
 * - Play Integrity (o servidor confere se é o app original da Play num aparelho íntegro).
 * - Convite: lê o código que veio no link da Play (install referrer) e abre o "compartilhar" do Android.
 * Tudo responde por sinais, na linha principal do Godot.
 */
class NaLataPlugin(godot: Godot) : GodotPlugin(godot) {
    private val tag = "NaLata"
    private val io = Executors.newSingleThreadExecutor()
    private var adsReady = false

    override fun getPluginName() = "NaLata"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        // ok, código do erro ("" se deu certo)
        SignalInfo("ads_initialized", java.lang.Boolean::class.java),
        // ganhou a recompensa (assistiu até o fim), código do erro ("" se deu certo)
        SignalInfo("rewarded_finished", java.lang.Boolean::class.java, String::class.java),
        // idToken ("" se não entrou), erro ("" | "cancelled" | "no_account" | mensagem)
        SignalInfo("google_signed_in", String::class.java, String::class.java),
        // token ("" se não deu), erro ("" se deu certo)
        SignalInfo("integrity_token", String::class.java, String::class.java),
        // texto do referrer da Play (ex.: "code=ABC123"; "" se não houver)
        SignalInfo("install_referrer", String::class.java),
    )

    private fun act(): Activity? = activity

    // ---------- AdMob ----------

    /** Liga o SDK do AdMob (uma vez). */
    @UsedByGodot
    fun adsInit() {
        val a = act() ?: return emitSignal("ads_initialized", false)
        if (adsReady) return emitSignal("ads_initialized", true)
        io.execute {
            MobileAds.initialize(a) {
                adsReady = true
                emitSignal("ads_initialized", true)
            }
        }
    }

    /**
     * Carrega e mostra uma propaganda premiada. `customData` e `userId` vão na confirmação (SSV) que o
     * Google manda ao servidor (/v1/admob/ssv). Responde com `rewarded_finished(ganhou, erro)`.
     */
    @UsedByGodot
    fun showRewarded(unitId: String, userId: String, customData: String) {
        val a = act() ?: return emitSignal("rewarded_finished", false, "no_activity")
        a.runOnUiThread {
            RewardedAd.load(a, unitId, AdRequest.Builder().build(), object : RewardedAdLoadCallback() {
                override fun onAdLoaded(ad: RewardedAd) {
                    ad.setServerSideVerificationOptions(
                        ServerSideVerificationOptions.Builder().setUserId(userId).setCustomData(customData).build()
                    )
                    var earned = false
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdDismissedFullScreenContent() {
                            emitSignal("rewarded_finished", earned, if (earned) "" else "closed")
                        }

                        override fun onAdFailedToShowFullScreenContent(e: AdError) {
                            emitSignal("rewarded_finished", false, "show_${e.code}")
                        }
                    }
                    ad.show(a) { earned = true }
                }

                override fun onAdFailedToLoad(e: LoadAdError) {
                    Log.w(tag, "rewarded load: ${e.code} ${e.message}")
                    emitSignal("rewarded_finished", false, if (e.code == AdRequest.ERROR_CODE_NO_FILL) "no_fill" else "load_${e.code}")
                }
            })
        }
    }

    // ---------- Login com Google ----------

    /**
     * Abre a escolha de conta Google. `webClientId` = cliente "Web" do projeto Google Cloud (o mesmo que o
     * servidor confere em GOOGLE_CLIENT_IDS). Primeiro tenta a folha de contas; se não houver, o botão
     * "Fazer login com o Google". Responde com `google_signed_in(idToken, erro)`.
     */
    @UsedByGodot
    fun googleSignIn(webClientId: String) {
        val a = act() ?: return emitSignal("google_signed_in", "", "no_activity")
        val sheet = GetCredentialRequest.Builder()
            .addCredentialOption(
                GetGoogleIdOption.Builder()
                    .setServerClientId(webClientId)
                    .setFilterByAuthorizedAccounts(false)
                    .setAutoSelectEnabled(false)
                    .build()
            ).build()
        requestCredential(a, sheet) { token, err ->
            if (err == "no_account") {
                val button = GetCredentialRequest.Builder()
                    .addCredentialOption(GetSignInWithGoogleOption.Builder(webClientId).build())
                    .build()
                requestCredential(a, button) { t2, e2 -> emitSignal("google_signed_in", t2, e2) }
            } else {
                emitSignal("google_signed_in", token, err)
            }
        }
    }

    /** Esquece a conta escolhida (na próxima vez a folha de contas aparece de novo). */
    @UsedByGodot
    fun googleSignOut() {
        val a = act() ?: return
        io.execute {
            try {
                kotlinx.coroutines.runBlocking {
                    CredentialManager.create(a).clearCredentialState(ClearCredentialStateRequest())
                }
            } catch (e: Exception) {
                Log.w(tag, "clearCredentialState: ${e.message}")
            }
        }
    }

    private fun requestCredential(a: Activity, req: GetCredentialRequest, done: (String, String) -> Unit) {
        io.execute {
            try {
                val res = kotlinx.coroutines.runBlocking { CredentialManager.create(a).getCredential(a, req) }
                val cred = res.credential
                if (cred is CustomCredential && cred.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                    done(GoogleIdTokenCredential.createFrom(cred.data).idToken, "")
                } else {
                    done("", "unexpected_credential")
                }
            } catch (e: GetCredentialCancellationException) {
                done("", "cancelled")
            } catch (e: NoCredentialException) {
                done("", "no_account")
            } catch (e: GetCredentialException) {
                Log.w(tag, "getCredential: ${e.type} ${e.message}")
                done("", e.type)
            } catch (e: Exception) {
                Log.w(tag, "getCredential: ${e.message}")
                done("", e.message ?: "error")
            }
        }
    }

    // ---------- Play Integrity ----------

    /**
     * Pede um token do Play Integrity (API clássica) com o `nonce` do servidor. `cloudProjectNumber` = número do
     * projeto Google Cloud ligado ao app na Play Console. Responde com `integrity_token(token, erro)`.
     */
    @UsedByGodot
    fun integrityToken(nonce: String, cloudProjectNumber: Long) {
        val a = act() ?: return emitSignal("integrity_token", "", "no_activity")
        try {
            IntegrityManagerFactory.create(a.applicationContext)
                .requestIntegrityToken(
                    IntegrityTokenRequest.builder().setNonce(nonce).setCloudProjectNumber(cloudProjectNumber).build()
                )
                .addOnSuccessListener { emitSignal("integrity_token", it.token(), "") }
                .addOnFailureListener {
                    Log.w(tag, "integrity: ${it.message}")
                    emitSignal("integrity_token", "", it.message ?: "error")
                }
        } catch (e: Exception) {
            emitSignal("integrity_token", "", e.message ?: "error")
        }
    }

    // ---------- Convite ----------

    /** Lê o referrer da instalação (o link do convite manda "code=<código>"). Responde com `install_referrer(texto)`. */
    @UsedByGodot
    fun installReferrer() {
        val a = act() ?: return emitSignal("install_referrer", "")
        val client = InstallReferrerClient.newBuilder(a.applicationContext).build()
        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(code: Int) {
                    var text = ""
                    if (code == InstallReferrerClient.InstallReferrerResponse.OK) {
                        text = try { client.installReferrer.installReferrer ?: "" } catch (e: Exception) { "" }
                    }
                    try { client.endConnection() } catch (_: Exception) {}
                    emitSignal("install_referrer", text)
                }

                override fun onInstallReferrerServiceDisconnected() {}
            })
        } catch (e: Exception) {
            emitSignal("install_referrer", "")
        }
    }

    /** Abre o "compartilhar" do Android com o texto do convite. */
    @UsedByGodot
    fun share(text: String) {
        val a = act() ?: return
        a.runOnUiThread {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
            }
            a.startActivity(Intent.createChooser(send, null))
        }
    }

    /** País do chip (ex.: "BR"; "" sem chip). Ajuda a sugerir o país e o antifraude do resgate. */
    @UsedByGodot
    fun simCountry(): String {
        val a = act() ?: return ""
        return try {
            val tm = a.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            (tm.simCountryIso ?: "").uppercase()
        } catch (e: Exception) {
            ""
        }
    }
}
