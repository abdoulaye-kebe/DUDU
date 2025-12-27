#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Make Flutter available
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found. Installing Flutter SDK (stable) into $HOME/flutter";
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
else
  echo "Flutter found: $(command -v flutter)"
fi

echo "Flutter version:"
flutter --version

cd "$PROJECT_DIR"

echo "Running flutter pub get..."
flutter pub get

echo "Precache iOS artifacts..."
flutter precache --ios

echo "Generating iOS build configuration (Generated.xcconfig)..."
flutter build ios --config-only

echo "Installing CocoaPods..."
cd ios

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods not found. Installing with gem (user install)..."
  gem install --user-install cocoapods -N
  export PATH="$(ruby -e 'require "rubygems"; print Gem.user_dir')/bin:$PATH"
fi

pod --version
pod install --repo-update

echo "Post-clone setup complete."
