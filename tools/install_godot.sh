#!/usr/bin/env bash
# Instala o Godot (Linux x86_64) de forma reproduzível, sem precisar de root.
#
# Uso:
#   tools/install_godot.sh              # só o editor/motor (para testes)
#   tools/install_godot.sh --templates  # também os modelos de exportação Web e Android
#
# Instala em $GODOT_HOME (padrão: ~/.local/share/godot-ci) e cria o atalho
# ~/.local/bin/godot. Se já estiver instalado na versão certa, não faz nada.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=godot_version.env
source "$ROOT/tools/godot_version.env"

WANT_TEMPLATES=0
[[ "${1:-}" == "--templates" ]] && WANT_TEMPLATES=1

TAG="${GODOT_VERSION}-${GODOT_FLAVOR}"
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${TAG}"
GODOT_HOME="${GODOT_HOME:-$HOME/.local/share/godot-ci}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
BIN_NAME="Godot_v${TAG}_linux.x86_64"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_FLAVOR}"

mkdir -p "$GODOT_HOME" "$BIN_DIR"

download() { # url destino sha512
  local url="$1" dest="$2" sum="$3"
  echo "Baixando $url"
  curl -fsSL --retry 4 --retry-delay 2 -o "$dest.part" "$url"
  echo "$sum  $dest.part" | sha512sum -c --quiet - || { echo "ERRO: checksum não confere para $url" >&2; rm -f "$dest.part"; exit 1; }
  mv "$dest.part" "$dest"
}

# 1) Motor
if [[ -x "$GODOT_HOME/$BIN_NAME" ]]; then
  echo "Godot $TAG já instalado em $GODOT_HOME"
else
  tmp="$(mktemp -d)"
  download "$BASE_URL/${BIN_NAME}.zip" "$tmp/godot.zip" "$GODOT_LINUX_SHA512"
  unzip -q -o "$tmp/godot.zip" -d "$GODOT_HOME"
  chmod +x "$GODOT_HOME/$BIN_NAME"
  rm -rf "$tmp"
fi
ln -sf "$GODOT_HOME/$BIN_NAME" "$BIN_DIR/godot"

# 2) Modelos de exportação (só Web e Android, para economizar espaço)
if [[ $WANT_TEMPLATES -eq 1 ]]; then
  # android_source.zip = modelo do "Gradle build" (preciso para o plugin Android: login Google e AdMob)
  if [[ -f "$TEMPLATES_DIR/web_nothreads_release.zip" && -f "$TEMPLATES_DIR/android_debug.apk" && -f "$TEMPLATES_DIR/android_source.zip" ]]; then
    echo "Modelos de exportação Web e Android já instalados em $TEMPLATES_DIR"
  else
    tmp="$(mktemp -d)"
    echo "(o pacote de modelos tem ~1,3 GB; pode demorar alguns minutos)"
    download "$BASE_URL/Godot_v${TAG}_export_templates.tpz" "$tmp/templates.tpz" "$GODOT_TEMPLATES_SHA512"
    mkdir -p "$TEMPLATES_DIR"
    unzip -q -o -j "$tmp/templates.tpz" 'templates/web*' 'templates/android_debug.apk' 'templates/android_release.apk' 'templates/android_source.zip' 'templates/version.txt' -d "$TEMPLATES_DIR"
    rm -rf "$tmp"
  fi
fi

"$BIN_DIR/godot" --version
echo "Pronto. Use: godot --headless --path \"$ROOT\" ..."
