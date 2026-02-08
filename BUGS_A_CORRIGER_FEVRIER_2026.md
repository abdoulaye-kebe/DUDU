# 🐛 BUGS À CORRIGER - APPLICATION CLIENT DUDU
**Date:** 8 Février 2026

## 📋 Liste des Bugs Identifiés

### 1. ❌ Autocomplétion des Adresses
**Problème:** Lors de la saisie de la destination, aucune suggestion n'apparaît
**Cause possible:** 
- Widget d'autocomplétion non appelé correctement
- Délai de debounce trop long
- Problème avec Google Places API

**Fichiers concernés:**
- `lib/widgets/address_autocomplete.dart`
- `lib/services/places_service.dart`
- `lib/screens/unified_ride_screen.dart`

**Solution:**
- Vérifier que le widget d'autocomplétion est bien utilisé
- Réduire le délai de debounce à 300ms
- Ajouter des logs pour déboguer

---

### 2. ❌ Chargement Lent de la Carte Google Maps
**Problème:** La carte Google Maps met du temps à charger
**Cause possible:**
- Pas de cache des tuiles de carte
- Chargement de trop d'éléments en même temps
- Initialisation lourde

**Fichiers concernés:**
- `lib/screens/unified_ride_screen.dart`
- `lib/screens/yango_style_map_screen.dart`

**Solution:**
- Activer le cache des tuiles
- Lazy loading des markers
- Optimiser l'initialisation de la carte

---

### 3. ❌ Icône Trajets Planifiés
**Problème:** L'icône affichée est une moto au lieu d'une voiture
**Fichiers concernés:**
- `lib/screens/scheduled_rides_screen.dart`
- `assets/images/vehicles/`

**Solution:**
- Utiliser `assets/images/vehicles/standard.png` au lieu de `moto.png`

---

### 4. ❌ Bouton Continuer Grisé
**Problème:** Après saisie du prix, le bouton "Continuer" reste grisé
**Cause possible:**
- Validation du formulaire trop stricte
- État non mis à jour après saisie du prix

**Fichiers concernés:**
- `lib/screens/unified_ride_screen.dart`
- `lib/screens/indriver_style_screen.dart`

**Solution:**
- Vérifier la logique de validation
- Appeler `setState()` après modification du prix

---

### 5. ❌ Moyen de Paiement Figé
**Problème:** Le moyen de paiement est figé sur Orange Money avec un numéro différent du téléphone de l'utilisateur
**Fichiers concernés:**
- `lib/screens/payment_method_screen.dart`
- `lib/screens/profile_screen.dart`

**Solution:**
- Permettre la sélection du moyen de paiement
- Utiliser le numéro de téléphone de l'utilisateur par défaut
- Permettre la modification du numéro

---

### 6. ❌ Icônes Orange Money et Wave Non Utilisées
**Problème:** Les icônes téléchargées pour OM et Wave ne sont pas affichées
**Fichiers concernés:**
- `assets/images/payments/`
- `lib/screens/payment_method_screen.dart`
- `lib/screens/mobile_payment_screen.dart`

**Solution:**
- Utiliser les icônes PNG au lieu des icônes par défaut
- Ajouter les assets dans `pubspec.yaml`

---

### 7. ❌ Free Money à Supprimer
**Problème:** Free Money apparaît encore dans certains écrans
**Fichiers concernés:**
- `lib/screens/payment_method_screen.dart`
- Backend: `backend/src/routes/payments.js`

**Solution:**
- Supprimer toutes les références à Free Money
- Garder uniquement Orange Money et Wave

---

### 8. ⚠️ Fonctionnalités en Cours à Finaliser
**Problème:** Certaines fonctionnalités ne sont pas terminées
**Action requise:**
- Identifier toutes les fonctionnalités en cours
- Les finaliser ou les désactiver

---

## 🎯 Plan d'Action

1. **Priorité HAUTE** - Corriger l'autocomplétion des adresses
2. **Priorité HAUTE** - Corriger le bouton Continuer grisé
3. **Priorité MOYENNE** - Corriger l'icône des trajets planifiés
4. **Priorité MOYENNE** - Corriger le moyen de paiement figé
5. **Priorité MOYENNE** - Utiliser les icônes OM et Wave
6. **Priorité BASSE** - Supprimer Free Money
7. **Priorité BASSE** - Optimiser le chargement de la carte
8. **Priorité BASSE** - Finaliser les fonctionnalités en cours

---

## 📝 Notes
- Tester chaque correction avant de passer à la suivante
- Rebuilder les APK après chaque série de corrections
- Déployer sur le serveur de production après validation
