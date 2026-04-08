#!/usr/bin/env bash
# Sync tracked content from SOURCE_REPO (default branch) into this fork.
# Preserves fork-only paths: .github/workflows, .github/scripts, state.json.
# Upstream's .github/workflows are never applied (fork keeps its own CI/automation).

set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-ansible-collections/cisco.ios}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
UPSTREAM_URL="https://github.com/${SOURCE_REPO}.git"

git fetch --depth=1 "$UPSTREAM_URL" "$UPSTREAM_BRANCH"
UPSTREAM_SHA="$(git rev-parse --short FETCH_HEAD)"
echo "Upstream ${SOURCE_REPO}@${UPSTREAM_BRANCH} = ${UPSTREAM_SHA}"

git checkout FETCH_HEAD -- . \
  ":(exclude).github/workflows" \
  ":(exclude).github/scripts" \
  ":(exclude)state.json"

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
