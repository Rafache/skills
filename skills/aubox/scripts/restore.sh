#!/usr/bin/env bash
# ==============================================================================
# AuBox - Restauration depuis le dépôt restic du Synology
# Usage : aubox-restore [snapshot]      (défaut : latest)
#
# Prérequis sur une machine neuve : Docker, partage NAS monté, et
# ~/.config/aubox/backup.env recréé avec le RESTIC_PASSWORD conservé hors serveur.
#
# Étapes : extraction de l'instantané, puis restauration des volumes aubox_*
# (seulement s'ils sont absents ou vides), de ~/services, des secrets et des
# fichiers non versionnés des projets. Les conteneurs ne sont pas démarrés :
# relancer chaque stack avec `docker compose up -d` dans ~/services/<stack>.
# ==============================================================================

set -euo pipefail

ENV_FILE="${AUBOX_BACKUP_ENV:-${HOME}/.config/aubox/backup.env}"
# shellcheck source=/dev/null
source "${ENV_FILE}"
REPO_DIR="${REPO_DIR_OVERRIDE:-${REPO_DIR}}"
SNAPSHOT="${1:-latest}"
RESTIC_IMAGE="restic/restic:0.18.1"
WORK="${HOME}/aubox-restore-$(date +%Y%m%d_%H%M%S)"
export RESTIC_PASSWORD

echo "=== Restauration AuBox (instantané : ${SNAPSHOT}) ==="
mkdir -p "${WORK}"
docker run --rm -e RESTIC_PASSWORD -e RESTIC_REPOSITORY=/repo \
  -v "${REPO_DIR}:/repo:ro" -v "${WORK}:/restore" \
  "${RESTIC_IMAGE}" restore "${SNAPSHOT}" --no-lock --target /restore
D="${WORK}/data"
# Fichiers extraits par root : rendre à l'utilisateur ce qui va dans le home
docker run --rm -v "${WORK}:/w" alpine sh -c \
  "for d in services secrets projets dumps host host_home; do [ -e /w/data/\$d ] && chown -R $(id -u):$(id -g) /w/data/\$d; done; true"

# 1. Volumes Docker (jamais écrasés s'ils contiennent déjà des données)
for src in "${D}"/volumes/*/; do
  v="$(basename "${src}")"
  docker volume create "${v}" >/dev/null
  if [ -n "$(docker run --rm -v "${v}:/v" alpine ls -A /v)" ]; then
    echo "[!] ${v} n'est pas vide : ignoré (le vider manuellement pour le restaurer)."
    continue
  fi
  echo "[+] Volume ${v}"
  docker run --rm -v "${v}:/v" -v "${src}:/src:ro" alpine cp -a /src/. /v/
done

# Home Assistant : la copie cohérente de l'historique redevient la base active
if docker run --rm -v aubox_homeassistant_data:/c alpine test -f /c/.aubox-backup-history.db 2>/dev/null; then
  docker run --rm -v aubox_homeassistant_data:/c alpine sh -c \
    '[ -f /c/home-assistant_v2.db ] || cp -a /c/.aubox-backup-history.db /c/home-assistant_v2.db'
fi

# 2. Configuration, secrets et fichiers non versionnés (sans écraser l'existant)
echo "[+] ~/services, secrets et fichiers des projets..."
cp -an "${D}/services" "${HOME}/" 2>/dev/null || true
[ -d "${D}/secrets" ] && cp -an "${D}/secrets/." "${HOME}/"
[ -d "${D}/projets" ] && cp -an "${D}/projets/." "${HOME}/"

# 3. Exports de bases : import manuel, selon le service concerné
if [ -n "$(ls -A "${D}/dumps" 2>/dev/null)" ]; then
  echo "[i] Exports de bases disponibles dans ${D}/dumps :"
  ls -1 "${D}/dumps"
  echo "    PostgreSQL : docker exec -i postgres pg_restore -U dev -C -d postgres < <fichier>.dump"
  echo "    MySQL      : gunzip -c <fichier>.sql.gz | docker exec -i mysql mysql -uroot -p<mdp> <base>"
fi

if [ -d "${D}/host" ]; then
  echo "[i] Configuration de l'hôte (fstab, crontab, unités systemd, paquets apt, ~/.config/agents) :"
  echo "    ${D}/host et ${D}/host_home : à réappliquer manuellement selon le besoin."
fi

echo "=== Terminé. Fichiers extraits : ${WORK} (à supprimer après vérification) ==="
echo "Démarrer ensuite les stacks : cd ~/services/<stack> && docker compose up -d"
