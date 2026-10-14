# {{NOM_PROJET}}

{{ROLE_ET_PERIMETRE_EN_QUELQUES_PHRASES}}

<!-- Canevas : adapter à la stack réelle, supprimer les champs et rubriques sans objet, puis ce commentaire.
Source de référence des commandes, de l'environnement local et des fichiers générés :
les autres documents y renvoient. Aucun secret, aucun lien vers un fichier inexistant.

Structure : arborescence commentée, un ou deux niveaux, seulement les dossiers utiles
pour s'orienter, une ligne de rôle par dossier, dossiers générés signalés. Exemple :
  src/           Code PHP (contrôleurs, services, entités)
  templates/     Gabarits Twig
  assets/        Sources front (JS, SCSS), compilées par Vite
  public/build/  Généré par `npm run build`, ne pas modifier
  tests/         Tests PHPUnit et Playwright

Exemples : « Données : `make fixtures` charge un jeu anonymisé » ;
« Services tiers — plateforme de consentement (CMP) : consentement, `assets/consent/`, clé de préprod via le VPN,
désactivé en local ». Problèmes fréquents : uniquement des blocages réellement rencontrés.
Autres rubriques possibles : fonctionnement spécifique (cache, hors-ligne…), référencement. -->

## Structure

{{STACK}}. Le build produit {{ARTEFACT_ET_EMPLACEMENT}}.

```text
{{ARBORESCENCE_COMMENTEE}}
```

## Démarrage

- Prérequis : {{VERSIONS_ET_OUTILS}}.
- Configuration : {{EXEMPLE_SANS_SECRET_ET_OBTENTION_DES_ACCES}}.

Depuis {{REPERTOIRE}}, dans {{ENVIRONNEMENT_EXECUTION}} :

```sh
{{COMMANDE_INSTALLATION}}
{{COMMANDE_DEMARRAGE}}
```

- Site : {{URL_LOCALE}}.
- Données : {{FIXTURES_OU_DUMP_ANONYMISE_ET_COMMANDE}}.
- Comptes de test : {{COMPTES_DES_FIXTURES_SANS_SECRET}}.
- Services locaux : {{SERVICE_URL_ET_ROLE}} (base, cache, recherche, capture des mails…).

## Commandes

- `{{COMMANDE_VALIDATION}}` : {{CONTROLES_EXECUTES}}, identiques à la CI.
- `{{COMMANDE_BUILD}}` : {{ARTEFACT_PRODUIT}}.
- `{{AUTRE_COMMANDE}}` : {{ROLE_ET_PRECONDITIONS}}.

## Services tiers

| Service | Rôle | Point d'entrée | Condition d'usage | En local |
|---|---|---|---|---|
| {{SERVICE}} | {{ROLE}} | `{{CHEMIN_DANS_LE_CODE}}` | {{CONSENTEMENT_CLE_OU_VPN}} | {{ALTERNATIVE_OU_DESACTIVE}} |

## Problèmes fréquents

- {{SYMPTOME}} : {{CAUSE_ET_SOLUTION}}.

## Contribuer

- [CONTRIBUTING.md](CONTRIBUTING.md) : process de la demande à la livraison, environnements distants.
- [AGENTS.md](AGENTS.md) : instructions pour les agents IA.
- {{DOCUMENTATION_COMPLEMENTAIRE}}
