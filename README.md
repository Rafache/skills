# Configuration IA (Agents & Skills)

Dépôt centralisant les compétences (*skills*) et instructions d'agents pour **Codex CLI**, **Claude Code** et **Antigravity / Gemini CLI**.

## Structure

```text
IA/
├── agents/                  # Instructions globales et personnalisées
│   ├── CODEX.md             # Instructions globales pour Codex CLI (~/.codex/AGENTS.md)
│   ├── CLAUDE.md            # Instructions globales pour Claude Code (~/.claude/CLAUDE.md)
│   └── GEMINI.md            # Instructions globales pour Gemini (~/.gemini/GEMINI.md)
├── skills/                  # Compétences / workflows spécialisés
│   ├── aubox/
│   │   └── SKILL.md
│   └── media-workflow/
│       ├── SKILL.md
│       └── scripts/
└── scripts/
    └── sync.sh              # Synchronisation des symlinks vers les différents outils
```

## Synchronisation

Pour déployer / mettre à jour les liens symboliques :

```bash
./scripts/sync.sh
```
