const cron = require('node-cron');
const Ride = require('../models/Ride');
const Driver = require('../models/Driver');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

/**
 * Service de rappel automatique pour les courses planifiées
 * Envoie des notifications 1 heure avant la course au chauffeur ET au client
 */
module.exports = function startScheduledRidesReminder(io) {
  if (!io) return;

  // Vérifier toutes les 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    try {
      const now = new Date();
      // Fenêtre de 1 heure (55-65 minutes pour éviter les doublons)
      const reminderStart = new Date(now.getTime() + 55 * 60 * 1000);
      const reminderEnd = new Date(now.getTime() + 65 * 60 * 1000);

      // Trouver les courses planifiées qui ont un chauffeur assigné
      const rides = await Ride.find({
        scheduledFor: { $gte: reminderStart, $lte: reminderEnd },
        status: 'accepted',
        driver: { $exists: true, $ne: null },
        reminderSent: { $ne: true } // Éviter d'envoyer plusieurs fois
      })
      .populate('driver')
      .populate('passenger');

      if (!rides.length) return;

      console.log('🔔 Reminder - envoi de rappels pour', rides.length, 'courses planifiées');

      for (const ride of rides) {
        try {
          const driver = ride.driver;
          const passenger = ride.passenger;

          if (!driver || !passenger) continue;

          const scheduledTime = new Date(ride.scheduledFor);
          const timeUntil = Math.round((scheduledTime - now) / (1000 * 60)); // minutes

          // Formater l'heure de la course
          const hours = scheduledTime.getHours().toString().padStart(2, '0');
          const minutes = scheduledTime.getMinutes().toString().padStart(2, '0');
          const timeString = `${hours}:${minutes}`;

          // 1. NOTIFICATION AU CHAUFFEUR
          if (driver.user && driver.user.fcmToken) {
            try {
              await notificationService.sendPushNotification(
                driver.user.fcmToken,
                '🔔 Rappel de course planifiée',
                `Course dans ${timeUntil} min à ${timeString}. Client: ${passenger.firstName} ${passenger.lastName}`,
                {
                  type: 'scheduled_ride_reminder',
                  rideId: ride._id.toString(),
                  scheduledFor: ride.scheduledFor.toISOString(),
                  pickup: ride.pickup.address,
                  destination: ride.destination.address
                }
              );
              console.log('✅ Rappel envoyé au chauffeur:', driver._id);
            } catch (err) {
              console.error('❌ Erreur envoi rappel chauffeur:', err);
            }
          }

          // Notification Socket.IO au chauffeur
          io.to(`driver_${driver._id}`).emit('scheduled-ride-reminder', {
            rideId: ride._id,
            scheduledFor: ride.scheduledFor,
            timeUntil: timeUntil,
            passenger: {
              name: `${passenger.firstName} ${passenger.lastName}`,
              phone: passenger.phone
            },
            pickup: ride.pickup,
            destination: ride.destination,
            pricing: ride.pricing
          });

          // 2. NOTIFICATION AU CLIENT
          if (passenger.fcmToken) {
            try {
              const driverName = driver.user 
                ? `${driver.user.firstName} ${driver.user.lastName}`
                : 'Votre chauffeur';
              
              const vehicleInfo = driver.vehicle 
                ? `${driver.vehicle.brand} ${driver.vehicle.model} ${driver.vehicle.color}`
                : 'Véhicule';

              await notificationService.sendPushNotification(
                passenger.fcmToken,
                '🔔 Rappel de course planifiée',
                `${driverName} viendra vous chercher dans ${timeUntil} min à ${timeString}. ${vehicleInfo}`,
                {
                  type: 'scheduled_ride_reminder',
                  rideId: ride._id.toString(),
                  scheduledFor: ride.scheduledFor.toISOString(),
                  driver: {
                    name: driverName,
                    phone: driver.user?.phone || '',
                    vehicle: vehicleInfo
                  }
                }
              );
              console.log('✅ Rappel envoyé au client:', passenger._id);
            } catch (err) {
              console.error('❌ Erreur envoi rappel client:', err);
            }
          }

          // Notification Socket.IO au client
          io.to(`passenger_${passenger._id}`).emit('scheduled-ride-reminder', {
            rideId: ride._id,
            scheduledFor: ride.scheduledFor,
            timeUntil: timeUntil,
            driver: {
              id: driver._id,
              name: driver.user ? `${driver.user.firstName} ${driver.user.lastName}` : 'Chauffeur DUDU',
              phone: driver.user?.phone || '',
              photo: driver.photo || null,
              rating: driver.stats?.averageRating || 0,
              vehicle: {
                brand: driver.vehicle?.brand || '',
                model: driver.vehicle?.model || '',
                color: driver.vehicle?.color || '',
                plate: driver.vehicle?.licensePlate || ''
              }
            },
            pickup: ride.pickup,
            destination: ride.destination
          });

          // Marquer le rappel comme envoyé
          ride.reminderSent = true;
          await ride.save();

          console.log('🔔 Rappel envoyé pour la course:', {
            rideId: ride._id.toString(),
            scheduledFor: ride.scheduledFor,
            timeUntil: `${timeUntil} min`
          });

        } catch (err) {
          console.error('🔔 Erreur envoi rappel pour une course:', err);
        }
      }
    } catch (error) {
      console.error('🔔 Reminder - erreur globale:', error);
    }
  });

  console.log('🔔 Service de rappel automatique démarré');
};
