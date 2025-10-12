# 🔔 Système de Notifications Push - DUDU

## 📋 Vue d'ensemble

Système intelligent de notifications push pour alerter les clients des opportunités de covoiturage et autres événements importants.

---

## 🎯 Types de Notifications

### 1. 🤝 Covoiturage Disponible

**Déclenchement :**
- 5+ chauffeurs activent covoiturage dans un rayon de 5km
- Client se trouve dans la zone

**Message :**
```
🤝 5 chauffeurs en covoiturage !
15 places disponibles • Économisez 600 FCFA
```

**Action :** Ouvre l'app sur l'écran de sélection "Partagé"

---

### 2. 💰 Prix Réduit

**Déclenchement :**
- Promotion active sur le covoiturage
- Heures creuses avec beaucoup de chauffeurs

**Message :**
```
💰 Prix réduit maintenant !
Économisez 600 FCFA avec le covoiturage
```

**Action :** Affiche les promotions actives

---

### 3. 🚗 Nouveau Chauffeur Proche

**Déclenchement :**
- Chauffeur active covoiturage à moins de 2km
- Client a récemment cherché une course

**Message :**
```
🚗 Nouveau chauffeur en covoiturage
Mamadou Sall est maintenant disponible à 1.2 km
```

---

### 4. ⏰ Rappel Habituel

**Déclenchement :**
- Basé sur l'historique du client
- À ses heures habituelles de trajet

**Message :**
```
🕐 Votre heure habituelle de trajet
Des chauffeurs en covoiturage sont disponibles près de vous
```

---

### 5. 🎉 Promotion Spéciale

**Déclenchement :**
- Événements spéciaux
- Heures de pointe

**Message :**
```
🎉 Promotion Covoiturage !
Profitez de -25% pendant 1h
```

---

### 6. ✅ Chauffeur Trouvé

**Déclenchement :**
- Quand un chauffeur accepte la course

**Message :**
```
✅ Chauffeur trouvé !
Mamadou Sall arrive dans 3 minutes
```

---

## 🔧 Configuration Firebase

### Backend (Node.js)

#### 1. Installation
```bash
cd backend
npm install firebase-admin
```

#### 2. Configuration
```javascript
// backend/config/firebase-adminsdk.json
// Télécharger depuis Firebase Console
{
  "type": "service_account",
  "project_id": "dudu-senegal",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  ...
}
```

#### 3. Initialisation
```javascript
// backend/src/services/notificationService.js
const admin = require('firebase-admin');
const serviceAccount = require('../../config/firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
```

---

### Frontend Flutter

#### 1. Installation
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.0.0
```

#### 2. Configuration Android

**android/app/build.gradle.kts**
```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Ajouter
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

**android/app/google-services.json**
```
Télécharger depuis Firebase Console
```

#### 3. Configuration iOS

**ios/Podfile**
```ruby
pod 'Firebase/Messaging'
```

**ios/Runner/Info.plist**
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

**ios/Runner/GoogleService-Info.plist**
```
Télécharger depuis Firebase Console
```

---

## 🚀 Utilisation

### Backend - Envoyer Notification

```javascript
const notificationService = require('./services/notificationService');

// Quand chauffeur active covoiturage
await notificationService.analyzeCarpoolAvailability({
  latitude: 14.7167,
  longitude: -17.4677
});

// Notification personnalisée
await notificationService.sendPushNotification(userId, {
  title: '🤝 Covoiturage disponible',
  body: '5 chauffeurs près de vous',
  data: {
    type: 'carpool_available',
    driversCount: '5'
  }
});
```

### Frontend Flutter - Recevoir Notifications

```dart
// main.dart
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  // Initialiser notifications
  await NotificationService().initialize();
  
  runApp(const DUDUApp());
}

// Écouter les notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('📬 Message reçu: ${message.notification?.title}');
  
  // Afficher notification locale
  NotificationService().showNotification(
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
  );
});

// Quand notification tapée
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('👆 Notification tapée');
  // Navigation...
});
```

---

## 📊 Logique Intelligente

### Seuils de Déclenchement

```javascript
// backend/src/services/notificationService.js

async analyzeCarpoolAvailability(location) {
  const drivers = await Driver.find({
    status: 'online',
    'preferences.acceptSharedRides': true,
    'preferences.carpoolSeats': { $gt: 0 }
  });

  const driversCount = drivers.length;
  const totalSeats = drivers.reduce((sum, d) => 
    sum + d.preferences.carpoolSeats, 0
  );

  // Seuil 1 : Beaucoup de chauffeurs (5+)
  if (driversCount >= 5) {
    await this.notifyUsersInArea(location, 3, {
      title: '🤝 Beaucoup de covoiturages !',
      body: `${driversCount} chauffeurs • ${totalSeats} places`
    });
  }

  // Seuil 2 : Augmentation soudaine (+3 en 5min)
  const recentIncrease = await this.checkRecentIncrease(location);
  if (recentIncrease >= 3) {
    await this.notifyUsersInArea(location, 2, {
      title: '📈 Forte disponibilité !',
      body: 'Profitez du covoiturage maintenant'
    });
  }

  return { driversCount, totalSeats };
}
```

---

## 🎛️ Préférences Utilisateur

### Interface de Configuration

```dart
// settings_screen.dart
class NotificationSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Notifications push'),
          subtitle: Text('Recevoir toutes les notifications'),
          value: _pushEnabled,
          onChanged: (value) => _updatePreference('push', value),
        ),
        SwitchListTile(
          title: Text('🤝 Covoiturage'),
          subtitle: Text('Alertes covoiturage disponible'),
          value: _carpoolEnabled,
          onChanged: (value) => _updatePreference('carpool', value),
        ),
        SwitchListTile(
          title: Text('🎉 Promotions'),
          subtitle: Text('Offres et réductions'),
          value: _promoEnabled,
          onChanged: (value) => _updatePreference('promo', value),
        ),
        SwitchListTile(
          title: Text('🕐 Rappels'),
          subtitle: Text('Basés sur vos habitudes'),
          value: _habitsEnabled,
          onChanged: (value) => _updatePreference('habits', value),
        ),
      ],
    );
  }
}
```

---

## 📈 Analytics et Suivi

### Mesurer l'Efficacité

```javascript
// backend/src/models/Notification.js
const notificationSchema = new mongoose.Schema({
  userId: { type: ObjectId, ref: 'User' },
  type: String, // 'carpool_available', 'promo', etc.
  title: String,
  body: String,
  sentAt: Date,
  deliveredAt: Date,
  openedAt: Date,
  actionTaken: String, // 'opened_app', 'requested_ride', 'dismissed'
  metadata: {
    driversCount: Number,
    savings: Number,
    location: Object
  }
});

// Taux d'ouverture
const openRate = (openedNotifications / sentNotifications) * 100;

// Taux de conversion
const conversionRate = (ridesRequested / sentNotifications) * 100;
```

---

## 🧪 Tests

### Test Backend
```bash
# Envoyer notification test
curl -X POST http://localhost:8000/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Flutter
```dart
// Simuler notification
await NotificationService().simulateCarpoolNotification();
```

---

## 🔐 Sécurité et Conformité

### RGPD / Vie Privée

✅ Consentement explicite requis  
✅ Opt-out facile  
✅ Données géolocalisées anonymisées  
✅ Pas de partage avec tiers  
✅ Suppression à la demande  

### Configuration Permissions

```xml
<!-- Android: AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- iOS: Info.plist -->
<key>NSUserNotificationsUsageDescription</key>
<string>Recevoir les alertes de covoiturage et promotions</string>
```

---

## 🎯 Meilleures Pratiques

### ✅ À Faire

1. **Pertinence** : Notifications utiles uniquement
2. **Timing** : Respecter les heures (pas la nuit)
3. **Fréquence** : Max 3-4 par jour
4. **Personnalisation** : Basées sur l'usage
5. **Action claire** : Bouton d'action évident

### ❌ À Éviter

1. Spam de notifications
2. Notifications génériques
3. Pas de valeur ajoutée
4. Horaires inappropriés
5. Notifications répétitives

---

## 📊 Exemples de Scénarios

### Scénario 1 : Rush Hour
```
17h00 : 3 chauffeurs activent covoiturage
17h05 : 2 autres s'ajoutent (total: 5)
→ Notification envoyée : "5 chauffeurs disponibles"
→ 100 utilisateurs dans la zone notifiés
→ 15 ouvrent l'app
→ 8 demandent une course
→ Taux de conversion: 8%
```

### Scénario 2 : Promotion
```
Samedi 14h : Lancement promo -25%
→ Notification : "🎉 -25% sur covoiturage pendant 2h"
→ 500 utilisateurs notifiés
→ 150 ouvrent l'app
→ 45 utilisent la promo
→ Taux de conversion: 9%
```

---

## 🚀 Déploiement

### Configuration Production

```javascript
// backend/.env
FIREBASE_PROJECT_ID=dudu-senegal
FIREBASE_PRIVATE_KEY=...
FIREBASE_CLIENT_EMAIL=...

// Activer notifications
NOTIFICATIONS_ENABLED=true
NOTIFICATION_BATCH_SIZE=100
NOTIFICATION_RATE_LIMIT=1000/hour
```

---

**Système de notifications intelligent et respectueux de l'utilisateur ! 🔔✨**

**DUDU - Transport Intelligent au Sénégal 🇸🇳**

