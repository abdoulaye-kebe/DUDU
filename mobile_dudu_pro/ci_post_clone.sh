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

echo "Installing CocoaPods..."
cd ios

# Ensure CocoaPods repo is usable
pod --version
pod install

echo "Post-clone setup complete."
