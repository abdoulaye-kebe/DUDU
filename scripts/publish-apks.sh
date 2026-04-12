#!/usr/bin/env bash
# Génère les APK release et les copie dans backend/public/downloads/
# Usage: depuis la racine du dépôt — ./scripts/publish-apks.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p backend/public/downloads

echo "==> Build client (dudu_flutter)..."
(cd dudu_flutter && flutter build apk --release --no-tree-shake-icons)
cp -f dudu_flutter/build/app/outputs/flutter-apk/app-release.apk backend/public/downloads/dudu-client.apk

echo "==> Build chauffeur (mobile_dudu_pro)..."
(cd mobile_dudu_pro && flutter build apk --release --no-tree-shake-icons)
cp -f mobile_dudu_pro/build/app/outputs/flutter-apk/app-release.apk backend/public/downloads/dudu-pro.apk
cp -f mobile_dudu_pro/build/app/outputs/flutter-apk/app-release.apk backend/public/downloads/dudu-driver.apk

mkdir -p dudu-website/public/downloads
cp -f backend/public/downloads/dudu-client.apk backend/public/downloads/dudu-pro.apk dudu-website/public/downloads/

echo ""
echo "APK prêts:"
ls -lh backend/public/downloads/dudu-client.apk backend/public/downloads/dudu-pro.apk backend/public/downloads/dudu-driver.apk
echo ""
echo "Copie site vitrine: dudu-website/public/downloads/ (client + pro)"
echo "Déploiement: rsync ou copier ces dossiers vers le serveur (chemins servis pour /downloads/)."
