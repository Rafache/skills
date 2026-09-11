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

  route)
    DOMAIN="${2:-}"
    if ! ip link show "${IFACE}" >/dev/null 2>&1; then
      echo "Erreur : le VPN n'est pas connecté (${IFACE} introuvable)." >&2
      exit 1
    fi
    if [ -z "${DOMAIN}" ] || ! [[ "${DOMAIN}" =~ ^[a-zA-Z0-9][-a-zA-Z0-9.]*\.[a-zA-Z]{2,}$ ]]; then
      echo "Erreur : seul un nom d'hôte valide est accepté (ex: preprod-pape-france.prionseneglise.fr)." >&2
      exit 1
    fi
    IPS=$(getent ahostsv4 "${DOMAIN}" | awk '{print $1}' | sort -u)
    if [ -z "${IPS}" ]; then
      echo "Erreur : aucune adresse IPv4 résolue pour ${DOMAIN}." >&2
      exit 1
    fi
    echo "Routage de ${DOMAIN} via ${IFACE} :"
    for ip in ${IPS}; do
      ip route replace "${ip}/32" dev "${IFACE}"
      echo "  + ${ip}/32 -> ${IFACE}"
    done
    ;;

  unroute)
    DOMAIN="${2:-}"
    if [ -z "${DOMAIN}" ] || ! [[ "${DOMAIN}" =~ ^[a-zA-Z0-9][-a-zA-Z0-9.]*\.[a-zA-Z]{2,}$ ]]; then
      echo "Erreur : seul un nom d'hôte valide est accepté." >&2
      exit 1
    fi
    IPS=$(getent ahostsv4 "${DOMAIN}" | awk '{print $1}' | sort -u)
    echo "Suppression des routes pour ${DOMAIN} :"
    for ip in ${IPS}; do
      ip route del "${ip}/32" dev "${IFACE}" 2>/dev/null || true
      echo "  - ${ip}/32"
    done
    ;;

  *)
    echo "Usage: bayard-vpn {start [OTP]|stop|status|logs|route <domaine>|unroute <domaine>}"
    exit 1
    ;;
esac
