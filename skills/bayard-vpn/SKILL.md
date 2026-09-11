---
name: bayard-vpn
description: Pilotage du VPN d'entreprise Bayard (Fortinet SSL-VPN) en split-tunneling sur l'AuBox pour accéder aux ressources internes (*.bayard.io, *.bayardev.com, preprod.*, 10.0.0.0/8, 172.16.0.0/12).
---

# Bayard VPN

Split-tunneling vers les réseaux privés Bayard (`10.0.0.0/8`, `172.16.0.0/12`). La passerelle par défaut de l'AuBox reste inchangée. Ne jamais lire ni modifier `/etc/openfortivpn/config`.

## 1. Commandes & Workflow Agent

Script : `bayard-vpn` (ou `scripts/bayard-vpn.sh`).

```bash
bayard-vpn status               # Vérifier l'état (CONNECTÉ / DÉCONNECTÉ)
bayard-vpn start <CODE_OTP>     # Connecter avec le FortiToken (6 chiffres)
bayard-vpn stop                 # Déconnecter
bayard-vpn route <domaine>      # Router un domaine public via l'IP Bayard
bayard-vpn unroute <domaine>    # Retirer les routes du domaine
bayard-vpn logs                 # Voir les logs récents
```

**Règle Agent** : Si le statut est `DÉCONNECTÉ`, demander le code à l'utilisateur :
> *« J'ai besoin d'accéder aux services internes Bayard. Pouvez-vous me donner votre code FortiToken actuel (6 chiffres) ? »*

## 2. Contournement WAF CloudFront (*.prionseneglise.fr, *.la-croix.com, *.notretemps.com, preprod.*, ...)

Le WAF AWS bloque au niveau HTTP l'IPv6 (renvoie un faux 404), les requêtes `HEAD`, les identifiants `curl` / `HeadlessChrome`, et n'autorise que certaines IP source.

### Les trois règles de forme

- **Avec `curl`** : forcer l'IPv4 (`-4`), un User-Agent navigateur, et ne jamais utiliser `curl -I` (toujours du `GET`) :
  ```bash
  curl -4 -s -L -A "Mozilla/5.0 (X11; Linux x86_64) Chrome/133.0.0.0" <URL>
  ```
- **Avec Chrome headless** : forcer l'IPv4 et surcharger le User-Agent :
  ```bash
  IP=$(getent ahostsv4 <domaine> | awk '{print $1}' | head -1)
  google-chrome --headless --disable-gpu --user-agent="Mozilla/5.0 (X11; Linux x86_64) Chrome/133.0.0.0" --host-resolver-rules="MAP <domaine> ${IP}" --dump-dom <URL>
  ```

### Sortir par l'IP Bayard quand l'IP de l'AuBox est refusée

Le split-tunneling ne pousse par défaut que `10.0.0.0/8` et `172.16.0.0/12`. **La passerelle Fortinet relaie et traduit le trafic qu'on lui adresse explicitement** : router la destination par `ppp-bayard` permet de ressortir avec l'IP publique de Bayard (`13.36.96.165`), autorisée par le WAF CloudFront.

Le script fournit une commande dédiée qui résout le domaine et pose une route `/32` par IP obtenue :

```bash
bayard-vpn route <domaine>    # Résout et pose les routes /32 sur ppp-bayard
```

Pour garantir que curl et Chrome utilisent bien l'une des IP routées même en cas de rotation DNS CloudFront, épingler l'IP :

```bash
IP=$(getent ahostsv4 <domaine> | awk '{print $1}' | head -1)
curl -4 -s -A "Mozilla/5.0 (X11; Linux x86_64) Chrome/133.0.0.0" \
  --resolve <domaine>:443:$IP -w " [sortie %{local_ip}]" https://<domaine>/<page>
```

`%{local_ip}` permet de vérifier le chemin emprunté : `172.27.x` pour le tunnel Bayard, `192.168.1.10` pour la Freebox.

Libérer une fois terminé (les routes disparaissent également à l'arrêt du VPN) :

```bash
bayard-vpn unroute <domaine>
```

> [!WARNING]
> Ne jamais basculer la route par défaut en tunnel complet : tout le trafic de l'AuBox partirait chez Bayard, y compris les projets perso, les conteneurs Docker et le renouvellement des certificats.

### Volume de requêtes

Ne pas marteler une préprod. Le 10/09/2026, plusieurs centaines de requêtes en quelques minutes ont précédé un blocage durable de l'IP domestique, qui ne s'est pas levé de lui-même. Pour toute mesure répétée, servir le build en local :

```bash
(cd public && nohup python3 -m http.server 8099 --bind 127.0.0.1 &)
npx -y lighthouse@latest http://127.0.0.1:8099/<page> --quiet
```

C'est d'ailleurs plus juste pour comparer deux états, la latence réseau ne brouillant rien. Le routage par Bayard sert aux **vérifications fonctionnelles** — en-têtes, présence d'un contenu, parcours de consentement — pas aux mesures de performance, qu'il fausserait en ajoutant de la latence et en changeant le POP atteint.

## 3. Review Apps & Préprods (*.review.bayardev.com, preprod.*)

Accessibles **sans VPN** via l'authentification HTTP Basic Auth (`Bayard Restricted Area`). Identifiants stockés dans `~/.config/bayard/review-auth.env` :

```bash
source ~/.config/bayard/review-auth.env
curl -s -L -u "${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}" <URL>
```
*Via navigateur :* `https://${BAYARD_REVIEW_USER}:${BAYARD_REVIEW_PASSWORD}@<domaine>/`

> [!NOTE]
> **Plage horaire préprods** : Les environnements de préprod Bayard sont automatiquement éteints la nuit de **20h à 8h** (timeouts ou indisponibilités normaux sur ce créneau).
