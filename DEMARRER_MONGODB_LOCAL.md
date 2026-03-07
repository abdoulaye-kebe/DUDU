# 🚀 Démarrer MongoDB Local pour DUDU

## ✅ Configuration Actuelle

Votre backend est **déjà configuré** pour MongoDB local :
- **URI** : `mongodb://localhost:27017/dudu`
- **Fichier `.env`** : Créé avec la configuration locale

## 📋 Démarrer MongoDB

### Option 1 : Avec Homebrew (macOS) - Recommandé

```bash
# Vérifier si MongoDB est installé
brew list mongodb-community 2>/dev/null || echo "MongoDB non installé"

# Si non installé, installer :
brew tap mongodb/brew
brew install mongodb-community

# Démarrer MongoDB
brew services start mongodb-community

# Vérifier qu'il tourne
brew services list | grep mongodb
```

Vous devriez voir : `mongodb-community   started`

### Option 2 : Vérifier si MongoDB tourne déjà

```bash
# Vérifier si MongoDB écoute sur le port 27017
lsof -i :27017 | grep LISTEN || echo "MongoDB non démarré"
```

## 🧪 Tester la Connexion

```bash
# Se connecter au shell MongoDB
mongosh

# Dans le shell, tester :
use dudu
show collections
exit
```

## 🚀 Démarrer le Backend

```bash
cd backend
npm start
```

Vous devriez voir :
```
✅ Connexion à MongoDB réussie
🚀 Serveur DUDU démarré sur le port 3000
```

## ✅ Vérification Complète

1. **MongoDB tourne** : `brew services list | grep mongodb`
2. **Backend connecté** : Message "✅ Connexion à MongoDB réussie"
3. **API accessible** : `curl http://localhost:3000/api/health`

## 📱 Pour votre Collaborateur

Pour que votre collaborateur utilise MongoDB local aussi :

1. **Installer MongoDB** :
   ```bash
   brew tap mongodb/brew
   brew install mongodb-community
   brew services start mongodb-community
   ```

2. **Créer le fichier `.env`** :
   ```bash
   cd backend
   cp .env.example .env  # Si vous avez partagé .env.example
   ```

3. **Utiliser la même configuration** : `mongodb://localhost:27017/dudu`

## ⚠️ Si MongoDB n'est pas Installé

### Installation complète sur macOS :

```bash
# 1. Installer Homebrew (si pas déjà fait)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Ajouter le tap MongoDB
brew tap mongodb/brew

# 3. Installer MongoDB
brew install mongodb-community

# 4. Démarrer MongoDB
brew services start mongodb-community

# 5. Vérifier
mongosh --version
```

---

**Une fois MongoDB démarré, votre backend se connectera automatiquement !** ✅







