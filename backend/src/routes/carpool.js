/**
 * Routes covoiturage (côté passager : chauffeurs disponibles pour covoiturage)
 */
const express = require('express');
const Driver = require('../models/Driver');

const router = express.Router();

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// @route   GET /api/v1/carpool/drivers/available
// @desc    Chauffeurs disponibles pour covoiturage dans un rayon (pour l’app passager)
// @access  Public (ou auth selon besoin)
// @query   latitude, longitude, radius (km, défaut 1)
router.get('/drivers/available', async (req, res) => {
  try {
    const lat = parseFloat(req.query.latitude);
    const lng = parseFloat(req.query.longitude);
    const radiusKm = parseFloat(req.query.radius) || 1;
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({
        success: false,
        message: 'Paramètres latitude et longitude requis et numériques',
      });
    }

    const drivers = await Driver.find({
      verificationStatus: 'approved',
      status: 'online',
      isAvailable: true,
      'preferences.acceptSharedRides': true,
      currentLocation: { $exists: true, $ne: null },
      'currentLocation.coordinates': { $exists: true, $size: 2 },
    })
      .populate('user', 'firstName lastName')
      .lean();

    const inRadius = drivers.filter((d) => {
      const coords = d.currentLocation?.coordinates;
      if (!coords || coords.length < 2) return false;
      const [lon, latDriver] = coords;
      return haversineKm(lat, lng, latDriver, lon) <= radiusKm;
    });

    const totalSeats = inRadius.reduce((sum, d) => sum + (d.preferences?.carpoolSeats ?? 1), 0);
    const list = inRadius.map((d) => ({
      id: d._id,
      name: d.user ? `${d.user.firstName || ''} ${d.user.lastName || ''}`.trim() : `${d.firstName || ''} ${d.lastName || ''}`.trim(),
      seats: d.preferences?.carpoolSeats ?? 1,
      rating: d.rating ?? 0,
    }));

    res.json({
      success: true,
      data: {
        count: list.length,
        totalSeats,
        drivers: list,
      },
    });
  } catch (error) {
    console.error('Erreur GET /carpool/drivers/available:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur',
    });
  }
});

module.exports = router;
