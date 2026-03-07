# Configuration Nginx – DUDU (détail)

Guide pour configurer Nginx sur le serveur (ex. 213.154.90.11) pour :
- **admin.dudugroup.sn** → interface admin (SPA build)
- **www.dudugroup.sn / dudugroup.sn** → site vitrine avec **home.html** en page d’accueil

---

## 1. Admin (admin.dudugroup.sn)

### 1.1 Build et emplacement des fichiers

Sur votre machine ou sur le serveur :

```bash
cd /chemin/vers/DUDU/admin-web
npm ci
npm run build
```

Cela crée le dossier **`dist/`** avec :
- `index.html`
- `assets/index-xxxx.js`, `assets/index-xxxx.css`, etc.

Sur le serveur, déployer **le contenu** de `dist/` dans un répertoire dédié, par exemple :

```bash
# Exemple : copier le build vers un dossier web
sudo mkdir -p /var/www/dudu-admin
sudo cp -r /chemin/vers/DUDU/admin-web/dist/* /var/www/dudu-admin/
# Ou utiliser rsync / votre méthode de déploiement
```

### 1.2 Fichier Nginx pour l’admin

Créer (ou modifier) le fichier de site pour l’admin, par exemple :

**`/etc/nginx/sites-available/admin.dudugroup.sn`**

```nginx
# Redirection HTTP → HTTPS (optionnel mais recommandé)
server {
    listen 80;
    server_name admin.dudugroup.sn;
    return 301 https://$server_name$request_uri;
}

# HTTPS – Admin DUDU (SPA)
server {
    listen 443 ssl http2;
    server_name admin.dudugroup.sn;

    # Racine = contenu du build (index.html + assets/)
    root /var/www/dudu-admin;
    index index.html;

    # SPA : toute requête qui ne correspond pas à un fichier/dossier
    # existant doit renvoyer index.html (sinon /login, /chauffeurs, etc. → 404)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache long pour les assets (noms avec hash)
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Certificats SSL (Let's Encrypt, etc.)
    ssl_certificate     /etc/letsencrypt/live/admin.dudugroup.sn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.dudugroup.sn/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```

**Sans HTTPS** (temporaire, pour test) :

```nginx
server {
    listen 80;
    server_name admin.dudugroup.sn;

    root /var/www/dudu-admin;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 1.3 Activer le site et recharger Nginx

```bash
sudo ln -sf /etc/nginx/sites-available/admin.dudugroup.sn /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 1.4 Vérifications

- Ouvrir **https://admin.dudugroup.sn** (ou http si pas encore de SSL).
- La page de login doit s’afficher (plus de page blanche si le build est bien servi).
- Si page blanche : vérifier que la racine Nginx (`root`) pointe bien vers le dossier qui contient `index.html` et le dossier `assets/`, et que vous avez bien déployé le **contenu de `dist/`**, pas le dossier `src/`.

---

## 2. Site vitrine (www.dudugroup.sn / dudugroup.sn)

### 2.1 Fichiers à déployer

Le site vitrine se trouve dans **`dudu-website/public/`**.  
Sur le serveur, ce contenu doit être servi par Nginx (par exemple : `/var/www/dudugroup.sn` ou `/var/www/dudu-website`).

Exemple de déploiement :

```bash
sudo mkdir -p /var/www/dudugroup.sn
# Copier tout le contenu de dudu-website/public/
sudo cp -r /chemin/vers/DUDU/dudu-website/public/* /var/www/dudugroup.sn/
```

Vous devez avoir par exemple : `index.html`, `home.html`, `css/`, `js/`, `images/`, etc.

### 2.2 Page d’accueil = home.html

Par défaut, Nginx sert **`index.html`** pour l’URL `/`.  
Pour que la page d’accueil du site soit **home.html** (hero « Yobalé sii sama prix »), deux options.

#### Option A : Redirection de `/` vers `/home.html`

```nginx
server {
    listen 80;
    server_name dudugroup.sn www.dudugroup.sn;

    root /var/www/dudugroup.sn;
    index index.html;

    # Page d'accueil = home.html
    location = / {
        return 302 /home.html;
    }

    # Tous les autres fichiers (CSS, JS, images, autres .html)
    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }
}
```

Ainsi, **https://dudugroup.sn/** ou **https://www.dudugroup.sn/** affiche directement le contenu de **home.html**.

#### Option B : Renommer home.html en index (alternative)

Si vous préférez que `/` serve directement le contenu de la page d’accueil sans redirection :

- Garder l’actuel `index.html` (page téléchargement) sous un autre nom, ex. **`download.html`**.
- Renommer **`home.html`** en **`index.html`** (et mettre à jour les liens internes qui pointent vers `home.html`).

Dans ce cas, la config Nginx reste classique : `index index.html;` et pas de `location = /`.

### 2.3 Fichier Nginx complet pour le site vitrine (avec Option A)

**`/etc/nginx/sites-available/dudugroup.sn`**

```nginx
# Redirection HTTP → HTTPS (recommandé)
server {
    listen 80;
    server_name dudugroup.sn www.dudugroup.sn;
    return 301 https://$host$request_uri;
}

# HTTPS – Site vitrine DUDU
server {
    listen 443 ssl http2;
    server_name dudugroup.sn www.dudugroup.sn;

    root /var/www/dudugroup.sn;
    index index.html;

    # Accueil = home.html (hero, services, etc.)
    location = / {
        return 302 /home.html;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    # Cache pour assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }

    ssl_certificate     /etc/letsencrypt/live/dudugroup.sn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dudugroup.sn/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```

Activation :

```bash
sudo ln -sf /etc/nginx/sites-available/dudugroup.sn /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 3. Résumé des hôtes et chemins

| Domaine               | Racine Nginx (exemple)   | Comportement |
|-----------------------|--------------------------|--------------|
| **admin.dudugroup.sn**| `/var/www/dudu-admin`    | Contenu de `admin-web/dist/`. `try_files ... /index.html` pour la SPA. |
| **dudugroup.sn**      | `/var/www/dudugroup.sn`  | Contenu de `dudu-website/public/`. `/` → redirection vers `/home.html` (Option A). |
| **www.dudugroup.sn**  | idem                     | Même `server_name` que dudugroup.sn. |

---

## 4. SSL (Let's Encrypt)

Si ce n’est pas déjà fait :

```bash
# Installer certbot si besoin
sudo apt install certbot python3-certbot-nginx

# Obtenir un certificat pour les deux domaines
sudo certbot --nginx -d dudugroup.sn -d www.dudugroup.sn
sudo certbot --nginx -d admin.dudugroup.sn
```

Puis adapter dans les blocs `server` les chemins `ssl_certificate` et `ssl_certificate_key` selon ce que Certbot a configuré.

---

## 5. Si le backend et le site partagent le même domaine (www.dudugroup.sn)

Souvent, l’API est exposée sous **https://www.dudugroup.sn/api**. Dans ce cas, le même fichier Nginx peut :

- servir le site vitrine (fichiers statiques) pour `/`, `/home.html`, `/css/`, etc. ;
- faire un **proxy** vers le backend Node pour `/api`.

Exemple à intégrer dans le bloc `server` du site vitrine :

```nginx
# Proxy API vers le backend Node (ex. port 3000)
location /api/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Dans ce cas, la racine du site reste `root /var/www/dudugroup.sn;` et la `location /api/` a la priorité pour les URLs qui commencent par `/api/`.

---

En suivant ce guide, **admin.dudugroup.sn** sert bien le build de l’admin (plus de page blanche) et **dudugroup.sn** affiche la page d’accueil **home.html** (hero et contenu du site vitrine).
