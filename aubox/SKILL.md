---
name: aubox
description: Référence technique, opérationnelle et garde-fous de la devbox headless AuBox (architecture, Docker rootless, Tailscale, outils, stockage NVMe/NFS, bonnes pratiques et commandes sans rescannage).
---

# AuBox — Guide Opérationnel & Bonnes Pratiques

Ce skill centralise l'architecture, la configuration réelle, la boîte à outils et les garde-fous de l'AuBox.
**Consulte ce document avant toute intervention système ou configuration afin d'éviter les scans inutiles, les réinstallations d'outils déjà présents et les erreurs destructrices.**

---

## 1. Fiche d'identité rapide

- **Machine** : Mini PC CHUWI AuBox
- **CPU** : AMD Ryzen 7 8745HS (8 cœurs / 16 threads)
- **GPU** : AMD Radeon 780M (accélération VA-API headless)
- **RAM** : 16 Go DDR5 (~12 Go alloués au système, reste réservé VRAM)
- **Stockage hôte** : SSD NVMe 512 Go (`/dev/nvme0n1p2` sur `/`)
- **OS** : Debian GNU/Linux 13 (Trixie) amd64, kernel 6.12, 100% headless (pas d'environnement de bureau)
- **Utilisateur principal** : `rafache` (avec privilèges sudo)
- **Réseau** :
  - Interface Ethernet principale : `eno1` (2,5 Gb/s), IP LAN DHCP réservée Freebox (`192.168.1.10`)
  - Interface 2,5 GbE secondaire : `enp3s0` (inactive par défaut)
  - VPN & Accès distant : VPN Freebox (WireGuard / OpenVPN) pour joindre le LAN en déplacement
  - Wake-on-LAN : Actif sur `eno1` via `wol.service` (MAC : `84:47:09:76:d9:3f`), réveillable depuis Freebox OS
  - Résolution locale : `aubox.local` via `avahi-daemon`
- **NAS Synology DS716+** :
  - IP LAN : `192.168.1.20` (MAC : `00:11:32:55:14:08`, Wake-on-LAN supporté)
  - Montages NFSv4 automount systemd (fstab `_netdev,nofail,x-systemd.automount`) :
    - `/mnt/ds716/video` -> `/volume1/video`
    - `/mnt/ds716/music` -> `/volume1/music`
    - `/mnt/ds716/backup` -> `/volume1/backup`
  - *Règle* : Le montage s'effectue automatiquement au premier accès (`ls /mnt/ds716/...`).

---

## 2. Cartographie des répertoires

```text
/home/rafache/
├── projets/           # Code source des projets
│   ├── bayard/        # Projets professionnels Bayard
│   └── perso/         # Projets personnels
├── services/          # Services Docker permanents
│   └── databases/     # Stack PostgreSQL, MySQL, Redis
├── scripts/           # Scripts d'administration hôte (ex: maintenance.sh)
├── skills/            # Compétences IA partagées (dépôt Git GitHub)
├── agents/            # Configurations d'agents spécialisés (ex: devbox)
├── .codex/            # Configuration et règles Codex CLI
├── .gemini/           # Configuration Antigravity (AGY)
├── .claude/           # Configuration Claude Code
├── .docker/           # Config client Docker rootless
├── .nvm/              # Versions Node.js gérées par NVM
└── .local/bin/        # Outils CLI locaux (uv, uvx, codex, agy)
```

> **Symlinks IA unifiés** :
> - `~/.codex/skills` -> `/home/rafache/skills`
> - `~/.gemini/config/skills` -> `/home/rafache/skills`
> - `~/.gemini/config/agents` -> `/home/rafache/agents`
>
> Tout skill ajouté dans `~/skills/` ou agent dans `~/agents/` est immédiatement accessible pour tous les agents.

---

## 3. Docker Rootless & Bases de Données

### Configuration Docker
- Docker tourne en **rootless** complet sous l'utilisateur `rafache` (linger systemd activé).
- Socket Docker : `/run/user/1000/docker.sock`
- Variable d'environnement à toujours utiliser :
  ```bash
  export DOCKER_HOST=unix:///run/user/1000/docker.sock
  ```
- Réseau Docker partagé : **`aubox`** (bridge externe).
  ```bash
  docker network ls  # vérifier la présence du réseau 'aubox'
  ```

### Stack permanente : `~/services/databases/`
Contient le `compose.yaml` des 3 bases de données principales :
- **PostgreSQL 18** (`postgres:18`)
- **MySQL 8.4** (`mysql:8.4`)
- **Redis 8** (`redis:8-alpine`) avec persistance AOF et mot de passe

### Règles de sécurité Docker & Ports
1. **Liaison IP stricte** :
   - Les ports des bases ne sont **JAMAIS** bindés sur `0.0.0.0` (accessible sur tous les réseaux).
   - Ils sont liés à l'IP LAN locale **`192.168.1.10`** (`192.168.1.10:5432`, `192.168.1.10:3306`, `192.168.1.10:6379`), ce qui permet d'y accéder depuis le réseau local ou à distance en se connectant au VPN Freebox.
2. **Communication inter-conteneurs** :
   - Toujours brancher les nouveaux conteneurs sur le réseau externe `aubox`.
   - Utiliser les alias réseau directs : `DB_HOST=postgres`, `DB_HOST=mysql`, `REDIS_HOST=redis`.
3. **Persistance des données** :
   - Les données des bases restent **exclusivement sur le NVMe local** via les volumes nommés (`aubox_postgres_data`, `aubox_mysql_data`, `aubox_redis_data`).
   - Le NAS `/mnt/ds716/backup` sert uniquement aux dumps et sauvegardes froides, jamais au stockage direct des moteurs de base de données.
4. **Politique de redémarrage (`restart`)** :
   - **Services permanents** (`~/services/`) : `restart: unless-stopped` (redémarrent au boot de l'hôte).
   - **Projets de développement** (`~/projets/`) : **`restart: "no"`** (ne doivent **JAMAIS** démarrer automatiquement au boot).
   - *Bonne pratique Git* : Ne jamais modifier les `docker-compose.yml` versionnés des dépôts de code ; appliquer systématiquement les surcharges locales via un fichier **`docker-compose.override.yml`** (ou `compose.override.yml`).

---

## 4. Outils & Écosystèmes Disponibles

Avant d'installer un binaire ou une dépendance, vérifier la boîte à outils existante :

| Outil | Emplacement / Commande | Remarques d'utilisation |
|---|---|---|
| **Node / npm / npx** | `~/.nvm/current/bin/` (Node v24+) | **Ne jamais installer Node via apt**. NVM gère le runtime. |
| **Python / uv / uvx** | `~/.local/bin/uv`, `uvx` | Utiliser `uv` pour les venvs/packages et `uvx` pour lancer des CLI Python isolés. |
| **Git** | `/usr/bin/git` | Installé et configuré. |
| **GitHub CLI** | `/usr/bin/gh` | Authentifié sur le compte `Rafache`. Gère `https://github.com/Rafache/skills.git`. |
| **GitLab CLI** | `/usr/bin/glab` | Authentifié sur **`gitlab.bayard.io`** (`rchemin`). *(Non configuré sur gitlab.com)*. |
| **Chrome DevTools MCP** | `npx -y chrome-devtools-mcp@latest` | Pilote Google Chrome Stable (`/usr/bin/google-chrome`) en mode headless. *(Playwright abandonné)*. |
| **FFmpeg / ffprobe** | `/usr/bin/ffmpeg`, `/usr/bin/ffprobe` | Accélération matérielle Radeon 780M (`radeonsi_drv_video.so`) : `h264_vaapi`, `hevc_vaapi`, `av1_vaapi`. |
| **aria2c** | `/usr/bin/aria2c` | Téléchargement rapide multi-segments / magnets (utilisé par le skill `media-workflow`). |
| **Outils système** | `sensors`, `nvme`, `smartctl`, `ethtool`, `vainfo` | Surveillance hardware et vidéo. |
| **Agents IA** | `codex`, `agy` (Antigravity), `claude` | Outils installés sur l'hôte. |

---

## 5. Garde-fous & Commandes Interdites

Pour préserver l'intégrité de l'AuBox, **les règles suivantes sont absolues** :

### 🛑 Interdictions strictes sans validation humaine préalable :
1. **Destruction de volumes Docker** :
   - ❌ `docker compose down -v`
   - ❌ `docker volume rm ...`
   - ❌ `docker system prune --volumes`
   *(Un simple `docker compose down` arrête les conteneurs sans altérer les données).*
2. **Suppressions brutales de fichiers** :
   - ❌ `rm -rf /` ou `rm -rf ~/...` sur des dossiers projets ou données.
3. **Exposition réseau non sécurisée** :
   - ❌ Ne jamais mapper de ports de services sensibles ou de bases de données sur `0.0.0.0`.
   - ✅ Utiliser `127.0.0.1` pour le local ou l'IP locale `192.168.1.10` pour l'accès privé via LAN ou VPN Freebox.
4. **Git destructif** :
   - ❌ `git reset --hard` ou `git clean -fd` sans demande formelle.
   - ❌ `git push --force` sur les branches principales.
5. **Fuite de secrets** :
   - ❌ Ne jamais committer de `.env`, token GitHub/GitLab, clé SSH ou mot de passe.
   - ❌ Ne jamais afficher les valeurs des secrets en clair dans les logs ou les réponses utilisateur.

---

## 6. Procédures Types pour Nouvelles Configurations

### A. Déployer un nouveau service Docker permanent
1. Créer un sous-dossier dédié : `mkdir -p ~/services/<nom-du-service>`.
2. Créer un fichier `compose.yaml` propre :
   - Spécifier des images avec tags de version précis (éviter `latest` en prod).
   - Raccorder au réseau existant :
     ```yaml
     networks:
       aubox:
         external: true
     ```
   - Lier les ports externes à l'IP locale si accès LAN/VPN nécessaire :
     ```yaml
     ports:
       - "192.168.1.10:PORT_HOTE:PORT_CONTAINER"
     ```
3. Stocker les secrets dans un fichier local `.env` (permissions `chmod 600 .env`).
4. Démarrer avec :
   ```bash
   export DOCKER_HOST=unix:///run/user/1000/docker.sock
   docker compose up -d
   ```

### B. Ajouter ou configurer un projet de code
1. Cloner dans l'arborescence adaptée :
   - Projets pro : `~/projets/bayard/<nom-projet>`
   - Projets perso : `~/projets/perso/<nom-projet>`
2. Écosystème Node : utiliser `npm install` ou `npx` (les binaires pointeront sur NVM courant).
3. Écosystème Python : initialiser avec `uv venv` puis `uv pip install ...`.

### C. Maintenance et mises à jour du système
Le script officiel est : `~/scripts/maintenance.sh`.
Il réalise :
```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean
docker system prune -f
```
*(Le nettoyage Docker avec `-f` nettoie les conteneurs éteints et caches, mais préserve scrupuleusement les volumes de données).*

---

## 7. Diagnostics Rapides (Sans Tout Rescanner)

Pour vérifier la santé du serveur sans exécuter de longs scans :

```bash
# État des conteneurs
export DOCKER_HOST=unix:///run/user/1000/docker.sock
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Espace disque hôte et montages Synology
df -h / /mnt/ds716/*

# Statut des interfaces réseau et adresses IP
ip -br a

# Températures et ventilation
sensors

# Accélération matérielle vidéo GPU Radeon
vainfo --display drm
```
