package app.nalata.godot

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.FileProvider
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
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import java.io.File
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
 * - Avisos no celular: um lembrete por dia, no máximo (AlarmManager + [ReminderReceiver]).
 * - Duelo: o link nalata://duelo/CÓDIGO abre o app ([LinkActivity] guarda o link para o jogo ler).
 * Tudo responde por sinais, na linha principal do Godot.
 */
class NaLataPlugin(godot: Godot) : GodotPlugin(godot) {
    private val tag = "NaLata"
    private val io = Executors.newSingleThreadExecutor()
    private var adsReady = false
    // propaganda premiada e anúncio entre níveis já carregados (para abrir na hora): um "slot" para cada bloco
    private val rewarded = AdSlot<RewardedAd>("rewarded") { a, unit, ok, fail ->
        RewardedAd.load(a, unit, AdRequest.Builder().build(), object : RewardedAdLoadCallback() {
            override fun onAdLoaded(ad: RewardedAd) = ok(ad)
            override fun onAdFailedToLoad(e: LoadAdError) = fail(e)
        })
    }
    private val interstitial = AdSlot<InterstitialAd>("interstitial") { a, unit, ok, fail ->
        InterstitialAd.load(a, unit, AdRequest.Builder().build(), object : InterstitialAdLoadCallback() {
            override fun onAdLoaded(ad: InterstitialAd) = ok(ad)
            override fun onAdFailedToLoad(e: LoadAdError) = fail(e)
        })
    }

    override fun getPluginName() = "NaLata"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        // ok, código do erro ("" se deu certo)
        SignalInfo("ads_initialized", java.lang.Boolean::class.java),
        // a próxima propaganda premiada ficou pronta (ou não), para abrir sem espera
        SignalInfo("rewarded_ready", java.lang.Boolean::class.java),
        // ganhou a recompensa (assistiu até o fim), código do erro ("" se deu certo)
        SignalInfo("rewarded_finished", java.lang.Boolean::class.java, String::class.java),
        // o anúncio entre níveis fechou (true se chegou a aparecer)
        SignalInfo("interstitial_finished", java.lang.Boolean::class.java),
        // idToken ("" se não entrou), erro ("" | "cancelled" | "no_account" | mensagem)
        SignalInfo("google_signed_in", String::class.java, String::class.java),
        // token ("" se não deu), erro ("" se deu certo)
        SignalInfo("integrity_token", String::class.java, String::class.java),
        // texto do referrer da Play (ex.: "code=ABC123"; "" se não houver)
        SignalInfo("install_referrer", String::class.java),
        // pode mostrar avisos no celular (depois de pedir a permissão no Android 13+)
        SignalInfo("notifications_allowed", java.lang.Boolean::class.java),
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

    /** Já deixa uma propaganda premiada carregada, para o toque em "assistir" abrir sem espera. */
    @UsedByGodot
    fun preloadRewarded(unitId: String) {
        val a = act() ?: return
        a.runOnUiThread { rewarded.load(a, unitId) { emitSignal("rewarded_ready", it != null) } }
    }

    /**
     * Mostra uma propaganda premiada (a já carregada, se houver; senão carrega agora). `customData` e `userId` vão na
     * confirmação (SSV) que o Google manda ao servidor (/v1/admob/ssv). Responde com `rewarded_finished(ganhou, erro)`.
     * Depois de mostrar, já carrega a próxima.
     */
    @UsedByGodot
    fun showRewarded(unitId: String, userId: String, customData: String) {
        val a = act() ?: return emitSignal("rewarded_finished", false, "no_activity")
        a.runOnUiThread {
            val show = fun(ad: RewardedAd?) {
                if (ad == null) return emitSignal("rewarded_finished", false, rewarded.lastLoadError.ifEmpty { "load" })
                rewarded.forget()
                ad.setServerSideVerificationOptions(
                    ServerSideVerificationOptions.Builder().setUserId(userId).setCustomData(customData).build()
                )
                var earned = false
                ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                    override fun onAdDismissedFullScreenContent() {
                        emitSignal("rewarded_finished", earned, if (earned) "" else "closed")
                        rewarded.load(a, unitId) {}
                    }

                    override fun onAdFailedToShowFullScreenContent(e: AdError) {
                        emitSignal("rewarded_finished", false, "show_${e.code}")
                        rewarded.load(a, unitId) {}
                    }
                }
                ad.show(a) { earned = true }
            }
            rewarded.load(a, unitId) { show(it) }
        }
    }

    /** Já deixa um anúncio entre níveis carregado. */
    @UsedByGodot
    fun preloadInterstitial(unitId: String) {
        val a = act() ?: return
        a.runOnUiThread { interstitial.load(a, unitId) {} }
    }

    /**
     * Mostra o anúncio entre níveis (o já carregado; se não houver nenhum pronto, responde na hora sem mostrar, para
     * não segurar o jogador esperando). Responde com `interstitial_finished(apareceu)` e já carrega o próximo.
     */
    @UsedByGodot
    fun showInterstitial(unitId: String) {
        val a = act() ?: return emitSignal("interstitial_finished", false)
        a.runOnUiThread {
            val reload = { interstitial.load(a, unitId) {} }
            val ad = interstitial.take(unitId)
            if (ad == null) {
                emitSignal("interstitial_finished", false)
                reload()
                return@runOnUiThread
            }
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdDismissedFullScreenContent() {
                    emitSignal("interstitial_finished", true)
                    reload()
                }

                override fun onAdFailedToShowFullScreenContent(e: AdError) {
                    emitSignal("interstitial_finished", false)
                    reload()
                }
            }
            ad.show(a)
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

    /** Abre o "compartilhar" com a figura do convite (arquivo do app) e o texto. Sem a figura, só o texto. */
    @UsedByGodot
    fun shareImage(path: String, text: String) {
        val a = act() ?: return
        a.runOnUiThread {
            val send = Intent(Intent.ACTION_SEND).apply { putExtra(Intent.EXTRA_TEXT, text) }
            try {
                val uri = FileProvider.getUriForFile(a, a.packageName + ".fileprovider", File(path))
                send.type = "image/png"
                send.putExtra(Intent.EXTRA_STREAM, uri)
                send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (e: Exception) {
                send.type = "text/plain"
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

    // ---------- Avisos no celular ----------

    /** Pode mostrar avisos? (Android 13+ pede permissão; antes, sempre pode.) */
    @UsedByGodot
    fun notificationsAllowed(): Boolean {
        val a = act() ?: return false
        return Build.VERSION.SDK_INT < 33 ||
            a.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    /** Pede a permissão de avisos (Android 13+). Responde com `notifications_allowed(bool)`. */
    @UsedByGodot
    fun requestNotifications() {
        val a = act() ?: return emitSignal("notifications_allowed", false)
        if (notificationsAllowed()) return emitSignal("notifications_allowed", true)
        a.runOnUiThread { a.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFY_REQUEST) }
    }

    override fun onMainRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?) {
        if (requestCode == NOTIFY_REQUEST) emitSignal("notifications_allowed", notificationsAllowed())
    }

    /**
     * Agenda o lembrete (substitui o anterior: no máximo um por vez, então no máximo um por dia).
     * `atMs` = hora em milissegundos Unix.
     */
    @UsedByGodot
    fun scheduleReminder(atMs: Long, title: String, text: String) {
        val a = act() ?: return
        val ctx = a.applicationContext
        ctx.getSharedPreferences(ReminderReceiver.PREFS, Context.MODE_PRIVATE).edit()
            .putString("title", title).putString("text", text).apply()
        val alarms = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // sem horário exato (não precisa de permissão especial); o Android pode atrasar uns minutos
        alarms.set(AlarmManager.RTC_WAKEUP, atMs, ReminderReceiver.pending(ctx))
    }

    /** Desliga o lembrete agendado. */
    @UsedByGodot
    fun cancelReminder() {
        val ctx = act()?.applicationContext ?: return
        (ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(ReminderReceiver.pending(ctx))
    }

    // ---------- Duelo por link ----------

    /** Link que abriu o app (ex.: "nalata://duelo/ABC123"), uma vez só; "" se não houver. */
    @UsedByGodot
    fun takeLink(): String {
        val prefs = act()?.applicationContext?.getSharedPreferences(LinkActivity.PREFS, Context.MODE_PRIVATE) ?: return ""
        val link = prefs.getString("link", "") ?: ""
        if (link.isNotEmpty()) prefs.edit().remove("link").apply()
        return link
    }

    private companion object {
        const val NOTIFY_REQUEST = 4210
    }
}

/**
 * Um bloco do AdMob com o anúncio já carregado (vale 1 h no AdMob; usamos 50 min) e a fila de quem espera o
 * carregamento. `request` chama o `load` do SDK do tipo certo. Tudo na thread da tela.
 */
private class AdSlot<T : Any>(
    private val name: String,
    private val request: (Activity, String, (T) -> Unit, (LoadAdError) -> Unit) -> Unit,
) {
    private var cached: T? = null
    private var cachedUnit = ""
    private var cachedAt = 0L
    private var loadingUnit = ""
    private val waiting = mutableListOf<(T?) -> Unit>()
    var lastLoadError = ""

    private fun fresh(unitId: String): T? =
        cached?.takeIf { cachedUnit == unitId && System.currentTimeMillis() - cachedAt < 50 * 60 * 1000L }

    /** O anúncio guardado, tirando-o do slot (cada um só aparece uma vez); null se não há nenhum pronto. */
    fun take(unitId: String): T? = fresh(unitId)?.also { cached = null }

    /** Esquece o guardado (quem pegou por `load` vai mostrá-lo). */
    fun forget() { cached = null }

    /** Carrega (ou usa o guardado) e guarda; `done(null)` se não veio. */
    fun load(a: Activity, unitId: String, done: (T?) -> Unit) {
        fresh(unitId)?.let { return done(it) }
        waiting.add(done)
        if (loadingUnit == unitId) return  // já está carregando: recebe quando chegar
        loadingUnit = unitId
        request(a, unitId, { ad ->
            loadingUnit = ""
            cached = ad
            cachedUnit = unitId
            cachedAt = System.currentTimeMillis()
            answer(ad)
        }, { e ->
            loadingUnit = ""
            Log.w("NaLata", "$name load: ${e.code} ${e.message}")
            lastLoadError = if (e.code == AdRequest.ERROR_CODE_NO_FILL) "no_fill" else "load_${e.code}"
            answer(null)
        })
    }

    private fun answer(ad: T?) {
        val all = waiting.toList()
        waiting.clear()
        all.forEach { it(ad) }
    }
}
