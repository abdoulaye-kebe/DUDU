const admin = require('firebase-admin');
const User = require('../models/User');
const Driver = require('../models/Driver');

function normalizeFcmData(data) {
  if (!data || typeof data !== 'object') return {};
  const out = {};
  for (const [k, v] of Object.entries(data)) {
    if (v === undefined || v === null) continue;
    out[k] = typeof v === 'string' ? v : String(v);
  }
  return out;
}

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
  /**
   * Push vers un chauffeur : token sur [User] lié ou sur le document [Driver].
   */
  async sendPushToDriver(driverId, notification) {
    try {
      ensureFirebaseInitialized();
      const driver = await Driver.findById(driverId).populate('user', 'fcmToken');
      if (!driver) {
        return null;
      }

      let token = null;
      if (driver.user && driver.user.fcmToken) {
        token = driver.user.fcmToken;
      } else if (driver.fcmToken) {
        token = driver.fcmToken;
      }
      if (!token) {
        console.log('Chauffeur sans token FCM');
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
        data: normalizeFcmData(notification.data || {}),
        token,
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Notification chauffeur envoyée:', response);
      return response;
    } catch (error) {
      console.error('❌ Erreur notification chauffeur:', error);
      return null;
    }
  }

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
        data: normalizeFcmData(notification.data || {}),
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
        data: normalizeFcmData(notification.data || {}),
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

