#!/usr/bin/env bash
set -euo pipefail

set -u

SOURCE="all"
TYPE="movie"
SORT="seeders"
LIMIT="50"
QUALITY=""
CODEC=""

usage() {
  cat >&2 <<'HELP'
Usage: search.sh [options] <recherche>

Options:
  --source magnetz|torrentclaw|all   Source de recherche (all par défaut)
  --type movie|show                  Type TorrentClaw (movie par défaut)
  --sort relevance|seeders|year|rating|added
  --limit N                          Nombre maximal de résultats TorrentClaw
  --quality 480p|720p|1080p|2160p   Résolution exacte TorrentClaw
  --codec x265|x264|av1              Codec vidéo TorrentClaw
  -h, --help                         Afficher cette aide
HELP
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) [[ $# -ge 2 ]] || usage; SOURCE="$2"; shift 2 ;;
    --type) [[ $# -ge 2 ]] || usage; TYPE="$2"; shift 2 ;;
    --sort) [[ $# -ge 2 ]] || usage; SORT="$2"; shift 2 ;;
    --limit) [[ $# -ge 2 ]] || usage; LIMIT="$2"; shift 2 ;;
    --quality) [[ $# -ge 2 ]] || usage; QUALITY="$2"; shift 2 ;;
    --codec) [[ $# -ge 2 ]] || usage; CODEC="$2"; shift 2 ;;
    -h|--help) usage ;;
    --) shift; break ;;
    -*) echo "Option inconnue: $1" >&2; usage ;;
    *) break ;;
  esac
done

QUERY="$*"
[[ -n "$QUERY" ]] || usage
[[ "$SOURCE" =~ ^(magnetz|torrentclaw|all)$ ]] || usage
[[ "$TYPE" =~ ^(movie|show)$ ]] || usage
[[ "$SORT" =~ ^(relevance|seeders|year|rating|added)$ ]] || usage
[[ "$LIMIT" =~ ^[1-9][0-9]*$ ]] || usage
[[ -z "$QUALITY" || "$QUALITY" =~ ^(480p|720p|1080p|2160p)$ ]] || usage
[[ -z "$CODEC" || "$CODEC" =~ ^(x265|x264|av1|h264|h265|hevc|xvid|vp9)$ ]] || usage

search_magnetz() {
  curl -fsSG 'https://magnetz.eu/api/magnets/search' \
    --data-urlencode "query=$QUERY" |
    jq '[
      .data[]? |
      {
        source: "magnetz",
        name,
        size: .human_size,
        seeders,
        leechers,
        magnet: .magnet_link
      }
    ] | sort_by(.seeders // 0) | reverse'
}

# Documentation API : https://torrentclaw.com/llms.txt

search_torrentclaw() {
  local -a headers=(
    -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36'
    -H 'Accept: application/json'
    -H 'X-Search-Source: mcp'
  )
  local config_file="${TORRENTCLAW_CONFIG:-/home/rafache/.config/torrentclaw/.env}"

  if [[ -z "${TORRENTCLAW_API_KEY:-}" && -r "$config_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "$config_file"
    set +a
  fi
  [[ -z "${TORRENTCLAW_API_KEY:-}" ]] || headers+=( -H "Authorization: Bearer $TORRENTCLAW_API_KEY" )

  local -a params=(
    --data-urlencode "q=$QUERY"
    --data-urlencode "type=$TYPE"
    --data-urlencode "sort=$SORT"
    --data-urlencode "limit=$LIMIT"
  )
  [[ -z "$QUALITY" ]] || params+=( --data-urlencode "quality=$QUALITY" )
  [[ -z "$CODEC" ]] || params+=( --data-urlencode "codec=$CODEC" )

  curl -fsSG 'https://torrentclaw.com/api/v1/search' "${headers[@]}" "${params[@]}" |
    jq '[
      (.results // .items // .data.results // .data.items // .data // .torrents // [])[]? |
      . as $content |
      (($content.torrents // [null])[]?) |
      . as $torrent |
      {
        source: "torrentclaw",
        provider: ($torrent.source // null),
        name: ($torrent.rawTitle // $content.title // $content.name // $content.displayName),
        content_title: ($content.title // $content.name // null),
        type: ($content.contentType // $content.type),
        quality: ($torrent.quality // null),
        codec: ($torrent.codec // null),
        quality_score: ($torrent.qualityScore // null),
        size: ($torrent.sizeBytes // $torrent.size // $torrent.sizeHuman // $torrent.human_size // null),
        seeders: ($torrent.seeders // $content.seeders // $content.seeds),
        leechers: ($torrent.leechers // $content.leechers // $content.peers),
        magnet: ($torrent.magnetUrl // $torrent.magnet // $torrent.magnet_link // $torrent.magnetLink),
        info_hash: ($torrent.infoHash // $torrent.info_hash)
      }
    ]'
}

case "$SOURCE" in
  magnetz) search_magnetz ;;
  torrentclaw) search_torrentclaw ;;
  all)
    jq -s 'add' <(search_magnetz) <(search_torrentclaw)
    ;;
esac
