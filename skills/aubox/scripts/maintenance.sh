#!/usr/bin/env bash
# ==============================================================================
# AuBox - Maintenance mensuelle (cron : 1er dimanche du mois à 04:00), lançable à la main.
#
# - apt : uniquement en lancement manuel (sudo demande le mot de passe). En cron, les
#   correctifs de sécurité sont appliqués chaque jour par unattended-upgrades.
# - Docker : met à jour les images non figées de chaque stack ~/services/*/compose.yaml
#   et ne recrée que les conteneurs dont l'image a changé. Les images figées (tag précis,
#   ex. Home Assistant) ne bougent pas : on les met à jour en changeant le tag.
# - Ménage : conteneurs, réseaux et images orphelins, cache de build de plus de 30 jours.
# - Notification iPhone (webhook HA) seulement si une image a été mise à jour,
#   si un redémarrage est requis ou en cas d'erreur.
# ==============================================================================

set -uo pipefail

ENV_FILE="${AUBOX_BACKUP_ENV:-${HOME}/.config/aubox/backup.env}"
# shellcheck source=/dev/null
[ -f "${ENV_FILE}" ] && source "${ENV_FILE}"
notify() {
  [ -n "${HA_WEBHOOK_URL:-}" ] || return 0
  curl -s -m 10 -X POST -H 'Content-Type: application/json' \
    -d "$(jq -n --arg t "$1" --arg m "$2" '{title: $t, message: $m}')" \
    "${HA_WEBHOOK_URL}" >/dev/null || true
}
ERRORS=()
UPDATED=()

echo "=== Maintenance AuBox [$(date '+%F %T')] ==="

# 1. Paquets système (lancement manuel uniquement)
if [ -t 0 ]; then
  echo "[+] Mise à jour apt..."
  { sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean; } || ERRORS+=("apt")
else
  echo "[i] apt ignoré hors lancement manuel (unattended-upgrades s'en charge)."
fi

# 2. Images Docker des stacks permanentes
for f in "${HOME}"/services/*/compose.yaml; do
  stack="$(basename "$(dirname "${f}")")"
  before="$(docker compose -f "${f}" images -q 2>/dev/null | sort)"
  echo "[+] ${stack} : pull..."
  if docker compose -f "${f}" pull --ignore-buildable --quiet && docker compose -f "${f}" up -d --remove-orphans --quiet-pull; then
    after="$(docker compose -f "${f}" images -q 2>/dev/null | sort)"
    [ "${before}" != "${after}" ] && UPDATED+=("${stack}")
  else
    ERRORS+=("docker ${stack}")
  fi
done

# 3. Ménage Docker (jamais de volumes)
docker system prune -f >/dev/null || ERRORS+=("docker prune")
docker builder prune -f --filter until=720h >/dev/null || ERRORS+=("builder prune")

# 4. Paquets npm globaux
export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"
npm update -g >/dev/null 2>&1 || ERRORS+=("npm")

# 5. Démons IA
if systemctl --user is-failed codex-remote-control.service >/dev/null 2>&1; then
  echo "[+] Réparation de Codex Remote Control..."
  rm -f "${HOME}/.codex/app-server-daemon"/*.pid "${HOME}/.codex/app-server-daemon"/*.lock
  systemctl --user restart codex-remote-control.service || ERRORS+=("codex-remote-control")
fi

# 6. Bilan
MSG=""
[ ${#UPDATED[@]} -gt 0 ] && MSG+="Mis à jour : ${UPDATED[*]}. "
[ -f /var/run/reboot-required ] && MSG+="Redémarrage requis. "
[ ${#ERRORS[@]} -gt 0 ] && MSG+="Erreurs : ${ERRORS[*]}."
echo "[i] ${MSG:-Rien à signaler.}"
[ -n "${MSG}" ] && notify "Maintenance AuBox" "${MSG}"
echo "=== Maintenance terminée [$(date '+%F %T')] ==="
[ ${#ERRORS[@]} -eq 0 ]
