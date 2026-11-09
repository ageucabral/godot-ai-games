#!/usr/bin/env bash
# Põe os símbolos de depuração do motor (tabela de símbolos do libgodot_android.so e do libc++_shared.so) dentro
# de um AAB, onde a Play os lê sozinha (BUNDLE-METADATA/com.android.tools.build.debugsymbols/<abi>/<lib>.so.sym),
# e assina o AAB de novo. Assim some o aviso "você não fez upload dos símbolos de depuração" e os relatórios de
# travamento (falhas e ANRs) mostram os nomes das funções do Godot.
#
# Os símbolos vêm da release oficial do Godot (conferidos por SHA-512 e pelo Build ID de cada biblioteca do AAB).
# Uso (o export_android_release.sh chama): tools/android_debug_symbols.sh <app.aab> <keystore> <alias>
#   com a senha em NALATA_KEYSTORE_PASSWORD (a mesma do arquivo e da chave).
set -euo pipefail
AAB="$(readlink -f "$1")" KEYSTORE="$2" ALIAS="$3"
: "${NALATA_KEYSTORE_PASSWORD:?Informe NALATA_KEYSTORE_PASSWORD}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=godot_version.env
source "$ROOT/tools/godot_version.env"
command -v llvm-objcopy >/dev/null && command -v llvm-readelf >/dev/null \
  || { echo "ERRO: falta o llvm (llvm-objcopy e llvm-readelf): sudo apt-get install llvm" >&2; exit 1; }

TAG="${GODOT_VERSION}-${GODOT_FLAVOR}"
NAME="Godot_native_debug_symbols.${GODOT_VERSION}.${GODOT_FLAVOR}.template_release.android.zip"
CACHE="${GODOT_HOME:-$HOME/.local/share/godot-ci}/$NAME"  # ~780 MB: baixa uma vez só
if [[ ! -f "$CACHE" ]]; then
  echo "Baixando os símbolos de depuração do Godot $TAG (~780 MB)"
  curl -fsSL --retry 4 --retry-delay 2 -o "$CACHE.part" "https://github.com/godotengine/godot-builds/releases/download/${TAG}/${NAME}"
  echo "$GODOT_ANDROID_SYMBOLS_SHA512  $CACHE.part" | sha512sum -c --quiet - || { echo "ERRO: checksum dos símbolos não confere" >&2; rm -f "$CACHE.part"; exit 1; }
  mv "$CACHE.part" "$CACHE"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/out/BUNDLE-METADATA/com.android.tools.build.debugsymbols"
unzip -q "$AAB" 'base/lib/*' -d "$WORK/aab"
for lib in "$WORK"/aab/base/lib/*/*.so; do
  rel="${lib#"$WORK"/aab/base/lib/}"  # <abi>/<lib>.so
  if ! unzip -q -o "$CACHE" "$rel" -d "$WORK/full" 2>/dev/null; then
    echo "Sem símbolos para $rel (biblioteca de outro pacote): pulando"
    continue
  fi
  want="$(llvm-readelf -n "$lib" | grep "Build ID" || true)"
  got="$(llvm-readelf -n "$WORK/full/$rel" | grep "Build ID" || true)"
  [[ -n "$want" && "$want" == "$got" ]] || { echo "ERRO: os símbolos não são do mesmo motor que $rel" >&2; exit 1; }
  # Só a tabela de símbolos (como o "SYMBOL_TABLE" do Android): ~20 MB por biblioteca em vez de ~700 MB.
  mkdir -p "$OUT/$(dirname "$rel")"
  llvm-objcopy --strip-debug --only-keep-debug "$WORK/full/$rel" "$OUT/$rel.sym"
  rm -f "$WORK/full/$rel"
done

# Coloca no AAB e assina de novo (a assinatura antiga não cobre os arquivos novos).
(cd "$WORK/out" && zip -q -r -D "$AAB" BUNDLE-METADATA)
zip -q -d "$AAB" 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.EC' 'META-INF/*.DSA' 'META-INF/MANIFEST.MF' >/dev/null 2>&1 || true
jarsigner -keystore "$KEYSTORE" -storepass:env NALATA_KEYSTORE_PASSWORD "$AAB" "$ALIAS" >/dev/null
echo "Símbolos de depuração incluídos: $(unzip -l "$AAB" 'BUNDLE-METADATA/com.android.tools.build.debugsymbols/*' | tail -1)"
