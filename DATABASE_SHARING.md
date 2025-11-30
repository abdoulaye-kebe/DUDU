# 🔐 Configuration Base de Données - DUDU

## 📊 État actuel de votre base de données

### MongoDB Local
- **URI** : `mongodb://localhost:27017/dudu`
- **Statut** : ✅ Opérationnel
- **Collections** : 5 collections actives

### Collections et données

| Collection | Documents | Description |
|------------|-----------|-------------|
| `users` | 22 | Utilisateurs (clients et chauffeurs) |
| `drivers` | 11 | Profils des chauffeurs |
| `rides` | 0 | Courses/trajets |
| `payments` | ? | Paiements |
| `subscriptions` | ? | Abonnements |

## 🔧 Configuration pour votre collègue

### Option 1 : MongoDB Local (Recommandé)

**Avantages :**
- ✅ Gratuit
- ✅ Rapide
- ✅ Pas de limite de données
- ✅ Contrôle total

**Configuration :**
```env
MONGODB_URI=mongodb://localhost:27017/dudu
MONGODB_TEST_URI=mongodb://localhost:27017/dudu_test
```

**Installation :**
```bash
# macOS
brew install mongodb-community

# Ubuntu
sudo apt install mongodb

# Démarrer
mongod
```

### Option 2 : MongoDB Atlas (Cloud)

**Avantages :**
- ✅ Accessible de partout
- ✅ Sauvegarde automatique
- ✅ Scalabilité
- ✅ Monitoring intégré

**Configuration :**
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/dudu?retryWrites=true&w=majority
```

**Étapes :**
1. Créer un compte sur [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Créer un cluster gratuit (M0)
3. Créer un utilisateur de base de données
4. Obtenir l'URI de connexion
5. Remplacer dans le fichier `.env`

## 📋 Instructions de partage

### 1. Données existantes

**Votre collègue peut :**
- Utiliser la même base de données locale
- Créer sa propre base de données
- Utiliser MongoDB Atlas

### 2. Données de test

**Pour ajouter des données de test :**
```bash
# Via API
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Via MongoDB
mongosh dudu
db.users.insertOne({email: "test@example.com", name: "Test User"})
```

### 3. Sauvegarde des données

**Exporter les données :**
```bash
# Exporter toutes les collections
mongodump --db dudu --out backup/

# Exporter une collection spécifique
mongoexport --db dudu --collection users --out users.json
```

**Importer les données :**
```bash
# Importer toutes les collections
mongorestore --db dudu backup/dudu/

# Importer une collection spécifique
mongoimport --db dudu --collection users --file users.json
```

## 🔒 Sécurité

### Variables d'environnement
- ✅ `MONGODB_URI` - URI de connexion
- ✅ `JWT_SECRET` - Clé secrète JWT
- ✅ `GOOGLE_MAPS_API_KEY` - Clé API Google Maps

### Fichiers sensibles
- ❌ Ne jamais commiter `.env`
- ✅ Utiliser `env.example` comme template
- ✅ Changer les clés en production

## 🚀 Démarrage rapide

### 1. Vérifier MongoDB
```bash
mongosh --eval "db.runCommand('ping')"
```

### 2. Tester la connexion
```bash
cd backend
node -e "require('dotenv').config(); const mongoose = require('mongoose'); mongoose.connect(process.env.MONGODB_URI).then(() => console.log('✅ Connecté')).catch(err => console.error('❌ Erreur:', err.message));"
```

### 3. Démarrer le serveur
```bash
npm start
```

## 📊 Monitoring

### Vérifier les collections
```bash
mongosh dudu --eval "db.getCollectionNames()"
```

### Compter les documents
```bash
mongosh dudu --eval "db.users.countDocuments()"
mongosh dudu --eval "db.drivers.countDocuments()"
```

### Voir les données
```bash
mongosh dudu --eval "db.users.find().limit(5)"
mongosh dudu --eval "db.drivers.find().limit(5)"
```

## 🎯 Prochaines étapes

1. **Partager la configuration** avec votre collègue
2. **Choisir l'option MongoDB** (local ou Atlas)
3. **Configurer l'environnement** avec le fichier `.env`
4. **Tester la connexion** à la base de données
5. **Développer ensemble** les nouvelles fonctionnalités

---

**🗄️ Votre base de données est prête à être partagée !**









