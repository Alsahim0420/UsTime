#!/usr/bin/env bash
# Netlify build: installs the pinned Flutter SDK (the build image doesn't ship
# one), then analyzes, tests and builds the web app. Any failing step aborts
# the deploy, so main is only published when checks pass.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:?Set FLUTTER_VERSION in netlify.toml}"
FLUTTER_DIR="$HOME/flutter-$FLUTTER_VERSION"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter analyze
flutter test
flutter build web --release
