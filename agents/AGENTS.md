# Communication & Posture
- Rester concis, professionnel et directement compréhensible.
- Privilégier des phrases courtes et éviter les explications inutiles.

# Méthode de travail & Qualité
- **Exploration** : Ne pas lancer de scans exhaustifs de l'hôte (`find /`, diagnostics globaux). Consulter en priorité le skill `aubox`.
- **Édition** : Préférer des modifications chirurgicales, préserver les commentaires existants et ne pas reformater des fichiers entiers sans demande.
- **Validation technique** : Toujours vérifier la syntaxe, les builds ou le statut des services après modification avant de clore la tâche.

# Contributions & Outils distants
- **Validation préalable** : Tout texte destiné à être envoyé, publié ou enregistré dans un outil distant doit être présenté pour validation avant envoi.
- **Résultat final** : Décrire uniquement le résultat final dans les contenus persistants (commits, PR/MR, tickets, docs, code).
- **Commits Git** : Ne jamais committer sans demande explicite de l'utilisateur. Découper ou amender en plusieurs commits si plusieurs sujets distincts sont traités. Titre uniquement sur une seule ligne (*conventional commit*, en anglais), sans corps ni description. .
- **Merge Request** : Ajuste les commits avec --fixup plutôt que d'empiler des correctifs.
- **Signature IA** : Ne jamais mentionner « généré avec une IA », ni signature ou co-auteur IA.

# Environnement local (AuBox)
Host : Debian 13 amd64 headless (`rafache`). Docker standard (groupe docker).
Référence : skill `aubox` (`~/.config/agents/skills/aubox/SKILL.md`).

- **Docker** : Jamais de suppression de volumes (`docker compose down -v`, `volume rm`, bases `aubox_*_data`).
- **Tooling** : Python via `uv`/`uvx`, Node via `nvm` (`npm`/`npx`, Node 24+). Ne jamais installer de runtimes via `apt`.
- **Fichiers** : Pas de commande destructive (`rm -rf`, `git reset --hard`, `git clean -fd`).
- **Réseau** : Jamais de port mappé sur `0.0.0.0` (uniquement `127.0.0.1` ou `192.168.1.10`).
- **Secrets & Fuites** : Ne jamais afficher ni committer de clés SSH, tokens ou fichiers `.env`. Les fichiers de secrets locaux (`~/.config/*/.env`) doivent être en `chmod 600` et sourcés à la volée sans jamais être affichés (`cat`/`echo`). Si un secret apparaît par inadvertance dans un fichier suivi, un diff Git ou une sortie, alerter immédiatement l'utilisateur et neutraliser la fuite avant toute opération distante.
