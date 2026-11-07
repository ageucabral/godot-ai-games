#!/usr/bin/env bash
# Testa a versão Web exportada num navegador sem tela (precisa de Node + Playwright).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -f build/web/index.html ]] || "$ROOT/tools/export_web.sh"
PORT="${PORT:-8060}"
python3 -m http.server "$PORT" --directory build/web >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true' EXIT
sleep 1
NODE_PATH="${NODE_PATH:-$(npm root -g)}" node "$ROOT/tools/web_smoke_test.js" "http://localhost:$PORT/index.html" "build/web_screenshot.png"
