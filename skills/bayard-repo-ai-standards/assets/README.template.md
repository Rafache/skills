# {{NOM_PROJET}}

{{ROLE_DU_PROJET_EN_UNE_PHRASE}}

<!-- Canevas : adapter à la stack réelle, supprimer les rubriques sans objet, puis ce commentaire.
Le README décrit : rôle, structure, démarrage, commandes. Il ne recopie ni les règles de
CONTRIBUTING, ni les variables du fichier `.dist`, ni les valeurs des fichiers de config.
Aucun secret, aucun lien vers un fichier inexistant. -->

## Rôle du projet

**Consommateurs**

- {{QUI_UTILISE_LE_PROJET_ET_POUR_QUOI}}

**Fonctionnement**

- {{FLUX_PRINCIPAUX_AUTHENTIFICATION_DONNEES_SERVICES}}

{{RENVOI_VERS_DOCS_SI_UTILE}}

## Stack technique

- {{LANGAGE_FRAMEWORK_VERSIONS}} ;
- {{STOCKAGE_ET_CACHE}} ;
- {{OUTILS_QUALITE_ET_TESTS}} ;
- services externes : {{SERVICES}}.

## Arborescence

<!-- Toutes les entrées versionnées du premier niveau (`git ls-files | cut -d/ -f1 | sort -u`),
un second niveau seulement quand il aide à s'orienter, et les fichiers locaux utiles marqués
« (local, non versionné) ». Un commentaire court par ligne : ce que c'est, pas quand le lire. -->

```text
.
├── {{DOSSIER}}/                  # {{ROLE}}
├── {{FICHIER_CONFIG_QUALITE}}    # {{ROLE}}
├── {{FICHIER}}.dist              # Modèle de configuration
├── {{FICHIER_LOCAL}}             # Configuration et secrets (local, non versionné)
├── AGENTS.md                     # Règles des agents IA
├── CONTRIBUTING.md               # Guide de contribution
└── README.md                     # Ce fichier
```

## Démarrer en local

Prérequis : {{OUTILS_ET_VERSIONS}}.

**Fichiers locaux**

- `{{FICHIER_LOCAL}}` : obligatoire, à créer depuis `{{FICHIER}}.dist`. Il est ignoré par Git.
- `{{FICHIER_OVERRIDE}}` : facultatif, ignoré par Git. Il adapte le poste (port, réseau) sans toucher la configuration commune.

**Installation**

```sh
{{COMMANDES_D_INSTALLATION_DANS_L_ORDRE}}
```

{{URL_LOCALE_ET_DONNEES_DE_TEST}}

{{ENVIRONNEMENT_D_EXECUTION_DES_COMMANDES}}

## Configuration

La configuration est lue depuis `{{FICHIER_LOCAL}}`. Le fichier [`{{FICHIER}}.dist`]({{FICHIER}}.dist) liste toutes les variables et décrit leur rôle.

## {{ACCEDER_OU_COMMANDES}}

{{EXEMPLE_D_APPEL_OU_COMMANDES_UTILES_ET_URL_DE_LA_DOC}}

## Vérifier une modification

```sh
{{COMMANDE_VALIDATION}}  # {{CONTROLES_EXECUTES}}
```

{{DIFFERENCES_ENTRE_LOCAL_ET_CI}}

## Contribuer

Les développeurs peuvent contribuer au projet :

- en ajoutant des fonctionnalités ;
- en corrigeant des bugs ;
- en faisant évoluer l'existant (refactorisation, performance, dépendances, documentation).

Chaque contribution part d'un ticket et passe par une Merge Request vers `{{BRANCHE_PRINCIPALE}}`. Elle doit suivre strictement le [guide de contribution](CONTRIBUTING.md), qui fixe :

- la procédure, du ticket au déploiement, et les rôles de chacun ;
- les règles sur les branches, le code, les vérifications, les commits et les Merge Requests.

Les agents IA suivent en plus [AGENTS.md](AGENTS.md). La CI est décrite dans [`{{FICHIER_CI}}`]({{FICHIER_CI}}).
