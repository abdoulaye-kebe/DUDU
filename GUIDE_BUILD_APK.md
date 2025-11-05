# 📱 Guide Build APK - DUDU

## 🚀 Commandes Rapides

### Option 1: Build Les Deux Apps (Recommandé)
```bash
# Double-cliquer sur:
rebuild-apps.bat
```

### Option 2: Build Séparément

#### App Client
```bash
# Double-cliquer sur:
build-client.bat
```

#### App Chauffeur
```bash
# Double-cliquer sur:
build-driver.bat
```

---

## 📋 Étapes Détaillées

### 1. Préparation

#### A. Vérifier Flutter
```bash
flutter doctor
```

Résultat attendu:
```
✓ Flutter (Channel stable, 3.x.x)
✓ Android toolchain
✓ Android Studio
```

#### B. Vérifier les Dépendances
```bash
# App Client
cd dudu_flutter
flutter pub get

# App Chauffeur
cd mobile_dudu_pro
flutter pub get
```

---

### 2. Build App Client

```bash
cd dudu_flutter

# Nettoyer
flutter clean

# Installer dépendances
flutter pub get

# Build APK Release
flutter build apk --release --no-tree-shake-icons
```

**APK généré:**
```
dudu_flutter/build/app/outputs/flutter-apk/app-release.apk
```

**Copier vers backend:**
```bash
copy build\app\outputs\flutter-apk\app-release.apk ..\backend\public\downloads\dudu-client.apk
```

---

### 3. Build App Chauffeur

```bash
cd mobile_dudu_pro

# Nettoyer
flutter clean

# Installer dépendances
flutter pub get

# Build APK Release
flutter build apk --release --no-tree-shake-icons
```

**APK généré:**
```
mobile_dudu_pro/build/app/outputs/flutter-apk/app-release.apk
```

**Copier vers backend:**
```bash
copy build\app\outputs\flutter-apk\app-release.apk ..\backend\public\downloads\dudu-driver.apk
```

---

## 🔧 Résolution Problèmes

### Problème 1: App Chauffeur Crash au Démarrage

**Cause:** Permissions de localisation manquantes

**Solution:** ✅ Déjà corrigé dans `AndroidManifest.xml`

Permissions ajoutées:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

**Gestion d'erreur:** Position par défaut (Dakar) si localisation échoue

---

### Problème 2: Build Échoue

#### Erreur: "Gradle build failed"

**Solution 1:** Nettoyer le cache
```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Solution 2:** Supprimer le dossier build
```bash
rmdir /s /q build
flutter build apk --release
```

**Solution 3:** Mettre à jour Gradle
```bash
cd android
gradlew clean
cd ..
flutter build apk --release
```

---

### Problème 3: APK Trop Gros

**Solution:** Build avec split-per-abi
```bash
flutter build apk --release --split-per-abi
```

Génère 3 APKs:
- `app-armeabi-v7a-release.apk` (ARM 32-bit)
- `app-arm64-v8a-release.apk` (ARM 64-bit) ← Recommandé
- `app-x86_64-release.apk` (x86 64-bit)

---

### Problème 4: Google Maps Ne S'Affiche Pas

**Cause:** Clé API manquante ou invalide

**Solution:** Vérifier `AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA" />
```

---

## 📦 Déploiement

### 1. Démarrer le Backend

```bash
cd backend
npm run dev
```

Serveur démarre sur: `http://41.208.146.203:3000`

### 2. Télécharger les APKs

#### Sur PC:
- Client: http://41.208.146.203:3000/download-client.html
- Chauffeur: http://41.208.146.203:3000/download-driver.html

#### Sur Mobile:
1. Ouvrir le navigateur
2. Aller sur l'URL ci-dessus
3. Cliquer sur "Télécharger"
4. Installer l'APK

---

## 🧪 Tests

### 1. Test App Client

```bash
# Installer sur téléphone
adb install backend/public/downloads/dudu-client.apk

# Ou via navigateur
# http://41.208.146.203:3000/download-client.html
```

**Tests:**
- ✅ Connexion
- ✅ Création de compte
- ✅ Recherche d'adresse
- ✅ Création de course
- ✅ Paiement

### 2. Test App Chauffeur

```bash
# Installer sur téléphone
adb install backend/public/downloads/dudu-driver.apk

# Ou via navigateur
# http://41.208.146.203:3000/download-driver.html
```

**Tests:**
- ✅ Connexion (776862514 / Azerty123)
- ✅ Dashboard s'affiche
- ✅ Carte Google Maps
- ✅ Bouton En ligne/Hors ligne
- ✅ Boutons Convoiturage et Femmes uniquement
- ✅ Profil chauffeur
- ✅ Paramètres

---

## 📊 Checklist Avant Build

### App Client
- [ ] `baseUrl` pointe vers IP publique (41.208.146.203)
- [ ] Permissions dans `AndroidManifest.xml`
- [ ] Clé Google Maps configurée
- [ ] Icône et nom d'app corrects
- [ ] Version incrémentée dans `pubspec.yaml`

### App Chauffeur
- [ ] `baseUrl` pointe vers IP publique (41.208.146.203)
- [ ] Permissions de localisation complètes
- [ ] Gestion d'erreur localisation (position par défaut)
- [ ] Clé Google Maps configurée
- [ ] Icône et nom d'app corrects
- [ ] Version incrémentée dans `pubspec.yaml`

---

## 🔄 Workflow Complet

### 1. Développement
```bash
# Tester en mode debug
flutter run -d chrome  # Web
flutter run            # Android émulateur
```

### 2. Corrections
```bash
# Faire les modifications
# Tester à nouveau
```

### 3. Build Release
```bash
# Utiliser les scripts
rebuild-apps.bat
```

### 4. Déploiement
```bash
# Démarrer backend
cd backend
npm run dev

# APKs disponibles sur:
# http://41.208.146.203:3000/download-client.html
# http://41.208.146.203:3000/download-driver.html
```

### 5. Tests
```bash
# Télécharger et installer sur téléphone
# Tester toutes les fonctionnalités
```

---

## 📝 Notes Importantes

### Permissions Android

**App Client:**
- Internet
- Localisation (fine et coarse)
- Réseau

**App Chauffeur:**
- Internet
- Localisation (fine, coarse, background)
- Réseau
- Foreground service
- Wake lock

### Gestion Localisation

**Position par défaut:** Dakar (14.6928, -17.4467)

Utilisée si:
- Service de localisation désactivé
- Permission refusée
- Timeout (10 secondes)
- Erreur

### URLs

**Mode Debug:**
- Web: `http://localhost:3000`
- Android émulateur: `http://10.0.2.2:3000`

**Mode Release:**
- `http://41.208.146.203:3000`

---

## ✅ Résumé

### Commandes Essentielles

```bash
# Build tout
rebuild-apps.bat

# Build client uniquement
build-client.bat

# Build chauffeur uniquement
build-driver.bat

# Nettoyer
flutter clean

# Installer dépendances
flutter pub get

# Build manuel
flutter build apk --release --no-tree-shake-icons
```

### Fichiers Importants

```
DUDU/
├── rebuild-apps.bat          ← Build les 2 apps
├── build-client.bat          ← Build client
├── build-driver.bat          ← Build chauffeur
├── backend/
│   └── public/
│       └── downloads/
│           ├── dudu-client.apk
│           └── dudu-driver.apk
├── dudu_flutter/             ← App client
└── mobile_dudu_pro/          ← App chauffeur
```

---

**Prêt à builder! 🚀**
