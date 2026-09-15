#!/usr/bin/env bash
set -euo pipefail

# Documentation API : https://torrentclaw.com/llms.txt

MODE="${1:-}"
shift || true

usage() {
  cat >&2 <<'HELP'
Usage: discover.sh <mode> [options]

Modes: recent, popular, trending, upcoming, streaming-top

Options:
  --locale CODE   Locale TorrentClaw (fr par défaut)
  --limit N       Nombre de résultats (10 par défaut)
  --page N        Page de résultats (1 par défaut)
  --type movie|show|all Filtre popular/upcoming
  --period daily|weekly|monthly Période trending (daily par défaut)
  --service NAME   Service streaming-top (netflix par défaut)
  --country CODE   Pays streaming-top (US par défaut)
  --show-type movie|series Type streaming-top (movie par défaut)
  --format table|json (table par défaut)
  -h, --help      Afficher cette aide
HELP
  exit 64
}

[[ "$MODE" =~ ^(recent|popular|trending|upcoming|streaming-top)$ ]] || usage
LOCALE="fr"
LIMIT="10"
PAGE="1"
TYPE=""
PERIOD="daily"
SERVICE="netflix"
COUNTRY="US"
SHOW_TYPE="movie"
FORMAT="table"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --locale) [[ $# -ge 2 ]] || usage; LOCALE="$2"; shift 2 ;;
    --limit) [[ $# -ge 2 ]] || usage; LIMIT="$2"; shift 2 ;;
    --page) [[ $# -ge 2 ]] || usage; PAGE="$2"; shift 2 ;;
    --type) [[ $# -ge 2 ]] || usage; TYPE="$2"; shift 2 ;;
    --period) [[ $# -ge 2 ]] || usage; PERIOD="$2"; shift 2 ;;
    --service) [[ $# -ge 2 ]] || usage; SERVICE="$2"; shift 2 ;;
    --country) [[ $# -ge 2 ]] || usage; COUNTRY="$2"; shift 2 ;;
    --show-type) [[ $# -ge 2 ]] || usage; SHOW_TYPE="$2"; shift 2 ;;
    --format) [[ $# -ge 2 ]] || usage; FORMAT="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Option inconnue: $1" >&2; usage ;;
  esac
done

[[ "$FORMAT" =~ ^(table|json)$ ]] || usage
headers=(
  -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36'
  -H 'Accept: application/json'
  -H 'X-Search-Source: mcp'
)
CONFIG_FILE="${TORRENTCLAW_CONFIG:-/home/rafache/.config/torrentclaw/.env}"
if [[ -z "${TORRENTCLAW_API_KEY:-}" && -r "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  set +a
fi
[[ -z "${TORRENTCLAW_API_KEY:-}" ]] || headers+=( -H "Authorization: Bearer $TORRENTCLAW_API_KEY" )

curl_args=( --data-urlencode "limit=$LIMIT" --data-urlencode "page=$PAGE" --data-urlencode "locale=$LOCALE" )
[[ -z "$TYPE" || "$TYPE" == "all" ]] || curl_args+=( --data-urlencode "type=$TYPE" )
[[ "$MODE" != "trending" ]] || curl_args+=( --data-urlencode "period=$PERIOD" )
if [[ "$MODE" == "streaming-top" ]]; then
  curl_args+=( --data-urlencode "service=$SERVICE" --data-urlencode "country=$COUNTRY" --data-urlencode "show_type=$SHOW_TYPE" )
fi
JSON=$(curl -fsSG "https://torrentclaw.com/api/v1/$MODE" "${headers[@]}" "${curl_args[@]}" \
  )

if [[ "$FORMAT" == "json" ]]; then
  jq . <<< "$JSON"
else
  jq -r '
    (.results // .items // .data.results // .data.items // .data // .torrents // [])[]? |
    [(.title // .name // .displayName // "?"),
     (.year // "?" | tostring),
     (.contentType // .type // "?"),
     ((.maxSeeders // .seeders // .seeds // "?") | tostring),
     (.createdAt // "" | tostring)] | @tsv
  ' <<< "$JSON" | column -t -s $'\t'
fi
