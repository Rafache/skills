#!/usr/bin/env bash
# ==============================================================================
# AuBox - Sauvegarde des données et de la configuration vers le Synology (restic)
# Planifiée par cron : mercredi et dimanche à 23:45. Le NAS n'est jamais réveillé :
# s'il est éteint, une notification est envoyée sur l'iPhone via Home Assistant.
#
# Ce qui est sauvegardé (dépôt restic chiffré et dédupliqué) :
#   - tous les volumes Docker "aubox_*", sauf EXCLUDE_VOLUMES (backup.env) ;
#   - ~/services (compose, Dockerfile, code) ;
#   - secrets : ~/.ssh, ~/.gitconfig, ~/.config/{bayard,.wrangler,freebox} ;
#   - configuration de l'hôte : fstab, gai.conf, wol.service, crontab, paquets apt,
#     ~/.config/systemd/user, ~/.config/agents ;
#   - fichiers non versionnés des projets (.env*, compose.override.yml) ;
#   - exports des bases déclarées par les services (étiquettes ci-dessous).
#
# Conventions (rien à modifier ici quand on ajoute un service) :
#   - nommer ses volumes "aubox_<service>_data" ;
#   - étiquettes Docker optionnelles sur le conteneur du service :
#       aubox.backup.pre       commande exécutée dans le conteneur avant la sauvegarde
#                              (ex. copie cohérente d'une base SQLite dans son volume)
#       aubox.backup.exclude   motifs restic exclus, séparés par des virgules
#       aubox.backup.postgres  bases PostgreSQL du service à exporter, séparées par des virgules
#       aubox.backup.mysql     bases MySQL du service à exporter, séparées par des virgules
#
# Configuration : ~/.config/aubox/backup.env (RESTIC_PASSWORD, REPO_DIR, HA_WEBHOOK_URL, EXCLUDE_VOLUMES)
# ==============================================================================

set -euo pipefail

ENV_FILE="${AUBOX_BACKUP_ENV:-${HOME}/.config/aubox/backup.env}"
# shellcheck source=/dev/null
source "${ENV_FILE}"
REPO_DIR="${REPO_DIR_OVERRIDE:-${REPO_DIR}}"
RESTIC_IMAGE="restic/restic:0.18.1"
STAGING="$(mktemp -d)"

notify() {
  curl -s -m 10 -X POST -H 'Content-Type: application/json' \
    -d "$(jq -n --arg t "$1" --arg m "$2" '{title: $t, message: $m}')" \
    "${HA_WEBHOOK_URL}" >/dev/null || true
}
cleanup() { rm -rf "${STAGING}"; }
on_error() { notify "Sauvegarde AuBox échouée" "Erreur ligne $1. Journal : ~/.local/state/aubox-backup.log"; }
trap cleanup EXIT
trap 'on_error $LINENO' ERR

restic() {
  docker run --rm -i --hostname aubox \
    -e RESTIC_PASSWORD -e RESTIC_REPOSITORY=/repo \
    -v "${REPO_DIR}:/repo" "$@"
}
export RESTIC_PASSWORD

echo "=== Sauvegarde AuBox [$(date '+%F %T')] ==="

# 1. Le NAS doit déjà être allumé (pas de réveil). timeout évite un blocage NFS.
REPO_PARENT="$(dirname "${REPO_DIR}")"
nas_ok=false
for _ in 1 2 3; do  # le premier accès déclenche l'automontage NFS, qui peut prendre quelques secondes
  timeout 15 ls "${REPO_PARENT}" >/dev/null 2>&1 || true
  if timeout 15 test -w "${REPO_PARENT}"; then nas_ok=true; break; fi
  sleep 5
done
if ! ${nas_ok}; then
  echo "[-] ${REPO_PARENT} inaccessible : NAS éteint ou partage non monté. Sauvegarde non faite."
  notify "Sauvegarde AuBox non faite" "Le NAS est éteint ou le partage backup est inaccessible."
  exit 1
fi
mkdir -p "${REPO_DIR}"
if [ ! -f "${REPO_DIR}/config" ]; then
  echo "[+] Initialisation du dépôt restic..."
  restic "${RESTIC_IMAGE}" init
fi

# 2. Exports cohérents déclarés par les services
mkdir -p "${STAGING}/dumps" "${STAGING}/projets"
for c in $(docker ps --filter label=aubox.backup.pre --format '{{.Names}}'); do
  echo "[+] Export préalable : ${c}"
  docker exec "${c}" sh -c "$(docker inspect -f '{{index .Config.Labels "aubox.backup.pre"}}' "${c}")"
done
for c in $(docker ps --filter label=aubox.backup.postgres --format '{{.Names}}'); do
  for db in $(docker inspect -f '{{index .Config.Labels "aubox.backup.postgres"}}' "${c}" | tr ',' ' '); do
    echo "[+] Export PostgreSQL : ${db} (${c})"
    docker exec postgres pg_dump -U dev -Fc "${db}" > "${STAGING}/dumps/postgres_${db}.dump"
  done
done
for c in $(docker ps --filter label=aubox.backup.mysql --format '{{.Names}}'); do
  for db in $(docker inspect -f '{{index .Config.Labels "aubox.backup.mysql"}}' "${c}" | tr ',' ' '); do
    echo "[+] Export MySQL : ${db} (${c})"
    MYSQL_ROOT_PASSWORD=$(grep '^MYSQL_ROOT_PASSWORD=' "${HOME}/services/databases/.env" | cut -d '=' -f2- | tr -d "\"'")
    docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mysql mysqldump -uroot --single-transaction "${db}" | gzip > "${STAGING}/dumps/mysql_${db}.sql.gz"
  done
done

# 3. Fichiers non versionnés des projets
if [ -d "${HOME}/projets" ]; then
  (cd "${HOME}" && find projets -type f \( -name ".env*" -o -name "*compose.override.yml" \) -print0 2>/dev/null \
    | tar --null -T - -cf - 2>/dev/null) | tar -xf - -C "${STAGING}" || true
fi

# 4. Points de montage : volumes aubox_*, configuration et secrets
MOUNTS=()
for v in $(docker volume ls -q --filter name='^aubox_'); do
  case " ${EXCLUDE_VOLUMES} " in *" ${v} "*) continue ;; esac
  MOUNTS+=(-v "${v}:/data/volumes/${v}:ro")
done
MOUNTS+=(-v "${HOME}/services:/data/services:ro" -v "${STAGING}/dumps:/data/dumps:ro" -v "${STAGING}/projets:/data/projets:ro")
for p in .ssh .gitconfig .config/bayard .config/.wrangler .config/freebox; do
  [ -e "${HOME}/${p}" ] && MOUNTS+=(-v "${HOME}/${p}:/data/secrets/${p}:ro")
done
# Configuration de l'hôte (référence pour reconstruire la machine)
mkdir -p "${STAGING}/host"
crontab -l > "${STAGING}/host/crontab.txt" 2>/dev/null || true
dpkg --get-selections > "${STAGING}/host/packages_apt.list"
for f in /etc/fstab /etc/gai.conf /etc/systemd/system/wol.service; do
  [ -f "${f}" ] && cp -p "${f}" "${STAGING}/host/"
done
MOUNTS+=(-v "${STAGING}/host:/data/host:ro")
for p in .config/systemd/user .config/agents; do
  [ -d "${HOME}/${p}" ] && MOUNTS+=(-v "${HOME}/${p}:/data/host_home/${p}:ro")
done

EXCLUDES=()
for c in $(docker ps --filter label=aubox.backup.exclude --format '{{.Names}}'); do
  for pat in $(docker inspect -f '{{index .Config.Labels "aubox.backup.exclude"}}' "${c}" | tr ',' ' '); do
    EXCLUDES+=(--exclude "${pat}")
  done
done

# 5. Sauvegarde, rétention, vérification mensuelle
echo "[+] Sauvegarde restic..."
restic "${MOUNTS[@]}" "${RESTIC_IMAGE}" backup /data --tag auto "${EXCLUDES[@]}"
echo "[+] Rétention (4 dernières, 8 semaines, 6 mois)..."
restic "${RESTIC_IMAGE}" forget --tag auto --keep-last 4 --keep-weekly 8 --keep-monthly 6 --prune
if [ "$(date +%d)" -le 07 ] && [ "$(date +%u)" -eq 7 ]; then
  echo "[+] Vérification mensuelle du dépôt..."
  restic "${RESTIC_IMAGE}" check --read-data-subset=10%
fi

date -Is > "${HOME}/.local/state/aubox-backup.last-success"  # lu par aubox-health
echo "=== Sauvegarde terminée [$(date '+%F %T')] ==="
restic "${RESTIC_IMAGE}" snapshots --latest 1 --compact
