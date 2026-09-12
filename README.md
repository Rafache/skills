# Configuration IA (Agents & Skills)

Dépôt centralisant les compétences (*skills*) et instructions d'agents pour **Codex CLI**, **Claude Code** et **Antigravity / Gemini CLI**.

## Structure

```text
agents/
├── agents/                  # Configuration globale unique
│   └── AGENTS.md            # Source unique pour tous les agents
├── skills/                  # Compétences / workflows spécialisés
│   ├── aubox/
│   │   └── SKILL.md
│   ├── bayard-vpn/
│   │   └── SKILL.md
│   └── movie-tool/
│       ├── SKILL.md
│       ├── references/
│       └── scripts/
└── scripts/
    ├── stealth-init.js      # Script d'injection furtivité pour navigateur headless
    └── sync.sh              # Synchronisation des symlinks vers les différents outils
```

## Synchronisation

Pour déployer / mettre à jour les liens symboliques :

```bash
./scripts/sync.sh
```

Les liens créés pour les agents globaux sont :
- `~/.codex/AGENTS.md` -> `agents/AGENTS.md`
- `~/.claude/CLAUDE.md` -> `agents/AGENTS.md`
- `~/.gemini/GEMINI.md` -> `agents/AGENTS.md`
