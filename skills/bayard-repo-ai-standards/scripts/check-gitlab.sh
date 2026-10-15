#!/usr/bin/env bash
# Vérifie en lecture seule la configuration GitLab du dépôt courant (voir references/gitlab.md).
# Usage : check-gitlab.sh [branche-longue ...]   (défaut : branche par défaut + preprod, prod, develop si elles existent)
# Sortie : une ligne ✅ / ❌ / ⚠️ / ❓ / — par point. Code de sortie 1 si au moins un ❌.
set -uo pipefail

command -v glab >/dev/null || { echo "❓ glab introuvable : configuration GitLab non vérifiée"; exit 0; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "❓ pas dans un dépôt Git"; exit 0; }
cd "$(git rev-parse --show-toplevel)"

exec python3 - "$@" <<'PY'
import json, re, subprocess, sys, os

def api(path):
    r = subprocess.run(["glab", "api", path], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    try:
        return json.loads(r.stdout)
    except ValueError:
        return None

fails = 0
def report(state, msg):
    global fails
    if state == "❌":
        fails += 1
    print(f"{state} {msg}")

project = api("projects/:id")
if project is None:
    print("❓ projet GitLab illisible (glab non authentifié ou droits insuffisants)")
    sys.exit(0)

print(f"Projet : {project.get('path_with_namespace')}")

# Réglages de fusion
def check(key, expected, label):
    if key not in project:
        report("❓", f"{label} : non exposé par l'API")
    elif project[key] == expected:
        report("✅", label)
    else:
        report("❌", f"{label} : attendu {expected!r}, trouvé {project[key]!r}")

check("merge_method", "ff", "Méthode de fusion fast-forward")
check("squash_option", "never", "Squash interdit")
check("only_allow_merge_if_pipeline_succeeds", True, "Pipeline obligatoire")
check("allow_merge_on_skipped_pipeline", False, "Pipeline ignoré non considéré comme réussi")
check("only_allow_merge_if_all_discussions_are_resolved", True, "Discussions résolues obligatoires")
check("remove_source_branch_after_merge", True, "Suppression de la branche source par défaut")

# Branches protégées
protected = api("projects/:id/protected_branches?per_page=100")
if protected is None:
    report("❓", "Branches protégées illisibles")
else:
    wanted = sys.argv[1:]
    if not wanted:
        wanted = [project.get("default_branch") or "main"]
        for b in ("preprod", "prod", "develop"):
            if api(f"projects/:id/repository/branches/{b}") is not None:
                wanted.append(b)
    rules = {p["name"]: p for p in protected}
    for b in wanted:
        rule = rules.get(b)
        if rule is None:
            report("❌", f"Branche {b} non protégée")
            continue
        push = [a["access_level"] for a in rule.get("push_access_levels", [])]
        merge = [a["access_level_description"] for a in rule.get("merge_access_levels", [])]
        if push and all(level == 0 for level in push):
            report("✅", f"{b} : aucun push direct")
        else:
            report("❌", f"{b} : push direct autorisé ({', '.join(a['access_level_description'] for a in rule['push_access_levels'])})")
        if rule.get("allow_force_push"):
            report("❌", f"{b} : force push autorisé")
        else:
            report("✅", f"{b} : force push interdit")
        report("✅" if merge and "No one" not in merge else "❌", f"{b} : fusion par {', '.join(merge) or 'personne'}")

# Tags protégés
tags = api("projects/:id/protected_tags?per_page=100")
if tags is None:
    report("❓", "Tags protégés illisibles")
elif not tags:
    existing = api("projects/:id/repository/tags?per_page=1")
    if existing:
        report("❌", "Aucun tag protégé alors que le dépôt a des tags")
    else:
        report("—", "Aucun tag dans le dépôt : protection des tags sans objet")
else:
    for t in tags:
        who = ", ".join(a["access_level_description"] for a in t.get("create_access_levels", []))
        report("✅", f"Tags {t['name']} : création par {who}")

# Jobs de CI tolérant l'échec
ci = ".gitlab-ci.yml"
if not os.path.exists(ci):
    report("❓", "Pas de .gitlab-ci.yml dans le dépôt")
else:
    job, found = None, []
    for line in open(ci, encoding="utf-8"):
        m = re.match(r"^([A-Za-z0-9_.-][^:\s]*):\s*$", line)
        if m:
            job = m.group(1)
        if re.match(r"^\s+allow_failure:\s*true", line) and job:
            found.append(job)
    if found:
        report("⚠️", f"Jobs en allow_failure: true : {', '.join(found)} — ❌ si l'un d'eux est un contrôle (tests, lint, secrets)")
    else:
        report("✅", "Aucun job en allow_failure: true")

sys.exit(1 if fails else 0)
PY
