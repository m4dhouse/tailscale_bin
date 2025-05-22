#!/bin/sh
echo "check_certificate = off" >> ~/.wgetrc

echo "Installing Wireguard Tailscale"
echo ""

BOXNAME=$(head -n 1 /etc/hostname)

[ -f /usr/bin/tailscale ] && rm -f /usr/bin/tailscale
[ -f /usr/bin/tailscaled ] && rm -f /usr/bin/tailscaled

ARCH=$(uname -m)

case "$ARCH" in
  arm*)
    TAILSCALE_URL="https://raw.githubusercontent.com/m4dhouse/tailscale_bin/main/tailscale_1.84.0_arm_all.ipk"
    ;;
  mips*)
    TAILSCALE_URL="https://raw.githubusercontent.com/m4dhouse/tailscale_bin/main/tailscale_1.84.0_mipsel_all.ipk"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

wget -qO /tmp/tailscale.ipk "$TAILSCALE_URL"
if [ $? -ne 0 ]; then
  echo "Error downloading Tailscale package"
  exit 1
fi


if [[ "$BOXNAME" == "sf8008" ]];then
  wget -qO /tmp/kernel-module-tun.ipk "https://raw.githubusercontent.com/m4dhouse/tailscale_bin/main/kernel-module-tun.ipk" >/dev/null 2>&1
  opkg --force-reinstall --force-overwrite install /tmp/kernel-module-tun.ipk >/dev/null 2>&1
fi;

opkg --force-reinstall --force-overwrite install /tmp/tailscale.ipk >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error installing Tailscale package"
  rm -rf /tmp/tailscale.ipk
  exit 1
fi

chmod 777 /usr/bin/tailscale
chmod 777 /usr/bin/tailscaled
chmod 777 /etc/init.d/tailscale

rm -rf /tmp/tailscale.ipk
rm -rf /tmp/kernel-module-tun.ipk

echo "Wireguard Tailscale successfully installed"
sleep 3
exit 0
