---
name: aubox
description: Règles d'administration et configuration système d'AuBox (Docker, réseau hôte/NPM, stockage NAS, runtimes). À utiliser pour toute intervention sur l'AuBox ou ses services (~/services, Home Assistant, Matter, proxy, AdGuard, bases) - ajout ou mise à jour d'un service, sauvegarde, restauration, maintenance, mises à jour, santé, notifications, ménage Docker.
---

# AuBox — Fiche Technique & Règles Système

## 1. Identité & Matériel
- **Hôte** : Mini PC CHUWI AuBox, Debian 13 (Trixie) amd64, kernel 6.12, 100% headless.
- **Hardware** : AMD Ryzen 7 8745HS (8C/16T), Radeon 780M (VA-API : `radeonsi_drv_video.so`), 32 Go DDR5, SSD NVMe 512 Go sur `/`.
- **Utilisateur** : `rafache` (sudo, groupe `docker`).
- **Réseau** :
  - LAN hôte : `192.168.1.10` (`eno1`, 2.5 Gb/s, WoL actif). Priorité IPv4 système dans `/etc/gai.conf`.
  - VPN : WireGuard Freebox (accès distant au LAN) et Fortinet Bayard (`bayard-vpn`).
  - Synology DS716+ (`192.168.1.20`) : Montages NFSv4 automount systemd sur `/mnt/ds716/{video,music,backup}`. Réveil WoL via CLI `freebox wol 00:11:32:55:14:08` (skill `freebox`).
  - Après l’envoi du WoL, le Synology met environ **1 minute** à démarrer. Attendre ce délai avant de conclure qu’il est inaccessible ; vérifier ensuite la disponibilité réseau et les montages NFS.

## 2. Cartographie des chemins
- `~/projets/` : Code source (`bayard/` pro, `perso/` personnel).
- `~/services/` : Stacks Docker permanentes (`databases/` : PG 18, MySQL 8.4, Redis 8 ; `proxy/` : Nginx Proxy Manager ; `browser/` : Chrome WebRTC n.eko + CDP 9222 ; `homeassistant/` : Home Assistant + matterjs-server, réseau hôte ; `adguard/` : DNS AdGuard Home). Un fichier `compose.yaml` par stack.
- `~/.config/agents/` : Dépôt central Git des agents et skills (`skills/` synchronisés via `scripts/sync.sh`).
- Secrets hôte (`chmod 600`) : `~/.config/bayard/.env`, `~/.config/freebox/.env`, `~/.config/.wrangler/`, `~/.config/aubox/backup.env` (mot de passe restic, webhook HA). Secrets des stacks dans le `.env` de chaque stack, jamais en clair dans `compose.yaml`.

## 3. Règles Docker
- **Bridge réseau** : Tout conteneur doit être rattaché au réseau externe `aubox`. Résolution interne par nom de service (`postgres`, `mysql`, `redis`). Exception : `homeassistant` et `matter-server` en `network_mode: host` (mDNS, Matter/Thread).
- **Versions d'images** : services critiques figés sur un tag précis (Home Assistant, matterjs-server) et mis à jour en changeant le tag ; les autres suivent `latest`/majeure et sont mis à jour par `aubox-maintenance`.
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
  - Planification (crontab de `rafache`) : `aubox-backup` mercredi et dimanche 23:45 ; `aubox-health` tous les jours 09:00 ; `aubox-maintenance` 1er dimanche du mois 04:00. Journaux : `~/.local/state/aubox-*.log`. Notifications iPhone via le webhook HA de `backup.env` (si HA est en panne, rien ne part).
  - apt : automatique chaque jour via `unattended-upgrades` (Debian, sécurité et dépôts tiers Docker, gh, Google Cloud SDK, config `/etc/apt/apt.conf.d/52aubox-unattended`) ; redémarrage automatique à 04:30 uniquement si un noyau ou une bibliothèque l'exige ; retrait automatique des dépendances inutiles et des anciens noyaux.
  - Mises à jour des outils : apt (ci-dessus) ; npm global, uv, codex, agy, twg par `aubox-maintenance` ; claude et tessl se mettent aussi à jour seuls. Node (NVM) : manuel.
  - `aubox-maintenance` : met à jour les images non figées de chaque stack `~/services` (ne recrée que ce qui a changé), ménage Docker (images sans conteneur et cache de build > 30 j, volumes orphelins sans nom ; jamais les volumes nommés), CLI (npm global, uv, codex, agy, twg), démons IA ; signale une nouvelle version de Home Assistant ou matterjs-server (figés : mise à jour manuelle en changeant le tag). apt complet uniquement en lancement manuel. Notifie si mise à jour, nouvelle version, redémarrage requis ou erreur.
  - `aubox-health` : silencieux si tout va bien ; notifie si un conteneur de `~/services` est arrêté/unhealthy, disque > 85 %, unité systemd en échec, ou dernière sauvegarde réussie > 5 jours.
  - `aubox-backup` : sauvegarde restic (chiffrée, dédupliquée) vers `/mnt/ds716/backup/aubox-restic`. Cron mercredi et dimanche 23:45 ; ne réveille pas le NAS, notifie l'iPhone via un webhook HA en cas d'échec. Journal : `~/.local/state/aubox-backup.log`. Config et mot de passe : `~/.config/aubox/backup.env`.
    - Sauvegarde automatiquement tout volume `aubox_*` (sauf `EXCLUDE_VOLUMES`), `~/services`, les secrets et les `.env`/overrides des projets.
    - Nouveau service : nommer ses volumes `aubox_<service>_data` ; étiquettes optionnelles `aubox.backup.pre` (export cohérent), `aubox.backup.exclude`, `aubox.backup.postgres` / `aubox.backup.mysql` (bases du service à exporter). Les bases des projets ne sont pas sauvegardées.
  - `aubox-restore [<snapshot>]` : restauration depuis le dépôt restic (`latest` par défaut), sans écraser les volumes non vides.

## 5. Référence de l'installation propre
- [references/baseline.md](references/baseline.md) liste ce qui doit être installé (paquets apt, outils hors apt, stacks, services, cron, config système) avec le rôle de chaque élément, et ce qui est volontairement absent.
- Toute installation ou suppression durable doit y être reportée. Pour un ménage, comparer l'état réel à cette liste.

## 6. Garde-fous & Commandes Interdites
- ❌ **Docker destructif** : Ne jamais exécuter `docker compose down -v`, `docker system prune --volumes` ni `docker volume rm` sur un volume nommé sans confirmation. Seule exception automatique : `aubox-maintenance` supprime les volumes orphelins sans nom.
- ❌ **Suppression brutale** : Pas de `rm -rf` sur `~/projets`, `~/services` ou les volumes sans confirmation.
- ❌ **Exposition publique** : Aucun port sensible ou BDD sur `0.0.0.0`.
- ❌ **Git destructif** : Pas de `reset --hard`, `clean -fd` ou `push --force` sur les branches principales.
- ❌ **Fuite de secrets** : Ne jamais afficher en clair ni committer de `.env`, tokens ou clés SSH.
