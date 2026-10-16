# Contribuer

Ce guide fixe les règles de contribution, du ticket à la mise en production.

<!-- Canevas : ne garder que les conventions confirmées par l'équipe, puis ce commentaire.
Un historique de commits n'établit pas seul une règle. Citer une commande par son nom ;
sa définition reste dans le manifeste. Renvoyer vers les fichiers de config sans recopier
leurs valeurs (pas de « PSR-12 », pas de « niveau 7 »). Listes courtes à l'impératif. -->

## Procédure

| Étape | Statut du ticket |
|-------|------------------|
| 1. Partir d'un ticket [{{OUTIL_DE_TICKETS}}]({{URL_PROJET}}) qui décrit le besoin et les critères d'acceptation. | `{{STATUT}}` |
| 2. Créer une branche depuis `{{BRANCHE_PRINCIPALE}}`. | |
| 3. Développer et tester la modification. | |
| 4. Ouvrir une Draft MR vers `{{BRANCHE_PRINCIPALE}}`. | `{{STATUT}}` |
| 5. Passer la MR en Ready, puis la fusionner après revue. | |
| 6. {{PUBLIER}}. | `{{STATUT}}` |
| 7. {{DEPLOYER}}. | `{{STATUT}}` |

## Ticket prêt

Avant de créer la branche, vérifier que le ticket contient :

- le besoin, du point de vue de son utilisateur ;
- des critères d'acceptation testables, cas limites compris ;
- {{POINTS_PROPRES_AU_PROJET}} (maquette, analytics, accessibilité, contrat d'API, données…), ou « aucun ».

S'il manque un point, le signaler {{AU_ROLE_PRODUIT}} dans le ticket avant de coder.

## Rôles (matrice RACI)

| Activité | {{ROLE_PRODUIT}} | Développeur | {{EQUIPE_INFRA}} |
|----------|:--:|:--:|:--:|
| Rédiger le ticket et les critères d'acceptation | R/A | C | |
| Trancher une question produit | R/A | C | |
| Trancher un choix technique | I | R/A | |
| Développer, tester et faire la revue de code | I | R/A | |
| Valider le résultat fonctionnel | R/A | C | |
| Fusionner une MR | I | R/A | |
| {{PUBLIER_ET_DEPLOYER}} | I | R/A | C |

> Légende : R : Réalise · A : Approuve · C : Consulté · I : Informé

## Branches

- Format : `features/<sujet-court>` ou `hotfix/<sujet-court>`.
- Le sujet est en anglais. Il peut commencer par l'identifiant du ticket.
- Une branche par sujet.

## Développer

Pour installer et lancer le projet, voir le [README](README.md).

Les scripts utiles sont définis dans [`{{MANIFESTE}}`]({{MANIFESTE}}). Ils s'exécutent {{ENVIRONNEMENT}} :

```sh
{{COMMANDE_TYPE}}
```

**Code**

- Respecter strictement les règles de [`{{CONFIG_STYLE}}`]({{CONFIG_STYLE}}) et de [`{{CONFIG_ANALYSE}}`]({{CONFIG_ANALYSE}}). `{{COMMANDE_FIX}}` corrige le style automatiquement.
- Écrire les commentaires en anglais, seulement quand ils sont nécessaires : expliquer le pourquoi qui ne se déduit pas du code, pas ce que fait le code.
- Ne jamais contourner un contrôle ({{ANNOTATIONS_D_IGNORE}}, règle assouplie dans la configuration) : corriger la cause. Un contournement justifié se valide par un humain dans une MR dédiée.
- {{REGLES_PROPRES_AU_PROJET}}

**Tests**

- Ajouter ou adapter les tests de `{{DOSSIER_TESTS}}` pour chaque changement de comportement.

**{{DONNEES_BUILD_OU_FICHIERS_PROTEGES}}**

- {{REGLES}}

**Documentation**

- Consulter [`{{DOC}}`]({{DOC}}) pour {{CAS}}.
- Mettre à jour ces documents si le fonctionnement décrit change, le README si l'installation change, et `{{FICHIER}}.dist` si la configuration change.
- Ajouter tout nouveau fichier ou dossier de premier niveau à l'arborescence du README et, s'il est utile à une tâche, aux instructions d'[AGENTS.md](AGENTS.md).

## Dette connue et pièges

Ne pas reproduire ces points, ni les corriger au passage d'une autre modification.

- {{DETTE_OU_PIEGE_CONFIRME_ET_RENVOI_VERS_LE_DETAIL}}

## Vérifier

Avant d'ouvrir ou de mettre à jour une MR :

- lancer `{{COMMANDE_VALIDATION}}` ;
- tester ce qui a été touché.

Une modification est terminée quand ces points sont faits. La CI, définie dans [`{{FICHIER_CI}}`]({{FICHIER_CI}}), {{CE_QUE_REJOUE_LA_CI}}.

## Commits

- Format [Conventional Commits](https://www.conventionalcommits.org/fr/) en anglais, sur une ligne.
- Un changement cohérent par commit.

## Merge Requests

**Ouvrir**

- Ouvrir une Draft MR vers `{{BRANCHE_PRINCIPALE}}`, liée au ticket.
- Utiliser le template [Default](.gitlab/merge_request_templates/Default.md) et renseigner chaque rubrique.
- Rédiger le titre en français, comme une phrase produit, sans préfixe Conventional Commits ni identifiant de ticket.

**Passer en Ready**

- Relire le diff.
- Nettoyer l'historique de la branche : un commit par changement cohérent, sans commit de correction. La branche de MR peut être réécrite, même si elle est déjà poussée ; jamais `{{BRANCHES_PROTEGEES}}`.
  Méthode conseillée : `git commit --fixup=<commit>`, puis `git rebase -i --autosquash origin/{{BRANCHE_PRINCIPALE}}` et `git push --force-with-lease`.
- Vérifier que la CI est verte.
- Pour un changement fonctionnel, faire valider le résultat dans la MR.

**Fusionner** seulement après :

- une revue de code manuelle et approfondie ;
- la validation fonctionnelle, si elle s'applique ;
- une CI verte.

## Publier et déployer

1. {{ETAPES_DE_PUBLICATION_ET_DE_DEPLOIEMENT}}
