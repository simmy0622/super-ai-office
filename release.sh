#!/bin/bash
set -e

VERSION=${1:-""}
if [ -z "$VERSION" ]; then
  echo "Usage: ./release.sh <version>  e.g. ./release.sh 1.1.0"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LANDING_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "▶ Building app v$VERSION..."

# Update version in tauri.conf.json
python3 -c "
import json, sys
path = '$REPO_ROOT/src-tauri/tauri.conf.json'
with open(path) as f: d = json.load(f)
d['version'] = '$VERSION'
with open(path, 'w') as f: json.dump(d, f, indent=2, ensure_ascii=False)
print('  tauri.conf.json updated to v$VERSION')
"

# Build
cd "$REPO_ROOT"
cargo tauri build

# Find the new dmg
DMG=$(ls "$REPO_ROOT/src-tauri/target/release/bundle/dmg/"*.dmg | head -1)
echo "▶ Copying $(basename "$DMG") to landing/assets/..."
cp "$DMG" "$LANDING_DIR/assets/AgentSalon.dmg"

# Update version shown on landing page
sed -i '' "s/当前版本 v[0-9.]*/当前版本 v$VERSION/" "$LANDING_DIR/index.html"

# Commit and push
echo "▶ Pushing to GitHub..."
cd "$LANDING_DIR"
git add .
git commit -m "Release v$VERSION"
git push

echo ""
echo "✅ Done! v$VERSION deployed."
echo "   Cloudflare Pages will auto-deploy in ~1 min."
echo "   https://github.com/simmy0622/super-ai-office"
