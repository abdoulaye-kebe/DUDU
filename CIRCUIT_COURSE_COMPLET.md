# 🚗 Circuit Complet d'une Course DUDU

## 📋 Vue d'ensemble

Ce document explique le circuit complet d'une course DUDU, de la demande du client jusqu'à la fin de la course, en passant par tous les statuts et notifications.

---

## 🔄 FLUX COMPLET D'UNE COURSE

### **PHASE 1 : Demande de Course (CLIENT)**

#### **1.1 Client remplit le formulaire**
**App Client (dudu_flutter)** → `enhanced_ride_request_screen.dart`

**Informations saisies :**
- 📍 Point de départ (adresse + coordonnées GPS)
- 📍 Point d'arrivée (adresse + coordonnées GPS)
- 💰 Prix proposé par le client
- 🚗 Type de course : `standard`, `comfort`, `women_only`, `delivery`
- 👥 Nombre de passagers
- 📝 Demandes spéciales (optionnel)

**Code :**
```dart
// Client appuie sur "Confirmer la course"
await ApiService.requestRide({
  pickup: pickupLocation,
  destination: destinationLocation,
  pricing: { totalPrice: proposedPrice },
  rideType: selectedRideType
});
```

#### **1.2 Backend reçoit la demande**
**Backend** → `POST /api/v1/rides/request`

**Actions du backend :**
1. ✅ Valider les données (adresses, coordonnées, prix)
2. 📏 Calculer la distance entre départ et arrivée
3. ⏱️ Estimer la durée du trajet
4. 💾 Créer la course dans la base de données avec statut `requested`
5. 🔍 Rechercher les chauffeurs disponibles

**Critères de recherche chauffeur :**
```javascript
{
  status: 'online',           // Chauffeur en ligne
  isAvailable: true,          // Disponible (pas en course)
  verificationStatus: 'approved', // Compte vérifié par admin
  rideTypes.standard: true    // Accepte ce type de course
}
```

**Cas spéciaux :**
- `delivery` → Cherche uniquement les motos
- `women_only` → Cherche uniquement les chauffeuses (gender: 'female')

#### **1.3 Notification aux chauffeurs**
**Backend** → **Socket.io** → **Tous les chauffeurs disponibles**

**Événement Socket.io :**
```javascript
io.emit('new-ride-request', {
  rideId: "65abc123...",
  pickup: { address: "Dakar, Plateau", coordinates: {...} },
  destination: { address: "Dakar, Almadies", coordinates: {...} },
  distance: 8.5,  // km
  pricing: { totalPrice: 3500 },  // FCFA
  rideType: "standard",
  passenger: { name: "Abdou K.", phone: "+221..." }
});
```

**Aussi envoyé individuellement :**
```javascript
// À chaque chauffeur disponible
io.to(`driver_${driverId}`).emit('ride-request', rideData);
```

#### **1.4 Réponse au client**
**Backend** → **Client**

```json
{
  "success": true,
  "message": "Demande de course envoyée",
  "data": {
    "ride": {
      "id": "65abc123...",
      "rideId": "DUDU-2026-001234",
      "status": "requested",
      "availableDrivers": 5
    }
  }
}
```

**Statut de la course :** `requested` ✅

---

### **PHASE 2 : Réception par les Chauffeurs**

#### **2.1 Chauffeurs reçoivent la notification**
**App Chauffeur (mobile_dudu_pro)** → `socket_service.dart`

**Événement écouté :**
```dart
socket.on('new-ride-request', (data) {
  // Afficher notification sonore + visuelle
  NotificationService.showRideRequest(data);
  
  // Ajouter à la liste des courses disponibles
  _availableRides.add(RideRequest.fromJson(data));
});
```

**Affichage :**
- 🔔 Notification sonore
- 📱 Popup avec détails de la course
- 📋 Ajout dans la liste des courses disponibles

**Écran :** `ride_requests_screen.dart`

**Informations affichées au chauffeur :**
- 📍 Adresse de départ
- 📍 Adresse d'arrivée
- 📏 Distance (8.5 km)
- 💰 Prix (3500 FCFA)
- 👤 Nom du client
- ⏱️ Temps estimé

**Actions possibles :**
- ✅ **Accepter** → Passe à la phase 3
- ❌ **Refuser** → Ignore la course
- ⏰ **Attendre** → La course reste dans la liste

---

### **PHASE 3 : Acceptation par un Chauffeur**

#### **3.1 Chauffeur accepte la course**
**App Chauffeur** → `acceptRide(rideId)`

```dart
// Chauffeur appuie sur "Accepter"
await ApiService.acceptRide(rideId);
```

#### **3.2 Backend traite l'acceptation**
**Backend** → `POST /api/v1/rides/:id/accept`

**Vérifications :**
1. ✅ Course existe et statut = `requested` ou `searching`
2. ✅ Chauffeur est en ligne et disponible
3. ✅ Chauffeur a un abonnement actif
4. ✅ Chauffeur est dans un rayon de 2 km du point de départ

**Actions :**
1. 📝 Assigner le chauffeur à la course
2. 🔄 Changer statut : `requested` → `accepted`
3. ⏰ Enregistrer `acceptedAt` (timestamp)
4. 🚫 Marquer chauffeur comme occupé (`status: 'busy'`, `isAvailable: false`)
5. 📢 Notifier le client
6. 📢 Notifier tous les autres chauffeurs

**Notifications Socket.io :**

**Au client :**
```javascript
io.to(`user_${passengerId}`).emit('ride-accepted', {
  rideId: "65abc123...",
  driver: {
    id: "65def456...",
    firstName: "Moussa",
    lastName: "Diop",
    phone: "+221...",
    vehicle: {
      make: "Toyota",
      model: "Corolla",
      plateNumber: "DK-1234-AB",
      color: "Blanc"
    },
    rating: 4.8
  }
});
```

**Aux autres chauffeurs :**
```javascript
io.emit('ride-taken', {
  rideId: "65abc123...",
  message: "Cette course a été acceptée par un autre chauffeur"
});
```

**Statut de la course :** `accepted` ✅

#### **3.3 Client reçoit la confirmation**
**App Client** → `socket_service.dart`

```dart
socket.on('ride-accepted', (data) {
  // Afficher les infos du chauffeur
  setState(() {
    assignedDriver = Driver.fromJson(data['driver']);
    rideStatus = 'accepted';
  });
  
  // Afficher écran de suivi
  Navigator.push(context, RideTrackingScreen(ride));
});
```

**Affichage client :**
- ✅ "Chauffeur trouvé !"
- 👤 Photo et nom du chauffeur
- 🚗 Véhicule (Toyota Corolla - DK-1234-AB)
- ⭐ Note du chauffeur (4.8/5)
- 📞 Bouton pour appeler le chauffeur
- 🗺️ Carte avec position du chauffeur en temps réel

---

### **PHASE 4 : Chauffeur en Route**

#### **4.1 Chauffeur se dirige vers le client**
**App Chauffeur** → Écran de course active

**Affichage chauffeur :**
- 🗺️ Carte avec itinéraire vers le point de départ
- 📍 Adresse du client
- 📞 Bouton pour appeler le client
- 🚗 Navigation GPS
- ✅ Bouton "Je suis arrivé"

**Suivi en temps réel :**
```dart
// Position du chauffeur mise à jour toutes les 5 secondes
TrackingService.updateLocation(latitude, longitude);
```

**Backend reçoit les positions :**
```javascript
socket.on('driver-location-update', (data) => {
  // Diffuser au client
  io.to(`user_${passengerId}`).emit('driver-location', {
    latitude: data.latitude,
    longitude: data.longitude
  });
});
```

**Client voit :**
- 🚗 Icône du chauffeur qui se déplace sur la carte
- ⏱️ Temps d'arrivée estimé (mis à jour en temps réel)
- 📏 Distance restante

**Statut de la course :** `accepted` (peut être `arriving` si implémenté)

---

### **PHASE 5 : Arrivée du Chauffeur**

#### **5.1 Chauffeur signale son arrivée**
**App Chauffeur** → Bouton "Je suis arrivé"

```dart
await ApiService.arriveAtPickup(rideId);
```

**Backend** → `POST /api/v1/rides/:id/arrive`

**Actions :**
1. ✅ Vérifier que chauffeur = chauffeur assigné
2. ✅ Vérifier statut = `accepted`
3. 🔄 Changer statut : `accepted` → `arrived`
4. ⏰ Enregistrer `arrivedAt`
5. 📢 Notifier le client

**Statut de la course :** `arrived` ✅

#### **5.2 Client est notifié**
**App Client** → Notification

**Affichage :**
- 🔔 "Votre chauffeur est arrivé !"
- 📍 "Il vous attend au point de départ"
- ⏱️ Minuteur (pour éviter attente trop longue)

---

### **PHASE 6 : Début de la Course**

#### **6.1 Client monte dans le véhicule**
**Chauffeur vérifie :** Identité du client (nom, téléphone)

#### **6.2 Chauffeur démarre la course**
**App Chauffeur** → Bouton "Démarrer la course"

```dart
await ApiService.startRide(rideId);
```

**Backend** → `POST /api/v1/rides/:id/start`

**Vérifications :**
1. ✅ Statut = `arrived`
2. ✅ Chauffeur assigné

**Actions :**
1. 🔄 Changer statut : `arrived` → `started`
2. ⏰ Enregistrer `startedAt`
3. ⏱️ Démarrer le chronomètre de durée
4. 📢 Notifier le client

**Statut de la course :** `started` ✅

#### **6.3 Client voit la course en cours**
**App Client** → Écran de suivi actif

**Affichage :**
- 🗺️ Carte avec trajet en temps réel
- 🚗 Position du véhicule qui se déplace
- 📏 Distance parcourue
- ⏱️ Durée écoulée
- 💰 Prix de la course
- 📍 Destination

---

### **PHASE 7 : Fin de la Course**

#### **7.1 Arrivée à destination**
**Chauffeur** → Bouton "Terminer la course"

```dart
await ApiService.completeRide(
  rideId,
  actualDuration: 25,  // minutes
  actualDistance: 8.7  // km
);
```

**Backend** → `POST /api/v1/rides/:id/complete`

**Actions :**
1. ✅ Vérifier statut = `started` (ou `in_progress`, `accepted`, `arriving`, `arrived`)
2. 🔄 Changer statut : `started` → `completed`
3. ⏰ Enregistrer `completedAt`
4. 📊 Mettre à jour statistiques chauffeur :
   - `totalRides++`
   - `completedRides++`
   - `totalEarnings += 3500 FCFA`
   - `totalDistance += 8.7 km`
5. 📊 Mettre à jour statistiques client :
   - `totalRides++`
   - `totalSpent += 3500 FCFA`
6. 🚗 Remettre chauffeur disponible (`status: 'online'`, `isAvailable: true`)
7. 📢 Notifier le client

**Statut de la course :** `completed` ✅

#### **7.2 Client reçoit confirmation**
**App Client** → Écran de fin de course

**Affichage :**
- ✅ "Course terminée !"
- 💰 Montant : 3500 FCFA
- 📏 Distance : 8.7 km
- ⏱️ Durée : 25 minutes
- ⭐ Bouton "Noter le chauffeur"
- 💳 Bouton "Payer"

---

### **PHASE 8 : Évaluation et Paiement**

#### **8.1 Client note le chauffeur**
**App Client** → Écran d'évaluation

```dart
await ApiService.rateRide(
  rideId,
  rating: 5,
  comment: "Excellent chauffeur, très professionnel !"
);
```

**Backend** → `POST /api/v1/rides/:id/rate`

**Actions :**
1. 📝 Enregistrer note (1-5 étoiles)
2. 📝 Enregistrer commentaire
3. 📊 Mettre à jour note moyenne du chauffeur
4. 📊 Incrémenter nombre d'évaluations

#### **8.2 Paiement**
**Méthodes disponibles :**
- 💵 Espèces (cash)
- 📱 Orange Money
- 📱 Wave
- 📱 Free Money

**Si paiement mobile :**
```dart
await ApiService.processPayment(
  rideId,
  method: 'orange_money',
  phoneNumber: '+221...'
);
```

**Statut paiement :**
- `pending` → En attente
- `processing` → En cours
- `completed` → Payé ✅
- `failed` → Échec

---

## 📊 TOUS LES STATUTS DE COURSE

### **Statuts Principaux**

| Statut | Description | Qui peut le voir | Actions possibles |
|--------|-------------|------------------|-------------------|
| `requested` | Demande envoyée, recherche de chauffeur | Client, Chauffeurs disponibles | Chauffeur: Accepter/Refuser<br>Client: Annuler |
| `searching` | Recherche active de chauffeur | Client | Client: Annuler |
| `accepted` | Chauffeur accepté, en route vers client | Client, Chauffeur | Chauffeur: Arriver/Annuler<br>Client: Annuler |
| `arriving` | Chauffeur en route (optionnel) | Client, Chauffeur | Chauffeur: Arriver |
| `arrived` | Chauffeur arrivé au point de départ | Client, Chauffeur | Chauffeur: Démarrer/Annuler<br>Client: Annuler |
| `started` | Course en cours | Client, Chauffeur | Chauffeur: Terminer |
| `completed` | Course terminée avec succès | Client, Chauffeur, Admin | Client: Noter/Payer |
| `cancelled` | Course annulée | Client, Chauffeur, Admin | Aucune |
| `no_driver` | Aucun chauffeur trouvé | Client | Client: Réessayer |
| `expired` | Demande expirée (timeout) | Client | Client: Réessayer |

### **Transitions de Statuts**

```
requested → searching → accepted → arriving → arrived → started → completed
    ↓           ↓          ↓          ↓         ↓         ↓
cancelled   cancelled  cancelled  cancelled cancelled  (rare)
    ↓
no_driver
    ↓
expired
```

---

## 📱 HISTORIQUE DES COURSES

### **Pour le CLIENT (dudu_flutter)**

#### **Où voir l'historique ?**
**Écran :** `dashboard_screen.dart` → Section "Mes courses"

**Endpoint API :**
```dart
GET /api/v1/rides/user/history
```

**Filtres disponibles :**
- Toutes les courses
- Courses terminées (`completed`)
- Courses annulées (`cancelled`)
- Courses en cours (`started`, `accepted`, `arrived`)

**Informations affichées :**
- 📅 Date et heure
- 📍 Départ → Arrivée
- 💰 Prix payé
- ⭐ Note donnée au chauffeur
- 🚗 Chauffeur (nom, véhicule)
- 📊 Statut

**Actions :**
- 👁️ Voir détails
- 📄 Télécharger reçu
- ⭐ Noter (si pas encore fait)
- 🔁 Refaire la même course

### **Pour le CHAUFFEUR (mobile_dudu_pro)**

#### **Où voir l'historique ?**
**Écran :** `driver_rides_screen.dart` ou `statistics_screen.dart`

**Endpoint API :**
```dart
GET /api/v1/drivers/rides/history
```

**Filtres disponibles :**
- Toutes les courses
- Courses terminées (`completed`)
- Courses annulées (`cancelled`)
- Aujourd'hui
- Cette semaine
- Ce mois

**Informations affichées :**
- 📅 Date et heure
- 📍 Départ → Arrivée
- 💰 Gain (prix de la course)
- ⭐ Note reçue du client
- 👤 Client (nom)
- 📊 Statut
- 📏 Distance parcourue
- ⏱️ Durée

**Statistiques :**
- 💰 Gains du jour/semaine/mois
- 🚗 Nombre de courses
- ⭐ Note moyenne
- 📏 Distance totale

---

## 🔔 SYSTÈME DE NOTIFICATIONS

### **Notifications Socket.io (Temps Réel)**

| Événement | Émetteur | Récepteur | Contenu |
|-----------|----------|-----------|---------|
| `new-ride-request` | Backend | Tous chauffeurs | Nouvelle demande de course |
| `ride-request` | Backend | Chauffeur spécifique | Demande personnalisée |
| `ride-accepted` | Backend | Client | Chauffeur a accepté |
| `ride-taken` | Backend | Autres chauffeurs | Course prise par un autre |
| `ride-cancelled` | Backend | Client + Chauffeur | Course annulée |
| `driver-location` | Backend | Client | Position du chauffeur |
| `ride-completed` | Backend | Client | Course terminée |

### **Notifications Push (À implémenter)**

- 📱 Nouvelle course disponible (chauffeur)
- ✅ Chauffeur trouvé (client)
- 🚗 Chauffeur arrivé (client)
- 🏁 Course terminée (client + chauffeur)
- ⭐ Nouvelle évaluation (chauffeur)

---

## ❌ ANNULATION DE COURSE

### **Qui peut annuler ?**
- ✅ **Client** : Avant que la course démarre (`requested`, `accepted`, `arrived`)
- ✅ **Chauffeur** : Avant que la course démarre
- ✅ **Système** : Si timeout ou erreur

### **Processus d'annulation**

**Endpoint :**
```dart
POST /api/v1/rides/:id/cancel
Body: { reason: "Client a changé d'avis" }
```

**Actions backend :**
1. 🔄 Changer statut → `cancelled`
2. ⏰ Enregistrer `cancelledAt`
3. 📝 Enregistrer raison et qui a annulé
4. 💰 Calculer remboursement si paiement déjà effectué
5. 🚗 Remettre chauffeur disponible (si assigné)
6. 📢 Notifier l'autre partie

**Raisons d'annulation :**
- `passenger_cancelled` - Client a annulé
- `driver_cancelled` - Chauffeur a annulé
- `no_driver_found` - Aucun chauffeur trouvé
- `payment_failed` - Paiement échoué
- `system_error` - Erreur système
- `timeout` - Délai expiré

**Pénalités (à implémenter) :**
- Client annule trop souvent → Avertissement
- Chauffeur annule trop souvent → Suspension temporaire

---

## 🎯 POINTS D'AMÉLIORATION IDENTIFIÉS

### **1. Notifications manquantes**
❌ **Problème :** Certaines notifications Socket.io ne sont pas implémentées

**À ajouter :**
- Notification quand chauffeur arrive (`ride-arrived`)
- Notification quand course démarre (`ride-started`)
- Notification de position en temps réel plus fluide

### **2. Système d'expiration**
❌ **Problème :** Les courses en `requested` restent indéfiniment

**Solution :**
```javascript
// Après 3 minutes sans acceptation
setTimeout(() => {
  if (ride.status === 'requested') {
    ride.status = 'expired';
    ride.save();
    io.to(`user_${ride.passenger}`).emit('ride-expired');
  }
}, 3 * 60 * 1000);
```

### **3. File d'attente de chauffeurs**
❌ **Problème :** Si premier chauffeur refuse, la course reste bloquée

**Solution :**
- Système de rotation automatique
- Proposer à d'autres chauffeurs si refus
- Élargir le rayon de recherche progressivement

### **4. Historique détaillé**
✅ **Implémenté partiellement**

**À améliorer :**
- Filtres par date plus précis
- Export PDF des courses
- Graphiques de statistiques
- Comparaison mois par mois

### **5. Paiement intégré**
❌ **Problème :** Paiement mobile pas encore intégré

**À implémenter :**
- API Orange Money
- API Wave
- API Free Money
- Gestion des remboursements automatiques

### **6. Suivi GPS en temps réel**
⚠️ **Partiellement implémenté**

**À améliorer :**
- Mise à jour position toutes les 3-5 secondes
- Calcul ETA (temps d'arrivée) dynamique
- Affichage du trajet sur la carte
- Alertes si chauffeur s'éloigne du trajet

### **7. Système de rating**
✅ **Implémenté pour client → chauffeur**

**À ajouter :**
- Chauffeur peut noter le client
- Commentaires obligatoires si note < 3
- Modération des commentaires
- Réponses aux évaluations

### **8. Gestion des litiges**
❌ **Non implémenté**

**À créer :**
- Bouton "Signaler un problème"
- Support client intégré
- Historique des litiges
- Remboursements partiels

### **9. Courses programmées**
⚠️ **Endpoint existe mais pas utilisé**

**À activer :**
- Interface pour programmer une course
- Notifications de rappel
- Assignation automatique à l'heure prévue

### **10. Mode hors ligne**
❌ **Non géré**

**À implémenter :**
- Cache des courses récentes
- Synchronisation automatique au retour en ligne
- Indicateur de connexion

---

## 📈 STATISTIQUES ET ANALYTICS

### **Données collectées**

**Par course :**
- Distance réelle vs estimée
- Durée réelle vs estimée
- Temps d'attente client
- Temps de réponse chauffeur
- Note finale

**Par chauffeur :**
- Taux d'acceptation
- Taux d'annulation
- Note moyenne
- Revenus journaliers/hebdo/mensuels
- Distance totale

**Par client :**
- Nombre de courses
- Dépenses totales
- Taux d'annulation
- Note moyenne donnée

**Globales (Admin) :**
- Courses par jour/heure
- Zones les plus demandées
- Prix moyens
- Taux de satisfaction

---

## 🔐 SÉCURITÉ

### **Vérifications en place**

✅ Authentification JWT pour toutes les requêtes  
✅ Vérification que chauffeur = chauffeur assigné  
✅ Vérification statut de course avant action  
✅ Vérification abonnement actif chauffeur  
✅ Vérification compte vérifié par admin  

### **À renforcer**

- Chiffrement des données sensibles
- Validation plus stricte des coordonnées GPS
- Détection de fraude (courses fictives)
- Limitation du nombre d'annulations
- Vérification d'identité renforcée

---

## 📞 SUPPORT

Pour toute question sur le circuit de course :
- Documentation technique : Ce fichier
- Code backend : `backend/src/routes/rides.js`
- Code client : `dudu_flutter/lib/screens/`
- Code chauffeur : `mobile_dudu_pro/lib/screens/`
