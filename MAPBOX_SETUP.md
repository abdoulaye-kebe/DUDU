# 🗺️ Configuration Mapbox pour DUDU

## 📝 Étapes pour obtenir votre clé API Mapbox (GRATUIT)

### 1. Créer un compte Mapbox
1. Aller sur : https://account.mapbox.com/auth/signup/
2. S'inscrire avec votre email
3. Confirmer votre email

### 2. Obtenir votre clé API (Access Token)
1. Une fois connecté, aller sur : https://account.mapbox.com/access-tokens/
2. Copier votre **Default public token** (commence par `pk.`)
3. Exemple : `pk.eyJ1IjoiZHVkdS1zZW5lZ2FsIiwiYSI6ImNsc2V4Z2V4Z2V4Z2V4In0.xxxxx`

### 3. Ajouter la clé dans le code
Ouvrir le fichier : `dudu_flutter/lib/services/mapbox_service.dart`

Remplacer la ligne 6 :
```dart
static const String _accessToken = 'pk.eyJ1IjoiZHVkdS1zZW5lZ2FsIiwiYSI6ImNsc2V4Z2V4Z2V4Z2V4In0.VOTRE_CLE_ICI';
```

Par :
```dart
static const String _accessToken = 'VOTRE_VRAIE_CLE_MAPBOX_ICI';
```

## 💰 Quota Gratuit Mapbox

- ✅ **100,000 requêtes/mois GRATUITES**
- ✅ Pas de carte bancaire requise pour commencer
- ✅ Largement suffisant pour démarrer DUDU

## 🚀 Avantages de Mapbox

1. **Ultra-rapide** : Autocomplétion < 100ms (comme Yango/Bolt)
2. **Excellent pour l'Afrique** : Données OpenStreetMap complètes
3. **Gratuit** : 100K requêtes/mois
4. **Offline** : Possibilité de cartes hors ligne
5. **Utilisé par** : Uber, Snapchat, Instacart

## 📊 Comparaison avec Google Maps

| Fonctionnalité | Google Maps | Mapbox |
|----------------|-------------|--------|
| Vitesse autocomplétion | ~300ms | ~100ms ⚡ |
| Quota gratuit | Limité + Facturation requise | 100K/mois |
| Prix après quota | $17/1000 | $0.50/1000 💰 |
| Données Afrique | Bon | Excellent ✅ |
| Offline maps | Non | Oui ✅ |

## ⚠️ Important

Après avoir ajouté votre clé Mapbox :
1. Sauvegarder le fichier `mapbox_service.dart`
2. Relancer l'application
3. Tester l'autocomplétion (elle sera ultra-rapide !)

## 🔒 Sécurité

- La clé publique (`pk.`) peut être utilisée côté client
- Pour la production, créer une clé avec restrictions d'URL
- Ne jamais partager votre clé secrète (`sk.`)
