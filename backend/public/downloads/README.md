# Dossier des APK DUDU

Ce dossier contient les fichiers APK pour les applications DUDU.

## Fichiers attendus

- `dudu-client.apk` - Application client DUDU
- `dudu-driver.apk` - Application chauffeur DUDU Pro

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
# Copier vers: backend/public/downloads/dudu-driver.apk
```

## URLs de téléchargement

Une fois le backend démarré:

- **Client:** http://41.208.146.203:3000/download-client.html
- **Chauffeur:** http://41.208.146.203:3000/download-driver.html

## Notes

- Les APK doivent être signés pour la production
- Tester sur un appareil physique Android
- Vérifier que l'IP publique est accessible depuis l'extérieur
