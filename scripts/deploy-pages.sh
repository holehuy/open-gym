#!/usr/bin/env bash
# Builds the web app locally and publishes it to the gh-pages branch, which GitHub Pages serves
# at https://holehuy.github.io/open-gym/. The same branch is what .github/workflows/pages.yml
# pushes to, so a local deploy and a CI deploy are interchangeable.
#
# Guest-mode build (no VITE_DEMO, so it starts empty) plus the 180 px exercise media.
#
# Usage: scripts/deploy-pages.sh [remote]     remote defaults to "holehuy"
set -euo pipefail

REMOTE="${1:-holehuy}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/frontend/dist"
URL="$(git -C "$ROOT" remote get-url "$REMOTE")"
SHA="$(git -C "$ROOT" rev-parse --short HEAD)"

if [ -n "$(git -C "$ROOT" status --porcelain -- frontend catalogue scripts/catalogue)" ]; then
  echo "warning: uncommitted changes in frontend/ or catalogue/ go into this deploy" >&2
fi

cd "$ROOT/frontend"
npm ci --no-audit --no-fund
npm run build
node "$ROOT/scripts/catalogue/stage-media.mjs" "$DIST"
touch "$DIST/.nojekyll"

# Publish dist/ as a single fresh commit; the branch keeps no history.
cd "$DIST"
rm -rf .git
git init -q -b gh-pages
git add -A
git commit -q -m "Deploy $SHA to GitHub Pages (local)"
git push -f "$URL" gh-pages
rm -rf .git

echo "Deployed $SHA. Pages refreshes in a minute or two: https://holehuy.github.io/open-gym/"
