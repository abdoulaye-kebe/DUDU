# 🚖 DUDU - Plateforme de Transport Intelligente au Sénégal

## 📱 Vue d'ensemble

DUDU est une plateforme de transport innovante qui met en relation passagers et chauffeurs avec un modèle économique unique : **prix libre pour le client** et **zéro commission pour le chauffeur**.

### 🌟 Caractéristiques uniques :

1. **Prix personnalisable** - Le client fixe son budget
2. **Zéro commission** - Les chauffeurs gardent 100% de leurs revenus
3. **Forfaits fixes** - Modèle basé sur abonnement pour les chauffeurs
4. **Choix transparent** - Le client choisit son chauffeur
5. **Covoiturage intelligent** - Réduction de 30% pour les passagers

---

## 🏗️ Architecture du projet

```
DUDU/
├── backend/              # API Node.js + Express + MongoDB + Socket.IO
├── dudu_flutter/         # 📱 DUDU Client (Application Passagers)
└── mobile_dudu_pro/      # 📱 DUDU Pro (Application Chauffeurs)
```

---

## 📱 DUDU Client (Passagers)

### Fonctionnalités principales :

#### 🗺️ Écran d'accueil avec carte Google Maps
- Géolocalisation automatique du téléphone
- Carte interactive de Dakar
- Position de départ récupérée automatiquement
- Possibilité de modifier l'adresse de départ manuellement

#### 💰 Système de prix personnalisable
- **Slider de prix** : 500 - 50,000 FCFA
- **Suggestions intelligentes** basées sur :
  - Historique personnel du client
  - Prix moyens de la zone
  - Distance et temps estimés
- **Prix moyens affichés** pour chaque trajet
- **Bouton Course Express** : Prix suggéré automatiquement

#### 🔍 Recherche et sélection
- **Barre de recherche** pour la destination
- Sélection du **point A** (départ) et **point B** (arrivée) sur la carte
- **Historique** des courses récentes avec les prix payés
- Suggestions basées sur les trajets fréquents

#### 🚗 Recherche de chauffeurs
- Recherche dans un **rayon de 2 km** autour du point de départ
- Attente de **3 minutes maximum** pour les réponses
- **Affichage des chauffeurs** qui acceptent votre prix
- **Choix du chauffeur** parmi ceux disponibles
- Informations visibles : Note, distance, temps d'arrivée, véhicule

### 📱 Installation et test :

```bash
cd dudu_flutter
flutter pub get
flutter run -d <device_id>
```

### 🔐 Compte de test :
- Téléphone : `776543210`
- Mot de passe : `test123456`

---

## 🚕 DUDU Pro (Chauffeurs)

### Fonctionnalités principales :

#### 📊 Tableau de bord
- **Statut** : En ligne / Hors ligne (bouton toggle)
- **Indicateur de forfait** : Jours restants affichés en permanence
- **Carte Google Maps** avec demandes de courses en temps réel
- **Revenus** :
  - Journaliers
  - Hebdomadaires
  - Mensuels
  - **100% pour vous, AUCUNE COMMISSION !**

#### 💳 Système de forfaits (Zéro commission)

| Forfait | Prix | Durée | Économie |
|---------|------|-------|----------|
| **Journalier** | 2,000 FCFA | 24h | - |
| **Hebdomadaire** | 12,000 FCFA | 7 jours | 14% |
| **Mensuel** ⭐ | 40,000 FCFA | 30 jours | 33% |
| **Annuel** 🏆 | 400,000 FCFA | 365 jours | 45% + 2 mois gratuits |

#### 🔔 Gestion des courses
- **Notifications** pour chaque nouvelle demande
- **30 secondes** pour répondre
- **Affichage du prix** proposé par le client
- **Accepter / Refuser** en un clic
- **Carte** avec localisation du client
- **Informations** : Nom, distance, trajet, prix

#### 📈 Statistiques et revenus
- Revenus du jour/semaine/mois
- Nombre de courses effectuées
- Note moyenne des passagers
- Historique complet des courses
- **Aucune déduction** - Tout pour vous !

### 📱 Installation et test :

```bash
cd mobile_dudu_pro
flutter pub get
flutter run -d <device_id>
```

---

## 🔧 Backend (API)

### Technologies :
- **Node.js** + **Express.js**
- **MongoDB** avec Mongoose
- **Socket.IO** pour le temps réel
- **JWT** pour l'authentification
- **Bcrypt** pour les mots de passe

### Installation :

```bash
cd backend
npm install
cp env.example .env
# Modifier le .env avec vos configurations
npm start
```

Le serveur démarre sur **http://localhost:8000**

### APIs principales :

#### Authentification
- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/auth/verify` - Vérification téléphone

#### Courses
- `POST /api/v1/rides/request` - Demander une course
- `GET /api/v1/rides/:id` - Détails
- `POST /api/v1/rides/:id/cancel` - Annuler

#### Chauffeurs
- `PUT /api/v1/drivers/status` - En ligne/Hors ligne
- `PUT /api/v1/drivers/location` - Position GPS
- `GET /api/v1/drivers/rides` - Historique
- `GET /api/v1/drivers/earnings` - Revenus
- `PUT /api/v1/drivers/preferences` - Préférences (covoiturage, etc.)

#### Covoiturage
- `PUT /api/v1/drivers/carpool/toggle` - Activer/Désactiver
- `GET /api/v1/drivers/carpool/compatible-rides` - Courses compatibles
- `POST /api/v1/drivers/carpool/accept` - Accepter course partagée (réduction 30%)

#### Abonnements
- `GET /api/v1/subscriptions/plans` - Liste des forfaits
- `POST /api/v1/subscriptions/purchase` - Acheter un forfait
- `GET /api/v1/subscriptions/current` - Forfait actuel

---

## 🗺️ Configuration Google Maps

### 1. Obtenir une clé API

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un projet "DUDU"
3. Activez les APIs :
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API
   - Geocoding API
   - Directions API
   - Distance Matrix API
   - Places API

4. Créez une clé API

### 2. Configurer la clé

**Pour dudu_flutter (Client) :**
- `android/app/src/main/AndroidManifest.xml` : Remplacez `AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA`
- `ios/Runner/AppDelegate.swift` : Ajoutez la clé

**Pour mobile_dudu_pro (Chauffeur) :**
- Même configuration

**Pour le backend :**
```bash
# Dans backend/.env
GOOGLE_MAPS_API_KEY=VOTRE_CLE_API
```

Voir **GOOGLE_MAPS_CONFIG.md** pour les instructions détaillées.

---

## 🚀 Démarrage rapide

### 1. Démarrer le backend

```bash
cd backend
npm install
npm start
# Backend sur http://localhost:8000
```

### 2. Lancer l'application Client

```bash
cd dudu_flutter
flutter pub get
flutter run
```

### 3. Lancer l'application Chauffeur

```bash
cd mobile_dudu_pro
flutter pub get
flutter run
```

---

## 💡 Flux d'utilisation

### Pour un passager (Client) :

1. **Ouvrir l'app** → Carte avec position actuelle géolocalisée
2. **Rechercher destination** → Taper ou sélectionner depuis l'historique
3. **Fixer son prix** → Utiliser le slider ou les suggestions
4. **Attendre** → Maximum 3 minutes pour les chauffeurs
5. **Choisir** → Sélectionner le chauffeur parmi ceux qui acceptent
6. **Suivre** → Voir le chauffeur arriver en temps réel
7. **Payer** → Orange Money, Wave, Free Money ou Cash

### Pour un chauffeur (Pro) :

1. **Acheter un forfait** → Journalier, Hebdo, Mensuel ou Annuel
2. **Se mettre en ligne** → Activer le statut
3. **Recevoir demandes** → Notifications avec prix et trajet
4. **Accepter / Refuser** → 30 secondes pour décider
5. **Prendre en charge** → Aller au point de rendez-vous
6. **Effectuer la course** → Navigation intégrée
7. **Encaisser** → 100% du montant, zéro commission !

---

## 💳 Modèle économique

### Pour les chauffeurs :
- **Pas de commission** sur les courses
- **Forfait fixe** mensuel/annuel/etc.
- **100% des revenus** de chaque course
- Exemple : 40 courses/jour à 2,500 FCFA = 100,000 FCFA/jour = 3,000,000 FCFA/mois
- Forfait mensuel : 40,000 FCFA
- **Revenu net : 2,960,000 FCFA** (vs 2,100,000 FCFA avec commission 30%)

### Pour les clients :
- **Prix libre** - Vous fixez votre budget
- **Transparence** - Vous choisissez votre chauffeur
- **Historique** - Suggestions basées sur vos trajets
- **Covoiturage** - 30% de réduction possible

---

## 🔄 Communication temps réel (Socket.IO)

### Événements principaux :

**Client :**
- `ride-request-sent` - Demande envoyée
- `ride-accepted` - Chauffeur trouvé
- `driver-arriving` - En route
- `driver-arrived` - Arrivé
- `ride-started` - Course commencée
- `ride-completed` - Terminée

**Chauffeur :**
- `ride-request-received` - Nouvelle demande
- `location-update` - Position temps réel
- `ride-cancelled` - Annulation

---

## 🛠️ Technologies

### Mobile :
- **Flutter 3.32+** - Cross-platform
- **Google Maps Flutter** - Cartes
- **Geolocator** - GPS
- **Provider** - State management
- **Socket.IO Client** - Temps réel

### Backend :
- **Node.js 18+**
- **Express.js 4**
- **MongoDB 8**
- **Socket.IO 4**
- **JWT** - Sécurité

---

## 📝 Prochaines étapes

- [ ] Intégration paiements mobile money (Orange Money, Wave, Free Money)
- [ ] Notifications push natives
- [ ] Chat client-chauffeur
- [ ] Système d'évaluation post-course
- [ ] Programme de parrainage
- [ ] Support Wolof
- [ ] Admin dashboard web
- [ ] Analytics et reporting

---

## 🤝 Contribuer

1. Fork le projet
2. Créez une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrez une Pull Request

---

## 📄 Licence

© 2024 DUDU - Tous droits réservés

---

## 📞 Support

- Email : support@dudu.sn
- Téléphone : +221 XX XXX XX XX
- Site web : https://dudu.sn (à venir)

---

## 👥 Équipe

- **Abdoulaye Kébé** - Développeur principal
- **Équipe DUDU** - Innovation et développement

---

**DUDU - Votre transport, votre prix, votre choix ! 🚖💚**

