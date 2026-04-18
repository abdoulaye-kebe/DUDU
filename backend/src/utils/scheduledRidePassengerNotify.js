const notificationService = require('../services/notificationService');

function passengerIdFromRide(ride) {
  if (!ride || !ride.passenger) return null;
  if (typeof ride.passenger === 'object' && ride.passenger._id) {
    return ride.passenger._id;
  }
  return ride.passenger;
}

function driverDisplayName(driver) {
  if (!driver) return '';
  var a = driver.firstName || '';
  var b = driver.lastName || '';
  var n = (a + ' ' + b).trim();
  return n;
}

/**
 * Push FCM au passager lorsqu'un trajet planifié est accepté (infos chauffeur + véhicule).
 */
async function sendScheduledRideAcceptedPush(ride, driver) {
  if (!ride || !ride.scheduledFor || !ride.passenger || !driver) return;
  try {
    var v = driver.vehicle || {};
    var name = driverDisplayName(driver) || 'Chauffeur DuDu';
    var veh = [v.make, v.model].filter(Boolean).join(' ');
    var extra = [v.color, v.plateNumber].filter(Boolean).join(' • ');
    var body =
      name +
      ' — ' +
      veh +
      (extra ? ' — ' + extra : '') +
      ' — ' +
      (driver.phone || '');

    var passengerId = passengerIdFromRide(ride);
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
  if (!ride || !ride.passenger || !driver) return;
  try {
    var v = driver.vehicle || {};
    var name = driverDisplayName(driver) || 'Votre chauffeur';
    var veh = [v.make, v.model].filter(Boolean).join(' ');
    var plate = v.plateNumber || '';
    var title;
    var body;
    if (phase === 'en_route') {
      title = '🚗 Votre chauffeur est en route';
      body =
        name +
        ' a quitté pour venir vous chercher. ' +
        veh +
        (plate ? ' — ' + plate : '');
    } else if (phase === 'at_pickup') {
      title = '📍 Votre chauffeur est sur place';
      body =
        name +
        ' vous attend au point de rencontre. ' +
        veh +
        (plate ? ' — ' + plate : '');
    } else {
      return;
    }

    var passengerId = passengerIdFromRide(ride);
    await notificationService.sendPushNotification(passengerId, {
      title: title,
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
