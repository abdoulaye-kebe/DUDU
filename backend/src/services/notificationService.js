const admin = require('firebase-admin');
const User = require('../models/User');

let _firebaseInitialized = false;

function ensureFirebaseInitialized() {
  if (_firebaseInitialized) return;

  // On attend une variable d'env JSON pour éviter de committer des secrets.
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON manquant (firebase-admin non initialisé)');
  }

  const serviceAccount = JSON.parse(raw);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  _firebaseInitialized = true;
}

class NotificationService {
  /**
   * Envoyer une notification push à un utilisateur
   */
  async sendPushNotification(userId, notification) {
    try {
      ensureFirebaseInitialized();
      const user = await User.findById(userId);
      
      if (!user || !user.fcmToken) {
        console.log('Utilisateur sans token FCM');
        return null;
      }

      const messageNotification = {
        title: notification.title,
        body: notification.body,
      };

      if (typeof notification.image === 'string' && notification.image.trim().length > 0) {
        messageNotification.imageUrl = notification.image;
      }

      const message = {
        notification: messageNotification,
        data: notification.data || {},
        token: user.fcmToken,
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Notification envoyée:', response);
      
      return response;
    } catch (error) {
      console.error('❌ Erreur notification:', error);
      return null;
    }
  }

  /**
   * Envoyer une notification à un topic (ex: promos)
   */
  async sendTopicNotification(topic, notification) {
    try {
      ensureFirebaseInitialized();
      const messageNotification = {
        title: notification.title,
        body: notification.body,
      };

      if (typeof notification.image === 'string' && notification.image.trim().length > 0) {
        messageNotification.imageUrl = notification.image;
      }

      const message = {
        notification: messageNotification,
        data: notification.data || {},
        topic,
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Notification topic ${topic} envoyée:`, response);
      return response;
    } catch (error) {
      console.error('❌ Erreur notification topic:', error);
      return null;
    }
  }

  /**
   * Notification : Chauffeur trouvé
   */
  async notifyDriverFound(userId, driverData) {
    const notification = {
      title: '✅ Chauffeur trouvé !',
      body: `${driverData.name} arrive dans ${driverData.eta} minutes`,
      data: {
        type: 'driver_found',
        driverId: driverData.id,
        eta: driverData.eta.toString(),
      },
    };

    return this.sendPushNotification(userId, notification);
  }

  /**
   * Notification : Chauffeur en route
   */
  async notifyDriverArriving(userId, driverData) {
    const notification = {
      title: '🚗 Chauffeur en route',
      body: `${driverData.name} est à ${driverData.distance} km`,
      data: {
        type: 'driver_arriving',
        driverId: driverData.id,
      },
    };

    return this.sendPushNotification(userId, notification);
  }
}

module.exports = new NotificationService();

