#!/usr/bin/env bash
# ==============================================================================
# AuBox - Script de restauration depuis une sauvegarde Synology DS716+
# Usage : ./restore.sh [/chemin/vers/dossier_backup] [--yes]
# Défaut : /mnt/ds716/backup/aubox/latest
# ==============================================================================

set -euo pipefail

DEFAULT_BACKUP="/mnt/ds716/backup/aubox/latest"
SOURCE_DIR="${1:-$DEFAULT_BACKUP}"
AUTO_CONFIRM=false

if [[ "${SOURCE_DIR}" == "--yes" || "${SOURCE_DIR}" == "-y" ]]; then
  SOURCE_DIR="$DEFAULT_BACKUP"
  AUTO_CONFIRM=true
fi

if [[ "${2:-}" == "--yes" || "${2:-}" == "-y" ]]; then
  AUTO_CONFIRM=true
fi

# 1. Vérification du dossier de sauvegarde
if [ ! -d "${SOURCE_DIR}" ]; then
  echo "[-] ERREUR: Le dossier de sauvegarde '${SOURCE_DIR}' n'existe pas." >&2
  exit 1
fi

SOURCE_REAL_PATH=$(readlink -f "${SOURCE_DIR}")
echo "=== Restauration AuBox ==="
echo "Source : ${SOURCE_REAL_PATH}"

if [ -f "${SOURCE_REAL_PATH}/manifest.txt" ]; then
  echo "--- Détails du manifeste ---"
  cat "${SOURCE_REAL_PATH}/manifest.txt"
  echo "----------------------------"
fi

if [ "$AUTO_CONFIRM" != "true" ]; then
  read -p "Voulez-vous restaurer cette sauvegarde sur votre machine ? (o/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    echo "Restauration annulée."
    exit 0
  fi
fi

# 2. Restauration des clés, dotfiles et secrets d'authentification
if [ -f "${SOURCE_REAL_PATH}/credentials_dotfiles.tar.gz" ]; then
  echo "[+] 1/7 Restauration des clés SSH, Git, Bayard et Wrangler..."
  tar xzf "${SOURCE_REAL_PATH}/credentials_dotfiles.tar.gz" -C "/home/rafache"
  chmod 700 /home/rafache/.ssh 2>/dev/null || true
  chmod 600 /home/rafache/.ssh/id_* 2>/dev/null || true
  chmod 700 /home/rafache/.config/bayard 2>/dev/null || true
  chmod 600 /home/rafache/.config/bayard/.env 2>/dev/null || true
  chmod 700 /home/rafache/.config/freebox 2>/dev/null || true
  chmod 600 /home/rafache/.config/freebox/.env 2>/dev/null || true
  chmod -R go-rwx /home/rafache/.config/.wrangler 2>/dev/null || true
fi

# 3. Restauration des configurations systemd user
if [ -f "${SOURCE_REAL_PATH}/systemd_user.tar.gz" ]; then
  echo "[+] 2/7 Restauration des services systemd user..."
  mkdir -p "/home/rafache/.config"
  tar xzf "${SOURCE_REAL_PATH}/systemd_user.tar.gz" -C "/home/rafache/.config"
  loginctl enable-linger rafache 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
fi

# 4. Restauration des services permanents (~/services)
if [ -f "${SOURCE_REAL_PATH}/services.tar.gz" ]; then
  echo "[+] 3/7 Restauration du dossier ~/services..."
  tar xzf "${SOURCE_REAL_PATH}/services.tar.gz" -C "/home/rafache"
fi

# 5. Restauration des volumes Nginx Proxy Manager
if [ -f "${SOURCE_REAL_PATH}/npm_volumes.tar.gz" ]; then
  echo "[+] 4/7 Restauration des volumes Nginx Proxy Manager..."
  docker volume create aubox_proxy_data >/dev/null 2>&1 || true
  docker volume create aubox_proxy_letsencrypt >/dev/null 2>&1 || true
  docker run --rm \
    -v aubox_proxy_data:/data \
    -v aubox_proxy_letsencrypt:/etc/letsencrypt \
    -v "${SOURCE_REAL_PATH}:/backup:ro" \
    alpine sh -c "tar xzf /backup/npm_volumes.tar.gz -C /"
fi

# 6. Démarrage des stacks permanentes (Bases de données & Proxy)
echo "[+] 5/7 Démarrage des conteneurs databases et proxy..."
if [ -d "/home/rafache/services/databases" ]; then
  (cd /home/rafache/services/databases && docker compose up -d)
fi

if [ -d "/home/rafache/services/proxy" ]; then
  (cd /home/rafache/services/proxy && docker compose up -d)
fi

# 7. Restauration des bases de données
echo "[+] 6/7 Restauration des bases de données SQL..."

# Attente disponibilité PostgreSQL
if [ -f "${SOURCE_REAL_PATH}/postgres_all.sql.gz" ]; then
  echo "    - Attente de PostgreSQL..."
  for i in {1..30}; do
    if docker exec postgres pg_isready -U dev >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  echo "    - Injection du dump PostgreSQL..."
  gunzip -c "${SOURCE_REAL_PATH}/postgres_all.sql.gz" | docker exec -i postgres psql -U dev dev >/dev/null 2>&1 || true
fi

# Attente disponibilité MySQL
if [ -f "${SOURCE_REAL_PATH}/mysql_all.sql.gz" ]; then
  echo "    - Attente de MySQL..."
  if [ -f "/home/rafache/services/databases/.env" ]; then
    MYSQL_ROOT_PASSWORD=$(grep '^MYSQL_ROOT_PASSWORD=' /home/rafache/services/databases/.env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
    for i in {1..30}; do
      if docker exec mysql mysqladmin ping -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    echo "    - Injection du dump MySQL..."
    gunzip -c "${SOURCE_REAL_PATH}/mysql_all.sql.gz" | docker exec -i mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null || true
  fi
fi

# 8. Restauration des fichiers non versionnés des projets (.env, overrides)
if [ -f "${SOURCE_REAL_PATH}/projets_untracked.tar.gz" ]; then
  echo "[+] 7/7 Restauration des .env et compose.override.yml des projets..."
  tar xzf "${SOURCE_REAL_PATH}/projets_untracked.tar.gz" -C "/home/rafache" 2>/dev/null || true
fi

echo ""
echo "=== Restauration terminée avec succès ==="
echo "Vérifications recommandées :"
echo "  1. 'docker ps' pour constater l'état des services."
echo "  2. Si nouvelle machine, appliquez les configurations système conservées dans :"
echo "     ${SOURCE_REAL_PATH}/system/"
echo "     - sudo cp ${SOURCE_REAL_PATH}/system/50-rootless-ports.conf /etc/sysctl.d/ && sudo sysctl --system"
echo "     - sudo cp ${SOURCE_REAL_PATH}/system/wol.service /etc/systemd/system/ && sudo systemctl enable wol"
