---
name: movie-tool
description: Recherche, téléchargement, optimisation x265 et classement de films ou séries vers le Synology.
---

# Workflow Média

Exécuter uniquement les étapes demandées (pas d'enchaînement automatique).

## Directives d'orchestration
- **Scripts dédiés** : Aucun script ad-hoc (Python ou bash) ; utiliser uniquement `scripts/*.sh`.
- **Tâches de fond** : Lancer `download.sh` et `optimize.sh` en arrière-plan, 1 par 1 (séquentiel).
- **Feedback** : Annoncer l'étape en cours, suivre le statut et résumer le résultat avant l'étape suivante.
- **Source protégée** : Ne jamais supprimer le fichier source sans validation explicite.

## Actions

| Action | Commande | Directive |
| :--- | :--- | :--- |
| **Recherche** | `scripts/search.sh "<titre>"` | Prioriser `FRENCH`/`MULTi`, résolution et seeders. Ne pas télécharger sans demande explicite. |
| **Téléchargement** | `scripts/download.sh '<magnet>'` | Tâche de fond. Destination : `/mnt/ds716/video/downloads`. Fournir bilan final. |
| **Analyse** | `scripts/probe.sh '<fichier>'` | Identifier codecs audio/vidéo, résolution, langues et sous-titres. |
| **Optimisation** | `scripts/optimize.sh [opts] '<src>'` | Tâche de fond. Règles et options : [optimize.md](file:///home/rafache/.config/agents/skills/movie-tool/references/optimize.md). |
| **Renommage** | Commandes standard | Formats stricts : [naming-and-storage.md](file:///home/rafache/.config/agents/skills/movie-tool/references/naming-and-storage.md). |
| **Rangement** | Déplacement vers NAS | Destinations et règles : [naming-and-storage.md](file:///home/rafache/.config/agents/skills/movie-tool/references/naming-and-storage.md). |
