# ⚠️ Étape importante : Ajouter le fichier à Xcode

Le fichier est maintenant au bon endroit, mais il **DOIT** être ajouté au projet Xcode.

## 📱 Méthode rapide

1. **Ouvrez Xcode** :
   ```bash
   cd ~/Desktop/DUDU/mobile_dudu_pro/ios
   open Runner.xcworkspace
   ```

2. **Dans Xcode** :
   - Dans le panneau de gauche (Project Navigator), trouvez le dossier `Runner`
   - Si vous ne voyez **PAS** `GoogleService-Info.plist` dans la liste :
     - Cliquez droit sur le dossier `Runner`
     - Cliquez sur "Add Files to Runner..."
     - Naviguez vers : `Runner/GoogleService-Info.plist`
     - ✅ Cochez "Copy items if needed" (déjà fait, mais cochez quand même)
     - ✅ Cochez "Add to targets: Runner"
     - Cliquez sur "Add"

3. **Vérifiez** :
   - Le fichier `GoogleService-Info.plist` doit maintenant apparaître dans Xcode sous le dossier `Runner`
   - Cliquez dessus pour voir qu'il contient bien les clés Firebase

## ✅ Une fois ajouté à Xcode

Le fichier devrait apparaître comme ceci dans Xcode :
```
Runner/
  ├── AppDelegate.swift
  ├── GoogleService-Info.plist  ← Doit être ici
  ├── Info.plist
  └── ...
```

---

**C'est fait ?** Une fois ajouté à Xcode, vous pouvez passer à l'étape suivante : installer les pods iOS.

