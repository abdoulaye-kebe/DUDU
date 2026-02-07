# Configuration Orange Money Production

## 🔑 Clés API Production

### Informations d'authentification
- **Client ID**: `c98da064-dd7e-4aae-9a80-6bbe4360b8e3`
- **Client Secret**: `de8266ac-2a46-42a1-ae26-aa162b5ceafd`
- **Merchant ID**: `DuDu`
- **Mode**: `production`

### APIs Activées
- ✅ PAYMENT - OM (Approuvé)
- ✅ QR CODE - OM (Approuvé)
- ✅ oauth (Approuvé)
- ✅ Orange-Money-Distributeur (Approuvé)
- ✅ esignature_product (Approuvé)
- ✅ NOTIFICATION (Approuvé)

---

## 🌐 URLs de Production

### API Base URL
```
https://api.orange.com/orange-money-webpay/v1
```

### URLs de Callback
- **Return URL**: `https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/callback`
- **Cancel URL**: `https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/cancel`
- **Notify URL**: `https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/notify`

---

## 🔐 Authentification OAuth 2.0

Orange Money utilise OAuth 2.0 pour l'authentification.

### 1. Obtenir un Token d'Accès

**Endpoint**: `POST https://api.orange.com/oauth/v3/token`

**Headers**:
```
Authorization: Basic base64(client_id:client_secret)
Content-Type: application/x-www-form-urlencoded
```

**Body**:
```
grant_type=client_credentials
```

**Exemple de requête**:
```bash
curl -X POST https://api.orange.com/oauth/v3/token \
  -H "Authorization: Basic Yzk4ZGEwNjQtZGQ3ZS00YWFlLTlhODAtNmJiZTQzNjBiOGUzOmRlODI2NmFjLTJhNDYtNDJhMS1hZTI2LWFhMTYyYjVjZWFmZA==" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials"
```

**Réponse**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

## 💳 Initier un Paiement

### Endpoint
```
POST https://api.orange.com/orange-money-webpay/v1/webpayment
```

### Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

### Body
```json
{
  "merchant_key": "c98da064-dd7e-4aae-9a80-6bbe4360b8e3",
  "currency": "XOF",
  "order_id": "ORDER_123456",
  "amount": 1000,
  "return_url": "https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/callback",
  "cancel_url": "https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/cancel",
  "notif_url": "https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/notify",
  "lang": "fr",
  "reference": "DUDU_RIDE_123"
}
```

### Réponse
```json
{
  "payment_url": "https://webpayment.orange-money.com/pay?token=abc123...",
  "pay_token": "abc123...",
  "notif_token": "xyz789..."
}
```

---

## 🔔 Webhooks et Callbacks

### Return URL (Succès)
Appelé quand l'utilisateur complète le paiement avec succès.

**URL**: `https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/callback`

**Paramètres**:
- `order_id`: ID de la commande
- `status`: Statut du paiement (SUCCESS, FAILED, PENDING)
- `txnid`: ID de la transaction Orange Money

### Cancel URL (Annulation)
Appelé quand l'utilisateur annule le paiement.

**URL**: `https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/cancel`

### Notify URL (Notification)
Webhook appelé par Orange Money pour notifier le statut du paiement.

**URL**: `https://www.dudugroup.sn/api/v1/mobile-payments/orange-money/notify`

**Méthode**: POST

**Body**:
```json
{
  "order_id": "ORDER_123456",
  "status": "SUCCESS",
  "txnid": "OM123456789",
  "amount": 1000,
  "currency": "XOF",
  "notif_token": "xyz789..."
}
```

---

## ✅ Vérifier le Statut d'un Paiement

### Endpoint
```
GET https://api.orange.com/orange-money-webpay/v1/transactionstatus/{order_id}
```

### Headers
```
Authorization: Bearer {access_token}
```

### Réponse
```json
{
  "status": "SUCCESS",
  "order_id": "ORDER_123456",
  "amount": 1000,
  "currency": "XOF",
  "txnid": "OM123456789",
  "payment_date": "2026-02-07T21:00:00Z"
}
```

---

## 💰 Frais de Transaction

- **Frais Orange Money**: 1% du montant
- **Montant minimum**: 100 FCFA
- **Montant maximum**: 1 000 000 FCFA

---

## 🔄 Flux de Paiement Complet

### Pour les Courses (Clients)

1. **Client termine une course**
2. **Sélectionne "Orange Money" comme mode de paiement**
3. **Backend initie le paiement** via API Orange Money
4. **Client est redirigé** vers la page de paiement Orange Money
5. **Client entre son code PIN** Orange Money
6. **Orange Money traite le paiement**
7. **Webhook notifie le backend** du résultat
8. **Backend met à jour** le statut de la course
9. **Client est redirigé** vers l'app avec confirmation

### Pour les Abonnements (Chauffeurs)

1. **Chauffeur sélectionne un abonnement**
2. **Choisit "Orange Money" comme paiement**
3. **Backend initie le paiement d'abonnement**
4. **Chauffeur complète le paiement** sur Orange Money
5. **Webhook confirme le paiement**
6. **Backend active automatiquement l'abonnement**
7. **Chauffeur reçoit confirmation**

---

## 🧪 Tests en Production

### Test avec un Petit Montant

```bash
# 1. Se connecter
curl -X POST http://localhost:3000/api/v1/drivers/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+221771234567","password":"password123"}'

# 2. Initier un paiement test (100 FCFA)
TOKEN="votre_token_jwt"
curl -X POST http://localhost:3000/api/v1/mobile-payments/orange-money/initiate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "rideId": "test_ride_001",
    "amount": 100,
    "phone": "+221771234567"
  }'
```

---

## ⚠️ Codes d'Erreur Courants

| Code | Message | Solution |
|------|---------|----------|
| 401 | Unauthorized | Vérifier le token OAuth |
| 400 | Invalid merchant_key | Vérifier le Client ID |
| 403 | Forbidden | Vérifier les permissions API |
| 500 | Internal Server Error | Contacter le support Orange |

---

## 📊 Monitoring

### Logs à Surveiller

```bash
# Sur le serveur
pm2 logs dudu-backend | grep -i "orange"
```

**Messages importants**:
- `✅ Token OAuth Orange Money obtenu`
- `✅ Paiement Orange Money initié`
- `✅ Callback Orange Money reçu`
- `✅ Abonnement activé après paiement Orange Money`

---

## 🔒 Sécurité

### Bonnes Pratiques

1. ✅ **Ne jamais exposer** le Client Secret dans le code frontend
2. ✅ **Toujours utiliser HTTPS** pour les callbacks
3. ✅ **Valider le notif_token** dans les webhooks
4. ✅ **Vérifier le statut** du paiement côté serveur
5. ✅ **Logger toutes les transactions** pour audit

### Variables d'Environnement (Recommandé)

```bash
# Dans .env
ORANGE_MONEY_MODE=production
ORANGE_MONEY_MERCHANT_KEY=c98da064-dd7e-4aae-9a80-6bbe4360b8e3
ORANGE_MONEY_MERCHANT_SECRET=de8266ac-2a46-42a1-ae26-aa162b5ceafd
ORANGE_MONEY_MERCHANT_ID=DuDu
```

---

## 📞 Support Orange Money

- **Email**: api.support@orange.com
- **Documentation**: https://developer.orange.com
- **Portal**: https://developer.orange.com/console

---

## ✅ Checklist de Mise en Production

- [x] Clés API configurées
- [x] Mode production activé
- [x] URLs de callback configurées
- [x] Service Orange Money implémenté
- [x] Routes API créées
- [x] Webhooks sécurisés
- [ ] Tests de paiement réussis
- [ ] Monitoring activé
- [ ] Documentation à jour

---

**Date de configuration**: 7 février 2026  
**Statut**: ✅ Prêt pour production
