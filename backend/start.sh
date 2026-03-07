#!/bin/bash

# Script de démarrage pour DUDU Backend
# Usage: ./start.sh

echo "🚀 Démarrage du serveur DUDU Backend..."

# Vérifier si le fichier .env existe
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env non trouvé!"
    echo "📋 Copiez env.example vers .env :"
    echo "   cp env.example .env"
    echo "   Puis éditez le fichier .env avec vos configurations"
    exit 1
fi

# Vérifier si MongoDB est installé
if ! command -v mongod &> /dev/null; then
    echo "⚠️  MongoDB n'est pas installé ou n'est pas dans le PATH"
    echo "📦 Installation recommandée :"
    echo "   macOS: brew install mongodb-community"
    echo "   Ubuntu: sudo apt install mongodb"
    echo "   Windows: Télécharger depuis mongodb.com"
    echo ""
    echo "🔄 Tentative de démarrage quand même..."
fi

# Installer les dépendances si nécessaire
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Démarrer le serveur
echo "🎯 Démarrage du serveur sur le port 3000..."
echo "🌐 API disponible sur: http://localhost:3000"
echo "📚 Documentation: http://localhost:3000/api/v1"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter le serveur"
echo ""

node start.js










