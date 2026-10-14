# Audit

Produire un diagnostic étayé et un plan arbitré avec l'utilisateur. Adapter la profondeur à la taille du dépôt. L'audit se termine quand le parcours, la grille et le plan ont été présentés.

## 1. Cadrer

- Définir le périmètre, les sources accessibles (dépôt, CI, tickets, MR récentes) et les limites.
- Lire documents, manifestes, scripts, tests et CI, y compris les instructions des sous-dossiers concernés.

## 2. Parcours à blanc

Source principale des constats : le premier point de rupture est la prochaine amélioration.

- Dérouler une ou deux tâches représentatives, de préférence un ticket réel récent, avec la seule documentation : besoin → installation → lancement → code → modification → validation → commit → MR → revue → livraison.
- Qualifier chaque étape : **trouvé** (emplacement), **déduit** du code ou de l'historique, **deviné** ou **bloqué**.
- Exécuter les étapes sans effet externe ; noter les autres « non exécuté ».

## 3. Grille

États : ✅ satisfaisant, ⚠️ à renforcer, ❌ écart, ❓ non vérifié, — sans objet. Pas de score global.

| Axe | Question | Signaux à chercher |
| :--- | :--- | :--- |
| **1. Source unique** | Le README mène-t-il partout, et chaque chose a-t-elle une seule source et une seule façon de faire ? | Commandes recopiées avec options divergentes (README, CI, AGENTS.md, skills) ; liens cassés ; plusieurs implémentations d'un même besoin (client HTTP, logs, état) ; migrations inachevées. |
| **2. Démarrage** | Installation et lancement sont-ils reproductibles sans deviner ? | Environnement exact (conteneur, utilisateur, répertoire) ; obtention des accès (VPN, registry, préprod) ; données, comptes de test et services locaux ; services tiers et leur alternative locale ; arborescence commentée ; étape connue d'une seule personne. |
| **3. Process de A à Z** | Le parcours du ticket à la livraison est-il décrit ? | Critères d'acceptation, branches, commits, MR, conditions de fusion, livraison et retour arrière ; environnements (branche, URL, accès, recette) ; ajout d'une dépendance ou d'une variable d'environnement ; convention seulement déduite de l'historique. |
| **4. Validation** | Une commande locale reproduit-elle la CI, bloquante et honnête ? | Faux vert (`allow_failure`, `\|\| true`, tests ignorés, baselines qui grossissent) ; tests instables tolérés ; résultats attendus tirés de l'implémentation ; erreurs sans indication de correction ; retours de revue récurrents non convertis en lint, test ou doc. |
| **5. Connaissance durable** | Contraintes, contrats et décisions sont-ils retrouvables et lisibles par un humain ? | Contrats cachés, zones fragiles, fichiers générés ; emplacement des décisions défini dans CONTRIBUTING ; documents verbeux que personne ne relit. Absence de `docs/` ou d'ADR non fautive en soi. |
| **6. Couche agent** | `AGENTS.md` est-il une carte courte, et le reste justifié ? | Écart au [canevas](../assets/AGENTS.md) par rôle couvert ; lectures obligatoires systématiques, rappels génériques, copie du README, préférences du poste ; fichiers par outil qui ne sont pas un simple renvoi ; skills ou hooks du projet hors du dépôt, liés à un agent, périmés ou sans besoin récurrent ; skill sans procédure documentée équivalente pour le développeur, ou qui recopie les étapes au lieu d'y renvoyer ; provenance des skills tiers. |
| **7. Contrôle humain** | Qu'est-ce qui empêche concrètement l'agent de fusionner, livrer ou affaiblir un contrôle, sans le brider à l'intérieur ? | Protection de branche, revue et CI obligatoires (imposé) vs simple consigne (demandé) ; secrets et accès production hors de portée ; MR de taille relisible, avec preuves ; demandes d'approbation superflues pour des actions locales sûres. Réglages distants non consultables : ❓. |

Qualifier les contrôles : configuré, documenté, exécuté avec succès, en échec, non vérifié. Ne jamais déclencher de livraison ni solliciter un service partagé.

## 4. Restituer

1. Périmètre, sources, contrôles exécutés et limites.
2. Parcours à blanc : étapes et points devinés ou bloquants.
3. Acquis, puis les trois constats les plus importants.
4. Tableau des constats, puis questions ouvertes.

| # | Axe | État | Preuve | Effet concret | Action proposée |
|---|---|---|---|---|---|

- Preuve : `fichier:ligne`, sortie de commande, pipeline daté ou information confirmée. Séparer faits et déductions.
- N'annoncer aucun gain chiffré sans mesure. Réviser le diagnostic face à une preuve nouvelle.

## 5. Planifier

- Lier chaque action à des constats. Chercher le plus petit changement utile, réutiliser l'existant.
- Prioriser : risque avéré (faux vert, frontière non verrouillée) → parcours bloqué → confort.
- Pour une erreur récurrente, préférer un contrôle déterministe (lint, test) ou une ligne de doc à un nouvel outil.
- Ne pas imposer Docker, GitFlow, ADR, plateforme, registre de skills, agent relecteur ou orchestration.
- Arbitrer avec l'utilisateur : **proposé**, **retenu**, **différé**, **écarté**.

| Action | Constats | Priorité | Effort et entretien | Critère de réussite | Décision |
|---|---|---|---|---|---|

Le plan validé alimente le mode [mise en place](mise-en-place.md) uniquement sur demande explicite.
