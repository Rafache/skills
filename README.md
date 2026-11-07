# Configuration IA (Agents & Skills)

Dépôt centralisant les compétences (*skills*) et instructions d'agents pour **Codex CLI**, **Claude Code** et **Antigravity / Gemini CLI**.

## Structure

```text
agents/AGENTS.md         # Instructions globales, source unique pour tous les agents
skills/<nom>/SKILL.md    # Un skill par dossier (+ scripts/ et references/ si besoin)
scripts/sync.sh          # Liens symboliques vers les dossiers des différents outils
```

## Skills

| Skill | Rôle |
|---|---|
| `ai-cost` | Bilan de consommation de tokens et de coûts IA par projet (Codex, Claude Code) |
| `aubox` | Administration de l'AuBox : Docker, réseau, NAS, sauvegarde, restauration, maintenance, santé |
| `bayard-repo-ai-standards` | Audit et outillage d'un dépôt Bayard pour le travail avec des agents IA |
| `bayard-vpn` | VPN Fortinet Bayard et routage vers les réseaux privés et review apps |
| `freebox` | API locale de la Freebox : équipements du réseau, Wake-on-LAN, état de la connexion |
| `movie-tool` | Films et séries : recherche, téléchargement, encodage x265, renommage, rangement |

## Synchronisation

Pour déployer / mettre à jour les liens symboliques :

```bash
./scripts/sync.sh
```

Chaque skill est lié dans `~/.codex/skills`, `~/.claude/skills`, `~/.gemini/antigravity-cli/skills` et `~/.gemini/config/skills`. Les liens créés pour les agents globaux sont :
- `~/.codex/AGENTS.md` -> `agents/AGENTS.md`
- `~/.claude/CLAUDE.md` -> `agents/AGENTS.md`
- `~/.gemini/GEMINI.md` -> `agents/AGENTS.md`
