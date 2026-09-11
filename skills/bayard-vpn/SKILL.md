---
name: bayard-vpn
description: Accès et tests des sites, préprods et APIs du groupe Bayard (*.bayard.io, *.bayardev.com, *.prionseneglise.fr, preprod.*). Piloter le VPN Fortinet en split-tunneling, router un domaine public via l'IP Bayard, contourner les blocages WAF CloudFront (faux 404) et s'authentifier sur les review apps.
---

# Bayard VPN

Split-tunneling vers les réseaux privés Bayard (`10.0.0.0/8`, `172.16.0.0/12`). La passerelle par défaut de l'AuBox reste inchangée. Ne jamais lire ni modifier `/etc/openfortivpn/config`.

## 1. Commandes & Workflow

Script : `bayard-vpn` (ou `scripts/bayard-vpn.sh`).

```bash
bayard-vpn status               # État (CONNECTÉ / DÉCONNECTÉ)
bayard-vpn start <CODE_OTP>     # Connecter avec le FortiToken (6 chiffres)
bayard-vpn stop                 # Déconnecter
bayard-vpn route <domaine>      # Router un domaine public/préprod via l'IP Bayard
bayard-vpn unroute <domaine>    # Retirer les routes du domaine
```

**Règle Agent** : Si le statut est `DÉCONNECTÉ`, demander le code à l'utilisateur :
> *« J'ai besoin d'accéder aux services internes Bayard. Pouvez-vous me donner votre code FortiToken actuel (6 chiffres) ? »*

## 2. Accès aux sites et préprods sous WAF CloudFront

Si un site public ou une préprod renvoie une erreur 404 ou 401 liée au filtrage IP :

```bash
bayard-vpn route <domaine>
curl -4 -s -L -A "Mozilla/5.0" https://<domaine>/
bayard-vpn unroute <domaine>   # Nettoyer après le test
```
*(Toujours utiliser un User-Agent standard et éviter `curl -I` que CloudFront bloque).*

## 3. Review Apps & Préprods (Basic Auth)

Accessibles **sans VPN** via l'authentification HTTP Basic Auth (`Bayard Restricted Area`). Identifiants stockés dans `~/.config/bayard/.env` :

```bash
source ~/.config/bayard/.env
curl -s -L -u "${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}" <URL>
```
*Via navigateur :* `https://${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}@<domaine>/`

> [!NOTE]
> **Extinction nocturne** : Les préprods sont automatiquement éteintes de **20h à 8h**.
