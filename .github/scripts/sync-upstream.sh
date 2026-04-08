#!/usr/bin/env bash
# Sync tracked content from SOURCE_REPO (default branch) into this fork.
# Never applies upstream's .github — this fork keeps only workflows/ and scripts/.
# state.json (issue mirror state) is never overwritten.

set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-ansible-collections/cisco.ios}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
UPSTREAM_URL="https://github.com/${SOURCE_REPO}.git"

# Remove anything under .github/ except workflows/ and scripts/ (fork-owned).
_prune_fork_github() {
  [[ -d .github ]] || return 0
  local path base
  for path in .github/*; do
    [[ -e "$path" ]] || continue
    base=$(basename "$path")
    case "$base" in
      workflows|scripts) ;;
      *)
        git rm -rf "$path" 2>/dev/null || rm -rf "$path"
        ;;
    esac
  done
}

git fetch --depth=1 "$UPSTREAM_URL" "$UPSTREAM_BRANCH"
UPSTREAM_SHA="$(git rev-parse --short FETCH_HEAD)"
echo "Upstream ${SOURCE_REPO}@${UPSTREAM_BRANCH} = ${UPSTREAM_SHA}"

git checkout FETCH_HEAD -- . ":(exclude).github" ":(exclude)state.json"
_prune_fork_github

# Pick up any renames/removals relative to the fork; keeps index aligned before commit.
git add -A

if git diff --cached --quiet; then
  echo "No changes; fork already matches upstream (excluding preserved paths)."
  exit 0
fi

if [[ "${SKIP_COMMIT:-}" == "1" ]]; then
  echo "SKIP_COMMIT=1 — changes are staged only; commit and push when ready."
  exit 0
fi

git commit -m "chore: sync upstream (${UPSTREAM_SHA})"
