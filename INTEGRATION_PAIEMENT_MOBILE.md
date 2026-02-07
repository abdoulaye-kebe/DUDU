# 💳 Intégration Paiement Mobile - Orange Money & Wave

**Date:** 7 février 2026  
**Version:** 1.0  
**Statut:** ✅ INTÉGRATION COMPLÈTE

---

## 🎉 Paiement Mobile Intégré !

L'intégration complète d'**Orange Money** et **Wave** est maintenant implémentée dans les applications DUDU.

---

## 📋 Ce qui a été implémenté

### ✅ Backend

#### 1. **Configuration des APIs**
**Fichier:** `backend/config/payment.config.js`

- Configuration Orange Money (sandbox et production)
- Configuration Wave (sandbox et production)
- Paramètres de frais et limites
- URLs de callback et webhook

#### 2. **Service Orange Money**
**Fichier:** `backend/src/services/orangeMoneyService.js`

**Fonctionnalités:**
- ✅ Authentification OAuth avec Orange Money API
- ✅ Initiation de paiement avec token
- ✅ Vérification du statut de paiement
- ✅ Traitement des callbacks
- ✅ Gestion des remboursements
- ✅ Calcul automatique des frais (1%)
- ✅ Normalisation des numéros de téléphone
- ✅ Mapping des statuts

#### 3. **Service Wave**
**Fichier:** `backend/src/services/waveService.js`

**Fonctionnalités:**
- ✅ Authentification HMAC avec Wave API
- ✅ Création de sessions de paiement
- ✅ Vérification du statut de paiement
- ✅ Traitement des webhooks avec validation de signature
- ✅ Gestion des remboursements
- ✅ Annulation de paiements
- ✅ Calcul automatique des frais (1.5%)
- ✅ Normalisation des numéros de téléphone

#### 4. **Routes API**
**Fichier:** `backend/src/routes/mobile-payments.js`

**Endpoints:**
- `POST /api/v1/mobile-payments/orange-money/initiate` - Initier paiement OM
- `POST /api/v1/mobile-payments/wave/initiate` - Initier paiement Wave
- `GET /api/v1/mobile-payments/:id/status` - Vérifier statut
- `POST /api/v1/mobile-payments/:id/cancel` - Annuler paiement
- `POST /api/v1/mobile-payments/orange-money/callback` - Callback OM
- `POST /api/v1/mobile-payments/wave/webhook` - Webhook Wave

---

## 🔧 Configuration Requise

### Variables d'Environnement

Créer un fichier `.env` dans `backend/` avec les clés API reçues :

```bash
# Orange Money - Sandbox (Tests)
ORANGE_MONEY_MODE=sandbox
ORANGE_MONEY_SANDBOX_MERCHANT_KEY=votre_merchant_key_sandbox
ORANGE_MONEY_SANDBOX_MERCHANT_SECRET=votre_merchant_secret_sandbox
ORANGE_MONEY_SANDBOX_MERCHANT_ID=votre_merchant_id_sandbox

# Orange Money - Production
ORANGE_MONEY_MERCHANT_KEY=votre_merchant_key_prod
ORANGE_MONEY_MERCHANT_SECRET=votre_merchant_secret_prod
ORANGE_MONEY_MERCHANT_ID=votre_merchant_id_prod

# Wave - Sandbox (Tests)
WAVE_MODE=sandbox
WAVE_SANDBOX_API_KEY=votre_api_key_sandbox
WAVE_SANDBOX_API_SECRET=votre_api_secret_sandbox
WAVE_SANDBOX_BUSINESS_ID=votre_business_id_sandbox
WAVE_SANDBOX_WEBHOOK_SECRET=votre_webhook_secret_sandbox

# Wave - Production
WAVE_API_KEY=votre_api_key_prod
WAVE_API_SECRET=votre_api_secret_prod
WAVE_BUSINESS_ID=votre_business_id_prod
WAVE_WEBHOOK_SECRET=votre_webhook_secret_prod

# URLs de callback (ajuster selon votre domaine)
ORANGE_MONEY_RETURN_URL=https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/callback
WAVE_CALLBACK_URL=https://www.dudugroup.sn/api/v1/mobile-payments/wave/webhook
```

---

## 🚀 Utilisation des APIs

### 1. Initier un Paiement Orange Money

**Endpoint:** `POST /api/v1/mobile-payments/orange-money/initiate`

**Headers:**
```json
{
  "Authorization": "Bearer <user_token>",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "rideId": "507f1f77bcf86cd799439011",
  "amount": 5000,
  "phone": "776862514"
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Paiement Orange Money initié avec succès",
  "data": {
    "paymentId": "65abc123def456789",
    "paymentToken": "OM_TOKEN_123456",
    "paymentUrl": "https://api.orange.com/pay/OM_TOKEN_123456",
    "amount": 5000,
    "currency": "XOF",
    "expiresAt": "2026-02-07T20:30:00.000Z",
    "instructions": "Suivez le lien pour compléter le paiement sur Orange Money"
  }
}
```

### 2. Initier un Paiement Wave

**Endpoint:** `POST /api/v1/mobile-payments/wave/initiate`

**Headers:**
```json
{
  "Authorization": "Bearer <user_token>",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "rideId": "507f1f77bcf86cd799439011",
  "amount": 5000,
  "phone": "776862514"
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Paiement Wave initié avec succès",
  "data": {
    "paymentId": "65abc123def456789",
    "sessionId": "WAVE_SESSION_123456",
    "checkoutUrl": "https://pay.wave.com/checkout/WAVE_SESSION_123456",
    "amount": 5000,
    "currency": "XOF",
    "expiresAt": "2026-02-07T20:30:00.000Z",
    "instructions": "Suivez le lien pour compléter le paiement sur Wave"
  }
}
```

### 3. Vérifier le Statut d'un Paiement

**Endpoint:** `GET /api/v1/mobile-payments/:paymentId/status`

**Headers:**
```json
{
  "Authorization": "Bearer <user_token>"
}
```

**Réponse:**
```json
{
  "success": true,
  "data": {
    "paymentId": "65abc123def456789",
    "status": "completed",
    "amount": 5000,
    "currency": "XOF",
    "method": "orange_money",
    "transactionId": "OM_TXN_789456",
    "completedAt": "2026-02-07T20:25:30.000Z"
  }
}
```

**Statuts possibles:**
- `pending` - En attente
- `processing` - En cours de traitement
- `completed` - Complété avec succès
- `failed` - Échoué
- `cancelled` - Annulé
- `refunded` - Remboursé

### 4. Annuler un Paiement

**Endpoint:** `POST /api/v1/mobile-payments/:paymentId/cancel`

**Headers:**
```json
{
  "Authorization": "Bearer <user_token>"
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Paiement annulé avec succès",
  "data": {
    "paymentId": "65abc123def456789",
    "status": "cancelled"
  }
}
```

---

## 🔄 Flux de Paiement Complet

### Scénario: Client paie une course avec Orange Money

1. **Client termine la course**
   - Chauffeur clique "TERMINER LA COURSE"
   - Backend met à jour le statut de la course

2. **Client choisit le mode de paiement**
   - Écran de paiement s'affiche
   - Client sélectionne "Orange Money"
   - Client entre son numéro: `776862514`

3. **Initiation du paiement**
   ```
   POST /api/v1/mobile-payments/orange-money/initiate
   {
     "rideId": "65abc...",
     "amount": 5000,
     "phone": "776862514"
   }
   ```

4. **Backend traite la demande**
   - Crée un enregistrement `Payment` dans MongoDB
   - Appelle `orangeMoneyService.initiatePayment()`
   - Orange Money API retourne un `paymentToken` et `paymentUrl`
   - Backend retourne les infos au client

5. **Client complète le paiement**
   - App ouvre `paymentUrl` dans un WebView ou navigateur
   - Client entre son code PIN Orange Money
   - Orange Money traite le paiement

6. **Callback Orange Money**
   ```
   POST /api/v1/mobile-payments/orange-money/callback
   {
     "order_id": "PAY123ABC",
     "status": "SUCCESS",
     "txnid": "OM_TXN_789456",
     "amount": "5000",
     "pay_date": "2026-02-07T20:25:30Z"
   }
   ```

7. **Backend met à jour le statut**
   - Trouve le paiement via `order_id`
   - Met à jour le statut à `completed`
   - Met à jour la course: `payment.status = 'completed'`
   - Envoie une notification au client et chauffeur

8. **Vérification par polling (optionnel)**
   - App peut appeler `/status` toutes les 3 secondes
   - Affiche le statut en temps réel

---

## 💰 Frais de Transaction

### Orange Money
- **Frais:** 1% du montant
- **Exemple:** Course de 5000 FCFA
  - Montant total: 5000 FCFA
  - Frais: 50 FCFA
  - Montant net chauffeur: 4950 FCFA

### Wave
- **Frais:** 1.5% du montant
- **Exemple:** Course de 5000 FCFA
  - Montant total: 5000 FCFA
  - Frais: 75 FCFA
  - Montant net chauffeur: 4925 FCFA

**Note:** Les frais sont automatiquement calculés par les services.

---

## 🔒 Sécurité

### Orange Money
- ✅ Authentification OAuth 2.0
- ✅ Token d'accès avec expiration
- ✅ HTTPS obligatoire
- ✅ Validation des callbacks

### Wave
- ✅ Authentification HMAC SHA-256
- ✅ Signature des requêtes
- ✅ Validation des webhooks avec signature
- ✅ HTTPS obligatoire
- ✅ Timing-safe comparison pour les signatures

---

## 🧪 Tests

### Mode Sandbox

Les deux services supportent un mode sandbox pour les tests:

```bash
# Dans .env
ORANGE_MONEY_MODE=sandbox
WAVE_MODE=sandbox
```

**Numéros de test Orange Money:**
- `+221700000001` - Paiement réussi
- `+221700000002` - Paiement échoué
- `+221700000003` - Paiement expiré

**Numéros de test Wave:**
- `+221770000001` - Paiement réussi
- `+221770000002` - Paiement échoué

### Tests Recommandés

1. **Test Paiement Réussi**
   - Initier un paiement
   - Compléter le paiement
   - Vérifier le statut `completed`
   - Vérifier que la course est marquée comme payée

2. **Test Paiement Échoué**
   - Initier un paiement
   - Simuler un échec
   - Vérifier le statut `failed`
   - Vérifier que la course reste `unpaid`

3. **Test Annulation**
   - Initier un paiement
   - Annuler avant complétion
   - Vérifier le statut `cancelled`

4. **Test Remboursement**
   - Compléter un paiement
   - Demander un remboursement
   - Vérifier le statut `refunded`

---

## 📱 Intégration Mobile (À Faire)

### Écrans à Créer

#### App Client (`dudu_flutter/`)

1. **Écran de Sélection du Mode de Paiement**
   - Liste des options: Orange Money, Wave, Espèces
   - Logos et descriptions
   - Champ numéro de téléphone

2. **Écran de Paiement Orange Money**
   - WebView pour `paymentUrl`
   - Indicateur de chargement
   - Gestion du retour (success/cancel)

3. **Écran de Paiement Wave**
   - WebView pour `checkoutUrl`
   - Indicateur de chargement
   - Gestion du retour (success/cancel)

4. **Écran de Confirmation de Paiement**
   - Statut du paiement
   - Détails de la transaction
   - Bouton "Retour au dashboard"

#### App Chauffeur (`mobile_dudu_pro/`)

1. **Notification de Paiement Reçu**
   - Montant reçu
   - Méthode de paiement
   - ID de transaction

---

## 🔧 Dépannage

### Erreur: "Impossible d'obtenir le token d'accès Orange Money"

**Cause:** Clés API incorrectes ou expirées

**Solution:**
1. Vérifier les variables d'environnement
2. Vérifier que `ORANGE_MONEY_MODE` correspond aux clés utilisées
3. Contacter Orange Money pour renouveler les clés

### Erreur: "Signature du webhook invalide" (Wave)

**Cause:** Secret webhook incorrect

**Solution:**
1. Vérifier `WAVE_WEBHOOK_SECRET` dans `.env`
2. S'assurer que le secret correspond à celui configuré sur Wave

### Paiement bloqué en "processing"

**Cause:** Callback/Webhook non reçu

**Solution:**
1. Vérifier que les URLs de callback sont accessibles publiquement
2. Vérifier les logs du backend
3. Tester manuellement avec `GET /status`

---

## 📊 Monitoring

### Logs à Surveiller

```bash
# Logs Orange Money
✅ Connexion à MongoDB réussie
🔔 Paiement Orange Money initié: PAY123ABC
✅ Callback Orange Money traité: SUCCESS

# Logs Wave
🔔 Paiement Wave initié: WAVE_SESSION_123
✅ Webhook Wave traité: completed
```

### Métriques Importantes

- Taux de réussite des paiements
- Temps moyen de traitement
- Nombre de remboursements
- Frais totaux collectés

---

## 🚀 Mise en Production

### Checklist

- [ ] Obtenir les clés API de production Orange Money
- [ ] Obtenir les clés API de production Wave
- [ ] Configurer les variables d'environnement de production
- [ ] Mettre `ORANGE_MONEY_MODE=production`
- [ ] Mettre `WAVE_MODE=production`
- [ ] Configurer les URLs de callback avec le domaine de production
- [ ] Tester avec de vrais paiements (petits montants)
- [ ] Configurer les webhooks sur les dashboards Orange Money et Wave
- [ ] Activer le monitoring et les alertes
- [ ] Former l'équipe support sur le dépannage

### URLs de Production

```bash
# Orange Money
ORANGE_MONEY_RETURN_URL=https://api.dudu.sn/api/v1/mobile-payments/orange-money/callback
ORANGE_MONEY_NOTIFY_URL=https://api.dudu.sn/api/v1/mobile-payments/orange-money/notify

# Wave
WAVE_CALLBACK_URL=https://api.dudu.sn/api/v1/mobile-payments/wave/callback
```

---

## 📞 Support

### Orange Money
- **Documentation:** https://developer.orange.com/apis/orange-money-webpay/
- **Support:** support-api@orange.com

### Wave
- **Documentation:** https://developer.wave.com/
- **Support:** developers@wave.com

---

## ✅ Résumé

L'intégration du paiement mobile est **COMPLÈTE** au niveau backend:

- ✅ Service Orange Money avec OAuth
- ✅ Service Wave avec HMAC
- ✅ Routes API complètes
- ✅ Gestion des callbacks et webhooks
- ✅ Calcul automatique des frais
- ✅ Gestion des remboursements
- ✅ Validation et sécurité
- ✅ Documentation complète

**Prochaines étapes:**
1. Configurer les clés API reçues dans `.env`
2. Tester en mode sandbox
3. Créer les écrans de paiement dans les apps mobiles
4. Tester le flux complet
5. Passer en production

---

**Date de création:** 7 février 2026  
**Version:** 1.0  
**Statut:** ✅ BACKEND COMPLET - APPS MOBILES À FAIRE
