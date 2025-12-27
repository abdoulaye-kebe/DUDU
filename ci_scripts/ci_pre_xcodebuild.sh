#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRO_DIR="$REPO_ROOT/mobile_dudu_pro"

# Ensure Flutter is available
if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_DIR="$HOME/flutter"
  echo "Flutter not found. Installing Flutter SDK (stable) into $FLUTTER_DIR";

  if [ -d "$FLUTTER_DIR" ] && [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
    echo "Found partial Flutter checkout. Removing $FLUTTER_DIR..."
    rm -rf "$FLUTTER_DIR"
  fi

  if [ ! -d "$FLUTTER_DIR" ]; then
    for attempt in 1 2 3; do
      echo "Cloning Flutter (attempt $attempt/3)..."
      if git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"; then
        break
      fi
      echo "Flutter clone failed. Retrying..."
      rm -rf "$FLUTTER_DIR"
      sleep 5
    done
  fi

  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

echo "Flutter version:"
flutter --version

cd "$PRO_DIR"

echo "flutter pub get"
flutter pub get

echo "flutter precache --ios"
flutter precache --ios

echo "flutter build ios --config-only (Generate Generated.xcconfig)"
flutter build ios --config-only

cd ios

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods not found. Installing with gem (user install)..."
  gem install --user-install cocoapods -N
  export PATH="$(ruby -e 'require "rubygems"; print Gem.user_dir')/bin:$PATH"
fi

pod --version
pod install --repo-update
