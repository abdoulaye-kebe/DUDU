# 🚗🏍️ Système d'Abonnements DUDU - Chauffeurs vs Livreurs

## 📋 Vue d'ensemble

DUDU propose un système d'abonnements différencié selon le type de véhicule :
- **🚗 Chauffeurs voiture** : Accès à tous les forfaits
- **🏍️ Livreurs moto** : Forfait journalier uniquement + bonus hebdomadaires

---

## 🚗 Chauffeurs Voiture (Transport Passagers)

### ✅ Forfaits Disponibles

| Forfait | Prix | Durée | Économies | Fonctionnalités |
|---------|------|-------|-----------|-----------------|
| **Journalier** | 2,000 FCFA | 1 jour | - | Courses illimitées, Support 24/7, Statistiques de base |
| **Hebdomadaire** | 12,000 FCFA | 7 jours | 15% | + Support prioritaire, Statistiques avancées |
| **Mensuel** | 45,000 FCFA | 30 jours | 25% | + Formation gratuite |
| **Annuel** | 450,000 FCFA | 365 jours | 40% | + Assurance incluse |

### 🎯 Avantages
- **Flexibilité totale** : Choix du forfait selon les besoins
- **Économies importantes** : Jusqu'à 40% de réduction
- **Fonctionnalités avancées** : Statistiques, formation, assurance
- **Renouvellement automatique** possible

---

## 🏍️ Livreurs Moto (Livraisons Colis)

### ⚠️ Restrictions Spécifiques

| Aspect | Limitation | Raison |
|--------|------------|--------|
| **Forfaits** | Journalier uniquement | Optimisation des livraisons |
| **Courses/jour** | Maximum 20 | Sécurité et efficacité |
| **Bonus** | Hebdomadaire | Motivation et rétention |

### 💰 Système de Bonus Hebdomadaire

#### 🎯 Critères d'Éligibilité
- **Minimum 10 courses** par semaine
- **Minimum 5,000 FCFA** de revenus
- **Abonnement actif** au forfait journalier

#### 🏆 Types de Bonus

**1. Forfait Gratuit (24h)**
- **Condition** : 15+ courses/semaine
- **Avantage** : 24h gratuites
- **Description** : "Excellent travail cette semaine !"

**2. Bonus Financier**
- **Condition** : 10-14 courses/semaine
- **Montant** : 10% des revenus de la semaine
- **Paiement** : Virement Orange Money/Wave

#### 📊 Exemples de Bonus

```
Livreur A : 18 courses/semaine → 24h gratuites
Livreur B : 12 courses/semaine → 1,200 FCFA bonus
Livreur C : 8 courses/semaine → Aucun bonus
```

---

## 🔧 API Endpoints

### 📋 Obtenir les Plans Disponibles

```http
GET /api/v1/subscriptions/plans?vehicleType=car
GET /api/v1/subscriptions/plans?vehicleType=moto
```

**Réponse pour voiture :**
```json
{
  "success": true,
  "data": {
    "vehicleType": "car",
    "plans": [
      {
        "type": "daily",
        "name": "Forfait Journalier",
        "price": 2000,
        "currency": "XOF",
        "duration": 1,
        "features": ["Courses illimitées", "Support 24/7"],
        "savings": {"amount": 0, "percentage": 0},
        "isAvailable": true
      },
      {
        "type": "weekly",
        "name": "Forfait Hebdomadaire",
        "price": 12000,
        "currency": "XOF",
        "duration": 7,
        "features": ["Courses illimitées", "Support prioritaire", "Statistiques avancées", "Réduction 15%"],
        "savings": {"amount": 2000, "percentage": 15},
        "isAvailable": true
      }
      // ... autres plans
    ],
    "restrictions": null
  }
}
```

**Réponse pour moto :**
```json
{
  "success": true,
  "data": {
    "vehicleType": "moto",
    "plans": [
      {
        "type": "daily",
        "name": "Forfait Journalier",
        "price": 2000,
        "currency": "XOF",
        "duration": 1,
        "features": ["Courses illimitées", "Support 24/7"],
        "savings": {"amount": 0, "percentage": 0},
        "isAvailable": true
      }
    ],
    "restrictions": {
      "allowedPlans": ["daily"],
      "maxDailyRides": 20,
      "weeklyBonus": {
        "description": "Bonus hebdomadaire pour livreurs moto",
        "types": ["free_subscription", "cash_bonus"],
        "freeSubscription": "24h gratuites",
        "cashBonus": "Virement Orange Money/Wave"
      }
    }
  }
}
```

### 🛒 Achat d'Abonnement

```http
POST /api/v1/subscriptions/purchase
```

**Body pour voiture :**
```json
{
  "planType": "monthly",
  "paymentMethod": "orange_money",
  "phone": "+221771234567",
  "autoRenew": true
}
```

**Body pour moto :**
```json
{
  "planType": "daily",
  "paymentMethod": "wave",
  "phone": "+221771234567",
  "autoRenew": false
}
```

**Erreur si moto essaie d'acheter autre chose que journalier :**
```json
{
  "success": false,
  "message": "Les livreurs moto ne peuvent souscrire qu'au forfait journalier",
  "data": {
    "allowedPlans": ["daily"],
    "vehicleType": "moto",
    "weeklyBonus": {
      "description": "Bonus hebdomadaire disponible",
      "types": ["free_subscription", "cash_bonus"]
    }
  }
}
```

### 🎁 Gestion des Bonus (Admin)

#### 📊 Livreurs Éligibles
```http
GET /api/v1/subscriptions/moto/weekly-bonus-eligible?minRides=10&minEarnings=5000
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "eligibleDrivers": [
      {
        "driverId": "driver_123",
        "subscription": {
          "id": "sub_456",
          "plan": {"type": "daily", "name": "Forfait Journalier"},
          "vehicleType": "moto",
          "status": "active"
        },
        "weeklyStats": {
          "rides": 18,
          "earnings": 12000
        },
        "bonusRecommendation": {
          "type": "free_subscription",
          "amount": 0,
          "description": "24h gratuites pour excellentes performances"
        }
      }
    ],
    "criteria": {
      "minRides": 10,
      "minEarnings": 5000,
      "period": "7 derniers jours"
    }
  }
}
```

#### ➕ Ajouter un Bonus
```http
POST /api/v1/subscriptions/:id/bonus
```

**Body :**
```json
{
  "type": "free_subscription",
  "amount": 0,
  "description": "Excellent travail cette semaine ! 24h gratuites offertes."
}
```

**ou**

```json
{
  "type": "cash_bonus",
  "amount": 1500,
  "description": "Bonus de performance - 10% de vos revenus"
}
```

#### 📈 Historique des Bonus
```http
GET /api/v1/subscriptions/:id/bonus-history
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": "sub_456",
      "vehicleType": "moto",
      "status": "active"
    },
    "bonusHistory": [
      {
        "type": "free_subscription",
        "amount": 0,
        "date": "2025-10-05T10:00:00Z",
        "description": "24h gratuites - Semaine excellente"
      },
      {
        "type": "cash_bonus",
        "amount": 1200,
        "date": "2025-09-28T10:00:00Z",
        "description": "Bonus performance - 10% revenus"
      }
    ],
    "totalBonusEarned": 1200,
    "lastBonusDate": "2025-10-05T10:00:00Z"
  }
}
```

---

## 🎯 Logique Métier

### 🚗 Chauffeurs Voiture
- **Flexibilité maximale** : Tous les forfaits disponibles
- **Économies importantes** : Jusqu'à 40% sur l'annuel
- **Fonctionnalités avancées** : Statistiques, formation, assurance
- **Pas de bonus** : Système de forfaits suffisant

### 🏍️ Livreurs Moto
- **Forfait journalier uniquement** : Optimisation des livraisons
- **Limite de 20 courses/jour** : Sécurité et efficacité
- **Bonus hebdomadaires** : Motivation et rétention
- **Système de récompense** : Performance récompensée

---

## 💡 Avantages du Système

### Pour DUDU
- **Optimisation des ressources** : Forfaits adaptés aux besoins
- **Rétention des livreurs** : Bonus hebdomadaires motivants
- **Flexibilité pour chauffeurs** : Choix selon les besoins
- **Contrôle des coûts** : Limites pour moto, forfaits pour voiture

### Pour les Chauffeurs
- **Économies importantes** : Jusqu'à 40% de réduction
- **Fonctionnalités avancées** : Statistiques, formation, assurance
- **Flexibilité** : Choix du forfait selon l'usage

### Pour les Livreurs
- **Bonus hebdomadaires** : Récompense de la performance
- **Forfait journalier** : Pas d'engagement long terme
- **Motivation** : Système de récompense clair

---

## 🔄 Workflow Hebdomadaire

### Lundi - Calcul des Bonus
1. **Analyse des performances** (courses + revenus)
2. **Identification des éligibles** (critères respectés)
3. **Calcul des bonus** (gratuit vs financier)
4. **Notification des livreurs** (SMS/App)

### Mardi - Distribution des Bonus
1. **Forfaits gratuits** : Activation automatique
2. **Virements** : Orange Money/Wave
3. **Suivi des distributions** : Confirmation
4. **Historique** : Enregistrement des bonus

---

## 📊 Métriques de Succès

### Chauffeurs Voiture
- **Taux d'achat** : Forfaits mensuels/annuels
- **Rétention** : Renouvellement automatique
- **Satisfaction** : Fonctionnalités avancées

### Livreurs Moto
- **Performance** : Nombre de courses/semaine
- **Rétention** : Taux de renouvellement journalier
- **Satisfaction** : Bonus reçus

---

## 🚀 Implémentation

### Backend
- ✅ **Modèle Subscription** mis à jour
- ✅ **Routes API** avec restrictions
- ✅ **Système de bonus** intégré
- ✅ **Validation** selon type de véhicule

### Frontend
- 🔄 **Interface différenciée** selon véhicule
- 🔄 **Affichage des restrictions** pour moto
- 🔄 **Historique des bonus** pour livreurs
- 🔄 **Notifications** de bonus hebdomadaires

---

**DUDU - Système d'abonnements intelligent et équitable ! 🚗🏍️💰**
