#!/usr/bin/env bash
# Preparação comum das exportações Android (lido com "source" por export_android.sh e
# export_android_release.sh): Godot + modelos, Android SDK, caminhos do SDK/Java para o Godot e o
# modelo "Gradle build" em android/build. Define ANDROID_HOME, JAVA_HOME e TEMPLATE_FLAG.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build/android && touch build/.gdignore  # o Godot não deve importar o que já foi exportado
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
JAVA_HOME="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
export JAVA_HOME

"$ROOT/tools/install_godot.sh" --templates >/dev/null
"$ROOT/tools/install_android_sdk.sh"

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
