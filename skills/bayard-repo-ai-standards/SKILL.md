---
name: bayard-repo-ai-standards
description: Audite un dépôt puis met en place les pratiques retenues pour que développeurs et agents y contribuent de A à Z sous contrôle humain. À utiliser pour évaluer ou outiller un dépôt (README, CONTRIBUTING, AGENTS.md, configuration, template de MR).
---

# Standards IA d'un dépôt

Exécuter uniquement le mode demandé. Sans plan validé, commencer par l'audit des axes concernés.

## Principes

- **Pratiques classiques d'abord** : README, CONTRIBUTING, AGENTS.md, fichier `.dist`, CI, `docs/`. Toute couche ajoutée (skill, hook, MCP) résout un problème observé [1].
- **Une information, un endroit** : renvoyer vers la source (fichier de config, manifeste, CI) sans recopier ses valeurs.
- **Chaque fichier a un rôle** : le README décrit, CONTRIBUTING fixe le process, AGENTS.md oriente et pose les garde-fous, le `.dist` porte la configuration, `docs/` ne garde que le non standard.
- **Renvois conditionnels** : dire quand consulter un fichier, jamais imposer de tout lire [4].
- **Process écrit de A à Z**, identique pour le développeur et l'agent [2].
- **Liberté à l'intérieur, verrou à la frontière** : l'agent modifie et vérifie librement ; commit, fusion et livraison restent au développeur, garantis par la plateforme quand c'est possible [3].
- **Corriger le système** : un retour de revue récurrent devient un lint, un test ou une ligne de doc [2].
- **Effet plutôt que présence** : juger ce qu'un fichier permet, pas sa longueur.

## Modes

| Mode | Déclencheur | Référence |
| :--- | :--- | :--- |
| **Audit** | Évaluer un dépôt ; produit un diagnostic et un plan arbitré. | [audit.md](references/audit.md) |
| **Mise en place** | Appliquer les actions retenues d'un plan validé. | [mise-en-place.md](references/mise-en-place.md) |
| **Vérifier GitLab** | Contrôler en lecture seule protections, fusion et CI. | `scripts/check-gitlab.sh` · [gitlab.md](references/gitlab.md) |

## Canevas

[README](assets/README.template.md) · [CONTRIBUTING](assets/CONTRIBUTING.template.md) · [AGENTS.md](assets/AGENTS.template.md) · [fichier `.dist`](assets/env.dist.template) · [template de MR](assets/merge-request.template.md) · [scripts de CI](assets/diff-integrity.sh) ([assertions](assets/test-changes.sh)) · [skill de projet](assets/SKILL.template.md)

## Garde-fous

- Audit : ne modifier ni le dépôt, ni ses branches, ni ses environnements, ni ses services.
- N'exécuter que des commandes sans effet externe, dont la cible est connue ; sinon noter « non exécuté ».
- Ne jamais afficher ni recopier de secret ; ne pas lire dumps, dépendances installées ni artefacts de build.
- Ne jamais committer, pousser, ouvrir de MR ni modifier un paramètre distant sans demande explicite.
- N'écrire que des informations vérifiées ou confirmées par l'utilisateur.

## Sources

1. Patrick Debois, *Coding Agents Don't Scale Themselves*, AI Native DevCon London 2026.
2. Ryan Lopopolo, *Harness Engineering*, AI Native DevCon London 2026.
3. Oleg Selajev, *Docker Sandboxes For Agents*, AI Native DevCon London 2026.
4. OpenAI, [Rethinking skills and prompts for GPT-6 Astra](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).
