## Instructions

<!-- Canevas : une ligne par fichier utile à une tâche, au format « contenu, pour <cas> ». Ne pas recopier le README : il décrit, ce fichier oriente. Supprimer ce commentaire. -->

- [README.md](README.md) : rôle du projet, arborescence, installation et commandes, pour comprendre le projet ou le lancer.
- [CONTRIBUTING.md](CONTRIBUTING.md) : flux projet, branches, règles de code, vérifications, commits, MR et déploiement, pour toute contribution.
- [{{MANIFESTE}}]({{MANIFESTE}}) : dépendances et scripts, à lancer {{ENVIRONNEMENT}}, pour vérifier une modification ou changer une dépendance.
- [{{CONFIG_QUALITE}}]({{CONFIG_QUALITE}}) : règles de style et d'analyse, pour une erreur de `{{COMMANDE}}` ou une évolution des règles.
- [{{FICHIER}}.dist]({{FICHIER}}.dist) : variables de configuration, pour toute question de configuration.
- [{{FICHIERS_DOCKER}}]({{FICHIERS_DOCKER}}) : environnement local, pour un problème ou une évolution de l'environnement local.
- [{{FICHIER_CI}}]({{FICHIER_CI}}) : contrôles et livraison, pour un échec de CI ou une évolution du pipeline.
- [{{DOC}}]({{DOC}}) : {{CONTENU}}, pour {{CAS}}.

## Règles

<!-- Adapter les champs ; ajouter les pièges propres au projet (ex. une commande qui vise la production par défaut). Supprimer ce commentaire. -->

- L'agent travaille pour le développeur qui le pilote.
- Prendre de manière autonome les décisions techniques courantes dans le périmètre confié.
- Pour toute modification, travailler sur une branche dédiée. Utiliser un worktree pour les développements importants, après accord du développeur.
- Limiter les modifications au périmètre demandé ; signaler le reste sans le traiter.
- Ne jamais committer ni pousser une branche sans demande explicite du développeur.
- Ne jamais pousser sur `{{BRANCHES_PROTEGEES}}`, passer une MR en Ready, la fusionner, {{PUBLIER}} ou déployer sans confirmation explicite du développeur, ni agir sur un environnement autre que l'environnement local.
- Ne jamais réécrire l'historique de `{{BRANCHES_PROTEGEES}}`. La réécriture d'une branche de MR est autorisée, même si elle a déjà été poussée, selon les règles de `CONTRIBUTING.md`.
- Ne jamais supprimer ou écraser des modifications locales, des fichiers non suivis par Git ou des volumes Docker sans confirmation explicite du développeur.
- Ne jamais déclencher d'action réelle sur un service externe ({{SERVICES_EXTERNES}}) sans confirmation explicite du développeur, y compris indirectement lors de tests locaux.
- Ne jamais afficher, recopier ou publier le contenu de `{{FICHIERS_DE_SECRETS}}` ni aucun secret.
- Présenter pour validation tout texte destiné à être envoyé, publié ou enregistré dans un outil distant, sauf si son contenu et sa destination ont déjà été explicitement approuvés.
- Décrire le résultat final et les choix techniques pertinents dans les contenus persistants (commits, MR, tickets, docs, code), pas le cheminement pour y arriver.
- Avant de coder, proposer les cas de test tirés des critères d'acceptation et attendre la validation du développeur.
- Ne jamais modifier ou supprimer une assertion existante pour faire passer un test : signaler l'écart au développeur.
- Ne jamais contourner une règle, un garde-fou, un test ou un contrôle qualité (désactiver, ignorer, affaiblir). Comprendre pourquoi il bloque et corriger la cause. Si ce n'est pas possible sans contournement, s'arrêter et prévenir le développeur.
- À la fin d'une tâche, résumer les modifications, les vérifications réellement effectuées et les problèmes non résolus. Ne jamais déclarer un test réussi sans l'avoir exécuté.
- En cas de doute sur une question produit ou une action hors périmètre, s'arrêter et demander au développeur.
