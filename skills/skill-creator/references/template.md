# Templates de Skill

## 1. Squelette `SKILL.md` (Routeur racine)

```markdown
---
name: <nom-du-skill>
description: <Action principale concise>. À utiliser lors de <condition de déclenchement précise>.
---

# <Titre du Skill>

<1 phrase résumant l'objectif. Rappeler d'exécuter uniquement les étapes demandées.>

## Directives d'orchestration
- **Principe clé 1** : Directive impérative sans justification.
- **Principe clé 2** : Outils autorisés ou interdits (ex. pas de scripts ad-hoc).
- **Garde-fous** : Ce qui ne doit jamais être fait sans accord préalable.

## Actions & Commandes

| Action | Commande / Outil | Directive & Référence |
| :--- | :--- | :--- |
| **<Action 1>** | `<commande 1>` | Directive immédiate. |
| **<Action 2>** | `<commande 2>` | Voir détails : [doc-action-2.md](references/doc-action-2.md). |

## Règles de validation
- Critère précis marquant la fin de la tâche (*Definition of Done*).
- Vérification locale obligatoire avant de conclure.
```

---

## 2. Squelette sous-doc (`references/<sujet>.md`)

```markdown
# <Sujet Spécifique>

## Directives & Paramètres
- **Règle 1** : Valeurs obligatoires, formats imposés.
- **Règle 2** : Comportement en cas d'erreur ou d'ambiguïté.

## Syntaxe ou Masque
```text
<format-strict-ou-code>
```

## Garde-fous spécifiques
- Limites strictes et points d'attention.
```
