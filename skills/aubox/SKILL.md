---
name: aubox
description: Règles d'administration et configuration système d'AuBox (Docker, réseau hôte/NPM, stockage NAS, sauvegardes et runtimes).
---

# AuBox — Fiche Technique & Règles Système

## 1. Identité & Matériel
- **Hôte** : Mini PC CHUWI AuBox, Debian 13 (Trixie) amd64, kernel 6.12, 100% headless.
- **Hardware** : AMD Ryzen 7 8745HS (8C/16T), Radeon 780M (VA-API : `radeonsi_drv_video.so`), 16 Go DDR5, SSD NVMe 512 Go sur `/`.
- **Utilisateur** : `rafache` (sudo, groupe `docker`).
- **Réseau** :
  - LAN hôte : `192.168.1.10` (`eno1`, 2.5 Gb/s, WoL actif). Priorité IPv4 système dans `/etc/gai.conf`.
  - VPN : WireGuard Freebox (accès distant au LAN) et Fortinet Bayard (`bayard-vpn`).
  - Synology DS716+ (`192.168.1.20`) : Montages NFSv4 automount systemd sur `/mnt/ds716/{video,music,backup}`. Réveil WoL via CLI `freebox wol 00:11:32:55:14:08`.
  - Après l’envoi du WoL, le Synology met environ **1 minute** à démarrer. Attendre ce délai avant de conclure qu’il est inaccessible ; vérifier ensuite la disponibilité réseau et les montages NFS.

## 2. Cartographie des chemins
- `~/projets/` : Code source (`bayard/` pro, `perso/` personnel).
- `~/services/` : Stacks Docker permanentes (`databases/` : PG 18, MySQL 8.4, Redis 8 ; `proxy/` : Nginx Proxy Manager ; `browser/` : Chrome WebRTC n.eko + CDP 9222).
- `~/.config/agents/` : Dépôt central Git des agents et skills (`skills/` synchronisés via `scripts/sync.sh`).
- Secrets hôte (`chmod 600`) : `~/.config/bayard/.env`, `~/.config/freebox/.env`, `~/.config/.wrangler/`.

## 3. Règles Docker
- **Bridge réseau** : Tout conteneur doit être rattaché au réseau externe `aubox`. Résolution interne par nom de service (`postgres`, `mysql`, `redis`).
- **Liaison des ports** : Toujours binder sur l'IP LAN `192.168.1.10:PORT:PORT` ou `127.0.0.1`, **jamais `0.0.0.0`**.
- **Stockage bases** : Exclusivement sur le NVMe local via volumes nommés (`aubox_*_data`). Le NAS sert uniquement aux dumps et backups froids.
- **Politique `restart`** :
  - `~/services/` (stacks permanentes) : `restart: unless-stopped`.
  - `~/projets/` (développement) : `restart: "no"`. Ne jamais committer de modification sur les `docker-compose.yml` des projets ; utiliser `compose.override.yml`.
- **Nginx Proxy Manager** (ports 80, 443, 81 sur `192.168.1.10`) :
  - Wildcards DNS Cloudflare : `*.aubox.chem1.fr` et `*.prions.aubox.chem1.fr`.
  - Vite HMR : spécifier `server.hmr.clientPort: 443`.

## 4. Outils & Runtimes Hôte
- **Node / npm / npx** : Gérés par NVM (`~/.nvm/current/bin`). Ne jamais installer Node via apt.
- **Python** : Géré par `uv` et `uvx` (`~/.local/bin/`).
- **Git & Forges** : `gh` authentifié (`Rafache`), `glab` authentifié sur `gitlab.bayard.io` (`rchemin`).
- **Cloudflare & Google** : `wrangler` (global npm), `gws` (`alfraid2029@gmail.com`).
- **Multimédia** : `ffmpeg`/`ffprobe` avec VA-API hardware, `aria2c` pour téléchargements multi-sources.
- **Navigateur permanent & Sessions (Chrome WebRTC n.eko & CDP)** :
  - Conteneur permanent sous `~/services/browser/` (`aubox-browser` basé sur n.eko Google Chrome officiel) avec affichage fenêtré X11, streaming WebRTC 60 fps avec son et accélération matérielle Radeon 780M (`/dev/dri`).
  - Piloté par les agents via `chrome-devtools-mcp` connecté au CDP local (`http://127.0.0.1:9222`).
  - Accessible aux utilisateurs via l'interface Web HTTPS `https://browser.aubox.chem1.fr` (NPM, port 6901, WebSockets + WebRTC UDP 52000).
  - Profil persistant sur volume local `aubox_browser_data` : cookies, sessions, compte Google et tokens partagés en continu entre l'agent et l'humain (contournement natif des anti-bots).
- **Maintenance & Sauvegarde** (scripts sous `scripts/`, exposés dans le `PATH`) :
  - `aubox-maintenance` : màj apt, docker prune, npm update, relance démons IA.
  - `aubox-backup` : dumps chauds BDD, volumes NPM, configs vers Synology (rotation 8).
  - `aubox-restore [<dir>]` : restauration complète depuis le NAS (`latest` par défaut).

## 5. Garde-fous & Commandes Interdites
- ❌ **Docker destructif** : Ne jamais exécuter `docker compose down -v`, `docker volume rm` ou `docker system prune --volumes`.
- ❌ **Suppression brutale** : Pas de `rm -rf` sur `~/projets`, `~/services` ou les volumes sans confirmation.
- ❌ **Exposition publique** : Aucun port sensible ou BDD sur `0.0.0.0`.
- ❌ **Git destructif** : Pas de `reset --hard`, `clean -fd` ou `push --force` sur les branches principales.
- ❌ **Fuite de secrets** : Ne jamais afficher en clair ni committer de `.env`, tokens ou clés SSH.
