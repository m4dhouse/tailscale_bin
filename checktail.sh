#!/bin/sh
echo "check_certificate = off" >> ~/.wgetrc
echo "Install Wireguard Tailscale"
echo ""
if [ -f /usr/bin/tailscale ];then
  rm -r /usr/bin/tailscale >/dev/null 2>&1
else
  echo ""
fi;
if [ -f /usr/bin/tailscaled ];then
  rm -r /usr/bin/tailscaled >/dev/null 2>&1
else
  echo ""
fi;
wget -qO /tmp/tailscale.ipk "https://raw.githubusercontent.com/m4dhouse/tailscale_bin/main/tailscale_1.76.1_arm_all.ipk" >/dev/null 2>&1
opkg --force-reinstall --force-overwrite install /tmp/tailscale.ipk >/dev/null 2>&1
chmod 777 /usr/bin/tailscale
chmod 777 /usr/bin/tailscaled
chmod 777 /etc/init.d/tailscale
rm -rf /tmp/tailscale.ipk
echo "Wireguard tailscale installed"
sleep 3
exit 0
