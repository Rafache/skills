#!/usr/bin/env bash
# ==============================================================================
# AuBox - Script de sauvegarde automatique vers Synology DS716+
# Cible : /mnt/ds716/backup/aubox/<TIMESTAMP>/
# ==============================================================================

set -euo pipefail

BACKUP_ROOT="/mnt/ds716/backup/aubox"
RETENTION_COUNT=8
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

echo "=== Début de la sauvegarde AuBox [${TIMESTAMP}] ==="

# 1. Vérification de l'accessibilité du NAS et réveil automatique Wake-on-LAN via Freebox si nécessaire
SYNOLOGY_IP="192.168.1.20"
SYNOLOGY_MAC="00:11:32:55:14:08"

ls "/mnt/ds716/backup" >/dev/null 2>&1 || true

if [ ! -d "/mnt/ds716/backup" ] || [ ! -w "/mnt/ds716/backup" ]; then
  echo "[*] Le NAS Synology semble endormi ou injoignable. Tentative de réveil Wake-on-LAN via Freebox..."
  if command -v freebox >/dev/null 2>&1; then
    freebox wol "${SYNOLOGY_MAC}" || true
  fi
  echo "    Attente du démarrage du NAS (jusqu'à 45s)..."
  for i in {1..45}; do
    if ping -c 1 -W 1 "${SYNOLOGY_IP}" >/dev/null 2>&1; then
      ls "/mnt/ds716/backup" >/dev/null 2>&1 || true
      if [ -w "/mnt/ds716/backup" ]; then
        echo "[+] NAS réveillé et partage NFS accessible !"
        break
      fi
    fi
    sleep 1
  done
fi

if [ ! -d "/mnt/ds716/backup" ] || [ ! -w "/mnt/ds716/backup" ]; then
  echo "[-] ERREUR: Le partage /mnt/ds716/backup n'est pas accessible en écriture." >&2
  echo "    Vérifiez que le NAS Synology est allumé et joignable sur le réseau." >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}/system"

# 2. Bases de données (Exports logiques à chaud)
echo "[+] 1/6 Export des bases de données..."

# PostgreSQL
if docker ps --format '{{.Names}}' | grep -q '^postgres$'; then
  echo "    - Dump PostgreSQL (toutes les bases)..."
  docker exec postgres pg_dumpall -U dev | gzip > "${BACKUP_DIR}/postgres_all.sql.gz"
fi

# MySQL
if docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
  echo "    - Dump MySQL (toutes les bases)..."
  if [ -f "/home/rafache/services/databases/.env" ]; then
    MYSQL_ROOT_PASSWORD=$(grep '^MYSQL_ROOT_PASSWORD=' /home/rafache/services/databases/.env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
    docker exec mysql mysqldump -uroot -p"${MYSQL_ROOT_PASSWORD}" --all-databases --single-transaction 2>/dev/null | gzip > "${BACKUP_DIR}/mysql_all.sql.gz"
  fi
fi

# Redis (Snapshot persistant)
if docker ps --format '{{.Names}}' | grep -q '^redis$'; then
  echo "    - Sauvegarde Redis..."
  if [ -f "/home/rafache/services/databases/.env" ]; then
    REDIS_PASSWORD=$(grep '^REDIS_PASSWORD=' /home/rafache/services/databases/.env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
    docker exec redis redis-cli -a "${REDIS_PASSWORD}" BGSAVE 2>/dev/null || true
  fi
fi

# 3. Nginx Proxy Manager (Base de données SQLite et certificats SSL)
echo "[+] 2/6 Sauvegarde des volumes Nginx Proxy Manager..."
if docker volume inspect aubox_proxy_data >/dev/null 2>&1; then
  docker run --rm \
    -v aubox_proxy_data:/data:ro \
    -v aubox_proxy_letsencrypt:/etc/letsencrypt:ro \
    -v "${BACKUP_DIR}:/backup" \
    alpine tar czf /backup/npm_volumes.tar.gz -C / data etc/letsencrypt
fi

# 4. Services permanents (~/services)
echo "[+] 3/6 Sauvegarde des définitions de services permanents..."
if [ -d "/home/rafache/services" ]; then
  tar czf "${BACKUP_DIR}/services.tar.gz" -C "/home/rafache" services
fi

# 5. Fichiers non versionnés des projets (.env, overrides)
echo "[+] 4/6 Sauvegarde des configurations locales des projets..."
if [ -d "/home/rafache/projets" ]; then
  (
    cd /home/rafache
    find projets -type f \( -name ".env*" -o -name "*compose.override.yml" \) 2>/dev/null | \
      tar czf "${BACKUP_DIR}/projets_untracked.tar.gz" -T -
  )
fi

# 6. Configurations systemd utilisateur & système
echo "[+] 5/6 Sauvegarde des configurations systemd..."
if [ -d "/home/rafache/.config/systemd/user" ]; then
  tar czf "${BACKUP_DIR}/systemd_user.tar.gz" -C "/home/rafache/.config" systemd/user
fi

# Fichiers système hôte
[ -f "/etc/systemd/system/wol.service" ] && cp -p "/etc/systemd/system/wol.service" "${BACKUP_DIR}/system/"
[ -f "/etc/sysctl.d/50-rootless-ports.conf" ] && cp -p "/etc/sysctl.d/50-rootless-ports.conf" "${BACKUP_DIR}/system/"
[ -f "/etc/fstab" ] && cp -p "/etc/fstab" "${BACKUP_DIR}/system/"
dpkg --get-selections > "${BACKUP_DIR}/system/packages_apt.list"

# 7. Clés SSH, identité Git et secrets CLI (~/.config/bayard, ~/.config/.wrangler, ~/.config/freebox)
echo "[+] 6/6 Sauvegarde des clés SSH, Git et configurations d'authentification..."
tar czf "${BACKUP_DIR}/credentials_dotfiles.tar.gz" \
  -C "/home/rafache" \
  .ssh \
  .gitconfig \
  .config/bayard \
  .config/.wrangler \
  .config/freebox 2>/dev/null || true

# Manifeste de sauvegarde
cat << MANIFEST > "${BACKUP_DIR}/manifest.txt"
Date: $(date -R)
Host: $(hostname)
Kernel: $(uname -r)
Debian: $(cat /etc/debian_version 2>/dev/null || echo "inconnu")
User: $(whoami)
Conteneurs actifs lors du backup:
$(docker ps --format '- {{.Names}} ({{.Image}})' 2>/dev/null || true)
MANIFEST

# Mise à jour du lien symbolique 'latest'
ln -sfn "${TIMESTAMP}" "${BACKUP_ROOT}/latest"

# 8. Rotation des anciennes sauvegardes (conserve les RETENTION_COUNT plus récentes)
echo "[+] Rotation des sauvegardes (conservation des ${RETENTION_COUNT} dernières)..."
OLD_BACKUPS=$(ls -dt "${BACKUP_ROOT}"/20* 2>/dev/null | tail -n +$((RETENTION_COUNT + 1)) || true)
if [ -n "${OLD_BACKUPS}" ]; then
  echo "${OLD_BACKUPS}" | while read -r old_backup; do
    echo "    - Suppression ancienne sauvegarde : $(basename "${old_backup}")"
    rm -r "${old_backup}"
  done
fi

BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
echo "=== Sauvegarde terminée avec succès ==="
echo "Emplacement : ${BACKUP_DIR}"
echo "Taille totale : ${BACKUP_SIZE}"
echo "Lien 'latest' : ${BACKUP_ROOT}/latest"
