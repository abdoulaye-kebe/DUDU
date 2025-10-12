# 🤝 Flux Covoiturage - Documentation Complète

## 🎯 Question : "Est-ce que si le chauffeur active covoiturage, les clients vont voir au niveau application client ?"

### ✅ Réponse : OUI, de manière intelligente !

---

## 🔄 Fonctionnement Complet

### Étape 1 : 🚕 Chauffeur Active le Covoiturage

```
📱 Application DUDU Pro (Chauffeur)
│
├─ Chauffeur appuie sur "Covoiturage"
├─ Dialogue s'ouvre : "Combien de places disponibles ?"
│  └─ Options : 1️⃣ 2️⃣ 3️⃣ 4️⃣
│
├─ Chauffeur choisit : 3 places
│
└─ ✅ Statut mis à jour :
    {
      carpoolMode: true,
      availableSeats: 3,
      status: 'online'
    }
```

**Backend :**
```javascript
// Le chauffeur devient visible pour covoiturage
driver.preferences.acceptSharedRides = true
driver.preferences.carpoolSeats = 3
driver.status = 'online'

→ Envoi notification au système
→ Mise à jour en temps réel (Socket.io)
```

---

### Étape 2 : 📱 Client Voit l'Option Covoiturage

#### Interface Client Améliorée

```
┌────────────────────────────────────┐
│  Choisissez votre type de course   │
├────────────────────────────────────┤
│                                    │
│  🚗 Standard                       │
│  └─ 2000 FCFA                      │
│     ✅ 12 chauffeurs disponibles   │  ← Compteur en temps réel
│                                    │
│  ⚡ Express                        │
│  └─ 2600 FCFA                      │
│     ✅ 8 chauffeurs disponibles    │
│                                    │
│  🤝 Partagé (Covoiturage)          │  ← OPTION COVOITURAGE
│  └─ 1600 FCFA (-20%)               │
│     ✅ 5 chauffeurs disponibles    │  ← Affiche seulement les chauffeurs
│     🪑 18 places disponibles       │     avec covoiturage ACTIVÉ
│                                    │
│  ✨ Premium                        │
│  └─ 3000 FCFA                      │
│     ✅ 3 chauffeurs disponibles    │
│                                    │
└────────────────────────────────────┘
```

---

### Étape 3 : 🔍 Système Trouve Chauffeurs Compatibles

Quand le client choisit **"Partagé"** :

```
Backend - Logique de recherche :

1. Récupérer position client
2. Calculer trajet désiré
3. Chercher chauffeurs :
   ✅ status = 'online'
   ✅ preferences.acceptSharedRides = true
   ✅ preferences.carpoolSeats > 0
   ✅ distance < 5km du client
   ✅ trajet compatible (même direction)

4. Trier par :
   - Distance
   - Note
   - Places disponibles
   
5. Envoyer notifications aux chauffeurs compatibles
```

**Exemple de requête :**
```javascript
// API Backend
GET /api/v1/drivers/available?
  rideType=shared
  &latitude=14.7167
  &longitude=-17.4677
  &destination_lat=14.7500
  &destination_lng=-17.4500
  
// Réponse
{
  "available": true,
  "count": 5,
  "drivers": [
    {
      "id": "driver123",
      "name": "Mamadou Sall",
      "rating": 4.8,
      "distance": 1.2,
      "carpoolSeats": 3,
      "vehicle": "Toyota Corolla"
    },
    ...
  ]
}
```

---

### Étape 4 : 📊 Affichage en Temps Réel

#### Mise à jour automatique (Socket.io)

```javascript
// Client écoute les événements
socket.on('drivers_update', (data) => {
  // Nombre de chauffeurs covoiturage disponibles
  carpoolDriversCount = data.carpoolDrivers
  availableSeats = data.totalSeats
  
  // Met à jour l'interface
  setState(() {
    _carpoolDriversCount = carpoolDriversCount
    _carpoolSeats = availableSeats
  })
})
```

**Résultat :**
```
Si 5 chauffeurs activent covoiturage avec 3 places chacun
→ Client voit : "5 chauffeurs disponibles | 15 places"

Si 2 chauffeurs désactivent
→ Temps réel : "3 chauffeurs disponibles | 9 places"
```

---

## 💡 Améliorations UX Proposées

### 1. Badge "Covoiturage Actif"

Sur la carte, afficher les chauffeurs en covoiturage avec un badge spécial :

```
🚗 Chauffeur Standard → Icône normale 🚗
🤝 Chauffeur Covoiturage → Icône spéciale 🚗🤝
```

### 2. Notification Push Client

Quand beaucoup de chauffeurs activent covoiturage :

```
🔔 Notification :
"5 chauffeurs en covoiturage près de vous !
Économisez jusqu'à 20% sur votre course 💰"
```

### 3. Prix Dynamique

Afficher le prix réduit instantanément :

```
Prix normal : 3000 FCFA
Prix covoiturage : 2400 FCFA ✅
Vous économisez : 600 FCFA 💰
```

### 4. Indicateur de Places Disponibles

```
🚗 Mamadou Sall - 4.8⭐
   Toyota Corolla
   🪑 3 places disponibles
   📍 1.2 km
   ⏱️ 3 min
```

---

## 🔐 Règles de Visibilité

### Le client VOIT un chauffeur en covoiturage SI :

✅ Chauffeur `status = 'online'`  
✅ Chauffeur `carpoolMode = true`  
✅ Chauffeur `carpoolSeats > 0`  
✅ Distance < 5km du client  
✅ Trajet compatible (même direction)  
✅ Abonnement chauffeur valide  

### Le client NE VOIT PAS un chauffeur SI :

❌ Chauffeur hors ligne  
❌ Covoiturage désactivé  
❌ Aucune place disponible  
❌ Trop loin du client  
❌ Déjà en course  
❌ Trajet incompatible  

---

## 📈 Exemple de Scénario Complet

### 10h00 - Situation initiale
```
Zone Almadies :
- 15 chauffeurs en ligne
- 0 en mode covoiturage
```

**Client ouvre l'app :**
```
🤝 Partagé (Covoiturage)
   ❌ Aucun chauffeur disponible
```

### 10h15 - Chauffeurs activent covoiturage
```
Mamadou active : 3 places
Moussa active : 2 places
Cheikh active : 4 places

→ Total : 3 chauffeurs, 9 places
```

**Client rafraîchit :**
```
🤝 Partagé (Covoiturage)
   ✅ 3 chauffeurs disponibles
   🪑 9 places disponibles
   💰 1600 FCFA (au lieu de 2000)
```

### 10h20 - Client demande course partagée
```
Client : Almadies → Plateau
Système trouve : Mamadou (trajet compatible)
Mamadou accepte
Places restantes : 2

→ Système peut encore attribuer 2 passagers
```

### 10h25 - Autre client demande
```
Client 2 : Ngor → Médina (compatible)
Système propose : Même voiture que Client 1
Client 2 accepte
Places restantes : 1

Prix réduit pour les 2 :
- Client 1 : 2000 → 1700 FCFA
- Client 2 : 1800 → 1530 FCFA
```

---

## 🎨 Implémentation Technique

### Backend - Route API

```javascript
// routes/drivers.js
router.get('/available', async (req, res) => {
  const { rideType, latitude, longitude } = req.query;
  
  let query = {
    status: 'online',
    isAvailable: true
  };
  
  // Si demande de covoiturage
  if (rideType === 'shared') {
    query['preferences.acceptSharedRides'] = true;
    query['preferences.carpoolSeats'] = { $gt: 0 };
  }
  
  const drivers = await Driver.find(query)
    .where('currentLocation')
    .near({
      center: [longitude, latitude],
      maxDistance: 5000 // 5km
    });
    
  res.json({
    available: drivers.length > 0,
    count: drivers.length,
    totalSeats: drivers.reduce((sum, d) => 
      sum + d.preferences.carpoolSeats, 0
    ),
    drivers: drivers.map(formatDriver)
  });
});
```

### Frontend Flutter - Affichage

```dart
// client_home_screen.dart
Widget _buildRideTypeOption(String type, String emoji, double multiplier) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _getAvailableDrivers(type),
    builder: (context, snapshot) {
      final count = snapshot.data?['count'] ?? 0;
      final seats = snapshot.data?['totalSeats'] ?? 0;
      
      return ListTile(
        leading: Text(emoji, style: TextStyle(fontSize: 32)),
        title: Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: type == 'Partagé' && count > 0
          ? Text('$count chauffeurs • $seats places', 
                 style: TextStyle(color: Colors.green))
          : Text('$count disponibles'),
        trailing: Text(
          '${(2000 * multiplier).toInt()} FCFA',
          style: TextStyle(
            color: Color(0xFF00A651),
            fontWeight: FontWeight.bold
          ),
        ),
        onTap: () => _selectRideType(type),
      );
    }
  );
}
```

---

## ✅ Résumé

### Quand chauffeur active covoiturage :

1. ✅ **Backend** enregistre : `carpoolMode = true`, `seats = 3`
2. ✅ **Socket.io** notifie tous les clients en temps réel
3. ✅ **Clients** voient l'option "Partagé" avec compteur
4. ✅ **Système** cherche uniquement chauffeurs covoiturage
5. ✅ **Prix réduit** automatiquement (-10% à -20%)

### Le client voit :
- ✅ Nombre de chauffeurs covoiturage disponibles
- ✅ Nombre total de places disponibles
- ✅ Prix réduit
- ✅ Mise à jour en temps réel

---

**C'est un système intelligent et transparent ! Le client sait toujours combien de chauffeurs en covoiturage sont disponibles.** 🤝✨

---

**DUDU - Transport Intelligent au Sénégal 🇸🇳**

