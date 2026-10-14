# Mise en place

Appliquer toutes les actions **retenues** du plan, les vérifier, puis remettre l'ensemble à l'utilisateur pour revue. Rien n'est commité sans sa demande.

## Préparer

- Repartir du plan validé. Sans plan, auditer d'abord les axes concernés.
- Vérifier l'état du dépôt et demander sur quelle branche travailler.
- Regrouper dès le départ les questions dont les réponses manquent ; ne s'interrompre ensuite que pour une vraie décision.

## Rédiger

- Modifier l'existant avant de créer un fichier. Diff minimal, sans reformater le reste.
- Partir du canevas concerné ([AGENTS.md](../assets/AGENTS.template.md), [README.md](../assets/README.template.md), [CONTRIBUTING.md](../assets/CONTRIBUTING.template.md)) et l'adapter à la stack réelle.
- Remplir chaque champ avec une information vérifiée ou confirmée. Sinon, supprimer la rubrique et la signaler ; ne laisser aucun `{{CHAMP}}` ni commentaire de canevas.
- Renvoyer vers la source canonique plutôt que recopier. Supprimer les copies devenues redondantes.
- Fichiers propres à un outil : un renvoi vers `AGENTS.md` (`@AGENTS.md` ou lien symbolique), rien d'autre.
- Retour de revue récurrent : l'encoder en lint ou test si possible, sinon en une ligne de documentation au bon endroit.
- Message d'erreur ajouté : indiquer la cause et la correction attendue.
- Ne créer skill, hook, script ou wrapper que si l'action retenue le prévoit explicitement.
- Skill de projet : documenter d'abord la procédure (`docs/`) et sa commande du manifeste, puis réduire le skill à son déclencheur et au renvoi, selon le [canevas](../assets/SKILL.template.md). Le versionner dans le dépôt.

## S'arrêter seulement pour

- une information introuvable qui change le contenu ;
- un changement qui affaiblirait un contrôle existant (CI, test, baseline) ;
- un paramètre distant (protection de branche, règles de fusion, droits, variables CI) : ne pas le modifier, fournir la procédure exacte ;
- des fichiers générés, données ou secrets à toucher.

## Vérifier

- Exécuter chaque commande documentée ou modifiée, si elle est sans effet externe. Sinon, le signaler.
- Vérifier chaque lien et chemin ajouté.
- Relancer la validation du projet si du code, de la configuration ou la CI a changé.
- Contrôler le critère de réussite de chaque action ; rejouer les étapes du parcours à blanc concernées.

## Remettre

- Par action : statut (**fait**, **partiel** avec le reste à faire, **bloqué**), fichiers modifiés, preuve de vérification.
- Actions laissées à l'utilisateur : paramètres distants, décisions d'équipe.
- Proposer un découpage en commits, un par sujet ; committer seulement sur demande.
