#!/usr/bin/env bash
# Gera um APK de TESTE (assinado com chave de depuração) em build/android/na-lata-teste.apk.
# Serve para instalar direto no celular. A versão da Google Play sai de tools/export_android_release.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/android_common.sh"
OUT="build/android/na-lata-teste.apk"

# Chave de depuração (a mesma em todas as máquinas não importa para testes).
KEYSTORE="$HOME/.local/share/godot/keystores/debug.keystore"
if [[ ! -f "$KEYSTORE" ]]; then
  mkdir -p "$(dirname "$KEYSTORE")"
  keytool -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android \
    -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 10000 2>/dev/null
fi
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"

"$ROOT/tools/godot.sh" --headless --path "$ROOT" "${TEMPLATE_FLAG[@]}" --export-debug "Android" "$OUT"
test -s "$OUT"
"$ANDROID_HOME/build-tools/36.1.0/apksigner" verify "$OUT"
ls -la "$OUT"
echo "APK de teste pronto em $OUT"
