# Optimisation x265

```bash
scripts/optimize.sh [options] '<fichier_source>' ['<fichier_destination>']
```

## Options & Directives
- **Lancement** : Tâche de fond obligatoire, 1 par 1.
- **Préréquis** : Exécuter `scripts/probe.sh` avant pour inspecter les flux.
- **Vidéo** : `-c 22` (défaut), `-p medium` (défaut). Sortie MKV.
- **Audio** :
  - `-a eac3` : Obligatoire si la piste est en DTS, DTS-HD ou TrueHD.
  - `-a copy` : Défaut (conserver EAC3, AC3, AAC existants).
- **Garde-fous** :
  - Si source déjà HEVC/x265 ou AV1 : alerter sur le gain minime avant encodage.
  - Si résolution HDR/Dolby Vision : vérifier la préservation des métadonnées.
  - Ne jamais écraser la source.
