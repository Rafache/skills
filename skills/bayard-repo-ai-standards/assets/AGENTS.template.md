# Instructions pour les agents

<!-- Canevas : remplacer les champs, supprimer les lignes sans objet, puis ce commentaire.
Une carte, pas un règlement : renvoyer vers les sources existantes,
ne garder ici que le non évident. Pas de préférences personnelles du poste.
« Autorisé sans demande » : uniquement des commandes sans accès à la production
ni à un service partagé.
Exemples : « `docs/database.md` : pour un changement de schéma » ;
« Les tests d'intégration exigent le conteneur `db` démarré ». -->

## Où trouver quoi

- `README.md` : structure, installation, données locales, commandes, services tiers.
- `CONTRIBUTING.md` : process du ticket à la livraison, fichiers protégés, décisions techniques à consulter avant de remettre en cause un choix structurant.
- `{{DOCUMENT}}` : pour {{TYPE_DE_CHANGEMENT}}.

## Contraintes non évidentes

- {{CONTRAINTE_NON_EVIDENTE}}

## Autorisé sans demande

- Modifier le code et la documentation du périmètre demandé.
- Lancer `{{COMMANDE_VALIDATION}}` et `{{AUTRE_COMMANDE_LOCALE}}`.
- Corriger les échecs liés au changement et relancer jusqu'au vert.

## Frontière

- Commit, push, MR, fusion et livraison : sur demande explicite uniquement.
- Ne pas désactiver un test, élargir une exclusion ou une baseline, ni modifier la CI pour obtenir un résultat vert : signaler l'échec.
- Ne pas modifier les fichiers protégés listés dans `CONTRIBUTING.md`.

## Apprendre

- Si un problème non évident risque de piéger la prochaine session, proposer la mise à jour de la documentation concernée.
