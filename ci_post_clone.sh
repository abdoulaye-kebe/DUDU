#!/bin/bash
set -euo pipefail

# Xcode Cloud automatically runs this script if it exists at repo root.
# Delegate to the Flutter iOS setup script for the Pro app.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/mobile_dudu_pro/ci_post_clone.sh"
