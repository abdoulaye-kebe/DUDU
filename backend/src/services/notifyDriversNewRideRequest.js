const Driver = require('../models/Driver');
const { getDriverNotifyMaxDistanceM } = require('../config/driverMatch.config');
const { buildNewRideRequestPayload } = require('../utils/buildNewRideRequestPayload');
const { buildDriverQueryForRideType } = require('../utils/driverRideTypeMatch');

/**
 * Chauffeurs en ligne, abonnement actif, vérif approuvée, type de course compatible, à proximité du pickup.
 */
async function findNearbyAvailableDrivers(
  pickupLng,
  pickupLat,
  maxDistanceMeters = getDriverNotifyMaxDistanceM(),
  rideType = 'standard'
) {
  const typeQuery = buildDriverQueryForRideType(rideType);

  return Driver.find({
    status: 'online',
    isAvailable: true,
    verificationStatus: 'approved',
    'subscription.isActive': true,
    'subscription.endDate': { $gt: new Date() },
    ...typeQuery,
    'currentLocation.coordinates': { $exists: true },
    currentLocation: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [pickupLng, pickupLat],
        },
        $maxDistance: maxDistanceMeters,
      },
    },
  });
}

/**
 * Émet un événement new-ride-request avec le même format que socketHandler.js
 * (pickup/destination objets complets, id + rideId, passager, pricing, scheduledFor optionnel).
 *
 * @returns {Promise<{ notified: number, driverIds: string[] }>}
 */
/**
 * @param {{ maxDistanceMeters?: number }} [options] — ex. courses planifiées : 20 km (20000 m)
 */
async function notifyDriversNewRideRequest(io, ride, passengerUser, options = {}) {
  if (!io || !ride) {
    return { notified: 0, driverIds: [] };
  }

  const pickup = ride.pickup;
  const dest = ride.destination;
  const lat = pickup?.coordinates?.latitude;
  const lng = pickup?.coordinates?.longitude;
  if (lat == null || lng == null) {
    console.warn('notifyDriversNewRideRequest: coordonnées pickup manquantes', ride._id);
    return { notified: 0, driverIds: [] };
  }

  const maxM =
    options.maxDistanceMeters != null && Number.isFinite(Number(options.maxDistanceMeters))
      ? Number(options.maxDistanceMeters)
      : getDriverNotifyMaxDistanceM();

  const rideType = ride.rideType || 'standard';
  const availableDrivers = await findNearbyAvailableDrivers(lng, lat, maxM, rideType);
  if (!availableDrivers.length) {
    return { notified: 0, driverIds: [] };
  }

  const rideData = buildNewRideRequestPayload(ride, passengerUser);

  const driverIds = [];
  availableDrivers.forEach((driver) => {
    const distance = driver.calculateDistance
      ? driver.calculateDistance(lat, lng)
      : 0;
    const roomId = `driver_${driver._id.toString()}`;
    io.to(roomId).emit('new-ride-request', {
      ...rideData,
      driverDistance: distance,
    });
    driverIds.push(driver._id.toString());
  });

  return { notified: availableDrivers.length, driverIds };
}

module.exports = {
  notifyDriversNewRideRequest,
  findNearbyAvailableDrivers,
};
