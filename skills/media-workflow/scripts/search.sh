#!/usr/bin/env bash
set -euo pipefail

QUERY="${*:-}"
[[ -n "$QUERY" ]] || { echo "Usage: $0 <recherche>" >&2; exit 64; }

curl -fsSG 'https://magnetz.eu/api/magnets/search' \
  --data-urlencode "query=$QUERY" |
jq '[
  .data[]? |
  {
    name,
    size: .human_size,
    seeders,
    leechers,
    magnet: .magnet_link
  }
] | sort_by(.seeders // 0) | reverse'
