# 🚗 DUDU Admin Dashboard

Interface web d'administration pour la plateforme DUDU.

## 🚀 Démarrage

### Installation
```bash
npm install
```

### Développement
```bash
npm run dev
```
L'application sera accessible sur http://localhost:3001

### Production
```bash
npm run build
npm run preview
```

## 📦 Technologies

- **React** - Framework UI
- **Vite** - Build tool
- **Axios** - Client HTTP
- **Socket.io** - Communication temps réel
- **Recharts** - Graphiques et analytics

## 🎨 Fonctionnalités

### Tableau de bord
- 📊 Statistiques en temps réel
- 💰 Revenus et transactions
- 🚗 Courses actives
- 🚕 Chauffeurs en ligne

### Gestion des chauffeurs
- ✅ Validation des inscriptions
- 🚫 Suspension/Réactivation
- 📊 Performance et notes
- 🗺️ Suivi GPS en temps réel

### Gestion des courses
- 🗺️ Monitoring en temps réel
- 📍 Tracking GPS
- 💬 Support client
- 📊 Historique détaillé

### Rapports et Analytics
- 📈 Graphiques de revenus
- 👥 Performance des chauffeurs
- 📊 Statistiques détaillées
- 📥 Export de données

## 🔐 Authentification

Utilisez un compte administrateur pour vous connecter.

## 🛠️ Configuration

Modifiez `src/services/api.js` pour configurer l'URL de l'API backend :
```javascript
const API_BASE_URL = 'http://localhost:8000/api/v1';
```

## 📱 Compatibilité

- Chrome (recommandé)
- Firefox
- Safari
- Edge

## 🤝 Support

Pour toute question, contactez l'équipe DUDU.

