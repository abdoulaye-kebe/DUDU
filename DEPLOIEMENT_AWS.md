# 🚀 Guide de Déploiement DUDU sur AWS

## 📍 Informations Serveur

| Élément | Valeur |
|---------|--------|
| **IP Serveur AWS** | `213.154.90.11` |
| **Port Backend** | `3000` |
| **URL API** | `http://213.154.90.11:3000/api/v1` |
| **URL Socket** | `http://213.154.90.11:3000` |

---

## 📱 URLs de Téléchargement des Applications

### Page de Téléchargement Client
```
http://213.154.90.11:3000/download-client.html
```

### Page de Téléchargement Chauffeur
```
http://213.154.90.11:3000/download-driver.html
```

### Téléchargement Direct APK

| Application | URL |
|-------------|-----|
| **DUDU Client** | `http://213.154.90.11:3000/downloads/dudu-client.apk` |
| **DUDU Pro (Chauffeur)** | `http://213.154.90.11:3000/downloads/dudu-driver.apk` |

---

## 🔧 Configuration Actuelle

### Apps Flutter (Mode Release)
Les apps sont configurées pour pointer vers le serveur AWS en mode release :

**Client (`dudu_flutter/lib/config/app_config.dart`):**
```dart
static const String productionServerUrl = 'http://213.154.90.11';
```

**Chauffeur (`mobile_dudu_pro/lib/config/app_config.dart`):**
```dart
static const String productionServerUrl = 'http://213.154.90.11';
```

---

## 📦 Génération des APK pour Production

### 1. Build APK Client
```bash
cd dudu_flutter
flutter clean
flutter pub get
flutter build apk --release
```

L'APK sera généré dans :
```
dudu_flutter/build/app/outputs/flutter-apk/app-release.apk
```

Copier vers le serveur :
```bash
copy build\app\outputs\flutter-apk\app-release.apk ..\backend\public\downloads\dudu-client.apk
```

### 2. Build APK Chauffeur
```bash
cd mobile_dudu_pro
flutter clean
flutter pub get
flutter build apk --release
```

L'APK sera généré dans :
```
mobile_dudu_pro/build/app/outputs/flutter-apk/app-release.apk
```

Copier vers le serveur :
```bash
copy build\app\outputs\flutter-apk\app-release.apk ..\backend\public\downloads\dudu-driver.apk
```

---

## 🖥️ Déploiement Backend sur AWS

### 1. Connexion au serveur
```bash
ssh user@213.154.90.11
```

### 2. Cloner/Mettre à jour le projet
```bash
cd /var/www
git clone <repo_url> dudu
# ou
cd dudu && git pull
```

### 3. Installer les dépendances
```bash
cd backend
npm install
```

### 4. Configuration environnement
Créer le fichier `.env` :
```bash
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
MONGODB_URI=mongodb://localhost:27017/dudu
JWT_SECRET=votre_secret_jwt_securise
```

### 5. Démarrer avec PM2
```bash
npm install -g pm2
pm2 start src/server.js --name dudu-backend
pm2 save
pm2 startup
```

---

## 🗄️ Base de Données

### Développement Local
- MongoDB local : `mongodb://localhost:27017/dudu`
- Les données restent sur ta machine

### Production (AWS)
- MongoDB sur le serveur : `mongodb://localhost:27017/dudu` (sur le serveur AWS)
- Les données sont sur le serveur AWS

### Migration des données (optionnel)
Pour copier les données locales vers le serveur :
```bash
# Export local
mongodump --db dudu --out ./backup

# Copier vers le serveur
scp -r ./backup user@213.154.90.11:/tmp/

# Sur le serveur, importer
mongorestore --db dudu /tmp/backup/dudu
```

---

## ✅ Checklist Déploiement

### Avant le Build
- [ ] Vérifier que `productionServerUrl` = `http://213.154.90.11`
- [ ] Vérifier que le backend est déployé sur AWS
- [ ] Vérifier que MongoDB est accessible sur AWS

### Build APK
- [ ] `flutter clean` sur les deux apps
- [ ] `flutter build apk --release` pour client
- [ ] `flutter build apk --release` pour chauffeur
- [ ] Copier les APK dans `backend/public/downloads/`

### Déploiement Serveur
- [ ] Backend démarré avec PM2
- [ ] MongoDB accessible
- [ ] Port 3000 ouvert dans le firewall AWS
- [ ] Test : `curl http://213.154.90.11:3000/api/health`

### Test Final
- [ ] Page téléchargement client accessible
- [ ] Page téléchargement chauffeur accessible
- [ ] APK téléchargeables
- [ ] Apps se connectent au backend AWS
- [ ] Inscription/Connexion fonctionnent

---

## 🔗 Liens Utiles pour le Client

Envoie ces liens à ton client :

### Téléchargement
- **App Client** : http://213.154.90.11:3000/download-client.html
- **App Chauffeur** : http://213.154.90.11:3000/download-driver.html

### Instructions d'installation
1. Ouvrir le lien sur le téléphone Android
2. Cliquer sur "Télécharger l'APK"
3. Autoriser l'installation depuis des sources inconnues
4. Installer l'application
5. Ouvrir et créer un compte

---

## 🐛 Dépannage

### L'app ne se connecte pas
1. Vérifier que le backend est démarré : `pm2 status`
2. Vérifier l'accès : `curl http://213.154.90.11:3000/api/health`
3. Vérifier le firewall AWS (port 3000 ouvert)

### APK ne se télécharge pas
1. Vérifier que les fichiers existent dans `public/downloads/`
2. Vérifier les permissions des fichiers

### Erreur de connexion MongoDB
1. Vérifier que MongoDB est démarré : `sudo systemctl status mongod`
2. Vérifier la connexion : `mongo --eval "db.stats()"`

---

**Date de mise à jour** : Décembre 2024
