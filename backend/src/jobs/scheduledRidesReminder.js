const cron = require('node-cron');
const Ride = require('../models/Ride');
const notificationService = require('../services/notificationService');

/**
 * Rappels client + chauffeur : 2h, 1h et 30 min avant la course planifiée.
 * Fenêtres en minutes restantes (minutesUntil) pour tolérer un cron chaque minute.
 */
const REMINDER_TIERS = [
  { key: '120m', label: '2 heures', minM: 118, maxM: 120 },
  { key: '60m', label: '1 heure', minM: 58, maxM: 60 },
  { key: '30m', label: '30 minutes', minM: 28, maxM: 30 },
];

function minutesUntil(scheduledFor, now) {
  return Math.round((new Date(scheduledFor) - now) / (1000 * 60));
}

function pickTier(minutes, sent) {
  const list = sent || [];
  return REMINDER_TIERS.find(
    (t) => minutes >= t.minM && minutes <= t.maxM && !list.includes(t.key),
  );
}

function formatTimeString(scheduledTime) {
  const d = new Date(scheduledTime);
  const hours = d.getHours().toString().padStart(2, '0');
  const minutes = d.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}

/**
 * Course acceptée avec chauffeur : push chauffeur (token User ou Driver) + passager + sockets.
 */
async function processAcceptedScheduledReminders(io, now) {
  const rides = await Ride.find({
    scheduledFor: { $gt: now },
    status: 'accepted',
    driver: { $exists: true, $ne: null },
  })
    .populate({ path: 'driver', populate: { path: 'user', select: 'firstName lastName phone fcmToken' } })
    .populate('passenger');

  for (const ride of rides) {
    try {
      const driver = ride.driver;
      const passenger = ride.passenger;
      if (!driver || !passenger) continue;

      const m = minutesUntil(ride.scheduledFor, now);
      const sent = ride.scheduledRemindersSent || [];
      const tier = pickTier(m, sent);
      if (!tier) continue;

      const timeString = formatTimeString(ride.scheduledFor);

      const nameFromDriver = `${driver.firstName || ''} ${driver.lastName || ''}`.trim();
      const nameFromUser = driver.user
        ? `${driver.user.firstName || ''} ${driver.user.lastName || ''}`.trim()
        : '';
      const driverName = nameFromDriver || nameFromUser || 'Votre chauffeur';
      const v = driver.vehicle || {};
      const vehicleInfo = [v.make, v.model, v.color, v.plateNumber]
        .filter(Boolean)
        .join(' ')
        .trim() || 'Véhicule';

      await notificationService.sendPushToDriver(driver._id, {
        title: `🔔 Rappel (${tier.label})`,
        body:
          `Course planifiée dans ${m} min à ${timeString}. Client: ${passenger.firstName} ${passenger.lastName}`,
        data: {
          type: 'scheduled_ride_reminder',
          tier: tier.key,
          rideId: ride._id.toString(),
          scheduledFor: ride.scheduledFor.toISOString(),
          pickup: String(ride.pickup?.address ?? ''),
          destination: String(ride.destination?.address ?? ''),
        },
      });

      io.to(`driver_${driver._id}`).emit('scheduled-ride-reminder', {
        rideId: ride._id,
        tier: tier.key,
        scheduledFor: ride.scheduledFor,
        timeUntil: m,
        passenger: {
          name: `${passenger.firstName} ${passenger.lastName}`,
          phone: passenger.phone,
        },
        pickup: ride.pickup,
        destination: ride.destination,
        pricing: ride.pricing,
      });

      if (passenger.fcmToken) {
        try {
          await notificationService.sendPushNotification(passenger._id, {
            title: `🔔 Rappel (${tier.label})`,
            body:
              `${driverName} viendra vous chercher dans ${m} min (prévu ${timeString}). ${vehicleInfo}`,
            data: {
              type: 'scheduled_ride_reminder',
              tier: tier.key,
              rideId: ride._id.toString(),
              scheduledFor: ride.scheduledFor.toISOString(),
              driverName,
              driverPhone: String(driver.phone ?? driver.user?.phone ?? ''),
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
        timeUntil: m,
        driver: {
          id: driver._id,
          name: driverName,
          phone: driver.phone || driver.user?.phone || '',
          photo: driver.photo || null,
          rating: driver.stats?.averageRating || 0,
          vehicle: {
            make: driver.vehicle?.make || '',
            model: driver.vehicle?.model || '',
            brand: driver.vehicle?.make || '',
            color: driver.vehicle?.color || '',
            plateNumber: driver.vehicle?.plateNumber || '',
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
      console.error('🔔 Erreur rappel (acceptée):', err);
    }
  }
}

/**
 * Course planifiée encore sans chauffeur : rappels passager uniquement (push + socket).
 */
async function processPendingScheduledReminders(io, now) {
  const rides = await Ride.find({
    scheduledFor: { $gt: now },
    status: 'requested',
    $or: [{ driver: null }, { driver: { $exists: false } }],
  }).populate('passenger');

  for (const ride of rides) {
    try {
      const passenger = ride.passenger;
      if (!passenger) continue;

      const m = minutesUntil(ride.scheduledFor, now);
      const sent = ride.scheduledRemindersSent || [];
      const tier = pickTier(m, sent);
      if (!tier) continue;

      const timeString = formatTimeString(ride.scheduledFor);

      if (passenger.fcmToken) {
        try {
          await notificationService.sendPushNotification(passenger._id, {
            title: `🔔 Rappel (${tier.label})`,
            body:
              `Votre trajet planifié est dans ${m} min (prévu à ${timeString}). Nous poursuivons la recherche d’un chauffeur.`,
            data: {
              type: 'scheduled_ride_reminder',
              tier: tier.key,
              rideId: ride._id.toString(),
              scheduledFor: ride.scheduledFor.toISOString(),
              pendingDriverAssignment: 'true',
            },
          });
        } catch (err) {
          console.error('❌ Rappel push client (sans chauffeur):', err);
        }
      }

      io.to(`passenger_${passenger._id}`).emit('scheduled-ride-reminder', {
        rideId: ride._id,
        tier: tier.key,
        scheduledFor: ride.scheduledFor,
        timeUntil: m,
        pendingDriverAssignment: true,
        pickup: ride.pickup,
        destination: ride.destination,
      });

      ride.scheduledRemindersSent = [...sent, tier.key];
      ride.reminderSent = true;
      await ride.save();

      console.log('🔔 Rappel passager (sans chauffeur)', tier.key, 'course', ride._id.toString());
    } catch (err) {
      console.error('🔔 Erreur rappel (en attente):', err);
    }
  }
}

module.exports = function startScheduledRidesReminder(io) {
  if (!io) return;

  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      await processAcceptedScheduledReminders(io, now);
      await processPendingScheduledReminders(io, now);
    } catch (error) {
      console.error('🔔 Reminder - erreur globale:', error);
    }
  });

  console.log('🔔 Service de rappels planifiés (2h / 1h / 30m) démarré');
};
