---
name: ai-cost
description: Consolide la consommation de tokens et coûts par projet (Codex et Claude Code). À utiliser lors d'une demande de bilan ou coûts IA par projet.
---

# AI Cost

Consolider la consommation de tokens et coûts financiers par projet via `ccusage`.

## Directives d'orchestration
- **Outil exclusif** : Exécuter uniquement `scripts/ai-cost.sh` (`ccusage` ne regroupe pas nativement par projet).
- **Format strict** : Restituer la table Markdown générée (lignes Codex, Claude, Total projet et totaux généraux).
- **Garde-fous** : Ne pas parser manuellement les sessions ou les rollouts.

## Actions & Commandes

| Action | Commande | Directive |
| :--- | :--- | :--- |
| **Bilan global** | `<skill-path>/scripts/ai-cost.sh` | Afficher le tableau consolidé complet. |
| **Filtrer un projet** | `<skill-path>/scripts/ai-cost.sh -p <nom>` | Filtrer sur un nom ou chemin de projet. |
| **Filtrer par date** | `<skill-path>/scripts/ai-cost.sh -s YYYY-MM-DD [-u YYYY-MM-DD]` | Restreindre à une période. |
| **Format JSON** | `<skill-path>/scripts/ai-cost.sh -j` | Sortie brute pour traitement automatisé. |

## Règles de validation
- Tableau Markdown complet retourné avec totaux généraux (Codex, Claude, Réuni).
