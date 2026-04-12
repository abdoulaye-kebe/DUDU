# Dossier des APK DUDU

Ce dossier contient les fichiers APK pour les applications DUDU.

## Fichiers attendus

- `dudu-client.apk` - Application client DUDU
- `dudu-pro.apk` - Application chauffeur DUDU Pro (lien utilisé par le site vitrine `dudu-website`)
- `dudu-driver.apk` - **Copie identique** de l’APK Pro (compatibilité anciens liens / pages backend)

## Comment générer les APK

### Pour l'application Client (dudu_flutter)

```bash
cd dudu_flutter
flutter build apk --release
# Le fichier sera dans: build/app/outputs/flutter-apk/app-release.apk
# Copier vers: backend/public/downloads/dudu-client.apk
```

### Pour l'application Chauffeur (mobile_dudu_pro)

```bash
cd mobile_dudu_pro
flutter build apk --release
# Le fichier sera dans: build/app/outputs/flutter-apk/app-release.apk
# Copier vers: backend/public/downloads/dudu-pro.apk
# (et dupliquer en dudu-driver.apk si vous gardez d'anciens liens)
```

## URLs de téléchargement

Une fois le backend démarré:

- **Client:** http://213.154.90.11:3000/download-client.html
- **Chauffeur:** http://213.154.90.11:3000/download-driver.html

## Script (macOS / Linux)

À la racine du dépôt :

```bash
chmod +x scripts/publish-apks.sh
./scripts/publish-apks.sh
```

## Déploiement sur le serveur

Après `git pull`, copier les trois fichiers de ce dossier vers le répertoire réellement servi pour `/downloads/` (souvent le même `backend/public/downloads/` derrière Nginx ou Node). Si le site statique est déployé séparément, dupliquer aussi les APK dans `dudu-website/public/downloads/` si ce vhost sert ce chemin.

## Notes

- Les APK doivent être signés pour la production
- Tester sur un appareil physique Android
- Vérifier que l'IP publique est accessible depuis l'extérieur
