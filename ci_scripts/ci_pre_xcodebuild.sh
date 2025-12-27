#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRO_DIR="$REPO_ROOT/mobile_dudu_pro"

# Ensure Flutter is available
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found. Installing Flutter SDK (stable) into $HOME/flutter";
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
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
