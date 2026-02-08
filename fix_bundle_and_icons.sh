#!/bin/bash

# Script pour corriger le Bundle Identifier et générer les icônes
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
log_info "  Correction Bundle ID et Icônes - DUDU"
log_info "=========================================="
echo ""

# 1. Corriger le Bundle Identifier pour DUDU Client
log_info "Correction du Bundle Identifier pour DUDU Client..."

CLIENT_PBXPROJ="$SCRIPT_DIR/dudu_flutter/ios/Runner.xcodeproj/project.pbxproj"

if [ -f "$CLIENT_PBXPROJ" ]; then
    # Backup
    cp "$CLIENT_PBXPROJ" "$CLIENT_PBXPROJ.backup"
    
    # Remplacer com.example.duduFlutter par sn.dudugroup.app
    sed -i '' 's/com\.example\.duduFlutter/sn.dudugroup.app/g' "$CLIENT_PBXPROJ"
    
    log_success "Bundle Identifier DUDU Client corrigé: sn.dudugroup.app"
else
    log_error "Fichier project.pbxproj non trouvé pour DUDU Client"
fi

# 2. Générer les icônes pour les deux apps
log_info ""
log_info "Génération des icônes d'application..."

# DUDU Client
log_info "Génération des icônes pour DUDU Client..."
cd "$SCRIPT_DIR/dudu_flutter"
flutter pub run flutter_launcher_icons || log_warning "flutter_launcher_icons non configuré pour DUDU Client"

# DUDU Pro
log_info "Génération des icônes pour DUDU Pro..."
cd "$SCRIPT_DIR/mobile_dudu_pro"

# Créer la configuration flutter_launcher_icons si elle n'existe pas
if ! grep -q "flutter_launcher_icons:" pubspec.yaml; then
    log_info "Ajout de la configuration flutter_launcher_icons dans pubspec.yaml..."
    cat >> pubspec.yaml << 'EOF'

# Configuration pour flutter_launcher_icons
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo_dudu_off.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo_dudu_off.png"
EOF
fi

flutter pub get
flutter pub run flutter_launcher_icons || log_warning "Erreur lors de la génération des icônes pour DUDU Pro"

cd "$SCRIPT_DIR"

echo ""
log_success "=========================================="
log_success "  Corrections terminées!"
log_success "=========================================="
echo ""

log_info "Résumé des modifications:"
log_info "  ✓ Bundle ID DUDU Client: sn.dudugroup.app"
log_info "  ✓ Bundle ID DUDU Pro: sn.dudu.mobileDuduPro (déjà correct)"
log_info "  ✓ Icônes générées pour les deux apps"
echo ""

log_warning "IMPORTANT: Vous devez maintenant:"
log_info "1. Ouvrir Xcode pour DUDU Client:"
log_info "   open dudu_flutter/ios/Runner.xcworkspace"
log_info ""
log_info "2. Dans Xcode, vérifier:"
log_info "   • Signing & Capabilities → Bundle Identifier = sn.dudugroup.app"
log_info "   • Signing & Capabilities → Team = Votre équipe Apple Developer"
log_info "   • General → App Icons Set = AppIcon"
log_info ""
log_info "3. Créer l'App ID dans Apple Developer:"
log_info "   • Aller sur developer.apple.com/account"
log_info "   • Certificates, Identifiers & Profiles → Identifiers"
log_info "   • Créer un App ID: sn.dudugroup.app"
log_info "   • Activer: Push Notifications, Maps, Background Modes"
log_info ""
log_info "4. Rebuilder les apps:"
log_info "   ./deploy_to_appstore.sh both"
echo ""

log_success "Script terminé! 🎉"
