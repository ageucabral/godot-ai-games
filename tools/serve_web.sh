#!/usr/bin/env bash
# Serve build/web/ localmente em http://localhost:8060 para testar no navegador.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/build/web"
exec python3 -m http.server "${PORT:-8060}"
