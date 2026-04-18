const notificationService = require('../services/notificationService');

/**
 * Push FCM au passager lorsqu’un trajet planifié est accepté (infos chauffeur + véhicule).
 */
async function sendScheduledRideAcceptedPush(ride, driver) {
  if (!ride?.scheduledFor || !ride.passenger || !driver) return;
  try {
    const v = driver.vehicle || {};
    const name = `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || 'Chauffeur DuDu';
    const veh = [v.make, v.model].filter(Boolean).join(' ');
    const extra = [v.color, v.plateNumber].filter(Boolean).join(' • ');
    const body = `${name} — ${veh}${extra ? ' — ' + extra : ''} — ${driver.phone || ''}';

    const passengerId =
      typeof ride.passenger === 'object' && ride.passenger?._id
        ? ride.passenger._id
        : ride.passenger;
    await notificationService.sendPushNotification(passengerId, {
      title: 'Trajet planifié — chauffeur confirmé',
      body: body.trim(),
      data: {
        type: 'scheduled_ride_accepted',
        rideId: String(ride._id),
        scheduledFor: ride.scheduledFor.toISOString(),
      },
    });
  } catch (e) {
    console.warn('sendScheduledRideAcceptedPush:', e.message);
  }
}

/**
 * Push FCM : chauffeur « en route » ou « sur place » (trajet planifié).
 * @param {'en_route'|'at_pickup'} phase
 */
async function sendScheduledPickupPhasePush(ride, driver, phase) {
  if (!ride?.passenger || !driver) return;
  try {
    const v = driver.vehicle || {};
    const name = `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || 'Votre chauffeur';
    const veh = [v.make, v.model].filter(Boolean).join(' ');
    const plate = v.plateNumber || '';
    let title;
    let body;
    if (phase === 'en_route') {
      title = '🚗 Votre chauffeur est en route';
      body = `${name} a quitté pour venir vous chercher. ${veh}${plate ? ' — ' + plate : ''}`;
    } else if (phase === 'at_pickup') {
      title = '📍 Votre chauffeur est sur place';
      body = `${name} vous attend au point de rencontre. ${veh}${plate ? ' — ' + plate : ''}`;
    } else {
      return;
    }

    const passengerId =
      typeof ride.passenger === 'object' && ride.passenger?._id
        ? ride.passenger._id
        : ride.passenger;
    await notificationService.sendPushNotification(passengerId, {
      title,
      body: body.trim(),
      data: {
        type: 'scheduled_pickup_update',
        phase: String(phase),
        rideId: String(ride._id),
      },
    });
  } catch (e) {
    console.warn('sendScheduledPickupPhasePush:', e.message);
  }
}

module.exports = { sendScheduledRideAcceptedPush, sendScheduledPickupPhasePush };
