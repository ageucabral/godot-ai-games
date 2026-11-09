#!/usr/bin/env bash
# Preparação comum das exportações Android (lido com "source" por export_android.sh e
# export_android_release.sh): Godot + modelos, Android SDK, caminhos do SDK/Java para o Godot e o
# modelo "Gradle build" em android/build (com o R8 ligado na versão release). Define ANDROID_HOME e JAVA_HOME.
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

# "Gradle build" (precisa do plugin Android: login Google e AdMob): o modelo vai para android/build na primeira
# exportação e é reinstalado com versão nova do Godot. Instalamos aqui mesmo (como o Godot faz com
# --install-android-build-template) para poder ligar o R8 antes da exportação.
# shellcheck source=godot_version.env
source "$ROOT/tools/godot_version.env"
if [[ ! -f "$ROOT/android/build/build.gradle" ]] || ! grep -qxF "${GODOT_VERSION}.${GODOT_FLAVOR}" "$ROOT/android/.build_version" 2>/dev/null; then
  rm -rf "$ROOT/android/build" "$ROOT/android/.build_version"
  SOURCE_ZIP="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_FLAVOR}/android_source.zip"
  mkdir -p "$ROOT/android/build"
  unzip -q -o "$SOURCE_ZIP" -d "$ROOT/android/build"
  touch "$ROOT/android/build/.gdignore"
  echo "${GODOT_VERSION}.${GODOT_FLAVOR}" > "$ROOT/android/.build_version"
fi

# AGP 9 (a Play recomenda; o modelo do Godot 4.7 vem com o AGP 8.6.1 e o Gradle 8.11.1). As duas chaves no
# gradle.properties mantêm o Kotlin e a DSL antigos que o modelo do Godot ainda usa.
AGP_VERSION="9.5.1"
GRADLE_VERSION="9.9.0"
if ! grep -q "nalata-agp9" "$ROOT/android/build/gradle.properties"; then
  sed -i -E "s/(androidGradlePlugin: *')[^']+'/\1${AGP_VERSION}'/" "$ROOT/android/build/config.gradle"
  sed -i -E "s#gradle-[0-9.]+-bin\.zip#gradle-${GRADLE_VERSION}-bin.zip#" "$ROOT/android/build/gradle/wrapper/gradle-wrapper.properties"
  printf '\n# nalata-agp9\nandroid.builtInKotlin=false\nandroid.newDsl=false\n' >> "$ROOT/android/build/gradle.properties"
fi

# R8 na versão "release" (a da Play): encolhe e otimiza o código Java/Kotlin, regras em android/proguard-rules.pro.
# O mapa para ler os erros fica em android/build/build/outputs/mapping/standardRelease/mapping.txt.
if ! grep -q "nalata-r8" "$ROOT/android/build/build.gradle"; then
  python3 - "$ROOT/android/build/build.gradle" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
anchor = "        release {\n"
at = s.index(anchor, s.index("buildTypes {")) + len(anchor)  # o "release" dos buildTypes, não o da assinatura
s = s[:at] + ("            // nalata-r8\n            minifyEnabled true\n"
              "            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), '../proguard-rules.pro'\n") + s[at:]
open(p, "w").write(s)
PY
fi
