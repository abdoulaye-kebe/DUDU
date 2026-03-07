# 🗺️ Configuration Google Maps - Carte de Dakar

## ✅ Configuration Actuelle

### **1. API Key Google Maps**

L'API key est déjà configurée dans le projet :

#### **iOS** (`ios/Runner/AppDelegate.swift`)
```swift
GMSServices.provideAPIKey("AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA")
```

#### **Android** (`android/app/src/main/AndroidManifest.xml`)
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA" />
```

---

### **2. Dépendances**

✅ **google_maps_flutter** : `^2.13.1` (déjà installé)
✅ **geolocator** : `^14.0.2` (déjà installé)

---

### **3. Modifications Apportées**

#### **Écran Principal** : `client_home_screen.dart`

**Changements effectués** :

1. **Chargement immédiat de Dakar** :
   ```dart
   Future<void> _initializeScreen() async {
     // Définir Dakar comme position par défaut immédiatement
     _setDefaultLocation();
     // ...
   }
   ```

2. **Carte toujours affichée** :
   - Avant : La carte ne s'affichait que si `_currentPosition != null`
   - Maintenant : La carte s'affiche toujours avec Dakar par défaut

3. **Position par défaut** :
   ```dart
   const LatLng(14.6928, -17.4467) // Centre de Dakar
   ```

4. **Centrage automatique** :
   ```dart
   onMapCreated: (controller) {
     // Si géolocalisation disponible → centre sur position actuelle
     // Sinon → centre sur Dakar par défaut
   }
   ```

---

## 📍 Coordonnées de Dakar

```dart
// Centre de Dakar (Place de l'Indépendance)
latitude: 14.6928
longitude: -17.4467
zoom: 14
```

---

## 🎯 Fonctionnalités Disponibles

### **1. Affichage de la Carte**
- ✅ Carte Google Maps centrée sur Dakar par défaut
- ✅ Zoom niveau 14 (vue de la ville)
- ✅ Marqueur sur Dakar si géolocalisation indisponible
- ✅ Marqueur sur position actuelle si géolocalisation disponible

### **2. Géolocalisation**
- ✅ Tentative automatique de récupération de la position
- ✅ Timeout de 10 secondes
- ✅ Bascule vers Dakar si échec

### **3. Marqueurs**
- ✅ Marqueur vert pour position actuelle
- ✅ Marqueur vert pour Dakar (par défaut)
- ✅ Marqueurs pour destinations sélectionnées

---

## 🚀 Test de la Carte

### **Scénario 1 : Avec Géolocalisation**
1. Autoriser l'accès à la localisation
2. La carte se centre sur votre position
3. Un marqueur vert apparaît à votre position

### **Scénario 2 : Sans Géolocalisation**
1. Refuser l'accès à la localisation
2. La carte se charge directement sur Dakar
3. Un marqueur vert apparaît au centre de Dakar

---

## 📱 Écrans Utilisant Google Maps

1. **`client_home_screen.dart`** ✅ (Modifié - Affichage Dakar par défaut)
2. **`map_screen.dart`** ✅ (Sélection de localisation)
3. **`interactive_map_screen.dart`** ✅ (Carte interactive)
4. **`ride_request_screen.dart`** ✅ (Demande de course)
5. **`ride_tracking_screen.dart`** ✅ (Suivi de course)
6. **`enhanced_ride_request_screen.dart`** ✅ (Demande améliorée)

---

## 🔧 Dépannage

### **Problème : Carte ne s'affiche pas**

**Vérifications** :
1. ✅ API key configurée dans `AppDelegate.swift (iOS)`
2. ✅ API key configurée dans `AndroidManifest.xml (Android)`
3. ✅ Permissions de localisation demandées
4. ✅ Internet disponible

### **Problème : Carte affiche "Map type not supported"**

**Solution** :
- Vérifier que l'API key a les bonnes restrictions
- Activer "Maps SDK for iOS" et "Maps SDK for Android" dans Google Cloud Console

### **Problème : Pas de marqueur sur Dakar**

**Solution** :
- Vérifier que `_setDefaultLocation()` est appelée dans `initState()`
- Vérifier les logs pour voir si `_markers` contient le marqueur

---

## 📊 Structure du Code

```
client_home_screen.dart
├── _initializeScreen()
│   ├── _setDefaultLocation() ← Définit Dakar immédiatement
│   ├── _getCurrentLocation() ← Essaie d'obtenir position actuelle
│   ├── _loadRecentRides()
│   └── _loadPriceSuggestions()
│
├── _setDefaultLocation()
│   └── Position: 14.6928, -17.4467 (Dakar)
│
└── build()
    └── GoogleMap()
        ├── initialCameraPosition: mapCenter (Dakar ou position actuelle)
        └── onMapCreated: Centrage automatique
```

---

## ✅ État Final

- ✅ Google Maps configuré avec API key
- ✅ Carte se charge toujours avec Dakar par défaut
- ✅ Géolocalisation optionnelle (améliore l'expérience si disponible)
- ✅ Marqueurs affichés correctement
- ✅ Zoom approprié pour la ville de Dakar (14)

---

## 🎨 Améliorations Futures Possibles

1. **Limite géographique** : Restreindre la carte à la région de Dakar
2. **Lieux populaires** : Afficher des POI (Points of Interest) de Dakar
3. **Trafic en temps réel** : Activer l'affichage du trafic
4. **Style personnalisé** : Appliquer un style de carte personnalisé pour Dakar

---

**La carte Google Maps se charge maintenant automatiquement sur Dakar dès l'ouverture de l'application !** ✅





