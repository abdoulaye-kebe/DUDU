const express = require('express');
const { body, validationResult } = require('express-validator');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Ride = require('../models/Ride');
const { auth, requireDriver, requireActiveSubscription, requireLocation, requireOnline, requireAvailable } = require('../middleware/auth');
const router = express.Router();

// @route   POST /api/v1/drivers/register
// @desc    Enregistrer un chauffeur
// @access  Private (utilisateur connecté)
router.post('/register', [
  auth,
  body('driverLicense.number').notEmpty().withMessage('Le numéro de permis est requis'),
  body('driverLicense.expiryDate').isISO8601().withMessage('Date d\'expiration invalide'),
  body('vehicle.make').notEmpty().withMessage('La marque du véhicule est requise'),
  body('vehicle.model').notEmpty().withMessage('Le modèle du véhicule est requis'),
  body('vehicle.year').isInt({ min: 1990, max: new Date().getFullYear() + 1 }),
  body('vehicle.color').notEmpty().withMessage('La couleur du véhicule est requise'),
  body('vehicle.plateNumber').notEmpty().withMessage('Le numéro de plaque est requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Données invalides',
        errors: errors.array()
      });
    }

    // Vérifier si l'utilisateur est déjà chauffeur
    const existingDriver = await Driver.findOne({ user: req.userId });
    if (existingDriver) {
      return res.status(400).json({
        success: false,
        message: 'Vous êtes déjà enregistré comme chauffeur'
      });
    }

    const {
      driverLicense,
      vehicle,
      workingZones = [],
      preferences = {}
    } = req.body;

    // Créer le chauffeur
    const driver = new Driver({
      user: req.userId,
      driverLicense,
      vehicle,
      workingZones,
      preferences,
      verificationStatus: 'pending'
    });

    await driver.save();

    res.status(201).json({
      success: true,
      message: 'Inscription en tant que chauffeur réussie. Votre compte est en attente de vérification.',
      data: {
        driver: {
          id: driver._id,
          verificationStatus: driver.verificationStatus,
          vehicle: driver.vehicle,
          createdAt: driver.createdAt
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'enregistrement du chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/drivers/profile
// @desc    Obtenir le profil du chauffeur
// @access  Private (chauffeur)
router.get('/profile', auth, requireDriver, async (req, res) => {
  try {
    const driver = await Driver.findById(req.driver._id)
      .populate('user', 'firstName lastName phone email');

    res.json({
      success: true,
      data: {
        driver: {
          id: driver._id,
          user: {
            firstName: driver.user.firstName,
            lastName: driver.user.lastName,
            phone: driver.user.phone,
            email: driver.user.email
          },
          driverLicense: driver.driverLicense,
          vehicle: driver.vehicle,
          status: driver.status,
          isAvailable: driver.isAvailable,
          currentLocation: driver.currentLocation,
          workingZones: driver.workingZones,
          subscription: driver.subscription,
          earnings: driver.earnings,
          stats: driver.stats,
          preferences: driver.preferences,
          verificationStatus: driver.verificationStatus,
          specialModes: driver.specialModes,
          createdAt: driver.createdAt
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du profil chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/drivers/profile
// @desc    Mettre à jour le profil du chauffeur
// @access  Private (chauffeur)
router.put('/profile', [
  auth,
  requireDriver,
  body('vehicle.make').optional().notEmpty(),
  body('vehicle.model').optional().notEmpty(),
  body('vehicle.year').optional().isInt({ min: 1990, max: new Date().getFullYear() + 1 }),
  body('vehicle.color').optional().notEmpty(),
  body('preferences.maxDistance').optional().isFloat({ min: 1, max: 100 }),
  body('preferences.minPrice').optional().isFloat({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Données invalides',
        errors: errors.array()
      });
    }

    const { vehicle, preferences, workingZones } = req.body;
    
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    // Mettre à jour les champs fournis
    if (vehicle) {
      Object.assign(driver.vehicle, vehicle);
    }
    if (preferences) {
      Object.assign(driver.preferences, preferences);
    }
    if (workingZones) {
      driver.workingZones = workingZones;
    }

    await driver.save();

    res.json({
      success: true,
      message: 'Profil chauffeur mis à jour avec succès',
      data: {
        driver: {
          vehicle: driver.vehicle,
          preferences: driver.preferences,
          workingZones: driver.workingZones
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour du profil chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/drivers/location
// @desc    Mettre à jour la localisation du chauffeur
// @access  Private (chauffeur)
router.put('/location', [
  auth,
  requireDriver,
  body('latitude').isFloat().withMessage('Latitude invalide'),
  body('longitude').isFloat().withMessage('Longitude invalide'),
  body('address').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Données invalides',
        errors: errors.array()
      });
    }

    const { latitude, longitude, address } = req.body;
    
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    // Mettre à jour la localisation
    driver.updateLocation(latitude, longitude, address);
    await driver.save();

    res.json({
      success: true,
      message: 'Localisation mise à jour avec succès',
      data: {
        location: driver.currentLocation
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour de la localisation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/drivers/status
// @desc    Mettre à jour le statut du chauffeur
// @access  Private (chauffeur)
router.put('/status', [
  auth,
  requireDriver,
  body('status').isIn(['offline', 'online', 'busy', 'unavailable']).withMessage('Statut invalide'),
  body('isAvailable').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Données invalides',
        errors: errors.array()
      });
    }

    const { status, isAvailable } = req.body;
    
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    driver.status = status;
    if (isAvailable !== undefined) {
      driver.isAvailable = isAvailable;
    }

    await driver.save();

    res.json({
      success: true,
      message: 'Statut mis à jour avec succès',
      data: {
        status: driver.status,
        isAvailable: driver.isAvailable
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/drivers/rides
// @desc    Obtenir l'historique des courses du chauffeur
// @access  Private (chauffeur)
router.get('/rides', auth, requireDriver, async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = { driver: req.driver._id };
    if (status) {
      filter.status = status;
    }

    const rides = await Ride.find(filter)
      .populate('passenger', 'firstName lastName phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Ride.countDocuments(filter);

    res.json({
      success: true,
      data: {
        rides: rides.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          pickup: ride.pickup,
          destination: ride.destination,
          distance: ride.distance,
          estimatedDuration: ride.estimatedDuration,
          pricing: ride.pricing,
          status: ride.status,
          rideType: ride.rideType,
          passenger: ride.passenger ? {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          } : null,
          requestedAt: ride.requestedAt,
          completedAt: ride.completedAt,
          rating: ride.rating
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalRides: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des courses:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/drivers/earnings
// @desc    Obtenir les revenus du chauffeur
// @access  Private (chauffeur)
router.get('/earnings', auth, requireDriver, async (req, res) => {
  try {
    const { period = 'today' } = req.query;
    
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    let startDate, endDate;
    const now = new Date();

    switch (period) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        endDate = new Date(startDate.getTime() + 24 * 60 * 60 * 1000);
        break;
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        endDate = now;
        break;
      case 'month':
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        endDate = now;
        break;
      default:
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        endDate = new Date(startDate.getTime() + 24 * 60 * 60 * 1000);
    }

    // Calculer les revenus pour la période
    const earnings = await Ride.aggregate([
      {
        $match: {
          driver: driver._id,
          status: 'completed',
          completedAt: { $gte: startDate, $lt: endDate }
        }
      },
      {
        $group: {
          _id: null,
          totalEarnings: { $sum: '$pricing.totalPrice' },
          totalRides: { $sum: 1 },
          averageEarnings: { $avg: '$pricing.totalPrice' }
        }
      }
    ]);

    const result = earnings.length > 0 ? earnings[0] : {
      totalEarnings: 0,
      totalRides: 0,
      averageEarnings: 0
    };

    res.json({
      success: true,
      data: {
        period,
        startDate,
        endDate,
        earnings: {
          total: result.totalEarnings,
          rides: result.totalRides,
          average: Math.round(result.averageEarnings),
          daily: driver.earnings.today,
          weekly: driver.earnings.thisWeek,
          monthly: driver.earnings.thisMonth,
          allTime: driver.earnings.total
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des revenus:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/drivers/nearby-rides
// @desc    Obtenir les courses à proximité
// @access  Private (chauffeur en ligne)
router.get('/nearby-rides', auth, requireDriver, requireActiveSubscription, requireLocation, requireOnline, async (req, res) => {
  try {
    const { radius = 2, limit = 10 } = req.query; // rayon en km
    
    const driver = await Driver.findById(req.driver._id);
    if (!driver || !driver.currentLocation) {
      return res.status(400).json({
        success: false,
        message: 'Localisation requise'
      });
    }

    // Trouver les courses à proximité
    const nearbyRides = await Ride.find({
      status: { $in: ['requested', 'searching'] },
      'pickup.coordinates': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [driver.currentLocation.longitude, driver.currentLocation.latitude]
          },
          $maxDistance: radius * 1000 // convertir en mètres
        }
      }
    })
    .populate('passenger', 'firstName lastName phone')
    .limit(parseInt(limit))
    .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: {
        rides: nearbyRides.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          pickup: ride.pickup,
          destination: ride.destination,
          distance: ride.distance,
          estimatedDuration: ride.estimatedDuration,
          pricing: ride.pricing,
          rideType: ride.rideType,
          passenger: {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          },
          requestedAt: ride.requestedAt,
          // Calculer la distance du chauffeur au point de prise en charge
          driverDistance: driver.calculateDistance(
            ride.pickup.coordinates.latitude,
            ride.pickup.coordinates.longitude
          )
        }))
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des courses à proximité:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/drivers/stats
// @desc    Obtenir les statistiques du chauffeur
// @access  Private (chauffeur)
router.get('/stats', auth, requireDriver, async (req, res) => {
  try {
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    // Statistiques des 30 derniers jours
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const monthlyStats = await Ride.aggregate([
      {
        $match: {
          driver: driver._id,
          status: 'completed',
          completedAt: { $gte: thirtyDaysAgo }
        }
      },
      {
        $group: {
          _id: null,
          totalRides: { $sum: 1 },
          totalEarnings: { $sum: '$pricing.totalPrice' },
          averageRating: { $avg: '$rating.driver.rating' },
          totalDistance: { $sum: '$distance' }
        }
      }
    ]);

    const stats = monthlyStats.length > 0 ? monthlyStats[0] : {
      totalRides: 0,
      totalEarnings: 0,
      averageRating: 0,
      totalDistance: 0
    };

    res.json({
      success: true,
      data: {
        overall: {
          totalRides: driver.stats.totalRides,
          completedRides: driver.stats.completedRides,
          cancelledRides: driver.stats.cancelledRides,
          averageRating: driver.stats.averageRating,
          totalEarnings: driver.stats.totalEarnings,
          totalDistance: driver.stats.totalDistance
        },
        monthly: {
          rides: stats.totalRides,
          earnings: stats.totalEarnings,
          averageRating: Math.round(stats.averageRating * 10) / 10,
          distance: Math.round(stats.totalDistance * 10) / 10
        },
        today: driver.getTodayStats(),
        subscription: {
          type: driver.subscription.type,
          isActive: driver.isSubscriptionValid(),
          endDate: driver.subscription.endDate
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des statistiques:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;
