#!/bin/bash
set -e

sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean

docker system prune -f

# Mise à jour des packages globaux npm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
npm update -g

# Santé des démons IA & Services
if systemctl --user is-failed codex-remote-control.service >/dev/null 2>&1; then
    echo "Réparation de Codex Remote Control..."
    rm -f "$HOME/.codex/app-server-daemon"/*.pid "$HOME/.codex/app-server-daemon"/*.lock
    systemctl --user restart codex-remote-control.service
fi

if systemctl --user is-failed agy-remote-control.service >/dev/null 2>&1; then
    echo "Relance d'Antigravity Remote Control..."
    systemctl --user restart agy-remote-control.service
fi

docker compose -f "$HOME/services/databases/compose.yaml" up -d --remove-orphans >/dev/null 2>&1
docker compose -f "$HOME/services/proxy/compose.yaml" up -d --remove-orphans >/dev/null 2>&1

echo "Maintenance terminée : $(date)"
