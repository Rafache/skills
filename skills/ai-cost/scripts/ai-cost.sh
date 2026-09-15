#!/usr/bin/env bash
# ==============================================================================
# ai-cost.sh - Consolidateur de consommation de tokens et coûts IA par projet
# (Codex & Claude Code via ccusage)
# ==============================================================================
set -euo pipefail

FILTER=""
SINCE=""
UNTIL=""
OUTPUT_JSON=false

show_help() {
  cat << 'EOF'
Usage: ai-cost.sh [OPTIONS]

Options:
  -p, --project <nom>     Filtrer sur un projet ou sous-chaîne de chemin
  -s, --since <YYYY-MM-DD>  Filtrer à partir de cette date
  -u, --until <YYYY-MM-DD>  Filtrer jusqu'à cette date
  -j, --json              Sortie JSON brute
  -h, --help              Afficher cette aide
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)
      FILTER="$2"
      shift 2
      ;;
    -s|--since)
      SINCE="$2"
      shift 2
      ;;
    -u|--until)
      UNTIL="$2"
      shift 2
      ;;
    -j|--json)
      OUTPUT_JSON=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Option inconnue: $1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

# 1. Cartographie des projets Claude (~/.claude/projects -> cwd)
claude_map=$(
  for dir in ~/.claude/projects/*; do
    [ -d "$dir" ] || continue
    pname=$(basename "$dir")
    cwd=$(grep -m 1 -h -o '"cwd":"[^"]*"' "$dir"/*.jsonl 2>/dev/null | head -1 | cut -d'"' -f4 || true)
    [ -n "$cwd" ] && printf "%s\t%s\n" "$pname" "$cwd"
  done | jq -Rs 'split("\n") | map(select(length > 0) | split("\t")) | map({(.[0]): .[1]}) | add // {}'
)

# 2. Cartographie des rollouts Codex (~/.codex -> cwd)
codex_map=$(
  find ~/.codex -name "rollout-*.jsonl" 2>/dev/null | while read -r f; do
    fname=$(basename "$f" .jsonl)
    cwd=$(head -n 1 "$f" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p')
    [ -n "$cwd" ] && printf "%s\t%s\n" "$fname" "$cwd"
  done | jq -Rs 'split("\n") | map(select(length > 0) | split("\t")) | map({(.[0]): .[1]}) | add // {}'
)

# 3. Récupération des sessions via ccusage
claude_args=("claude" "session" "-j")
codex_args=("codex" "session" "-j")

if [ -n "$SINCE" ]; then
  claude_args+=("--since" "${SINCE//-/}")
  codex_args+=("--since" "$SINCE")
fi
if [ -n "$UNTIL" ]; then
  claude_args+=("--until" "${UNTIL//-/}")
  codex_args+=("--until" "$UNTIL")
fi

claude_json=$(npx ccusage "${claude_args[@]}" 2>/dev/null | sed -n '/^{/,$p' || echo "{}")
codex_json=$(npx ccusage "${codex_args[@]}" 2>/dev/null | sed -n '/^{/,$p' || echo "{}")

# 4. Traitement et consolidation jq
jq -r -n \
  --argjson claude "$claude_json" \
  --argjson codex "$codex_json" \
  --argjson claude_map "$claude_map" \
  --argjson codex_map "$codex_map" \
  --arg filter "$FILTER" \
  --argjson output_json "$OUTPUT_JSON" \
  '
  def str_rev: explode | reverse | implode;
  def num:
    tostring | str_rev | [scan(".{1,3}")] | map(str_rev) | reverse | join(",");

  def fmt_cost:
    ((. * 100 | round) / 100) as $c |
    "\($c)" |
    if contains(".") then
      split(".") | "\(.[0]).\((.[1] + "00")[0:2])"
    else
      "\(.).00"
    end;

  def empty_stats:
    {sessions: 0, input: 0, output: 0, cache_read: 0, cache_write: 0, total: 0, cost: 0.0};

  ($claude.sessions // []) as $c_sess |
  ($codex.sessions // []) as $x_sess |

  (reduce $c_sess[] as $s ({};
    ($claude_map[$s.projectPath] // $s.projectPath // "Inconnu") as $p |
    .[$p].claude.sessions += 1 |
    .[$p].claude.input += ($s.inputTokens // 0) |
    .[$p].claude.output += ($s.outputTokens // 0) |
    .[$p].claude.cache_read += ($s.cacheReadTokens // 0) |
    .[$p].claude.cache_write += ($s.cacheCreationTokens // 0) |
    .[$p].claude.total += ($s.totalTokens // 0) |
    .[$p].claude.cost += ($s.totalCost // 0.0)
  )) as $claude_proj |

  (reduce $x_sess[] as $s ($claude_proj;
    ($codex_map[$s.sessionFile] // "Inconnu") as $p |
    .[$p].codex.sessions += 1 |
    .[$p].codex.input += ($s.inputTokens // 0) |
    .[$p].codex.output += ($s.outputTokens // 0) |
    .[$p].codex.cache_read += ($s.cacheReadTokens // 0) |
    .[$p].codex.cache_write += ($s.cacheCreationTokens // 0) |
    .[$p].codex.total += ($s.totalTokens // 0) |
    .[$p].codex.cost += ($s.costUSD // 0.0)
  )) as $all_proj |

  [ $all_proj | to_entries[] |
    .key as $proj |
    select($filter == "" or ($proj | ascii_downcase | contains($filter | ascii_downcase))) |
    (empty_stats + (.value.codex // {})) as $codex |
    (empty_stats + (.value.claude // {})) as $claude |
    {
      proj: $proj,
      codex: $codex,
      claude: $claude,
      total: {
        sessions: ($codex.sessions + $claude.sessions),
        input: ($codex.input + $claude.input),
        output: ($codex.output + $claude.output),
        cache_read: ($codex.cache_read + $claude.cache_read),
        cache_write: ($codex.cache_write + $claude.cache_write),
        total: ($codex.total + $claude.total),
        cost: ($codex.cost + $claude.cost)
      }
    }
  ] | sort_by(-.total.cost) as $projects |

  if $output_json then
    $projects
  else
    (reduce $projects[] as $p (
      {codex: empty_stats, claude: empty_stats, all: empty_stats};
      .codex.sessions += $p.codex.sessions |
      .codex.input += $p.codex.input |
      .codex.output += $p.codex.output |
      .codex.cache_read += $p.codex.cache_read |
      .codex.cache_write += $p.codex.cache_write |
      .codex.total += $p.codex.total |
      .codex.cost += $p.codex.cost |
      .claude.sessions += $p.claude.sessions |
      .claude.input += $p.claude.input |
      .claude.output += $p.claude.output |
      .claude.cache_read += $p.claude.cache_read |
      .claude.cache_write += $p.claude.cache_write |
      .claude.total += $p.claude.total |
      .claude.cost += $p.claude.cost |
      .all.sessions += $p.total.sessions |
      .all.input += $p.total.input |
      .all.output += $p.total.output |
      .all.cache_read += $p.total.cache_read |
      .all.cache_write += $p.total.cache_write |
      .all.total += $p.total.total |
      .all.cost += $p.total.cost
    )) as $gt |

    [
      "| Projet | Agent | Sessions | Tokens Entrée | Tokens Sortie | Cache Lecture | Cache Écriture | Total Tokens | Coût USD |",
      "| :--- | :--- | :---: | ---: | ---: | ---: | ---: | ---: | ---: |",
      (
        $projects[] |
        "| **\(.proj)** | Codex | \(.codex.sessions) | \(.codex.input | num) | \(.codex.output | num) | \(.codex.cache_read | num) | \(.codex.cache_write | num) | \(.codex.total | num) | $\(.codex.cost | fmt_cost) |",
        "| | Claude | \(.claude.sessions) | \(.claude.input | num) | \(.claude.output | num) | \(.claude.cache_read | num) | \(.claude.cache_write | num) | \(.claude.total | num) | $\(.claude.cost | fmt_cost) |",
        "| | **Total Projet** | **\(.total.sessions)** | **\(.total.input | num)** | **\(.total.output | num)** | **\(.total.cache_read | num)** | **\(.total.cache_write | num)** | **\(.total.total | num)** | **$\(.total.cost | fmt_cost)** |"
      ),
      "| :--- | :--- | :---: | ---: | ---: | ---: | ---: | ---: | ---: |",
      "| **TOTAL GLOBAL** | **Codex** | **\($gt.codex.sessions)** | **\($gt.codex.input | num)** | **\($gt.codex.output | num)** | **\($gt.codex.cache_read | num)** | **\($gt.codex.cache_write | num)** | **\($gt.codex.total | num)** | **$\($gt.codex.cost | fmt_cost)** |",
      "| | **Claude** | **\($gt.claude.sessions)** | **\($gt.claude.input | num)** | **\($gt.claude.output | num)** | **\($gt.claude.cache_read | num)** | **\($gt.claude.cache_write | num)** | **\($gt.claude.total | num)** | **$\($gt.claude.cost | fmt_cost)** |",
      "| | **TOTAL RÉUNI** | **\($gt.all.sessions)** | **\($gt.all.input | num)** | **\($gt.all.output | num)** | **\($gt.all.cache_read | num)** | **\($gt.all.cache_write | num)** | **\($gt.all.total | num)** | **$\($gt.all.cost | fmt_cost)** |"
    ] | join("\n")
  end
  '
