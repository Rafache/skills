---
name: media-workflow
description: Recherche des torrents via Magnetz, télécharge un magnet avec aria2c, analyse un film avec ffprobe, peut l'optimiser en x265, le renommer et le ranger sur le Synology. Chaque étape peut être demandée seule ou enchaînée explicitement.
---

# Torrent / média

Ce skill est volontairement modulaire. Ne lance que les étapes demandées par l'utilisateur.

## Rôle de l'Agent : Orchestrateur

L'agent agit en chef d'orchestre du workflow :
- **Interdiction formelle de créer des scripts Python ad-hoc / à la volée** : Ne jamais écrire de wrapper `.py`, de watcher ou de script temporaire.
- **Utiliser exclusivement les scripts connus** du dossier `scripts/` (`search.sh`, `download.sh`, `probe.sh`, `optimize.sh`) et les commandes standard (`mkdir -p`, `mv`).
- **Exécution 1 par 1 en tâche de fond** :
  - Lancer les tâches longues (téléchargement `download.sh`, encodage `optimize.sh`) **en tâche de fond** (background task) **séquentiellement, une par une**.
  - Ne jamais exécuter plusieurs tâches lourdes en parallèle (préserve CPU, I/O et bande passante).
- **Supervision & Feedback continu** :
  - Annoncer le plan : étape en cours (ex : *Téléchargement*) et étapes à venir (ex : *Analyse → Encodage → Renommage → Rangement*).
  - Suivre l'avancement de la tâche de fond en direct (vérifier les logs/statuts).
  - À la complétion d'une tâche, analyser le résultat (`DOWNLOAD_SUMMARY` ou `OPTIMIZE_SUMMARY`, code retour, taille), donner un feedback synthétique à l'utilisateur, puis lancer l'étape suivante.

## Actions disponibles

1. `search` — rechercher des torrents.
2. `download` — télécharger un lien magnet.
3. `analyze` — analyser un fichier média.
4. `optimize` — réencoder/nettoyer un média.
5. `rename` — normaliser le nom du fichier.
6. `organize` — ranger le fichier sur le Synology.
7. `pipeline` — enchaîner plusieurs étapes, uniquement si la demande de l'utilisateur les implique.

Une demande peut ne concerner qu'une seule action.

Exemples :
- « cherche Oradour 2026 » → `search` seulement.
- « télécharge ce magnet » → `download` seulement.
- « analyse ce fichier » → `analyze` seulement.
- « optimise ce fichier » → `analyze` si nécessaire puis `optimize`.
- « renomme ce fichier » → `rename` seulement.
- « range ce film » → `organize` seulement.
- « cherche, télécharge et range X » → `search` → `download` → analyse minimale si nécessaire → `organize`.
- « traite complètement X » → `search` → `download` → `analyze` → `optimize` si pertinent → `rename` → `organize`.

Ne rajoute pas automatiquement des étapes qui n'ont pas été demandées.

# 1. Recherche

Utiliser :

```bash
scripts/search.sh "<requête>"
```

Le script interroge l'API publique Magnetz et renvoie un JSON trié par nombre de seeders décroissant.

Pour choisir un résultat, tenir compte dans cet ordre :
- correspondance avec le titre demandé ;
- langue/release demandée : `FRENCH`, `VFF`, `TRUEFRENCH`, `MULTi`, `VOSTFR` ;
- résolution ;
- codec/source si précisés ;
- nombre de seeders ;
- taille.

Si l'utilisateur demande seulement une recherche, présenter les meilleurs résultats et **ne pas télécharger**.

Si l'utilisateur demande explicitement recherche + téléchargement, choisir le meilleur résultat correspondant aux critères. En cas d'ambiguïté réelle entre plusieurs releases, demander lequel utiliser.

# 2. Téléchargement

Pour un magnet fourni ou sélectionné :

```bash
scripts/download.sh '<magnet>'
```

Règles :
- un seul torrent à la fois ;
- destination fixe : `/mnt/ds716/video/downloads` ;
- aria2c en one-shot ;
- aucun daemon ;
- aucun RPC ;
- aucun service systemd ;
- arrêt du seeding à la fin.

Si l'environnement d'agent sait lancer une commande longue comme tâche asynchrone, utiliser cette capacité native.

À la fin, fournir un bilan avec :
- fichier ;
- taille ;
- durée du téléchargement ;
- vitesse moyenne si elle peut être déduite du résumé aria2 ;
- statut final.

Le script ajoute :

```text
DOWNLOAD_SUMMARY|duration_seconds=<secondes>|exit_code=<code>
```

# 3. Analyse

Utiliser :

```bash
scripts/probe.sh '<fichier>'
```

Interpréter le JSON ffprobe et résumer :
- durée média et taille ;
- codec vidéo ;
- résolution ;
- FPS ;
- bitrate ;
- pixel format ;
- HDR / Dolby Vision si présents ;
- audio : codec, langue, canaux, titre, default ;
- sous-titres : codec, langue, titre, default, forced.

L'analyse peut être demandée seule. Dans ce cas, ne pas encoder, renommer ou déplacer.

# 4. Optimisation x265

Utiliser le script connu :

```bash
scripts/optimize.sh [options] '<fichier_source>' ['<fichier_destination>']
```

Options disponibles :
- `-a, --audio <copy|eac3|aac>` : Codec audio (défaut : `copy`).
  - **`eac3` (recommandé)** : Convertit en Dolby Digital Plus (640k). À utiliser pour les pistes sans perte ou peu compatibles comme le **DTS, DTS-HD, TrueHD** (gain de 2 à 4 Go par film, compatibilité universelle Direct Play sur TV/Apple TV).
  - `aac` : Encodage AAC (384k).
  - `copy` : Recopie sans réencodage (pour pistes déjà en EAC3, AC3, AAC).
- `-c, --crf <int>` : CRF vidéo x265 (défaut : `22`).
- `-p, --preset <nom>` : Preset x265 (défaut : `medium`).

À lancer obligatoirement en **tâche de fond** (background task).

Avant l'encodage, inspecter le fichier via `scripts/probe.sh` pour déterminer les codecs vidéo et audio.

Politique par défaut :
- vidéo : `libx265`, `-preset medium`, `-crf 22` ;
- audio : `copy` par défaut, ou `-a eac3` si DTS / DTS-HD / TrueHD détecté ou sur demande ;
- conserver résolution et framerate ;
- conserver métadonnées et chapitres ;
- copier les sous-titres sans réencodage ;
- produire un conteneur MKV ;
- interdiction stricte d'écraser le fichier source.

Le script renvoie en fin d'exécution :
```text
OPTIMIZE_SUMMARY|duration_seconds=<secondes>|exit_code=<code>|audio_codec=<codec>|output=<fichier>
```

Ne pas réencoder mécaniquement :
- si la vidéo est déjà HEVC/x265 ou AV1, signaler que le gain est probablement faible ;
- si le bitrate est déjà faible, signaler le risque de perte ;
- pour HDR/Dolby Vision, préserver correctement les informations couleur/HDR ou demander confirmation si le pipeline n'est pas sûr.

Si les langues de pistes sont absentes ou ambiguës, ne pas deviner.

# 5. Renommage

Le renommage peut être demandé seul, sans réencodage.

## Film

Format :

```text
Titre.Officiel.Annee.<FRENCH ou VOSTFR>.<Resolution>.<CodecAudio>.x265.mkv
```

Exemple :

```text
Minions.And.Monsters.2026.FRENCH.1080p.AAC.x265.mkv
```

Pour un fichier qui n'est pas en x265 et qui est seulement renommé, conserver le codec vidéo réel à la place de `x265`.

## Série

Format :

```text
Titre.Officiel.SxxExx.<FRENCH ou VOSTFR>.<Resolution>.<CodecAudio>.x265.mkv
```

Exemple :

```text
Asterix.et.Obelix.Le.Combat.des.Chefs.S01E05.FRENCH.1080p.EAC3.x265.mkv
```

Pour plusieurs épisodes dans le même fichier, utiliser une notation explicite telle que :

```text
S01E01-E02
```

Règles de langue :
- `FRENCH` si une piste audio française est conservée ;
- `VOSTFR` s'il n'y a pas d'audio français mais qu'une piste anglaise et des sous-titres français sont présents.

Ne pas inventer un titre officiel, une année ou un numéro d'épisode incertain. Utiliser le contexte disponible ou demander confirmation.

# 6. Rangement Synology

Arborescence :

```text
/mnt/ds716/video/
├── downloads/
├── Enfants/
│   ├── Films/
│   └── Series/
└── Adulte/
    ├── Films/
    └── Series/
```

## Film

Destination :

```text
/mnt/ds716/video/Enfants/Films/
```

ou :

```text
/mnt/ds716/video/Adulte/Films/
```

## Série

Destination :

```text
/mnt/ds716/video/<Enfants ou Adulte>/Series/Titre.Officiel/
```

Les épisodes sont directement dans le dossier de la série. Ne pas créer de dossier `Season 01`.

Si le classement `Enfants` / `Adulte` est ambigu, demander confirmation.

Créer le dossier cible avec `mkdir -p` si nécessaire puis déplacer avec `mv`.

Ne jamais supprimer automatiquement le fichier source d'un réencodage. Si un fichier x265 a été produit, demander explicitement avant de supprimer l'original.

# Principes

- **Zéro script Python jetable** : L'agent s'interdit d'écrire du code Python ad-hoc et s'appuie sur les scripts connus du dossier `scripts/`.
- **Orchestration séquentielle** : Les tâches lourdes s'exécutent 1 par 1 en tâche de fond avec feedback continu.
- Les scripts sont des primitives simples ; l'agent garde le rôle d'orchestrateur.
- Chaque action peut être utilisée indépendamment.
- N'enchaîner que les actions demandées ou clairement impliquées.
- Ne pas modifier les permissions du NAS.
- Ne pas inventer des métadonnées absentes ou ambiguës.
