#!/usr/bin/env bash
# Executado automaticamente no início de cada sessão do Claude Code na Web.
# Garante que o Godot esteja instalado e os recursos importados.
set -uo pipefail
[[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]] || exit 0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/tools/install_godot.sh" >/dev/null 2>&1 || { echo "Aviso: não foi possível instalar o Godot automaticamente."; exit 0; }
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"; fi
"$HOME/.local/bin/godot" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
echo "Godot $("$HOME/.local/bin/godot" --version) pronto."
