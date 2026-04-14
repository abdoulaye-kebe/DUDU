const Driver = require('../models/Driver');

/**
 * Même recherche géo que socketHandler (request-ride) : chauffeurs en ligne à proximité du pickup.
 */
async function findNearbyAvailableDrivers(pickupLng, pickupLat, maxDistanceMeters = 2000) {
  return Driver.find({
    status: 'online',
    isAvailable: true,
    'subscription.isActive': true,
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
async function notifyDriversNewRideRequest(io, ride, passengerUser) {
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

  const availableDrivers = await findNearbyAvailableDrivers(lng, lat, 2000);
  if (!availableDrivers.length) {
    return { notified: 0, driverIds: [] };
  }

  const firstName = passengerUser?.firstName || 'Client';
  const lastName = passengerUser?.lastName || 'DUDU';

  const rideData = {
    id: ride._id,
    rideId: ride.rideId,
    pickup,
    destination: dest,
    pricing: ride.pricing,
    rideType: ride.rideType || 'standard',
    passenger: {
      id: passengerUser?._id,
      name: `${firstName} ${lastName}`.trim(),
      phone: passengerUser?.phone,
    },
    requestedAt: ride.requestedAt,
  };

  if (ride.scheduledFor) {
    rideData.scheduledFor = ride.scheduledFor;
  }

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
