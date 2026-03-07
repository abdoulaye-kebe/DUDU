# 🗄️ Configuration MongoDB Local

## ✅ Configuration Actuelle

Votre backend est **déjà configuré** pour utiliser MongoDB local par défaut :

```javascript
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu')
```

Cela signifie que si vous n'avez pas de fichier `.env`, MongoDB utilisera automatiquement :
- **Host** : `localhost`
- **Port** : `27017`
- **Base de données** : `dudu`

## 📋 Étape 1 : Vérifier si MongoDB est Installé

### Sur macOS :

```bash
# Vérifier si MongoDB est installé
brew list mongodb-community 2>/dev/null || echo "MongoDB non installé"

# Ou vérifier si le service tourne
brew services list | grep mongodb
```

### Installer MongoDB (si nécessaire) :

```bash
# Installer MongoDB avec Homebrew
brew tap mongodb/brew
brew install mongodb-community

# Démarrer MongoDB
brew services start mongodb-community
```

## 📋 Étape 2 : Créer le Fichier .env (Optionnel)

Le fichier `.env` est optionnel si MongoDB tourne sur `localhost:27017`.

Créer `backend/.env` :

```bash
cd backend
touch .env
```

Contenu minimal pour MongoDB local :

```env
# Configuration de base
NODE_ENV=development
PORT=3000
API_VERSION=v1

# MongoDB Local
MONGODB_URI=mongodb://localhost:27017/dudu

# JWT Configuration
JWT_SECRET=dudu-super-secret-jwt-key-2024-development
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# Socket.io Configuration
SOCKET_CORS_ORIGIN=http://localhost:3000
```

## 🚀 Étape 3 : Démarrer MongoDB Local

### Si MongoDB est installé via Homebrew :

```bash
# Démarrer le service MongoDB
brew services start mongodb-community

# Vérifier qu'il tourne
brew services list | grep mongodb
```

### Si MongoDB est installé autrement :

```bash
# Démarrer MongoDB manuellement
mongod --config /usr/local/etc/mongod.conf

# Ou simplement (avec config par défaut)
mongod
```

## ✅ Étape 4 : Tester la Connexion

```bash
cd backend
npm start
```

Vous devriez voir :
```
✅ Connexion à MongoDB réussie
🚀 Serveur DUDU démarré sur le port 3000
```

## 🔍 Vérifier que MongoDB Fonctionne

```bash
# Se connecter à MongoDB avec le shell
mongosh

# Dans le shell MongoDB :
use dudu
show collections
```

## ⚠️ Problèmes Courants

### Erreur : "Connection refused"
→ MongoDB n'est pas démarré
**Solution** : `brew services start mongodb-community`

### Erreur : "Port 27017 already in use"
→ MongoDB tourne déjà
**Solution** : C'est normal, continuez

### Erreur : "command not found: mongod"
→ MongoDB n'est pas installé
**Solution** : `brew install mongodb-community`

## 👥 Collaboration avec MongoDB Local

Si votre collaborateur veut utiliser MongoDB local aussi :

1. **Installation** : Installer MongoDB localement
2. **Démarrer** : `brew services start mongodb-community`
3. **Utiliser** : Le backend se connectera automatiquement à `localhost:27017`

**Note** : Pour partager les données, utilisez plutôt MongoDB Atlas (cloud) ou exportez/importez les données.

---

**Votre configuration actuelle fonctionne déjà avec MongoDB local !** ✅







