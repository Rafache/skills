---
name: movie-tool
description: Recherche, découverte, téléchargement, optimisation x265 et classement de films ou séries vers le Synology.
---

# Workflow Média

Exécuter uniquement les étapes demandées (pas d'enchaînement automatique).

## Directives d'orchestration
- **Scripts dédiés** : Aucun script ad-hoc (Python ou bash) ; utiliser uniquement `scripts/*.sh`.
- **Tâches de fond** : Lancer `download.sh` et `optimize.sh` en arrière-plan, 1 par 1 (séquentiel).
- **Feedback** : Annoncer l'étape en cours, suivre le statut et résumer le résultat avant l'étape suivante.
- **Source protégée** : Ne jamais supprimer le fichier source sans validation explicite.
- **Secrets** : Ne jamais écrire de clé API dans le skill, les scripts, le code ou un dépôt. TorrentClaw charge éventuellement `TORRENTCLAW_API_KEY` depuis la variable d’environnement ou `/home/rafache/.config/torrentclaw/.env`.

## Actions

| Action | Commande | Directive |
| :--- | :--- | :--- |
| **Recherche** | `scripts/search.sh [options] "<titre>"` | `all` par défaut. Rechercher dans les deux sources, dédoublonner et retenir la meilleure correspondance avant de proposer un téléchargement. Privilégier `2160p`/`x265`, puis élargir à `1080p` si nécessaire. |
| **Découverte** | `scripts/discover.sh recent\|popular\|trending\|upcoming\|streaming-top [options]` | Utiliser uniquement TorrentClaw. Ne pas télécharger sans demande explicite. |
| **Téléchargement** | `scripts/download.sh '<magnet>'` | Tâche de fond. Destination : `/mnt/ds716/video/downloads`. Fournir bilan final. |
| **Analyse** | `scripts/probe.sh '<fichier>'` | Identifier codecs audio/vidéo, résolution, langues et sous-titres. |
| **Optimisation** | `scripts/optimize.sh [opts] '<src>'` | Tâche de fond. Règles et options : [optimize.md](file:///home/rafache/.config/agents/skills/movie-tool/references/optimize.md). |
| **Renommage** | Commandes standard | Formats stricts : [naming-and-storage.md](file:///home/rafache/.config/agents/skills/movie-tool/references/naming-and-storage.md). |
| **Rangement** | Déplacement vers NAS | Destinations et règles : [naming-and-storage.md](file:///home/rafache/.config/agents/skills/movie-tool/references/naming-and-storage.md). |

## Recherche et découverte

- Référence API TorrentClaw : [llms.txt](https://torrentclaw.com/llms.txt). Utiliser uniquement les endpoints REST publics ; ne pas dépendre de Torznab, du débrid ou des flux RSS personnalisés réservés aux offres supérieures.

- Pour une recherche de titre, utiliser `search.sh --source all` par défaut. Comparer le titre, l'année, le type et la saison/épisode quand ces informations sont disponibles.
- `search.sh --source magnetz` et `search.sh --source torrentclaw` permettent de cibler une source.
- Les filtres TorrentClaw `--quality 2160p|1080p` et `--codec x265|hevc` sont facultatifs ; ne pas imposer 2160p si aucune version fiable n'est disponible.
- `discover.sh recent` interroge les ajouts récents TorrentClaw ; cela décrit l'indexation TorrentClaw.
- `discover.sh popular` interroge les contenus populaires TorrentClaw.
- `discover.sh trending` utilise les tendances quotidiennes, hebdomadaires ou mensuelles.
- `discover.sh upcoming` utilise les sorties prévues dans les six prochains mois selon les données TorrentClaw/TMDB.
- `discover.sh streaming-top` interroge le Top 10 d'une plateforme et indique si un torrent correspondant existe.
- Les options sont `--locale`, `--limit`, `--page`, `--type`, `--period`, `--service`, `--country`, `--show-type` et `--format table|json`, selon le mode.
