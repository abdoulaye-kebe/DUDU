# Deeplinks Orange Money et MAX IT

## 📱 Qu'est-ce qu'un Deeplink ?

Un **deeplink** est un lien permettant d'ouvrir directement une application mobile avec des paramètres pré-remplis. Dans le cas d'Orange Money/MAX IT, le deeplink ouvre l'application avec les détails de la transaction à effectuer.

---

## 🔗 Types de Deeplinks

Lors de la génération d'un QR Code via l'API Orange Money, vous recevez **deux deeplinks** :

### 1. Deeplink MAX IT
```
deeplinks.maxIt
```
Ouvre l'application **MAX IT** avec les détails de la transaction.

### 2. Deeplink Orange Money
```
deeplinks.om
```
Ouvre l'application **Orange Money** avec les détails de la transaction.

---

## 💡 Utilisation dans DUDU

### Backend (API Response)

Quand un paiement Orange Money est initié, l'API retourne :

```json
{
  "success": true,
  "message": "Paiement Orange Money initié avec succès",
  "data": {
    "paymentId": "PAY_123456",
    "qrCode": "data:image/png;base64,iVBORw0KGgo...",
    "qrCodeUrl": "https://...",
    "deeplinks": {
      "maxIt": "maxit://payment?transaction=...",
      "orangeMoney": "orangemoney://payment?transaction=..."
    },
    "amount": 1000,
    "currency": "XOF",
    "expiresAt": "2026-02-07T22:30:00Z"
  }
}
```

### Frontend (App Mobile Flutter)

L'application mobile peut utiliser ces deeplinks pour :

1. **Afficher deux boutons** : "Payer avec MAX IT" et "Payer avec Orange Money"
2. **Ouvrir l'app directement** au clic sur le bouton

```dart
// Exemple Flutter
import 'package:url_launcher/url_launcher.dart';

// Ouvrir MAX IT
Future<void> openMaxIt(String deeplink) async {
  final uri = Uri.parse(deeplink);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback : afficher le QR Code
    showQRCode();
  }
}

// Ouvrir Orange Money
Future<void> openOrangeMoney(String deeplink) async {
  final uri = Uri.parse(deeplink);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback : afficher le QR Code
    showQRCode();
  }
}
```

---

## 🎨 Interface Utilisateur Recommandée

### Écran de Paiement

```
┌─────────────────────────────────┐
│   Paiement Orange Money         │
│                                 │
│   Montant: 1000 FCFA           │
│                                 │
│   Choisissez votre méthode:    │
│                                 │
│  ┌──────────────┐              │
│  │   MAX IT     │              │
│  │   [Logo]     │              │
│  └──────────────┘              │
│                                 │
│  ┌──────────────┐              │
│  │ Orange Money │              │
│  │   [Logo]     │              │
│  └──────────────┘              │
│                                 │
│   ou                           │
│                                 │
│  ┌──────────────┐              │
│  │  [QR Code]   │              │
│  │              │              │
│  └──────────────┘              │
│                                 │
│  Scannez avec votre app        │
└─────────────────────────────────┘
```

---

## ⚙️ Configuration Requise

### 1. Produit QR CODE - OM
Assurez-vous que le produit **QR CODE - OM** est bien intégré à votre application sur le portail Orange Developer.

### 2. Application en Production
L'application doit être en mode **production** (pas sandbox).

### 3. Permissions Mobile
L'app mobile doit avoir la permission de lancer des URL externes :

**Android** (`AndroidManifest.xml`):
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="maxit" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="orangemoney" />
  </intent>
</queries>
```

**iOS** (`Info.plist`):
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>maxit</string>
  <string>orangemoney</string>
</array>
```

---

## 🔄 Flux de Paiement Complet

### 1. Initiation
```
Client App → Backend API → Orange Money API
```

### 2. Réception des Deeplinks
```
Orange Money API → Backend → Client App
```

### 3. Choix de l'Utilisateur
```
┌─────────────────┐
│ MAX IT          │ → Ouvre MAX IT avec deeplink
├─────────────────┤
│ Orange Money    │ → Ouvre Orange Money avec deeplink
├─────────────────┤
│ Scanner QR Code │ → Affiche le QR Code
└─────────────────┘
```

### 4. Paiement
```
App MAX IT/Orange Money → Validation → Callback Backend
```

### 5. Confirmation
```
Backend → Update Payment Status → Notify Client App
```

---

## 📊 Avantages des Deeplinks

### ✅ Pour l'Utilisateur
- **Expérience fluide** : Pas besoin de scanner un QR Code
- **Rapidité** : Ouverture directe de l'app de paiement
- **Simplicité** : Un seul clic pour payer

### ✅ Pour le Développeur
- **Meilleur taux de conversion** : Moins de friction
- **Compatibilité** : Fonctionne avec MAX IT et Orange Money
- **Fallback** : QR Code disponible si l'app n'est pas installée

---

## 🚨 Gestion des Erreurs

### App Non Installée
```dart
try {
  await launchUrl(uri);
} catch (e) {
  // Afficher le QR Code en fallback
  showDialog(
    context: context,
    builder: (context) => QRCodeDialog(qrCode: qrCodeData),
  );
}
```

### Deeplink Invalide
```dart
if (deeplink == null || deeplink.isEmpty) {
  // Utiliser uniquement le QR Code
  showQRCode();
  return;
}
```

---

## 📝 Notes Importantes

1. **Coexistence MAX IT et Orange Money** : Les deux applications doivent coexister jusqu'à l'arrêt du service Orange Money
2. **Expiration** : Les deeplinks expirent en même temps que le QR Code (5 minutes par défaut)
3. **Sécurité** : Les deeplinks contiennent des tokens temporaires et ne peuvent être réutilisés

---

## 🔗 Liens Utiles

- **Portail Orange Developer**: https://developer.orange-sonatel.com
- **Documentation API**: https://developers.orange-sonatel.com/documentation
- **Support**: partenaires.orangemoney@orange-sonatel.com

---

**Date de documentation**: 7 février 2026  
**Version API**: v4 (QR Code)  
**Statut**: ✅ Implémenté dans DUDU
