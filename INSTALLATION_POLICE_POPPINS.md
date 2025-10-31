# 🎨 Installation de la Police Poppins

## ✅ Configuration Terminée

Les fichiers `pubspec.yaml` ont été configurés pour les deux applications :
- ✅ `dudu_flutter/pubspec.yaml` - Police Poppins ajoutée
- ✅ `mobile_dudu_pro/pubspec.yaml` - Police Poppins ajoutée
- ✅ Thème mis à jour avec `fontFamily: 'Poppins'`

---

## 📥 ÉTAPE 1 : Télécharger la Police Poppins

### Option 1 : Google Fonts (Recommandé)
1. Allez sur : **https://fonts.google.com/specimen/Poppins**
2. Cliquez sur **"Download family"** en haut à droite
3. Extrayez le fichier ZIP téléchargé

### Option 2 : Lien Direct
- Téléchargez directement : **https://fonts.google.com/download?family=Poppins**

---

## 📂 ÉTAPE 2 : Copier les Fichiers de Police

Dans le dossier extrait, vous trouverez un dossier `static/`. Copiez ces 5 fichiers `.ttf` :

### Pour `dudu_flutter/assets/fonts/` :
```
✅ Poppins-Light.ttf       (poids 300)
✅ Poppins-Regular.ttf     (poids 400)
✅ Poppins-Medium.ttf      (poids 500)
✅ Poppins-SemiBold.ttf    (poids 600)
✅ Poppins-Bold.ttf        (poids 700)
```

### Pour `mobile_dudu_pro/assets/fonts/` :
```
✅ Poppins-Light.ttf       (poids 300)
✅ Poppins-Regular.ttf     (poids 400)
✅ Poppins-Medium.ttf      (poids 500)
✅ Poppins-SemiBold.ttf    (poids 600)
✅ Poppins-Bold.ttf        (poids 700)
```

**IMPORTANT :** Les dossiers `assets/fonts/` ont déjà été créés automatiquement !

---

## 🔧 ÉTAPE 3 : Installer les Dépendances

Après avoir copié les fichiers de police, exécutez ces commandes :

### Pour dudu_flutter :
```bash
cd dudu_flutter
flutter pub get
flutter clean
flutter pub get
```

### Pour mobile_dudu_pro :
```bash
cd mobile_dudu_pro
flutter pub get
flutter clean
flutter pub get
```

---

## ✨ ÉTAPE 4 : Vérifier l'Installation

La police Poppins sera automatiquement appliquée à **TOUTES les pages** car elle est définie dans le thème global.

### Test rapide :
```bash
cd dudu_flutter
flutter run
```

Vous devriez voir la police Poppins partout dans l'application ! 🎉

---

## 🎯 Utilisation de Poppins

### Police par défaut (automatique)
La police est déjà appliquée globalement via le thème. Aucun code supplémentaire nécessaire !

### Utilisation manuelle (si besoin)
```dart
Text(
  'Mon texte',
  style: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
  ),
)
```

### Poids disponibles :
- `FontWeight.w300` → Poppins-Light
- `FontWeight.w400` → Poppins-Regular (par défaut)
- `FontWeight.w500` → Poppins-Medium
- `FontWeight.w600` → Poppins-SemiBold
- `FontWeight.w700` → Poppins-Bold (ou `FontWeight.bold`)

---

## 🔍 Structure des Dossiers

```
DUDU/
├── dudu_flutter/
│   └── assets/
│       ├── fonts/
│       │   ├── Poppins-Light.ttf
│       │   ├── Poppins-Regular.ttf
│       │   ├── Poppins-Medium.ttf
│       │   ├── Poppins-SemiBold.ttf
│       │   └── Poppins-Bold.ttf
│       └── images/
│           └── logo_dudu_off.png
│
└── mobile_dudu_pro/
    └── assets/
        ├── fonts/
        │   ├── Poppins-Light.ttf
        │   ├── Poppins-Regular.ttf
        │   ├── Poppins-Medium.ttf
        │   ├── Poppins-SemiBold.ttf
        │   └── Poppins-Bold.ttf
        └── images/
            └── logo_dudu_off.png
```

---

## 🚨 Problèmes Courants

### Erreur : "Font family not found"
**Solution :** 
1. Vérifiez que les fichiers `.ttf` sont bien dans `assets/fonts/`
2. Exécutez `flutter clean` puis `flutter pub get`
3. Redémarrez l'application

### La police ne s'affiche pas
**Solution :**
1. Vérifiez l'orthographe : `fontFamily: 'Poppins'` (avec majuscule)
2. Assurez-vous que `pubspec.yaml` est bien indenté
3. Redémarrez l'application complètement

### Erreur de compilation
**Solution :**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📝 Notes

- ✅ La police Poppins est **gratuite** et open-source
- ✅ Elle est **optimisée** pour les écrans mobiles
- ✅ Elle supporte **tous les caractères** (français, wolof, etc.)
- ✅ Elle est **moderne** et très lisible
- ✅ Utilisée par des milliers d'applications populaires

---

## 🎨 Pourquoi Poppins ?

- **Moderne** : Design contemporain et élégant
- **Lisible** : Excellente lisibilité sur mobile
- **Polyvalente** : Fonctionne pour titres et textes
- **Professionnelle** : Utilisée par Google, Airbnb, etc.
- **Légère** : Ne ralentit pas l'application

---

**Créé le :** 27 octobre 2025
**Couleur principale :** #0d5d36 (Vert DUDU)
**Police :** Poppins
