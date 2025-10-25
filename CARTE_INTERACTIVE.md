# 🗺️ Carte Interactive Google Maps DUDU

## 📋 Vue d'ensemble

Une carte Google Maps interactive complète avec des fonctionnalités avancées pour la plateforme DUDU de transport et livraison.

## 🎯 Fonctionnalités

### 1. **Affichage de la carte**
- ✅ Carte Google Maps intégrée
- ✅ Mode normal et satellite
- ✅ Affichage du trafic routier
- ✅ Géolocalisation automatique
- ✅ Carte centrée sur le Sénégal (villes principales)

### 2. **Géolocalisation**
- ✅ Position GPS en temps réel
- ✅ Marqueur de position actuelle (bleu)
- ✅ Cercle de rayon de recherche (2km)
- ✅ Centrage automatique sur la position
- ✅ Gestion des permissions de localisation

### 3. **Marqueurs interactifs**
- ✅ Marqueurs des villes principales du Sénégal :
  - 🟢 Dakar (capitale)
  - 🟠 Thiès, Kaolack, Ziguinchor, Saint-Louis
- ✅ Marqueur de destination (rouge)
- ✅ Marqueurs temporaires (violet)
- ✅ InfoWindow avec informations au clic
- ✅ Placement de marqueurs par long press

### 4. **Navigation et itinéraires**
- ✅ Calcul d'itinéraire entre deux points
- ✅ Traçage de routes (lignes bleues pointillées)
- ✅ Distance et temps estimé
- ✅ Calcul de distance entre points
- ✅ Définir une destination

### 5. **Contrôles UI**
- ✅ Boutons zoom + / -
- ✅ Basculer entre modes (normal/satellite)
- ✅ Activer/désactiver l'affichage du trafic
- ✅ Bouton "Ma position" (recentrer)
- ✅ Bouton "Effacer" les marqueurs temporaires
- ✅ Card d'information de localisation sélectionnée

### 6. **Interactions utilisateur**
- ✅ Tap sur un marqueur → Affiche infos détaillées
- ✅ Long press sur carte → Ajoute marqueur
- ✅ Tap sur marqueur → Affiche modal avec actions :
  - Définir destination
  - Obtenir itinéraire
- ✅ Swipe/zoom pour naviguer sur la carte

## 📱 Interface utilisateur

### Boutons de contrôle (en bas)
```
[Type de carte] [Trafic] [Ma position] [Effacer]
```

### Boutons de zoom (en haut à droite)
```
[+]
[-]
```

### Card d'information
- Affiche la localisation sélectionnée
- Disparaît quand aucune location n'est sélectionnée

## 🔧 Configuration

### Fichier : `lib/screens/interactive_map_screen.dart`

### Dépendances requises
```yaml
dependencies:
  google_maps_flutter: ^2.13.1
  geolocator: ^14.0.2
```

### Permissions Android
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Clé API Google Maps
Configurée dans `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA" />
```

## 🚀 Utilisation

### Accéder à la carte interactive

1. **Depuis l'écran d'accueil** :
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const InteractiveMapScreen(),
  ),
);
```

2. **Ou utilisez le bouton dédié** dans l'application

### Utiliser les fonctionnalités

#### Définir une destination
1. Cliquez sur un marqueur de ville
2. Sélectionnez "Définir destination"
3. Un marqueur rouge apparaît sur la carte
4. Une ligne trace l'itinéraire depuis votre position

#### Obtenir un itinéraire
1. Cliquez sur un marqueur
2. Sélectionnez "Itinéraire"
3. Une dialog affiche :
   - Distance en km
   - Temps estimé en minutes
4. L'itinéraire est tracé sur la carte

#### Ajouter un marqueur personnalisé
1. Faites un long press sur la carte
2. Un marqueur violet apparaît
3. Cliquez sur "Effacer" pour les supprimer

#### Changer le type de carte
1. Cliquez sur le bouton "Type"
2. Bascule entre mode normal et satellite

#### Activer l'affichage du trafic
1. Cliquez sur le bouton "Trafic"
2. Les conditions de circulation s'affichent

## 🌍 Villes affichées

| Ville | Coordonnées | Type |
|-------|-------------|------|
| Dakar | 14.6928, -17.4467 | Capitale |
| Thiès | 14.7896, -16.9260 | Ville |
| Kaolack | 14.1510, -16.0755 | Ville |
| Ziguinchor | 12.5641, -16.2630 | Ville |
| Saint-Louis | 16.0179, -16.4896 | Ville |

## 🎨 Couleurs et design

### Couleurs principales
- Vert DUDU : `#00A651`
- Bleu position actuelle : `BitmapDescriptor.hueBlue`
- Rouge destination : `BitmapDescriptor.hueRed`
- Violet marqueur temporel : `BitmapDescriptor.hueViolet`

### Styles de polylines
- Couleur : Bleu
- Largeur : 5
- Pattern : Tirets avec espacements

## 🔮 Fonctionnalités à venir

- [ ] Intégration Google Directions API pour des itinéraires précis
- [ ] Recherche d'adresses avec autocomplétion
- [ ] Affichage des chauffeurs disponibles sur la carte
- [ ] Mode navigation GPS
- [ ] Historique des trajets
- [ ] Favoris (adresses fréquentes)
- [ ] Partage d'emplacement
- [ ] Offline maps

## 🐛 Dépannage

### La carte ne s'affiche pas
1. Vérifiez que la clé API Google Maps est valide
2. Assurez-vous que l'API est activée dans Google Cloud Console
3. Vérifiez les permissions de localisation

### La géolocalisation ne fonctionne pas
1. Autorisez les permissions de localisation
2. Activez le GPS sur votre appareil
3. Vérifiez votre connexion Internet

### Les marqueurs n'apparaissent pas
1. Vérifiez que le zoom est suffisant (zoom > 10)
2. Videz le cache de l'application
3. Redémarrez l'application

## 📞 Support

Pour toute question ou problème, consultez :
- [Documentation Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Documentation Geolocator](https://pub.dev/packages/geolocator)

## 📝 Notes

- La carte est optimisée pour le Sénégal
- Les distances sont calculées en mètres puis converties en km
- Le temps estimé utilise une vitesse moyenne de 30 km/h
- Les marqueurs temporaires sont automatiquement supprimés au clic sur "Effacer"

---

**Développé pour DUDU - Plateforme de Transport et Livraison** 🚗📦



