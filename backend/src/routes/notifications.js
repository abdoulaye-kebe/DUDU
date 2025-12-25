const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { auth } = require('../middleware/auth');

// Routes protégées (nécessitent authentification)
router.post('/register-token', auth, notificationController.registerFCMToken);
router.post('/test', auth, notificationController.sendTestNotification);
router.get('/stats', auth, notificationController.getNotificationStats);
router.put('/preferences', auth, notificationController.updateNotificationPreferences);

// Promo push via topic
router.post('/promo', auth, notificationController.sendPromoToTopic);

// Webhook (appelé par le système)
router.post('/webhook/carpool-change', notificationController.onCarpoolStatusChange);

module.exports = router;

