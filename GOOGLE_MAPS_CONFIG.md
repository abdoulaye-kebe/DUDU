# Configuration Google Maps pour DUDU

## Obtenir une clé API Google Maps

1. **Accédez à Google Cloud Console**
   - Allez sur [https://console.cloud.google.com/](https://console.cloud.google.com/)
   - Connectez-vous avec votre compte Google

2. **Créez un nouveau projet** (ou sélectionnez-en un existant)
   - Cliquez sur le menu déroulant du projet en haut
   - Cliquez sur "Nouveau projet"
   - Nommez-le "DUDU" et créez-le

3. **Activez les APIs nécessaires**
   - Allez dans "APIs & Services" > "Bibliothèque"
   - Recherchez et activez les APIs suivantes :
     - **Maps SDK for Android**
     - **Maps SDK for iOS**
     - **Maps JavaScript API**
     - **Geocoding API**
     - **Directions API**
     - **Distance Matrix API**
     - **Places API**

4. **Créez des identifiants (API Key)**
   - Allez dans "APIs & Services" > "Identifiants"
   - Cliquez sur "Créer des identifiants" > "Clé API"
   - Copiez la clé générée

5. **Sécurisez votre clé** (Recommandé)
   - Cliquez sur la clé créée pour la modifier
   - Sous "Restrictions relatives aux applications" :
     - Pour Android : Ajoutez votre package name `sn.dudu.client`
     - Pour iOS : Ajoutez votre bundle ID `sn.dudu.client`
   - Sous "Restrictions relatives aux API" :
     - Sélectionnez "Restreindre la clé"
     - Sélectionnez toutes les APIs activées ci-dessus

## Configuration dans le projet

### 1. Application Mobile (React Native/Expo)

Modifiez le fichier `mobile-dudu/DUDU/app.json` :

```json
{
  "expo": {
    "ios": {
      "config": {
        "googleMapsApiKey": "VOTRE_CLE_API_ICI"
      }
    },
    "android": {
      "config": {
        "googleMaps": {
          "apiKey": "VOTRE_CLE_API_ICI"
        }
      }
    }
  }
}
```

### 2. Backend (Node.js)

Ajoutez dans le fichier `backend/.env` :

```env
GOOGLE_MAPS_API_KEY=VOTRE_CLE_API_ICI
```

## Fonctionnalités implémentées

### 📍 **Google Maps**
- ✅ Carte interactive avec marqueurs
- ✅ Géolocalisation en temps réel
- ✅ Calcul d'itinéraire
- ✅ Géocodage inverse (coordonnées → adresse)
- ✅ Calcul de distance entre deux points
- ✅ Estimation du prix de la course

### 🚗 **Covoiturage**
- ✅ Activation/Désactivation du mode covoiturage
- ✅ Recherche de courses compatibles
- ✅ Acceptation de courses partagées
- ✅ Réduction automatique du prix (30%)
- ✅ Gestion de la capacité du véhicule
- ✅ Interface chauffeur avec switch covoiturage

## Nouveaux écrans créés

1. **MapRideScreen.tsx** - Écran de demande de course avec carte Google Maps
2. **DriverHomeScreen.tsx** - Tableau de bord chauffeur avec option covoiturage

## Nouvelles routes API

### Covoiturage
- `PUT /api/v1/drivers/preferences` - Mettre à jour les préférences (incluant covoiturage)
- `PUT /api/v1/drivers/carpool/toggle` - Activer/Désactiver le covoiturage
- `GET /api/v1/drivers/carpool/compatible-rides` - Trouver des courses compatibles
- `POST /api/v1/drivers/carpool/accept` - Accepter une course partagée

### Localisation
- `PUT /api/v1/drivers/location` - Mettre à jour la position du chauffeur
- `PUT /api/v1/drivers/status` - Mettre à jour le statut (online/offline)

## Test de l'intégration

### 1. Tester la carte
```bash
cd mobile-dudu/DUDU
npm start
# Puis appuyez sur 'w' pour ouvrir dans le navigateur
```

### 2. Tester le backend
```bash
cd backend
npm start
```

### 3. Tester le mode covoiturage

**Activer le covoiturage (Chauffeur) :**
```bash
curl -X PUT http://localhost:8000/api/v1/drivers/carpool/toggle \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -d '{"enabled": true}'
```

**Trouver des courses compatibles :**
```bash
curl -X GET "http://localhost:8000/api/v1/drivers/carpool/compatible-rides?currentRideId=ID_COURSE" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

**Accepter une course partagée :**
```bash
curl -X POST http://localhost:8000/api/v1/drivers/carpool/accept \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -d '{
    "currentRideId": "ID_COURSE_ACTUELLE",
    "newRideId": "ID_NOUVELLE_COURSE"
  }'
```

## Limitations et tarification Google Maps

⚠️ **Attention aux coûts** :
- Google Maps offre **$200 de crédit gratuit par mois**
- Au-delà, chaque requête est facturée
- Pour un usage production, configurez des quotas et des alertes de facturation

## Prochaines étapes

1. Remplacez `YOUR_GOOGLE_MAPS_API_KEY_HERE` par votre vraie clé API
2. Testez l'application
3. Ajoutez plus de fonctionnalités :
   - Suivi en temps réel du chauffeur
   - Notifications push pour les courses
   - Historique des trajets
   - Évaluations et commentaires

## Support

Pour toute question, consultez la documentation officielle :
- [Google Maps Platform](https://developers.google.com/maps)
- [React Native Maps](https://github.com/react-native-maps/react-native-maps)
- [Expo Location](https://docs.expo.dev/versions/latest/sdk/location/)

