---
name: skill-creator
description: Guide la conception, l'écriture et l'organisation de skills d'agent selon les standards Astra (progressive disclosure, directives concises).
---

# Créateur de Skills

Concevoir des skills légers, modulaires et sans sur-guidage pour les modèles modernes.

## Directives de Conception (Standard Astra)

1. **Description frontmatter ciblée** :
   - Formule stricte : *Ce que fait le skill + Quand le déclencher*.
   - Proscrire les listes de mots-clés génériques qui provoquent des faux positifs.
   - Longueur maximale recommandée : 1 à 2 phrases courtes.

2. **Divulgation progressive (*Progressive disclosure*)** :
   - `SKILL.md` racine : simple routeur (< 40-50 lignes) listant les actions directes.
   - `references/` : spécifications, formats stricts ou options détaillées (lus à la demande).
   - `scripts/` : scripts déterministes bash/python exécutables.

3. **Style de rédaction : Directives pures** :
   - Phrases courtes à l'impératif ou puces directives.
   - Zéro explication de ce que l'IA sait déjà faire (ex. comment marche `curl`, `git` ou `mkdir`).
   - Zéro justification ou bavardage technique (ex. ne pas expliquer le gain de performance ou la compatibilité).

4. **Autonomie & Garde-fous** :
   - Donner permission d'itérer et vérifier en local jusqu'à complétion.
   - Définir les interdictions absolues (ex. suppression de fichiers, commits sans accord).

## Workflow de Création

1. Définir le nom (kebab-case, court, évocateur, ex. `movie-tool`, `bayard-vpn`).
2. Créer l'arborescence sous `~/.config/agents/skills/<nom>/` :
   - `SKILL.md`
   - `references/` (si workflows complexes ou formats détaillés)
   - `scripts/` (si outillage bash/CLI dédié)
3. Rédiger le contenu selon les modèles : [template.md](references/template.md).
4. Synchroniser les liens symboliques :
   ```bash
   ~/.config/agents/scripts/sync.sh
   ```
5. Valider la syntaxe et vérifier les liens créés dans `~/.codex/`, `~/.claude/`, `~/.gemini/`.
