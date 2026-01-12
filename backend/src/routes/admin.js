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
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Accès réservé aux administrateurs'
    });
  }
  next();
};

// Toutes les routes admin sont protégées
router.use(auth, requireAdmin);

// @route   GET /api/v1/admin/dashboard
// @desc    Obtenir les statistiques du tableau de bord
// @access  Private (admin)
router.get('/dashboard', async (req, res) => {
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
      { $addFields: { completedRides: { $filter: { input: '$rides', as: 'ride', cond: { $eq: ['$$ride.status', 'completed'] } } } } },
      { $project: { 
        firstName: 1,
        lastName: 1,
        vehicle: 1, 
        totalRides: { $size: '$completedRides' },
        totalEarnings: { $sum: '$completedRides.pricing.totalPrice' }
      }},
      { $match: { totalRides: { $gt: 0 } } },
      { $sort: { totalRides: -1 } },
      { $limit: 5 }
    ]);

    // Courses récentes
    const recentRides = await Ride.find()
      .populate('passenger', 'firstName lastName phone')
      .populate('driver', 'firstName lastName phone vehicle')
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
          name: `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || 'Chauffeur',
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
            name: `${ride.driver.firstName || ''} ${ride.driver.lastName || ''}`.trim() || 'Chauffeur',
            phone: ride.driver.phone,
            vehicle: ride.driver.vehicle ? 
              `${ride.driver.vehicle.make || ''} ${ride.driver.vehicle.plateNumber || ''}`.trim() : 
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
router.get('/users', async (req, res) => {
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

// @route   PUT /api/v1/admin/drivers/:id/verify
// @desc    Vérifier et valider un chauffeur (définir niveau de service Standard/Express)
// @access  Private (admin)
router.put('/drivers/:id/verify', [
  body('status').isIn(['approved', 'rejected']).withMessage('Statut de vérification invalide'),
  body('serviceLevel').optional().isIn(['standard', 'express', 'luxe']).withMessage('Niveau de service invalide'),
  body('womenOnlyOverride').optional().isBoolean().withMessage('womenOnlyOverride invalide'),
  body('vehicleCondition').optional().isIn(['excellent', 'good', 'acceptable', 'rejected']),
  body('vehicleInspected').optional().isBoolean(),
  body('documentsVerified').optional().isBoolean(),
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

    const { 
      status, 
      serviceLevel = 'standard',
      womenOnlyOverride,
      vehicleCondition,
      vehicleInspected = false,
      documentsVerified = false,
      notes = '' 
    } = req.body;

    const driver = await Driver.findById(req.params.id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    // Mise à jour du statut de vérification
    driver.verificationStatus = status;
    driver.verificationNotes = notes;
    driver.isVerified = status === 'approved';
    driver.isActive = status === 'approved';
    driver.status = status === 'approved' ? 'offline' : 'pending';
    driver.isAvailable = false;

    // Si approuvé, définir le niveau de service
    if (status === 'approved') {
      driver.serviceLevel = serviceLevel;
      
      // Définir les types de courses autorisés selon le niveau de service
      driver.rideTypes = {
        standard: true,  // Tous les chauffeurs approuvés peuvent faire du standard
        comfort: serviceLevel === 'express',  // Seuls les chauffeurs validés "confort" (serviceLevel=express) peuvent faire du confort
        luxe: serviceLevel === 'luxe',
        delivery: driver.vehicle?.category === 'moto',  // Livraison pour les motos
        moto: driver.vehicle?.category === 'moto',
        women_only: typeof womenOnlyOverride === 'boolean' ? womenOnlyOverride : driver.gender === 'female'  // Override admin possible
      };
    }

    // Informations de validation par l'admin
    driver.adminValidation = {
      validatedBy: 'admin',
      validatedAt: new Date(),
      vehicleInspected,
      vehicleCondition,
      documentsVerified,
      notes
    };

    await driver.save();

    res.json({
      success: true,
      message: `Chauffeur ${status === 'approved' ? 'approuvé' : 'rejeté'} avec succès`,
      data: {
        driver: {
          id: driver._id,
          verificationStatus: driver.verificationStatus,
          isVerified: driver.isVerified,
          isActive: driver.isActive,
          serviceLevel: driver.serviceLevel,
          rideTypes: driver.rideTypes,
          adminValidation: driver.adminValidation
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
// @desc    Obtenir la liste des courses avec filtres avancés
// @access  Private (admin)
router.get('/rides', auth, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, dateFrom, dateTo, cancelledBy } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = {};
    
    // Filtre par statut (peut être multiple: completed, cancelled, in_progress)
    if (status) {
      if (status === 'in_progress') {
        // En cours = accepted, arriving, arrived, started
        filter.status = { $in: ['accepted', 'arriving', 'arrived', 'started'] };
      } else if (status.includes(',')) {
        filter.status = { $in: status.split(',') };
      } else {
        filter.status = status;
      }
    }
    
    // Filtre par qui a annulé (passenger, driver, system)
    if (cancelledBy) {
      filter['cancellation.cancelledBy'] = cancelledBy;
    }
    
    // Filtre par date
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo);
    }

    const rides = await Ride.find(filter)
      .populate('passenger', 'firstName lastName phone email')
      .populate('driver', 'firstName lastName phone vehicle')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Ride.countDocuments(filter);
    
    // Statistiques rapides
    const stats = {
      total: await Ride.countDocuments(),
      completed: await Ride.countDocuments({ status: 'completed' }),
      cancelled: await Ride.countDocuments({ status: 'cancelled' }),
      inProgress: await Ride.countDocuments({ 
        status: { $in: ['accepted', 'arriving', 'arrived', 'started'] }
      }),
      cancelledByPassenger: await Ride.countDocuments({ 
        status: 'cancelled',
        'cancellation.cancelledBy': 'passenger'
      }),
      cancelledByDriver: await Ride.countDocuments({ 
        status: 'cancelled',
        'cancellation.cancelledBy': 'driver'
      })
    };

    res.json({
      success: true,
      data: {
        rides: rides.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          pickup: {
            address: ride.pickup?.address,
            coordinates: ride.pickup?.coordinates
          },
          destination: {
            address: ride.destination?.address,
            coordinates: ride.destination?.coordinates
          },
          distance: ride.distance,
          pricing: ride.pricing,
          status: ride.status,
          rideType: ride.rideType,
          passenger: ride.passenger ? {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone,
            email: ride.passenger.email
          } : null,
          driver: ride.driver ? {
            id: ride.driver._id,
            name: `${ride.driver.firstName} ${ride.driver.lastName}`,
            phone: ride.driver.phone,
            vehicle: ride.driver.vehicle ? 
              `${ride.driver.vehicle.make} ${ride.driver.vehicle.model} - ${ride.driver.vehicle.plateNumber}` : 
              'N/A'
          } : null,
          requestedAt: ride.requestedAt,
          acceptedAt: ride.acceptedAt,
          startedAt: ride.startedAt,
          completedAt: ride.completedAt,
          cancelledAt: ride.cancelledAt,
          cancellation: ride.cancellation ? {
            reason: ride.cancellation.reason,
            cancelledBy: ride.cancellation.cancelledBy,
            refundAmount: ride.cancellation.refundAmount,
            refundProcessed: ride.cancellation.refundProcessed
          } : null,
          payment: {
            method: ride.payment?.method,
            status: ride.payment?.status,
            transactionId: ride.payment?.transactionId
          }
        })),
        stats,
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

// @route   GET /api/v1/admin/rides/cancelled
// @desc    Obtenir l'historique des courses annulées avec détails
// @access  Private (admin)
router.get('/rides/cancelled', auth, requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 50, cancelledBy, dateFrom, dateTo } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre pour courses annulées uniquement
    const filter = { status: 'cancelled' };
    
    if (cancelledBy) {
      filter['cancellation.cancelledBy'] = cancelledBy;
    }
    
    if (dateFrom || dateTo) {
      filter.cancelledAt = {};
      if (dateFrom) filter.cancelledAt.$gte = new Date(dateFrom);
      if (dateTo) filter.cancelledAt.$lte = new Date(dateTo);
    }

    const cancelledRides = await Ride.find(filter)
      .populate('passenger', 'firstName lastName phone email')
      .populate('driver', 'firstName lastName phone vehicle')
      .sort({ cancelledAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Ride.countDocuments(filter);
    
    // Statistiques d'annulation
    const cancellationStats = {
      total: total,
      byPassenger: await Ride.countDocuments({ 
        status: 'cancelled',
        'cancellation.cancelledBy': 'passenger'
      }),
      byDriver: await Ride.countDocuments({ 
        status: 'cancelled',
        'cancellation.cancelledBy': 'driver'
      }),
      bySystem: await Ride.countDocuments({ 
        status: 'cancelled',
        'cancellation.cancelledBy': 'system'
      }),
      totalRefundAmount: await Ride.aggregate([
        { $match: { status: 'cancelled', 'cancellation.refundAmount': { $exists: true } } },
        { $group: { _id: null, total: { $sum: '$cancellation.refundAmount' } } }
      ]).then(result => result[0]?.total || 0)
    };

    res.json({
      success: true,
      data: {
        cancelledRides: cancelledRides.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          pickup: {
            address: ride.pickup?.address,
            coordinates: ride.pickup?.coordinates
          },
          destination: {
            address: ride.destination?.address,
            coordinates: ride.destination?.coordinates
          },
          distance: ride.distance,
          pricing: ride.pricing,
          passenger: ride.passenger ? {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone,
            email: ride.passenger.email
          } : null,
          driver: ride.driver ? {
            id: ride.driver._id,
            name: `${ride.driver.firstName} ${ride.driver.lastName}`,
            phone: ride.driver.phone,
            vehicle: ride.driver.vehicle ? 
              `${ride.driver.vehicle.make} ${ride.driver.vehicle.model} - ${ride.driver.vehicle.plateNumber}` : 
              'N/A'
          } : null,
          requestedAt: ride.requestedAt,
          acceptedAt: ride.acceptedAt,
          cancelledAt: ride.cancelledAt,
          cancellation: {
            reason: ride.cancellation.reason,
            cancelledBy: ride.cancellation.cancelledBy,
            refundAmount: ride.cancellation.refundAmount,
            refundProcessed: ride.cancellation.refundProcessed
          },
          payment: {
            method: ride.payment?.method,
            status: ride.payment?.status
          }
        })),
        stats: cancellationStats,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalCancelled: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des courses annulées:', error);
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

// @route   POST /api/v1/admin/drivers
// @desc    Créer un nouveau chauffeur
// @access  Private (admin)
router.post('/drivers', async (req, res) => {
  try {
    const {
      firstName, lastName, phone, email, password, dateOfBirth, gender, nationalId,
      address, driverLicense, vehicle, rideTypes, preferences, subscription
    } = req.body;

    // Validation des champs requis
    if (!firstName || !lastName || !phone || !email) {
      return res.status(400).json({
        success: false,
        message: 'Les champs prénom, nom, téléphone et email sont requis'
      });
    }

    // Vérifier si le chauffeur existe déjà
    const existingDriver = await Driver.findOne({
      $or: [{ phone }, { email }, { 'driverLicense.number': driverLicense?.number }]
    });

    if (existingDriver) {
      return res.status(400).json({
        success: false,
        message: 'Un chauffeur avec ce téléphone, email ou numéro de permis existe déjà'
      });
    }

    // Utiliser le mot de passe fourni ou générer un par défaut
    const driverPassword = password || `dudu${phone.slice(-4)}`;

    // Créer le chauffeur (le mot de passe sera hashé automatiquement par le middleware pre-save)
    const driver = new Driver({
      firstName,
      lastName,
      phone,
      email,
      password: driverPassword,
      dateOfBirth,
      gender,
      nationalId,
      address,
      driverLicense,
      vehicle,
      rideTypes: rideTypes || {
        standard: true,
        express: false,
        shared: false,
        womenOnly: false
      },
      preferences: preferences || {
        maxDistance: 10,
        minPrice: 1000,
        acceptsShared: false
      },
      status: 'offline',
      isAvailable: false,
      isVerified: true, // Auto-approuvé par l'admin
      verificationStatus: 'approved',
      subscription: {
        plan: subscription?.plan || 'daily',
        isActive: subscription?.isActive !== undefined ? subscription.isActive : true,
        startDate: subscription?.startDate || new Date(),
        endDate: subscription?.endDate || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      }
    });

    await driver.save();

    // Retourner le chauffeur sans le mot de passe
    const driverResponse = driver.toObject();
    delete driverResponse.password;

    res.status(201).json({
      success: true,
      message: 'Chauffeur créé avec succès',
      driver: driverResponse
    });

  } catch (error) {
    console.error('Erreur création chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du chauffeur',
      error: error.message
    });
  }
});

// @route   GET /api/v1/admin/drivers
// @desc    Obtenir la liste des chauffeurs
// @access  Private (admin)
router.get('/drivers', async (req, res) => {
  try {
    const { status, verificationStatus, page = 1, limit = 50 } = req.query;
    
    const query = {};
    if (status) {
      query.status = status;
    }
    if (verificationStatus) {
      query.verificationStatus = verificationStatus;
    }

    const drivers = await Driver.find(query)
      .select('-__v -password')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Driver.countDocuments(query);

    res.json({
      success: true,
      drivers,
      pagination: {
        total,
        page: parseInt(page),
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Erreur récupération chauffeurs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des chauffeurs'
    });
  }
});

// @route   GET /api/v1/admin/driver-applications
// @desc    Obtenir les candidatures chauffeurs en attente
// @access  Private (admin)
router.get('/driver-applications', async (req, res) => {
  try {
    const drivers = await Driver.find({ verificationStatus: 'pending' })
      .select('-password -__v')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      applications: drivers
    });
  } catch (error) {
    console.error('Erreur récupération candidatures chauffeurs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des candidatures'
    });
  }
});

// @route   GET /api/v1/admin/drivers/:id
// @desc    Obtenir les détails d'un chauffeur
// @access  Private (admin)
router.get('/drivers/:id', async (req, res) => {
  try {
    const driver = await Driver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    res.json({
      success: true,
      driver
    });

  } catch (error) {
    console.error('Erreur récupération chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du chauffeur'
    });
  }
});

// @route   PUT /api/v1/admin/drivers/:id
// @desc    Mettre à jour un chauffeur
// @access  Private (admin)
router.put('/drivers/:id', async (req, res) => {
  try {
    // Trouver le chauffeur
    const driver = await Driver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    // Mettre à jour les champs
    Object.keys(req.body).forEach(key => {
      driver[key] = req.body[key];
    });

    // Sauvegarder (déclenche le middleware pre-save pour hasher le mot de passe)
    await driver.save();

    // Retourner sans le mot de passe
    const driverResponse = driver.toObject();
    delete driverResponse.password;

    res.json({
      success: true,
      message: 'Chauffeur mis à jour avec succès',
      driver: driverResponse
    });

  } catch (error) {
    console.error('Erreur mise à jour chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du chauffeur',
      error: error.message
    });
  }
});

// @route   DELETE /api/v1/admin/drivers/:id
// @desc    Supprimer un chauffeur
// @access  Private (admin)
router.delete('/drivers/:id', async (req, res) => {
  try {
    const driver = await Driver.findByIdAndDelete(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    res.json({
      success: true,
      message: 'Chauffeur supprimé avec succès'
    });

  } catch (error) {
    console.error('Erreur suppression chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression du chauffeur'
    });
  }
});

module.exports = router;




