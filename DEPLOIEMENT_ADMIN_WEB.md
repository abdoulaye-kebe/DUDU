# 🚀 Guide de Déploiement Admin Web DUDU

## ⚠️ IMPORTANT - À FAIRE PAR VOTRE BINÔME

Ce guide est destiné à la personne qui a accès au serveur (213.154.90.11).

---

## 📋 Modifications effectuées

### 1. Configuration CORS Backend
Le backend autorise maintenant les requêtes depuis **dudugroup.sn**

**Fichier modifié :** `backend/src/server.js`

### 2. Configuration Admin Web
L'admin web pointe automatiquement vers le serveur de production quand accédé depuis dudugroup.sn

**Fichier modifié :** `admin-web/src/config.js`

### 3. Nouveaux endpoints API
- `/api/v1/admin/rides` - Amélioré avec filtres avancés
- `/api/v1/admin/rides/cancelled` - Historique des annulations

**Fichier modifié :** `backend/src/routes/admin.js`

---

## 🔧 Étapes de déploiement

### ÉTAPE 1 : Mettre à jour le code sur le serveur

```bash
# Se connecter au serveur
ssh user@213.154.90.11

# Aller dans le dossier du projet
cd /chemin/vers/DUDU

# Récupérer les dernières modifications
git pull origin main
# OU si vous utilisez une autre branche
git pull origin <nom-de-la-branche>
```

### ÉTAPE 2 : Redémarrer le backend

#### Option A : Avec PM2 (recommandé)
```bash
cd backend

# Installer les dépendances si nécessaire
npm install

# Redémarrer le backend
pm2 restart dudu-backend

# Vérifier que c'est bien démarré
pm2 status
pm2 logs dudu-backend --lines 50
```

#### Option B : Sans PM2
```bash
cd backend

# Arrêter le processus actuel (Ctrl+C si en cours)
# Puis redémarrer
npm run dev
# OU en production
npm start
```

### ÉTAPE 3 : Rebuilder et déployer l'admin web

```bash
cd admin-web

# Installer les dépendances
npm install

# Builder pour la production
npm run build

# Le dossier dist/ contient maintenant l'admin web
# Déployer ce dossier sur votre serveur web (Nginx, Apache, etc.)
```

#### Configuration Nginx pour dudugroup.sn

Créer ou modifier `/etc/nginx/sites-available/dudugroup.sn` :

```nginx
server {
    listen 80;
    server_name dudugroup.sn www.dudugroup.sn;

    root /var/www/dudu-admin/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache des assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Activer le site :
```bash
sudo ln -s /etc/nginx/sites-available/dudugroup.sn /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### ÉTAPE 4 : Vérifier que tout fonctionne

#### 4.1 Vérifier le backend
```bash
# Tester l'API
curl http://213.154.90.11:3000/api/v1/health

# Devrait retourner :
# {"status":"OK","message":"DUDU API est opérationnelle",...}
```

#### 4.2 Vérifier l'admin web
1. Ouvrir https://dudugroup.sn dans le navigateur
2. Ouvrir la console (F12)
3. Vérifier les logs :
```
🌐 Admin DUDU Configuration:
   Environment: PRODUCTION
   API URL: http://213.154.90.11:3000/api/v1
   Socket URL: http://213.154.90.11:3000
```

4. Vérifier qu'il n'y a **PAS** d'erreurs CORS dans la console
5. Les statistiques devraient se charger (Total Clients, Chauffeurs Actifs, etc.)

---

## ✅ Checklist de vérification

- [ ] Code mis à jour sur le serveur (git pull)
- [ ] Backend redémarré (pm2 restart ou npm start)
- [ ] Admin web rebuilder (npm run build)
- [ ] Dossier dist/ déployé sur le serveur web
- [ ] Nginx configuré et rechargé
- [ ] API accessible (curl http://213.154.90.11:3000/api/v1/health)
- [ ] Admin web accessible (https://dudugroup.sn)
- [ ] Pas d'erreurs CORS dans la console
- [ ] Statistiques se chargent correctement
- [ ] Page Chauffeurs affiche les données
- [ ] Page Courses affiche les données

---

## 🚨 Résolution de problèmes

### Problème : "Impossible de charger les données"

**Vérifications :**
```bash
# 1. Backend est-il démarré ?
pm2 status
# ou
ps aux | grep node

# 2. Backend écoute-t-il sur le port 3000 ?
netstat -tulpn | grep 3000
# ou
lsof -i :3000

# 3. MongoDB est-il connecté ?
pm2 logs dudu-backend | grep MongoDB
```

**Solution :**
```bash
# Redémarrer le backend
pm2 restart dudu-backend

# Vérifier les logs
pm2 logs dudu-backend --lines 100
```

### Problème : Erreurs CORS dans la console

**Message d'erreur typique :**
```
Access to XMLHttpRequest at 'http://213.154.90.11:3000/api/v1/admin/dashboard' 
from origin 'https://dudugroup.sn' has been blocked by CORS policy
```

**Solution :**
1. Vérifier que le fichier `backend/src/server.js` contient bien dudugroup.sn dans la config CORS
2. Redémarrer le backend : `pm2 restart dudu-backend`
3. Vider le cache du navigateur (Ctrl+Shift+Delete)
4. Recharger la page (Ctrl+F5)

### Problème : Stats affichent "0" partout

**Cause :** Base de données vide ou non connectée

**Vérifications :**
```bash
# Se connecter à MongoDB
mongo
# ou
mongosh

# Utiliser la base DUDU
use dudu

# Compter les utilisateurs
db.users.countDocuments()

# Compter les chauffeurs
db.drivers.countDocuments()

# Compter les courses
db.rides.countDocuments()
```

**Si les collections sont vides :**
C'est normal si personne ne s'est encore inscrit. Les stats seront à 0 jusqu'à ce que :
- Des clients s'inscrivent via l'app mobile
- Des chauffeurs s'inscrivent via DUDU Pro
- Des courses soient créées

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifier les logs du backend :**
```bash
pm2 logs dudu-backend --lines 200
```

2. **Vérifier la console du navigateur :**
- Ouvrir F12
- Onglet Console
- Chercher les erreurs en rouge

3. **Tester l'API directement :**
```bash
# Dashboard
curl http://213.154.90.11:3000/api/v1/admin/dashboard

# Chauffeurs
curl http://213.154.90.11:3000/api/v1/admin/drivers

# Courses
curl http://213.154.90.11:3000/api/v1/admin/rides
```

---

## 🎯 Résultat attendu

Après le déploiement, l'admin web sur **https://dudugroup.sn** devrait :

✅ Se charger sans erreur  
✅ Afficher les statistiques en temps réel  
✅ Afficher la liste des chauffeurs (s'il y en a)  
✅ Afficher la liste des clients (s'il y en a)  
✅ Afficher la liste des courses (s'il y en a)  
✅ Permettre de filtrer les courses par statut  
✅ Afficher l'historique des annulations  

---

**Date de dernière mise à jour :** 3 janvier 2026  
**Version backend :** v1  
**Version admin web :** v1
