#!/bin/bash

# 🚀 Script d'installation automatique DUDU
# Usage: ./setup.sh

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour installer les prérequis
install_prerequisites() {
    print_status "Vérification des prérequis..."
    
    # Vérifier le système d'exploitation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        PACKAGE_MANAGER="apt"
    else
        print_error "Système d'exploitation non supporté: $OSTYPE"
        exit 1
    fi
    
    print_success "Système détecté: $OS"
    
    # Vérifier Node.js
    if ! command_exists node; then
        print_warning "Node.js non trouvé. Installation..."
        if [[ "$OS" == "macOS" ]]; then
            brew install node
        else
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    else
        NODE_VERSION=$(node --version)
        print_success "Node.js trouvé: $NODE_VERSION"
    fi
    
    # Vérifier MongoDB
    if ! command_exists mongod; then
        print_warning "MongoDB non trouvé. Installation..."
        if [[ "$OS" == "macOS" ]]; then
            brew install mongodb-community
        else
            sudo apt install mongodb
        fi
    else
        print_success "MongoDB trouvé"
    fi
    
    # Vérifier Flutter
    if ! command_exists flutter; then
        print_warning "Flutter non trouvé. Installation..."
        if [[ "$OS" == "macOS" ]]; then
            brew install flutter
        else
            sudo snap install flutter --classic
        fi
    else
        FLUTTER_VERSION=$(flutter --version | head -n 1)
        print_success "Flutter trouvé: $FLUTTER_VERSION"
    fi
    
    # Vérifier Git
    if ! command_exists git; then
        print_warning "Git non trouvé. Installation..."
        if [[ "$OS" == "macOS" ]]; then
            brew install git
        else
            sudo apt install git
        fi
    else
        print_success "Git trouvé"
    fi
}

# Fonction pour configurer le backend
setup_backend() {
    print_status "Configuration du backend..."
    
    cd backend
    
    # Installer les dépendances
    print_status "Installation des dépendances Node.js..."
    npm install
    
    # Créer le fichier .env
    if [ ! -f ".env" ]; then
        print_status "Création du fichier .env..."
        cp env.example .env
        print_success "Fichier .env créé"
    else
        print_warning "Fichier .env existe déjà"
    fi
    
    # Vérifier la configuration MongoDB
    print_status "Vérification de la connexion MongoDB..."
    if mongosh --eval "db.runCommand('ping')" >/dev/null 2>&1; then
        print_success "MongoDB est opérationnel"
    else
        print_warning "MongoDB n'est pas démarré. Démarrage..."
        mongod --fork --logpath /tmp/mongod.log
        sleep 3
        if mongosh --eval "db.runCommand('ping')" >/dev/null 2>&1; then
            print_success "MongoDB démarré avec succès"
        else
            print_error "Impossible de démarrer MongoDB"
            exit 1
        fi
    fi
    
    cd ..
}

# Fonction pour configurer les apps Flutter
setup_flutter_apps() {
    print_status "Configuration des applications Flutter..."
    
    # App Client
    print_status "Configuration de l'app client..."
    cd dudu_flutter
    flutter pub get
    cd ..
    
    # App Chauffeur
    print_status "Configuration de l'app chauffeur..."
    cd mobile_dudu_pro
    flutter pub get
    cd ..
    
    print_success "Applications Flutter configurées"
}

# Fonction pour configurer l'admin web
setup_admin_web() {
    print_status "Configuration de l'interface admin..."
    
    cd admin-web
    npm install
    cd ..
    
    print_success "Interface admin configurée"
}

# Fonction pour tester l'installation
test_installation() {
    print_status "Test de l'installation..."
    
    # Test du backend
    print_status "Test du backend..."
    cd backend
    timeout 10s node start.js >/dev/null 2>&1 &
    BACKEND_PID=$!
    sleep 3
    
    if curl -s http://localhost:3000/api/health >/dev/null; then
        print_success "Backend opérationnel"
        kill $BACKEND_PID 2>/dev/null || true
    else
        print_warning "Backend non accessible (normal si MongoDB n'est pas démarré)"
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    cd ..
    
    # Test Flutter
    print_status "Test Flutter..."
    cd dudu_flutter
    if flutter doctor >/dev/null 2>&1; then
        print_success "Flutter configuré correctement"
    else
        print_warning "Flutter nécessite une configuration supplémentaire"
    fi
    cd ..
}

# Fonction pour afficher les instructions finales
show_final_instructions() {
    print_success "Installation terminée !"
    echo ""
    echo "🚀 Pour démarrer le projet :"
    echo ""
    echo "1. Backend :"
    echo "   cd backend"
    echo "   npm start"
    echo ""
    echo "2. App Client :"
    echo "   cd dudu_flutter"
    echo "   flutter run"
    echo ""
    echo "3. App Chauffeur :"
    echo "   cd mobile_dudu_pro"
    echo "   flutter run"
    echo ""
    echo "4. Admin Web :"
    echo "   cd admin-web"
    echo "   npm start"
    echo ""
    echo "📚 Documentation complète : README_COLLABORATION.md"
    echo "🔧 Configuration : backend/CONFIGURATION_ENV.md"
    echo ""
    echo "🌐 URLs :"
    echo "   - Backend API: http://localhost:3000"
    echo "   - Admin Web: http://localhost:3001"
    echo "   - MongoDB: mongodb://localhost:27017/dudu"
    echo ""
    print_success "Bon développement ! 🎉"
}

# Fonction principale
main() {
    echo "🚀 Installation automatique DUDU"
    echo "================================="
    echo ""
    
    # Vérifier si nous sommes dans le bon répertoire
    if [ ! -f "backend/package.json" ]; then
        print_error "Ce script doit être exécuté depuis la racine du projet DUDU"
        exit 1
    fi
    
    # Installation des prérequis
    install_prerequisites
    
    # Configuration des composants
    setup_backend
    setup_flutter_apps
    setup_admin_web
    
    # Test de l'installation
    test_installation
    
    # Instructions finales
    show_final_instructions
}

# Exécution du script
main "$@"









