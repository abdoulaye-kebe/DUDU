const Driver = require('../models/Driver');

/**
 * Obtenir les chauffeurs en covoiturage disponibles dans un rayon donné
 */
exports.getAvailableCarpoolDrivers = async (req, res) => {
  try {
    const { latitude, longitude, radius = 1 } = req.query; // radius en km, défaut 1km

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude et longitude sont requises',
      });
    }

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);
    const radiusInMeters = parseFloat(radius) * 1000; // Convertir km en mètres

    console.log(`🔍 Recherche chauffeurs covoiturage: ${lat}, ${lon}, rayon: ${radius}km`);

    // Rechercher les chauffeurs dans le rayon spécifié
    const drivers = await Driver.find({
      status: 'online',
      isAvailable: true,
      'preferences.acceptSharedRides': true,
      'preferences.carpoolSeats': { $gt: 0 },
      'currentLocation.latitude': { $exists: true },
      'currentLocation.longitude': { $exists: true },
    }).populate('user', 'firstName lastName phone');

    // Filtrer par distance et calculer la distance exacte
    const driversWithDistance = drivers
      .map(driver => {
        const distance = calculateDistance(
          lat,
          lon,
          driver.currentLocation.latitude,
          driver.currentLocation.longitude
        );

        return {
          id: driver._id,
          name: `${driver.user?.firstName || ''} ${driver.user?.lastName || ''}`.trim(),
          phone: driver.user?.phone,
          vehicle: {
            make: driver.vehicle.make,
            model: driver.vehicle.model,
            color: driver.vehicle.color,
            plateNumber: driver.vehicle.plateNumber,
            capacity: driver.vehicle.capacity,
          },
          rating: driver.stats.averageRating,
          totalRides: driver.stats.completedRides,
          carpoolSeats: driver.preferences.carpoolSeats,
          distance: Math.round(distance * 10) / 10, // Arrondir à 1 décimale
          location: {
            latitude: driver.currentLocation.latitude,
            longitude: driver.currentLocation.longitude,
          },
        };
      })
      .filter(driver => driver.distance <= radius)
      .sort((a, b) => a.distance - b.distance); // Trier par distance croissante

    const totalSeats = driversWithDistance.reduce((sum, d) => sum + d.carpoolSeats, 0);

    console.log(`✅ Trouvé ${driversWithDistance.length} chauffeurs, ${totalSeats} places totales`);

    res.json({
      success: true,
      message: `${driversWithDistance.length} chauffeur(s) trouvé(s)`,
      data: {
        drivers: driversWithDistance,
        count: driversWithDistance.length,
        totalSeats,
        searchRadius: radius,
        userLocation: { latitude: lat, longitude: lon },
      },
    });
  } catch (error) {
    console.error('❌ Erreur recherche chauffeurs covoiturage:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la recherche des chauffeurs',
      error: error.message,
    });
  }
};

/**
 * Calculer la distance entre deux points GPS (formule Haversine)
 * Retourne la distance en kilomètres
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la Terre en km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return distance;
}

function toRad(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * Créer des chauffeurs de test pour simulation
 */
exports.createTestDrivers = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude et longitude sont requises',
      });
    }

    // Créer 5 chauffeurs de test autour de la position donnée
    const testDriversData = [
      { name: 'Mamadou', lastName: 'Sall', offsetKm: 0.5, seats: 3, car: 'Toyota', model: 'Corolla' },
      { name: 'Moussa', lastName: 'Ndiaye', offsetKm: 0.8, seats: 2, car: 'Renault', model: 'Symbol' },
      { name: 'Cheikh', lastName: 'Sy', offsetKm: 0.3, seats: 4, car: 'Peugeot', model: '301' },
      { name: 'Abdou', lastName: 'Diallo', offsetKm: 1.2, seats: 2, car: 'Honda', model: 'Civic' },
      { name: 'Ibrahima', lastName: 'Fall', offsetKm: 0.9, seats: 3, car: 'Hyundai', model: 'Accent' },
    ];

    const createdDrivers = [];

    for (const driverData of testDriversData) {
      // Calculer une position aléatoire autour du point donné
      const offsetLat = (Math.random() - 0.5) * (driverData.offsetKm / 111); // 1 degré ≈ 111 km
      const offsetLon = (Math.random() - 0.5) * (driverData.offsetKm / 111);

      // Créer ou mettre à jour le chauffeur
      const driver = {
        status: 'online',
        isAvailable: true,
        currentLocation: {
          latitude: latitude + offsetLat,
          longitude: longitude + offsetLon,
          lastUpdated: new Date(),
        },
        preferences: {
          acceptSharedRides: true,
          carpoolSeats: driverData.seats,
        },
        vehicle: {
          make: driverData.car,
          model: driverData.model,
          color: 'Blanche',
          capacity: 4,
        },
        stats: {
          averageRating: 4.5 + Math.random() * 0.4,
          completedRides: Math.floor(Math.random() * 200) + 50,
        },
      };

      createdDrivers.push(driver);
    }

    res.json({
      success: true,
      message: `${createdDrivers.length} chauffeurs de test créés`,
      data: createdDrivers,
    });
  } catch (error) {
    console.error('❌ Erreur création chauffeurs test:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création des chauffeurs de test',
      error: error.message,
    });
  }
};

