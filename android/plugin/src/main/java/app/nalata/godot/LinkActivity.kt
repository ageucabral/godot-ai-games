package app.nalata.godot

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * Recebe o link do duelo (nalata://duelo/CÓDIGO), guarda para o jogo ler (`takeLink`) e abre o app.
 * Fica invisível: só passa o link adiante e fecha.
 */
class LinkActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val link = intent?.dataString ?: ""
        if (link.isNotEmpty()) {
            getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("link", link).apply()
        }
        packageManager.getLaunchIntentForPackage(packageName)?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            startActivity(it)
        }
        finish()
    }

    companion object {
        const val PREFS = "nalata_link"
    }
}
