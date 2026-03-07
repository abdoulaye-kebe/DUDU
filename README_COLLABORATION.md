# 🚀 DUDU - Guide de Collaboration Développeur

## 📋 Vue d'ensemble du projet

**DUDU** est une application de transport/covoiturage complète avec :
- **Backend** : Node.js + Express + MongoDB
- **Client App** : Flutter (pour les passagers)
- **Driver App** : Flutter (pour les chauffeurs)
- **Admin Web** : React.js (interface d'administration)

## 🗂️ Structure du projet

```
DUDU/
├── backend/                 # API Backend (Node.js)
├── dudu_flutter/           # App Client (Flutter)
├── mobile_dudu_pro/        # App Chauffeur (Flutter)
├── admin-web/              # Interface Admin (React)
├── docs/                   # Documentation
└── *.md                    # Fichiers de documentation
```

## 🚀 Installation rapide

### 1. Prérequis

**Système requis :**
- **Node.js** v18+ : [nodejs.org](https://nodejs.org)
- **Flutter** v3.0+ : [flutter.dev](https://flutter.dev)
- **MongoDB** : [mongodb.com](https://www.mongodb.com)
- **Git** : [git-scm.com](https://git-scm.com)

**Installation macOS :**
```bash
# Node.js
brew install node

# MongoDB
brew install mongodb-community

# Flutter
brew install flutter

# Git (si pas installé)
brew install git
```

**Installation Ubuntu :**
```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# MongoDB
sudo apt install mongodb

# Flutter
sudo snap install flutter --classic
```

### 2. Cloner le projet

```bash
git clone https://github.com/votre-username/DUDU.git
cd DUDU
```

### 3. Configuration Backend

```bash
cd backend

# Installer les dépendances
npm install

# Copier la configuration
cp env.example .env

# Éditer la configuration (optionnel)
nano .env

# Démarrer MongoDB
mongod

# Démarrer le serveur (dans un autre terminal)
npm start
```

### 4. Configuration Apps Flutter

**App Client :**
```bash
cd dudu_flutter
flutter pub get
flutter run
```

**App Chauffeur :**
```bash
cd mobile_dudu_pro
flutter pub get
flutter run
```

**Admin Web :**
```bash
cd admin-web
npm install
npm start
```

## 🔧 Configuration détaillée

### Base de données MongoDB

**Option 1 : MongoDB Local**
```env
MONGODB_URI=mongodb://localhost:27017/dudu
```

**Option 2 : MongoDB Atlas (Cloud)**
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/dudu
```

### APIs externes

**Google Maps (Déjà configuré) :**
```env
GOOGLE_MAPS_API_KEY=AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA
```

**Autres APIs (Optionnelles) :**
```env
# Paiements mobiles
ORANGE_MONEY_API_KEY=your-key
WAVE_API_KEY=your-key
FREE_MONEY_API_KEY=your-key

# SMS
SMS_API_KEY=your-key

# Email
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

## 📊 État actuel du projet

### ✅ Fonctionnalités implémentées

**Backend :**
- ✅ Authentification JWT
- ✅ Gestion des utilisateurs (22 utilisateurs)
- ✅ Gestion des chauffeurs (11 chauffeurs)
- ✅ Système de courses
- ✅ Paiements
- ✅ Abonnements
- ✅ Socket.io pour temps réel
- ✅ API REST complète

**Apps Flutter :**
- ✅ Cartes Google Maps interactives
- ✅ Géolocalisation temps réel
- ✅ Autocomplétion d'adresses
- ✅ Interface utilisateur moderne
- ✅ Système de navigation
- ✅ Gestion des courses

**Admin Web :**
- ✅ Dashboard
- ✅ Gestion des chauffeurs
- ✅ Gestion des courses
- ✅ Interface d'administration

### 🔄 En cours de développement

- 🔄 Intégration Google Maps dans le backend
- 🔄 Système de paiement mobile
- 🔄 Notifications push
- 🔄 Système de rating

## 🛠️ Commandes utiles

### Backend
```bash
# Démarrer le serveur
npm start

# Mode développement avec rechargement
npm run dev

# Tests
npm test

# Vérifier la santé de l'API
curl http://localhost:3000/api/health
```

### Flutter
```bash
# Installer les dépendances
flutter pub get

# Nettoyer le cache
flutter clean

# Construire pour Android
flutter build apk

# Construire pour iOS
flutter build ios

# Lancer sur émulateur
flutter run
```

### MongoDB
```bash
# Démarrer MongoDB
mongod

# Se connecter à la base
mongosh dudu

# Voir les collections
db.getCollectionNames()

# Compter les documents
db.users.countDocuments()
```

## 🌐 URLs et ports

| Service | URL | Port |
|---------|-----|------|
| **Backend API** | http://localhost:3000 | 3000 |
| **Client App** | Flutter | - |
| **Driver App** | Flutter | - |
| **Admin Web** | http://localhost:3001 | 3001 |
| **MongoDB** | mongodb://localhost:27017 | 27017 |

## 📱 APIs principales

### Authentification
```bash
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
```

### Utilisateurs
```bash
GET /api/v1/users
GET /api/v1/users/:id
PUT /api/v1/users/:id
```

### Chauffeurs
```bash
GET /api/v1/drivers
POST /api/v1/drivers
PUT /api/v1/drivers/:id
```

### Courses
```bash
POST /api/v1/rides
GET /api/v1/rides
PUT /api/v1/rides/:id/status
```

## 🐛 Dépannage

### Problèmes courants

**1. MongoDB ne démarre pas :**
```bash
# Vérifier si MongoDB est installé
which mongod

# Démarrer MongoDB
mongod

# Vérifier la connexion
mongosh --eval "db.runCommand('ping')"
```

**2. Flutter ne trouve pas les dépendances :**
```bash
flutter clean
flutter pub get
```

**3. Backend ne se connecte pas à MongoDB :**
```bash
# Vérifier le fichier .env
cat backend/.env

# Tester la connexion
cd backend
node -e "require('dotenv').config(); const mongoose = require('mongoose'); mongoose.connect(process.env.MONGODB_URI).then(() => console.log('✅ Connecté')).catch(err => console.error('❌ Erreur:', err.message));"
```

**4. Port déjà utilisé :**
```bash
# Trouver le processus utilisant le port
lsof -i :3000

# Tuer le processus
kill -9 PID
```

## 📞 Support

### Contacts
- **Développeur principal** : [Votre nom]
- **Email** : [votre-email@example.com]
- **GitHub** : [votre-github-username]

### Ressources
- **Documentation Flutter** : [flutter.dev/docs](https://flutter.dev/docs)
- **Documentation Node.js** : [nodejs.org/docs](https://nodejs.org/docs)
- **Documentation MongoDB** : [docs.mongodb.com](https://docs.mongodb.com)

## 📝 Notes importantes

### Sécurité
- ⚠️ Ne jamais commiter le fichier `.env`
- ⚠️ Changer les clés API en production
- ⚠️ Utiliser HTTPS en production

### Développement
- 🔄 Toujours tester sur émulateur avant déploiement
- 🔄 Utiliser Git pour versionner le code
- 🔄 Documenter les nouvelles fonctionnalités

### Production
- 🚀 Utiliser MongoDB Atlas pour la production
- 🚀 Configurer les variables d'environnement
- 🚀 Utiliser un reverse proxy (Nginx)

---

## 🎯 Prochaines étapes

1. **Cloner le projet** et suivre les instructions d'installation
2. **Configurer l'environnement** avec le fichier `.env`
3. **Tester les APIs** avec les endpoints fournis
4. **Développer de nouvelles fonctionnalités**
5. **Partager les améliorations** via Git

**Bon développement ! 🚀**










