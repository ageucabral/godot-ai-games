#!/usr/bin/env bash
# Gera o pacote da Google Play (AAB) em build/android/na-lata.aab: preset "Android Play",
# pacote app.nalata.android (o mesmo do app atual na Play), assinado com a chave de envio (upload key).
#
# A chave NUNCA vai para o git. Passe por variáveis de ambiente:
#   NALATA_KEYSTORE           caminho do arquivo .jks/.keystore (baixado do expo.dev)
#   NALATA_KEYSTORE_PASSWORD  senha do arquivo
#   NALATA_KEY_ALIAS          alias da chave
#   NALATA_KEY_PASSWORD       senha da chave (se vazia, usa a do arquivo)
# Exemplo: NALATA_KEYSTORE=~/chaves/nalata.jks NALATA_KEYSTORE_PASSWORD=... NALATA_KEY_ALIAS=... \
#          tools/export_android_release.sh
set -euo pipefail
: "${NALATA_KEYSTORE:?Informe NALATA_KEYSTORE (arquivo da chave de envio)}"
: "${NALATA_KEYSTORE_PASSWORD:?Informe NALATA_KEYSTORE_PASSWORD}"
: "${NALATA_KEY_ALIAS:?Informe NALATA_KEY_ALIAS}"
NALATA_KEY_PASSWORD="${NALATA_KEY_PASSWORD:-$NALATA_KEYSTORE_PASSWORD}"
NALATA_KEYSTORE="$(readlink -f "$NALATA_KEYSTORE")"
test -f "$NALATA_KEYSTORE" || { echo "Arquivo da chave não encontrado: $NALATA_KEYSTORE" >&2; exit 1; }

source "$(dirname "${BASH_SOURCE[0]}")/android_common.sh"
OUT="build/android/na-lata.aab"

# Confere a chave antes de gastar minutos no Gradle (senha ou alias errados param aqui).
# (senhas por ":env", para não aparecerem na lista de processos)
export NALATA_KEYSTORE_PASSWORD NALATA_KEY_PASSWORD
keytool -list -keystore "$NALATA_KEYSTORE" -storepass:env NALATA_KEYSTORE_PASSWORD -alias "$NALATA_KEY_ALIAS" >/dev/null

# O Godot usa uma senha só (arquivo e chave). Se a do alias for diferente (comum nas chaves do Expo),
# assina com uma cópia temporária em que a chave passa a ter a senha do arquivo; a chave em si não muda.
SIGN_KEYSTORE="$NALATA_KEYSTORE"
if [[ "$NALATA_KEY_PASSWORD" != "$NALATA_KEYSTORE_PASSWORD" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  SIGN_KEYSTORE="$TMP_DIR/upload.jks"
  keytool -importkeystore -noprompt -srckeystore "$NALATA_KEYSTORE" -srcstorepass:env NALATA_KEYSTORE_PASSWORD \
    -srcalias "$NALATA_KEY_ALIAS" -srckeypass:env NALATA_KEY_PASSWORD \
    -destkeystore "$SIGN_KEYSTORE" -deststoretype PKCS12 -deststorepass:env NALATA_KEYSTORE_PASSWORD \
    -destkeypass:env NALATA_KEYSTORE_PASSWORD >/dev/null
fi
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$SIGN_KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$NALATA_KEY_ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$NALATA_KEYSTORE_PASSWORD"

rm -f "$OUT"
"$ROOT/tools/godot.sh" --headless --path "$ROOT" "${TEMPLATE_FLAG[@]}" --export-release "Android Play" "$OUT"
test -s "$OUT"
# O AAB é assinado com jarsigner: confere a assinatura e mostra a impressão digital (SHA-1/SHA-256) da chave,
# que tem de ser a mesma "chave de upload" cadastrada na Play Console.
# (um AAB SEM assinatura também sai com 0, só dizendo "jar is unsigned": por isso confere o texto)
VERIFY_OUT="$(jarsigner -verify "$OUT")"
grep -q "jar verified" <<<"$VERIFY_OUT" || { echo "AAB sem assinatura válida: $OUT" >&2; exit 1; }
keytool -printcert -jarfile "$OUT" | grep -E "SHA1|SHA256" || true
ls -la "$OUT"
VERSION_NAME="$(sed -n '/\[preset.2.options\]/,$p' export_presets.cfg | grep -m1 '^version/name' | cut -d'"' -f2)"
echo "Pacote da Play pronto em $OUT (versão $VERSION_NAME)"
