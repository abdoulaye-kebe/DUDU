# 🚗 DUDU - Logique Métier Complète

## 📋 Vue d'ensemble

DUDU est une plateforme de transport et livraison avec **deux catégories de véhicules** :

### 🚗 VOITURES
**Servent uniquement au transport de personnes et bagages**

#### Types de voitures :
1. **Standard** 🚗
   - Voiture classique
   - Transport de passagers
   - Prix de base
   - Covoiturage possible

2. **Express** ⚡
   - Course rapide avec priorité
   - Transport de passagers
   - Prix majoré (1.3x)
   - Covoiturage possible

3. **Premium** ✨
   - Voiture haut de gamme
   - Transport de passagers
   - Prix majoré (1.5x)
   - Covoiturage possible

4. **Cargo** 🧳
   - Voiture spacieuse pour bagages
   - Transport de bagages volumineux
   - Prix majoré (1.2x)
   - **PAS de covoiturage** (pour bagages uniquement)

### 🏍️ MOTOS
**Servent uniquement à la livraison de colis**

#### Types de service moto :
1. **Livraison Express** 📦
   - Colis et documents
   - Livraison rapide
   - Photos obligatoires
   - Code de confirmation OTP

---

## 🤝 Covoiturage (Voitures uniquement)

### Principe
Le chauffeur peut **accepter plusieurs passagers** sur un même trajet compatible.

### Fonctionnement

#### 1. Activation par le chauffeur
```
1. Chauffeur active "Mode Covoiturage"
2. Système demande : "Combien de places disponibles ?"
3. Chauffeur choisit : 1, 2, 3 ou 4 places
4. Le système cherche des passagers sur trajets compatibles
```

#### 2. Attribution des places
```
Exemple : Chauffeur active 3 places
├── Passager 1 demande : Almadies → Plateau (1 place)
├── Passager 2 demande : Ngor → Médina (1 place) 
└── Passager 3 demande : Ouakam → Point E (1 place)

Si trajets compatibles → 3 passagers dans la même voiture
```

#### 3. Tarification
- **Réduction automatique** pour chaque passager
- Plus il y a de passagers, moins chacun paie
- Exemple :
  - Course solo : 3000 FCFA
  - Course à 3 : 2400 FCFA/personne (réduction 20%)

### Règles
✅ Voitures Standard, Express, Premium  
❌ Voitures Cargo (réservées aux bagages)  
❌ Motos (livraison uniquement)  
✅ Nombre de places : 1 à 4 (selon capacité véhicule)  
✅ Trajets compatibles uniquement  

---

## 🧳 Transport de Bagages (Voitures Cargo)

### Principe
Des voitures spacieuses dédiées au **transport de bagages volumineux**.

### Cas d'usage
- Déménagement
- Transport de marchandises
- Bagages aéroport
- Achats volumineux

### Fonctionnement
```
1. Client choisit "Bagages"
2. Précise :
   - Nombre de bagages
   - Taille approximative
   - Poids estimé
3. Système trouve une voiture cargo disponible
4. Chauffeur cargo accepte
5. Transport effectué
```

### Règles
✅ Voitures Cargo uniquement  
❌ Covoiturage impossible  
❌ Transport de personnes + bagages simultané  
✅ Tarification selon volume/poids  

---

## 📦 Livraison de Colis (Motos uniquement)

### Principe
Livraison rapide de colis par moto.

### Types de colis
1. **Document** 📄 - Léger, urgent
2. **Petit colis** 📦 - Jusqu'à 5kg
3. **Moyen colis** 📦 - 5-15kg
4. **Grand colis** 📦 - 15-30kg
5. **Nourriture** 🍱 - Livraison rapide
6. **Fragile** ⚠️ - Manipulation délicate

### Processus complet

#### Étape 1 : Demande du client
```
1. Client sélectionne "Livraison"
2. Remplit les informations :
   ├── Adresse de récupération
   ├── Adresse de livraison
   ├── Type de colis
   ├── Poids et dimensions
   ├── Description
   └── Contact du destinataire
3. Prend photo du colis
4. Confirme la demande
```

#### Étape 2 : Attribution à une moto
```
1. Système trouve motos disponibles à proximité
2. Moto accepte la livraison
3. Moto se rend au point de récupération
```

#### Étape 3 : Récupération du colis
```
1. Moto arrive chez l'expéditeur
2. Vérifie le colis
3. Prend photo de confirmation
4. Démarre le transport
5. Système génère code OTP (ex: 1234)
```

#### Étape 4 : Livraison
```
1. Moto arrive chez le destinataire
2. Destinataire reçoit le colis
3. Moto demande le code OTP
4. Destinataire donne le code
5. Moto prend photo de preuve
6. Système valide avec le code OTP
7. Livraison confirmée
```

### Sécurité
- ✅ Photos obligatoires (avant/après)
- ✅ Code OTP pour validation
- ✅ Tracking GPS en temps réel
- ✅ Assurance incluse
- ✅ Support client 24/7

### Règles
✅ Motos uniquement  
❌ Voitures ne font PAS de livraison  
✅ Photos obligatoires  
✅ Code OTP obligatoire  
✅ Poids max : 30kg  

---

## 👥 Interface Chauffeur - Options disponibles

### 🚗 Chauffeur VOITURE Standard/Express/Premium
```
Options disponibles :
├── ✅ Statut En ligne / Hors ligne
├── ✅ Mode Covoiturage (avec nb de places)
└── ❌ Livraisons (réservé aux motos)
```

### 🚗 Chauffeur VOITURE Cargo
```
Options disponibles :
├── ✅ Statut En ligne / Hors ligne
├── ✅ Transport de bagages
└── ❌ Covoiturage (incompatible avec bagages)
```

### 🏍️ Chauffeur MOTO
```
Options disponibles :
├── ✅ Statut En ligne / Hors ligne
├── ✅ Livraisons
└── ❌ Covoiturage (pas de passagers sur moto)
```

---

## 💰 Tarification

### Courses Voitures (au kilomètre)
| Type | Multiplicateur | Exemple (10km) |
|------|----------------|----------------|
| Standard | 1.0x | 2000 FCFA |
| Express | 1.3x | 2600 FCFA |
| Premium | 1.5x | 3000 FCFA |
| Cargo (bagages) | 1.2x | 2400 FCFA |

### Covoiturage (réduction)
```
Réduction par nb de passagers :
- 2 passagers : -10% chacun
- 3 passagers : -15% chacun
- 4 passagers : -20% chacun
```

### Livraisons Moto (forfait + distance)
| Type colis | Base | + par km |
|-----------|------|----------|
| Document | 500 FCFA | 100 FCFA |
| Petit | 800 FCFA | 150 FCFA |
| Moyen | 1200 FCFA | 200 FCFA |
| Grand | 1800 FCFA | 250 FCFA |

---

## 🎯 Règles Métier Importantes

### ✅ CE QUI EST POSSIBLE

**Voitures** :
- Transport de passagers (solo ou covoiturage)
- Transport de bagages (voitures cargo uniquement)
- Courses programmées
- Paiement mobile ou cash

**Motos** :
- Livraison de colis uniquement
- Livraison express
- Photos obligatoires
- Code OTP pour validation

### ❌ CE QUI N'EST PAS POSSIBLE

- ❌ Voiture ne peut pas faire de livraison de colis
- ❌ Moto ne peut pas transporter de passagers
- ❌ Covoiturage sur voiture cargo (réservée bagages)
- ❌ Transport passagers + bagages simultané
- ❌ Livraison sans photo de preuve
- ❌ Livraison sans code OTP

---

## 🔄 Flux de Données

### Backend - Modèle Driver
```javascript
{
  vehicle: {
    category: 'car' | 'moto',  // Catégorie
    type: 'standard' | 'cargo' | 'premium' | 'moto_delivery',
    capacity: 4  // Capacité totale
  },
  preferences: {
    acceptSharedRides: true,  // Covoiturage
    carpoolSeats: 2,          // Nb places dispo
    acceptLuggage: false      // Bagages (cargo)
  }
}
```

### Backend - Modèle Ride
```javascript
{
  rideType: 'standard' | 'express' | 'premium' | 'shared' | 'cargo' | 'delivery',
  vehicleCategory: 'car' | 'moto',
  carpoolInfo: {
    isCarpool: false,
    requestedSeats: 1,
    availableSeats: 3,
    otherPassengers: [...]
  },
  delivery: {
    packageType: '...',
    photos: {...},
    confirmationCode: '1234'
  }
}
```

---

## 📱 Interface Client - Sélection

```
┌─────────────────────────────┐
│   Choisissez votre service  │
├─────────────────────────────┤
│                             │
│ 🚗 VOITURES                 │
│ ├─ Standard (2000 FCFA)     │
│ ├─ Express (2600 FCFA)      │
│ ├─ Premium (3000 FCFA)      │
│ ├─ Partagé (1600 FCFA)      │
│ └─ Bagages (2400 FCFA)      │
│                             │
│ ─────────────────────────   │
│                             │
│ 🏍️ MOTOS                    │
│ └─ Livraison (dès 500 FCFA) │
│                             │
└─────────────────────────────┘
```

---

## ✅ Validation et Cohérence

### Lors d'une demande de course
```
SI rideType = 'delivery'
  ALORS vehicleCategory DOIT ÊTRE 'moto'
  
SI rideType = 'cargo'
  ALORS vehicleCategory DOIT ÊTRE 'car'
  ET vehicle.type DOIT ÊTRE 'cargo'
  
SI rideType = 'shared'
  ALORS carpoolInfo.isCarpool = true
  ET driver.preferences.carpoolSeats > 0
```

### Lors de l'activation covoiturage (chauffeur)
```
SI vehicleCategory = 'car'
  ET vehicleType IN ['standard', 'express', 'premium']
  ALORS
    1. Demander nb de places (1 à capacity)
    2. Activer mode covoiturage
    3. Chercher passagers compatibles
```

---

**Fait avec ❤️ au Sénégal 🇸🇳**

