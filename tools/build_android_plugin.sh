#!/usr/bin/env bash
# Compila o plugin Android do Na Lata (android/plugin, Kotlin) e copia o .aar para addons/nalata_android/bin/.
# Precisa do Android SDK (tools/install_android_sdk.sh). O .aar gerado vai para o git.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
"$ROOT/tools/install_android_sdk.sh"
cd "$ROOT/android/plugin"
echo "sdk.dir=$ANDROID_HOME" > local.properties
./gradlew --no-daemon -q assembleRelease
mkdir -p "$ROOT/addons/nalata_android/bin"
cp build/outputs/aar/nalata-plugin-release.aar "$ROOT/addons/nalata_android/bin/nalata-release.aar"
echo "Plugin pronto em addons/nalata_android/bin/nalata-release.aar"
