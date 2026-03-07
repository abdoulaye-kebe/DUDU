# 🗄️ Migration vers MongoDB Atlas (Cloud Gratuit)

## ✅ Pourquoi MongoDB Atlas au lieu de Firebase ?

1. **Cohérence** : Votre backend est déjà en Node.js/Express avec MongoDB
2. **Gratuit** : Plan M0 gratuit avec 512 MB (suffisant pour développement)
3. **Simplicité** : Pas besoin de changer toute l'architecture
4. **Collaboration** : Votre collaborateur pourra utiliser la même base de données

## 📋 Ce qui a été modifié

✅ Retiré Firebase de `pubspec.yaml` (dépendances)
✅ Retiré Firebase de `main.dart` (initialisation)
✅ Service Firebase conservé (optionnel pour plus tard si besoin)

## 🚀 Configuration MongoDB Atlas

### Étape 1 : Créer un compte (2 minutes)

1. Allez sur : https://www.mongodb.com/cloud/atlas/register
2. Créez un compte gratuit
3. Créez un cluster **M0 FREE**

### Étape 2 : Configurer l'accès (3 minutes)

1. **Database Access** : Créez un utilisateur avec mot de passe
2. **Network Access** : Autorisez `0.0.0.0/0` (tous les IPs) pour le développement

### Étape 3 : Obtenir la Connection String

1. Cliquez sur **"Connect"** sur votre cluster
2. Choisissez **"Connect your application"**
3. Sélectionnez **Node.js** / **Version 5.5+**
4. Copiez la connection string qui ressemble à :
   ```
   mongodb+srv://username:password@cluster.mongodb.net/dudu?retryWrites=true&w=majority
   ```

### Étape 4 : Configurer le Backend

1. **Créez le fichier `.env` dans `backend/`** :
   ```bash
   cd backend
   cp env.example .env
   ```

2. **Modifiez `backend/.env`** :
   ```env
   NODE_ENV=development
   PORT=3000
   API_VERSION=v1

   # MongoDB Atlas (Cloud gratuit)
   MONGODB_URI=mongodb+srv://votre_username:votre_password@votre-cluster.xxxxx.mongodb.net/dudu?retryWrites=true&w=majority

   # JWT Configuration
   JWT_SECRET=dudu-super-secret-jwt-key-2024-development
   JWT_EXPIRES_IN=7d
   JWT_REFRESH_EXPIRES_IN=30d

   # Socket.io Configuration
   SOCKET_CORS_ORIGIN=http://localhost:3000
   ```

3. **Remplacez** dans `MONGODB_URI` :
   - `votre_username` par votre nom d'utilisateur MongoDB Atlas
   - `votre_password` par votre mot de passe MongoDB Atlas
   - `votre-cluster.xxxxx.mongodb.net` par votre URL de cluster

### Étape 5 : Tester la Connexion

```bash
cd backend
npm start
```

Vous devriez voir :
```
✅ Connexion à MongoDB réussie
🚀 Serveur DUDU démarré sur le port 3000
```

## 📱 Application Mobile

L'application mobile reste connectée au backend via l'API REST. Aucun changement nécessaire dans l'app mobile.

L'URL de l'API est configurée automatiquement dans `api_service.dart` :
- **iOS Simulator** : `http://127.0.0.1:3000/api/v1`
- **Android Emulator** : `http://10.0.2.2:3000/api/v1`

## 👥 Partage avec Votre Collaborateur

Une fois MongoDB Atlas configuré, votre collaborateur peut :

1. **Utiliser la même connection string** (si vous partagez les credentials)
2. **Ou créer son propre utilisateur** dans MongoDB Atlas :
   - Allez dans "Database Access"
   - Ajoutez un nouvel utilisateur
   - Partagez la connection string avec le nouveau username/password

## ✅ Avantages de MongoDB Atlas

- ✅ **Gratuit** (plan M0)
- ✅ **Cloud** : Accessible depuis n'importe où
- ✅ **Sauvegardes automatiques**
- ✅ **Compatible** avec votre code backend existant
- ✅ **Pas de migration de code nécessaire**

## 📚 Documentation Complète

Voir `GUIDE_MONGODB_ATLAS_GRATUIT.md` pour le guide détaillé.

---

**Résumé** : Remplacez juste la connection string MongoDB dans `backend/.env` et tout fonctionnera ! 🎉







