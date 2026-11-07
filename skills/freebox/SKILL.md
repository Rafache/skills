---
name: freebox
description: Pilotage de la Freebox via son API locale - équipements du réseau local et Wi-Fi, réveil Wake-on-LAN, état de la connexion, appels API bruts.
---

# Freebox

CLI maison pour l'API Freebox OS (v8), utilisable depuis l'AuBox.

## 1. Commandes

Script : `freebox` (ou `scripts/freebox.py`).

```bash
freebox status                  # État de la connexion (fibre, IP publique)
freebox hosts                   # Équipements du réseau local (nom, IP, MAC)
freebox wifi                    # Équipements connectés en Wi-Fi
freebox wol <MAC>               # Réveiller un équipement (ex. NAS : 00:11:32:55:14:08)
freebox raw GET /connection/    # Appel brut à l'API (méthodes GET/POST/PUT/DELETE, --data '<json>')
freebox register                # Association initiale (appui sur le bouton de la Freebox requis)
```

## 2. Configuration

- Jeton d'application : `~/.config/freebox/.env` (`FREEBOX_APP_TOKEN`, `chmod 600`), créé par `freebox register`. Ne jamais l'afficher.
- API : `http://mafreebox.freebox.fr/api/v8`, application `fr.chem1.aubox`.

## 3. Règles Agent

- Identifier un appareil par son IP : `freebox hosts` (ou `getent hosts <ip>` pour le nom local).
- Ne pas réveiller le Synology pour une sauvegarde planifiée : `aubox-backup` notifie au lieu de réveiller.
- Si `Freebox non configurée` : demander à l'utilisateur de lancer `freebox register` et d'appuyer sur le bouton de la Freebox.
