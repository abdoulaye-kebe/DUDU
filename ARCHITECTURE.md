# 🚀 Architecture DUDU - Plateforme de Transport

## 📱 Applications Mobiles

### 1. DUDU Client (`dudu_flutter/`)
**Pour les passagers**

#### Fonctionnalités principales :
- ✅ **Écran d'accueil avec carte Google Maps interactive**
  - Localisation en temps réel
  - Visualisation des chauffeurs à proximité
  
- ✅ **Système de prix personnalisable**
  - Slider de prix (500 - 50,000 FCFA)
  - Suggestions basées sur l'historique
  - Prix moyen de la zone
  - Course Express avec prix suggéré

- ✅ **Recherche intelligente**
  - Barre de recherche pour destination
  - Sélection point A et B
  - Historique des courses récentes
  - Affichage des prix moyens

- ✅ **Recherche de chauffeurs**
  - Rayon de 2km autour du point de départ
  - Attente de 3 minutes max
  - Affichage des chauffeurs qui acceptent
  - Choix du chauffeur préféré

#### Écrans:
- `ClientHomeScreen` - Écran principal avec carte et recherche
- `DriverWaitingScreen` - Écran d'attente des chauffeurs

---

### 2. DUDU Pro (`mobile_dudu_pro/`)
**Pour les chauffeurs**

#### Fonctionnalités principales :
- ✅ **Tableau de bord**
  - Statut : En ligne / Hors ligne
  - Indicateur de forfait (jours restants)
  - Carte avec demandes de courses en temps réel
  - Revenus journaliers/hebdomadaires/mensuels

- ✅ **Système de forfaits** (Aucune commission!)
  - **Journalier** : 2,000 FCFA (24h)
  - **Hebdomadaire** : 12,000 FCFA (7 jours) - 14% d'économie
  - **Mensuel** : 40,000 FCFA (30 jours) - 33% d'économie ⭐ Populaire
  - **Annuel** : 400,000 FCFA (365 jours) - 45% d'économie + 2 mois gratuits 🏆

- ✅ **Gestion des courses**
  - Notification des demandes (30 secondes pour répondre)
  - Affichage du prix proposé par le client
  - Acceptation / Refus
  - **100% des revenus pour le chauffeur, ZÉRO commission!**

- ✅ **Statistiques et revenus**
  - Revenus du jour / semaine / mois
  - Nombre de courses
  - Note moyenne
  - Historique complet

#### Écrans:
- `DriverDashboardScreen` - Tableau de bord principal
- `RideRequestDialog` - Dialog pour les demandes de course
- `SubscriptionPlansSheet` - Choix des forfaits

---

## 🔧 Backend (`backend/`)

### APIs principales:

#### **Authentification**
- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/auth/verify` - Vérification téléphone

#### **Courses (Rides)**
- `POST /api/v1/rides/request` - Demander une course
- `GET /api/v1/rides/:id` - Détails d'une course
- `POST /api/v1/rides/:id/cancel` - Annuler une course

#### **Chauffeurs**
- `POST /api/v1/drivers/register` - Inscription chauffeur
- `PUT /api/v1/drivers/status` - Mise à jour statut (online/offline)
- `PUT /api/v1/drivers/location` - Mise à jour localisation
- `GET /api/v1/drivers/rides` - Historique des courses
- `GET /api/v1/drivers/earnings` - Revenus
- `GET /api/v1/drivers/stats` - Statistiques

#### **Covoiturage**
- `PUT /api/v1/drivers/preferences` - Mettre à jour préférences
- `PUT /api/v1/drivers/carpool/toggle` - Activer/Désactiver covoiturage
- `GET /api/v1/drivers/carpool/compatible-rides` - Courses compatibles
- `POST /api/v1/drivers/carpool/accept` - Accepter une course partagée

#### **Abonnements (Forfaits)**
- `GET /api/v1/subscriptions/plans` - Liste des forfaits
- `POST /api/v1/subscriptions/purchase` - Acheter un forfait
- `GET /api/v1/subscriptions/current` - Forfait actuel
- `PUT /api/v1/subscriptions/:id/cancel` - Annuler l'abonnement

---

## 💳 Système de tarification

### Pour les Clients:
- **Prix libre** : Le client fixe son budget
- **Suggestions intelligentes** basées sur :
  - Historique personnel
  - Prix moyens de la zone
  - Distance et temps estimés
- **Course Express** : Prix suggéré automatiquement

### Pour les Chauffeurs:
- **Forfaits fixes** : Pas de commission sur les courses
- **100% des revenus** reviennent au chauffeur
- **Paiements mobile money** : Orange Money, Wave, Free Money

---

## 🗺️ Google Maps

### Configuration requise:
1. Obtenir une clé API Google Maps
2. Activer les APIs suivantes:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Directions API
   - Distance Matrix API

### Configuration:
Voir `GOOGLE_MAPS_CONFIG.md` pour les instructions détaillées.

---

## 🔄 Communication temps réel

### Socket.IO
- Demandes de courses en temps réel
- Mise à jour de localisation des chauffeurs
- Notifications push
- Suivi des courses en cours

### Événements Socket:
**Client :**
- `ride-request-sent` - Demande envoyée
- `ride-accepted` - Course acceptée
- `driver-arriving` - Chauffeur en route
- `driver-arrived` - Chauffeur arrivé
- `ride-started` - Course commencée
- `ride-completed` - Course terminée

**Chauffeur :**
- `ride-request-received` - Nouvelle demande
- `ride-cancelled` - Course annulée
- `location-update` - Mise à jour de position

---

## 📊 Base de données (MongoDB)

### Collections principales:
- **users** - Utilisateurs (clients)
- **drivers** - Chauffeurs
- **rides** - Courses
- **subscriptions** - Abonnements chauffeurs
- **payments** - Paiements

### Schémas:
Voir les modèles dans `backend/src/models/`

---

## 🚦 États des courses

```
requested → searching → accepted → arriving → arrived → started → completed
                                           ↓
                                      cancelled
```

---

## 💡 Fonctionnalités uniques DUDU

1. **Prix libre pour le client** - Innovation majeure
2. **Zéro commission pour le chauffeur** - Modèle basé sur forfaits
3. **Choix du chauffeur par le client** - Transparence totale
4. **Covoiturage intelligent** - Réduction de 30% pour les passagers
5. **Course Express** - Prix suggéré automatiquement
6. **Historique intelligent** - Suggestions basées sur l'utilisation

---

## 🛠️ Technologies utilisées

### Mobile:
- **Flutter 3.8+** - Framework cross-platform
- **Dart** - Langage de programmation
- **Google Maps Flutter** - Cartes interactives
- **Geolocator** - Géolocalisation
- **Provider** - Gestion d'état
- **Socket.IO Client** - Communication temps réel

### Backend:
- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **MongoDB** - Base de données NoSQL
- **Mongoose** - ODM pour MongoDB
- **Socket.IO** - WebSocket temps réel
- **JWT** - Authentification

---

## 🚀 Démarrage rapide

### Backend:
```bash
cd backend
npm install
npm start
# Serveur sur http://localhost:8000
```

### Application Client:
```bash
cd dudu_flutter
flutter pub get
flutter run
```

### Application Chauffeur:
```bash
cd mobile_dudu_pro
flutter pub get
flutter run
```

---

## 📝 Prochaines étapes

### À développer:
- [ ] Intégration paiements mobile money (Orange Money, Wave, Free Money)
- [ ] Système de notifications push
- [ ] Chat intégré client-chauffeur
- [ ] Évaluation et commentaires post-course
- [ ] Programme de parrainage
- [ ] Mode hors ligne
- [ ] Optimisation de l'algorithme de matching
- [ ] Tableau de bord admin web

### Améliorations:
- [ ] Tests unitaires et d'intégration
- [ ] CI/CD avec GitHub Actions
- [ ] Documentation API avec Swagger
- [ ] Monitoring et analytics
- [ ] Support multilingue (Français, Wolof)

---

## 📞 Support

Pour toute question ou problème:
- Email: support@dudu.sn
- Tél: +221 XX XXX XX XX

---

## 📄 Licence

© 2024 DUDU - Tous droits réservés

