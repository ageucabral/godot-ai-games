#!/usr/bin/env bash
# Encontra o executável do Godot (instalando se faltar) e o executa.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN="$(command -v godot)"
  elif [[ -x "$HOME/.local/bin/godot" ]]; then GODOT_BIN="$HOME/.local/bin/godot"
  else
    "$ROOT/tools/install_godot.sh" >&2
    GODOT_BIN="$HOME/.local/bin/godot"
  fi
fi
exec "$GODOT_BIN" "$@"
