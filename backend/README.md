# DUDU Backend API

Backend API pour la plateforme de transport DUDU au Sénégal.

## 🚀 Démarrage Rapide

### Prérequis
- Node.js 18+
- MongoDB
- Redis (optionnel)

### Installation

1. Installer les dépendances :
```bash
npm install
```

2. Configurer les variables d'environnement :
```bash
cp .env.example .env
# Éditer .env (MongoDB, JWT, Wave, etc.)
```

3. Démarrer le serveur :
```bash
# Développement
npm run dev

# Production
npm start
```

## 📁 Structure du Projet

```
src/
├── config/          # Configuration de la base de données
├── controllers/     # Contrôleurs (à créer)
├── middleware/      # Middlewares d'authentification
├── models/          # Modèles Mongoose
├── routes/          # Routes API
├── services/        # Services métier (à créer)
├── socket/          # Gestion Socket.io
├── utils/           # Utilitaires (à créer)
└── server.js        # Point d'entrée principal
```

## 🔗 Endpoints API

### Authentification
- `POST /api/v1/auth/register` - Inscription utilisateur
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/auth/verify` - Vérification SMS
- `GET /api/v1/auth/me` - Profil utilisateur

### Utilisateurs
- `GET /api/v1/users/profile` - Profil utilisateur
- `PUT /api/v1/users/profile` - Mettre à jour le profil
- `GET /api/v1/users/rides` - Historique des courses
- `GET /api/v1/users/stats` - Statistiques utilisateur

### Chauffeurs
- `POST /api/v1/drivers/register` - Inscription chauffeur
- `GET /api/v1/drivers/profile` - Profil chauffeur
- `PUT /api/v1/drivers/location` - Mettre à jour la localisation
- `GET /api/v1/drivers/nearby-rides` - Courses à proximité
- `GET /api/v1/drivers/earnings` - Revenus

### Courses
- `POST /api/v1/rides/request` - Demander une course
- `POST /api/v1/rides/:id/accept` - Accepter une course
- `POST /api/v1/rides/:id/complete` - Terminer une course
- `POST /api/v1/rides/:id/cancel` - Annuler une course

### Paiements
- `POST /api/v1/payments/initiate` - Initier un paiement
- `POST /api/v1/payments/:id/confirm` - Confirmer un paiement
- `GET /api/v1/payments` - Historique des paiements

### Abonnements
- `GET /api/v1/subscriptions/plans` - Plans disponibles
- `POST /api/v1/subscriptions/purchase` - Acheter un abonnement
- `GET /api/v1/subscriptions/current` - Abonnement actuel

### Administration
- `GET /api/v1/admin/dashboard` - Tableau de bord admin
- `GET /api/v1/admin/users` - Liste des utilisateurs
- `GET /api/v1/admin/drivers` - Liste des chauffeurs
- `GET /api/v1/admin/rides` - Liste des courses

## 🔌 WebSocket Events

### Chauffeurs
- `update-location` - Mettre à jour la localisation
- `update-status` - Changer le statut (en ligne/hors ligne)
- `accept-ride` - Accepter une course
- `driver-arrived` - Signaler l'arrivée
- `start-ride` - Commencer la course
- `complete-ride` - Terminer la course

### Passagers
- `request-ride` - Demander une course
- `track-ride` - Suivre une course en temps réel
- `cancel-ride` - Annuler une course

## 🗄️ Modèles de Données

### User
- Informations personnelles
- Préférences de paiement
- Statistiques d'utilisation

### Driver
- Informations professionnelles
- Véhicule
- Abonnement
- Localisation en temps réel

### Ride
- Itinéraire (départ/arrivée)
- Tarification personnalisée
- Statut de la course
- Suivi en temps réel

### Payment
- Paiements mobile money
- Paiements en espèces
- Remboursements

### Subscription
- Forfaits chauffeurs
- Renouvellement automatique
- Historique des abonnements

## 🔐 Sécurité

- Authentification JWT
- Validation des données avec express-validator
- Limitation du taux de requêtes
- Middleware de sécurité Helmet
- CORS configuré

## 📱 Intégrations

- **Mobile Money** : Orange Money, Wave, Free Money
- **Cartes** : Google Maps API
- **SMS** : API de notification
- **Géolocalisation** : MongoDB Geospatial

## 🚀 Déploiement (production, Git pull)

1. Sur le serveur, le dépôt doit pointer vers ce repo (ex. `~/DUDU` ou `~/dudu-backend`).
2. **Une seule fois** : `cp .env.example .env` puis remplir `MONGODB_URI`, `JWT_SECRET`, `WAVE_*`, `ADMIN_*`, etc.
3. **À chaque mise à jour** (monorepo : dépôt Git à la racine du projet) :
   ```bash
   cd /chemin/vers/DUDU
   ./scripts/prod-update-backend.sh
   ```
   Cela fait `git pull`, puis `npm ci` dans `backend/`, puis **`pm2 reload`** du processus **`dudu-bac`** (`ecosystem.config.cjs`).

   Si le backend est un **clone séparé** (dossier `backend/` seul avec son `.git`) :
   ```bash
   cd /chemin/vers/backend
   ./scripts/prod-update.sh
   ```

**Premier lancement PM2** (si le process n’existe pas encore) :
```bash
cd backend
npm install --omit=dev
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup   # optionnel — redémarrage auto au boot
```

**Fichiers versionnés utiles en prod** : `ecosystem.config.cjs`, `scripts/prod-update.sh`, `.env.example` (modèle uniquement — pas les secrets).

### Variables d'environnement

Voir **`/.env.example`** à la racine du dossier `backend` (liste à jour : Wave, courses planifiées, admin, etc.).

### Docker (optionnel)

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## 📊 Monitoring

- Logs avec Morgan
- Health check : `GET /api/health`
- Métriques de performance
- Gestion d'erreurs centralisée

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature
3. Commit les changements
4. Push vers la branche
5. Ouvrir une Pull Request

## 📄 Licence

MIT License - voir le fichier LICENSE pour plus de détails.




