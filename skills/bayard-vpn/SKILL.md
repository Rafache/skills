---
name: bayard-vpn
description: Gestion du tunnel VPN d'entreprise Bayard (Fortinet SSL-VPN) en split-tunneling sur l'AuBox. Permet aux agents de vérifier l'accès aux sites internes (*.bayard.io, intranet-bayard.com), de solliciter le code FortiToken à l'utilisateur si nécessaire et de piloter le tunnel.
---

# Bayard VPN — Guide Opérationnel & Bonnes Pratiques

Ce skill décrit comment piloter le tunnel VPN d'entreprise Bayard depuis l'AuBox afin d'accéder aux environnements et services internes (`*.bayard.io`, `*.intranet-bayard.com`, sous-réseaux privés `10.0.0.0/8` et `172.16.0.0/12`).

---

## 1. Principes & Sécurité

1. **Split-Tunneling strict** :
   - Seul le trafic destiné aux sous-réseaux d'entreprise (`10.0.0.0/8`, `172.16.0.0/12`) est dirigé vers l'interface `ppp-bayard`.
   - La passerelle par défaut de l'AuBox (Internet, Freebox, SSH, services Docker) reste **totalement inchangée**.
2. **Cloisonnement des secrets** :
   - Le mot de passe corporate est confiné dans `/etc/openfortivpn/config` sous permissions `root:root (600)`.
   - **Interdiction absolue** : Les agents ne doivent jamais tenter de lire, afficher ou modifier ce fichier.
   - Seul le code temporaire OTP (**FortiToken**, 6 chiffres) est manipulé dynamiquement.

---

## 2. Commandes CLI

Le script officiel est situé dans `/home/rafache/scripts/bayard-vpn.sh` (accessible directement via `bayard-vpn`) :

```bash
# Vérifier si le tunnel est actif et si les sites internes répondent
bayard-vpn status

# Démarrer le tunnel avec le code FortiToken
bayard-vpn start <CODE_OTP_6_CHIFFRES>

# Arrêter le tunnel proprement
bayard-vpn stop

# Consulter les derniers logs de connexion
bayard-vpn logs
```

---

## 3. Workflow pour les Agents IA

Quand une tâche nécessite d'interagir avec des ressources internes Bayard (navigateur headless, curl, tests d'API, requêtes SQL/bases distantes) :

1. **Vérification préalable** :
   Exécuter `bayard-vpn status`.
2. **Si le VPN est DÉCONNECTÉ** :
   Demander explicitement le code FortiToken à l'utilisateur dans le chat :
   > *"J'ai besoin d'accéder aux services internes Bayard pour réaliser cette action. Pouvez-vous me donner votre code FortiToken actuel (6 chiffres) ?"*
3. **À la réception du code** :
   Exécuter `bayard-vpn start <CODE>`.
4. **Si la connexion réussit** :
   Reprendre immédiatement le déroulement normal de la tâche.

---

## 4. Tests Web & WAF CloudFront (Bonnes Pratiques)

Certains sites d'entreprise ou préprods (ex: `*.prionseneglise.fr`, `*.intranet-bayard.com`) sont protégés par le WAF AWS CloudFront :

1. **Ne jamais utiliser `curl -I` (HEAD)** :
   CloudFront intercepte les requêtes `HEAD` brutes et renvoie une fausse erreur `404` ou `403`. Toujours effectuer des requêtes `GET`.
2. **Fournir un User-Agent navigateur avec curl et forcer IPv4** :
   Le WAF bloque les requêtes avec le User-Agent `curl/...` par défaut. Utiliser systématiquement un User-Agent réaliste et le drapeau `-4` (le tunnel VPN étant strictement IPv4) :
   ```bash
   curl -4 -s -L -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" <URL>
   ```
3. **Privilégier Google Chrome headless (Chrome DevTools MCP)** :
   Pour tester une page ou vérifier le rendu d'un site, utiliser prioritairement Chrome DevTools MCP. Il transmet nativement les en-têtes réels d'un navigateur moderne, exécute le JavaScript et n'est jamais filtré par les règles anti-bot du WAF.

---

## 5. Review Apps (`*.review.bayardev.com`)

Les environnements de revue déployés sur `*.review.bayardev.com` sont protégés par une authentification HTTP Basic Auth (`Bayard Restricted Area`) :

- **Identifiants** : stockés localement et de manière sécurisée dans `~/.config/bayard/review-auth.env` (permissions `600`).
- **Utilisation en CLI (curl)** :
  ```bash
  source ~/.config/bayard/review-auth.env
  curl -4 -s -L -u "${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}" <URL>
  ```
- **Utilisation avec Chrome / Navigateur** :
  Passer l'URL avec les identifiants pré-remplis :
  `https://${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}@<domaine>.review.bayardev.com/`

