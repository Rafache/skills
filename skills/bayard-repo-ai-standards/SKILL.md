---
name: bootstrap-ai
description: Audite un dépôt puis met en place les pratiques retenues pour que développeurs et agents y contribuent de A à Z sous contrôle humain. À utiliser pour évaluer ou outiller un dépôt (README, CONTRIBUTING, AGENTS.md, CI).
---

# Bootstrap IA d'un dépôt

## Philosophie

Un dépôt clair pour un développeur l'est aussi pour un agent : les bonnes pratiques historiques suffisent, sans usine IA à côté [1]. L'agent exécute ; le développeur reste le pilote et le garde-fou.

- **Simplicité** : fichiers et process connus (README, CONTRIBUTING, AGENTS.md, manifeste, CI, docs). Chaque couche ajoutée (skill, hook, wrapper, MCP, fichier par outil) résout un problème observé.
- **Une seule source de vérité** : une information, un endroit ; une façon de faire. Le code guide aussi l'agent : deux manières de faire la même chose l'égarent [2].
- **Process explicite de A à Z** : ce qui n'est pas écrit n'existe pas pour un agent [2]. Même process pour le développeur et l'agent ; un skill de projet renvoie à une procédure documentée.
- **Liberté à l'intérieur, verrou à la frontière** : l'agent modifie, teste et construit librement ; commit, fusion et livraison restent au développeur, garantis par la plateforme, car une consigne n'est pas une barrière [3]. La prudence écrite en excès freine sans protéger [4].
- **Corriger le système, pas seulement le code** : un retour de revue récurrent devient un test, un lint ou une ligne de documentation [2].
- **Effet plutôt que présence** : juger ce qu'un fichier permet, pas son existence ni sa longueur. L'existant peut suffire.

## Objectif

Répondre à une question : *un nouvel arrivant, humain ou agent, peut-il livrer un changement de A à Z avec le seul dépôt, prouver qu'il est correct, sous le contrôle du développeur ?* Distinguer exigence de l'équipe, contrat technique et recommandation de ce skill. Exécuter uniquement le mode demandé.

## Modes

| Mode | Déclencheur | Référence |
| :--- | :--- | :--- |
| **Audit** | Évaluer, challenger un dépôt. Produit un diagnostic et un plan arbitré. | [audit.md](references/audit.md) |
| **Mise en place** | Appliquer les actions retenues d'un plan validé. | [mise-en-place.md](references/mise-en-place.md) |

Sans plan validé, commencer par l'audit, au moins sur les axes concernés.

Canevas pour illustrer ou rédiger une proposition : [AGENTS.md](assets/AGENTS.md), [README.md](assets/README.md), [CONTRIBUTING.md](assets/CONTRIBUTING.md), [skill de projet](assets/skill-projet.md).

## Garde-fous

- Audit : ne pas modifier le dépôt, ses branches, ses environnements ou ses services.
- N'exécuter que des commandes sans effet externe, dont la cible est connue. Sinon, noter « non exécuté ».
- Ne pas lire secrets, dumps, dépendances installées ni artefacts de build.
- Ne jamais committer, pousser, ouvrir de MR ni modifier un paramètre distant sans demande explicite.
- N'écrire dans le dépôt que des informations vérifiées ou confirmées par l'utilisateur.

## Sources

1. Patrick Debois, *Coding Agents Don't Scale Themselves*, AI Native DevCon London 2026 : « Everything that's good for you that we've been advocating for years on good engineering practices is actually good for agents. »
2. Ryan Lopopolo, *Harness Engineering*, AI Native DevCon London 2026 : « I never want to give the same review feedback twice. »
3. Oleg Selajev, *Docker Sandboxes For Agents*, AI Native DevCon London 2026.
4. OpenAI, [Rethinking skills and prompts for GPT-6 Astra](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).
