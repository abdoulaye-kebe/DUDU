# Guide : Ajouter GoogleService-Info.plist à votre projet iOS

## ✅ Étape 1 : Placer le fichier

1. **Trouvez le fichier téléchargé** `GoogleService-Info.plist` (probablement dans votre dossier Téléchargements)

2. **Copiez-le** dans le dossier suivant :
   ```
   /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro/ios/Runner/
   ```

   Vous pouvez :
   - **Glisser-déposer** le fichier dans le Finder à cet endroit
   - Ou utiliser le terminal :
     ```bash
     cp ~/Downloads/GoogleService-Info.plist ~/Desktop/DUDU/mobile_dudu_pro/ios/Runner/
     ```

## ⚠️ Étape 2 : Ajouter le fichier à Xcode (OBLIGATOIRE)

**C'est la partie la plus importante !** Le fichier doit être ajouté au projet Xcode, sinon il ne sera pas inclus dans l'application.

### Méthode 1 : Via Xcode (Recommandé)

1. **Ouvrez le projet dans Xcode** :
   ```bash
   cd ~/Desktop/DUDU/mobile_dudu_pro/ios
   open Runner.xcworkspace
   ```
   ⚠️ **Important** : Ouvrez `.xcworkspace` et NON `.xcodeproj`

2. Dans Xcode :
   - Dans le panneau de gauche (Project Navigator), trouvez le dossier `Runner`
   - **Glissez-déposez** le fichier `GoogleService-Info.plist` depuis le Finder dans le dossier `Runner` dans Xcode
   - Une fenêtre de dialogue apparaîtra
   - ✅ **Cochez** "Copy items if needed" (si pas déjà coché)
   - ✅ **Cochez** "Add to targets: Runner"
   - Cliquez sur **"Finish"**

3. **Vérifiez** que le fichier apparaît maintenant dans Xcode sous le dossier `Runner`

### Méthode 2 : Vérification rapide

Si vous avez déjà ajouté le fichier, vérifiez dans Xcode :
- Le fichier `GoogleService-Info.plist` doit apparaître dans la liste des fichiers du projet
- Si vous cliquez dessus, il doit s'ouvrir dans l'éditeur Xcode

## 🔍 Vérification du contenu

Le fichier `GoogleService-Info.plist` devrait contenir des informations comme :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLIENT_ID</key>
	<string>...</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>...</string>
	<key>API_KEY</key>
	<string>...</string>
	<key>GCM_SENDER_ID</key>
	<string>...</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>sn.dudu.mobileDuduPro</string>
	<key>PROJECT_ID</key>
	<string>votre-project-id</string>
	<key>STORAGE_BUCKET</key>
	<string>votre-project-id.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:...</string>
</dict>
</plist>
```

Vérifiez que `BUNDLE_ID` correspond à `sn.dudu.mobileDuduPro`.

## ✅ Étape 3 : Vérification finale

1. **Dans Xcode**, sélectionnez le fichier `GoogleService-Info.plist`
2. **Dans l'inspecteur de fichiers** (panneau de droite), vérifiez que :
   - Le **Target Membership** inclut ✅ **Runner**

## 🚀 Étape 4 : Installer les dépendances iOS

Exécutez dans le terminal :

```bash
cd ~/Desktop/DUDU/mobile_dudu_pro/ios
pod install
```

## 📱 Étape 5 : Tester

Lancez l'application :

```bash
cd ~/Desktop/DUDU/mobile_dudu_pro
flutter run
```

Si tout est correct, l'application devrait se lancer sans erreur Firebase.

## ❓ Problèmes courants

### Erreur : "GoogleService-Info.plist not found"
- Le fichier n'a pas été ajouté au projet Xcode
- Solution : Suivez l'Étape 2 ci-dessus

### Erreur : "BUNDLE_ID mismatch"
- Le Bundle ID dans Firebase ne correspond pas à celui du projet
- Vérifiez que le Bundle ID est bien `sn.dudu.mobileDuduPro` dans les deux endroits

### Erreur : "FirebaseApp not initialized"
- Le fichier n'est pas trouvé par l'application
- Vérifiez qu'il est bien dans `ios/Runner/` et ajouté à Xcode

---

Une fois ces étapes terminées, votre configuration Firebase iOS sera complète ! 🎉

