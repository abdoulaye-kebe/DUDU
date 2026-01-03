# 🔍 Guide Final de Vérification - DUDU

## 📅 Date : 3 janvier 2026

---

## ⚠️ RÉPONSE À VOTRE QUESTION : Chrome et Production

### **Question :** Si je run et build sur Chrome, je pourrai me connecter à la prod (213.154.90.11:3000) ?

### **Réponse :** ❌ **NON - Problème CORS**

**Explication :**

Quand vous lancez l'app Flutter sur **Chrome** (Web), votre navigateur va bloquer les requêtes vers `http://213.154.90.11:3000` à cause de la **politique CORS** (Cross-Origin Resource Sharing).

#### **Pourquoi ?**

1. **Votre app Flutter sur Chrome** tourne sur `http://localhost:PORT` (ex: `http://localhost:8080`)
2. **Le backend** tourne sur `http://213.154.90.11:3000`
3. Ce sont **deux origines différentes** → Chrome bloque par sécurité

#### **Ce qui se passera :**

```
Console Chrome:
❌ Access to XMLHttpRequest at 'http://213.154.90.11:3000/api/v1/auth/login' 
   from origin 'http://localhost:8080' has been blocked by CORS policy: 
   No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

---

## ✅ Solutions

### **Solution 1 : Ajouter CORS pour localhost (Recommandé pour dev)**

**Fichier :** `backend/src/server.js`

**Modifier la configuration CORS :**

```javascript
// Configuration CORS
const corsOptions = {
  origin: [
    'https://dudugroup.sn',
    'http://dudugroup.sn',
    'https://www.dudugroup.sn',
    'http://www.dudugroup.sn',
    'http://localhost:8080',      // ✨ AJOUTER CECI
    'http://localhost:3000',      // ✨ AJOUTER CECI
    'http://127.0.0.1:8080',      // ✨ AJOUTER CECI
    'http://127.0.0.1:3000'       // ✨ AJOUTER CECI
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));
```

**Puis redémarrer le backend :**
```bash
cd backend
pm2 restart dudu-api
```

### **Solution 2 : Utiliser localhost pour le backend (Dev uniquement)**

**Modifier :** `dudu_flutter/lib/config/app_config.dart`

```dart
static const String _env = String.fromEnvironment('ENV', defaultValue: 'local'); // Changer 'prod' en 'local'
```

**Puis lancer :**
```bash
cd backend
npm run dev  # Backend sur localhost:3000
```

```bash
cd dudu_flutter
flutter run -d chrome
```

### **Solution 3 : Build APK (Pas de problème CORS)**

**Sur Android/iOS, il n'y a PAS de problème CORS !**

Les apps mobiles natives peuvent se connecter directement à `http://213.154.90.11:3000` sans restriction.

---

## 📱 Guide : Build APK

### **Prérequis**

1. ✅ Android SDK installé
2. ✅ Flutter configuré (`flutter doctor`)
3. ✅ Connexion Internet

### **Étapes**

#### **1. Vérifier la configuration**

```bash
cd dudu_flutter
flutter doctor -v
```

**Vérifier que tout est ✅ pour Android**

#### **2. Nettoyer le projet**

```bash
flutter clean
flutter pub get
```

#### **3. Vérifier que l'app pointe vers la PROD**

**Fichier :** `dudu_flutter/lib/config/app_config.dart`

```dart
static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod'); // ✅ Doit être 'prod'
```

**Vérifier :**
```dart
static const String productionServerUrl = 'http://213.154.90.11:3000'; // ✅ OK
```

#### **4. Build APK de Debug (Pour tester)**

```bash
flutter build apk --debug
```

**Fichier généré :**
```
dudu_flutter/build/app/outputs/flutter-apk/app-debug.apk
```

#### **5. Build APK de Release (Pour production)**

```bash
flutter build apk --release
```

**Fichier généré :**
```
dudu_flutter/build/app/outputs/flutter-apk/app-release.apk
```

#### **6. Installer sur téléphone**

**Option A : Via USB**
```bash
flutter install
```

**Option B : Copier l'APK**
1. Copier `app-release.apk` sur votre téléphone
2. Ouvrir le fichier
3. Autoriser "Sources inconnues" si demandé
4. Installer

---

## 🧪 Tests à Effectuer

### **Test 1 : Connexion Backend**

**App Client (dudu_flutter)**

1. Lancer l'app
2. Aller sur écran de connexion
3. Entrer : `+221771234567` / `password123`
4. **Vérifier :** Connexion réussie
5. **Vérifier :** Dashboard s'affiche

**Logs attendus :**
```
✅ Socket.io connecté (Client)
✅ Profil chargé
```

### **Test 2 : Demande de Course**

1. Cliquer "Nouvelle course"
2. Choisir point de départ
3. Choisir destination
4. Proposer un prix (ex: 2000 FCFA)
5. Confirmer

**Vérifier :**
- ✅ Course créée
- ✅ Recherche de chauffeur
- ✅ Notification si chauffeur accepte

### **Test 3 : GPS Temps Réel**

**Prérequis :** Chauffeur doit accepter la course

1. Ouvrir app client
2. **Vérifier :** Carte affichée
3. **Vérifier :** Icône chauffeur se déplace toutes les 3 secondes
4. **Vérifier :** Position fluide

**Logs attendus :**
```
📍 Position chauffeur mise à jour
🚗 Chauffeur en route
```

### **Test 4 : Notifications Socket.io**

**Scénario complet :**

1. Client demande course
2. Chauffeur accepte → **Vérifier :** Notification "Chauffeur trouvé"
3. Chauffeur arrive → **Vérifier :** Notification "Chauffeur arrivé"
4. Chauffeur démarre → **Vérifier :** Notification "Course démarrée"
5. Chauffeur termine → **Vérifier :** Notification "Course terminée"

### **Test 5 : Rotation Automatique (Nouveau)**

**Scénario :**

1. Client demande course
2. Chauffeur A refuse
3. **Vérifier :** Client ne voit PAS le refus
4. **Vérifier :** Chauffeur B reçoit automatiquement
5. Chauffeur B accepte
6. **Vérifier :** Course continue normalement

### **Test 6 : Rating Bidirectionnel (Nouveau)**

**Après course terminée :**

1. Client note chauffeur (5 étoiles)
2. Chauffeur note client (4 étoiles)
3. **Vérifier :** Les deux notes enregistrées
4. **Vérifier :** Note moyenne mise à jour

### **Test 7 : Litige (Nouveau)**

1. Client signale un problème
2. **Vérifier :** Litige créé
3. Admin résout
4. **Vérifier :** Client et chauffeur notifiés

### **Test 8 : Course Programmée (Nouveau)**

1. Client programme course pour demain 8h
2. **Vérifier :** Status "scheduled"
3. À 8h → **Vérifier :** Status passe à "requested"
4. **Vérifier :** Chauffeurs notifiés

---

## 🗺️ Vérification Google Maps

### **Clé API Google Maps**

**Fichier :** `dudu_flutter/lib/config/app_config.dart`

```dart
static const String googleMapsApiKey = 'AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA';
```

### **APIs Activées (Vérifier sur Google Cloud Console)**

1. ✅ **Maps SDK for Android**
2. ✅ **Maps SDK for iOS**
3. ✅ **Places API**
4. ✅ **Geocoding API**
5. ✅ **Directions API**

### **Test Carte**

1. Ouvrir app
2. **Vérifier :** Carte s'affiche
3. **Vérifier :** Position actuelle détectée
4. **Vérifier :** Autocomplete adresses fonctionne
5. **Vérifier :** Itinéraire affiché

---

## 🔧 Problèmes Courants

### **Problème 1 : "Failed to connect to backend"**

**Cause :** Backend non accessible

**Solution :**
```bash
# Vérifier que le backend tourne
ssh root@213.154.90.11
pm2 status

# Si arrêté
pm2 restart dudu-api
```

### **Problème 2 : "CORS Error" (Chrome uniquement)**

**Cause :** CORS non configuré pour localhost

**Solution :** Voir "Solution 1" ci-dessus

### **Problème 3 : "Socket.io disconnected"**

**Cause :** Token invalide ou backend redémarré

**Solution :**
1. Se déconnecter
2. Se reconnecter
3. Vérifier logs backend

### **Problème 4 : "Carte ne s'affiche pas"**

**Cause :** Clé API Google Maps invalide

**Solution :**
1. Vérifier la clé dans `app_config.dart`
2. Vérifier que les APIs sont activées sur Google Cloud
3. Vérifier les restrictions de la clé

### **Problème 5 : "GPS ne fonctionne pas"**

**Cause :** Permissions non accordées

**Solution :**
1. Paramètres téléphone → Apps → DUDU → Permissions
2. Activer "Localisation" → "Toujours autoriser"

---

## 📊 Checklist Finale

### **Backend**

- [ ] Backend tourne sur `213.154.90.11:3000`
- [ ] MongoDB connecté
- [ ] CORS configuré (si test sur Chrome)
- [ ] Socket.io opérationnel
- [ ] PM2 actif (`pm2 status`)

### **App Client (dudu_flutter)**

- [ ] Configuration pointe vers prod (`app_config.dart`)
- [ ] Google Maps API key valide
- [ ] Permissions localisation activées
- [ ] APK build réussi
- [ ] App installée sur téléphone

### **App Chauffeur (mobile_dudu_pro)**

- [ ] Configuration pointe vers prod
- [ ] GPS temps réel activé (3 sec)
- [ ] Socket.io envoie position
- [ ] APK build réussi
- [ ] App installée sur téléphone

### **Fonctionnalités**

- [ ] Connexion client fonctionne
- [ ] Connexion chauffeur fonctionne
- [ ] Demande de course fonctionne
- [ ] Acceptation course fonctionne
- [ ] GPS temps réel fonctionne (3 sec)
- [ ] Notifications Socket.io fonctionnent
- [ ] Rotation automatique fonctionne
- [ ] Rating bidirectionnel fonctionne
- [ ] Litiges fonctionnent
- [ ] Courses programmées fonctionnent

---

## 🚀 Commandes Rapides

### **Backend**

```bash
# Vérifier status
ssh root@213.154.90.11
pm2 status

# Redémarrer
pm2 restart dudu-api

# Voir logs
pm2 logs dudu-api

# Arrêter
pm2 stop dudu-api

# Démarrer
pm2 start dudu-api
```

### **App Client**

```bash
# Nettoyer
cd dudu_flutter
flutter clean
flutter pub get

# Lancer sur Chrome (Dev uniquement)
flutter run -d chrome

# Build APK Debug
flutter build apk --debug

# Build APK Release
flutter build apk --release

# Installer sur téléphone
flutter install
```

### **App Chauffeur**

```bash
# Nettoyer
cd mobile_dudu_pro
flutter clean
flutter pub get

# Build APK Release
flutter build apk --release
```

---

## 📞 Support

### **Logs Importants**

**Backend :**
```bash
pm2 logs dudu-api --lines 100
```

**App Flutter :**
```bash
flutter logs
```

### **Tester API Directement**

**Connexion :**
```bash
curl -X POST http://213.154.90.11:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "+221771234567", "password": "password123"}'
```

**Health Check :**
```bash
curl http://213.154.90.11:3000/api/v1/health
```

---

## 📝 Résumé

### **Pour Chrome/Web :**
❌ **Problème CORS** - Nécessite configuration backend

### **Pour APK Android :**
✅ **Pas de problème** - Fonctionne directement avec la prod

### **Recommandation :**
1. **Développement :** Utiliser localhost pour backend + Chrome
2. **Tests :** Build APK et tester sur téléphone réel
3. **Production :** APK Release avec backend prod

---

**Date de dernière mise à jour :** 3 janvier 2026  
**Version :** v1.0  
**Statut :** Toutes les améliorations implémentées ✅
