# Instructions Build APK

## Commandes Rapides

### Build Les Deux Apps
Double-cliquer sur: `rebuild-apps.bat`

### Build Client Uniquement
Double-cliquer sur: `build-client.bat`

### Build Chauffeur Uniquement
Double-cliquer sur: `build-driver.bat`

## APKs Generes

- Client: `backend/public/downloads/dudu-client.apk`
- Chauffeur: `backend/public/downloads/dudu-driver.apk`

## Telechargement

- Client: http://41.208.146.203:3000/download-client.html
- Chauffeur: http://41.208.146.203:3000/download-driver.html

## Corrections Appliquees

1. Permissions localisation completes
2. Gestion erreur localisation (position par defaut Dakar)
3. Profil chauffeur corrige
4. Creation course corrigee
5. Dashboard charge preferences

## Tests

1. Demarrer backend: `cd backend && npm run dev`
2. Telecharger APKs depuis navigateur
3. Installer sur telephone
4. Tester toutes les fonctionnalites
