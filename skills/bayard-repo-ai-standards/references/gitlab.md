# Configuration GitLab

Verrou de la plateforme : ce que les consignes écrites ne garantissent pas. Vérifier en lecture seule avec [`check-gitlab.sh`](../scripts/check-gitlab.sh) depuis le dépôt ; ne jamais modifier un réglage distant.

## Cible

| Réglage | Chemin GitLab | Valeur attendue |
| :--- | :--- | :--- |
| Branches longues (`main`, branches de déploiement) | Settings → Repository → Protected branches | Protégées ; *Allowed to push and merge* : **No one** ; *Allowed to force push* : désactivé ; *Allowed to merge* : rôle défini, cohérent avec le RACI de CONTRIBUTING |
| Tags de publication | Settings → Repository → Protected tags | Motif couvrant les tags publiés (`*`) ; création réservée aux mainteneurs |
| Méthode de fusion | Settings → Merge requests → Merge method | **Fast-forward merge** |
| Squash | Settings → Merge requests → Squash commits when merging | **Do not allow** |
| Pipeline | Settings → Merge requests → Merge checks | *Pipelines must succeed* coché ; *Skipped pipelines are considered successful* décoché |
| Discussions | Settings → Merge requests → Merge checks | *All threads must be resolved* coché |
| Branche source | Settings → Merge requests → Merge options | *Enable "Delete source branch" option by default* coché |
| Jobs de contrôle | `.gitlab-ci.yml` | Aucun job de contrôle (tests, lint, secrets) en `allow_failure: true` |
| Fichiers générés versionnés | `.gitlab-ci.yml` | Un job les reconstruit et échoue s'ils diffèrent de la version committée |
| Messages de commit | `.gitlab-ci.yml` | Un job vérifie le format des commits de la MR et l'absence de `fixup!` restant |
| Intégrité du diff | `.gitlab-ci.yml` | Un job bloquant refuse les contournements ajoutés par la MR (annotations d'ignore, test PHP ou JS désactivé ou isolé, baseline qui grossit, règle assouplie) ; canevas : [`diff-integrity.sh`](../assets/diff-integrity.sh) |
| Assertions modifiées | `.gitlab-ci.yml` | Un job non bloquant liste les assertions de tests existants supprimées ou modifiées, à justifier dans la MR ; répertoires de tests via `TEST_PATHS` ; canevas : [`test-changes.sh`](../assets/test-changes.sh) |

## Garde-fous

- Lecture uniquement (`glab api` en GET). Sans droit de lecture ou sans `glab` authentifié : état ❓, jamais déduit.
- Écart constaté : le signaler avec le chemin GitLab et la valeur attendue ; la modification reste à l'utilisateur.
- GitLab ne distingue pas un humain de son agent sur un même jeton : ces réglages bornent l'agent autant que son utilisateur. Les règles d'`AGENTS.md` couvrent le reste.
- Approbations obligatoires : fonction payante. Si absente, noter que la revue reste une règle écrite.
