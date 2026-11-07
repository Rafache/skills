#!/usr/bin/env bash
# ==============================================================================
# AuBox - Maintenance mensuelle (cron : 1er dimanche du mois à 04:00), lançable à la main.
#
# - apt : uniquement en lancement manuel (sudo demande le mot de passe). En cron, les
#   correctifs de sécurité sont appliqués chaque jour par unattended-upgrades.
# - Docker : met à jour les images non figées de chaque stack ~/services/*/compose.yaml
#   et ne recrée que les conteneurs dont l'image a changé. Les images figées (tag précis,
#   ex. Home Assistant) ne bougent pas : on les met à jour en changeant le tag.
# - Ménage : conteneurs et réseaux orphelins, images sans conteneur de plus de 30 jours,
#   cache de build de plus de 30 jours,
#   volumes orphelins sans nom (identifiant brut de 64 caractères) ; les volumes nommés
#   (aubox_*, etc.) ne sont jamais supprimés automatiquement.
# - CLI : npm global (claude, wrangler, gws), uv, codex, agy, twg via leurs propres commandes.
# - Versions figées : signale une nouvelle version de Home Assistant ou de matterjs-server
#   (mise à jour manuelle : changer le tag dans ~/services/homeassistant/compose.yaml).
# - Notification iPhone (webhook HA) seulement si une image a été mise à jour, si une
#   nouvelle version figée existe, si un redémarrage est requis ou en cas d'erreur.
# ==============================================================================

set -uo pipefail
export PATH="${HOME}/.local/bin:${PATH}"  # cron n'inclut pas ~/.local/bin (uv, codex, agy, twg)

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

# 3. Ménage Docker
docker system prune -f >/dev/null || ERRORS+=("docker prune")
docker builder prune -f --filter until=720h >/dev/null || ERRORS+=("builder prune")
# Images sans aucun conteneur (même arrêté) et créées il y a plus de 30 jours
docker image prune -a -f --filter until=720h >/dev/null || ERRORS+=("image prune")
# Volumes orphelins sans nom uniquement (docker volume prune ignore ceux non marqués anonymes)
docker volume ls -qf dangling=true | grep -E '^[0-9a-f]{64}$' | xargs -r docker volume rm >/dev/null || ERRORS+=("volumes orphelins")

# 4. Paquets npm globaux
export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"
npm update -g >/dev/null 2>&1 || ERRORS+=("npm")

# 4bis. CLI autonomes (chacun via sa propre commande de mise à jour)
command -v uv >/dev/null && { uv self update -q </dev/null >/dev/null 2>&1 || ERRORS+=("uv"); }
command -v codex >/dev/null && { codex update </dev/null >/dev/null 2>&1 || ERRORS+=("codex"); }
command -v agy >/dev/null && { agy update </dev/null >/dev/null 2>&1 || ERRORS+=("agy"); }
command -v twg >/dev/null && { twg upgrade </dev/null >/dev/null 2>&1 || ERRORS+=("twg"); }

# 4ter. Versions figées : nouvelle version disponible ?
NEWVERS=()
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chromium/124.0 Safari/537.36"
HA_COMPOSE="${HOME}/services/homeassistant/compose.yaml"
for pair in "home-assistant/core|ghcr.io/home-assistant/home-assistant" "matter-js/matterjs-server|ghcr.io/matter-js/matterjs-server"; do
  repo="${pair%%|*}"; img="${pair##*|}"
  cur="$(docker compose -f "${HA_COMPOSE}" config --images 2>/dev/null | grep "^${img}:" | cut -d: -f2)"
  new="$(curl -s -m 15 -A "${UA}" "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name // empty' | sed 's/^v//')"
  [ -n "${cur}" ] && [ -n "${new}" ] && [ "${cur}" != "${new}" ] && NEWVERS+=("${img##*/} ${new} (actuel ${cur})")
done

# 5. Démons IA
if systemctl --user is-failed codex-remote-control.service >/dev/null 2>&1; then
  echo "[+] Réparation de Codex Remote Control..."
  rm -f "${HOME}/.codex/app-server-daemon"/*.pid "${HOME}/.codex/app-server-daemon"/*.lock
  systemctl --user restart codex-remote-control.service || ERRORS+=("codex-remote-control")
fi

# 6. Bilan
MSG=""
[ ${#UPDATED[@]} -gt 0 ] && MSG+="Mis à jour : ${UPDATED[*]}. "
[ ${#NEWVERS[@]} -gt 0 ] && MSG+="Nouvelle version disponible : $(IFS=,; echo "${NEWVERS[*]}" | sed 's/,/, /g'). "
[ -f /var/run/reboot-required ] && MSG+="Redémarrage requis. "
[ ${#ERRORS[@]} -gt 0 ] && MSG+="Erreurs : ${ERRORS[*]}."
echo "[i] ${MSG:-Rien à signaler.}"
[ -n "${MSG}" ] && notify "Maintenance AuBox" "${MSG}"
echo "=== Maintenance terminée [$(date '+%F %T')] ==="
[ ${#ERRORS[@]} -eq 0 ]
