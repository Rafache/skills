---
name: bayard-vpn
description: Pilotage du VPN d'entreprise Bayard (Fortinet SSL-VPN) en split-tunneling sur l'AuBox pour accéder aux ressources internes (*.bayard.io, *.bayardev.com, 10.0.0.0/8, 172.16.0.0/12).
---

# Bayard VPN

Split-tunneling vers les réseaux privés Bayard (`10.0.0.0/8`, `172.16.0.0/12`). La passerelle par défaut de l'AuBox reste inchangée. Ne jamais lire ni modifier `/etc/openfortivpn/config`.

## 1. Commandes & Workflow Agent

Script : `bayard-vpn` (ou `scripts/bayard-vpn.sh`).

```bash
bayard-vpn status               # Vérifier l'état (CONNECTÉ / DÉCONNECTÉ)
bayard-vpn start <CODE_OTP>     # Connecter avec le FortiToken (6 chiffres)
bayard-vpn stop                 # Déconnecter
bayard-vpn logs                 # Voir les logs récents
```

**Règle Agent** : Si le statut est `DÉCONNECTÉ`, demander le code à l'utilisateur :
> *« J'ai besoin d'accéder aux services internes Bayard. Pouvez-vous me donner votre code FortiToken actuel (6 chiffres) ? »*

## 2. Contournement WAF CloudFront (*.prionseneglise.fr, préprods)

Le WAF bloque au niveau HTTP l'IPv6 (renvoie un faux 404), les requêtes `HEAD` et les identifiants `curl` / `HeadlessChrome`.

- **Avec `curl`** : forcer l'IPv4 (`-4`), un User-Agent navigateur et ne jamais utiliser `curl -I` (toujours du `GET`) :
  ```bash
  curl -4 -s -L -A "Mozilla/5.0 (X11; Linux x86_64) Chrome/133.0.0.0" <URL>
  ```
- **Avec Chrome headless** : forcer l'IPv4 et surcharger le User-Agent :
  ```bash
  IP=$(dig +short A <domaine> | tail -n1)
  google-chrome --headless --disable-gpu --user-agent="Mozilla/5.0 (X11; Linux x86_64) Chrome/133.0.0.0" --host-resolver-rules="MAP <domaine> ${IP}" --dump-dom <URL>
  ```

## 3. Review Apps (*.review.bayardev.com)

Authentification Basic Auth requise. Identifiants stockés dans `~/.config/bayard/review-auth.env` :

```bash
source ~/.config/bayard/review-auth.env
curl -4 -s -L -u "${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}" <URL>
```
*Via navigateur :* `https://${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}@<domaine>.review.bayardev.com/`
