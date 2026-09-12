# Nommage & Rangement Synology

## Conventions de nommage
- **Film** : `Titre.Officiel.Annee.<FRENCH|VOSTFR>.<Resolution>.<CodecAudio>.<CodecVideo>.mkv`
  - Exemple : `Minions.And.Monsters.2026.FRENCH.1080p.AAC.x265.mkv`
- **Série** : `Titre.Officiel.SxxExx.<FRENCH|VOSTFR>.<Resolution>.<CodecAudio>.<CodecVideo>.mkv`
  - Exemple : `Asterix.Le.Combat.des.Chefs.S01E05.FRENCH.1080p.EAC3.x265.mkv`
  - Multi-épisodes : `S01E01-E02`
- **Langue** : `FRENCH` si audio français présent ; `VOSTFR` si audio VO + sous-titres FR.

## Arborescence Synology
```text
/mnt/ds716/video/
├── downloads/
├── Enfants/
│   ├── Films/
│   └── Series/<Titre.Officiel>/
└── Adulte/
    ├── Films/
    └── Series/<Titre.Officiel>/
```

## Directives
- Épisodes de série directement dans le dossier série (pas de sous-dossier saison).
- Demander validation en cas d'ambiguïté `Enfants` vs `Adulte`.
- Conserver les permissions existantes du NAS.
