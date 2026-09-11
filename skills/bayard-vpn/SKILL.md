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
bayard-vpn unroute              # Retirer les routes hôtes ajoutées
```

**Règle Agent** : Si le statut est `DÉCONNECTÉ`, demander le code à l'utilisateur :
> *« J'ai besoin d'accéder aux services internes Bayard. Pouvez-vous me donner votre code FortiToken actuel (6 chiffres) ? »*

## 2. Accès aux sites et préprods sous WAF CloudFront

Si un site public ou une préprod renvoie une erreur 404 liée au filtrage IP :

```bash
bayard-vpn route <domaine>
curl -4 -s -L -A "Mozilla/5.0" https://<domaine>/
bayard-vpn unroute              # Nettoyer après le test
```
Le drapeau `-4` et un User-Agent navigateur sont obligatoires (le tunnel est strictement IPv4 et CloudFront bloque les requêtes `HEAD` / `curl -I`).

> [!WARNING]
> **Ne pas marteler une préprod.** Plusieurs centaines de requêtes en quelques minutes suffisent à faire bloquer durablement une IP. Pour toute mesure répétée — audits Lighthouse, vérification d'assets — servir le build en local avec `python3 -m http.server --bind 127.0.0.1`, et ne sortir sur l'URL publique que pour des contrôles ponctuels.

## 3. Review Apps & Préprods (Basic Auth)

Accessibles **sans VPN** via l'authentification HTTP Basic Auth (`Bayard Restricted Area`). Identifiants stockés dans `~/.config/bayard/.env` :

```bash
source ~/.config/bayard/.env
curl -s -L -u "${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}" <URL>
```
*Via navigateur :* `https://${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}@<domaine>/`

> [!NOTE]
> **Extinction nocturne** : Les préprods sont automatiquement éteintes de **20h à 8h**.
