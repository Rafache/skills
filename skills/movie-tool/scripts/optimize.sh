#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'HELP' >&2
Usage: optimize.sh [options] <fichier_source> [fichier_destination]

Options:
  -a, --audio <copy|eac3|aac>   Codec audio (défaut: copy)
                                - eac3: Dolby Digital Plus (640k), recommandé pour DTS/TrueHD
                                - aac: AAC (384k)
                                - copy: recopie sans réencodage
  -c, --crf <int>               CRF vidéo x265 (défaut: 22)
  -p, --preset <nom>            Preset x265 (défaut: medium)
  -h, --help                    Afficher cette aide
HELP
  exit 64
}

AUDIO_CODEC="copy"
VIDEO_CRF="22"
VIDEO_PRESET="medium"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--audio)
      [[ $# -ge 2 ]] || usage
      AUDIO_CODEC="$2"
      shift 2
      ;;
    -c|--crf)
      [[ $# -ge 2 ]] || usage
      VIDEO_CRF="$2"
      shift 2
      ;;
    -p|--preset)
      [[ $# -ge 2 ]] || usage
      VIDEO_PRESET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "Option inconnue: $1" >&2
      usage
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

[[ ${#POSITIONAL[@]} -ge 1 ]] || usage

INPUT="${POSITIONAL[0]}"
OUTPUT="${POSITIONAL[1]:-${INPUT%.*}.x265.mkv}"

[[ -f "$INPUT" ]] || {
  echo "Erreur: Fichier source introuvable: $INPUT" >&2
  exit 66
}

if [[ "$INPUT" == "$OUTPUT" ]]; then
  echo "Erreur: Le fichier de sortie ne doit pas écraser la source" >&2
  exit 65
fi

AUDIO_OPTS=()
case "$AUDIO_CODEC" in
  copy)
    AUDIO_OPTS=(-c:a copy)
    ;;
  eac3)
    AUDIO_OPTS=(-c:a eac3 -b:a 640k)
    ;;
  aac)
    AUDIO_OPTS=(-c:a aac -b:a 384k)
    ;;
  *)
    echo "Erreur: Codec audio non supporté: $AUDIO_CODEC (valeurs autorisées: copy, eac3, aac)" >&2
    exit 67
    ;;
esac

START=$(date +%s)

set +e
ffmpeg -hide_banner -v error -stats \
  -i "$INPUT" \
  -map 0:v:0 -c:v libx265 -crf "$VIDEO_CRF" -preset "$VIDEO_PRESET" \
  -map 0:a? "${AUDIO_OPTS[@]}" \
  -map 0:s? -c:s copy \
  -map_metadata 0 -map_chapters 0 \
  "$OUTPUT"
STATUS=$?
set -e

DURATION=$(($(date +%s) - START))
echo "OPTIMIZE_SUMMARY|duration_seconds=$DURATION|exit_code=$STATUS|audio_codec=$AUDIO_CODEC|output=$OUTPUT"

exit "$STATUS"
