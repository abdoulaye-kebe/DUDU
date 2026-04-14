const cron = require('node-cron');
const Ride = require('../models/Ride');
const notificationService = require('../services/notificationService');

/**
 * Rappels chauffeur + client : 2h, 1h, 30 min et 15 min avant la course planifiée.
 * Fenêtres en minutes restantes (minutesUntil) pour tolérer un cron chaque minute.
 */
const REMINDER_TIERS = [
  { key: '120m', label: '2 heures', minM: 118, maxM: 120 },
  { key: '60m', label: '1 heure', minM: 58, maxM: 60 },
  { key: '30m', label: '30 minutes', minM: 28, maxM: 30 },
  { key: '15m', label: '15 minutes', minM: 13, maxM: 15 },
];

module.exports = function startScheduledRidesReminder(io) {
  if (!io) return;

  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();

      const rides = await Ride.find({
        scheduledFor: { $gt: now },
        status: 'accepted',
        driver: { $exists: true, $ne: null },
      })
        .populate({ path: 'driver', populate: { path: 'user', select: 'firstName lastName phone fcmToken' } })
        .populate('passenger');

      if (!rides.length) return;

      for (const ride of rides) {
        try {
          const driver = ride.driver;
          const passenger = ride.passenger;
          if (!driver || !passenger) continue;

          const scheduledTime = new Date(ride.scheduledFor);
          const minutesUntil = Math.round((scheduledTime - now) / (1000 * 60));
          const sent = ride.scheduledRemindersSent || [];

          const tier = REMINDER_TIERS.find(
            (t) => minutesUntil >= t.minM && minutesUntil <= t.maxM && !sent.includes(t.key),
          );
          if (!tier) continue;

          const hours = scheduledTime.getHours().toString().padStart(2, '0');
          const minutes = scheduledTime.getMinutes().toString().padStart(2, '0');
          const timeString = `${hours}:${minutes}`;

          const driverName = driver.user
            ? `${driver.user.firstName} ${driver.user.lastName}`
            : 'Votre chauffeur';
          const vehicleInfo = driver.vehicle
            ? `${driver.vehicle.brand} ${driver.vehicle.model} ${driver.vehicle.color}`
            : 'Véhicule';

          // --- Chauffeur (push + socket) — sendPushNotification(userId, { title, body, data })
          if (driver.user && driver.user.fcmToken) {
            try {
              await notificationService.sendPushNotification(driver.user._id, {
                title: `🔔 Rappel (${tier.label})`,
                body:
                  `Course planifiée dans ${minutesUntil} min à ${timeString}. Client: ${passenger.firstName} ${passenger.lastName}`,
                data: {
                  type: 'scheduled_ride_reminder',
                  tier: tier.key,
                  rideId: ride._id.toString(),
                  scheduledFor: ride.scheduledFor.toISOString(),
                  pickup: String(ride.pickup?.address ?? ''),
                  destination: String(ride.destination?.address ?? ''),
                },
              });
            } catch (err) {
              console.error('❌ Rappel push chauffeur:', err);
            }
          }

          io.to(`driver_${driver._id}`).emit('scheduled-ride-reminder', {
            rideId: ride._id,
            tier: tier.key,
            scheduledFor: ride.scheduledFor,
            timeUntil: minutesUntil,
            passenger: {
              name: `${passenger.firstName} ${passenger.lastName}`,
              phone: passenger.phone,
            },
            pickup: ride.pickup,
            destination: ride.destination,
            pricing: ride.pricing,
          });

          // --- Client (push + socket)
          if (passenger.fcmToken) {
            try {
              await notificationService.sendPushNotification(passenger._id, {
                title: `🔔 Rappel (${tier.label})`,
                body:
                  `${driverName} viendra vous chercher dans ${minutesUntil} min (prévu ${timeString}). ${vehicleInfo}`,
                data: {
                  type: 'scheduled_ride_reminder',
                  tier: tier.key,
                  rideId: ride._id.toString(),
                  scheduledFor: ride.scheduledFor.toISOString(),
                  driverName,
                  driverPhone: String(driver.user?.phone ?? ''),
                  vehicleInfo,
                },
              });
            } catch (err) {
              console.error('❌ Rappel push client:', err);
            }
          }

          io.to(`passenger_${passenger._id}`).emit('scheduled-ride-reminder', {
            rideId: ride._id,
            tier: tier.key,
            scheduledFor: ride.scheduledFor,
            timeUntil: minutesUntil,
            driver: {
              id: driver._id,
              name: driverName,
              phone: driver.user?.phone || '',
              photo: driver.photo || null,
              rating: driver.stats?.averageRating || 0,
              vehicle: {
                brand: driver.vehicle?.brand || '',
                model: driver.vehicle?.model || '',
                color: driver.vehicle?.color || '',
                plate: driver.vehicle?.licensePlate || '',
              },
            },
            pickup: ride.pickup,
            destination: ride.destination,
          });

          ride.scheduledRemindersSent = [...sent, tier.key];
          ride.reminderSent = true;
          await ride.save();

          console.log('🔔 Rappel envoyé', tier.key, 'course', ride._id.toString());
        } catch (err) {
          console.error('🔔 Erreur rappel pour une course:', err);
        }
      }
    } catch (error) {
      console.error('🔔 Reminder - erreur globale:', error);
    }
  });

  console.log('🔔 Service de rappels planifiés (2h / 1h / 30m / 15m) démarré');
};
