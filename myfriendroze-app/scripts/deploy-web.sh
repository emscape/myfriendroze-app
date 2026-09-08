#!/usr/bin/env bash
# Builds and deploys the admin app's web/PWA build to Firebase Hosting.
#
# Bakes in --build-number=$(git rev-list --count HEAD) automatically —
# without this, the build number silently falls back to pubspec.yaml's
# static value, and the Profile screen's displayed version stops changing
# on real deploys (see the version comment in pubspec.yaml and the
# Deployment section of CLAUDE.md). This script exists so that flag can't
# be forgotten or mistyped; run this instead of the raw flutter/firebase
# commands for any real deploy.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: working tree has uncommitted changes — the deployed build" >&2
  echo "won't exactly match any single commit. Ctrl-C to abort, or wait 5s to continue." >&2
  sleep 5
fi

BUILD_NUMBER=$(git rev-list --count HEAD)
# Read the version name (the part before +N) straight from pubspec.yaml
# rather than hardcoding it, so this line doesn't go stale the next time
# the version name changes independently of this script.
VERSION_NAME=$(grep -m1 '^version:' pubspec.yaml | sed -E 's/^version:\s*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
echo "Building web release, build number ${BUILD_NUMBER} (git rev-list --count HEAD)..."

flutter build web --release --build-number="${BUILD_NUMBER}"

echo "Deploying to Firebase Hosting (myfriendroze-platform)..."
firebase deploy --only hosting --project myfriendroze-platform

echo "Deployed. Version shown on the Profile screen should read: ${VERSION_NAME} (${BUILD_NUMBER})"
