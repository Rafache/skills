#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Skills
for dir in ~/.codex/skills ~/.claude/skills ~/.gemini/antigravity-cli/skills; do
  [ -L "$dir" ] && rm "$dir"
  mkdir -p "$dir"
  for s in "$ROOT"/skills/*; do
    [ -d "$s" ] && ln -sfn "$s" "$dir/"
  done
done

# Agents globaux
mkdir -p ~/.codex ~/.claude ~/.gemini
ln -sf "$ROOT/agents/AGENTS.md" ~/.codex/AGENTS.md
ln -sf "$ROOT/agents/AGENTS.md" ~/.claude/CLAUDE.md
ln -sf "$ROOT/agents/AGENTS.md" ~/.gemini/GEMINI.md

echo "Synchronisation terminée."
