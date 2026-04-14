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
      acceptExpressRides
    } = req.body;

    // Mettre à jour les préférences
    if (maxDistance !== undefined) driver.preferences.maxDistance = maxDistance;
    if (minPrice !== undefined) driver.preferences.minPrice = minPrice;
    if (workingHours !== undefined) driver.preferences.workingHours = workingHours;
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

