#!/bin/bash

# Script pour builder et préparer les apps pour TestFlight
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
log_info "=========================================="
log_info "  Build pour TestFlight - DUDU v1.0.0"
log_info "=========================================="
echo ""

# 1. Build DUDU Client
log_info "Build de DUDU Client pour TestFlight..."
cd "$SCRIPT_DIR/dudu_flutter"

log_info "Nettoyage..."
flutter clean
flutter pub get

log_info "Installation des pods..."
cd ios
pod install
cd ..

log_info "Build de l'archive IPA..."
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist

if [ $? -eq 0 ]; then
    log_success "✅ DUDU Client buildé avec succès!"
    IPA_CLIENT="$SCRIPT_DIR/dudu_flutter/build/ios/ipa/DUDU.ipa"
    if [ -f "$IPA_CLIENT" ]; then
        log_info "📦 IPA Client: $IPA_CLIENT"
        ls -lh "$IPA_CLIENT"
    fi
else
    log_error "Échec du build DUDU Client"
    exit 1
fi

echo ""

# 2. Build DUDU Pro
log_info "Build de DUDU Pro pour TestFlight..."
cd "$SCRIPT_DIR/mobile_dudu_pro"

log_info "Nettoyage..."
flutter clean
flutter pub get

log_info "Installation des pods..."
cd ios
pod install
cd ..

log_info "Build de l'archive IPA..."
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist

if [ $? -eq 0 ]; then
    log_success "✅ DUDU Pro buildé avec succès!"
    IPA_PRO="$SCRIPT_DIR/mobile_dudu_pro/build/ios/ipa/mobile_dudu_pro.ipa"
    if [ -f "$IPA_PRO" ]; then
        log_info "📦 IPA Pro: $IPA_PRO"
        ls -lh "$IPA_PRO"
    fi
else
    log_error "Échec du build DUDU Pro"
    exit 1
fi

echo ""
log_success "=========================================="
log_success "  Builds terminés!"
log_success "=========================================="
echo ""

log_info "📦 Fichiers IPA créés:"
echo ""
log_info "DUDU Client:"
log_info "  $IPA_CLIENT"
echo ""
log_info "DUDU Pro:"
log_info "  $IPA_PRO"
echo ""

log_warning "PROCHAINES ÉTAPES:"
echo ""
log_info "1. Uploader vers App Store Connect:"
log_info "   • Ouvrir Transporter (Mac App Store)"
log_info "   • Glisser-déposer les 2 fichiers .ipa"
log_info "   • Cliquer 'Deliver'"
echo ""
log_info "2. Configurer TestFlight:"
log_info "   • Aller sur appstoreconnect.apple.com"
log_info "   • Sélectionner chaque app"
log_info "   • Onglet TestFlight"
log_info "   • Ajouter des testeurs"
echo ""
log_info "3. Distribuer aux testeurs:"
log_info "   • Les testeurs recevront un email"
log_info "   • Ils téléchargeront TestFlight depuis l'App Store"
log_info "   • Ils pourront installer DUDU via TestFlight"
echo ""

log_success "Script terminé! 🎉"
