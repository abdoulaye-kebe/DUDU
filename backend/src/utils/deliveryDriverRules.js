const Ride = require('../models/Ride');

const ACTIVE_RIDE_STATUSES = ['accepted', 'arriving', 'arrived', 'started'];

/**
 * Livraisons actives pour un livreur (non terminées / non annulées).
 */
async function getActiveDeliveryRides(driverId) {
  return Ride.find({
    driver: driverId,
    rideType: 'delivery',
    status: { $in: ACTIVE_RIDE_STATUSES },
  }).select('delivery.isUrgent');
}

function isDeliveryRideUrgent(ride) {
  return !!(ride && ride.delivery && ride.delivery.isUrgent === true);
}

/**
 * Un livreur peut-il recevoir la notification pour une nouvelle livraison ?
 * - Urgent : seulement si 0 livraison en cours (dédié, style Yango).
 * - Non urgent : jusqu'à 2 livraisons si aucune n'est urgente ; sinon refus si une urgente est en cours.
 */
async function driverShouldReceiveDeliveryNotification(driverId, newRideIsUrgent) {
  const active = await getActiveDeliveryRides(driverId);
  const n = active.length;
  if (n >= 2) return false;
  if (newRideIsUrgent) return n === 0;
  if (n === 0) return true;
  return !isDeliveryRideUrgent(active[0]);
}

/**
 * Un livreur peut-il accepter cette course livraison (socket ou HTTP) ?
 */
async function driverCanAcceptNewDelivery(driverId, incomingRide) {
  if (incomingRide.rideType !== 'delivery') {
    return { ok: true };
  }

  const active = await getActiveDeliveryRides(driverId);
  const n = active.length;
  if (n >= 2) {
    return {
      ok: false,
      code: 'MAX_DELIVERIES',
      message:
        'Vous avez déjà 2 livraisons en cours. Terminez-en une avant d\'en accepter une autre.',
    };
  }

  const incomingUrgent = isDeliveryRideUrgent(incomingRide);

  if (incomingUrgent) {
    if (n > 0) {
      return {
        ok: false,
        code: 'URGENT_REQUIRES_EMPTY',
        message:
          'Cette livraison est urgente : vous devez terminer la course en cours avant de l\'accepter.',
      };
    }
    return { ok: true };
  }

  if (n === 0) return { ok: true };
  if (isDeliveryRideUrgent(active[0])) {
    return {
      ok: false,
      code: 'STACK_BLOCKED_BY_URGENT',
      message:
        'Vous avez une livraison urgente en cours. Vous ne pouvez pas en empiler une autre pour le moment.',
    };
  }
  return { ok: true };
}

module.exports = {
  ACTIVE_RIDE_STATUSES,
  driverShouldReceiveDeliveryNotification,
  driverCanAcceptNewDelivery,
  isDeliveryRideUrgent,
};
