#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 <fichier>" >&2; exit 64; }

exec ffprobe -v error -show_format -show_streams -of json "$1"
