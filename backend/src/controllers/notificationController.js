const notificationService = require('../services/notificationService');
const Driver = require('../models/Driver');

/**
 * Webhook appelé quand un chauffeur active/désactive le covoiturage
 */
exports.onCarpoolStatusChange = async (req, res) => {
  try {
    const { driverId, carpoolMode, carpoolSeats } = req.body;

    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({ message: 'Chauffeur non trouvé' });
    }

    // Analyser la disponibilité dans la zone
    const carpoolData = await notificationService.analyzeCarpoolAvailability({
      latitude: driver.currentLocation.latitude,
      longitude: driver.currentLocation.longitude,
    });

    res.json({
      success: true,
      carpoolData,
    });
  } catch (error) {
    console.error('Erreur webhook covoiturage:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * Enregistrer le token FCM d'un utilisateur
 */
exports.registerFCMToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fcmToken, platform } = req.body;

    if (req.user.role === 'driver') {
      await Driver.findByIdAndUpdate(userId, {
        fcmToken,
        'deviceInfo.platform': platform,
      });
    } else {
      const User = require('../models/User');
      await User.findByIdAndUpdate(userId, {
        fcmToken,
        'deviceInfo.platform': platform,
      });
    }

    res.json({ success: true, message: 'Token FCM enregistré' });
  } catch (error) {
    console.error('Erreur enregistrement FCM:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * Envoyer notification test
 */
exports.sendTestNotification = async (req, res) => {
  try {
    const userId = req.user.id;

    const notification = {
      title: '🧪 Test Notification',
      body: 'Ceci est une notification test de DUDU',
      data: {
        type: 'test',
      },
    };

    const result = await notificationService.sendPushNotification(userId, notification);

    res.json({
      success: true,
      result,
    });
  } catch (error) {
    console.error('Erreur notification test:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * Envoyer une promo à tous les utilisateurs abonnés au topic `promos`
 */
exports.sendPromoToTopic = async (req, res) => {
  try {
    const { title, body, image, data } = req.body || {};
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'title et body requis'
      });
    }

    const notification = {
      title,
      body,
      image: image || null,
      data: data || { type: 'promo' },
    };

    const result = await notificationService.sendTopicNotification('promos', notification);

    if (!result) {
      return res.status(500).json({
        success: false,
        message: 'Échec envoi notification promo'
      });
    }

    res.json({
      success: true,
      result,
    });
  } catch (error) {
    console.error('Erreur promo topic:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

/**
 * Obtenir statistiques notifications
 */
exports.getNotificationStats = async (req, res) => {
  try {
    // À implémenter : statistiques des notifications envoyées
    res.json({
      success: true,
      stats: {
        today: 0,
        thisWeek: 0,
        thisMonth: 0,
      },
    });
  } catch (error) {
    console.error('Erreur stats notifications:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * Mettre à jour préférences notifications
 */
exports.updateNotificationPreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    const preferences = req.body;

    const User = require('../models/User');
    await User.findByIdAndUpdate(userId, {
      'preferences.pushNotifications': preferences.pushNotifications !== false,
      'preferences.carpoolNotifications': preferences.carpoolNotifications !== false,
      'preferences.promoNotifications': preferences.promoNotifications !== false,
    });

    res.json({ success: true, message: 'Préférences mises à jour' });
  } catch (error) {
    console.error('Erreur préférences notifications:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

