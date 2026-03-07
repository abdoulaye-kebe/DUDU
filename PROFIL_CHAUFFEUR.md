# Profil Chauffeur - Structure Complète

## Vue d'ensemble

Le profil chauffeur (`Driver`) contient toutes les informations nécessaires pour qu'un utilisateur puisse exercer en tant que chauffeur dans l'application DUDU.

## Structure du Profil

### 1. Informations de Base

```javascript
{
  id: ObjectId,              // ID unique du profil chauffeur
  user: ObjectId,            // Référence à l'utilisateur (User)
  createdAt: Date,           // Date de création
  updatedAt: Date            // Date de dernière mise à jour
}
```

### 2. Informations Professionnelles

**Permis de Conduire (`driverLicense`):**
- `number`: String (requis, unique) - Numéro du permis
- `expiryDate`: Date (requis) - Date d'expiration
- `issueDate`: Date (optionnel) - Date d'émission
- `category`: String (enum: 'A', 'B', 'C', 'D', défaut: 'B') - Catégorie du permis

### 3. Informations du Véhicule (`vehicle`)

- `make`: String (requis) - Marque du véhicule (ex: "Toyota")
- `model`: String (requis) - Modèle du véhicule (ex: "Corolla")
- `year`: Number (requis, min: 1990) - Année du véhicule
- `color`: String (requis) - Couleur du véhicule
- `plateNumber`: String (requis, unique) - Numéro de plaque d'immatriculation
- `category`: String (enum: 'car', 'moto', requis) - Catégorie du véhicule
- `type`: String (enum: 'standard', 'cargo', 'premium', 'moto_delivery', défaut: 'standard')
- `capacity`: Number (défaut: 4, min: 1, max: 8) - Capacité en passagers
- `features`: Array (optionnel) - Équipements disponibles
  - Options: 'ac', 'wifi', 'charging', 'child_seat', 'wheelchair_access', 'large_cargo', 'refrigerated'
- `photos`: Array[String] (optionnel) - URLs des photos du véhicule

### 4. Statut et Disponibilité

- `status`: String (enum: 'offline', 'online', 'busy', 'unavailable', défaut: 'offline')
- `isAvailable`: Boolean (défaut: false) - Disponibilité pour accepter des courses

### 5. Localisation (`currentLocation`)

- `latitude`: Number - Latitude actuelle
- `longitude`: Number - Longitude actuelle
- `address`: String - Adresse textuelle
- `lastUpdated`: Date - Date de dernière mise à jour de la localisation

### 6. Zone de Travail (`workingZones`)

Array d'objets contenant:
- `name`: String - Nom de la zone
- `coordinates.center.latitude`: Number
- `coordinates.center.longitude`: Number
- `coordinates.radius`: Number - Rayon en kilomètres

### 7. Abonnement (`subscription`)

- `type`: String (enum: 'daily', 'weekly', 'monthly', 'yearly', requis)
- `startDate`: Date (requis) - Date de début
- `endDate`: Date (requis) - Date de fin
- `isActive`: Boolean (défaut: true) - Statut actif
- `autoRenew`: Boolean (défaut: false) - Renouvellement automatique

### 8. Revenus (`earnings`)

- `today`: Number (défaut: 0) - Revenus du jour en FCFA
- `thisWeek`: Number (défaut: 0) - Revenus de la semaine en FCFA
- `thisMonth`: Number (défaut: 0) - Revenus du mois en FCFA
- `total`: Number (défaut: 0) - Revenus totaux en FCFA

### 9. Statistiques (`stats`)

- `totalRides`: Number (défaut: 0) - Nombre total de courses
- `completedRides`: Number (défaut: 0) - Courses terminées
- `cancelledRides`: Number (défaut: 0) - Courses annulées
- `averageRating`: Number (défaut: 0, min: 0, max: 5) - Note moyenne
- `totalRatingCount`: Number (défaut: 0) - Nombre d'évaluations
- `totalDistance`: Number (défaut: 0) - Distance totale en kilomètres
- `totalEarnings`: Number (défaut: 0) - Revenus totaux

### 10. Préférences (`preferences`)

- `maxDistance`: Number (défaut: 20) - Distance maximale en kilomètres
- `minPrice`: Number (défaut: 500) - Prix minimum en FCFA
- `workingHours.start`: String (format "HH:MM") - Heure de début
- `workingHours.end`: String (format "HH:MM") - Heure de fin
- `workingHours.days`: Array[String] - Jours de travail
- `acceptSharedRides`: Boolean (défaut: true) - Accepter le covoiturage
- `carpoolSeats`: Number (défaut: 1, min: 1, max: 8) - Places disponibles pour covoiturage
- `acceptExpressRides`: Boolean (défaut: true) - Accepter les courses express
- `acceptLuggage`: Boolean (défaut: false) - Accepter les bagages (cargo uniquement)

### 11. Documents (`documents`)

- `driverLicensePhoto`: String - URL de la photo du permis
- `vehicleRegistration`: String - URL de la carte grise
- `insurance`: String - URL de l'assurance
- `technicalInspection`: String - URL du contrôle technique
- `criminalRecord`: String - URL du casier judiciaire

### 12. Vérification

- `isVerified`: Boolean (défaut: false) - Statut de vérification
- `verificationStatus`: String (enum: 'pending', 'approved', 'rejected', défaut: 'pending')
- `verificationNotes`: String - Notes de vérification

### 13. Modes Spéciaux (`specialModes`)

Array de modes spéciaux:
- 'women_only' - Femmes uniquement
- 'elderly_friendly' - Accessible aux personnes âgées
- 'student_discount' - Réduction étudiant
- 'ceremony_mode' - Mode cérémonie

### 14. Historique des Positions (`locationHistory`)

Array d'objets contenant:
- `latitude`: Number
- `longitude`: Number
- `timestamp`: Date

### 15. Notifications (`notifications`)

- `newRideRequest`: Boolean (défaut: true)
- `rideUpdates`: Boolean (défaut: true)
- `earnings`: Boolean (défaut: true)
- `subscription`: Boolean (défaut: true)

## Création Automatique du Profil

Lors de la première connexion en tant que chauffeur (activation du bouton "Se connecter"), un profil minimal est automatiquement créé avec les données de test suivantes:

```javascript
{
  driverLicense: {
    number: "TEST-{timestamp}-{random}",
    expiryDate: Date + 1 an,
    category: "B"
  },
  vehicle: {
    make: "Toyota",
    model: "Corolla",
    year: 2020,
    color: "Blanc",
    plateNumber: "TEST-{timestamp}-{random}",
    category: "car",
    type: "standard",
    capacity: 4
  },
  status: "offline",
  isAvailable: false,
  verificationStatus: "pending",
  subscription: {
    type: "daily",
    isActive: true,
    startDate: new Date(),
    endDate: new Date() + 1 an,
    autoRenew: false
  }
}
```

## API Endpoints

### Obtenir le profil
```
GET /api/v1/drivers/profile
Authorization: Bearer {token}
```

### Mettre à jour le statut
```
PUT /api/v1/drivers/status
Authorization: Bearer {token}
Body: {
  "status": "online" | "offline" | "busy" | "unavailable",
  "isAvailable": boolean
}
```

### Mettre à jour la localisation
```
PUT /api/v1/drivers/location
Authorization: Bearer {token}
Body: {
  "latitude": number,
  "longitude": number,
  "address": string (optionnel)
}
```

## Méthodes Utiles

Le modèle Driver expose plusieurs méthodes utiles:

- `isSubscriptionValid()`: Vérifie si l'abonnement est valide
- `getTodayStats()`: Retourne les statistiques du jour
- `updateLocation(lat, lng, address)`: Met à jour la localisation
- `canAcceptRide()`: Vérifie si le chauffeur peut accepter une course




