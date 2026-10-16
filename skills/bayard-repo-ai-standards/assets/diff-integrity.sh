#!/bin/sh
# Fails when the merge request adds a way around a quality control.
# Usage: diff-integrity.sh [base]   (default: $CI_MERGE_REQUEST_DIFF_BASE_SHA)
set -eu

base="${1:-${CI_MERGE_REQUEST_DIFF_BASE_SHA:?base commit required}}"

git diff --unified=0 --no-color --no-ext-diff "$base" HEAD | awk '
function flag(msg) { printf "%s:%d: %s\n    %s\n", file, line, msg, text; found = 1 }

/^\+\+\+ / { file = substr($0, 7); next }
/^--- / { next }
/^@@ / {
  split($3, pos, ",")
  line = substr(pos[1], 2) - 1
  next
}
/^-/ {
  if (file ~ /(^|\/)phpstan\.neon(\.dist)?$/ && match($0, /level:[ \t]*[0-9]+/)) {
    old_level = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", old_level)
  }
  next
}
/^\+/ {
  line++
  text = substr($0, 2)

  if (file ~ /\.php$/ && text ~ /phpcs:(ignore|disable)|@?phpstan-ignore/)
    flag("contrôle désactivé dans le code")

  if (file ~ /(^|\/)tests?\// && file ~ /\.php$/ && text ~ /markTest(Skipped|Incomplete)/)
    flag("test désactivé")

  if (file ~ /\.[jt]sx?$/ && (file ~ /\.(spec|test)\.[jt]sx?$/ || file ~ /(^|\/)(tests?|__tests__)\//) \
      && text ~ /(test|it|describe)(\.describe)?\.(skip|only|fixme)\(|(^|[^A-Za-z])[xf](it|describe)\(/)
    flag("test désactivé ou isolé")

  if (file ~ /(^|\/)phpcs\.baseline\.xml$/ && text ~ /<violation/)
    flag("nouvel écart ajouté à la baseline, qui ne doit que rétrécir")

  if (file ~ /(^|\/)\.?phpcs\.xml(\.dist)?$/ && text ~ /<exclude|severity="0"/)
    flag("règle PHPCS désactivée ou exclusion ajoutée")

  if (file ~ /(^|\/)phpstan\.neon(\.dist)?$/) {
    if (text ~ /ignoreErrors|excludePaths/)
      flag("erreurs PHPStan ignorées ou chemins exclus")
    if (match(text, /level:[ \t]*[0-9]+/)) {
      new_level = substr(text, RSTART, RLENGTH); gsub(/[^0-9]/, "", new_level)
      if (old_level != "" && new_level + 0 < old_level + 0)
        flag("niveau PHPStan abaissé de " old_level " à " new_level)
    }
  }
}
END {
  if (found) {
    print ""
    print "La MR contourne un contrôle qualité. Corriger la cause plutôt que désactiver le contrôle."
    print "Si le contournement est justifié, le faire valider par un humain dans une MR dédiée."
    print "Voir CONTRIBUTING.md, rubrique Développer."
    exit 1
  }
}
'
