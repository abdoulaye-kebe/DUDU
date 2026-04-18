/**
 * Distance Haversine (km) et ETA pour notifications passager.
 */
function distanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/** ETA en minutes (vitesse min. 18 km/h en ville si GPS trop lent). */
function etaMinutesFromDistance(distanceKm, speedKmh) {
  const v = Math.max(Number(speedKmh) || 0, 18);
  if (!Number.isFinite(distanceKm) || distanceKm <= 0) return 1;
  return Math.max(1, Math.ceil((distanceKm / v) * 60));
}

/**
 * Objet chauffeur + véhicule pour le client (socket / API).
 * @param {import('mongoose').Document} driver — document Driver Mongoose
 */
function buildDriverPayloadForPassenger(driver) {
  if (!driver) return null;
  const v = driver.vehicle || {};
  const rating =
    driver.stats && typeof driver.stats.averageRating === 'number'
      ? driver.stats.averageRating
      : 0;

  return {
    id: driver._id,
    firstName: driver.firstName,
    lastName: driver.lastName,
    fullName: `${driver.firstName || ''} ${driver.lastName || ''}`.trim(),
    name: `${driver.firstName || ''} ${driver.lastName || ''}`.trim(),
    phone: driver.phone,
    photo: driver.profilePhoto || null,
    rating,
    vehicle: {
      category: v.category || 'car',
      type: v.type || 'sedan',
      make: v.make || '',
      model: v.model || '',
      brand: v.make || '',
      color: v.color || '',
      plateNumber: v.plateNumber || '',
      year: v.year || null,
    },
  };
}

/**
 * ETA depuis position GPS vers pickup (acceptation).
 */
function estimateArrivalMinutesToPickup(driver, pickupLat, pickupLng) {
  const lat = driver?.location?.latitude;
  const lng = driver?.location?.longitude;
  if (
    lat == null ||
    lng == null ||
    pickupLat == null ||
    pickupLng == null
  ) {
    return 5;
  }
  const d = distanceKm(lat, lng, pickupLat, pickupLng);
  return etaMinutesFromDistance(d, 25);
}

module.exports = {
  distanceKm,
  etaMinutesFromDistance,
  buildDriverPayloadForPassenger,
  estimateArrivalMinutesToPickup,
};
