#!/bin/bash

# Script de déploiement App Store pour DUDU
# Usage: ./deploy_to_appstore.sh [client|pro|both]

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
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

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter n'est pas installé"
        exit 1
    fi
    log_success "Flutter installé: $(flutter --version | head -n 1)"
    
    # Vérifier CocoaPods
    if ! command -v pod &> /dev/null; then
        log_error "CocoaPods n'est pas installé. Installez-le avec: sudo gem install cocoapods"
        exit 1
    fi
    log_success "CocoaPods installé: $(pod --version)"
    
    # Vérifier Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode n'est pas installé"
        exit 1
    fi
    log_success "Xcode installé: $(xcodebuild -version | head -n 1)"
}

# Fonction pour nettoyer et préparer un projet
prepare_project() {
    local project_path=$1
    local project_name=$2
    
    log_info "Préparation de $project_name..."
    
    cd "$project_path"
    
    # Nettoyage
    log_info "Nettoyage du projet..."
    flutter clean
    
    # Récupération des dépendances
    log_info "Récupération des dépendances Flutter..."
    flutter pub get
    
    # Installation des pods
    log_info "Installation des CocoaPods..."
    cd ios
    pod install
    cd ..
    
    log_success "$project_name préparé avec succès"
}

# Fonction pour build un projet
build_project() {
    local project_path=$1
    local project_name=$2
    
    log_info "Build de $project_name pour iOS..."
    
    cd "$project_path"
    
    # Build IPA
    log_info "Création de l'archive IPA..."
    flutter build ipa --release
    
    if [ $? -eq 0 ]; then
        log_success "Build de $project_name réussi!"
        log_info "Fichier IPA: $project_path/build/ios/ipa/"
        ls -lh "$project_path/build/ios/ipa/"*.ipa 2>/dev/null || log_warning "Fichier IPA non trouvé"
    else
        log_error "Échec du build de $project_name"
        exit 1
    fi
}

# Fonction pour ouvrir Xcode
open_xcode() {
    local project_path=$1
    local project_name=$2
    
    log_info "Ouverture de $project_name dans Xcode..."
    open "$project_path/ios/Runner.xcworkspace"
}

# Fonction principale
main() {
    local target=${1:-both}
    
    echo ""
    log_info "=========================================="
    log_info "  Déploiement App Store - DUDU"
    log_info "=========================================="
    echo ""
    
    # Vérifier les prérequis
    check_prerequisites
    
    # Chemins des projets
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    CLIENT_PATH="$SCRIPT_DIR/dudu_flutter"
    PRO_PATH="$SCRIPT_DIR/mobile_dudu_pro"
    
    case $target in
        client)
            log_info "Déploiement de DUDU Client uniquement"
            prepare_project "$CLIENT_PATH" "DUDU Client"
            build_project "$CLIENT_PATH" "DUDU Client"
            
            log_info ""
            log_success "=========================================="
            log_success "  Build DUDU Client terminé!"
            log_success "=========================================="
            log_info ""
            log_info "Prochaines étapes:"
            log_info "1. Ouvrir Xcode: open $CLIENT_PATH/ios/Runner.xcworkspace"
            log_info "2. Product → Archive"
            log_info "3. Distribute App → App Store Connect"
            log_info "4. Ou utiliser Transporter pour uploader le .ipa"
            ;;
            
        pro)
            log_info "Déploiement de DUDU Pro uniquement"
            prepare_project "$PRO_PATH" "DUDU Pro"
            build_project "$PRO_PATH" "DUDU Pro"
            
            log_info ""
            log_success "=========================================="
            log_success "  Build DUDU Pro terminé!"
            log_success "=========================================="
            log_info ""
            log_info "Prochaines étapes:"
            log_info "1. Ouvrir Xcode: open $PRO_PATH/ios/Runner.xcworkspace"
            log_info "2. Product → Archive"
            log_info "3. Distribute App → App Store Connect"
            log_info "4. Ou utiliser Transporter pour uploader le .ipa"
            ;;
            
        both)
            log_info "Déploiement de DUDU Client et DUDU Pro"
            
            # Build Client
            prepare_project "$CLIENT_PATH" "DUDU Client"
            build_project "$CLIENT_PATH" "DUDU Client"
            
            echo ""
            
            # Build Pro
            prepare_project "$PRO_PATH" "DUDU Pro"
            build_project "$PRO_PATH" "DUDU Pro"
            
            log_info ""
            log_success "=========================================="
            log_success "  Builds terminés!"
            log_success "=========================================="
            log_info ""
            log_info "Fichiers IPA créés:"
            log_info "  • DUDU Client: $CLIENT_PATH/build/ios/ipa/"
            log_info "  • DUDU Pro: $PRO_PATH/build/ios/ipa/"
            log_info ""
            log_info "Prochaines étapes:"
            log_info "1. Uploader les .ipa vers App Store Connect via Transporter"
            log_info "2. Ou ouvrir dans Xcode et faire Product → Archive"
            log_info "3. Remplir les métadonnées dans App Store Connect"
            log_info "4. Soumettre pour review"
            log_info ""
            log_info "Voir le guide complet: GUIDE_DEPLOIEMENT_APP_STORE.md"
            ;;
            
        *)
            log_error "Usage: $0 [client|pro|both]"
            exit 1
            ;;
    esac
    
    echo ""
    log_success "Script terminé avec succès! 🎉"
    echo ""
}

# Exécuter le script
main "$@"
