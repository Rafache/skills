# AuBox — Référence de l'installation propre

Liste de ce qui doit être installé et pourquoi. Sert au ménage (tout ce qui n'est pas listé est suspect), à la reconstruction après une panne et à l'ajout d'un outil (l'ajouter ici avec son rôle).

Contrôle rapide des paquets apt installés à la main, hors bibliothèques et base Debian :

```bash
comm -23 <(apt-mark showmanual | grep -v '^lib' | sort) \
  <(dpkg-query -W -f='${Package} ${Priority}\n' | awk '$2~/required|important|standard/{print $1}' | sort -u)
```

Les bibliothèques (`lib*`) ne sont pas suivies une à une : ce sont des dépendances, apt les retire seul quand plus rien ne les utilise.

## 1. Paquets apt

| Paquet(s) | Dépôt | Rôle |
|---|---|---|
| `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin`, `docker-buildx-plugin` | Docker | Moteur Docker et Compose (stacks `~/services`, projets) |
| `gh` | GitHub CLI | GitHub (dépôt des skills, projets perso) |
| `google-cloud-cli` | Google Cloud SDK | Google Cloud (`gcloud`) |
| `glab` | Debian | GitLab Bayard |
| `git`, `git-lfs` | Debian | Versionnement, fichiers volumineux |
| `build-essential` | Debian | Compilation (modules natifs npm/Python) |
| `curl`, `jq`, `unzip`, `zip`, `zstd`, `qpdf`, `netcat-traditional` | Debian | Outils en ligne de commande (scripts `aubox-*`, skills) |
| `tmux`, `htop` | Debian | Sessions persistantes, supervision |
| `ffmpeg`, `vainfo`, `mesa-va-drivers` | Debian | Encodage vidéo, accélération matérielle VA-API (Radeon 780M ; nécessite le groupe `render`) |
| `aria2` | Debian | Téléchargements multi-sources (`movie-tool`) |
| `openfortivpn` | Debian | VPN Fortinet Bayard (`bayard-vpn`) |
| `nfs-common` | Debian | Montages NFS du Synology |
| `ethtool` | Debian | Wake-on-LAN de la carte réseau (`wol.service`) |
| `smartmontools`, `nvme-cli`, `lm-sensors`, `usbutils` | Debian | Santé du SSD, températures, matériel |
| `unattended-upgrades`, `needrestart` | Debian | Mises à jour automatiques, redémarrage des services après mise à jour |
| `bubblewrap`, `dbus-user-session` | Debian | Isolation des outils IA, services systemd utilisateur |
| `firmware-amd-graphics`, `firmware-realtek` | Debian | Pilotes GPU Radeon et carte réseau |
| `linux-image-amd64`, `grub-*`, `shim-signed`, `initramfs-tools` | Debian | Noyau et démarrage |
| `sudo`, `gnupg`, `sqv`, `openssl-provider-legacy`, `task-ssh-server`, `task-french`, `tasksel`, `console-setup`, `keyboard-configuration`, `busybox`, `logsave`, `krb5-locales`, `zlib1g`, `gcc-14-base` | Debian | Base de l'installation (SSH, langue, clavier, signatures) |

## 2. Outils hors apt

| Outil | Installation | Mise à jour |
|---|---|---|
| Node.js 24 | NVM (`~/.nvm`) | Manuelle |
| `claude`, `wrangler`, `gws` (`@googleworkspace/cli`) | npm global | `aubox-maintenance` (mensuelle) |
| `codex` | Binaire autonome (`~/.codex/packages`) | `codex update` via `aubox-maintenance` |
| `agy` (Antigravity) | Binaire (`~/.local/bin`) | `agy update` via `aubox-maintenance` |
| `twg` | Binaire (`~/.local/bin`) | `twg upgrade` via `aubox-maintenance` + `twg-upkeep.timer` |
| `uv`, `uvx` | Binaire (`~/.local/bin`) | `uv self update` via `aubox-maintenance` |
| `tessl` | Binaire (`~/.local/share/tessl`) | Automatique |
| `aubox-*`, `bayard-vpn`, `freebox` | Liens vers `~/.config/agents/skills/*/scripts` | Git |

Aucune bibliothèque Python n'est installée au niveau utilisateur (ni pip, ni outil `uv`).

## 3. Stacks Docker (`~/services`)

| Stack | Conteneurs | Volumes |
|---|---|---|
| `homeassistant` | `homeassistant`, `matter-server` (réseau hôte, versions figées) | `aubox_homeassistant_data`, `aubox_matterjs_data` |
| `proxy` | `proxy` (Nginx Proxy Manager) | `aubox_proxy_data`, `aubox_proxy_letsencrypt` |
| `adguard` | `adguard` (DNS, utilisé par au moins un Mac du réseau) | `aubox_adguard_conf`, `aubox_adguard_work` |
| `databases` | `postgres`, `mysql`, `redis` | `aubox_postgres_data`, `aubox_mysql_data`, `aubox_redis_data` |
| `browser` | `browser` (Chrome n.eko + CDP) | `aubox_browser_data` |

## 4. Services et planification

- Système : `ssh`, `cron`, `docker`, `containerd`, `unattended-upgrades` (+ timers `apt-daily*`), `smartmontools`, `lm-sensors`, `nfs-blkmap`, `rpcbind`, `systemd-timesyncd`, `wol.service`.
- Utilisateur : `antigravity-cli-daemon`, `codex-remote-control`, `twg-upkeep.timer` (linger activé).
- Cron (`rafache`) : `aubox-backup` (mer. et dim. 23:45), `aubox-health` (tous les jours 09:00), `aubox-maintenance` (1er dimanche du mois 04:00).

## 5. Configuration système modifiée

| Fichier | Rôle |
|---|---|
| `/etc/fstab` | Automontage NFS du Synology (`video`, `music`, `backup`) |
| `/etc/gai.conf` | Priorité IPv4 |
| `/etc/systemd/system/wol.service` | Wake-on-LAN au démarrage |
| `/etc/apt/apt.conf.d/52aubox-unattended` | Dépôts tiers, redémarrage auto 04:30, retrait des paquets inutiles |
| `/etc/docker/daemon.json` | Rotation des journaux des conteneurs (10 Mo × 3) |
| `~/.config/systemd/user/antigravity-cli-daemon.service.d/override.conf` | Attente du DNS au démarrage d'Antigravity |

## 6. Volontairement absent

Ne pas réinstaller sans besoin explicite :

- Samba (partage de fichiers) : inutilisé.
- Docker rootless (`docker-ce-rootless-extras`, `uidmap`, `slirp4netns`, `fuse-overlayfs`) : seul le Docker système est utilisé.
- Playwright / Chromium sur l'hôte (`xvfb`, polices, bibliothèques graphiques) : le navigateur tourne dans le conteneur `browser`.
- Arduino (`arduino-cli`, `~/.arduino15`), ESPHome : inutilisés.
- `docker-model-plugin`, `popularity-contest`, `os-prober`, `laptop-detect` : inutiles sur ce serveur.
- `python-matter-server` : remplacé par matterjs-server.
