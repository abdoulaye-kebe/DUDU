# 🌐 GUIDE COMPLET DE CONFIGURATION DES URLs - DUDU

**Date:** 20 Décembre 2024  
**Problème identifié:** Erreur d'inscription chauffeur - connexion impossible au serveur

---

## ❌ PROBLÈME IDENTIFIÉ DANS L'IMAGE

**Erreur visible:**
```
Exception: Erreur candidature chauffeur:
ClientException with SocketException: OS Error: Connection
timed out, errno = 110, address = 213.154.90.11, port = 37448
```

**Cause:** L'application mobile essaie de se connecter à `213.154.90.11` mais le serveur ne répond pas ou n'est pas accessible depuis l'émulateur.

---

## 🎯 CONFIGURATIONS NÉCESSAIRES

### **1. ÉMULATEUR ANDROID**
- ✅ **URL à utiliser:** `http://10.0.2.2:3000`
- ❌ **NE PAS utiliser:** `localhost` ou `127.0.0.1`
- **Raison:** `10.0.2.2` est l'alias pour `localhost` de la machine hôte dans l'émulateur Android

### **2. APPAREIL PHYSIQUE (même réseau WiFi)**
- ✅ **URL à utiliser:** `http://192.168.X.X:3000` (IP locale de votre PC)
- ❌ **NE PAS utiliser:** `localhost` ou `10.0.2.2`
- **Raison:** L'appareil doit accéder au serveur via le réseau local

### **3. PRODUCTION (serveur distant)**
- ✅ **URL à utiliser:** `http://213.154.90.11`
- **Raison:** Serveur de production accessible depuis internet

### **4. ADMIN WEB (Chrome/navigateur)**
- ✅ **Développement:** `http://localhost:3000`
- ✅ **Production:** `http://213.154.90.11`

---

## 🔧 SOLUTION INTELLIGENTE - DÉTECTION AUTOMATIQUE

Je vais créer une configuration intelligente qui détecte automatiquement l'environnement.

### **Stratégie:**
1. **Mode DEBUG + Émulateur Android** → `10.0.2.2:3000`
2. **Mode DEBUG + Appareil physique** → Permettre de choisir (local ou prod)
3. **Mode RELEASE** → `213.154.90.11` (production)

---

## 📝 FICHIERS À MODIFIER

### **1. Application Chauffeur**
`mobile_dudu_pro/lib/config/app_config.dart`

### **2. Application Client**
`dudu_flutter/lib/config/app_config.dart`

### **3. Admin Web**
`admin-web/src/config.js`

---

## 🚀 NOUVELLE CONFIGURATION INTELLIGENTE

### **Pour les Apps Flutter (Client & Chauffeur):**

```dart
static String get baseUrl {
  if (kDebugMode) {
    // En mode DEBUG, utiliser le serveur local
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Émulateur Android
      return '$androidEmulatorUrl/api/$apiVersion';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Simulateur iOS
      return '$localServerUrl/api/$apiVersion';
    } else {
      // Web ou autre
      return '$localServerUrl/api/$apiVersion';
    }
  } else {
    // En mode RELEASE, toujours utiliser la production
    return '$productionServerUrl/api/$apiVersion';
  }
}
```

### **Pour l'Admin Web:**

```javascript
// Détection automatique de l'environnement
const isDevelopment = window.location.hostname === 'localhost';

export const API_BASE_URL = isDevelopment
  ? 'http://localhost:3000/api/v1'
  : 'http://213.154.90.11/api/v1';

export const SOCKET_URL = isDevelopment
  ? 'http://localhost:3000'
  : 'http://213.154.90.11';
```

---

## 🧪 TESTS À EFFECTUER

### **Test 1: Émulateur Android + Serveur Local**
1. Démarrer le backend: `cd backend && npm start`
2. Vérifier que le serveur tourne sur `http://localhost:3000`
3. Lancer l'app sur émulateur
4. **Vérifier dans les logs:** `API URL: http://10.0.2.2:3000/api/v1`
5. Tester l'inscription chauffeur

### **Test 2: Émulateur Android + Serveur Production**
1. Compiler en mode RELEASE: `flutter build apk`
2. Installer l'APK sur l'émulateur
3. **Vérifier dans les logs:** `API URL: http://213.154.90.11/api/v1`
4. Tester l'inscription chauffeur

### **Test 3: Admin Web + Serveur Local**
1. Ouvrir Chrome sur `http://localhost:3001`
2. **Vérifier dans la console:** Appels vers `http://localhost:3000/api/v1`
3. Tester la réception des inscriptions

### **Test 4: Admin Web + Serveur Production**
1. Déployer l'admin web
2. Ouvrir sur le domaine de production
3. **Vérifier dans la console:** Appels vers `http://213.154.90.11/api/v1`

---

## ⚠️ PROBLÈMES POTENTIELS ET SOLUTIONS

### **Problème 1: Connection timed out (comme dans l'image)**

**Causes possibles:**
1. ❌ Le serveur backend n'est pas démarré
2. ❌ Le firewall bloque le port 3000
3. ❌ L'URL est incorrecte (localhost au lieu de 10.0.2.2)
4. ❌ Le serveur de production est down

**Solutions:**
```bash
# Vérifier que le backend tourne
cd backend
npm start

# Vérifier le port
netstat -ano | findstr :3000

# Tester l'accès depuis l'émulateur
# Dans l'émulateur, ouvrir Chrome et aller sur:
http://10.0.2.2:3000/api/v1/health
```

### **Problème 2: CORS Error**

**Cause:** Le backend refuse les requêtes cross-origin

**Solution:**
```javascript
// backend/src/app.js
app.use(cors({
  origin: ['http://localhost:3001', 'http://10.0.2.2:3000'],
  credentials: true
}));
```

### **Problème 3: Socket.io ne se connecte pas**

**Cause:** URL Socket.io incorrecte

**Solution:**
```dart
// Vérifier que socketUrl utilise le bon port
static String get socketUrl {
  if (kDebugMode) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
  return 'http://213.154.90.11:3000';
}
```

### **Problème 4: Certificat SSL (si HTTPS)**

**Cause:** Certificat auto-signé ou invalide

**Solution:**
```dart
// Pour le développement uniquement
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// Dans main.dart
void main() {
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(MyApp());
}
```

---

## 📊 TABLEAU RÉCAPITULATIF

| Environnement | App Mobile | Admin Web | Backend |
|---------------|------------|-----------|---------|
| **Émulateur + Local** | `10.0.2.2:3000` | `localhost:3000` | `localhost:3000` |
| **Appareil + Local** | `192.168.X.X:3000` | `localhost:3000` | `localhost:3000` |
| **Production** | `213.154.90.11` | `213.154.90.11` | `213.154.90.11` |

---

## 🔍 COMMANDES DE DIAGNOSTIC

### **Vérifier le backend:**
```bash
# Tester l'API
curl http://localhost:3000/api/v1/health

# Depuis l'émulateur (dans Chrome de l'émulateur)
http://10.0.2.2:3000/api/v1/health

# Production
curl http://213.154.90.11/api/v1/health
```

### **Vérifier les logs:**
```bash
# Backend
cd backend
npm start
# Regarder les logs pour voir les requêtes entrantes

# Flutter
flutter run
# Regarder les logs pour voir l'URL utilisée
```

---

## ✅ CHECKLIST DE VÉRIFICATION

- [ ] Backend démarré et accessible
- [ ] Configuration URL correcte pour l'environnement
- [ ] CORS configuré pour accepter les requêtes
- [ ] Firewall autorise le port 3000
- [ ] Socket.io configuré avec la bonne URL
- [ ] Logs montrent l'URL correcte
- [ ] Test d'inscription fonctionne
- [ ] Admin web reçoit les données

---

## 🎯 PROCHAINES ÉTAPES

1. **Modifier les fichiers de configuration** avec la détection automatique
2. **Redémarrer le backend** si nécessaire
3. **Recompiler les apps Flutter**
4. **Tester sur émulateur** avec serveur local
5. **Tester en production** avec serveur distant
6. **Documenter** les configurations qui fonctionnent

---

**Cette configuration intelligente résoudra tous les problèmes de connexion !** 🚀
