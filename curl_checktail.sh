#!/bin/sh
echo "insecure" >> ~/.curlrc

echo "Installing Tailscale (latest stable)"
echo ""

if ! command -v curl >/dev/null 2>&1; then
  echo "curl non trovato, provo a installarlo dal feed..."
  if [ -d /etc/opkg ]; then
    opkg update >/dev/null 2>&1
    opkg install curl >/dev/null 2>&1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "ERRORE: curl non disponibile. Installalo manualmente."
    exit 1
  fi
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERRORE: python3 non disponibile. Installalo prima di procedere."
  exit 1
fi

BOXNAME=$(head -n 1 /etc/hostname)

[ -f /usr/bin/tailscale ] && rm -f /usr/bin/tailscale
[ -f /usr/bin/tailscaled ] && rm -f /usr/bin/tailscaled

ARCH=$(uname -m)

case "$ARCH" in
  arm*)
    TS_KEY="arm"
    ;;
  aarch64|arm64)
    TS_KEY="arm64"
    ;;
  mips*)
    TS_KEY="mipsle"
    ;;
  *)
    echo "Architettura non supportata: $ARCH"
    exit 1
    ;;
esac

JSON_URL="https://pkgs.tailscale.com/stable/?mode=json"
echo "Recupero l'ultima versione da $JSON_URL ..."

TARBALL=$(curl -fsSL --insecure "$JSON_URL" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['Tarballs']['${TS_KEY}'])
except Exception as e:
    sys.stderr.write('parse error: %s\n' % e)
")

if [ -z "$TARBALL" ]; then
  echo "ERRORE: impossibile determinare l'ultima versione per ${TS_KEY}."
  echo "Verifica la connessione con:"
  echo "  curl -fsSL --insecure '$JSON_URL' | head -n 20"
  exit 1
fi

VERSION=$(echo "$TARBALL" | cut -d_ -f2)
TGZ_URL="https://pkgs.tailscale.com/stable/${TARBALL}"
TGZ_FILE="/tmp/${TARBALL}"

echo "Ultima versione trovata: ${VERSION} (${TARBALL})"
echo "Scaricando ${TGZ_URL} ..."

curl -fsSL --insecure -o "$TGZ_FILE" "$TGZ_URL"
if [ $? -ne 0 ]; then
  echo "Errore nel download dell'archivio Tailscale."
  rm -f "$TGZ_FILE"
  exit 1
fi

echo "Estrazione dei binari..."
tar -xzf "$TGZ_FILE" -C /tmp
if [ $? -ne 0 ]; then
  echo "Errore nell'estrazione dell'archivio."
  rm -f "$TGZ_FILE"
  exit 1
fi

EXTRACT_DIR="/tmp/tailscale_${VERSION}_${TS_KEY}"

if [ ! -f "$EXTRACT_DIR/tailscale" ] || [ ! -f "$EXTRACT_DIR/tailscaled" ]; then
  echo "ERRORE: binari non trovati nell'archivio estratto."
  rm -rf "$EXTRACT_DIR" "$TGZ_FILE"
  exit 1
fi

mv -f "$EXTRACT_DIR/tailscale" /usr/bin/tailscale
mv -f "$EXTRACT_DIR/tailscaled" /usr/bin/tailscaled

chmod 755 /usr/bin/tailscale
chmod 755 /usr/bin/tailscaled

if [ "$BOXNAME" = "sf8008" ]; then
  echo "Installazione modulo kernel TUN per sf8008..."
  curl -fsSL --insecure -o /tmp/kernel-module-tun.ipk \
    "https://raw.githubusercontent.com/m4dhouse/tailscale_bin/main/kernel-module-tun.ipk" >/dev/null 2>&1
  opkg --force-reinstall --force-overwrite install /tmp/kernel-module-tun.ipk >/dev/null 2>&1
  rm -f /tmp/kernel-module-tun.ipk
fi

rm -rf "$EXTRACT_DIR" "$TGZ_FILE"

if [ -x /usr/bin/tailscale ] && [ -x /usr/bin/tailscaled ]; then
  echo "Tailscale ${VERSION} installato correttamente."
  /usr/bin/tailscale version
else
  echo "ERRORE: installazione non riuscita."
  exit 1
fi

sleep 3
exit 0
