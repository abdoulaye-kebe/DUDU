# 🎨 Icône de l'App DUDU Pro

## ✅ Icône Installée

Le logo DUDU a été copié dans tous les dossiers mipmap:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

## 🔄 Pour Optimiser l'Icône (Optionnel)

### Option 1: Android Asset Studio (En ligne)

1. Aller sur: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
2. Upload `logo_dudu_off.png`
3. Ajuster le padding, la forme, etc.
4. Télécharger le ZIP
5. Extraire et remplacer les fichiers dans `android/app/src/main/res/`

### Option 2: flutter_launcher_icons (Package)

```bash
# 1. Ajouter au pubspec.yaml:
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/logo_dudu_off.png"
  adaptive_icon_background: "#0d5d36"
  adaptive_icon_foreground: "assets/images/logo_dudu_off.png"

# 2. Générer les icônes:
flutter pub get
flutter pub run flutter_launcher_icons
```

## 📱 Tailles Recommandées

- **mdpi**: 48x48 px
- **hdpi**: 72x72 px
- **xhdpi**: 96x96 px
- **xxhdpi**: 144x144 px
- **xxxhdpi**: 192x192 px

## 🎯 Rebuild l'App

Pour voir le nouveau logo:

```bash
flutter clean
flutter pub get
flutter run
```

L'icône apparaîtra sur l'écran d'accueil de l'émulateur/téléphone!
