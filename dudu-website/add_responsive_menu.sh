#!/bin/bash

# Script pour ajouter le menu hamburger responsive à toutes les pages HTML

echo "🔧 Ajout du menu hamburger responsive aux pages du site vitrine..."

# Liste des fichiers HTML à modifier (sauf home.html déjà fait)
pages=(
    "public/about.html"
    "public/contact.html"
    "public/driver-signup.html"
    "public/faq.html"
    "public/pricing.html"
    "public/privacy.html"
    "public/services.html"
    "public/terms.html"
)

for page in "${pages[@]}"; do
    if [ -f "$page" ]; then
        echo "📝 Modification de $page..."
        
        # Vérifier si le hamburger n'existe pas déjà
        if ! grep -q '<div class="hamburger">' "$page"; then
            # Ajouter le menu hamburger après le logo
            sed -i '' '/<a href="home.html" class="logo">/,/<\/a>/{
                /<\/a>/a\
            <div class="hamburger">\
                <span></span>\
                <span></span>\
                <span></span>\
            </div>
            }' "$page"
            echo "  ✅ Menu hamburger ajouté"
        else
            echo "  ⏭️  Menu hamburger déjà présent"
        fi
        
        # Remplacer les scripts inline par l'inclusion du fichier main.js
        if ! grep -q 'src="js/main.js"' "$page"; then
            # Supprimer les anciens scripts inline et ajouter main.js
            sed -i '' '/<script>/,/<\/script>/d' "$page"
            sed -i '' 's|</body>|    <script src="js/main.js"></script>\n</body>|' "$page"
            echo "  ✅ Script main.js ajouté"
        else
            echo "  ⏭️  Script main.js déjà présent"
        fi
    else
        echo "⚠️  Fichier $page non trouvé"
    fi
done

echo ""
echo "✨ Modifications terminées !"
echo "📱 Le site est maintenant responsive avec menu hamburger sur mobile"
