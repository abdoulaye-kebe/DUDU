const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { auth, requireAdmin } = require('../middleware/auth');

// Routes protégées (nécessitent authentification)
router.post('/register-token', auth, notificationController.registerFCMToken);
router.post('/test', auth, notificationController.sendTestNotification);
router.get('/stats', auth, notificationController.getNotificationStats);
router.put('/preferences', auth, notificationController.updateNotificationPreferences);

// Promo push via topic — réservé aux administrateurs
router.post('/promo', auth, requireAdmin, notificationController.sendPromoToTopic);

module.exports = router;

