# 🚀 Guide de Démarrage Rapide - DUDU

Ce guide vous permet de lancer rapidement toutes les applications DUDU.

## ⚡ Démarrage Express (5 minutes)

### 1️⃣ Backend (Terminal 1)
```bash
cd backend
npm install
npm start
```
✅ Backend disponible sur : http://localhost:8000

### 2️⃣ Application Client Flutter (Terminal 2)
```bash
cd dudu_flutter
flutter pub get
flutter run
```
📱 Testez avec :
- **Téléphone** : `776543210`
- **Mot de passe** : `test123456`

### 3️⃣ Application Chauffeur Flutter (Terminal 3)
```bash
cd mobile_dudu_pro
flutter pub get
flutter run -d "autre-device-id"
```

### 4️⃣ Interface Web Admin (Terminal 4)
```bash
cd admin-web
npm install
npm run dev
```
🖥️ Accédez à : http://localhost:3001

## 📱 Tester les Fonctionnalités

### 🗺️ Client - Demander une Course
1. Lancer l'app client
2. Se connecter avec `776543210` / `test123456`
3. Voir la carte interactive
4. Taper une adresse de destination
5. Sélectionner un type de course
6. Confirmer la demande

### 🚕 Chauffeur - Accepter une Course
1. Lancer l'app chauffeur
2. Se connecter
3. Activer le statut "En ligne"
4. Recevoir les demandes de courses
5. Activer le mode covoiturage (optionnel)
6. Activer les livraisons (optionnel)

### 📦 Client - Demander une Livraison
1. Dans l'app client
2. Sélectionner "Livraison"
3. Remplir les détails :
   - Adresse de récupération
   - Adresse de livraison
   - Type de colis
   - Poids et dimensions
   - Infos du destinataire
4. Prendre une photo du colis
5. Confirmer

### 🖥️ Admin - Monitorer
1. Ouvrir http://localhost:3001
2. Voir le tableau de bord
3. Consulter les statistiques
4. Gérer les chauffeurs
5. Suivre les courses en temps réel

## 🧪 Scénarios de Test

### Scénario 1 : Course Simple
1. **Client** : Demande une course standard de Almadies → Plateau
2. **Système** : Notifie les chauffeurs proches
3. **Chauffeur** : Accepte la course
4. **Client** : Voit le chauffeur arriver
5. **Chauffeur** : Démarre puis termine la course
6. **Les deux** : Notent l'expérience

### Scénario 2 : Covoiturage
1. **Chauffeur** : Active le mode covoiturage
2. **Client 1** : Demande Almadies → Plateau
3. **Chauffeur** : Accepte
4. **Client 2** : Demande Ngor → Médina (trajet compatible)
5. **Chauffeur** : Accepte le 2ème passager
6. **Système** : Réduit le prix pour les deux

### Scénario 3 : Livraison
1. **Client** : Demande livraison de document
2. **Client** : Prend photo du colis
3. **Moto** : Accepte et récupère
4. **Moto** : Confirme photo de récupération
5. **Système** : Génère code OTP (ex: 1234)
6. **Moto** : Livre au destinataire
7. **Destinataire** : Donne code OTP
8. **Moto** : Prend photo + confirme code
9. **Système** : Valide la livraison

## 🔧 Résolution de Problèmes

### ❌ Backend ne démarre pas
```bash
# Vérifier MongoDB
mongod --version

# Vérifier le port
lsof -i :8000
```

### ❌ Flutter ne trouve pas l'appareil
```bash
# Lister les appareils
flutter devices

# Relancer
flutter run -d <device-id>
```

### ❌ Erreur Google Maps
1. Vérifier la clé API dans :
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/AppDelegate.swift`
2. Activer les APIs sur Google Cloud Console

### ❌ Interface admin ne charge pas
```bash
# Nettoyer et réinstaller
cd admin-web
rm -rf node_modules
npm install
npm run dev
```

## 📊 URLs et Ports

| Application | URL | Port |
|------------|-----|------|
| Backend API | http://localhost:8000 | 8000 |
| Admin Web | http://localhost:3001 | 3001 |
| MongoDB | mongodb://localhost:27017 | 27017 |

## 🎯 Comptes de Test

### Passager
- Téléphone : `776543210`
- Mot de passe : `test123456`

### Chauffeur
- À créer depuis l'interface admin
- Ou s'inscrire dans l'app

### Admin
- Email : `admin@dudu.sn`
- Mot de passe : `admin123`

## ✅ Checklist de Vérification

Avant de tester, vérifiez que :

- [ ] MongoDB est démarré
- [ ] Backend tourne sur port 8000
- [ ] Fichier `.env` est configuré
- [ ] Google Maps API est configurée
- [ ] Émulateur iOS/Android est lancé
- [ ] Interface admin est accessible

## 🚀 Commandes Rapides

### Tout arrêter
```bash
# Ctrl+C dans chaque terminal
# Ou
pkill -f "node"
pkill -f "flutter"
```

### Tout nettoyer
```bash
# Backend
cd backend && rm -rf node_modules

# Admin
cd admin-web && rm -rf node_modules

# Flutter Client
cd dudu_flutter && flutter clean

# Flutter Chauffeur
cd mobile_dudu_pro && flutter clean
```

### Tout réinstaller
```bash
# Backend
cd backend && npm install

# Admin
cd admin-web && npm install

# Flutter
cd dudu_flutter && flutter pub get
cd ../mobile_dudu_pro && flutter pub get
```

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs dans chaque terminal
2. Consultez la documentation dans `docs/`
3. Vérifiez le README.md principal

## 🎉 Bon Test !

Tout est prêt ! Lancez les 4 applications et testez les fonctionnalités. 🚗🚕📦🖥️

---

**DUDU - Transport et Livraison au Sénégal 🇸🇳**

