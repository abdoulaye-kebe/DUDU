# 🧪 Guide de Test DUDU

## 🎯 Applications à tester

1. **DUDU Client** (dudu_flutter) - Application passagers
2. **DUDU Pro** (mobile_dudu_pro) - Application chauffeurs
3. **Backend** - API Node.js

---

## ✅ Prérequis

### Backend qui tourne:
```bash
cd backend
npm start
# Doit afficher: 🚀 Serveur DUDU démarré sur le port 8000
```

### MongoDB actif:
Le backend doit être connecté à MongoDB

---

## 📱 Test Application CLIENT (dudu_flutter)

### Lancer l'app:
```bash
cd dudu_flutter
flutter run -d <device_id>
```

### 🔐 Identifiants de test:
- **Téléphone**: `776543210` ou `+221776543210`
- **Mot de passe**: `test123456`

### 📋 Fonctionnalités à tester:

#### 1. Écran de Login
- [ ] Formulaire s'affiche correctement
- [ ] Validation du numéro de téléphone fonctionne
- [ ] Connexion avec les identifiants de test
- [ ] Navigation vers la carte après login réussi

#### 2. Écran Carte Google Maps
- [ ] Carte s'affiche correctement
- [ ] Position GPS automatiquement détectée
- [ ] Marqueur vert sur votre position
- [ ] Barre de recherche "Où allez-vous?" visible

#### 3. Recherche de destination
- [ ] Cliquer sur la barre de recherche
- [ ] Modal s'ouvre avec l'historique
- [ ] Sélectionner une destination de l'historique
- [ ] OU saisir une nouvelle destination

#### 4. Slider de prix personnalisable
- [ ] Modal de prix s'ouvre
- [ ] Slider fonctionne (500 - 50,000 FCFA)
- [ ] Prix sélectionné s'affiche en grand
- [ ] Prix suggéré basé sur l'historique
- [ ] Chips de prix rapides (Moyen, Économique, Généreux)

#### 5. Recherche de chauffeurs
- [ ] Bouton "Rechercher des chauffeurs"
- [ ] Écran d'attente s'affiche
- [ ] Compteur 3:00 minutes visible
- [ ] Barre de progression
- [ ] Informations du trajet affichées

#### 6. Choix du chauffeur
- [ ] Liste des chauffeurs qui acceptent
- [ ] Nom, note, distance, véhicule affichés
- [ ] Bouton "Choisir" fonctionne
- [ ] Sélection confirmée

---

## 🚕 Test Application CHAUFFEUR (mobile_dudu_pro)

### Lancer l'app:
```bash
cd mobile_dudu_pro
flutter run -d <device_id>
```

### 📋 Fonctionnalités à tester:

#### 1. Tableau de bord
- [ ] Carte Google Maps s'affiche
- [ ] Statut "Hors ligne" affiché
- [ ] Indicateur de forfait visible (jours restants)
- [ ] Statistiques du jour affichées

#### 2. Statut En ligne/Hors ligne
- [ ] Bouton toggle grand et visible
- [ ] Couleur change (gris → vert)
- [ ] État sauvegardé
- [ ] Demande de permission localisation

#### 3. Gestion des forfaits
- [ ] Menu drawer accessible
- [ ] Option "Gérer mon forfait"
- [ ] Modal des 4 forfaits s'affiche:
  - Journalier: 2,000 FCFA
  - Hebdomadaire: 12,000 FCFA (-14%)
  - Mensuel: 40,000 FCFA (-33%) ⭐
  - Annuel: 400,000 FCFA (-45%) 🏆
- [ ] Badges (POPULAIRE, MEILLEURE OFFRE)
- [ ] Options de paiement (Orange Money, Wave, Free Money)

#### 4. Notifications de course
- [ ] Notification apparaît quand client demande
- [ ] Informations complètes:
  - Nom du passager
  - Point de départ
  - Destination
  - Distance
  - Prix proposé
- [ ] Compteur 30 secondes
- [ ] Texte "100% pour vous, aucune commission"
- [ ] Boutons Accepter / Refuser

#### 5. Statistiques et revenus
- [ ] Gains du jour affichés
- [ ] Nombre de courses
- [ ] Note moyenne avec étoile
- [ ] Revenus hebdomadaires
- [ ] Revenus mensuels
- [ ] Historique accessible

---

## 🔧 Test Backend (API)

### Health Check:
```bash
curl http://localhost:8000/api/v1/health
# Devrait retourner: Route non trouvée (normal, pas de /health)
```

### Test Inscription:
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "phone": "777777777",
    "password": "test123456"
  }'
```

### Test Connexion:
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "776543210",
    "password": "test123456"
  }'
```

---

## 🗺️ Test Google Maps

### Vérifier la clé API:
1. Ouvrir dudu_flutter/android/app/src/main/AndroidManifest.xml
2. Chercher: `AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA`
3. Vérifier dans iOS: dudu_flutter/ios/Runner/Info.plist

### Test dans l'app:
- [ ] Carte s'affiche (pas d'écran gris)
- [ ] Carte centrée sur Dakar
- [ ] Zoom/dézoom fonctionne
- [ ] Déplacement de la carte fluide
- [ ] Marqueurs s'affichent correctement

---

## ⚠️ Problèmes courants

### Carte ne s'affiche pas:
- Vérifier la clé Google Maps
- Vérifier les APIs activées sur Google Cloud
- Vérifier la connexion Internet

### Backend ne répond pas:
```bash
# Vérifier que le backend tourne
lsof -i:8000

# Si rien, relancer:
cd backend
npm start
```

### Login échoue:
- Vérifier que le backend tourne
- Vérifier l'URL dans api_service.dart: `http://localhost:8000/api/v1`
- Créer un nouveau compte si nécessaire

### Simulateur iOS lent:
```bash
# Redémarrer le simulateur
killall Simulator
open -a Simulator
```

---

## 📊 Résultats attendus

### DUDU Client:
✅ Login réussi
✅ Carte Google Maps visible
✅ Géolocalisation active
✅ Prix personnalisable
✅ Recherche fonctionne

### DUDU Pro:
✅ Tableau de bord visible
✅ Toggle En ligne/Hors ligne
✅ Forfaits affichés
✅ Notifications fonctionnent

### Backend:
✅ Port 8000 actif
✅ MongoDB connecté
✅ APIs répondent
✅ Socket.IO prêt

---

## 🎉 Validation finale

Toutes les cases cochées = **Prêt pour production !** ✅

---

## 📞 Support

Si problème persistant:
1. Vérifier les logs dans le terminal
2. Consulter ARCHITECTURE.md
3. Consulter GOOGLE_MAPS_CONFIG.md

