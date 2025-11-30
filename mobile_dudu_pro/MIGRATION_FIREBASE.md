# Migration vers Firebase - Guide d'Utilisation

## 📦 Ce qui a été fait

✅ **Dépendances Firebase ajoutées** dans `pubspec.yaml`
✅ **Service Firebase créé** (`lib/services/firebase_service.dart`)
✅ **Initialisation Firebase** configurée dans `main.dart`
✅ **Structure Firestore** documentée

## 🔄 Comment utiliser Firebase dans votre code

### Option 1 : Utiliser Firebase directement (Recommandé pour nouveau code)

```dart
import '../services/firebase_service.dart';

// Obtenir l'instance
final firebaseService = FirebaseService();

// Exemple : Connexion
try {
  final userCredential = await firebaseService.signInWithPhoneAndPassword(
    phone: '221771234567',
    password: 'motdepasse',
  );
  // Connexion réussie
} catch (e) {
  // Gérer l'erreur
}

// Exemple : Obtenir le profil en temps réel
firebaseService.streamDriverProfile().listen((profile) {
  if (profile != null) {
    // Mettre à jour l'UI avec le profil
  }
});

// Exemple : Mettre à jour le statut
await firebaseService.updateOnlineStatus(
  isOnline: true,
  isAvailable: true,
  latitude: 14.6928,
  longitude: -17.4467,
);

// Exemple : Écouter les courses à proximité
firebaseService.streamNearbyRides(
  latitude: 14.6928,
  longitude: -17.4467,
  radiusKm: 5.0,
).listen((rides) {
  // Mettre à jour la liste des courses disponibles
});
```

### Option 2 : Migrer progressivement depuis ApiService

Vous pouvez garder les deux services et migrer progressivement :

1. **Commencez par l'authentification** dans `login_screen.dart`
2. **Migrez le chargement du profil** dans `driver_dashboard_screen.dart`
3. **Migrez les courses** progressivement

## 📝 Exemple de Migration dans driver_dashboard_screen.dart

### Avant (avec ApiService)
```dart
Future<void> _loadDriverProfile() async {
  try {
    final profile = await ApiService.getDriverProfile();
    setState(() {
      _driverProfile = profile;
    });
  } catch (e) {
    // Gérer l'erreur
  }
}
```

### Après (avec FirebaseService)
```dart
Future<void> _loadDriverProfile() async {
  try {
    setState(() {
      _isLoading = true;
    });
    
    // Obtenir le profil une fois
    final profile = await FirebaseService().getDriverProfile();
    
    // OU écouter les changements en temps réel
    FirebaseService().streamDriverProfile().listen((profile) {
      if (mounted) {
        setState(() {
          _driverProfile = profile;
          _isLoading = false;
        });
      }
    });
  } catch (e) {
    setState(() {
      _error = 'Erreur: $e';
      _isLoading = false;
    });
  }
}
```

## 🔥 Avantages de Firebase

1. **Temps réel** : Les changements sont synchronisés automatiquement
2. **Collaboration** : Plusieurs développeurs peuvent travailler simultanément
3. **Pas de backend nécessaire** : Firestore gère tout
4. **Offline** : Les données sont mises en cache automatiquement
5. **Scalable** : Firebase s'adapte à la croissance

## ⚠️ Prochaines Étapes

1. **Configurer Firebase** (voir `FIREBASE_SETUP.md`)
2. **Ajouter les fichiers de configuration** :
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. **Migrer le login_screen.dart** pour utiliser Firebase Auth
4. **Tester** avec de vraies données Firebase

## 🛠️ Commandes Utiles

```bash
# Installer les dépendances
flutter pub get

# Pour iOS, installer les pods
cd ios && pod install && cd ..

# Lancer l'application
flutter run
```

## 📚 Documentation

- Guide de configuration : `FIREBASE_SETUP.md`
- Service Firebase : `lib/services/firebase_service.dart`
- Documentation Firebase : https://firebase.flutter.dev/

