# 🔐 Identifiants de Test - DUDU

## 📱 Application Client (dudu_flutter)

### Comptes Clients
| Type | Téléphone | Mot de passe | Nom | Description |
|------|-----------|--------------|-----|-------------|
| **Client 1** | `221771234567` | `client123` | Client Test | Compte client principal |
| **Client 2** | `221771234568` | `client456` | Marie Diop | Compte client secondaire |

## 🚗 Application Chauffeur (mobile_dudu_pro)

### Comptes Chauffeurs
| Type | Téléphone | Mot de passe | Nom | Véhicule | Description |
|------|-----------|--------------|-----|----------|-------------|
| **Chauffeur Voiture** | `221771234567` | `chauffeur123` | Test User | Toyota Corolla | Chauffeur voiture standard |
| **Livreur Moto** | `221771234568` | `livreur123` | Test User | Moto | Livreur moto pour livraisons |

## 🎯 Fonctionnalités Testées

### Application Client
- ✅ **Connexion** : Utiliser les identifiants client
- ✅ **Carte Interactive** : Carte du Sénégal avec autocomplétion
- ✅ **Demande de Course** : Sélection départ/destination
- ✅ **Types de Course** : Standard, Express, Premium, Partagé, Femmes, Livraison
- ✅ **Calcul de Prix** : Estimation automatique basée sur la distance
- ✅ **Géolocalisation** : Position actuelle automatique

### Application Chauffeur
- ✅ **Connexion** : Utiliser les identifiants chauffeur
- ✅ **Dashboard** : Carte du Sénégal avec marqueurs des villes
- ✅ **Statut En ligne/Hors ligne** : Toggle pour accepter les courses
- ✅ **Gestion des Courses** : Voir et accepter les demandes
- ✅ **Abonnements** : 
  - **Chauffeurs voiture** : Journalier, Hebdomadaire, Mensuel
  - **Livreurs moto** : Journalier uniquement + bonus hebdomadaires
- ✅ **Statistiques** : Courses, gains, évaluations
- ✅ **Paramètres** : Profil, préférences, déconnexion

## 🗺️ Carte Interactive - Villes du Sénégal

### Villes Principales Disponibles
- **Dakar** : Place de l'Indépendance, Aéroport, Université, Marché Sandaga
- **Thiès** : Centre-ville, Gare
- **Kaolack** : Marché central, Gare routière
- **Ziguinchor** : Centre-ville, Port
- **Saint-Louis** : Centre historique, Gare
- **Diourbel** : Centre-ville
- **Louga** : Centre-ville
- **Tambacounda** : Centre-ville
- **Kolda** : Centre-ville
- **Fatick** : Centre-ville

### Lieux d'Intérêt
- **Aéroport Léopold Sédar Senghor** (Dakar)
- **Place de l'Indépendance** (Dakar)
- **Université Cheikh Anta Diop** (Dakar)
- **Marché Sandaga** (Dakar)
- **Gare de Dakar**
- **Port de Dakar**

## 🚀 Guide de Test Rapide

### 1. Tester l'Application Client
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/dudu_flutter
flutter run -d "iPhone 16 Pro"
```
- Se connecter avec : `221771234567` / `client123`
- Tester la carte interactive
- Demander une course avec autocomplétion

### 2. Tester l'Application Chauffeur
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro
flutter run -d "iPhone 16 Pro"
```
- Se connecter avec : `221771234567` / `chauffeur123`
- Vérifier la carte du Sénégal
- Tester les abonnements
- Gérer les courses

### 3. Tester le Backend
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/backend
npm start
```
- Vérifier : http://localhost:8000/api/health
- API disponible sur : http://localhost:8000/api/v1

## 🔧 Fonctionnalités Avancées

### Autocomplétion Intelligente
- **Recherche par ville** : "Dakar", "Thiès", "Kaolack"
- **Recherche par région** : "Dakar", "Thiès", "Kaolack"
- **Lieux d'intérêt** : "Aéroport", "Université", "Marché"
- **Recherche partielle** : "Dak" → "Dakar"

### Calcul de Prix Dynamique
- **Prix de base** : 1000 FCFA
- **Prix par km** : 500 FCFA
- **Prix temps** : 300 FCFA
- **Multiplicateurs** :
  - Standard : 1.0x
  - Express : 1.5x
  - Premium : 2.0x
  - Partagé : 0.7x
  - Femmes : 1.2x
  - Livraison : 1.3x

### Géolocalisation
- **Position actuelle** : Détection automatique
- **Limites Sénégal** : Vérification des coordonnées
- **Distance calculée** : Formule de Haversine
- **Temps estimé** : 2 minutes par km

## 📊 Statistiques de Test

### Chauffeur Test
- **Courses totales** : 100
- **Courses terminées** : 95
- **Courses annulées** : 5
- **Note moyenne** : 4.8/5
- **Gains totaux** : 500,000 FCFA
- **Distance totale** : 5,000 km

### Livreur Moto Test
- **Abonnement** : Journalier uniquement
- **Bonus hebdomadaires** : Disponibles
- **Livraisons** : Activées
- **Restrictions** : Forfait journalier seulement

## 🎨 Interface Utilisateur

### Thème DUDU
- **Couleur principale** : Vert (#00A651)
- **Couleur secondaire** : Bleu
- **Police** : Roboto
- **Icônes** : Material Design

### Navigation
- **Client** : Carte → Demande → Suivi
- **Chauffeur** : Dashboard → Courses → Statistiques
- **Admin** : Dashboard → Gestion → Rapports

## 🔄 Flux de Test Complet

1. **Connexion Client** → Carte interactive
2. **Sélection départ/destination** → Autocomplétion
3. **Calcul prix** → Estimation automatique
4. **Demande course** → Envoi au système
5. **Connexion Chauffeur** → Dashboard
6. **Acceptation course** → Suivi en temps réel
7. **Finalisation** → Paiement et évaluation

## 📱 Compatibilité

- **iOS** : iPhone 16 Pro (Simulateur)
- **Android** : Support complet
- **Web** : Interface responsive
- **Backend** : Node.js + MongoDB + Socket.io

## 🚨 Notes Importantes

- **Backend requis** : Démarrer avec `npm start`
- **Simulateur** : iPhone 16 Pro recommandé
- **Géolocalisation** : Autoriser l'accès
- **Réseau** : Connexion internet requise
- **Données** : Simulation en mode test















