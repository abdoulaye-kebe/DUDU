#!/bin/bash

# Script de déploiement complet DUDU
# Déploie le site vitrine et l'admin panel

set -e

SERVER="root@213.154.90.11"
REMOTE_DIR="/var/www/DUDU"

echo "🚀 Déploiement DUDU - Site Vitrine + Admin Panel"
echo "================================================"
echo ""

# 1. Pousser les modifications vers GitHub
echo "📤 1. Push vers GitHub..."
git add .
git status
read -p "Voulez-vous commiter et pusher? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git commit -m "fix: Améliorer la responsivité mobile du site vitrine et admin panel" || echo "Rien à commiter"
    git push origin main
    echo "✅ Push terminé"
else
    echo "⏭️  Push ignoré"
fi

echo ""
echo "🔄 2. Déploiement sur le serveur..."
echo ""

# 2. Connexion au serveur et déploiement
ssh $SERVER << 'ENDSSH'
set -e

echo "📥 Pull des dernières modifications..."
cd /var/www/DUDU
git pull origin main

echo ""
echo "🌐 Déploiement du site vitrine..."
echo "✅ Site vitrine déjà à jour (fichiers statiques)"

echo ""
echo "⚙️  Déploiement de l'admin panel..."
cd /var/www/DUDU/admin-web
npm run build

echo ""
echo "🔄 Redémarrage des services..."
pm2 restart dudu-backend
sudo systemctl reload nginx

echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "📱 Sites déployés:"
echo "   • Site vitrine: https://www.dudugroup.sn"
echo "   • Admin panel: https://admin.dudugroup.sn"
echo ""
ENDSSH

echo ""
echo "🎉 Déploiement complet terminé!"
echo ""
echo "⚠️  N'oubliez pas de:"
echo "   1. Vider le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)"
echo "   2. Tester sur mobile et desktop"
echo ""
