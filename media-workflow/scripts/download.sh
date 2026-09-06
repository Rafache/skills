#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 && "$1" == magnet:\?* ]] || {
  echo "Usage: $0 'magnet:?xt=...'" >&2
  exit 64
}

START=$(date +%s)

set +e
aria2c \
  --dir=/mnt/ds716/video/downloads \
  --continue=true \
  --seed-time=0 \
  --summary-interval=5 \
  "$1"
STATUS=$?
set -e

DURATION=$(($(date +%s) - START))
echo "DOWNLOAD_SUMMARY|duration_seconds=$DURATION|exit_code=$STATUS"

exit "$STATUS"
