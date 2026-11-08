#!/usr/bin/env bash
# Instala o mínimo do Android SDK para o Godot gerar APK (sem Android Studio).
# Usa $ANDROID_HOME (padrão: ~/android-sdk). Se já tiver o apksigner, não faz nada.
set -euo pipefail
ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
BUILD_TOOLS="35.0.0"
# O "Gradle build" do Godot 4.7 (plugin Android) compila com a API 36 e as build-tools 36.1.0.
GRADLE_BUILD_TOOLS="36.1.0"
if [[ -x "$ANDROID_HOME/build-tools/$BUILD_TOOLS/apksigner" && -x "$ANDROID_HOME/build-tools/$GRADLE_BUILD_TOOLS/apksigner" && -d "$ANDROID_HOME/platforms/android-36" ]]; then
  echo "Android SDK já instalado em $ANDROID_HOME"
  exit 0
fi
mkdir -p "$ANDROID_HOME/cmdline-tools"
if [[ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]; then
  tmp="$(mktemp -d)"
  curl -fsSL --retry 4 -o "$tmp/clt.zip" "https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
  unzip -q "$tmp/clt.zip" -d "$tmp"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$tmp"
fi
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" \
  "platform-tools" "build-tools;$BUILD_TOOLS" "platforms;android-35" \
  "build-tools;$GRADLE_BUILD_TOOLS" "platforms;android-36" >/dev/null
echo "Android SDK instalado em $ANDROID_HOME"
