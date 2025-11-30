# Configuration de l'environnement DUDU

## Instructions pour votre collègue développeur

### 1. Créer le fichier .env

Copiez le fichier `env.example` vers `.env` dans le dossier `backend/` :

```bash
cd backend
cp env.example .env
```

### 2. Configuration de la base de données

#### Option A : MongoDB Local (Recommandé pour le développement)

Si vous avez MongoDB installé localement, utilisez cette configuration dans votre `.env` :

```env
MONGODB_URI=mongodb://localhost:27017/dudu
MONGODB_TEST_URI=mongodb://localhost:27017/dudu_test
```

**Installation de MongoDB :**
- **macOS** : `brew install mongodb-community`
- **Ubuntu** : `sudo apt install mongodb`
- **Windows** : Télécharger depuis [mongodb.com](https://www.mongodb.com/try/download/community)

#### Option B : MongoDB Atlas (Cloud)

Si vous préférez utiliser MongoDB Atlas (cloud), remplacez l'URI par :

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/dudu?retryWrites=true&w=majority
```

**Étapes pour MongoDB Atlas :**
1. Créer un compte sur [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Créer un cluster gratuit
3. Créer un utilisateur de base de données
4. Obtenir l'URI de connexion
5. Remplacer dans le fichier `.env`

### 3. Configuration des APIs externes

#### Google Maps API (Déjà configuré)
```env
GOOGLE_MAPS_API_KEY=AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA
```

#### Autres APIs (Optionnelles pour le développement)
```env
# Paiements mobiles
ORANGE_MONEY_API_KEY=your-orange-money-api-key
WAVE_API_KEY=your-wave-api-key
FREE_MONEY_API_KEY=your-free-money-api-key

# SMS
SMS_API_KEY=your-sms-api-key

# Email
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 4. Installation et démarrage

```bash
# Installer les dépendances
npm install

# Démarrer le serveur
npm start
# ou
node start.js
```

### 5. Vérification de la connexion

Le serveur devrait démarrer sur `http://localhost:3000` et afficher :
```
✅ MongoDB connecté: localhost
🚀 Serveur démarré sur le port 3000
```

### 6. Structure de la base de données

Les collections suivantes seront créées automatiquement :
- `users` - Utilisateurs (clients et chauffeurs)
- `drivers` - Profils des chauffeurs
- `rides` - Courses/trajets
- `payments` - Paiements
- `subscriptions` - Abonnements

### 7. Données de test

Pour ajouter des données de test, vous pouvez utiliser les endpoints API :
- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/rides` - Créer une course

### 8. Sécurité

⚠️ **Important** : Ne jamais commiter le fichier `.env` dans Git. Il contient des informations sensibles.

Le fichier `.env` est déjà dans `.gitignore` pour éviter les fuites de données.

### 9. Support

Si vous rencontrez des problèmes :
1. Vérifiez que MongoDB est démarré : `mongod`
2. Vérifiez les logs du serveur
3. Testez la connexion MongoDB : `mongosh`

### 10. Variables d'environnement importantes

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `NODE_ENV` | Environnement | `development` |
| `PORT` | Port du serveur | `3000` |
| `MONGODB_URI` | URI MongoDB | `mongodb://localhost:27017/dudu` |
| `JWT_SECRET` | Clé secrète JWT | `dudu-super-secret-jwt-key-2024-development` |
| `GOOGLE_MAPS_API_KEY` | Clé API Google Maps | Déjà configurée |









