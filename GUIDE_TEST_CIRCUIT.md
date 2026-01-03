# 🧪 Guide de Test - Circuit Complet de Course DUDU

## 🎯 Objectif

Ce guide vous permet de tester le circuit complet d'une course DUDU, de la demande client jusqu'à la fin, pour vérifier que tout fonctionne correctement.

---

## 📋 Prérequis

### **1. Backend démarré**
```bash
cd backend
npm run dev
# Doit afficher: "✅ Connexion à MongoDB réussie"
# Doit afficher: "🚀 Serveur démarré sur le port 3000"
```

### **2. Comptes de test**

**Client :**
- Téléphone : `+221771234567`
- Mot de passe : `test123`

**Chauffeur :**
- Téléphone : `+221772345678`
- Mot de passe : `test123`
- **Important :** Doit être vérifié par admin (`verificationStatus: 'approved'`)

**Vérifier le chauffeur via MongoDB :**
```javascript
db.drivers.updateOne(
  { phone: "+221772345678" },
  { $set: { 
      verificationStatus: "approved",
      isVerified: true,
      status: "offline"
  }}
)
```

---

## 🧪 TEST COMPLET - Étape par étape

### **PHASE 1 : Préparation**

#### **Étape 1.1 : Ouvrir les deux applications**

**Terminal 1 - App Client :**
```bash
cd dudu_flutter
flutter run
```

**Terminal 2 - App Chauffeur :**
```bash
cd mobile_dudu_pro
flutter run
```

#### **Étape 1.2 : Connexion**

**Sur App Client :**
1. Ouvrir l'app
2. Se connecter avec `+221771234567` / `test123`
3. Vérifier que le dashboard s'affiche

**Sur App Chauffeur :**
1. Ouvrir l'app
2. Se connecter avec `+221772345678` / `test123`
3. Vérifier que le dashboard s'affiche

#### **Étape 1.3 : Mettre le chauffeur en ligne**

**Sur App Chauffeur :**
1. Sur le dashboard, activer le switch "En ligne"
2. **Vérifier :** Le switch passe au vert
3. **Vérifier :** Message "Vous êtes maintenant en ligne"

**Logs backend attendus :**
```
📡 Chauffeur +221772345678 est maintenant en ligne
```

---

### **PHASE 2 : Demande de Course**

#### **Étape 2.1 : Client demande une course**

**Sur App Client :**
1. Appuyer sur "Nouvelle course" ou "Commander"
2. Remplir le formulaire :
   - **Départ :** "Dakar, Plateau" (ou utiliser position actuelle)
   - **Arrivée :** "Dakar, Almadies"
   - **Prix proposé :** 3500 FCFA
   - **Type :** Standard
3. Appuyer sur "Confirmer la course"

**✅ Vérifications :**
- Message "Recherche de chauffeur en cours..."
- Loader/spinner affiché
- Pas d'erreur

**Logs backend attendus :**
```
🔍 Recherche chauffeurs: 1 trouvés en ligne
📡 Demande de course envoyée via Socket.io à 1 chauffeurs
```

#### **Étape 2.2 : Chauffeur reçoit la notification**

**Sur App Chauffeur :**

**✅ Vérifications :**
- 🔔 Notification sonore (si activée)
- 📱 Popup ou carte de course apparaît
- Informations affichées :
  - Départ : "Dakar, Plateau"
  - Arrivée : "Dakar, Almadies"
  - Distance : ~8.5 km
  - Prix : 3500 FCFA
  - Nom du client
- Boutons "Accepter" et "Refuser" visibles

**Logs backend attendus :**
```
📢 Course 65abc123... envoyée à chauffeur +221772345678
```

---

### **PHASE 3 : Acceptation**

#### **Étape 3.1 : Chauffeur accepte**

**Sur App Chauffeur :**
1. Appuyer sur "Accepter"
2. Attendre la confirmation

**✅ Vérifications :**
- Message "Course acceptée !"
- Écran change pour afficher les détails de la course
- Bouton "Je suis arrivé" visible
- Carte avec itinéraire vers le client

**Logs backend attendus :**
```
📢 Course 65abc123... acceptée par +221772345678
📢 Notification envoyée au client
```

#### **Étape 3.2 : Client reçoit confirmation**

**Sur App Client :**

**✅ Vérifications :**
- Message "Chauffeur trouvé !"
- Informations du chauffeur affichées :
  - Nom : "Prénom Nom"
  - Véhicule : "Toyota Corolla - DK-1234-AB"
  - Note : ⭐ 4.8/5
  - Photo (si disponible)
- Bouton "Appeler le chauffeur"
- Carte avec position du chauffeur
- Temps d'arrivée estimé

**Vérifier dans MongoDB :**
```javascript
db.rides.findOne({ rideId: "DUDU-2026-..." })
// Doit afficher:
// status: "accepted"
// driver: ObjectId("...")
// acceptedAt: ISODate("2026-01-03...")
```

---

### **PHASE 4 : Chauffeur en Route**

#### **Étape 4.1 : Simulation du déplacement**

**Sur App Chauffeur :**
- Le chauffeur se déplace (ou simuler en changeant la position GPS)
- Position mise à jour toutes les 5 secondes

**Sur App Client :**

**✅ Vérifications :**
- Icône du chauffeur se déplace sur la carte
- Temps d'arrivée mis à jour
- Distance restante diminue

**Logs backend attendus :**
```
📍 Position chauffeur mise à jour: lat=14.xxx, lng=-17.xxx
📡 Position envoyée au client
```

---

### **PHASE 5 : Arrivée**

#### **Étape 5.1 : Chauffeur signale son arrivée**

**Sur App Chauffeur :**
1. Appuyer sur "Je suis arrivé"
2. Attendre confirmation

**✅ Vérifications :**
- Message "Arrivée signalée"
- Bouton change pour "Démarrer la course"
- Statut affiché : "En attente du client"

**Sur App Client :**

**✅ Vérifications :**
- Notification "Votre chauffeur est arrivé !"
- Message "Le chauffeur vous attend"
- Bouton "Appeler" mis en évidence

**Vérifier dans MongoDB :**
```javascript
db.rides.findOne({ rideId: "DUDU-2026-..." })
// status: "arrived"
// arrivedAt: ISODate("2026-01-03...")
```

---

### **PHASE 6 : Début de Course**

#### **Étape 6.1 : Chauffeur démarre la course**

**Sur App Chauffeur :**
1. Vérifier que le client est monté
2. Appuyer sur "Démarrer la course"
3. Attendre confirmation

**✅ Vérifications :**
- Message "Course démarrée !"
- Chronomètre démarre
- Carte affiche l'itinéraire vers la destination
- Bouton "Terminer la course" visible

**Sur App Client :**

**✅ Vérifications :**
- Message "Course en cours"
- Chronomètre visible
- Carte montre le trajet
- Distance parcourue affichée
- Prix affiché

**Vérifier dans MongoDB :**
```javascript
db.rides.findOne({ rideId: "DUDU-2026-..." })
// status: "started"
// startedAt: ISODate("2026-01-03...")
```

**Logs backend attendus :**
```
🚗 Course 65abc123... démarrée
📡 Client notifié
```

---

### **PHASE 7 : Fin de Course**

#### **Étape 7.1 : Chauffeur termine la course**

**Sur App Chauffeur :**
1. Arriver à destination
2. Appuyer sur "Terminer la course"
3. Confirmer

**✅ Vérifications :**
- Message "Course terminée !"
- Récapitulatif affiché :
  - Distance : 8.7 km
  - Durée : 25 minutes
  - Gain : 3500 FCFA
- Bouton "Retour au dashboard"
- Statistiques mises à jour

**Sur App Client :**

**✅ Vérifications :**
- Message "Course terminée !"
- Récapitulatif affiché :
  - Distance : 8.7 km
  - Durée : 25 minutes
  - Prix : 3500 FCFA
- Bouton "Noter le chauffeur"
- Bouton "Payer"

**Vérifier dans MongoDB :**
```javascript
db.rides.findOne({ rideId: "DUDU-2026-..." })
// status: "completed"
// completedAt: ISODate("2026-01-03...")
// actualDuration: 25

// Vérifier stats chauffeur
db.drivers.findOne({ phone: "+221772345678" })
// stats.totalRides: +1
// stats.completedRides: +1
// stats.totalEarnings: +3500
// earnings.today: +3500

// Vérifier stats client
db.users.findOne({ phone: "+221771234567" })
// totalRides: +1
// totalSpent: +3500
```

**Logs backend attendus :**
```
✅ Course 65abc123... terminée
📊 Stats chauffeur mises à jour
📊 Stats client mises à jour
🚗 Chauffeur remis en ligne
```

---

### **PHASE 8 : Évaluation**

#### **Étape 8.1 : Client note le chauffeur**

**Sur App Client :**
1. Appuyer sur "Noter le chauffeur"
2. Sélectionner 5 étoiles
3. (Optionnel) Ajouter un commentaire : "Excellent chauffeur !"
4. Valider

**✅ Vérifications :**
- Message "Merci pour votre évaluation !"
- Retour au dashboard

**Vérifier dans MongoDB :**
```javascript
db.rides.findOne({ rideId: "DUDU-2026-..." })
// rating.passenger.rating: 5
// rating.passenger.comment: "Excellent chauffeur !"

db.drivers.findOne({ phone: "+221772345678" })
// rating: (nouvelle moyenne calculée)
// totalRatings: +1
```

---

### **PHASE 9 : Historique**

#### **Étape 9.1 : Vérifier l'historique client**

**Sur App Client :**
1. Aller dans "Mes courses" ou "Historique"
2. Vérifier que la course apparaît

**✅ Vérifications :**
- Course visible dans la liste
- Informations correctes :
  - Date et heure
  - Départ → Arrivée
  - Prix : 3500 FCFA
  - Chauffeur : Nom
  - Note donnée : ⭐⭐⭐⭐⭐
  - Statut : Terminée

#### **Étape 9.2 : Vérifier l'historique chauffeur**

**Sur App Chauffeur :**
1. Aller dans "Mes courses" ou "Statistiques"
2. Vérifier que la course apparaît

**✅ Vérifications :**
- Course visible dans la liste
- Informations correctes :
  - Date et heure
  - Départ → Arrivée
  - Gain : 3500 FCFA
  - Client : Nom
  - Note reçue : ⭐⭐⭐⭐⭐
  - Statut : Terminée
- Statistiques mises à jour :
  - Gains du jour : +3500 FCFA
  - Courses du jour : +1

---

## 🧪 TEST D'ANNULATION

### **Test 1 : Client annule avant acceptation**

**Étapes :**
1. Client demande une course
2. **AVANT** que le chauffeur accepte
3. Client appuie sur "Annuler"
4. Confirmer l'annulation

**✅ Vérifications :**
- Course disparaît de la liste des chauffeurs
- Message "Course annulée" au client
- Statut dans DB : `cancelled`
- `cancellation.cancelledBy: "passenger"`

### **Test 2 : Chauffeur annule après acceptation**

**Étapes :**
1. Client demande une course
2. Chauffeur accepte
3. Chauffeur appuie sur "Annuler la course"
4. Sélectionner une raison
5. Confirmer

**✅ Vérifications :**
- Client reçoit notification "Course annulée par le chauffeur"
- Chauffeur redevient disponible
- Statut dans DB : `cancelled`
- `cancellation.cancelledBy: "driver"`
- `cancellation.reason: "driver_cancelled"`

### **Test 3 : Vérifier historique des annulations**

**Admin Web :**
1. Ouvrir https://dudugroup.sn
2. Aller dans "Courses Annulées"
3. Vérifier que les courses annulées apparaissent

**✅ Vérifications :**
- Statistiques correctes
- Filtres fonctionnent (par client, par chauffeur)
- Raisons d'annulation affichées

---

## 🐛 DÉBOGAGE

### **Problème : Chauffeur ne reçoit pas la notification**

**Vérifications :**
1. Chauffeur est bien en ligne ?
   ```javascript
   db.drivers.findOne({ phone: "+221772345678" })
   // status: "online"
   // isAvailable: true
   ```

2. Chauffeur est vérifié ?
   ```javascript
   // verificationStatus: "approved"
   // isVerified: true
   ```

3. Socket.io connecté ?
   - Vérifier logs backend : "📡 Chauffeur connecté via Socket.io"
   - Vérifier dans l'app : Indicateur de connexion

4. Type de course compatible ?
   ```javascript
   // rideTypes.standard: true
   ```

### **Problème : Client ne voit pas le chauffeur**

**Vérifications :**
1. Vérifier que `ride.driver` est bien assigné dans MongoDB
2. Vérifier que Socket.io a émis `ride-accepted`
3. Vérifier logs backend pour erreurs
4. Redémarrer l'app client

### **Problème : Statistiques pas mises à jour**

**Vérifications :**
1. Vérifier que la course est bien `completed`
2. Vérifier logs backend : "📊 Stats chauffeur mises à jour"
3. Vérifier dans MongoDB :
   ```javascript
   db.drivers.findOne({ phone: "+221772345678" })
   // Vérifier stats.totalRides, earnings.today, etc.
   ```

### **Problème : Historique vide**

**Vérifications :**
1. Vérifier que des courses existent avec statut `completed` ou `cancelled`
2. Vérifier l'endpoint API :
   ```bash
   curl http://213.154.90.11:3000/api/v1/rides/user/history \
     -H "Authorization: Bearer <token>"
   ```
3. Vérifier les filtres dans l'app

---

## 📊 CHECKLIST COMPLÈTE

### **Fonctionnalités de base**
- [ ] Client peut demander une course
- [ ] Chauffeur reçoit la notification
- [ ] Chauffeur peut accepter
- [ ] Client voit le chauffeur assigné
- [ ] Chauffeur peut signaler son arrivée
- [ ] Client est notifié de l'arrivée
- [ ] Chauffeur peut démarrer la course
- [ ] Client voit la course en cours
- [ ] Chauffeur peut terminer la course
- [ ] Client voit la course terminée
- [ ] Client peut noter le chauffeur
- [ ] Statistiques sont mises à jour

### **Annulations**
- [ ] Client peut annuler avant acceptation
- [ ] Client peut annuler après acceptation
- [ ] Chauffeur peut annuler après acceptation
- [ ] Raisons d'annulation enregistrées
- [ ] Historique des annulations accessible

### **Historique**
- [ ] Client voit ses courses passées
- [ ] Chauffeur voit ses courses passées
- [ ] Admin voit toutes les courses
- [ ] Filtres fonctionnent
- [ ] Détails complets affichés

### **Temps réel**
- [ ] Position chauffeur mise à jour
- [ ] Notifications Socket.io fonctionnent
- [ ] Temps d'arrivée estimé affiché
- [ ] Chronomètre fonctionne

### **Statistiques**
- [ ] Gains chauffeur mis à jour
- [ ] Dépenses client mises à jour
- [ ] Nombre de courses incrémenté
- [ ] Distance totale calculée
- [ ] Note moyenne calculée

---

## 🎯 RÉSULTATS ATTENDUS

Après avoir suivi tous les tests, vous devriez avoir :

✅ **1 course complétée** dans MongoDB avec :
- Statut : `completed`
- Tous les timestamps remplis
- Note du client : 5/5
- Paiement : `completed` (si testé)

✅ **Statistiques chauffeur** mises à jour :
- `totalRides: 1`
- `completedRides: 1`
- `totalEarnings: 3500`
- `rating: 5.0`

✅ **Statistiques client** mises à jour :
- `totalRides: 1`
- `totalSpent: 3500`

✅ **Historique** visible dans les deux apps

✅ **Admin web** affiche la course dans le dashboard

---

## 📝 RAPPORT DE TEST

Après les tests, remplir ce rapport :

```
Date du test : ___________
Testeur : ___________

RÉSULTATS :
[ ] Demande de course : OK / KO
[ ] Notification chauffeur : OK / KO
[ ] Acceptation : OK / KO
[ ] Arrivée : OK / KO
[ ] Démarrage : OK / KO
[ ] Fin de course : OK / KO
[ ] Évaluation : OK / KO
[ ] Historique : OK / KO
[ ] Annulation : OK / KO
[ ] Statistiques : OK / KO

PROBLÈMES RENCONTRÉS :
1. ___________
2. ___________
3. ___________

AMÉLIORATIONS SUGGÉRÉES :
1. ___________
2. ___________
3. ___________
```

---

**Bon test ! 🚀**
