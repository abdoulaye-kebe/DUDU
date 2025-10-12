# 🚗 DUDU - Plateforme de Transport et Livraison

**DUDU** est une plateforme complète de transport de passagers et de livraison au Sénégal, similaire à Uber/Bolt, avec des fonctionnalités avancées de covoiturage et de livraison de colis.

## 📦 Architecture du Projet

Le projet DUDU est composé de 4 applications principales :

```
DUDU/
├── backend/              # API REST Node.js + Socket.io
├── dudu_flutter/         # Application mobile Client (Flutter)
├── mobile_dudu_pro/      # Application mobile Chauffeur (Flutter)
└── admin-web/           # Interface web d'administration (React)
```

## 🚀 Applications

### 1. 📱 DUDU Client (Flutter)
**Application mobile pour les passagers**

**Fonctionnalités :**
- 🗺️ Carte interactive Google Maps
- 📍 Recherche d'adresse avec autocomplétion (Google Places API)
- 🚗 Demande de courses (Standard, Express, Premium)
- 🤝 Réservation de covoiturage
- 📦 Demande de livraison de colis (moto)
- 💳 Paiements intégrés
- 📊 Historique des courses
- ⭐ Système de notation

**Installation :**
```bash
cd dudu_flutter
flutter pub get
flutter run
```

**Configuration Google Maps :**
- Clé API dans `android/app/src/main/AndroidManifest.xml`
- Clé API dans `ios/Runner/AppDelegate.swift`
- Voir `GOOGLE_MAPS_CONFIG.md` pour les détails

### 2. 🚕 DUDU Pro (Flutter)
**Application mobile pour les chauffeurs**

**Fonctionnalités :**
- 🗺️ Carte Google Maps avec position en temps réel
- ✅ Statut En ligne/Hors ligne
- 🤝 Mode covoiturage (partage de courses)
- 📦 Acceptation de livraisons
- 💰 Suivi des revenus quotidiens
- 📊 Statistiques de performance
- ⭐ Notes et évaluations
- 🔔 Notifications de nouvelles courses

**Installation :**
```bash
cd mobile_dudu_pro
flutter pub get
flutter run
```

### 3. 🖥️ Admin Dashboard (React)
**Interface web d'administration**

**Fonctionnalités :**
- 📊 Dashboard avec statistiques en temps réel
- 👥 Gestion des chauffeurs (validation, suspension)
- 🗺️ Monitoring des courses en direct
- 💰 Rapports financiers
- 📈 Analytics et graphiques
- 🔔 Notifications temps réel (Socket.io)

**Installation :**
```bash
cd admin-web
npm install
npm run dev
```

**Accès :** http://localhost:3001

### 4. ⚙️ Backend API (Node.js)
**API REST et WebSocket**

**Technologies :**
- Node.js + Express
- MongoDB (base de données)
- Socket.io (temps réel)
- JWT (authentification)

**Fonctionnalités :**
- 🔐 Authentification (passagers, chauffeurs, admins)
- 🗺️ Gestion des courses
- 💳 Gestion des paiements
- 📱 Communication temps réel
- 📊 Système de notation
- 🤝 Logique de covoiturage
- 📦 Gestion des livraisons

**Installation :**
```bash
cd backend
npm install
cp env.example .env
# Configurer MongoDB et les clés API
npm start
```

**Variables d'environnement (.env) :**
```env
PORT=8000
MONGODB_URI=mongodb://localhost:27017/dudu
JWT_SECRET=votre_secret_jwt
GOOGLE_MAPS_API_KEY=votre_clé_google_maps
SOCKET_CORS_ORIGIN=http://localhost:5000
```

## 🎯 Types de Services

### 🚗 Transport de Passagers
1. **Standard** - Voiture classique (économique)
2. **Express** - Course rapide avec priorité
3. **Premium** - Voiture haut de gamme
4. **Covoiturage** - Partage de course entre plusieurs passagers

### 📦 Livraison de Colis (Moto)
- Livraison rapide par moto
- Types de colis : Document, Petit, Moyen, Grand
- Photo du colis à la prise en charge
- Photo de preuve à la livraison
- Code de confirmation OTP
- Suivi en temps réel

## 🔧 Installation Complète

### Prérequis
- Node.js (v18+)
- Flutter (v3.0+)
- MongoDB
- Xcode (pour iOS)
- Android Studio (pour Android)

### 1. Backend
```bash
cd backend
npm install
cp env.example .env
# Configurer .env avec vos clés
npm start
```

### 2. Applications Mobile Flutter
```bash
# Client
cd dudu_flutter
flutter pub get
flutter run

# Chauffeur
cd mobile_dudu_pro
flutter pub get
flutter run
```

### 3. Interface Web Admin
```bash
cd admin-web
npm install
npm run dev
```

## 📱 Configuration Google Maps

### Obtenir une clé API Google Maps
1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créer un projet
3. Activer les APIs :
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Créer une clé API

### Configuration Flutter
Voir le fichier `GOOGLE_MAPS_CONFIG.md` pour les instructions détaillées.

## 🧪 Tests

### Tester l'Application Client
```bash
# Identifiants de test
Téléphone : 776543210
Mot de passe : test123456
```

### Tester l'Application Chauffeur
```bash
# Créer un compte chauffeur depuis l'admin
# Ou utiliser un compte de test
```

### Tester l'Interface Admin
```bash
# Accéder à http://localhost:3001
# Utiliser un compte admin
```

## 📊 Flux de Fonctionnement

### Course Standard
1. **Client** : Recherche destination → Sélectionne type → Demande course
2. **Système** : Trouve chauffeurs disponibles → Envoie notification
3. **Chauffeur** : Accepte la course
4. **Système** : Connecte client et chauffeur
5. **Chauffeur** : Se déplace vers pickup → Démarre course
6. **Client** : Suivi en temps réel
7. **Chauffeur** : Termine course → Paiement
8. **Client + Chauffeur** : Notation mutuelle

### Covoiturage
1. **Chauffeur** : Active mode covoiturage
2. **Système** : Trouve courses compatibles sur le trajet
3. **Chauffeur** : Peut accepter jusqu'à 3 passagers
4. **Prix** : Réduit pour chaque passager (partage)

### Livraison de Colis
1. **Client** : Sélectionne "Livraison" → Saisit détails
2. **Client** : Prend photo du colis
3. **Système** : Trouve moto disponible
4. **Chauffeur** : Récupère colis → Confirme photo
5. **Système** : Génère code OTP pour destinataire
6. **Chauffeur** : Livre → Photo + Code OTP
7. **Système** : Confirme livraison → Paiement

## 🚀 Déploiement

### Backend (Heroku/Railway/DigitalOcean)
```bash
# Variables d'environnement à configurer
PORT
MONGODB_URI
JWT_SECRET
GOOGLE_MAPS_API_KEY
```

### Applications Mobile (Stores)
```bash
# iOS
cd dudu_flutter/ios
flutter build ios --release

# Android
cd dudu_flutter
flutter build apk --release
```

### Interface Web (Vercel/Netlify)
```bash
cd admin-web
npm run build
# Déployer le dossier dist/
```

## 🔐 Sécurité

- ✅ Authentification JWT
- ✅ Chiffrement HTTPS
- ✅ Validation des données
- ✅ Rate limiting
- ✅ Protection CORS
- ✅ Sanitisation des entrées

## 📈 Performances

- ⚡ Communication temps réel (Socket.io)
- 🗺️ Mise à jour GPS optimisée
- 💾 Cache intelligent
- 📊 Requêtes optimisées

## 🤝 Contributions

Ce projet est développé par l'équipe DUDU.

## 📄 Licence

Propriétaire - DUDU © 2024

## 📞 Support

Pour toute question ou assistance :
- Email : support@dudu.sn
- Documentation : `docs/`

## 🎉 Crédits

- **Framework Mobile** : Flutter
- **Backend** : Node.js + Express
- **Base de données** : MongoDB
- **Cartes** : Google Maps Platform
- **Temps réel** : Socket.io
- **UI** : Material Design

---

**Fait avec ❤️ au Sénégal 🇸🇳**
