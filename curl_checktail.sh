#!/bin/sh

echo "insecure" >> ~/.curlrc

echo "Installing Tailscale (latest stable) + init.d + TUN module"
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

BOXNAME=$(head -n 1 /etc/hostname 2>/dev/null)

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
    exit 1
fi

VERSION=$(echo "$TARBALL" | cut -d_ -f2)
TGZ_URL="https://pkgs.tailscale.com/stable/${TARBALL}"
TGZ_FILE="/tmp/${TARBALL}"

echo "Ultima versione trovata: ${VERSION} (${TARBALL})"
echo "Scaricando ${TGZ_URL} ..."

curl -fsSL --insecure -o "$TGZ_FILE" "$TGZ_URL" || {
    echo "Errore nel download dell'archivio Tailscale."
    rm -f "$TGZ_FILE"
    exit 1
}

echo "Estrazione dei binari..."
tar -xzf "$TGZ_FILE" -C /tmp || {
    echo "Errore nell'estrazione dell'archivio."
    rm -f "$TGZ_FILE"
    exit 1
}

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
rm -rf "$EXTRACT_DIR" "$TGZ_FILE"

echo "Installazione kernel-module-tun e update-rc.d ..."
opkg update >/dev/null 2>&1
opkg install kernel-module-tun >/dev/null 2>&1 || {
    echo "ATTENZIONE: installazione di kernel-module-tun fallita."
    echo "Potrebbe essere necessario installarlo manualmente."
}
opkg install update-rc.d >/dev/null 2>&1 || {
    echo "ATTENZIONE: installazione di update-rc.d fallita."
    echo "Potrebbe essere necessario installarlo manualmente."
}

modprobe tun 2>/dev/null

INIT_URL="https://raw.githubusercontent.com/m4dhouse/tailscale_bin/refs/heads/main/tailscale"
INIT_DEST="/etc/init.d/tailscale"

echo "Scaricando lo script init.d da $INIT_URL ..."
curl -fsSL --insecure -o "$INIT_DEST" "$INIT_URL" || {
    echo "ERRORE: download dello script init.d fallito."
    rm -f "$INIT_DEST"
    exit 1
}

chmod 777 "$INIT_DEST"
echo "Script init.d installato in $INIT_DEST (permessi 777)."

if [ -x /usr/bin/tailscale ] && [ -x /usr/bin/tailscaled ] && [ -x "$INIT_DEST" ]; then
    echo "Installazione completata con successo."
    echo "Versione Tailscale:"
    /usr/bin/tailscale version
else
    echo "ERRORE: installazione non riuscita."
    exit 1
fi

sleep 3
exit 0
