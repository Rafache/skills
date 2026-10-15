# Mise en place

Appliquer toutes les actions **retenues** du plan, les vérifier, puis remettre l'ensemble à l'utilisateur pour revue. Rien n'est committé sans sa demande.

## Préparer

- Repartir du plan validé. Sans plan, auditer d'abord les axes concernés.
- Créer une branche dédiée depuis la branche principale à jour. Mettre de côté (`git stash`) le travail en cours de l'utilisateur plutôt que l'écraser, et le signaler.
- Regrouper dès le départ les questions dont les réponses manquent ; ne s'interrompre ensuite que pour une vraie décision.

## Rédiger

- Modifier l'existant avant de créer un fichier. Diff minimal, sans reformater le reste. Conserver les règles propres au projet.
- Partir des canevas et les adapter à la stack réelle : [README](../assets/README.template.md), [CONTRIBUTING](../assets/CONTRIBUTING.template.md), [AGENTS.md](../assets/AGENTS.template.md), [fichier `.dist`](../assets/env.dist.template), [template de MR](../assets/merge-request.template.md).
- Remplir chaque champ avec une information vérifiée ou confirmée. Sinon, supprimer la rubrique et la signaler ; ne laisser aucun `{{CHAMP}}` ni commentaire de canevas.
- Répartir l'information selon le rôle de chaque fichier :
  - README : rôle, stack, arborescence complète, démarrage, renvoi vers le `.dist` ;
  - fichier `.dist` : toutes les variables lues par le code, commentées, sans secret ;
  - CONTRIBUTING : procédure, rôles, règles, vérifications, MR, livraison ;
  - AGENTS.md : instructions « contenu, pour <cas> » et règles ;
  - `docs/` : uniquement le non standard, absent des autres fichiers.
- Renvoyer vers la source canonique plutôt que recopier. Supprimer les copies devenues redondantes et les références vers un fichier supprimé.
- Fichiers propres à un outil : un renvoi vers `AGENTS.md` (`@AGENTS.md` ou lien symbolique), rien d'autre.
- Retour de revue récurrent : l'encoder en lint ou test si possible, sinon en une ligne de documentation au bon endroit.
- Ne créer skill, hook, script ou wrapper que si l'action retenue le prévoit. Skill de projet : documenter d'abord la procédure, puis réduire le skill au renvoi, selon le [canevas](../assets/SKILL.template.md).

## S'arrêter seulement pour

- une information introuvable qui change le contenu ;
- un changement qui affaiblirait un contrôle existant (CI, test, baseline) ;
- un paramètre distant (protection de branche, règles de fusion, droits, variables CI) : ne pas le modifier, fournir la procédure exacte ;
- un secret versionné : le signaler, proposer une tâche séparée, ne pas le recopier ;
- des fichiers générés, données ou secrets à toucher.

## Vérifier

- Exécuter chaque commande documentée ou modifiée, si elle est sans effet externe. Sinon, le signaler.
- Vérifier chaque lien et chemin ajouté.
- Comparer l'arborescence du README à `git ls-files | cut -d/ -f1 | sort -u`.
- Charger le fichier `.dist` avec l'outil du projet, ou vérifier sa syntaxe (ex. `php -l`).
- Lancer la recherche de secrets du projet (ex. Gitleaks) sur les fichiers ajoutés.
- Relancer la validation du projet si du code, de la configuration ou la CI a changé.
- Contrôler le critère de réussite de chaque action ; rejouer les étapes du parcours à blanc concernées.

## Remettre

- Par action : statut (**fait**, **partiel** avec le reste à faire, **bloqué**), fichiers modifiés, preuve de vérification.
- Actions laissées à l'utilisateur : paramètres distants, décisions d'équipe, secrets à changer.
- Proposer un découpage en commits, un par sujet ; committer seulement sur demande.
- Sur demande : pousser, puis présenter le texte de la Draft MR pour validation avant de la créer.
