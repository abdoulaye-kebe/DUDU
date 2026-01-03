# Configuration Admin Web DUDU

## 🌐 Domaines configurés

L'admin web DUDU est accessible via les domaines suivants :
- **Production principale :** https://dudugroup.sn
- **Alternatives :** http://dudugroup.sn, https://www.dudugroup.sn, http://www.dudugroup.sn
- **Anciens domaines :** https://admin.dudu.sn, https://dudu.sn

## 🔧 Configuration Backend (CORS)

Le backend autorise les requêtes depuis tous ces domaines.

**Fichier :** `backend/src/server.js`

```javascript
// CORS autorisé pour :
- https://dudu.sn
- https://admin.dudu.sn
- https://dudugroup.sn (PRINCIPAL)
- http://dudugroup.sn
- https://www.dudugroup.sn
- http://www.dudugroup.sn
```

## 📡 Configuration Frontend (Admin Web)

**Fichier :** `admin-web/src/config.js`

L'admin web détecte automatiquement l'environnement :

### En développement (localhost)
```javascript
API_BASE_URL = 'http://localhost:3000/api/v1'
SOCKET_URL = 'http://localhost:3000'
```

### En production (dudugroup.sn)
```javascript
API_BASE_URL = 'http://213.154.90.11:3000/api/v1'
SOCKET_URL = 'http://213.154.90.11:3000'
```

## ✅ Vérification

Pour vérifier que l'admin web se connecte correctement :

1. Ouvrir https://dudugroup.sn
2. Ouvrir la console du navigateur (F12)
3. Vérifier les logs :
```
🌐 Admin DUDU Configuration:
   Environment: PRODUCTION
   API URL: http://213.154.90.11:3000/api/v1
   Socket URL: http://213.154.90.11:3000
```

4. Vérifier qu'il n'y a pas d'erreurs CORS dans la console

## 🚨 Problèmes courants

### "Impossible de charger les données"
**Cause :** Erreur CORS ou backend non accessible

**Solutions :**
1. Vérifier que le backend est démarré sur 213.154.90.11:3000
2. Vérifier les logs du backend pour les erreurs CORS
3. Vérifier que le domaine est bien dans la liste CORS autorisée

### Stats affichent "0"
**Cause :** Pas de données dans la base de données ou erreur API

**Solutions :**
1. Vérifier la connexion MongoDB
2. Vérifier que des utilisateurs/chauffeurs/courses existent
3. Tester l'API directement : `curl http://213.154.90.11:3000/api/v1/admin/dashboard`

## 🔄 Déploiement

Après modification de la configuration :

### Backend
```bash
cd backend
# Redémarrer le serveur
pm2 restart dudu-backend
# ou
npm run dev
```

### Admin Web
```bash
cd admin-web
npm run build
# Déployer le dossier dist/ sur le serveur web
```

## 📊 Endpoints API disponibles

- `GET /api/v1/admin/dashboard` - Statistiques générales
- `GET /api/v1/admin/drivers` - Liste des chauffeurs
- `GET /api/v1/admin/users` - Liste des clients
- `GET /api/v1/admin/rides` - Liste des courses
- `GET /api/v1/admin/rides/cancelled` - Historique annulations
- `GET /api/v1/admin/payments` - Liste des paiements

## 🔐 Authentification

L'admin web utilise JWT stocké dans localStorage :
- Clé : `admin_token`
- Envoyé dans header : `Authorization: Bearer <token>`

## 📝 Notes importantes

1. **CORS est crucial** : Sans CORS correctement configuré, l'admin web ne peut pas charger les données
2. **Détection automatique** : L'admin web détecte automatiquement s'il est en dev ou prod
3. **Pas de HTTPS sur API** : L'API backend utilise HTTP (pas HTTPS) sur le port 3000
4. **Domaine principal** : dudugroup.sn est le domaine principal de l'admin web
