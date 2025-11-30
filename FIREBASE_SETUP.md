# Guide de Configuration Firebase pour DUDU Pro

Ce guide vous explique comment configurer Firebase dans votre projet DUDU Pro pour permettre la collaboration entre développeurs.

## 📋 Prérequis

- Un compte Google (Gmail)
- Flutter SDK installé
- Android Studio ou Xcode installé selon votre plateforme cible

## 🔥 Étape 1 : Créer un Projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur **"Ajouter un projet"** ou **"Add project"**
3. Entrez le nom du projet : **"DUDU Pro"** (ou votre nom préféré)
4. Activez Google Analytics (recommandé)
5. Créez le projet

## 📱 Étape 2 : Ajouter les Applications

### Pour Android

1. Dans la console Firebase, cliquez sur l'icône Android
2. Entrez le **package name** de votre app :
   - Regardez dans `mobile_dudu_pro/android/app/build.gradle.kts`
   - Cherchez `applicationId` (ex: `com.dudu.mobile_dudu_pro`)
3. Entrez un nom d'application (ex: "DUDU Pro Android")
4. Téléchargez le fichier `google-services.json`
5. Placez-le dans : `mobile_dudu_pro/android/app/google-services.json`

### Pour iOS

1. Dans la console Firebase, cliquez sur l'icône iOS
2. Entrez le **Bundle ID** :
   - Regardez dans `mobile_dudu_pro/ios/Runner.xcodeproj` ou dans Xcode
   - (ex: `com.dudu.mobileDuduPro`)
3. Téléchargez le fichier `GoogleService-Info.plist`
4. Placez-le dans : `mobile_dudu_pro/ios/Runner/GoogleService-Info.plist`
5. **Important** : Ajoutez le fichier au projet Xcode :
   - Ouvrez `mobile_dudu_pro/ios/Runner.xcworkspace` dans Xcode
   - Glissez-déposez `GoogleService-Info.plist` dans le dossier `Runner`
   - Cochez "Copy items if needed"

## 🔧 Étape 3 : Configuration des Build Files

### Android

Ajoutez le plugin Google Services dans `mobile_dudu_pro/android/build.gradle.kts` :

```kotlin
buildscript {
    dependencies {
        // ...
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

Dans `mobile_dudu_pro/android/app/build.gradle.kts`, ajoutez en bas :

```kotlin
plugins {
    // ...
    id("com.google.gms.google-services")
}
```

### iOS

Dans `mobile_dudu_pro/ios/Podfile`, ajoutez si nécessaire :

```ruby
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'Firebase/Messaging'
pod 'Firebase/Storage'
```

Puis exécutez dans le terminal :
```bash
cd mobile_dudu_pro/ios
pod install
```

## 📦 Étape 4 : Installer les Dépendances Flutter

Dans le terminal, exécutez :

```bash
cd mobile_dudu_pro
flutter pub get
```

## 🗄️ Étape 5 : Configurer Firestore Database

1. Dans la console Firebase, allez dans **"Firestore Database"**
2. Cliquez sur **"Créer une base de données"** ou **"Create database"**
3. Choisissez **"Mode production"** (ou **"Mode test"** pour développement)
4. Sélectionnez une région proche (ex: `europe-west` pour l'Afrique de l'Ouest)
5. Créez la base de données

### Règles de Sécurité Firestore (Mode Test - à ajuster pour production)

Dans l'onglet "Règles" de Firestore, pour le développement :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permettre l'accès aux chauffeurs pour leur propre document
    match /drivers/{driverId} {
      allow read, write: if request.auth != null && request.auth.uid == driverId;
    }
    
    // Permettre la lecture des courses à proximité, écriture pour les propriétaires
    match /rides/{rideId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        request.resource.data.driver == request.auth.uid ||
        resource.data.driver == request.auth.uid
      );
    }
    
    // Abonnements
    match /subscriptions/{subscriptionId} {
      allow read, write: if request.auth != null && 
        resource.data.driverId == request.auth.uid;
    }
    
    // Plans d'abonnement - lecture seule pour tous les utilisateurs authentifiés
    match /subscription_plans/{planId} {
      allow read: if request.auth != null;
      allow write: if false; // Seulement via la console admin
    }
  }
}
```

⚠️ **ATTENTION** : Ces règles sont pour le développement. Pour la production, renforcez la sécurité !

## 👤 Étape 6 : Configurer Firebase Authentication

1. Dans la console Firebase, allez dans **"Authentication"**
2. Cliquez sur **"Commencer"** ou **"Get started"**
3. Activez **"Email/Password"** (Sign-in method)
   - Pour une meilleure sécurité, vous pouvez aussi activer **"Phone"** plus tard

## 📊 Étape 7 : Structure des Collections Firestore

Votre base de données Firestore utilisera les collections suivantes :

### Collection `drivers`
```json
{
  "id": "uid_du_chauffeur",
  "firstName": "Prénom",
  "lastName": "Nom",
  "phone": "+221771234567",
  "email": "chauffeur@dudu.sn",
  "vehicleType": "car" | "moto",
  "vehicle": {
    "make": "Toyota",
    "model": "Corolla",
    "year": 2020,
    "color": "Blanc",
    "plateNumber": "DK-1234-AB",
    "type": "standard",
    "capacity": 4
  },
  "stats": {
    "totalRides": 100,
    "completedRides": 95,
    "cancelledRides": 5,
    "averageRating": 4.8,
    "totalEarnings": 500000,
    "totalDistance": 5000,
    "todayRides": 5,
    "todayEarnings": 25000,
    "weeklyRides": 20,
    "weeklyEarnings": 100000,
    "bonusEarned": 0
  },
  "isOnline": false,
  "isAvailable": false,
  "currentLocation": {
    "latitude": 14.6928,
    "longitude": -17.4467,
    "address": "Adresse complète",
    "timestamp": "2024-01-01T12:00:00Z"
  },
  "location": GeoPoint(14.6928, -17.4467),
  "subscription": {
    "id": "subscription_id",
    "type": "monthly",
    "status": "active"
  },
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### Collection `rides`
```json
{
  "id": "ride_id",
  "rideId": "RIDE-123456",
  "passenger": "passenger_id",
  "driver": "driver_id",
  "pickup": {
    "address": "Adresse de départ",
    "coordinates": {
      "latitude": 14.6928,
      "longitude": -17.4467
    },
    "instructions": "Instructions optionnelles"
  },
  "destination": {
    "address": "Adresse d'arrivée",
    "coordinates": {
      "latitude": 14.7896,
      "longitude": -16.9260
    }
  },
  "pricing": {
    "basePrice": 500,
    "distancePrice": 1000,
    "timePrice": 500,
    "surgeMultiplier": 1.0,
    "totalPrice": 2000,
    "currency": "XOF"
  },
  "status": "requested" | "accepted" | "arrived" | "started" | "completed" | "cancelled",
  "rideType": "standard" | "express" | "shared" | "delivery",
  "vehicleCategory": "car" | "moto",
  "passengers": 1,
  "requestedAt": Timestamp,
  "acceptedAt": Timestamp,
  "arrivedAt": Timestamp,
  "startedAt": Timestamp,
  "completedAt": Timestamp,
  "cancelledAt": Timestamp
}
```

### Collection `subscriptions`
```json
{
  "id": "subscription_id",
  "driverId": "driver_uid",
  "planId": "plan_id",
  "type": "daily" | "weekly" | "monthly" | "yearly",
  "name": "Plan Mensuel",
  "price": 15000,
  "currency": "XOF",
  "duration": 30,
  "features": ["feature1", "feature2"],
  "status": "active" | "expired" | "cancelled",
  "startDate": Timestamp,
  "endDate": Timestamp,
  "paymentMethod": "orange_money",
  "autoRenew": false,
  "createdAt": Timestamp
}
```

### Collection `subscription_plans`
```json
{
  "id": "plan_id",
  "type": "monthly",
  "name": "Plan Mensuel",
  "price": 15000,
  "currency": "XOF",
  "duration": 30,
  "vehicleType": "car" | "moto",
  "features": ["feature1", "feature2"],
  "isAvailable": true
}
```

## 🚀 Étape 8 : Tester la Configuration

1. Assurez-vous que tous les fichiers sont en place
2. Exécutez l'application :
   ```bash
   flutter run
   ```
3. Vérifiez dans les logs qu'il n'y a pas d'erreur Firebase

## 👥 Étape 9 : Partage avec vos Collaborateurs

Pour que votre collaborateur puisse travailler sur le même projet :

1. **Partagez les fichiers de configuration Firebase** :
   - `mobile_dudu_pro/android/app/google-services.json`
   - `mobile_dudu_pro/ios/Runner/GoogleService-Info.plist`
   - ⚠️ **Ne les commitez PAS dans Git** si vous préférez (ajoutez-les au `.gitignore`)
   - Ou partagez-les via un moyen sécurisé (Drive, email sécurisé, etc.)

2. **Partagez les identifiants Firebase** (optionnel) :
   - Ajoutez votre collaborateur comme membre du projet dans Firebase Console
   - Aller dans "Paramètres du projet" > "Utilisateurs et autorisations"
   - Invitez votre collaborateur avec son email

3. **Documentez la structure** :
   - Les collections et leur structure sont définies ci-dessus
   - Utilisez le service `FirebaseService` dans le code pour interagir avec Firestore

## 🔒 Sécurité

- **Pour la production** : Modifiez les règles Firestore pour plus de sécurité
- **Authentification** : Utilisez Firebase Authentication pour sécuriser l'accès
- **Données sensibles** : Ne stockez jamais de mots de passe en clair dans Firestore

## 📚 Ressources

- [Documentation Firebase Flutter](https://firebase.flutter.dev/)
- [Documentation Firestore](https://firebase.google.com/docs/firestore)
- [Règles de sécurité Firestore](https://firebase.google.com/docs/firestore/security/get-started)

## ❓ Problèmes Courants

### Erreur : "FirebaseApp not initialized"
- Assurez-vous que `Firebase.initializeApp()` est appelé dans `main.dart`
- Vérifiez que les fichiers de configuration sont présents

### Erreur : "MissingPluginException"
- Exécutez `flutter clean && flutter pub get`
- Pour Android : `cd android && ./gradlew clean`
- Pour iOS : `cd ios && pod install`

### Erreur : "Permission denied" dans Firestore
- Vérifiez les règles de sécurité Firestore
- Assurez-vous que l'utilisateur est authentifié

---

Bon développement ! 🚀

