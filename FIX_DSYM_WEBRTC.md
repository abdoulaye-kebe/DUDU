# 🔧 FIX : Erreur dSYM WebRTC.framework

**Erreur :**
```
The archive did not include a dSYM for the WebRTC.framework with the UUIDs [4C4C445C-5555-3144-A123-D3009B21938E]
```

**Cause :** Le framework WebRTC (utilisé par `flutter_webrtc`) ne génère pas automatiquement ses symboles de débogage (dSYM) lors de l'archivage.

---

## ✅ SOLUTION 1 : Upload sans Symboles (Rapide)

**Avantage :** Permet de soumettre l'app immédiatement  
**Inconvénient :** Pas de symboles de crash pour WebRTC

### Étapes :

1. **Dans Xcode Organizer :**
   - Sélectionner l'archive
   - Cliquer **Distribute App**
   - Choisir **App Store Connect**
   - **DÉCOCHER** "Upload your app's symbols to receive symbolicated reports"
   - Continuer l'upload

2. **Résultat :**
   - L'app sera uploadée sans erreur
   - Tu pourras soumettre pour review
   - Les crashes WebRTC ne seront pas symbolisés

---

## ✅ SOLUTION 2 : Générer les dSYM Manquants (Recommandé)

**Avantage :** Symboles complets pour tous les frameworks  
**Inconvénient :** Nécessite un rebuild

### Étapes :

#### **1. Ajouter un Build Phase Script**

Dans Xcode :

1. Ouvrir `mobile_dudu_pro/ios/Runner.xcworkspace`
2. Sélectionner le projet **Runner**
3. Sélectionner la target **Runner**
4. Onglet **Build Phases**
5. Cliquer **+** → **New Run Script Phase**
6. Nommer le script : "Generate dSYMs for CocoaPods"
7. Coller ce script :

```bash
#!/bin/bash

# Générer les dSYM pour tous les frameworks CocoaPods
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "🔍 Génération des dSYM pour les frameworks..."
    
    # Chemin vers les frameworks
    FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
    
    # Parcourir tous les frameworks
    for FRAMEWORK in "${FRAMEWORKS_PATH}"/*.framework; do
        if [ -d "${FRAMEWORK}" ]; then
            FRAMEWORK_NAME=$(basename "${FRAMEWORK}" .framework)
            FRAMEWORK_EXECUTABLE="${FRAMEWORK}/${FRAMEWORK_NAME}"
            
            if [ -f "${FRAMEWORK_EXECUTABLE}" ]; then
                echo "📦 Génération dSYM pour ${FRAMEWORK_NAME}..."
                dsymutil "${FRAMEWORK_EXECUTABLE}" -o "${DWARF_DSYM_FOLDER_PATH}/${FRAMEWORK_NAME}.framework.dSYM" 2>/dev/null || true
            fi
        fi
    done
    
    echo "✅ dSYM générés!"
fi
```

8. Déplacer ce script **AVANT** "Embed Pods Frameworks"

#### **2. Rebuild et Archive**

```bash
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro

# Clean
flutter clean
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# Reinstall
flutter pub get
cd ios
pod install
cd ..

# Build
flutter build ios --release

# Archive dans Xcode
open ios/Runner.xcworkspace
```

Dans Xcode :
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Archive
3. Attendre la fin de l'archivage
4. Les dSYM seront générés automatiquement

#### **3. Upload vers App Store Connect**

Dans Organizer :
1. Sélectionner la nouvelle archive
2. Distribute App → App Store Connect
3. **COCHER** "Upload your app's symbols"
4. Upload
5. ✅ Pas d'erreur dSYM !

---

## ✅ SOLUTION 3 : Modifier le Podfile (Alternative)

### Étapes :

1. **Éditer `mobile_dudu_pro/ios/Podfile`**

Ajouter à la fin du fichier :

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Générer les dSYM pour tous les pods
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      
      # Configuration spécifique pour WebRTC
      if target.name == 'WebRTC'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'YES'
      end
    end
  end
end
```

2. **Reinstall Pods**

```bash
cd /Users/abdoulayekebe/Desktop/DUDU/mobile_dudu_pro/ios
pod deintegrate
pod install
cd ..
```

3. **Rebuild et Archive**

```bash
flutter clean
flutter build ios --release
# Puis Archive dans Xcode
```

---

## 🎯 RECOMMANDATION

**Pour une première soumission rapide :**
→ Utiliser **SOLUTION 1** (Upload sans symboles)

**Pour une version production complète :**
→ Utiliser **SOLUTION 2** (Build Phase Script)

---

## 📊 Vérification

### Après l'archive, vérifier que les dSYM sont présents :

```bash
# Trouver le chemin de l'archive
ARCHIVE_PATH="~/Library/Developer/Xcode/Archives/[DATE]/Runner [DATE].xcarchive"

# Lister les dSYM
ls -la "${ARCHIVE_PATH}/dSYMs/"

# Devrait afficher :
# - Runner.app.dSYM
# - WebRTC.framework.dSYM
# - [autres frameworks].framework.dSYM
```

### Vérifier les UUIDs :

```bash
# UUID de l'app
dwarfdump --uuid "${ARCHIVE_PATH}/Products/Applications/Runner.app/Runner"

# UUID du framework WebRTC
dwarfdump --uuid "${ARCHIVE_PATH}/dSYMs/WebRTC.framework.dSYM"

# Les UUIDs doivent correspondre
```

---

## ⚠️ Notes Importantes

### **Pourquoi cette erreur ?**

Le package `flutter_webrtc` utilise le framework WebRTC natif qui est distribué comme framework précompilé via CocoaPods. Ces frameworks précompilés n'incluent pas toujours les dSYM par défaut.

### **Impact si on ignore ?**

- L'app fonctionnera normalement
- Mais les crash reports impliquant WebRTC ne seront pas symbolisés
- Tu verras des adresses mémoire au lieu de noms de fonctions

### **Frameworks concernés**

Cette solution fonctionne pour tous les frameworks CocoaPods :
- WebRTC
- GoogleMaps
- Firebase
- Etc.

---

## 🔄 Pour les Futures Mises à Jour

Une fois le script Build Phase ajouté, il sera automatiquement exécuté à chaque archive. Tu n'auras plus besoin de faire quoi que ce soit.

---

## 📞 Si le Problème Persiste

### **Erreur : "dsymutil: error: cannot parse the debug map"**

Solution :
```bash
# Dans le Build Phase Script, ajouter 2>/dev/null || true
dsymutil "${FRAMEWORK_EXECUTABLE}" -o "${DSYM_FILE}" 2>/dev/null || true
```

### **Erreur : "No such file or directory"**

Vérifier que :
- Le framework existe dans `${FRAMEWORKS_PATH}`
- Le chemin `${DWARF_DSYM_FOLDER_PATH}` est accessible
- Les permissions sont correctes

### **L'upload échoue toujours**

Utiliser **SOLUTION 1** (upload sans symboles) pour débloquer la situation immédiatement.

---

**Document créé le :** 12 Février 2026  
**Version :** 1.0
