#!/usr/bin/env bash
# Exporta o jogo para Web em build/web/ (index.html + arquivos .wasm/.pck).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build && touch build/.gdignore  # o Godot não deve importar o que já foi exportado
"$ROOT/tools/install_godot.sh" --templates >/dev/null
mkdir -p build/web
"$ROOT/tools/godot.sh" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$ROOT/tools/godot.sh" --headless --path "$ROOT" --export-release "Web" build/web/index.html
ls -la build/web
test -f build/web/index.html && test -f build/web/index.pck && test -f build/web/index.wasm
echo "Exportação Web concluída em build/web/"
