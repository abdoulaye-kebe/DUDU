const admin = require('firebase-admin');
const Driver = require('../models/Driver');
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
   * Notification : Chauffeurs covoiturage disponibles
   */
  async notifyCarpoolAvailable(userId, location, carpoolData) {
    const { driversCount, totalSeats, averageDistance } = carpoolData;

    if (driversCount < 3) {
      return; // Pas assez de chauffeurs pour notifier
    }

    const notification = {
      title: '🤝 Covoiturage disponible !',
      body: `${driversCount} chauffeurs près de vous • ${totalSeats} places • Économisez jusqu'à 20%`,
      image: null,
      data: {
        type: 'carpool_available',
        driversCount: driversCount.toString(),
        totalSeats: totalSeats.toString(),
        averageDistance: averageDistance.toString(),
      },
    };

    return this.sendPushNotification(userId, notification);
  }

  /**
   * Notification : Nouveau chauffeur covoiturage proche
   */
  async notifyNewCarpoolDriver(userId, driverData) {
    const notification = {
      title: '🚗 Nouveau chauffeur en covoiturage',
      body: `${driverData.name} est maintenant disponible à ${driverData.distance} km`,
      data: {
        type: 'new_carpool_driver',
        driverId: driverData.id,
        distance: driverData.distance.toString(),
      },
    };

    return this.sendPushNotification(userId, notification);
  }

  /**
   * Notification : Prix réduit disponible
   */
  async notifyPriceReduction(userId, savings) {
    const notification = {
      title: '💰 Prix réduit !',
      body: `Économisez ${savings} FCFA avec le covoiturage maintenant`,
      data: {
        type: 'price_reduction',
        savings: savings.toString(),
      },
    };

    return this.sendPushNotification(userId, notification);
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

  /**
   * Notification : Promotion covoiturage (heures de pointe)
   */
  async notifyCarpoolPromotion(userId) {
    const notification = {
      title: '🎉 Promotion Covoiturage !',
      body: 'Profitez de -25% sur vos courses partagées pendant 1h',
      data: {
        type: 'carpool_promo',
        discount: '25',
      },
    };

    return this.sendPushNotification(userId, notification);
  }

  /**
   * Envoyer notification à tous les utilisateurs d'une zone
   */
  async notifyUsersInArea(location, radius, notification) {
    try {
      // Trouver tous les utilisateurs dans la zone
      const users = await User.find({
        'lastKnownLocation': {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [location.longitude, location.latitude],
            },
            $maxDistance: radius * 1000, // Convertir km en mètres
          },
        },
        fcmToken: { $exists: true, $ne: null },
        'preferences.pushNotifications': true,
      });

      console.log(`📢 Envoi notification à ${users.length} utilisateurs`);

      const promises = users.map(user =>
        this.sendPushNotification(user._id, notification)
      );

      const results = await Promise.allSettled(promises);
      const success = results.filter(r => r.status === 'fulfilled').length;

      console.log(`✅ ${success}/${users.length} notifications envoyées`);
      
      return { total: users.length, success };
    } catch (error) {
      console.error('❌ Erreur notification zone:', error);
      return { total: 0, success: 0 };
    }
  }

  /**
   * Analyser la disponibilité covoiturage et notifier si nécessaire
   */
  async analyzeCarpoolAvailability(location) {
    try {
      // Compter les chauffeurs covoiturage dans la zone (5km)
      const drivers = await Driver.find({
        status: 'online',
        isAvailable: true,
        'preferences.acceptSharedRides': true,
        'preferences.carpoolSeats': { $gt: 0 },
        'currentLocation': {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [location.longitude, location.latitude],
            },
            $maxDistance: 5000, // 5km
          },
        },
      });

      const driversCount = drivers.length;
      const totalSeats = drivers.reduce((sum, d) => sum + d.preferences.carpoolSeats, 0);

      // Si seuil atteint (ex: 5+ chauffeurs), notifier les utilisateurs
      if (driversCount >= 5) {
        const notification = {
          title: '🤝 Beaucoup de covoiturages disponibles !',
          body: `${driversCount} chauffeurs • ${totalSeats} places • Économisez maintenant`,
          data: {
            type: 'carpool_surge',
            driversCount: driversCount.toString(),
            totalSeats: totalSeats.toString(),
          },
        };

        await this.notifyUsersInArea(location, 3, notification);
      }

      return { driversCount, totalSeats };
    } catch (error) {
      console.error('❌ Erreur analyse covoiturage:', error);
      return { driversCount: 0, totalSeats: 0 };
    }
  }

  /**
   * Notification personnalisée basée sur les habitudes
   */
  async notifyBasedOnHabits(userId) {
    try {
      const user = await User.findById(userId).populate('rideHistory');
      
      // Analyser les habitudes
      const usualTime = new Date().getHours();
      const usualDays = new Date().getDay();
      
      // Si l'utilisateur prend souvent des courses à cette heure
      const habitsMatch = user.rideHistory?.some(ride => {
        const rideHour = new Date(ride.requestedAt).getHours();
        const rideDay = new Date(ride.requestedAt).getDay();
        return Math.abs(rideHour - usualTime) <= 1 && rideDay === usualDays;
      });

      if (habitsMatch) {
        const notification = {
          title: '🕐 Votre heure habituelle de trajet',
          body: 'Des chauffeurs en covoiturage sont disponibles près de vous',
          data: {
            type: 'habit_reminder',
          },
        };

        return this.sendPushNotification(userId, notification);
      }
    } catch (error) {
      console.error('❌ Erreur notification habitudes:', error);
    }
  }
}

module.exports = new NotificationService();

