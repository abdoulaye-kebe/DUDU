# Déploiement de l’admin DUDU (admin.dudugroup.sn)

## Connexion admin : « Erreur de connexion » alors que le serveur répond en curl

Souvent dû au **contenu mixte** : le build embarquait `VITE_API_BASE_URL=http://213.154.90.11/...` (HTTP). Depuis **`https://admin.dudugroup.sn`**, le navigateur **bloque** les appels vers une API en HTTP → échec réseau sans message serveur.

**Correctif :** `.env.production` avec **`https://www.dudugroup.sn`**, puis `npm run build` et redéploiement du `dist/`. Le code ignore aussi les `VITE_*` en `http://` non-local (sauf rebuild, mettre à jour le dépôt).

---

## Pourquoi la page est blanche ?

Si vous voyez une **page blanche** sur admin.dudugroup.sn, c’est en général parce que le serveur sert les **fichiers sources** (dont `index.html` qui charge `/src/main.jsx`) au lieu des **fichiers compilés**.  
Il faut déployer le **build** (dossier `dist/`), pas le code source.

## Étapes de déploiement

### 1. Build en local

```bash
cd admin-web
npm ci
npm run build
```

Cela crée le dossier **`dist/`** avec notamment :
- `index.html`
- `assets/` (JS et CSS avec noms du type `index-xxxx.js`)

### 2. Déployer le contenu de `dist/` sur le serveur

- Copiez **tout le contenu** de `dist/` (pas le dossier `dist` lui-même) vers la racine du site admin sur le serveur (ex. répertoire de `admin.dudugroup.sn`).
- Ne déployez **pas** les dossiers `src/`, `public/`, etc. Seul le contenu de `dist/` doit être en production.

### 3. Configuration serveur (Nginx / Apache)

- **Racine du site** : pointer vers le répertoire où se trouvent `index.html` et `assets/`.
- **SPA** : pour que les liens directs (ex. `/login`) fonctionnent, toute requête qui ne correspond pas à un fichier existant doit renvoyer `index.html`.

**Exemple Nginx :** voir le guide détaillé à la racine du projet : **[CONFIGURATION_NGINX_DUDU.md](../CONFIGURATION_NGINX_DUDU.md)** (section « Admin (admin.dudugroup.sn) »), avec exemples HTTPS, cache des assets et commandes d’activation.

Résumé minimal :

```nginx
server {
    server_name admin.dudugroup.sn;
    root /var/www/dudu-admin;   # contenu de dist/ déployé ici
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Après déploiement, recharger la config Nginx et vider le cache du navigateur (ou ouvrir en navigation privée).
