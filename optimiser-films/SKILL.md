---
name: optimiser-films
description: >-
  Utilisez cette compétence pour optimiser, nettoyer ou ranger des films. Elle permet d'encoder en H.265 (avec hevc_videotoolbox sur Mac localement puis upload NAS), renommer selon la norme Scene (ex: Titre.Annee.FRENCH.1080p.EAC3.x265), gérer les sous-titres forcés, afficher des notifications système, et tenir un registre d'économies de stockage. Elle supporte le traitement d'un film unique ou d'un dossier entier (Batch).
---

# Optimisation et Rangement de Films (Media Center)

## 1. Mode d'exécution et Logique de Dossier

Avant toute chose, analysez le chemin du fichier pour déterminer la règle à appliquer :
* **Chemin contenant `Enfants`** 👉 Objectif **VF** (Audio Français uniquement, pas de sous-titres sauf les "forcés"). Le tag final sera `FRENCH`.
* **Chemin contenant `Adulte` (ou autre)** :
  * Étape 1 : Faites une recherche web pour déterminer la **langue originale** du film (ex: Américain, Espagnol, Français...).
  * Si la langue originale est **Française** 👉 Objectif **VF**. Gardez l'audio Français, supprimez les sous-titres (sauf "forcés"). Le tag sera `FRENCH`.
  * Si la langue originale est **Étrangère** 👉 Objectif **VOSTFR**. Gardez l'audio Original, ajoutez impérativement la piste de sous-titres Français complets. Le tag sera `VOSTFR`.
* **Note sur le mode Batch (Dossier)** : Si l'utilisateur demande d'optimiser tout un dossier, utilisez `find` pour identifier tous les films lourds (> 4Go). Traitez-les en invoquant des sous-agents. **IMPORTANT : Ne lancez pas plus de 2 sous-agents d'encodage en même temps**.

## 2. Analyse et Préparation du Film (par le Master Agent)

Pour chaque film :
1. **Titre Officiel et Langue Originale** : Cherchez sur le web le titre officiel français exact. **Si vous êtes en mode Adulte/VOSTFR**, cherchez également quelle est la *langue originale* de l'oeuvre (ex: La Casa de Papel = Espagnol, Parasite = Coréen).
2. **Métadonnées et Sous-titres (`ffprobe` / `subliminal` / `ffsubsync`)** :
   - L'index de la piste vidéo et sa **résolution** (>700 = 1080p, >2000 = 2160p).
   - L'index de la piste audio cible (Français si `Enfants` ou si film FR, Langue Originale si film étranger).
   - **Gestion des Sous-Titres** : Cherchez la piste de sous-titre voulue dans le fichier avec `ffprobe`.
     - *Si absente* et que l'objectif est VOSTFR : Ordonnez au sous-agent de la télécharger.
       Note: Sur Mac, ces outils s'installent souvent dans `~/Library/Python/*/bin/`. Ajoutez ce dossier au PATH avant de lancer :
       `export PATH=$PATH:$HOME/Library/Python/*/bin`
       `subliminal download -l fr "/tmp/Source.mkv"`
       `ffsubsync "/tmp/Source.mkv" -i "/tmp/Source.fr.srt" -o "/tmp/Source.sync.srt"`
       Le sous-agent devra alors intégrer ce nouveau fichier SRT dans sa commande ffmpeg (en ajoutant `-i "/tmp/Source.sync.srt" -c:s srt`).
3. **Nomenclature P2P (Scene)** : Remplacez les espaces par des points.
   👉 Format attendu : `Titre.Officiel.Annee.<FRENCH ou VOSTFR>.<Resolution>.<CodecAudio>.x265.mkv`

## 3. Lancement du Sous-Agent (Workflow NAS)

Créez un agent temporaire avec `define_subagent` (ex: `Encodeur_TitreDuFilm`), avec `enable_write_tools: true`.
Ensuite, utilisez `invoke_subagent` avec ce type. Donnez-lui ce prompt précis :

> "Ton rôle est d'encoder le fichier '{Fichier_Source}' en H.265.
> Voici les consignes strictes (tu dois lancer des outils `run_command` SÉPARÉS pour chaque étape afin que l'utilisateur puisse suivre la progression visuellement) :
>
> 1. **Téléchargement Local** : Copie le fichier source dans `/tmp/` (commande `cp`). Calcule et note le poids de départ (ex: `du -h`).
> 2. **Encodage** : Encode-le localement avec ffmpeg.
>    - Vidéo : `-map 0:v:0 -c:v hevc_videotoolbox -q:v 60 -tag:v hvc1`
>    - Audio : `-map 0:a:<INDEX_FR> -c:a copy`
>    - Sous-titres : Si un sous-titre forcé a été trouvé, mappe-le (`-map 0:s:<INDEX> -c:s copy`). Sinon, supprime tous les sous-titres (`-sn`).
>    Exemple : `ffmpeg -i "/tmp/Source.mkv" ... "/tmp/{Nom_Scene}.mkv"`
> 3. **Upload** : Déplace le fichier final vers le NAS (commande `mv`).
> 4. **Nettoyage** : Supprime la copie source dans `/tmp/` (commande `rm`).
> 5. **Notification Mac** : Affiche une notification macOS avec la commande :
>    `osascript -e 'display notification "Le film {Titre} est prêt !" with title "Antigravity - Optimisation"'`
> 6. **Log (Registre)** : Calcule le poids du nouveau fichier. Calcule la différence (les Go économisés). Ajoute une ligne dans le fichier `/Volumes/video/Enfants/Films/Optimisation_Log.md` avec la date, le nom du film, le poids de départ, le poids final, et l'économie (ex: `echo "- 2026-08-30 : **Dragons** (9.4 Go -> 2.0 Go) = **7.4 Go d'économie**" >> ...`).
>
> Préviens-moi par message (send_message) quand toutes ces étapes sont validées."

## 4. Finalisation

Quand le sous-agent vous prévient de la réussite, supprimez l'ancien fichier lourd du NAS et passez au film suivant si vous étiez en mode Batch.
