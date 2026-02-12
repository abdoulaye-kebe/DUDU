# 🍎 GUIDE DE PUBLICATION APP STORE - DUDU

**Date :** 12 Février 2026  
**Compte Apple Developer :** Requis ✅  
**Applications :** DUDU Client + DUDU Pro (Chauffeur)

---

## 📋 PRÉREQUIS

### ✅ Ce que tu as déjà

- [x] Compte Apple Developer actif
- [x] Applications Flutter compilées
- [x] IPA générés (non signés)
- [x] Backend live fonctionnel

### 📝 Ce qu'il faut préparer

- [ ] Certificats de distribution iOS
- [ ] Profils de provisionnement
- [ ] App Store Connect configuré
- [ ] Métadonnées (descriptions, screenshots, etc.)
- [ ] Icônes et assets
- [ ] Politique de confidentialité
- [ ] Conditions d'utilisation

---

## 🔐 ÉTAPE 1 : CONFIGURATION CERTIFICATS

### **1.1 Créer les Certificats**

**Sur Apple Developer Portal (developer.apple.com) :**

1. Aller dans **Certificates, Identifiers & Profiles**
2. Cliquer sur **Certificates** → **+**
3. Sélectionner **Apple Distribution**
4. Suivre les instructions pour générer le CSR
5. Télécharger et installer le certificat

### **1.2 Créer les App IDs**

**App Client (DUDU) :**
- Bundle ID : `sn.dudugroup.app`
- Nom : DUDU - Transport & Livraison
- Capabilities : 
  - Push Notifications
  - Maps
  - Background Modes
  - Location Services

**App Chauffeur (DUDU Pro) :**
- Bundle ID : `sn.dudu.mobileDuduPro`
- Nom : DUDU Pro - Chauffeur
- Capabilities :
  - Push Notifications
  - Maps
  - Background Modes
  - Location Services

### **1.3 Créer les Profils de Provisionnement**

Pour chaque app :
1. **Profiles** → **+**
2. Sélectionner **App Store**
3. Choisir l'App ID
4. Sélectionner le certificat de distribution
5. Télécharger le profil

---

## 📱 ÉTAPE 2 : CONFIGURATION XCODE

### **2.1 Ouvrir les Projets iOS**

**App Client :**
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/dudu_flutter
open ios/Runner.xcworkspace
```

**App Chauffeur :**
```bash
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro
open ios/Runner.xcworkspace
```

### **2.2 Configuration Signing**

Dans Xcode, pour chaque projet :

1. Sélectionner le projet **Runner**
2. Onglet **Signing & Capabilities**
3. **Team** : Sélectionner ton compte Apple Developer
4. **Bundle Identifier** : Vérifier qu'il correspond
5. **Provisioning Profile** : Sélectionner le profil App Store
6. Décocher **Automatically manage signing**
7. Sélectionner manuellement le profil de distribution

### **2.3 Vérifier les Infos**

**Info.plist - Permissions requises :**

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>DUDU a besoin de votre position pour trouver des chauffeurs près de vous</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>DUDU a besoin de votre position en arrière-plan pour suivre votre course</string>

<key>NSCameraUsageDescription</key>
<string>DUDU a besoin d'accéder à votre caméra pour prendre des photos de profil</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>DUDU a besoin d'accéder à vos photos pour votre photo de profil</string>
```

---

## 🏗️ ÉTAPE 3 : BUILD POUR APP STORE

### **3.1 Build avec Xcode**

**Commandes Flutter :**

```bash
# App Client
cd /Users/abdoulayekebe/Desktop/DUDU/dudu_flutter
flutter clean
flutter pub get
flutter build ios --release

# App Chauffeur
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro
flutter clean
flutter pub get
flutter build ios --release
```

### **3.2 Archive dans Xcode**

Pour chaque app :

1. Ouvrir le workspace dans Xcode
2. Sélectionner **Any iOS Device (arm64)**
3. Menu **Product** → **Archive**
4. Attendre la fin de l'archivage
5. La fenêtre **Organizer** s'ouvre automatiquement

### **3.3 Upload vers App Store Connect**

Dans l'Organizer :

1. Sélectionner l'archive
2. Cliquer **Distribute App**
3. Choisir **App Store Connect**
4. Sélectionner **Upload**
5. Cocher **Include bitcode** (si disponible)
6. Cocher **Upload your app's symbols**
7. Cliquer **Next** → **Upload**
8. Attendre la fin de l'upload

---

## 📝 ÉTAPE 4 : APP STORE CONNECT

### **4.1 Créer les Apps**

**Sur App Store Connect (appstoreconnect.apple.com) :**

1. Aller dans **My Apps**
2. Cliquer **+** → **New App**

**Pour DUDU Client :**
- Platform : iOS
- Name : DUDU - Transport & Livraison
- Primary Language : French
- Bundle ID : sn.dudugroup.app
- SKU : DUDU-CLIENT-001

**Pour DUDU Pro :**
- Platform : iOS
- Name : DUDU Pro - Chauffeur
- Primary Language : French
- Bundle ID : sn.dudu.mobileDuduPro
- SKU : DUDU-PRO-001

### **4.2 Informations de l'App**

**Catégories :**
- Primary : Travel
- Secondary : Navigation

**Informations de Contact :**
- Email : support@dudugroup.sn
- Téléphone : +221 XX XXX XX XX
- URL : https://www.dudugroup.sn

### **4.3 Descriptions**

**DUDU Client - Description Courte (30 caractères max) :**
```
Transport rapide au Sénégal
```

**DUDU Client - Description Complète :**
```
🚗 DUDU - Votre Solution de Transport au Sénégal

Découvrez DUDU, l'application de transport qui révolutionne vos déplacements à Dakar et au Sénégal !

✨ FONCTIONNALITÉS PRINCIPALES

🚕 TYPES DE COURSES
• Standard : Transport économique et fiable
• Confort : Véhicules haut de gamme
• Luxe : Expérience premium avec prix flexible
• Moto : Déplacements rapides en deux-roues
• Femme : Courses réservées aux femmes

💰 PAIEMENT FLEXIBLE
• Wave - Paiement mobile instantané
• Orange Money - Sécurisé et rapide
• Espèces - Option traditionnelle
• Paiement en fin de course ou à l'avance

📅 COURSES PLANIFIÉES
• Réservez vos courses à l'avance
• Paiement sécurisé avant la course
• Confirmation instantanée

🗺️ SUIVI EN TEMPS RÉEL
• Suivez votre chauffeur en direct
• Partagez votre trajet avec vos proches
• Numéros d'urgence intégrés

🎯 POURQUOI CHOISIR DUDU ?

✅ Chauffeurs vérifiés et professionnels
✅ Tarifs transparents et compétitifs
✅ Service client 24/7
✅ Paiement sécurisé
✅ Interface simple et intuitive
✅ Disponible dans tout le Sénégal

📱 TÉLÉCHARGEZ MAINTENANT

Rejoignez des milliers d'utilisateurs satisfaits et profitez d'un transport fiable, rapide et sécurisé au Sénégal !

🌍 DUDU - Votre partenaire mobilité au Sénégal
```

**DUDU Pro - Description Courte :**
```
Gagnez de l'argent en conduisant
```

**DUDU Pro - Description Complète :**
```
🚗 DUDU Pro - Devenez Chauffeur Partenaire

Transformez votre véhicule en source de revenus avec DUDU Pro, l'application dédiée aux chauffeurs professionnels au Sénégal !

💼 POURQUOI DEVENIR CHAUFFEUR DUDU ?

💰 REVENUS ATTRACTIFS
• Gagnez jusqu'à 500 000 FCFA/mois
• Abonnements flexibles dès 1 000 FCFA/jour
• Bonus hebdomadaires pour les meilleurs
• Paiements rapides et sécurisés

📊 GESTION SIMPLIFIÉE
• Tableau de bord complet
• Statistiques en temps réel
• Historique des courses
• Suivi des revenus

🗺️ NAVIGATION INTELLIGENTE
• GPS intégré avec itinéraires optimisés
• Instructions vocales en temps réel
• Calcul automatique de la distance
• Temps de trajet estimé

🎯 FONCTIONNALITÉS PRO

✅ Abonnements Flexibles
• Journalier : 1 000 FCFA
• Hebdomadaire : 5 000 FCFA (économisez 29%)
• Mensuel : 21 000 FCFA (économisez 30%)
• Cumul illimité de jours

✅ Courses Illimitées
• Acceptez autant de courses que vous voulez
• Zones de forte demande signalées
• Notifications instantanées

✅ Support Dédié
• Équipe disponible 24/7
• Formation gratuite
• Assistance technique

✅ Sécurité Maximale
• Assurance incluse
• Vérification des passagers
• Bouton d'urgence intégré

📱 COMMENT ÇA MARCHE ?

1️⃣ Téléchargez DUDU Pro
2️⃣ Créez votre compte chauffeur
3️⃣ Soumettez vos documents
4️⃣ Attendez la validation (24-48h)
5️⃣ Choisissez votre abonnement
6️⃣ Commencez à gagner !

🎁 BONUS SPÉCIAUX

🏆 Bonus Hebdomadaire Moto
• 10 courses/semaine : 1 jour gratuit
• 20 courses/semaine : 2 000 FCFA cash

💎 Programme de Fidélité
• Points à chaque course
• Récompenses exclusives
• Avantages VIP

🌟 REJOIGNEZ-NOUS AUJOURD'HUI

Des milliers de chauffeurs font déjà confiance à DUDU Pro pour augmenter leurs revenus. Pourquoi pas vous ?

🚗 DUDU Pro - Votre succès, notre priorité
```

### **4.4 Mots-clés (100 caractères max)**

**DUDU Client :**
```
transport,taxi,dakar,senegal,course,vtc,moto,livraison,wave,orange
```

**DUDU Pro :**
```
chauffeur,vtc,taxi,revenus,travail,senegal,dakar,conduire,argent
```

### **4.5 Screenshots Requis**

**Tailles requises pour iPhone :**
- 6.7" (iPhone 14 Pro Max) : 1290 x 2796 px
- 6.5" (iPhone 11 Pro Max) : 1242 x 2688 px
- 5.5" (iPhone 8 Plus) : 1242 x 2208 px

**Nombre de screenshots :** 3-10 par taille

**Screenshots à créer :**
1. Écran d'accueil avec carte
2. Sélection du type de course
3. Suivi de course en temps réel
4. Paiement
5. Historique des courses

---

## 🎨 ÉTAPE 5 : ASSETS ET ICÔNES

### **5.1 Icône de l'App**

**Tailles requises :**
- 1024x1024 px (App Store)
- Toutes les tailles dans Assets.xcassets

**Format :**
- PNG sans transparence
- Pas de coins arrondis (iOS le fait automatiquement)

### **5.2 Captures d'écran**

**Outils recommandés :**
- Simulateur iOS (Xcode)
- Screenshot Maker (en ligne)
- Figma/Sketch pour les designs

**Conseils :**
- Utiliser des données réalistes
- Montrer les fonctionnalités clés
- Ajouter du texte explicatif si nécessaire
- Utiliser des couleurs cohérentes avec la marque

---

## 📄 ÉTAPE 6 : DOCUMENTS LÉGAUX

### **6.1 Politique de Confidentialité**

**URL requise :** https://www.dudugroup.sn/privacy

**Sections à inclure :**
- Collecte de données (localisation, profil, paiement)
- Utilisation des données
- Partage avec tiers (chauffeurs, services de paiement)
- Sécurité des données
- Droits des utilisateurs
- Contact

### **6.2 Conditions d'Utilisation**

**URL requise :** https://www.dudugroup.sn/terms

**Sections à inclure :**
- Acceptation des conditions
- Utilisation du service
- Paiements et remboursements
- Responsabilités
- Résiliation
- Loi applicable

### **6.3 Support**

**URL requise :** https://www.dudugroup.sn/support

**Informations à fournir :**
- FAQ
- Contact support
- Tutoriels
- Signalement de problèmes

---

## 🔍 ÉTAPE 7 : REVIEW GUIDELINES

### **7.1 Points de Vérification Apple**

**Fonctionnalités :**
- [ ] L'app fonctionne sans crash
- [ ] Toutes les fonctionnalités sont opérationnelles
- [ ] Les paiements sont conformes aux règles Apple
- [ ] La localisation est utilisée de manière appropriée
- [ ] Les notifications sont pertinentes

**Contenu :**
- [ ] Pas de contenu offensant
- [ ] Descriptions précises
- [ ] Screenshots représentatifs
- [ ] Métadonnées complètes

**Légal :**
- [ ] Politique de confidentialité accessible
- [ ] Conditions d'utilisation claires
- [ ] Conformité RGPD/lois locales

### **7.2 Informations de Test**

**À fournir dans App Store Connect :**

**Compte de test :**
- Email : test@dudugroup.sn
- Mot de passe : [à définir]

**Notes pour les reviewers :**
```
DUDU est une application de transport au Sénégal.

COMPTE DE TEST :
Email : test@dudugroup.sn
Mot de passe : TestDudu2026!

FONCTIONNALITÉS À TESTER :
1. Inscription/Connexion
2. Demander une course (utiliser l'adresse : Dakar, Sénégal)
3. Suivre la course en temps réel
4. Paiement (mode test activé)

PAIEMENTS :
Les paiements Wave et Orange Money sont intégrés via deep links.
En mode test, les paiements ne sont pas réellement effectués.

LOCALISATION :
L'app utilise la localisation pour :
- Trouver des chauffeurs à proximité
- Suivre la course en temps réel
- Calculer les itinéraires

BACKEND :
Serveur de production : http://213.154.90.11:3000
```

---

## 🚀 ÉTAPE 8 : SOUMISSION

### **8.1 Checklist Finale**

**App Store Connect :**
- [ ] Informations de l'app complètes
- [ ] Screenshots uploadés (toutes tailles)
- [ ] Icône 1024x1024 uploadée
- [ ] Description et mots-clés remplis
- [ ] Catégories sélectionnées
- [ ] Politique de confidentialité URL
- [ ] Conditions d'utilisation URL
- [ ] Support URL
- [ ] Informations de contact
- [ ] Build uploadé et traité
- [ ] Informations de test fournies

**Pricing :**
- [ ] Prix défini (Gratuit recommandé)
- [ ] Pays/régions sélectionnés (Sénégal + autres)

### **8.2 Soumettre pour Review**

1. Aller dans **App Store Connect**
2. Sélectionner l'app
3. Onglet **App Store**
4. Cliquer **Add for Review**
5. Répondre aux questions de conformité
6. Cliquer **Submit for Review**

### **8.3 Délais**

**Temps de review :**
- Première soumission : 24-48 heures
- Mises à jour : 24 heures
- Rejets : Réponse immédiate avec raisons

**Statuts possibles :**
- **Waiting for Review** : En attente
- **In Review** : En cours de vérification
- **Pending Developer Release** : Approuvé, en attente de publication
- **Ready for Sale** : Publié sur l'App Store
- **Rejected** : Refusé (avec raisons)

---

## 🎯 ÉTAPE 9 : APRÈS PUBLICATION

### **9.1 Monitoring**

**App Store Connect Analytics :**
- Téléchargements
- Impressions
- Taux de conversion
- Notes et avis
- Crashes

**Backend Monitoring :**
- Logs serveur
- Erreurs API
- Performance
- Utilisation

### **9.2 Mises à Jour**

**Fréquence recommandée :**
- Corrections de bugs : Immédiat
- Nouvelles fonctionnalités : Mensuel
- Améliorations : Bimensuel

**Process :**
1. Développer les changements
2. Tester en profondeur
3. Incrémenter la version
4. Build et upload
5. Soumettre pour review

### **9.3 Support Utilisateurs**

**Répondre aux avis :**
- Positifs : Remercier
- Négatifs : Proposer une solution
- Délai : Moins de 24h

**Support direct :**
- Email : support@dudugroup.sn
- Téléphone : +221 XX XXX XX XX
- Chat in-app (si disponible)

---

## 📊 CHECKLIST PUBLICATION

### **Avant Soumission**

- [ ] Compte Apple Developer actif (99$/an)
- [ ] Certificats de distribution créés
- [ ] Profils de provisionnement configurés
- [ ] Apps buildées et archivées dans Xcode
- [ ] Builds uploadés sur App Store Connect
- [ ] Screenshots créés (toutes tailles)
- [ ] Icônes préparées (1024x1024)
- [ ] Descriptions rédigées (FR + EN)
- [ ] Mots-clés définis
- [ ] Politique de confidentialité en ligne
- [ ] Conditions d'utilisation en ligne
- [ ] Page de support en ligne
- [ ] Compte de test créé
- [ ] Notes pour reviewers rédigées
- [ ] Prix défini (Gratuit)
- [ ] Pays/régions sélectionnés

### **Pendant Review**

- [ ] Surveiller les emails d'Apple
- [ ] Répondre rapidement si questions
- [ ] Tester le compte de test
- [ ] Vérifier le backend live

### **Après Approbation**

- [ ] Publier immédiatement ou planifier
- [ ] Annoncer sur les réseaux sociaux
- [ ] Informer les utilisateurs existants
- [ ] Monitorer les téléchargements
- [ ] Répondre aux premiers avis
- [ ] Corriger les bugs critiques rapidement

---

## 🆘 PROBLÈMES COURANTS

### **Rejection Reasons**

**1. Crash au lancement**
- Solution : Tester sur device réel, pas seulement simulateur

**2. Fonctionnalité manquante**
- Solution : S'assurer que toutes les features décrites fonctionnent

**3. Métadonnées incorrectes**
- Solution : Vérifier que screenshots correspondent à l'app

**4. Paiements non conformes**
- Solution : Utiliser In-App Purchase pour achats digitaux

**5. Localisation non justifiée**
- Solution : Expliquer clairement l'usage dans Info.plist

### **Solutions Rapides**

**Build échoue :**
```bash
flutter clean
flutter pub get
rm -rf ios/Pods
cd ios && pod install
cd .. && flutter build ios --release
```

**Certificat expiré :**
- Renouveler sur developer.apple.com
- Télécharger et installer le nouveau
- Rebuild l'app

**Profil invalide :**
- Vérifier que le Bundle ID correspond
- Recréer le profil si nécessaire
- Sélectionner le bon profil dans Xcode

---

## 📞 RESSOURCES

**Documentation Apple :**
- App Store Review Guidelines : https://developer.apple.com/app-store/review/guidelines/
- App Store Connect Help : https://help.apple.com/app-store-connect/
- Human Interface Guidelines : https://developer.apple.com/design/human-interface-guidelines/

**Outils :**
- Xcode : https://developer.apple.com/xcode/
- Transporter : https://apps.apple.com/app/transporter/id1450874784
- TestFlight : https://developer.apple.com/testflight/

**Support :**
- Apple Developer Forums : https://developer.apple.com/forums/
- Stack Overflow : https://stackoverflow.com/questions/tagged/ios
- Flutter Documentation : https://flutter.dev/docs

---

**Guide créé le :** 12 Février 2026  
**Version :** 1.0  
**Auteur :** Équipe DUDU

🍎 **Bonne chance pour la publication sur l'App Store !**
