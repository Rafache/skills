# Contribuer à {{NOM_PROJET}}

Installation, environnement et commandes : [README.md](README.md).

<!-- Canevas : ne garder que les conventions confirmées par l'équipe, puis ce commentaire.
Un historique de commits n'établit pas seul une règle.
Citer une commande par son nom ; sa définition reste dans le README.
Exemple : « Branche : partir de `develop`, nommer `feat/<ticket>-<sujet>` ».
Contrôles web possibles, à garder seulement s'ils sont pratiqués : navigateurs et
responsive, accessibilité, performance, SEO (métadonnées, URLs, redirections),
tracking et consentement, erreurs console. -->

## Avant de commencer

- Besoin : {{SOURCE_DU_BESOIN_ET_CRITERES_ACCEPTATION}}.
- Rôles : {{RESPONSABILITES_PRODUIT_TECHNIQUE_ET_VALIDATION}}.
- Branche : partir de `{{BRANCHE_BASE}}`, nommer `{{CONVENTION_DE_NOMMAGE}}`.

## Environnements

| Environnement | Alimenté par | URL | Accès | Validé par |
|---|---|---|---|---|
| {{REVIEW_APP_PREPROD_PROD}} | {{BRANCHE_TAG_OU_ACTION}} | {{URL}} | {{COMMENT_OBTENIR_L_ACCES}} | {{ROLE}} |

## Modifier

- {{REGLES_ARCHITECTURE_ET_METIER}}
- Dépendances : {{POLITIQUE_AJOUT_ET_MISE_A_JOUR}} ; lockfiles toujours versionnés.
- Variable d'environnement : l'ajouter à `{{FICHIER_EXEMPLE_ENV}}` sans valeur secrète, la déclarer dans {{EMPLACEMENT_VARIABLES_PAR_ENVIRONNEMENT}}, le signaler dans la MR.
- Fichiers protégés : ne pas modifier à la main les fichiers générés (voir README, rubrique Structure) ni {{DONNEES_A_PRESERVER}}.
- Ajouter ou adapter les tests des comportements modifiés.
- Mettre à jour la documentation concernée.

## Vérifier

- Lancer `{{COMMANDE_VALIDATION}}` ; {{PRECONDITIONS_ET_DIFFERENCES_LOCAL_CI}}.
- Vérification fonctionnelle : sur {{ENVIRONNEMENT_DE_RECETTE}}, contrôler {{CONTROLES_WEB_PRATIQUES}}.
- Preuves à joindre à la MR : {{PREUVES_FONCTIONNELLES_ATTENDUES}}.

## Proposer

- Commits : {{CONVENTION_DE_COMMIT}}.
- MR vers `{{BRANCHE_CIBLE}}`, liée au ticket, avec les preuves. Une MR par sujet, de taille relisible.
- Fusion : {{CONDITIONS_DE_REVUE_ET_DE_FUSION}}.
- L'auteur de la MR répond de son contenu, quel que soit l'outil utilisé pour le produire.
- Un retour de revue qui revient devient une règle de lint, un test ou une ligne de documentation.

## Livrer

- Déclencheur : {{DECLENCHEUR_ET_VALIDATION_PREALABLE}}.
- Migrations et configuration : {{MIGRATIONS_ET_CONFIGURATION}}.
- Après livraison : {{VERIFICATION_ET_RETOUR_ARRIERE}} (ex. purge du cache ou du CDN, logs et erreurs front).

## Décisions techniques

- {{EMPLACEMENT_ET_FORMAT_DES_DECISIONS}}
- Les consulter avant de remettre en cause un choix structurant.
