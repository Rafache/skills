#!/usr/bin/env bash
# ==============================================================================
# AuBox - Contrôle de santé quotidien (cron : 09:00), lançable à la main.
# Silencieux si tout va bien ; sinon une seule notification iPhone (ntfy) listant :
#   - conteneur d'une stack ~/services arrêté ou unhealthy ;
#   - disque / au-delà de 85 % ;
#   - unité systemd en échec (système ou utilisateur) ;
#   - dernière sauvegarde réussie de plus de 5 jours.
# Limite : si l'AuBox elle-même est hors service, rien ne part (il faudrait un veilleur externe).
# ==============================================================================

set -uo pipefail

ENV_FILE="${AUBOX_BACKUP_ENV:-${HOME}/.config/aubox/backup.env}"
# shellcheck source=/dev/null
[ -f "${ENV_FILE}" ] && source "${ENV_FILE}"
# shellcheck source=lib-notify.sh
source "$(dirname "$(readlink -f "$0")")/lib-notify.sh"
LAST_BACKUP="${HOME}/.local/state/aubox-backup.last-success"
PROBLEMS=()

# 1. Conteneurs des stacks permanentes
for f in "${HOME}"/services/*/compose.yaml; do
  while read -r name state health; do
    [ -z "${name}" ] && continue
    if [ "${state}" != "running" ] || [ "${health}" = "unhealthy" ]; then
      PROBLEMS+=("${name} : ${state}${health:+ (${health})}")
    fi
  done < <(docker compose -f "${f}" ps -a --format '{{.Name}} {{.State}} {{.Health}}' 2>/dev/null)
done

# 2. Disque
use="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"
[ "${use}" -gt 85 ] && PROBLEMS+=("disque / à ${use} %")

# 3. Unités systemd en échec
failed="$( (systemctl --failed --no-legend --plain; systemctl --user --failed --no-legend --plain) 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
[ -n "${failed// /}" ] && PROBLEMS+=("unités en échec : ${failed}")

# 4. Fraîcheur de la sauvegarde
if [ ! -f "${LAST_BACKUP}" ]; then
  PROBLEMS+=("aucune sauvegarde réussie enregistrée")
elif [ -n "$(find "${LAST_BACKUP}" -mtime +5)" ]; then
  PROBLEMS+=("dernière sauvegarde réussie : $(cut -c1-10 "${LAST_BACKUP}")")
fi

# Bilan
if [ ${#PROBLEMS[@]} -eq 0 ]; then
  echo "$(date '+%F %T') OK"
  exit 0
fi
MSG="$(printf '%s ; ' "${PROBLEMS[@]}")"
echo "$(date '+%F %T') PROBLÈMES : ${MSG}"
aubox_notify "Santé AuBox" "${MSG%; }" 4
exit 1
