/**
 * Contraintes MongoDB pour qu'un chauffeur soit éligible à une course
 * selon le type choisi par le client (standard, confort, luxe, femmes, livraison, moto).
 *
 * @param {string} [rideType]
 * @returns {Record<string, unknown>}
 */
function buildDriverQueryForRideType(rideType) {
  const rt = rideType || 'standard';

  if (rt === 'delivery') {
    return {
      'vehicle.category': 'moto',
      'rideTypes.delivery': true,
    };
  }
  if (rt === 'moto') {
    return {
      'vehicle.category': 'moto',
      'rideTypes.moto': true,
    };
  }
  if (rt === 'women_only') {
    return {
      'rideTypes.women_only': true,
      gender: 'female',
    };
  }
  if (rt === 'comfort') {
    return {
      'vehicle.category': 'car',
      'rideTypes.comfort': true,
    };
  }
  if (rt === 'luxe') {
    return {
      'vehicle.category': 'car',
      'rideTypes.luxe': true,
    };
  }
  // standard (défaut) : voiture uniquement — les motos (livreurs / taxi moto) ont leurs propres rideType
  return {
    'vehicle.category': 'car',
    'rideTypes.standard': true,
  };
}

module.exports = {
  buildDriverQueryForRideType,
};
