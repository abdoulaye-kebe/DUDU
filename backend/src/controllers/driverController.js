const Driver = require('../models/Driver');
const User = require('../models/User');
const Ride = require('../models/Ride');

// @desc    Obtenir le profil du chauffeur
// @route   GET /api/v1/drivers/profile
// @access  Private (Driver only)
exports.getProfile = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id })
      .populate('user', '-password');

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    res.status(200).json({
      success: true,
      data: { driver }
    });
  } catch (error) {
    console.error('Erreur récupération profil chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Mettre à jour les préférences du chauffeur
// @route   PUT /api/v1/drivers/preferences
// @access  Private (Driver only)
exports.updatePreferences = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const {
      maxDistance,
      minPrice,
      workingHours,
      acceptSharedRides,
      acceptExpressRides
    } = req.body;

    // Mettre à jour les préférences
    if (maxDistance !== undefined) driver.preferences.maxDistance = maxDistance;
    if (minPrice !== undefined) driver.preferences.minPrice = minPrice;
    if (workingHours !== undefined) driver.preferences.workingHours = workingHours;
    if (acceptSharedRides !== undefined) driver.preferences.acceptSharedRides = acceptSharedRides;
    if (acceptExpressRides !== undefined) driver.preferences.acceptExpressRides = acceptExpressRides;

    await driver.save();

    res.status(200).json({
      success: true,
      message: 'Préférences mises à jour avec succès',
      data: { driver }
    });
  } catch (error) {
    console.error('Erreur mise à jour préférences:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Activer/Désactiver le mode covoiturage
// @route   PUT /api/v1/drivers/carpool/toggle
// @access  Private (Driver only)
exports.toggleCarpoolMode = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const { enabled } = req.body;

    driver.preferences.acceptSharedRides = enabled;
    await driver.save();

    res.status(200).json({
      success: true,
      message: `Mode covoiturage ${enabled ? 'activé' : 'désactivé'}`,
      data: {
        carpoolEnabled: driver.preferences.acceptSharedRides
      }
    });
  } catch (error) {
    console.error('Erreur toggle covoiturage:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Mettre à jour la localisation du chauffeur
// @route   PUT /api/v1/drivers/location
// @access  Private (Driver only)
exports.updateLocation = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const { latitude, longitude, address } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude et longitude requises'
      });
    }

    driver.updateLocation(latitude, longitude, address);
    await driver.save();

    res.status(200).json({
      success: true,
      message: 'Localisation mise à jour',
      data: {
        location: driver.currentLocation
      }
    });
  } catch (error) {
    console.error('Erreur mise à jour localisation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Mettre à jour le statut du chauffeur
// @route   PUT /api/v1/drivers/status
// @access  Private (Driver only)
exports.updateStatus = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const { status, isAvailable } = req.body;

    if (status) {
      const validStatuses = ['offline', 'online', 'busy', 'unavailable'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: 'Statut invalide'
        });
      }
      driver.status = status;
    }

    if (isAvailable !== undefined) {
      driver.isAvailable = isAvailable;
    }

    await driver.save();

    res.status(200).json({
      success: true,
      message: 'Statut mis à jour',
      data: {
        status: driver.status,
        isAvailable: driver.isAvailable
      }
    });
  } catch (error) {
    console.error('Erreur mise à jour statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Trouver des courses compatibles pour le covoiturage
// @route   GET /api/v1/drivers/carpool/compatible-rides
// @access  Private (Driver only)
exports.getCompatibleCarpoolRides = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    if (!driver.preferences.acceptSharedRides) {
      return res.status(400).json({
        success: false,
        message: 'Le mode covoiturage n\'est pas activé'
      });
    }

    // Trouver les courses en attente ou en cours qui sont sur le même trajet
    const { currentRideId } = req.query;
    
    if (!currentRideId) {
      return res.status(400).json({
        success: false,
        message: 'ID de la course actuelle requis'
      });
    }

    const currentRide = await Ride.findById(currentRideId);
    
    if (!currentRide) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    // Trouver les courses dans un rayon proche du trajet actuel
    const compatibleRides = await Ride.find({
      _id: { $ne: currentRideId },
      status: { $in: ['requested', 'searching'] },
      rideType: { $in: ['standard', 'shared'] },
      'pickup.coordinates': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [
              currentRide.pickup.coordinates.longitude,
              currentRide.pickup.coordinates.latitude
            ]
          },
          $maxDistance: 5000 // 5 km de rayon
        }
      }
    }).limit(10);

    res.status(200).json({
      success: true,
      count: compatibleRides.length,
      data: { rides: compatibleRides }
    });
  } catch (error) {
    console.error('Erreur recherche courses compatibles:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Accepter une course partagée additionnelle
// @route   POST /api/v1/drivers/carpool/accept
// @access  Private (Driver only)
exports.acceptSharedRide = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const { currentRideId, newRideId } = req.body;

    if (!currentRideId || !newRideId) {
      return res.status(400).json({
        success: false,
        message: 'IDs des courses requis'
      });
    }

    const currentRide = await Ride.findById(currentRideId);
    const newRide = await Ride.findById(newRideId);

    if (!currentRide || !newRide) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    // Vérifier la capacité du véhicule
    const totalPassengers = currentRide.passengers + newRide.passengers;
    
    if (totalPassengers > driver.vehicle.capacity) {
      return res.status(400).json({
        success: false,
        message: 'Capacité du véhicule dépassée'
      });
    }

    // Marquer la nouvelle course comme partagée
    newRide.isShared = true;
    newRide.driver = driver._id;
    newRide.status = 'accepted';
    
    // Réduire le prix pour le passager (par exemple, 30% de réduction)
    newRide.sharedPrice = Math.round(newRide.pricing.totalPrice * 0.7);
    
    // Ajouter le passager à la liste des passagers partagés de la course actuelle
    if (!currentRide.sharedWith) {
      currentRide.sharedWith = [];
    }
    currentRide.sharedWith.push(newRide.passenger);
    currentRide.isShared = true;

    await currentRide.save();
    await newRide.save();

    res.status(200).json({
      success: true,
      message: 'Course partagée acceptée',
      data: {
        currentRide,
        newRide
      }
    });
  } catch (error) {
    console.error('Erreur acceptation course partagée:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Obtenir les statistiques du chauffeur
// @route   GET /api/v1/drivers/stats
// @access  Private (Driver only)
exports.getStats = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const stats = {
      earnings: driver.earnings,
      stats: driver.stats,
      todayStats: driver.getTodayStats(),
      subscriptionValid: driver.isSubscriptionValid()
    };

    res.status(200).json({
      success: true,
      data: { stats }
    });
  } catch (error) {
    console.error('Erreur récupération statistiques:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// @desc    Obtenir l'historique des courses du chauffeur
// @route   GET /api/v1/drivers/rides/history
// @access  Private (Driver only)
exports.getRidesHistory = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Profil chauffeur non trouvé'
      });
    }

    const { page = 1, limit = 10, status } = req.query;
    const query = { driver: driver._id };
    
    if (status) {
      query.status = status;
    }

    const rides = await Ride.find(query)
      .populate('passenger', 'firstName lastName phone')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();

    const count = await Ride.countDocuments(query);

    res.status(200).json({
      success: true,
      count: rides.length,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      data: { rides }
    });
  } catch (error) {
    console.error('Erreur récupération historique:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

module.exports = exports;

