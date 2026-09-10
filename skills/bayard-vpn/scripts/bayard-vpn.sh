#!/usr/bin/env bash
# Contrôle simple du VPN Bayard en Split-Tunneling
set -euo pipefail

[ "$(id -u)" -ne 0 ] && exec sudo /home/rafache/scripts/bayard-vpn.sh "$@"

IFACE="ppp-bayard"

case "${1:-status}" in
  start)
    OTP="${2:-}"
    [ -z "${OTP}" ] && read -r -p "Code FortiToken (6 chiffres) : " OTP
    
    echo "Connexion au VPN Bayard..."
    pkill openfortivpn 2>/dev/null || true
    openfortivpn -c /etc/openfortivpn/config --otp="${OTP}" --pppd-ifname="${IFACE}" > /var/log/bayard-vpn.log 2>&1 &
    
    sleep 4
    ip route replace 10.0.0.0/8 dev "${IFACE}"
    ip route replace 172.16.0.0/12 dev "${IFACE}"
    printf "nameserver 10.20.20.97\nnameserver 10.20.21.144\n" > /etc/resolv.conf.head
    sed -i '/10.20.20.97/d;/10.20.21.144/d' /etc/resolv.conf 2>/dev/null || true
    sed -i '1s/^/nameserver 10.20.20.97\nnameserver 10.20.21.144\n/' /etc/resolv.conf
    
    echo "VPN Bayard connecté."
    ;;

  stop)
    pkill openfortivpn 2>/dev/null || true
    rm -f /etc/resolv.conf.head
    sed -i '/10.20.20.97/d;/10.20.21.144/d' /etc/resolv.conf 2>/dev/null || true
    echo "VPN Bayard déconnecté."
    ;;

  status)
    if ip link show "${IFACE}" >/dev/null 2>&1; then
      echo "VPN Bayard : CONNECTÉ"
    else
      echo "VPN Bayard : DÉCONNECTÉ"
    fi
    ;;

  logs)
    tail -n 20 /var/log/bayard-vpn.log 2>/dev/null || echo "Aucun log."
    ;;

  *)
    echo "Usage: bayard-vpn {start [OTP]|stop|status|logs}"
    exit 1
    ;;
esac
