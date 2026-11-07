#!/usr/bin/env bash
# Roda todos os testes automatizados sem abrir janela.
# Sai com código 0 só se TODOS passarem.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# Importa os recursos (necessário na primeira vez e após adicionar arquivos).
"$ROOT/tools/godot.sh" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$ROOT/tools/godot.sh" --headless --path "$ROOT" --script res://tests/run_tests.gd -- "$@"
