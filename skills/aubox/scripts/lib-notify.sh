# AuBox - Notification iPhone via ntfy (https://ntfy.sh), indépendante de Home Assistant.
# Le sujet secret NTFY_TOPIC est défini dans ~/.config/aubox/backup.env.
# Usage : aubox_notify "<titre>" "<message>" [priorité 1-5, défaut 3]

aubox_notify() {
  if [ -z "${NTFY_TOPIC:-}" ]; then
    echo "[!] NTFY_TOPIC absent : notification non envoyée (${1})"
    return 0
  fi
  curl -s -m 15 -o /dev/null -w '%{http_code}' -X POST "${NTFY_SERVER:-https://ntfy.sh}" \
    -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chromium/124.0 Safari/537.36" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg topic "${NTFY_TOPIC}" --arg title "$1" --arg msg "$2" --argjson prio "${3:-3}" \
      '{topic: $topic, title: $title, message: $msg, priority: $prio, tags: ["computer"]}')" \
    | grep -q '^200$' || echo "[!] Notification ntfy impossible (${1})"
}
