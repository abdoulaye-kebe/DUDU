# 📱 ARCHITECTURE DU PROJET DUDU FLUTTER

## 🎯 STRUCTURE DES ÉCRANS

### ✅ ÉCRANS PRINCIPAUX (À GARDER)

#### 1. **Authentification**
- `login_screen.dart` - Connexion utilisateur
- `register_screen.dart` - Inscription nouveau client
- `verify_phone_screen.dart` - Vérification code SMS

#### 2. **Dashboard & Navigation**
- `dashboard_screen.dart` ⭐ - **PAGE D'ACCUEIL** après connexion
  - Affiche les 5 types de courses
  - Section "Où allons-nous ?" avec destinations récentes
  - Menu utilisateur (profil, historique, paramètres, déconnexion)

#### 3. **Types de Courses** (5 pages dédiées - NOUVELLES)
- `standard_ride_screen.dart` - Course classique (x1.0) - Vert
- `express_ride_screen.dart` - Course rapide (x1.3) - Orange [POPULAIRE]
- `shared_ride_screen.dart` - Covoiturage (x0.7) - Bleu [-30%]
- `women_only_ride_screen.dart` - Femmes uniquement (x1.0) - Rose
- `delivery_ride_screen.dart` - Livraison colis (x0.8) - Orange foncé

#### 4. **Carte & Réservation**
- `map_ride_screen.dart` ⭐ - **ÉCRAN PRINCIPAL DE RÉSERVATION**
  - Carte interactive Google Maps
  - Sélection Point A (départ) et Point B (destination)
  - Calcul automatique du prix selon le type de course
  - Recherche d'adresses avec suggestions
  - Affichage du trajet sur la carte
  - Bouton de confirmation de réservation

#### 5. **Suivi & Historique**
- `ride_tracking_screen.dart` - Suivi en temps réel du chauffeur
- `rides_screen.dart` - Historique des courses (En cours, Terminées, Annulées)

#### 6. **Livraison**
- `delivery_request_screen.dart` - Formulaire détaillé pour livraison
- `delivery_tracking_screen.dart` - Suivi livraison en temps réel

#### 7. **Profil**
- `profile_screen.dart` - Profil utilisateur avec vraies données

---

### ❌ ÉCRANS À SUPPRIMER (Doublons/Obsolètes)

- `ride_request_screen.dart` ❌ - Doublon de map_ride_screen
- `improved_ride_request_screen.dart` ❌ - Doublon avec background vert
- `map_screen.dart` ❌ - Ancienne version
- `simple_map_screen.dart` ❌ - Version simplifiée non utilisée
- `working_map_screen.dart` ❌ - Version de test
- `interactive_map_screen.dart` ❌ - Doublon
- `home_screen.dart` ❌ - Remplacé par dashboard_screen
- `client_home_screen.dart` ❌ - Remplacé par dashboard_screen
- `ride_type_selection_screen.dart` ⚠️ - Logique intégrée dans les pages dédiées

---

## 🔄 FLUX DE NAVIGATION

### 1. **Inscription → Connexion**
```
RegisterScreen → (Succès) → LoginScreen
```

### 2. **Connexion → Dashboard**
```
LoginScreen → (Succès) → DashboardScreen
```

### 3. **Dashboard → Réservation de Course**
```
DashboardScreen 
  → Clic sur "Standard" → StandardRideScreen (map_ride_screen avec params)
  → Clic sur "Express" → ExpressRideScreen (map_ride_screen avec params)
  → Clic sur "Covoiturage" → SharedRideScreen (map_ride_screen avec params)
  → Clic sur "Femmes" → WomenOnlyRideScreen (map_ride_screen avec params)
  → Clic sur "Livraison" → DeliveryRideScreen (delivery_request_screen)
```

### 4. **Réservation → Suivi**
```
MapRideScreen → (Confirmation) → RideTrackingScreen
```

### 5. **Menu Utilisateur**
```
DashboardScreen → Menu (☰)
  → Mon profil → ProfileScreen
  → Mon historique → RidesScreen
  → Paramètres → (À développer)
  → Aide & Support → (À développer)
  → Se déconnecter → LoginScreen
```

---

## 🎨 CHARTE GRAPHIQUE

### Couleurs DUDU
```dart
primaryGreen = Color(0xFF0d5d36)  // Vert principal
darkGreen = Color(0xFF094d2a)     // Vert foncé
lightGreen = Color(0xFF10b981)    // Vert clair
accentBlack = Color(0xFF1A1A1A)   // Noir accent
```

### Couleurs par Type de Course
- **Standard**: Vert (#0d5d36)
- **Express**: Orange (#FF9800)
- **Covoiturage**: Bleu (#2196F3)
- **Femmes**: Rose (#E91E63)
- **Livraison**: Orange foncé (#FF6B00)

### Règles de Design
- ✅ Background BLANC sur toutes les pages
- ✅ Pas de dégradé vert en background
- ✅ Icônes compactes (60x60px)
- ✅ Bordures arrondies (12-20px)
- ✅ Ombres légères pour profondeur

---

## 🗺️ FONCTIONNALITÉS CARTE (map_ride_screen.dart)

### Point A (Départ)
- Position actuelle GPS du client
- OU sélection manuelle d'une adresse
- OU choix d'un lieu populaire

### Point B (Destination)
- Recherche d'adresse avec autocomplétion
- Sélection sur la carte
- Lieux récents/favoris

### Calcul de Prix
```dart
Prix de base = Distance × Tarif au km
Prix final = Prix de base × priceMultiplier

Exemples:
- Standard: x1.0
- Express: x1.3 (+30%)
- Covoiturage: x0.7 (-30%)
- Femmes: x1.0
- Livraison: x0.8 (-20%)
```

### Affichage
- Trajet tracé sur la carte (Polyline)
- Marqueurs A et B
- Distance estimée
- Temps estimé
- Prix calculé

---

## 🔌 INTÉGRATIONS

### Services
- `api_service.dart` - Appels API backend
- `places_service.dart` - Recherche d'adresses
- `socket_service.dart` - WebSocket pour suivi temps réel

### Providers
- `auth_provider.dart` - Gestion authentification et utilisateur

### Packages Clés
- `google_maps_flutter` - Carte interactive
- `geolocator` - Géolocalisation
- `provider` - State management
- `http` - Requêtes API
- `shared_preferences` - Stockage local

---

## 📝 PROCHAINES ÉTAPES

### Phase 1: Client (EN COURS)
- [x] Correction URL API pour web
- [x] Dashboard avec 5 types de courses
- [x] Pages dédiées par type de course
- [x] Profil avec vraies données
- [x] Background blanc partout
- [ ] Finaliser map_ride_screen avec calcul prix
- [ ] Tester réservation complète
- [ ] Implémenter suivi temps réel

### Phase 2: Chauffeur (À VENIR)
- [ ] Application chauffeur mobile (Flutter Pro)
- [ ] Réception des demandes de course
- [ ] Navigation vers client
- [ ] Suivi de course

### Phase 3: Backend
- [ ] API de matching client-chauffeur
- [ ] Calcul de prix dynamique
- [ ] Gestion des courses par type
- [ ] WebSocket pour temps réel

---

## 🚀 COMMANDES UTILES

```bash
# Lancer sur web
flutter run -d chrome

# Lancer sur Android
flutter run -d emulator-5554

# Nettoyer le projet
flutter clean
flutter pub get

# Vérifier les erreurs
flutter analyze
```

---

**Dernière mise à jour**: 1er novembre 2024
**Version**: 1.0.0
**Développé avec ❤️ pour DUDU Sénégal**
