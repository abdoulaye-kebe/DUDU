# 🗺️ Schéma Visuel du Flux de Course DUDU

## 📊 Vue d'ensemble simplifiée

```
┌─────────────┐                                    ┌──────────────┐
│   CLIENT    │                                    │  CHAUFFEUR   │
│ (dudu_app)  │                                    │ (dudu_pro)   │
└──────┬──────┘                                    └──────┬───────┘
       │                                                  │
       │ 1. Demande course                               │
       │ (départ, arrivée, prix)                         │
       ├──────────────────────────────────────────┐      │
       │                                          │      │
       │                                          ▼      │
       │                                    ┌──────────────────┐
       │                                    │     BACKEND      │
       │                                    │  (Node.js API)   │
       │                                    └────────┬─────────┘
       │                                             │
       │                                             │ 2. Recherche
       │                                             │    chauffeurs
       │                                             │    disponibles
       │                                             │
       │                                             ├─────────────────┐
       │                                             │                 │
       │                                             ▼                 ▼
       │                                    ┌──────────────┐   ┌──────────────┐
       │                                    │  Socket.io   │   │   MongoDB    │
       │                                    │  (temps réel)│   │  (database)  │
       │                                    └──────┬───────┘   └──────────────┘
       │                                           │
       │                                           │ 3. Notification
       │                                           │    "new-ride-request"
       │                                           │
       │                                           ├──────────────────────────┐
       │                                           │                          │
       │                                           ▼                          ▼
       │                                    ┌──────────┐              ┌──────────┐
       │                                    │Chauffeur1│              │Chauffeur2│
       │                                    │ (online) │              │ (online) │
       │                                    └────┬─────┘              └──────────┘
       │                                         │
       │                                         │ 4. Accepte
       │                                         │    la course
       │                                         │
       │                                         ▼
       │                                    ┌──────────────┐
       │◄───────────────────────────────────┤   BACKEND    │
       │ 5. "ride-accepted"                 │ (assignation)│
       │    Infos chauffeur                 └──────────────┘
       │                                             │
       │                                             │ 6. Chauffeur
       │                                             │    en route
       │                                             ▼
       │◄────────────────────────────────────────────┤
       │ 7. Position GPS temps réel                  │
       │    (toutes les 5 sec)                       │
       │                                             │
       │                                             │ 8. Arrivé
       │◄────────────────────────────────────────────┤
       │ "ride-arrived"                              │
       │                                             │
       │                                             │ 9. Démarre
       │◄────────────────────────────────────────────┤    course
       │ "ride-started"                              │
       │                                             │
       │                                             │ 10. Termine
       │◄────────────────────────────────────────────┤     course
       │ "ride-completed"                            │
       │                                             │
       │ 11. Note chauffeur                          │
       ├────────────────────────────────────────────►│
       │                                             │
       │ 12. Paiement                                │
       ├────────────────────────────────────────────►│
       │                                             │
       ▼                                             ▼
   [FIN]                                         [FIN]
```

---

## 🔄 Diagramme détaillé des statuts

```
                    DEMANDE DE COURSE
                          │
                          ▼
                  ┌───────────────┐
                  │   requested   │ ◄─── Client envoie demande
                  └───────┬───────┘
                          │
                          ├──────────► [no_driver] ──► Aucun chauffeur trouvé
                          │
                          ├──────────► [expired] ────► Timeout (3 min)
                          │
                          ▼
                  ┌───────────────┐
                  │   searching   │ ◄─── Recherche active
                  └───────┬───────┘
                          │
                          ▼
                  ┌───────────────┐
                  │   accepted    │ ◄─── Chauffeur accepte
                  └───────┬───────┘
                          │
                          │ Annulation possible ici
                          │         │
                          │         └──────────► [cancelled]
                          │
                          ▼
                  ┌───────────────┐
                  │   arriving    │ ◄─── Chauffeur en route (optionnel)
                  └───────┬───────┘
                          │
                          ▼
                  ┌───────────────┐
                  │    arrived    │ ◄─── Chauffeur arrivé
                  └───────┬───────┘
                          │
                          │ Annulation possible ici
                          │         │
                          │         └──────────► [cancelled]
                          │
                          ▼
                  ┌───────────────┐
                  │    started    │ ◄─── Course en cours
                  └───────┬───────┘
                          │
                          │ Annulation rare ici
                          │
                          ▼
                  ┌───────────────┐
                  │   completed   │ ◄─── Course terminée ✅
                  └───────────────┘
                          │
                          ▼
                  ┌───────────────┐
                  │ Rating/Payment│ ◄─── Évaluation + Paiement
                  └───────────────┘
```

---

## 📱 Architecture des applications

```
┌─────────────────────────────────────────────────────────────────┐
│                        DUDU ECOSYSTEM                            │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│   APP CLIENT     │         │   APP CHAUFFEUR  │         │   ADMIN WEB      │
│  (dudu_flutter)  │         │(mobile_dudu_pro) │         │  (React.js)      │
├──────────────────┤         ├──────────────────┤         ├──────────────────┤
│ • Demander course│         │ • Voir demandes  │         │ • Voir toutes    │
│ • Suivre course  │         │ • Accepter course│         │   les courses    │
│ • Noter chauffeur│         │ • Gérer course   │         │ • Statistiques   │
│ • Payer          │         │ • Voir gains     │         │ • Gérer users    │
│ • Historique     │         │ • Historique     │         │ • Annulations    │
└────────┬─────────┘         └────────┬─────────┘         └────────┬─────────┘
         │                            │                            │
         │                            │                            │
         └────────────────┬───────────┴────────────────────────────┘
                          │
                          │ HTTP REST API + Socket.io
                          │
                          ▼
         ┌────────────────────────────────────────┐
         │          BACKEND (Node.js)             │
         ├────────────────────────────────────────┤
         │                                        │
         │  ┌──────────────────────────────────┐ │
         │  │      Routes (Express.js)         │ │
         │  ├──────────────────────────────────┤ │
         │  │ • /api/v1/rides/request          │ │
         │  │ • /api/v1/rides/:id/accept       │ │
         │  │ • /api/v1/rides/:id/arrive       │ │
         │  │ • /api/v1/rides/:id/start        │ │
         │  │ • /api/v1/rides/:id/complete     │ │
         │  │ • /api/v1/rides/:id/cancel       │ │
         │  │ • /api/v1/rides/:id/rate         │ │
         │  │ • /api/v1/admin/rides            │ │
         │  │ • /api/v1/admin/rides/cancelled  │ │
         │  └──────────────────────────────────┘ │
         │                                        │
         │  ┌──────────────────────────────────┐ │
         │  │    Socket.io (Temps réel)        │ │
         │  ├──────────────────────────────────┤ │
         │  │ • new-ride-request               │ │
         │  │ • ride-accepted                  │ │
         │  │ • ride-taken                     │ │
         │  │ • driver-location                │ │
         │  │ • ride-cancelled                 │ │
         │  │ • ride-completed                 │ │
         │  └──────────────────────────────────┘ │
         │                                        │
         │  ┌──────────────────────────────────┐ │
         │  │      Models (Mongoose)           │ │
         │  ├──────────────────────────────────┤ │
         │  │ • User (Client)                  │ │
         │  │ • Driver (Chauffeur)             │ │
         │  │ • Ride (Course)                  │ │
         │  │ • Payment (Paiement)             │ │
         │  │ • Subscription (Abonnement)      │ │
         │  └──────────────────────────────────┘ │
         │                                        │
         └────────────────┬───────────────────────┘
                          │
                          ▼
         ┌────────────────────────────────────────┐
         │         MongoDB (Database)             │
         ├────────────────────────────────────────┤
         │ Collections:                           │
         │ • users                                │
         │ • drivers                              │
         │ • rides ◄─── Historique complet        │
         │ • payments                             │
         │ • subscriptions                        │
         └────────────────────────────────────────┘
```

---

## 🔔 Flux des notifications Socket.io

```
ÉVÉNEMENT: new-ride-request
┌──────────┐
│ Backend  │
└────┬─────┘
     │
     │ io.emit('new-ride-request', {...})
     │
     ├─────────────────────────────────────────────┐
     │                                             │
     ▼                                             ▼
┌──────────┐                                  ┌──────────┐
│Chauffeur1│                                  │Chauffeur2│
│ (online) │                                  │ (online) │
└──────────┘                                  └──────────┘
     │                                             │
     │ Affiche notification                        │ Affiche notification
     │ "Nouvelle course disponible"                │ "Nouvelle course disponible"
     │                                             │
     │ [Accepter] [Refuser]                        │ [Accepter] [Refuser]
     │                                             │
     │ Clique "Accepter"                           │
     ▼                                             │
┌──────────┐                                       │
│ Backend  │                                       │
└────┬─────┘                                       │
     │                                             │
     │ io.to('user_123').emit('ride-accepted')    │
     │ io.emit('ride-taken')                       │
     │                                             │
     ├─────────────────────────────────────────────┼──────────┐
     │                                             │          │
     ▼                                             ▼          ▼
┌──────────┐                                  ┌──────────┐ ┌──────────┐
│  Client  │                                  │Chauffeur2│ │Chauffeur3│
└──────────┘                                  └──────────┘ └──────────┘
     │                                             │          │
     │ Affiche:                                    │          │
     │ "Chauffeur trouvé!"                         │          │
     │ Nom, véhicule, photo                        │          │
     │                                             │          │
     │                                        Retire course   Retire course
     │                                        de la liste     de la liste
```

---

## 💾 Structure de données dans MongoDB

```
Collection: rides
┌────────────────────────────────────────────────────────────┐
│ {                                                          │
│   _id: ObjectId("65abc123..."),                           │
│   rideId: "DUDU-2026-001234",                             │
│   passenger: ObjectId("65user123..."), ◄─── Ref User      │
│   driver: ObjectId("65driver456..."),  ◄─── Ref Driver    │
│                                                            │
│   pickup: {                                                │
│     address: "Dakar, Plateau",                            │
│     coordinates: { lat: 14.6928, lng: -17.4467 }          │
│   },                                                       │
│                                                            │
│   destination: {                                           │
│     address: "Dakar, Almadies",                           │
│     coordinates: { lat: 14.7392, lng: -17.4978 }          │
│   },                                                       │
│                                                            │
│   distance: 8.5,              // km                       │
│   estimatedDuration: 17,      // minutes                  │
│   actualDuration: 25,         // minutes (après course)   │
│                                                            │
│   pricing: {                                               │
│     basePrice: 500,                                       │
│     distancePrice: 1700,                                  │
│     timePrice: 170,                                       │
│     surgeMultiplier: 1.0,                                 │
│     totalPrice: 3500,         // FCFA                     │
│     currency: "XOF"                                       │
│   },                                                       │
│                                                            │
│   status: "completed", ◄───────────────────────────────── │
│   rideType: "standard",                                   │
│                                                            │
│   requestedAt: "2026-01-03T20:00:00Z",                    │
│   acceptedAt: "2026-01-03T20:02:15Z",                     │
│   arrivedAt: "2026-01-03T20:12:30Z",                      │
│   startedAt: "2026-01-03T20:15:00Z",                      │
│   completedAt: "2026-01-03T20:40:00Z",                    │
│   cancelledAt: null,                                       │
│                                                            │
│   cancellation: {             // Si annulée               │
│     reason: "passenger_cancelled",                        │
│     cancelledBy: "passenger", // ou "driver" ou "system"  │
│     refundAmount: 3500,                                   │
│     refundProcessed: false                                │
│   },                                                       │
│                                                            │
│   rating: {                                                │
│     passenger: {                                           │
│       rating: 5,              // 1-5 étoiles              │
│       comment: "Excellent!"                               │
│     }                                                      │
│   },                                                       │
│                                                            │
│   payment: {                                               │
│     method: "cash",           // ou orange_money, wave    │
│     status: "completed",      // pending, processing, etc │
│     transactionId: null,                                  │
│     paidAt: "2026-01-03T20:45:00Z"                        │
│   }                                                        │
│ }                                                          │
└────────────────────────────────────────────────────────────┘
```

---

## 📊 Flux de données - Historique

```
┌─────────────────────────────────────────────────────────────┐
│                    HISTORIQUE DES COURSES                    │
└─────────────────────────────────────────────────────────────┘

CLIENT demande historique:
┌──────────┐
│  Client  │
│   App    │
└────┬─────┘
     │
     │ GET /api/v1/rides/user/history
     │
     ▼
┌──────────────────┐
│     Backend      │
│                  │
│ Ride.find({      │
│   passenger: id, │
│   status: {      │
│     $in: [       │
│      'completed',│
│      'cancelled' │
│     ]            │
│   }              │
│ })               │
│ .sort({          │
│   completedAt: -1│
│ })               │
└────┬─────────────┘
     │
     ▼
┌──────────────────┐
│    MongoDB       │
│                  │
│ Retourne:        │
│ [                │
│   {course1},     │
│   {course2},     │
│   {course3}      │
│ ]                │
└────┬─────────────┘
     │
     ▼
┌──────────┐
│  Client  │
│   App    │
│          │
│ Affiche: │
│ ┌──────┐ │
│ │Course│ │
│ │ #1   │ │
│ └──────┘ │
│ ┌──────┐ │
│ │Course│ │
│ │ #2   │ │
│ └──────┘ │
└──────────┘

CHAUFFEUR demande historique:
┌──────────┐
│Chauffeur │
│   App    │
└────┬─────┘
     │
     │ GET /api/v1/drivers/rides/history
     │
     ▼
┌──────────────────┐
│     Backend      │
│                  │
│ Ride.find({      │
│   driver: id,    │
│   status: {      │
│     $in: [       │
│      'completed',│
│      'cancelled' │
│     ]            │
│   }              │
│ })               │
│ .populate(       │
│   'passenger'    │
│ )                │
└────┬─────────────┘
     │
     ▼
┌──────────┐
│Chauffeur │
│   App    │
│          │
│ Affiche: │
│ ┌──────┐ │
│ │Gains │ │
│ │3500F │ │
│ └──────┘ │
│ ┌──────┐ │
│ │Gains │ │
│ │2800F │ │
│ └──────┘ │
└──────────┘

ADMIN demande toutes les courses:
┌──────────┐
│  Admin   │
│   Web    │
└────┬─────┘
     │
     │ GET /api/v1/admin/rides?status=completed
     │
     ▼
┌──────────────────┐
│     Backend      │
│                  │
│ Ride.find({      │
│   status: filter │
│ })               │
│ .populate(       │
│   'passenger',   │
│   'driver'       │
│ )                │
│ .sort({          │
│   createdAt: -1  │
│ })               │
│ .limit(20)       │
└────┬─────────────┘
     │
     ▼
┌──────────┐
│  Admin   │
│   Web    │
│          │
│ Tableau: │
│ ┌──────────────────────────────┐ │
│ │ID│Client│Chauffeur│Prix│Stat│ │
│ ├──┼──────┼─────────┼────┼────┤ │
│ │01│Abdou │Moussa   │3500│✓   │ │
│ │02│Fatou │Ibra     │2800│✓   │ │
│ └──────────────────────────────┘ │
└──────────┘
```

---

## 🎯 Points clés à retenir

### ✅ Ce qui fonctionne bien
1. **Système de statuts** - Bien défini et cohérent
2. **Notifications Socket.io** - Temps réel pour demandes et acceptations
3. **Historique** - Sauvegarde complète de toutes les courses
4. **Statistiques** - Mise à jour automatique pour chauffeurs et clients
5. **Annulation** - Gérée avec raisons et remboursements

### ⚠️ Ce qui peut être amélioré
1. **Expiration des demandes** - Pas de timeout automatique
2. **Notifications manquantes** - Arrivée et démarrage pas notifiés
3. **Paiement mobile** - Pas encore intégré (Orange Money, Wave)
4. **GPS temps réel** - Mise à jour position à améliorer
5. **File d'attente** - Si chauffeur refuse, pas de rotation automatique

### 🚀 Prochaines étapes recommandées
1. Implémenter timeout 3 minutes pour demandes
2. Ajouter toutes les notifications Socket.io manquantes
3. Intégrer APIs de paiement mobile
4. Améliorer suivi GPS (3-5 secondes)
5. Créer système de file d'attente chauffeurs
6. Ajouter notifications push
7. Implémenter courses programmées
8. Créer système de litiges/support
