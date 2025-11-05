# 📱 Guide de Déploiement APK - DUDU

## 🎯 Configuration IP Publique

**IP Publique:** `41.208.146.203`  
**Port Backend:** `3000`

---

## ✅ Modifications Appliquées

### 1. API Services - IP Publique Ajoutée

#### App Chauffeur (`mobile_dudu_pro/lib/services/api_service.dart`)
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api/v1';  // Web
  } else if (kDebugMode) {
    return 'http://10.0.2.2:3000/api/v1';   // Émulateur
  } else {
    return 'http://41.208.146.203:3000/api/v1';  // ✅ IP Publique
  }
}
```

#### App Client (`dudu_flutter/lib/services/api_service.dart`)
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api/v1';  // Web
  } else if (kDebugMode) {
    return 'http://10.0.2.2:3000/api/v1';   // Émulateur
  } else {
    return 'http://41.208.146.203:3000/api/v1';  // ✅ IP Publique
  }
}
```

### 2. Pages de Téléchargement Créées

#### Page Client
**Fichier:** `backend/public/download-client.html`
- Design moderne vert DUDU
- Informations de l'app
- Bouton de téléchargement
- Liste des fonctionnalités

#### Page Chauffeur
**Fichier:** `backend/public/download-driver.html`
- Design moderne bleu Pro
- Badge "CHAUFFEUR"
- Informations de l'app
- Liste des fonctionnalités Pro

### 3. Backend Configuré

**Fichier:** `backend/src/server.js`
```javascript
// Servir les fichiers statiques
app.use(express.static('public'));
```

---

## 📦 Génération des APK

### Étape 1: Build App Client

```bash
cd dudu_flutter

# Build APK Release
flutter build apk --release

# Le fichier sera dans:
# build/app/outputs/flutter-apk/app-release.apk

# Copier vers le dossier public
copy build\app\outputs\flutter-apk\app-release.apk ..\backend\public\downloads\dudu-client.apk
```

### Étape 2: Build App Chauffeur

```bash
cd mobile_dudu_pro

# Build APK Release
flutter build apk --release

# Le fichier sera dans:
# build/app/outputs/flutter-apk/app-release.apk

# Copier vers le dossier public
copy build\app\outputs\flutter-apk\app-release.apk ..\backend\public\downloads\dudu-driver.apk
```

---

## 🌐 URLs de Téléchargement

Une fois le backend démarré:

### Client
```
http://41.208.146.203:3000/download-client.html
```

### Chauffeur
```
http://41.208.146.203:3000/download-driver.html
```

### Téléchargement Direct APK

**Client:**
```
http://41.208.146.203:3000/downloads/dudu-client.apk
```

**Chauffeur:**
```
http://41.208.146.203:3000/downloads/dudu-driver.apk
```

---

## 🚀 Démarrage du Backend

```bash
cd backend

# Démarrer le serveur
npm run dev

# Le serveur écoute sur 0.0.0.0:3000
# Accessible depuis n'importe quel appareil via 41.208.146.203:3000
```

**Vérification:**
```bash
# Depuis un autre appareil
curl http://41.208.146.203:3000/api/health
```

---

## 📱 Test sur Appareil Android

### 1. Télécharger l'APK

Sur votre téléphone Android:
1. Ouvrir le navigateur
2. Aller sur: `http://41.208.146.203:3000/download-client.html`
3. Cliquer sur "Télécharger l'APK"
4. Autoriser l'installation depuis des sources inconnues
5. Installer l'APK

### 2. Tester la Connexion

1. Ouvrir l'app DUDU
2. Se connecter avec:
   - **Client:** Téléphone + Mot de passe
   - **Chauffeur:** `776862514` / `Azerty123`
3. Vérifier que l'app se connecte au backend

---

## 🔧 Configuration Réseau

### Pare-feu Windows

Autoriser le port 3000:
```powershell
# Ouvrir PowerShell en Admin
New-NetFirewallRule -DisplayName "DUDU Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Vérifier l'IP Publique

```bash
ipconfig

# Chercher "Carte Ethernet Ethernet 6"
# Adresse IPv4: 41.208.146.203
```

### Test de Connectivité

Depuis un autre appareil sur le même réseau:
```bash
ping 41.208.146.203
curl http://41.208.146.203:3000/api/health
```

---

## 📋 Checklist Déploiement

### Avant de Build

- [ ] IP publique ajoutée dans `api_service.dart` (client)
- [ ] IP publique ajoutée dans `api_service.dart` (chauffeur)
- [ ] Backend configuré pour servir les fichiers statiques
- [ ] Dossier `public/downloads` créé

### Build APK

- [ ] `flutter build apk --release` pour client
- [ ] `flutter build apk --release` pour chauffeur
- [ ] APK client copié dans `backend/public/downloads/dudu-client.apk`
- [ ] APK chauffeur copié dans `backend/public/downloads/dudu-driver.apk`

### Déploiement

- [ ] Backend démarré (`npm run dev`)
- [ ] Port 3000 ouvert dans le pare-feu
- [ ] Test de `http://41.208.146.203:3000/api/health`
- [ ] Pages de téléchargement accessibles
- [ ] APK téléchargeables

### Test

- [ ] Télécharger APK client depuis téléphone
- [ ] Installer et tester connexion client
- [ ] Télécharger APK chauffeur depuis téléphone
- [ ] Installer et tester connexion chauffeur
- [ ] Vérifier profil, statistiques, etc.

---

## 🎨 Design des Pages

### Page Client
- **Couleur:** Vert DUDU (#0d5d36 → #10b981)
- **Logo:** Rond avec "D"
- **Fonctionnalités:** 4 items avec icônes
- **Responsive:** Mobile-first

### Page Chauffeur
- **Couleur:** Bleu Pro (#1e40af → #3b82f6)
- **Badge:** "CHAUFFEUR" orange
- **Fonctionnalités:** 5 items avec icônes
- **Responsive:** Mobile-first

---

## 🔒 Sécurité

### Pour la Production

1. **Signer les APK:**
```bash
# Créer un keystore
keytool -genkey -v -keystore dudu-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dudu

# Build APK signé
flutter build apk --release --split-per-abi
```

2. **HTTPS:**
- Utiliser un certificat SSL
- Configurer nginx comme reverse proxy
- Rediriger HTTP → HTTPS

3. **Domaine:**
- Acheter un domaine (ex: dudu.sn)
- Pointer vers 41.208.146.203
- Utiliser `https://dudu.sn` au lieu de l'IP

---

## 📊 Structure des Fichiers

```
DUDU/
├── backend/
│   ├── public/
│   │   ├── download-client.html      ✅ Page client
│   │   ├── download-driver.html      ✅ Page chauffeur
│   │   └── downloads/
│   │       ├── README.md             ✅ Instructions
│   │       ├── dudu-client.apk       ⏳ À générer
│   │       └── dudu-driver.apk       ⏳ À générer
│   └── src/
│       └── server.js                 ✅ Configuré
├── dudu_flutter/
│   └── lib/services/
│       └── api_service.dart          ✅ IP publique
└── mobile_dudu_pro/
    └── lib/services/
        └── api_service.dart          ✅ IP publique
```

---

## 🐛 Dépannage

### APK ne se télécharge pas

1. Vérifier que le backend est démarré
2. Vérifier que les APK existent dans `public/downloads/`
3. Vérifier les permissions du dossier

### App ne se connecte pas

1. Vérifier l'IP publique: `ipconfig`
2. Vérifier que le backend est accessible: `curl http://41.208.146.203:3000/api/health`
3. Vérifier le pare-feu Windows
4. Vérifier que l'appareil est sur le même réseau (ou que l'IP est publique)

### Erreur 401 sur le profil

1. Vérifier que le token est bien stocké
2. Vérifier que la route `/profile` existe
3. Vérifier les logs du backend

---

## ✅ Résumé

### Fait ✅
1. IP publique `41.208.146.203` ajoutée dans les deux apps
2. Pages de téléchargement HTML créées
3. Backend configuré pour servir les fichiers statiques
4. Structure de dossiers créée

### À Faire ⏳
1. Build les APK en mode release
2. Copier les APK dans `backend/public/downloads/`
3. Démarrer le backend
4. Tester le téléchargement depuis un téléphone
5. Tester la connexion des apps

---

**Prochaine étape:** Build les APK et tester! 🚀
