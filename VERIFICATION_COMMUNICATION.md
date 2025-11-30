# ✅ Vérification Communication Backend ↔ Application Client

## 📋 Configuration Actuelle

### **Application Client (Flutter - dudu_flutter)**

#### URLs de Connexion selon la Plateforme :
- **iOS Simulator** : `http://127.0.0.1:3000/api/v1`
- **Android Emulator** : `http://10.0.2.2:3000/api/v1`
- **Web** : `http://127.0.0.1:3000/api/v1`

#### Routes d'Authentification Utilisées :
1. **Connexion** : `POST /api/v1/auth/login`
   - Paramètres : `{ phone, password }`
   - Fichier : `dudu_flutter/lib/services/api_service.dart:74`
   - Utilisé dans : `dudu_flutter/lib/providers/auth_provider.dart:28`

2. **Inscription** : `POST /api/v1/auth/register`
   - Paramètres : `{ firstName, lastName, phone, password, language?, referralCode? }`
   - Fichier : `dudu_flutter/lib/services/api_service.dart:104`
   - Utilisé dans : `dudu_flutter/lib/providers/auth_provider.dart:66`

3. **Vérification SMS** : `POST /api/v1/auth/verify`
   - Paramètres : `{ phone, code }`
   - Fichier : `dudu_flutter/lib/services/api_service.dart:151`

4. **Profil utilisateur** : `GET /api/v1/auth/me`
   - Headers : `Authorization: Bearer {token}`
   - Fichier : `dudu_flutter/lib/services/api_service.dart:181`

---

### **Backend (Node.js/Express)**

#### Configuration :
- **Port** : `3000`
- **Base URL** : `http://localhost:3000/api/v1`
- **MongoDB** : `mongodb://localhost:27017/dudu`

#### Routes d'Authentification Disponibles :
1. **POST `/api/v1/auth/register`** ✅
   - Validation des données
   - Création de compte
   - Fichier : `backend/src/routes/auth.js:11`

2. **POST `/api/v1/auth/login`** ✅
   - Authentification par téléphone/mot de passe
   - Génération de token JWT
   - Fichier : `backend/src/routes/auth.js:76`

3. **POST `/api/v1/auth/verify`** ✅
   - Vérification du code SMS
   - Fichier : `backend/src/routes/auth.js:150`

4. **GET `/api/v1/auth/me`** ✅
   - Récupération du profil utilisateur (authentifié)
   - Fichier : `backend/src/routes/auth.js:208`

---

## ✅ État de la Communication

### **Configuration Correcte** ✅

| Élément | Statut | Détails |
|---------|--------|---------|
| **API Service Flutter** | ✅ Configuré | URLs adaptées par plateforme |
| **Routes Backend** | ✅ Disponibles | Toutes les routes d'auth existent |
| **AuthProvider** | ✅ Connecté | Utilise `ApiService.login()` et `ApiService.register()` |
| **Gestion Token** | ✅ Implémentée | Sauvegarde dans `SharedPreferences` |
| **Headers HTTP** | ✅ Configurés | Token ajouté automatiquement |

---

## 🔍 Vérifications à Effectuer

### 1. **Backend Démarré ?**
```bash
cd backend
npm start
# Devrait afficher : "🚀 Serveur DUDU démarré sur le port 3000"
```

### 2. **MongoDB Connecté ?**
```bash
# Vérifier que MongoDB tourne
brew services list | grep mongodb
# Devrait afficher : "mongodb-community@7.0 started"

# Vérifier la connexion
mongosh
# > use dudu
# > show collections
```

### 3. **Test de Connexion depuis l'App**

#### Scénario de Test - Connexion :
1. Ouvrir l'app `dudu_flutter`
2. Aller sur l'écran de connexion
3. Entrer un numéro : `+221771234567`
4. Entrer un mot de passe : `password123`
5. Cliquer sur "Se connecter"

#### Scénario de Test - Inscription :
1. Aller sur l'écran d'inscription
2. Remplir le formulaire :
   - Prénom : `Test`
   - Nom : `User`
   - Téléphone : `+221771234567`
   - Mot de passe : `password123`
3. Cliquer sur "S'inscrire"

---

## 🐛 Problèmes Potentiels et Solutions

### ❌ Erreur : "Connection refused"

**Cause** : Backend non démarré ou port différent

**Solution** :
```bash
# Démarrer le backend
cd backend
npm start

# Vérifier le port
lsof -i :3000
```

---

### ❌ Erreur : "MongoDB connection failed"

**Cause** : MongoDB non démarré

**Solution** :
```bash
# Démarrer MongoDB
brew services start mongodb-community@7.0

# Vérifier
brew services list | grep mongodb
```

---

### ❌ Erreur : "Invalid phone format"

**Cause** : Format de téléphone incorrect

**Solution** :
- Format attendu : `+221771234567` ou `221771234567` ou `771234567`
- Le backend normalise automatiquement le format

---

### ❌ Erreur : "User not found" ou "Invalid password"

**Cause** : Utilisateur non existant ou mot de passe incorrect

**Solution** :
- S'inscrire d'abord via l'écran d'inscription
- Ou créer un utilisateur directement dans MongoDB :
```javascript
// Dans mongosh
use dudu
db.users.insertOne({
  phone: "+221771234567",
  password: "$2b$10$...", // Hash bcrypt
  firstName: "Test",
  lastName: "User"
})
```

---

## 📊 Flux de Communication

### **Connexion (Login)**
```
┌─────────────┐                    ┌──────────┐                    ┌──────────┐
│  Flutter    │                    │ Backend  │                    │ MongoDB  │
│   Client    │                    │          │                    │          │
└──────┬──────┘                    └────┬─────┘                    └────┬─────┘
       │                                 │                               │
       │  1. POST /auth/login           │                               │
       │     { phone, password }        │                               │
       │───────────────────────────────>│                               │
       │                                 │                               │
       │                                 │  2. Recherche utilisateur    │
       │                                 │─────────────────────────────>│
       │                                 │                               │
       │                                 │  3. Vérification password    │
       │                                 │<─────────────────────────────│
       │                                 │                               │
       │                                 │  4. Génération JWT token     │
       │                                 │                               │
       │  5. Response {                 │                               │
       │       user, token              │                               │
       │     }                          │                               │
       │<───────────────────────────────│                               │
       │                                 │                               │
       │  6. Sauvegarde token local     │                               │
       │     (SharedPreferences)        │                               │
       │                                 │                               │
```

### **Inscription (Register)**
```
┌─────────────┐                    ┌──────────┐                    ┌──────────┐
│  Flutter    │                    │ Backend  │                    │ MongoDB  │
│   Client    │                    │          │                    │          │
└──────┬──────┘                    └────┬─────┘                    └────┬─────┘
       │                                 │                               │
       │  1. POST /auth/register        │                               │
       │     { firstName, lastName,     │                               │
       │       phone, password }        │                               │
       │───────────────────────────────>│                               │
       │                                 │                               │
       │                                 │  2. Validation données        │
       │                                 │                               │
       │                                 │  3. Hash password (bcrypt)   │
       │                                 │                               │
       │                                 │  4. Création utilisateur      │
       │                                 │─────────────────────────────>│
       │                                 │                               │
       │                                 │  5. Confirmation création     │
       │                                 │<─────────────────────────────│
       │                                 │                               │
       │                                 │  6. Génération JWT token     │
       │                                 │                               │
       │  7. Response {                 │                               │
       │       user, token              │                               │
       │     }                          │                               │
       │<───────────────────────────────│                               │
       │                                 │                               │
       │  8. Sauvegarde token local     │                               │
       │                                 │                               │
```

---

## ✅ Conclusion

**OUI, la communication est CONFIGURÉE** entre :
- ✅ Application Client (`dudu_flutter`) ↔ Backend
- ✅ Routes d'authentification : Login, Register, Verify, Profile
- ✅ Gestion des tokens JWT
- ✅ Sauvegarde locale des données utilisateur

**Pour que tout fonctionne, il faut :**
1. ✅ MongoDB démarré (`brew services start mongodb-community@7.0`)
2. ✅ Backend démarré (`cd backend && npm start`)
3. ✅ Application Flutter lancée (`cd dudu_flutter && flutter run`)

---

## 🧪 Test Rapide

```bash
# 1. Démarrer MongoDB
brew services start mongodb-community@7.0

# 2. Démarrer le backend
cd backend
npm start

# 3. Dans un autre terminal, tester l'API
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "+221771234567", "password": "test123"}'

# 4. Lancer l'application Flutter
cd ../dudu_flutter
flutter run
```






