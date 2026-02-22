#!/bin/bash

# Script de déploiement du site vitrine DUDU sur le serveur de production

echo "🚀 Déploiement du site vitrine DUDU..."
echo ""

# Vérifier qu'on est dans le bon répertoire
if [ ! -d "dudu-website/public" ]; then
    echo "❌ Erreur: Répertoire dudu-website/public non trouvé"
    exit 1
fi

# Afficher les modifications à déployer
echo "📋 Derniers commits à déployer:"
git log --oneline -5
echo ""

# Demander confirmation
read -p "Voulez-vous déployer ces modifications sur le serveur de production? (o/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 1
fi

# Connexion SSH au serveur (à adapter selon vos identifiants)
SERVER_USER="root"
SERVER_HOST="213.154.90.11"
SERVER_PATH="/var/www/DUDU/dudu-website/public"

echo "📤 Connexion au serveur $SERVER_HOST..."
echo ""

# Commandes à exécuter sur le serveur
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    echo "📂 Navigation vers le répertoire du projet..."
    cd /var/www/DUDU
    
    echo "📥 Récupération des dernières modifications..."
    git pull origin main
    
    echo "🔄 Rechargement de Nginx..."
    sudo systemctl reload nginx
    
    echo "✅ Déploiement terminé!"
    echo ""
    echo "🌐 Le site est maintenant à jour sur:"
    echo "   - https://www.dudugroup.sn"
    echo "   - https://dudugroup.sn"
ENDSSH

echo ""
echo "✨ Déploiement réussi!"
echo "🧪 Testez le site sur votre téléphone pour vérifier la responsivité"
