# Vérification des endpoints API DUDU

## Base URL

- **Backend** : toutes les routes sont préfixées par `/api/v1/`.
- **Clients** : `AppConfig.baseUrl` = `http://<host>:3000/api/v1` (dudu_flutter et mobile_dudu_pro).

Les appels client sont donc de la forme `$baseUrl/<ressource>/...` → `http://<host>:3000/api/v1/<ressource>/...` ✅

---

## 1. Auth (`/api/v1/auth`)

| Méthode | Endpoint backend | Client (dudu_flutter) | Statut |
|--------|------------------|----------------------|--------|
| POST | `/auth/register` | `$baseUrl/auth/register` | ✅ |
| POST | `/auth/login` | `$baseUrl/auth/login` | ✅ |
| POST | `/auth/verify` | `$baseUrl/auth/verify` | ✅ |
| POST | `/auth/resend-verification` | `$baseUrl/auth/resend-verification` | ✅ |
| GET | `/auth/me` | `$baseUrl/auth/me` | ✅ |
| POST | `/auth/logout` | `$baseUrl/auth/logout` | ✅ |
| POST | `/auth/admin/login` | (admin) | ✅ |
| GET | `/auth/test-code/:phone` | (dev) | ✅ |

---

## 2. Users (`/api/v1/users`)

| Méthode | Endpoint backend | Client | Statut |
|--------|------------------|--------|--------|
| GET | `/users/profile` | `$baseUrl/users/profile` | ✅ |
| PUT | `/users/profile` | `$baseUrl/users/profile` | ✅ |
| PUT | `/users/budget-settings` | `$baseUrl/users/budget-settings` | ✅ |
| GET | `/users/scheduled-rides` | `$baseUrl/users/scheduled-rides` | ✅ |
| GET | `/users/rides` | `$baseUrl/users/rides` | ✅ |
| GET | `/users/stats` | (profil) | ✅ |
| PUT | `/users/address` | (profil) | ✅ |
| POST | `/users/upload-avatar` | (à appeler avec multipart `avatar`) | ✅ |
| DELETE | `/users/account` | `$baseUrl/users/account` | ✅ |

---

## 3. Drivers (`/api/v1/drivers`) – mobile_dudu_pro

| Méthode | Endpoint backend | Client | Statut |
|--------|------------------|--------|--------|
| POST | `/drivers/login` | `$baseUrl/drivers/login` | ✅ |
| POST | `/drivers/apply` | `$baseUrl/drivers/apply` | ✅ |
| POST | `/drivers/register` | (inscription) | ✅ |
| GET | `/drivers/profile` | `$baseUrl/drivers/profile` | ✅ |
| PUT | `/drivers/profile` | (profil) | ✅ |
| PUT | `/drivers/location` | `$baseUrl/drivers/location` | ✅ |
| PUT | `/drivers/status` | `$baseUrl/drivers/status` | ✅ |
| PUT | `/drivers/ride-types` | `$baseUrl/drivers/ride-types` | ✅ |
| PUT | `/drivers/change-password` | `$baseUrl/drivers/change-password` | ✅ |
| DELETE | `/drivers/account` | `$baseUrl/drivers/account` | ✅ |
| GET | `/drivers/rides` | `$baseUrl/drivers/rides` | ✅ |
| GET | `/drivers/stats` | `$baseUrl/drivers/stats` | ✅ |
| GET | `/drivers/nearby-rides` | `$baseUrl/drivers/nearby-rides` | ✅ |
| GET | `/drivers/carpool/compatible-rides` | (côté chauffeur) | ✅ |
| POST | `/drivers/carpool/accept` | (côté chauffeur) | ✅ |

---

## 4. Rides (`/api/v1/rides`)

| Méthode | Endpoint backend | Client | Statut |
|--------|------------------|--------|--------|
| POST | `/rides/request` | `$baseUrl/rides/request` (dudu_flutter) | ✅ |
| POST | `/rides/create` | `$baseUrl/rides/create` (dudu_flutter) | ✅ |
| POST | `/rides/schedule` | `$baseUrl/rides/schedule` (dudu_flutter) | ✅ |
| GET | `/rides/:id` | `$baseUrl/rides/$rideId` (dudu_flutter) | ✅ |
| POST | `/rides/:id/accept` | `$baseUrl/rides/$rideId/accept` (mobile_dudu_pro) | ✅ |
| POST | `/rides/:id/arrive` | `$baseUrl/rides/$rideId/arrive` | ✅ |
| POST | `/rides/:id/start` | `$baseUrl/rides/$rideId/start` | ✅ |
| POST | `/rides/:id/complete` | `$baseUrl/rides/$rideId/complete` | ✅ |
| POST | `/rides/:id/cancel` | `$baseUrl/rides/$rideId/cancel` | ✅ |
| POST | `/rides/:id/rate` | `$baseUrl/rides/$rideId/rate` (passager note chauffeur) | ✅ |
| POST | `/rides/:id/rate-passenger` | `$baseUrl/rides/$rideId/rate-passenger` (mobile_dudu_pro) | ✅ **Corrigé** |

---

## 5. Covoiturage (`/api/v1/carpool`)

| Méthode | Endpoint backend | Client | Statut |
|--------|------------------|--------|--------|
| GET | `/carpool/drivers/available` | `$baseUrl/carpool/drivers/available?latitude=...&longitude=...&radius=1` (dudu_flutter) | ✅ **Ajouté** |

Route ajoutée : `backend/src/routes/carpool.js`, montée dans `server.js` sous `/api/v1/carpool`.

---

## 6. Paiements et abonnements

| Méthode | Endpoint backend | Client | Statut |
|--------|------------------|--------|--------|
| POST | `/payments/initiate` | (payments) | ✅ |
| GET | `/payments`, `/payments/:id` | (historique) | ✅ |
| POST | `/mobile-payments/orange-money/initiate` | `$baseUrl/mobile-payments/orange-money/initiate` | ✅ |
| POST | `/mobile-payments/wave/initiate` | `$baseUrl/mobile-payments/wave/initiate` | ✅ |
| GET | `/mobile-payments/:id/status` | `$baseUrl/mobile-payments/$paymentId/status` | ✅ |
| POST | `/mobile-payments/:id/cancel` | (dudu_flutter) | ✅ |
| POST | `/mobile-payments/subscription/wave/initiate` | mobile_dudu_pro | ✅ |
| POST | `/mobile-payments/subscription/orange-money/initiate` | mobile_dudu_pro | ✅ |
| GET | `/subscriptions/plans` | `$baseUrl/subscriptions/plans?vehicleType=...` | ✅ |
| POST | `/subscriptions/purchase` | `$baseUrl/subscriptions/purchase` | ✅ |
| GET | `/subscriptions/current` | `$baseUrl/subscriptions/current` | ✅ |
| GET | `/subscriptions/:id/bonus-history` | `$baseUrl/subscriptions/$id/bonus-history` | ✅ |

---

## 7. Santé et autres

| Méthode | Endpoint | Client | Statut |
|--------|----------|--------|--------|
| GET | `/api/v1/health` | `$baseUrl/health` | ✅ |
| Notifications | `/api/v1/notifications/*` | (FCM, préférences) | ✅ |
| Admin | `/api/v1/admin/*` | (admin web) | ✅ |
| Disputes | `/api/v1/disputes/*` | (litiges) | ✅ |

---

## Corrections effectuées

1. **GET /api/v1/carpool/drivers/available**  
   - Manquait côté backend.  
   - **Ajout** : `backend/src/routes/carpool.js` avec route GET `/drivers/available` (query: `latitude`, `longitude`, `radius`). Montage dans `server.js` sous `/api/v1/carpool`.  
   - Le client dudu_flutter (`carpool_monitor_service`) appelait déjà cette URL → désormais opérationnel.

2. **POST /api/v1/rides/:id/rate-passenger**  
   - Utilisé par mobile_dudu_pro (`rate_passenger_screen`) pour que le chauffeur note le passager.  
   - **Ajout** : route dans `backend/src/routes/rides.js` et champ `passengerRating` dans le modèle `Ride`.  
   - Réponse : `{ success, message, data: { passengerRating } }`.

---

## Résumé

- **Base URL** : cohérente entre backend (`/api/v1`) et clients (`baseUrl = .../api/v1`).  
- **Endpoints principaux** (auth, users, drivers, rides, payments, subscriptions, mobile-payments) : tous alignés.  
- **Covoiturage** : endpoint `/carpool/drivers/available` ajouté et vérifié.  
- **Notation passager** : endpoint `/rides/:id/rate-passenger` ajouté et vérifié.

Pour tester rapidement :

- Health : `GET http://localhost:3000/api/v1/health`
- Covoiturage : `GET http://localhost:3000/api/v1/carpool/drivers/available?latitude=14.69&longitude=-17.44&radius=1`
- Rate-passenger : `POST http://localhost:3000/api/v1/rides/<rideId>/rate-passenger` avec body `{ "rating": 5, "comment": "..." }` et header `Authorization: Bearer <token_chauffeur>`.
