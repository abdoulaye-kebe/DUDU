# 📱 Guide de Déploiement App Store - DUDU

## Applications à déployer
1. **DUDU** - Application client (dudu_flutter)
2. **DUDU Pro** - Application chauffeur (mobile_dudu_pro)

---

## ✅ ÉTAPE 1 : Prérequis

### Compte Apple Developer
- [ ] Compte Apple Developer actif (99$/an)
- [ ] Accès à [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Certificats de distribution iOS configurés
- [ ] Provisioning profiles créés

### Outils nécessaires
- [ ] Xcode 15+ installé
- [ ] Flutter SDK à jour
- [ ] CocoaPods installé
- [ ] Transporter (optionnel, pour upload)

---

## 📋 ÉTAPE 2 : Préparation des Apps

### 2.1 Mise à jour des informations de l'app

#### Pour DUDU Client (`dudu_flutter`)

**Bundle ID recommandé:** `sn.dudugroup.app` ou `sn.dudu.client`

**Fichiers à modifier:**

1. **ios/Runner.xcodeproj/project.pbxproj**
   - Ouvrir avec Xcode
   - Sélectionner le projet Runner
   - Dans "General" → "Identity"
   - Définir le Bundle Identifier: `sn.dudugroup.app`

2. **Info.plist** (déjà configuré ✅)
   - CFBundleDisplayName: "DUDU"
   - Permissions géolocalisation: ✅
   - Google Maps API Key: ✅

3. **pubspec.yaml** (déjà configuré ✅)
   - version: 1.0.0+1

#### Pour DUDU Pro (`mobile_dudu_pro`)

**Bundle ID recommandé:** `sn.dudugroup.pro` ou `sn.dudu.driver`

**Fichiers à modifier:**

1. **ios/Runner.xcodeproj/project.pbxproj**
   - Bundle Identifier: `sn.dudugroup.pro`

2. **Info.plist**
   - CFBundleDisplayName: "DUDU Pro"
   - Ajouter permissions géolocalisation en arrière-plan
   - Ajouter permissions notifications push

3. **pubspec.yaml** (déjà configuré ✅)
   - version: 1.0.0+1

---

## 🎨 ÉTAPE 3 : Assets et Icônes

### 3.1 Icône de l'application

**Tailles requises pour iOS:**
- 1024x1024px (App Store)
- 180x180px (iPhone)
- 167x167px (iPad Pro)
- 152x152px (iPad)
- 120x120px (iPhone)
- 87x87px (iPhone)
- 80x80px (iPad)
- 76x76px (iPad)
- 60x60px (iPhone)
- 58x58px (iPhone)
- 40x40px (iPad/iPhone)
- 29x29px (iPhone)
- 20x20px (iPad/iPhone)

**Commande pour générer les icônes:**
```bash
# Dans chaque projet
flutter pub run flutter_launcher_icons
```

### 3.2 Screenshots pour App Store

**Tailles requises:**
- iPhone 6.7" (1290 x 2796 px) - iPhone 14 Pro Max
- iPhone 6.5" (1242 x 2688 px) - iPhone XS Max
- iPhone 5.5" (1242 x 2208 px) - iPhone 8 Plus
- iPad Pro 12.9" (2048 x 2732 px)

**Screens à capturer:**
- Écran d'accueil
- Recherche de trajet / Demandes de courses
- Carte avec trajet
- Profil utilisateur
- Historique des courses

---

## 🔐 ÉTAPE 4 : Configuration des Certificats

### 4.1 Créer les certificats dans Apple Developer

1. Aller sur [developer.apple.com/account](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles
3. Créer un **App ID** pour chaque app:
   - DUDU Client: `sn.dudugroup.app`
   - DUDU Pro: `sn.dudugroup.pro`

4. Activer les capabilities:
   - [x] Push Notifications
   - [x] Background Modes (Location updates, Remote notifications)
   - [x] Maps
   - [x] Associated Domains (si deep linking)

5. Créer un **Distribution Certificate**
6. Créer des **Provisioning Profiles** (App Store Distribution)

### 4.2 Configuration dans Xcode

```bash
# Ouvrir le projet iOS
cd dudu_flutter/ios
open Runner.xcworkspace

# Répéter pour mobile_dudu_pro
cd ../../mobile_dudu_pro/ios
open Runner.xcworkspace
```

Dans Xcode:
1. Sélectionner le projet Runner
2. Signing & Capabilities
3. Cocher "Automatically manage signing"
4. Sélectionner votre Team
5. Vérifier que le Bundle ID est correct

---

## 🏗️ ÉTAPE 5 : Build de Production

### 5.1 Nettoyage et préparation

```bash
# Pour DUDU Client
cd /Users/abdoulayekebe/Desktop/DUDU/dudu_flutter
flutter clean
flutter pub get
cd ios
pod install
cd ..

# Pour DUDU Pro
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### 5.2 Build iOS Release

**Pour DUDU Client:**
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/dudu_flutter

# Build archive
flutter build ipa --release

# Le fichier .ipa sera dans: build/ios/ipa/
```

**Pour DUDU Pro:**
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro

# Build archive
flutter build ipa --release

# Le fichier .ipa sera dans: build/ios/ipa/
```

### 5.3 Build via Xcode (Alternative)

```bash
# Ouvrir dans Xcode
cd dudu_flutter/ios
open Runner.xcworkspace
```

Dans Xcode:
1. Product → Scheme → Runner
2. Product → Destination → Any iOS Device (arm64)
3. Product → Archive
4. Attendre la fin du build
5. Window → Organizer
6. Sélectionner l'archive
7. Distribute App → App Store Connect

---

## 📤 ÉTAPE 6 : Upload vers App Store Connect

### 6.1 Créer les apps dans App Store Connect

1. Aller sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → + → New App

**Pour DUDU Client:**
- Platform: iOS
- Name: DUDU
- Primary Language: French
- Bundle ID: sn.dudugroup.app
- SKU: DUDU-CLIENT-001

**Pour DUDU Pro:**
- Platform: iOS
- Name: DUDU Pro
- Primary Language: French
- Bundle ID: sn.dudugroup.pro
- SKU: DUDU-PRO-001

### 6.2 Upload du build

**Méthode 1: Via Xcode Organizer**
1. Window → Organizer
2. Sélectionner l'archive
3. Distribute App
4. App Store Connect
5. Upload
6. Suivre les étapes

**Méthode 2: Via Transporter**
1. Télécharger Transporter depuis Mac App Store
2. Ouvrir Transporter
3. Se connecter avec Apple ID
4. Glisser-déposer le fichier .ipa
5. Deliver

**Méthode 3: Via ligne de commande**
```bash
xcrun altool --upload-app -f build/ios/ipa/dudu_flutter.ipa \
  -t ios -u votre@email.com -p "mot-de-passe-app-specific"
```

---

## 📝 ÉTAPE 7 : Remplir les informations App Store

### 7.1 Informations de l'app DUDU Client

**Nom:** DUDU

**Sous-titre:** Transport rapide et sécurisé au Sénégal

**Description:**
```
DUDU est votre solution de transport moderne au Sénégal. Réservez une course en quelques secondes et profitez d'un trajet confortable avec des chauffeurs vérifiés.

🚗 FONCTIONNALITÉS PRINCIPALES :
• Réservation instantanée de courses
• Courses planifiées à l'avance
• Plusieurs types de véhicules (Standard, Confort, Luxe, Moto)
• Courses femmes uniquement avec chauffeuses
• Service de livraison rapide
• Paiement mobile (Orange Money, Wave, Free Money)
• Suivi en temps réel de votre chauffeur
• Historique complet de vos trajets
• Évaluation des chauffeurs

🔒 SÉCURITÉ :
• Chauffeurs vérifiés et formés
• Partage de trajet en temps réel
• Support client 24/7
• Assurance incluse

💰 TARIFS TRANSPARENTS :
• Prix libre : proposez votre tarif
• Estimation avant réservation
• Pas de frais cachés

Téléchargez DUDU maintenant et profitez d'un transport fiable au Sénégal !
```

**Mots-clés:**
```
transport,taxi,vtc,sénégal,dakar,course,chauffeur,livraison,moto,covoiturage
```

**Catégories:**
- Principale: Voyages
- Secondaire: Navigation

**URL de support:** https://www.dudugroup.sn/support
**URL marketing:** https://www.dudugroup.sn
**URL politique de confidentialité:** https://www.dudugroup.sn/privacy

### 7.2 Informations de l'app DUDU Pro

**Nom:** DUDU Pro

**Sous-titre:** Application pour chauffeurs DUDU

**Description:**
```
DUDU Pro est l'application dédiée aux chauffeurs partenaires du réseau DUDU. Gagnez de l'argent en conduisant selon votre propre emploi du temps.

👨‍✈️ POUR LES CHAUFFEURS :
• Acceptez ou refusez les courses
• Gérez vos disponibilités
• Courses planifiées avec rappels automatiques
• Plusieurs types de courses (Standard, Confort, Luxe, Livraison)
• Tableau de bord avec statistiques
• Historique détaillé des gains
• Gestion d'abonnement

💼 GESTION PROFESSIONNELLE :
• Suivi des revenus quotidiens
• Statistiques de performance
• Évaluations clients
• Support dédié aux chauffeurs

📱 FONCTIONNALITÉS :
• Notifications en temps réel
• Navigation intégrée
• Appels directs aux clients
• Mode femme uniquement
• Gestion multi-livraisons

Rejoignez le réseau DUDU et commencez à gagner dès aujourd'hui !
```

**Mots-clés:**
```
chauffeur,driver,vtc,taxi,livraison,sénégal,dakar,pro,professionnel,gains
```

**Catégories:**
- Principale: Économie et entreprise
- Secondaire: Voyages

---

## 🎬 ÉTAPE 8 : Préparation des Screenshots

### Commandes pour capturer les screenshots

```bash
# Lancer l'app sur différents simulateurs
flutter run -d "iPhone 14 Pro Max"
flutter run -d "iPhone 8 Plus"
flutter run -d "iPad Pro (12.9-inch)"

# Capturer avec Cmd+S dans le simulateur
# Ou utiliser xcrun simctl io booted screenshot screenshot.png
```

### Screens recommandés pour DUDU Client:
1. Écran d'accueil avec carte
2. Sélection de destination
3. Choix du type de course
4. Suivi du chauffeur en temps réel
5. Historique des courses

### Screens recommandés pour DUDU Pro:
1. Dashboard chauffeur
2. Demande de course entrante
3. Navigation vers client
4. Statistiques et gains
5. Profil et paramètres

---

## ✅ ÉTAPE 9 : Soumission pour Review

### 9.1 Informations de review

**Coordonnées de contact:**
- Prénom: [Votre prénom]
- Nom: [Votre nom]
- Email: support@dudugroup.sn
- Téléphone: +221 XX XXX XX XX

**Compte de démo pour review:**
```
Client:
Email: demo@dudu.sn
Mot de passe: Demo2024!

Chauffeur:
Email: driver@dudu.sn
Mot de passe: Driver2024!
```

**Notes pour le reviewer:**
```
DUDU est une plateforme de transport au Sénégal. 

Pour tester l'application client:
1. Connectez-vous avec le compte démo
2. Entrez une adresse de départ et d'arrivée à Dakar
3. Sélectionnez un type de course
4. Proposez un prix
5. Un chauffeur de test acceptera automatiquement

Pour tester l'application chauffeur:
1. Connectez-vous avec le compte chauffeur
2. Activez le mode "En ligne"
3. Vous recevrez des demandes de courses
4. Acceptez une course pour voir le flux complet

Localisation de test: Dakar, Sénégal (14.7167, -17.4677)
```

### 9.2 Checklist finale

**Avant soumission:**
- [ ] Build uploadé et traité par App Store Connect
- [ ] Screenshots ajoutés pour toutes les tailles
- [ ] Icône de l'app (1024x1024) uploadée
- [ ] Description remplie
- [ ] Mots-clés ajoutés
- [ ] Catégories sélectionnées
- [ ] URLs de support/privacy ajoutées
- [ ] Informations de contact remplies
- [ ] Compte de démo créé et testé
- [ ] Notes pour reviewer ajoutées
- [ ] Classification d'âge définie (4+)
- [ ] Prix défini (Gratuit)

### 9.3 Soumettre

1. Dans App Store Connect
2. Sélectionner l'app
3. Version → 1.0
4. Cliquer "Submit for Review"
5. Répondre aux questions de conformité
6. Soumettre

---

## ⏱️ ÉTAPE 10 : Après la soumission

### Délais attendus
- **Review initial:** 24-48 heures
- **Réponse aux questions:** Immédiate
- **Publication:** Automatique après approbation

### Statuts possibles
- **Waiting for Review:** En attente
- **In Review:** En cours de review
- **Pending Developer Release:** Approuvé, en attente de publication manuelle
- **Ready for Sale:** Publié sur l'App Store
- **Rejected:** Refusé (voir les raisons et corriger)

### En cas de rejet

Les raisons courantes:
1. **Crash au démarrage:** Tester sur device réel
2. **Permissions non justifiées:** Vérifier les descriptions dans Info.plist
3. **Contenu manquant:** Ajouter compte démo fonctionnel
4. **Liens cassés:** Vérifier URLs de support/privacy
5. **Métadonnées incorrectes:** Vérifier description/screenshots

**Actions:**
1. Lire attentivement le message de rejet
2. Corriger les problèmes identifiés
3. Créer une nouvelle version (1.0.1)
4. Re-soumettre

---

## 🚀 ÉTAPE 11 : Publication

Une fois approuvé:
1. L'app apparaît sur l'App Store
2. Partager le lien: `https://apps.apple.com/app/idXXXXXXXXXX`
3. Promouvoir sur les réseaux sociaux
4. Surveiller les reviews et ratings

---

## 📊 Monitoring Post-Publication

### App Store Connect Analytics
- Téléchargements
- Impressions
- Conversions
- Crashes
- Reviews

### Mises à jour futures
```bash
# Incrémenter la version
# Dans pubspec.yaml: version: 1.0.1+2

# Build et upload
flutter build ipa --release
# Upload via Xcode/Transporter
```

---

## 🆘 Ressources et Support

- [Documentation Flutter iOS](https://docs.flutter.dev/deployment/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 📞 Contact

Pour toute question sur le déploiement:
- Email: support@dudugroup.sn
- Documentation: https://www.dudugroup.sn/docs

**Bonne chance avec votre déploiement ! 🎉**
