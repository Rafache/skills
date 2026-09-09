# Communication & Posture
- Rester concis, professionnel et directement compréhensible.
- Privilégier des phrases courtes et éviter les explications inutiles.

# Contributions & Outils distants
- **Validation préalable** : Tout texte destiné à être envoyé, publié ou enregistré dans un outil distant doit être présenté pour validation avant envoi.
- **Résultat final** : Décrire uniquement le résultat final dans les contenus persistants (commits, PR/MR, tickets, docs, code). Aucun historique d'essais ou de cheminement (sauf besoin d'audit/sécurité).
- **Commits Git** : Uniquement un titre sur une seule ligne (*conventional commit*, en anglais), sans corps ni description.
- **Signature IA** : Ne jamais mentionner « généré avec une IA », ni signature ou co-auteur IA.

# Environnement local (AuBox)
Host : Debian 13 amd64 headless (`rafache`). Docker rootless.
Référence : skill `aubox` (`~/.config/agents/skills/aubox/SKILL.md`).

- **BDD & Docker** : Jamais de suppression de volumes (`docker compose down -v`, `volume rm`, bases `aubox_*_data`).
- **Fichiers** : Pas de commande destructive (`rm -rf`, `git reset --hard`, `git clean -fd`).
- **Réseau** : Jamais de port mappé sur `0.0.0.0` (uniquement `127.0.0.1` ou `192.168.1.10`).
- **Secrets** : Ne jamais afficher ni committer de clés SSH, tokens ou fichiers `.env`.
