#!/usr/bin/env bash
# Gera um APK de TESTE (assinado com chave de depuração) em build/android/na-lata-teste.apk.
# Serve para instalar direto no celular. Para a Google Play será preciso uma chave de
# publicação própria e o formato AAB (fica para depois).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build && touch build/.gdignore  # o Godot não deve importar o que já foi exportado
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
JAVA_HOME="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
OUT="build/android/na-lata-teste.apk"

"$ROOT/tools/install_godot.sh" --templates >/dev/null
"$ROOT/tools/install_android_sdk.sh"

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

# Diz ao Godot onde estão o Android SDK e o Java (configuração do "editor").
"$ROOT/tools/godot.sh" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
SETTINGS="$(ls "$HOME"/.config/godot/editor_settings-*.tres 2>/dev/null | head -1 || true)"
if [[ -n "$SETTINGS" ]]; then
  sed -i '/^export\/android\/android_sdk_path/d;/^export\/android\/java_sdk_path/d' "$SETTINGS"
  sed -i "/^\[resource\]/a export/android/android_sdk_path = \"$ANDROID_HOME\"\nexport/android/java_sdk_path = \"$JAVA_HOME\"" "$SETTINGS"
fi

# "Gradle build" (precisa do plugin Android: login Google e AdMob): o Godot instala o modelo em android/build
# na primeira exportação (--install-android-build-template); com versão nova do Godot, reinstala.
# shellcheck source=godot_version.env
source "$ROOT/tools/godot_version.env"
TEMPLATE_FLAG=()
if [[ ! -f "$ROOT/android/build/build.gradle" ]] || ! grep -qxF "${GODOT_VERSION}.${GODOT_FLAVOR}" "$ROOT/android/.build_version" 2>/dev/null; then
  rm -rf "$ROOT/android/build" "$ROOT/android/.build_version"
  TEMPLATE_FLAG=(--install-android-build-template)
fi

mkdir -p build/android
"$ROOT/tools/godot.sh" --headless --path "$ROOT" "${TEMPLATE_FLAG[@]}" --export-debug "Android" "$OUT"
test -s "$OUT"
"$ANDROID_HOME/build-tools/36.1.0/apksigner" verify "$OUT"
ls -la "$OUT"
echo "APK de teste pronto em $OUT"
