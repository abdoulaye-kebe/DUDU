const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');

// Routes protégées (nécessitent authentification)
router.post('/register-token', protect, notificationController.registerFCMToken);
router.post('/test', protect, notificationController.sendTestNotification);
router.get('/stats', protect, notificationController.getNotificationStats);
router.put('/preferences', protect, notificationController.updateNotificationPreferences);

// Webhook (appelé par le système)
router.post('/webhook/carpool-change', notificationController.onCarpoolStatusChange);

module.exports = router;

