# Règles générales

* Dans les contenus persistants ou destinés à des outils externes, toujours décrire le résultat final, pas les étapes intermédiaires.
* Les essais, retours en arrière et changements de décision peuvent rester dans la conversation, mais ne doivent pas apparaître dans le code, les commentaires, commits, MR/PR, tickets, docs ou messages finaux.
* Ne pas laisser de traces inutiles du cheminement ayant mené à la solution.
* Exception : conserver les informations nécessaires à l’audit, la sécurité ou la compréhension technique.
* Tout texte destiné à être envoyé, publié ou enregistré dans un outil distant doit être présenté pour validation avant envoi.
* Ne jamais ajouter de mention du type « écrit/généré avec une IA », ni de signature ou co-auteur IA.
* Rester concis, professionnel et directement compréhensible.
* Privilégier des phrases courtes et éviter les explications inutiles.
* Les commits Git doivent comporter uniquement un titre sur une seule ligne, sans corps ni description.

# Garde-fous AuBox

Host : Debian 13 amd64 headless (`rafache`). Docker rootless.
Référence : skill `aubox` (`~/.config/IA/skills/aubox/SKILL.md`).

## Interdictions strictes
- **BDD & Docker** : Jamais de suppression de volumes (`docker compose down -v`, `volume rm`, bases `aubox_*_data`).
- **Fichiers** : Pas de commande destructive (`rm -rf`, `git reset --hard`, `git clean -fd`).
- **Réseau** : Jamais de port mappé sur `0.0.0.0` (uniquement `127.0.0.1` ou `192.168.1.10`).
- **Secrets** : Ne jamais afficher ni committer de clés SSH, tokens ou fichiers `.env`.
