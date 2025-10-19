const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Ride = require('../models/Ride');
const { auth, requireVerification } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/v1/users/profile
// @desc    Obtenir le profil de l'utilisateur
// @access  Private
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          email: user.email,
          address: user.address,
          language: user.language,
          currency: user.currency,
          isVerified: user.isVerified,
          referralCode: user.referralCode,
          profilePicture: user.profilePicture,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          totalRides: user.totalRides,
          totalSpent: user.totalSpent,
          averageRating: user.averageRating,
          budgetSettings: user.budgetSettings,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/users/profile
// @desc    Mettre à jour le profil de l'utilisateur
// @access  Private
router.put('/profile', [
  auth,
  body('firstName').optional().trim().isLength({ min: 2, max: 50 }),
  body('lastName').optional().trim().isLength({ min: 2, max: 50 }),
  body('email').optional().isEmail().normalizeEmail(),
  body('language').optional().isIn(['fr', 'wo']),
  body('currency').optional().isIn(['XOF', 'EUR', 'USD'])
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

    const { firstName, lastName, email, language, currency, dateOfBirth, gender } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Mettre à jour les champs fournis
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (email) user.email = email;
    if (language) user.language = language;
    if (currency) user.currency = currency;
    if (dateOfBirth) user.dateOfBirth = new Date(dateOfBirth);
    if (gender) user.gender = gender;

    await user.save();

    res.json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          email: user.email,
          language: user.language,
          currency: user.currency,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour du profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/users/address
// @desc    Mettre à jour l'adresse de l'utilisateur
// @access  Private
router.put('/address', [
  auth,
  body('street').notEmpty().withMessage('La rue est requise'),
  body('city').optional().trim(),
  body('neighborhood').optional().trim(),
  body('coordinates.latitude').isFloat().withMessage('Latitude invalide'),
  body('coordinates.longitude').isFloat().withMessage('Longitude invalide')
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

    const { street, city, neighborhood, coordinates } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    user.address = {
      street,
      city: city || 'Dakar',
      neighborhood,
      coordinates: {
        latitude: coordinates.latitude,
        longitude: coordinates.longitude
      }
    };

    await user.save();

    res.json({
      success: true,
      message: 'Adresse mise à jour avec succès',
      data: {
        address: user.address
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'adresse:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/users/budget-settings
// @desc    Mettre à jour les paramètres de budget
// @access  Private
router.put('/budget-settings', [
  auth,
  body('maxPricePerKm').optional().isFloat({ min: 0 }),
  body('preferredPaymentMethod').optional().isIn(['orange_money', 'wave', 'free_money', 'cash'])
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

    const { maxPricePerKm, preferredPaymentMethod } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    if (!user.budgetSettings) {
      user.budgetSettings = {};
    }

    if (maxPricePerKm !== undefined) {
      user.budgetSettings.maxPricePerKm = maxPricePerKm;
    }
    if (preferredPaymentMethod) {
      user.budgetSettings.preferredPaymentMethod = preferredPaymentMethod;
    }

    await user.save();

    res.json({
      success: true,
      message: 'Paramètres de budget mis à jour avec succès',
      data: {
        budgetSettings: user.budgetSettings
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour des paramètres de budget:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/users/rides
// @desc    Obtenir l'historique des courses de l'utilisateur
// @access  Private
router.get('/rides', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = { passenger: req.userId };
    if (status) {
      filter.status = status;
    }

    const rides = await Ride.find(filter)
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName phone')
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
          driver: ride.driver ? {
            id: ride.driver._id,
            name: ride.driver.user ? 
              `${ride.driver.user.firstName} ${ride.driver.user.lastName}` : 
              'Chauffeur inconnu',
            phone: ride.driver.user ? ride.driver.user.phone : null,
            vehicle: ride.driver.vehicle ? {
              make: ride.driver.vehicle.make,
              model: ride.driver.vehicle.model,
              color: ride.driver.vehicle.color,
              plateNumber: ride.driver.vehicle.plateNumber
            } : null
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

// @route   GET /api/v1/users/stats
// @desc    Obtenir les statistiques de l'utilisateur
// @access  Private
router.get('/stats', auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Statistiques des courses
    const totalRides = await Ride.countDocuments({ passenger: req.userId });
    const completedRides = await Ride.countDocuments({ 
      passenger: req.userId, 
      status: 'completed' 
    });
    const cancelledRides = await Ride.countDocuments({ 
      passenger: req.userId, 
      status: 'cancelled' 
    });

    // Montant total dépensé
    const totalSpent = await Ride.aggregate([
      { $match: { passenger: req.userId, status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$pricing.totalPrice' } } }
    ]);

    // Courses du mois
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const monthlyRides = await Ride.countDocuments({
      passenger: req.userId,
      status: 'completed',
      completedAt: { $gte: startOfMonth }
    });

    // Moyenne des prix
    const avgPrice = await Ride.aggregate([
      { $match: { passenger: req.userId, status: 'completed' } },
      { $group: { _id: null, average: { $avg: '$pricing.totalPrice' } } }
    ]);

    res.json({
      success: true,
      data: {
        totalRides,
        completedRides,
        cancelledRides,
        totalSpent: totalSpent.length > 0 ? totalSpent[0].total : 0,
        monthlyRides,
        averagePrice: avgPrice.length > 0 ? Math.round(avgPrice[0].average) : 0,
        averageRating: user.averageRating,
        memberSince: user.createdAt
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

// @route   POST /api/v1/users/upload-avatar
// @desc    Uploader une photo de profil
// @access  Private
router.post('/upload-avatar', auth, async (req, res) => {
  try {
    // TODO: Implémenter l'upload d'image avec Cloudinary
    res.json({
      success: true,
      message: 'Upload d\'avatar non encore implémenté'
    });

  } catch (error) {
    console.error('Erreur lors de l\'upload de l\'avatar:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   DELETE /api/v1/users/account
// @desc    Supprimer le compte utilisateur
// @access  Private
router.delete('/account', auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Vérifier s'il y a des courses en cours
    const activeRides = await Ride.countDocuments({
      passenger: req.userId,
      status: { $in: ['requested', 'searching', 'accepted', 'arriving', 'arrived', 'started'] }
    });

    if (activeRides > 0) {
      return res.status(400).json({
        success: false,
        message: 'Impossible de supprimer le compte avec des courses en cours'
      });
    }

    // Désactiver le compte au lieu de le supprimer
    user.isActive = false;
    await user.save();

    res.json({
      success: true,
      message: 'Compte désactivé avec succès'
    });

  } catch (error) {
    console.error('Erreur lors de la suppression du compte:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;




