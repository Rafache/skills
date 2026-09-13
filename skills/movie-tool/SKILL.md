---
name: movie-tool
description: Recherche, découverte, téléchargement, encodage x265, renommage de films ou séries TV.
---

# Workflow Média

Exécuter uniquement les étapes demandées (pas d'enchaînement automatique).

## Directives d'orchestration
- **Scripts dédiés** : Utiliser uniquement `scripts/*.sh`.
- **Feedback** : Annoncer l'étape en cours, suivre le statut et résumer le résultat avant l'étape suivante.
- **Source protégée** : Ne jamais supprimer le fichier source sans validation explicite.

## Actions

| Action | Commande | Directive |
| :--- | :--- | :--- |
| **Recherche** | `scripts/search.sh [--source magnetz\|torrentclaw\|all] [options] "<titre>"` | Choisir Magnetz, TorrentClaw ou les deux (`all` par défaut). En mode multi-source, dédoublonner et retenir la meilleure correspondance avant de proposer un téléchargement. Privilégier `2160p`/`x265`, puis élargir à `1080p` si nécessaire. |
| **Découverte** | `scripts/discover.sh recent\|popular\|trending\|upcoming\|streaming-top [options]` | Découvrir des contenus récents, populaires, tendance ou à venir. Ne pas télécharger sans demande explicite. |
| **Téléchargement** | `scripts/download.sh '<magnet>'` | Tâche de fond. Destination : `/mnt/ds716/video/downloads`. Fournir bilan final. |
| **Analyse** | `scripts/probe.sh '<fichier>'` | Identifier codecs audio/vidéo, résolution, langues et sous-titres. |
| **Optimisation** | `scripts/optimize.sh [opts] '<src>'` | Tâche de fond et séquentiel. Règles et options : [optimize.md](file:///home/rafache/.config/agents/skills/movie-tool/references/optimize.md). |
| **Renommage** | Commandes standard | Formats stricts : [naming-and-storage.md](file:///home/rafache/.config/agents/skills/movie-tool/references/naming-and-storage.md). |
| **Rangement** | Déplacement vers NAS | Destinations et règles : [naming-and-storage.md](file:///home/rafache/.config/agents/skills/movie-tool/references/naming-and-storage.md). |
