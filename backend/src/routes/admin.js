const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const Payment = require('../models/Payment');
const Subscription = require('../models/Subscription');
const { auth } = require('../middleware/auth');
const router = express.Router();

// Middleware pour vérifier les droits d'administration
const requireAdmin = (req, res, next) => {
  // TODO: Implémenter un système de rôles d'administration
  // Pour l'instant, on considère que tous les utilisateurs sont admin
  next();
};

// @route   GET /api/v1/admin/dashboard
// @desc    Obtenir les statistiques du tableau de bord
// @access  Private (admin)
router.get('/dashboard', auth, requireAdmin, async (req, res) => {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Statistiques générales
    const totalUsers = await User.countDocuments();
    const totalDrivers = await Driver.countDocuments();
    const totalRides = await Ride.countDocuments();
    const totalPayments = await Payment.countDocuments();

    // Statistiques du jour
    const todayUsers = await User.countDocuments({ createdAt: { $gte: startOfDay } });
    const todayDrivers = await Driver.countDocuments({ createdAt: { $gte: startOfDay } });
    const todayRides = await Ride.countDocuments({ createdAt: { $gte: startOfDay } });
    const todayPayments = await Payment.countDocuments({ createdAt: { $gte: startOfDay } });

    // Revenus
    const todayRevenue = await Payment.aggregate([
      { $match: { createdAt: { $gte: startOfDay }, status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    const monthlyRevenue = await Payment.aggregate([
      { $match: { createdAt: { $gte: startOfMonth }, status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    // Courses par statut
    const ridesByStatus = await Ride.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    // Chauffeurs par statut
    const driversByStatus = await Driver.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    // Abonnements actifs
    const activeSubscriptions = await Subscription.countDocuments({ status: 'active' });
    const expiringSubscriptions = await Subscription.countDocuments({
      status: 'active',
      endDate: { $lte: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) }
    });

    // Top chauffeurs (par nombre de courses)
    const topDrivers = await Driver.aggregate([
      { $lookup: { from: 'rides', localField: '_id', foreignField: 'driver', as: 'rides' } },
      { $match: { 'rides.status': 'completed' } },
      { $project: { 
        user: 1, 
        vehicle: 1, 
        totalRides: { $size: '$rides' },
        totalEarnings: { $sum: '$rides.pricing.totalPrice' }
      }},
      { $sort: { totalRides: -1 } },
      { $limit: 5 }
    ]);

    // Courses récentes
    const recentRides = await Ride.find()
      .populate('passenger', 'firstName lastName phone')
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName')
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          totalDrivers,
          totalRides,
          totalPayments,
          activeSubscriptions
        },
        today: {
          users: todayUsers,
          drivers: todayDrivers,
          rides: todayRides,
          payments: todayPayments,
          revenue: todayRevenue.length > 0 ? todayRevenue[0].total : 0
        },
        monthly: {
          revenue: monthlyRevenue.length > 0 ? monthlyRevenue[0].total : 0
        },
        charts: {
          ridesByStatus: ridesByStatus.reduce((acc, item) => {
            acc[item._id] = item.count;
            return acc;
          }, {}),
          driversByStatus: driversByStatus.reduce((acc, item) => {
            acc[item._id] = item.count;
            return acc;
          }, {})
        },
        alerts: {
          expiringSubscriptions,
          pendingVerifications: await Driver.countDocuments({ verificationStatus: 'pending' })
        },
        topDrivers: topDrivers.map(driver => ({
          id: driver._id,
          name: driver.user ? `${driver.user.firstName} ${driver.user.lastName}` : 'Inconnu',
          vehicle: driver.vehicle ? `${driver.vehicle.make} ${driver.vehicle.model}` : 'N/A',
          totalRides: driver.totalRides,
          totalEarnings: driver.totalEarnings
        })),
        recentRides: recentRides.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          passenger: ride.passenger ? {
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          } : null,
          driver: ride.driver ? {
            name: ride.driver.user ? 
              `${ride.driver.user.firstName} ${ride.driver.user.lastName}` : 
              'Inconnu',
            vehicle: ride.driver.vehicle ? 
              `${ride.driver.vehicle.make} ${ride.driver.vehicle.plateNumber}` : 
              'N/A'
          } : null,
          status: ride.status,
          pricing: ride.pricing,
          createdAt: ride.createdAt
        }))
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du tableau de bord:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/admin/users
// @desc    Obtenir la liste des utilisateurs
// @access  Private (admin)
router.get('/users', auth, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, search, status, verified } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = {};
    if (search) {
      filter.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }
    if (status) filter.isActive = status === 'active';
    if (verified !== undefined) filter.isVerified = verified === 'true';

    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(filter);

    res.json({
      success: true,
      data: {
        users: users.map(user => ({
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          email: user.email,
          isVerified: user.isVerified,
          isActive: user.isActive,
          totalRides: user.totalRides,
          totalSpent: user.totalSpent,
          averageRating: user.averageRating,
          createdAt: user.createdAt,
          lastActive: user.updatedAt
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalUsers: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/admin/drivers
// @desc    Obtenir la liste des chauffeurs
// @access  Private (admin)
router.get('/drivers', auth, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, search, status, verificationStatus } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = {};
    if (search) {
      filter.$or = [
        { 'vehicle.make': { $regex: search, $options: 'i' } },
        { 'vehicle.model': { $regex: search, $options: 'i' } },
        { 'vehicle.plateNumber': { $regex: search, $options: 'i' } }
      ];
    }
    if (status) filter.status = status;
    if (verificationStatus) filter.verificationStatus = verificationStatus;

    const drivers = await Driver.find(filter)
      .populate('user', 'firstName lastName phone email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Driver.countDocuments(filter);

    res.json({
      success: true,
      data: {
        drivers: drivers.map(driver => ({
          id: driver._id,
          user: {
            firstName: driver.user.firstName,
            lastName: driver.user.lastName,
            phone: driver.user.phone,
            email: driver.user.email
          },
          vehicle: driver.vehicle,
          status: driver.status,
          isAvailable: driver.isAvailable,
          verificationStatus: driver.verificationStatus,
          subscription: driver.subscription,
          stats: driver.stats,
          earnings: driver.earnings,
          createdAt: driver.createdAt
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalDrivers: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des chauffeurs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/admin/drivers/:id/verify
// @desc    Vérifier un chauffeur
// @access  Private (admin)
router.put('/drivers/:id/verify', [
  auth,
  requireAdmin,
  body('status').isIn(['approved', 'rejected']).withMessage('Statut de vérification invalide'),
  body('notes').optional().isString()
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

    const { status, notes = '' } = req.body;

    const driver = await Driver.findById(req.params.id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    driver.verificationStatus = status;
    driver.verificationNotes = notes;
    driver.isVerified = status === 'approved';

    if (status === 'approved') {
      driver.isActive = true;
    }

    await driver.save();

    res.json({
      success: true,
      message: `Chauffeur ${status === 'approved' ? 'approuvé' : 'rejeté'} avec succès`,
      data: {
        driver: {
          id: driver._id,
          verificationStatus: driver.verificationStatus,
          isVerified: driver.isVerified,
          isActive: driver.isActive
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la vérification du chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/admin/rides
// @desc    Obtenir la liste des courses
// @access  Private (admin)
router.get('/rides', auth, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, dateFrom, dateTo } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = {};
    if (status) filter.status = status;
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo);
    }

    const rides = await Ride.find(filter)
      .populate('passenger', 'firstName lastName phone')
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName')
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
          pricing: ride.pricing,
          status: ride.status,
          rideType: ride.rideType,
          passenger: ride.passenger ? {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          } : null,
          driver: ride.driver ? {
            id: ride.driver._id,
            name: ride.driver.user ? 
              `${ride.driver.user.firstName} ${ride.driver.user.lastName}` : 
              'Inconnu',
            vehicle: ride.driver.vehicle ? 
              `${ride.driver.vehicle.make} ${ride.driver.vehicle.plateNumber}` : 
              'N/A'
          } : null,
          requestedAt: ride.requestedAt,
          completedAt: ride.completedAt,
          cancelledAt: ride.cancelledAt
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

// @route   GET /api/v1/admin/payments
// @desc    Obtenir la liste des paiements
// @access  Private (admin)
router.get('/payments', auth, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, method, dateFrom, dateTo } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = {};
    if (status) filter.status = status;
    if (method) filter.method = method;
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo);
    }

    const payments = await Payment.find(filter)
      .populate('user', 'firstName lastName phone')
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName')
      .populate('ride', 'rideId pickup destination')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Payment.countDocuments(filter);

    // Calculer les revenus totaux
    const totalRevenue = await Payment.aggregate([
      { $match: { status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    res.json({
      success: true,
      data: {
        payments: payments.map(payment => ({
          id: payment._id,
          paymentId: payment.paymentId,
          type: payment.type,
          amount: payment.amount,
          currency: payment.currency,
          method: payment.method,
          status: payment.status,
          user: payment.user ? {
            name: `${payment.user.firstName} ${payment.user.lastName}`,
            phone: payment.user.phone
          } : null,
          driver: payment.driver ? {
            name: payment.driver.user ? 
              `${payment.driver.user.firstName} ${payment.driver.user.lastName}` : 
              'Inconnu'
          } : null,
          ride: payment.ride ? {
            rideId: payment.ride.rideId,
            pickup: payment.ride.pickup,
            destination: payment.ride.destination
          } : null,
          initiatedAt: payment.initiatedAt,
          completedAt: payment.completedAt,
          isVerified: payment.isVerified
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalPayments: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        },
        summary: {
          totalRevenue: totalRevenue.length > 0 ? totalRevenue[0].total : 0
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des paiements:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/admin/users/:id/status
// @desc    Modifier le statut d'un utilisateur
// @access  Private (admin)
router.put('/users/:id/status', [
  auth,
  requireAdmin,
  body('isActive').isBoolean().withMessage('Statut actif requis')
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

    const { isActive } = req.body;

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    user.isActive = isActive;
    await user.save();

    res.json({
      success: true,
      message: `Utilisateur ${isActive ? 'activé' : 'désactivé'} avec succès`,
      data: {
        user: {
          id: user._id,
          isActive: user.isActive
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la modification du statut utilisateur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;




