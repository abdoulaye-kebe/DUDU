# 🧪 Guide TestFlight - DUDU v1.0.0

## 📱 Distribuer vos apps aux testeurs via TestFlight

TestFlight permet à vos testeurs de télécharger et tester vos apps avant la publication officielle sur l'App Store.

---

## ✅ **ÉTAPE 1 : Créer les App IDs (Apple Developer)**

### 1.1 Aller sur Apple Developer

🔗 [developer.apple.com/account](https://developer.apple.com/account)

### 1.2 Créer l'App ID pour DUDU Client

1. **Certificates, Identifiers & Profiles** → **Identifiers** → **+**
2. Sélectionner **App IDs** → **Continue**
3. Remplir :
   ```
   Description: DUDU - Transport Client
   Bundle ID: Explicit → sn.dudugroup.app
   ```
4. **Capabilities** (cocher) :
   - ✅ Push Notifications
   - ✅ Maps
   - ✅ Background Modes
   - ✅ Associated Domains
5. **Continue** → **Register**

### 1.3 Créer l'App ID pour DUDU Pro

Répéter avec :
```
Description: DUDU Pro - Application Chauffeur
Bundle ID: Explicit → sn.dudu.mobileDuduPro
```
Mêmes capabilities → **Register**

---

## 📲 **ÉTAPE 2 : Créer les apps dans App Store Connect**

### 2.1 Aller sur App Store Connect

🔗 [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

### 2.2 Créer DUDU Client

1. **My Apps** → **+** (en haut à gauche) → **New App**
2. Remplir le formulaire :
   ```
   Platform: iOS
   Name: DUDU
   Primary Language: French (France)
   Bundle ID: sn.dudugroup.app (sélectionner dans la liste)
   SKU: DUDU-CLIENT-2026
   User Access: Full Access
   ```
3. **Create**

### 2.3 Créer DUDU Pro

Répéter avec :
```
Name: DUDU Pro
Bundle ID: sn.dudu.mobileDuduPro
SKU: DUDU-PRO-2026
```

---

## 🔨 **ÉTAPE 3 : Builder les apps**

### 3.1 Rendre le script exécutable

```bash
cd /Users/abdoulayekebe/Desktop/DUDU
chmod +x build_for_testflight.sh
```

### 3.2 Lancer le build

```bash
./build_for_testflight.sh
```

Le script va :
- ✅ Nettoyer les projets
- ✅ Installer les dépendances
- ✅ Builder les archives IPA
- ✅ Créer les fichiers prêts pour l'upload

**Durée estimée :** 5-10 minutes

### 3.3 Vérifier les fichiers

Les fichiers IPA seront créés ici :
```
dudu_flutter/build/ios/ipa/DUDU.ipa
mobile_dudu_pro/build/ios/ipa/mobile_dudu_pro.ipa
```

---

## 📤 **ÉTAPE 4 : Uploader vers App Store Connect**

### Option 1 : Via Transporter (Recommandé)

1. **Télécharger Transporter** depuis le Mac App Store
2. **Ouvrir Transporter**
3. **Se connecter** avec ton Apple ID
4. **Glisser-déposer** les 2 fichiers .ipa :
   - `DUDU.ipa`
   - `mobile_dudu_pro.ipa`
5. **Cliquer "Deliver"**
6. Attendre la fin de l'upload (5-15 min selon connexion)

### Option 2 : Via Xcode

1. Ouvrir Xcode
2. **Window** → **Organizer**
3. **Archives** (onglet)
4. Sélectionner l'archive DUDU
5. **Distribute App** → **App Store Connect** → **Upload**
6. Répéter pour DUDU Pro

### Option 3 : Via ligne de commande

```bash
xcrun altool --upload-app \
  -f dudu_flutter/build/ios/ipa/DUDU.ipa \
  -t ios \
  -u votre@email.com \
  -p "mot-de-passe-app-specific"
```

---

## 🧪 **ÉTAPE 5 : Configurer TestFlight**

### 5.1 Attendre le traitement

Après l'upload, Apple va traiter les builds (15-30 min).

Tu recevras un email : **"Your build has been processed"**

### 5.2 Configurer DUDU Client

1. Aller sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps** → **DUDU**
3. **TestFlight** (onglet en haut)
4. Tu verras ton build **1.0.0 (1)** avec le statut **"Ready to Submit"**

**Remplir les informations de test :**

1. Cliquer sur le build **1.0.0**
2. **Test Information** :
   ```
   What to Test:
   Version 1.0.0 - Première version beta
   
   Fonctionnalités à tester:
   - Connexion et inscription
   - Création de courses immédiates
   - Création de courses planifiées
   - Suivi en temps réel du chauffeur
   - Paiement mobile money
   - Notifications push
   - Géolocalisation
   
   Notes:
   - Utiliser une vraie adresse à Dakar
   - Tester avec un compte chauffeur actif
   ```

3. **Export Compliance** :
   - "Does your app use encryption?" → **NO** (si pas de chiffrement custom)
   - Ou **YES** et remplir les détails si tu utilises HTTPS

4. **Save**

### 5.3 Configurer DUDU Pro

Répéter les mêmes étapes pour **DUDU Pro** :
```
What to Test:
Version 1.0.0 - Première version beta chauffeur

Fonctionnalités à tester:
- Connexion chauffeur
- Réception de demandes de courses
- Acceptation/refus de courses
- Navigation vers client
- Gestion des courses planifiées
- Rappels automatiques
- Statistiques et gains
- Abonnement chauffeur
```

---

## 👥 **ÉTAPE 6 : Ajouter des testeurs**

### 6.1 Testeurs internes (jusqu'à 100)

**Pour DUDU Client :**

1. Dans **TestFlight** → **Internal Testing**
2. **+** (à côté de "Internal Testers")
3. **Add Internal Testers**
4. Entrer les emails de ton équipe :
   ```
   testeur1@dudu.sn
   testeur2@dudu.sn
   ```
5. **Add**
6. Sélectionner le build **1.0.0**
7. **Start Testing**

**Répéter pour DUDU Pro**

### 6.2 Testeurs externes (jusqu'à 10,000)

**Pour distribuer à plus de testeurs :**

1. **TestFlight** → **External Testing**
2. **+** → **Create New Group**
3. Nom du groupe : `Testeurs DUDU Beta`
4. **Create**
5. **Add Testers** :
   - Entrer les emails des testeurs
   - Ou importer un fichier CSV
6. Sélectionner le build **1.0.0**
7. **Submit for Review** (Apple doit approuver - 24-48h)

---

## 📧 **ÉTAPE 7 : Les testeurs reçoivent l'invitation**

### 7.1 Email d'invitation

Tes testeurs recevront un email :
```
Subject: You're invited to test DUDU

[Testeur],

Abdoulaye vous invite à tester DUDU via TestFlight.

[Install TestFlight] [View in TestFlight]
```

### 7.2 Installation par les testeurs

**Les testeurs doivent :**

1. **Installer TestFlight** depuis l'App Store (gratuit)
2. **Ouvrir l'email** d'invitation
3. **Cliquer "View in TestFlight"** ou **"Redeem"**
4. Dans TestFlight, cliquer **"Install"**
5. L'app DUDU s'installe comme une app normale
6. **Ouvrir DUDU** et commencer à tester

### 7.3 Feedback des testeurs

Les testeurs peuvent :
- Envoyer des **screenshots** avec annotations
- Envoyer des **crash reports** automatiquement
- Laisser des **commentaires** dans TestFlight

Tu verras tout dans **App Store Connect** → **TestFlight** → **Feedback**

---

## 🔄 **ÉTAPE 8 : Mettre à jour la version**

### 8.1 Nouvelle version

Quand tu corriges des bugs ou ajoutes des features :

1. **Modifier `pubspec.yaml` :**
   ```yaml
   version: 1.0.1+2  # Version 1.0.1, build 2
   ```

2. **Rebuilder :**
   ```bash
   ./build_for_testflight.sh
   ```

3. **Uploader** via Transporter

4. **Dans TestFlight :**
   - Le nouveau build **1.0.1 (2)** apparaîtra
   - Les testeurs recevront une notification
   - Ils peuvent mettre à jour dans TestFlight

### 8.2 Notes de version

Pour chaque nouveau build, ajoute des notes :
```
Version 1.0.1 - 20 janvier 2026

Corrections:
- Fix crash au démarrage
- Amélioration de la géolocalisation
- Correction notifications push

Nouveautés:
- Ajout du mode nuit
- Optimisation de la batterie
```

---

## 📊 **ÉTAPE 9 : Suivre les tests**

### 9.1 Métriques TestFlight

Dans **App Store Connect** → **TestFlight** → **Metrics** :

- **Installations** : Nombre de testeurs qui ont installé
- **Sessions** : Nombre d'ouvertures de l'app
- **Crashes** : Taux de crash et détails
- **Feedback** : Commentaires des testeurs

### 9.2 Crash Reports

**TestFlight** → **Crashes** :
- Voir les crashs en temps réel
- Stack traces complètes
- Fréquence et impact

### 9.3 Feedback

**TestFlight** → **Feedback** :
- Lire les commentaires
- Voir les screenshots annotés
- Répondre aux testeurs

---

## 🚀 **ÉTAPE 10 : Publier sur l'App Store**

### 10.1 Quand la beta est stable

Après plusieurs itérations de tests :

1. **App Store Connect** → **DUDU** → **App Store** (onglet)
2. **+Version or Platform** → **iOS**
3. Version : `1.0.0`
4. Remplir toutes les métadonnées (voir `APP_STORE_METADATA.md`)
5. Sélectionner le build TestFlight validé
6. **Submit for Review**

### 10.2 Review Apple

- Délai : 24-48 heures
- Apple teste l'app
- Si approuvé : **Ready for Sale**
- Si rejeté : Corriger et re-soumettre

---

## ✅ **Checklist complète**

### Configuration initiale
- [ ] App IDs créés dans Apple Developer
- [ ] Apps créées dans App Store Connect
- [ ] Certificats de distribution configurés

### Build et upload
- [ ] Script `build_for_testflight.sh` exécuté
- [ ] Fichiers .ipa générés
- [ ] Upload via Transporter réussi
- [ ] Builds traités par Apple (email reçu)

### Configuration TestFlight
- [ ] Informations de test remplies
- [ ] Export compliance configuré
- [ ] Testeurs internes ajoutés
- [ ] Testeurs externes ajoutés (si besoin)
- [ ] Groupes de test créés

### Distribution
- [ ] Invitations envoyées aux testeurs
- [ ] Testeurs ont installé TestFlight
- [ ] Testeurs ont installé les apps
- [ ] Feedback reçu et traité

### Suivi
- [ ] Métriques consultées régulièrement
- [ ] Crashes corrigés
- [ ] Nouvelles versions uploadées
- [ ] Notes de version ajoutées

---

## 🆘 **Problèmes courants**

### "Build Invalid"

**Cause :** Bundle ID incorrect ou certificat manquant

**Solution :**
1. Vérifier le Bundle ID dans Xcode
2. Vérifier les certificats dans Apple Developer
3. Rebuilder

### "Missing Export Compliance"

**Cause :** Information de chiffrement non remplie

**Solution :**
1. Dans TestFlight → Build → Export Compliance
2. Répondre aux questions
3. Save

### "Testeurs ne reçoivent pas l'email"

**Cause :** Email incorrect ou spam

**Solution :**
1. Vérifier l'adresse email
2. Demander aux testeurs de vérifier les spams
3. Renvoyer l'invitation

### "App crash au démarrage"

**Cause :** Permissions manquantes ou backend inaccessible

**Solution :**
1. Vérifier Info.plist (permissions)
2. Tester la connexion au backend
3. Consulter les crash reports dans TestFlight

---

## 📞 **Support**

- **Documentation Apple :** [developer.apple.com/testflight](https://developer.apple.com/testflight)
- **Support DUDU :** support@dudugroup.sn
- **Guide complet :** `GUIDE_DEPLOIEMENT_APP_STORE.md`

---

**Bonne chance avec vos tests ! 🎉**
