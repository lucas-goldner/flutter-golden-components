#!/usr/bin/env bash
# Builds the gallery for Vercel. Vercel has no Flutter preinstalled, so this
# fetches a pinned SDK first (kept in .flutter-sdk, which Vercel's build cache
# can reuse between deployments).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
FLUTTER_DIR="${FLUTTER_DIR:-$PWD/.flutter-sdk}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics --enable-web >/dev/null
flutter --version

cd example
flutter pub get
flutter build web --release
