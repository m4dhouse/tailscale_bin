#!/bin/sh
# shell created by madhouse
PYVERSION=$(python -c "import sys; print(sys.version_info.minor)")
ARCHITECTURE=$(uname -m)

case $PYVERSION in
  13)
    BASE_BRANCH='python-3.13'
    ;;
  12)
    BASE_BRANCH='python-3.12'
    ;;
  11)
    BASE_BRANCH='python3'
    ;;
  9)
    BASE_BRANCH='python-3.9'
    ;;
  *)
    echo "Unsupported Python version: $PYVERSION"
    exit 1
    ;;
esac

RAW_URL_IPK="https://raw.githubusercontent.com/m4dhouse/Wireguard-Vpn/$BASE_BRANCH/version"
FILE_IPK=$(python -c "import urllib.request; print(urllib.request.urlopen('$RAW_URL_IPK').read().decode())")

case $ARCHITECTURE in
  arm*)
    URL_IPK="https://raw.githubusercontent.com/m4dhouse/Wireguard-Vpn/$BASE_BRANCH/enigma2-plugin-extensions-wireguard-vpn_${FILE_IPK}_all.ipk"
    ;;
  mips*)
    URL_IPK="https://raw.githubusercontent.com/m4dhouse/Wireguard-Vpn/$BASE_BRANCH/enigma2-plugin-extensions-wireguard-vpn-mips_${FILE_IPK}_all.ipk"
    ;;
  aarch64*)
    URL_IPK="https://raw.githubusercontent.com/m4dhouse/Wireguard-Vpn/$BASE_BRANCH/enigma2-plugin-extensions-wireguard-vpn-aarch64_${FILE_IPK}_all.ipk"
    ;;
  *)
    echo "Unsupported architecture: $ARCHITECTURE"
    exit 1
    ;;
esac

echo '====================================='
echo '   I install WireGuard VPN plugin'
echo '====================================='
opkg --force-reinstall --force-overwrite --force-depends install $URL_IPK
echo ''
echo '===================================='
echo '         Restarting enigma2         '
echo '===================================='
init 4
init 3
exit 0
