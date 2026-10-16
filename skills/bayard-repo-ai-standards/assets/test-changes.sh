#!/bin/sh
# Lists assertions removed or changed in tests that already existed before the merge request.
# A legitimate refactor may do this: the job warns, the reviewer checks each one.
# Usage: test-changes.sh [base]   (default: $CI_MERGE_REQUEST_DIFF_BASE_SHA)
set -eu

base="${1:-${CI_MERGE_REQUEST_DIFF_BASE_SHA:?base commit required}}"
status=0

for file in $(git diff --name-only --diff-filter=MD "$base" HEAD -- 'tests/'); do
  git diff --unified=0 --no-color --no-ext-diff "$base" HEAD -- "$file" | awk -v file="$file" '
    /^@@ / { split($2, pos, ","); line = substr(pos[1], 2) - 1; next }
    /^---|^\+\+\+/ { next }
    /^-/ {
      line++
      text = substr($0, 2)
      if (text ~ /assert[A-Za-z]*\(|expect[A-Za-z]*\(|->with\(|willReturn|willThrow/) {
        printf "%s:%d: assertion supprimée ou modifiée\n    %s\n", file, line, text
        found = 1
      }
    }
    END { exit found ? 1 : 0 }
  ' || status=1
done

if [ "$status" -ne 0 ]; then
  echo ""
  echo "Des assertions de tests existants ont changé. Vérifier que l'attendu a vraiment changé"
  echo "et le justifier dans la MR ; ne jamais adapter un test pour faire passer le code."
  echo "Voir CONTRIBUTING.md, rubrique Tests."
fi
exit "$status"
