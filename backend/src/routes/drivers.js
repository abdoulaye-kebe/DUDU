const express = require('express');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Ride = require('../models/Ride');
const { auth, requireDriver, requireActiveSubscription, requireLocation, requireOnline, requireAvailable } = require('../middleware/auth');
const router = express.Router();

const normalizePhoneNumber = (phone) => {
  if (!phone) return null;
  let normalized = phone.toString().trim();
  normalized = normalized.replace(/\s+/g, '');

  if (normalized.startsWith('+')) {
    normalized = '+' + normalized.slice(1).replace(/\D/g, '');
  } else {
    normalized = normalized.replace(/\D/g, '');
  }

  if (normalized.startsWith('+221')) {
    return normalized;
  }

  if (normalized.startsWith('221')) {
    return `+${normalized}`;
  }

  if (normalized.length === 9) {
    return `+221${normalized}`;
  }

  if (!normalized.startsWith('+') && normalized.length > 0) {
    return `+${normalized}`;
  }

  return normalized;
};

// @route   POST /api/v1/drivers/login
// @desc    Connexion d'un chauffeur
// @access  Public
router.post('/login', async (req, res) => {
  try {
    let { phone, password } = req.body;

    // Validation
    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Téléphone et mot de passe requis'
      });
    }

    // Normaliser le numéro de téléphone
    phone = normalizePhoneNumber(phone);

    // Vérifier que le chauffeur existe
    let driver = await Driver.findOne({ phone });

    // Création AUTOMATIQUE de comptes de test sur le backend local
    if (!driver && (phone === '+221786205992' || phone === '+221781000734')) {
      const isMotoCourier = phone === '+221781000734';

      console.log(
        `🧪 Création d'un ${isMotoCourier ? 'livreur moto' : 'chauffeur voiture'} de test pour ${phone}`
      );

      driver = new Driver({
        firstName: isMotoCourier ? 'Test' : 'Test',
        lastName: isMotoCourier ? 'Courier' : 'Driver',
        phone,
        email: isMotoCourier ? 'courier.test@example.com' : 'driver.test@example.com',
        password: '123456',
        dateOfBirth: new Date('1990-01-01'),
        gender: 'male',
        nationalId: isMotoCourier ? 'TEST-CNI-781000734' : 'TEST-CNI-786205992',
        address: {
          street: 'Rue de test',
          city: 'Dakar',
          region: 'Dakar',
          country: 'Sénégal',
          postalCode: '10000'
        },
        driverLicense: {
          number: isMotoCourier ? 'PERMIS-TEST-781000734' : 'PERMIS-TEST-786205992',
          expiryDate: new Date('2030-12-31'),
          issueDate: new Date('2020-01-01'),
          category: isMotoCourier ? 'A' : 'B'
        },
        vehicle: {
          make: isMotoCourier ? 'Moto' : 'Toyota',
          model: isMotoCourier ? 'Delivery' : 'Yaris',
          year: 2018,
          color: isMotoCourier ? 'Rouge' : 'Noir',
          plateNumber: isMotoCourier ? 'DK-LIV-781' : 'DK-TEST-786',
          category: isMotoCourier ? 'moto' : 'car',
          type: isMotoCourier ? 'moto_delivery' : 'sedan',
          capacity: isMotoCourier ? 1 : 4,
          hasAirConditioning: !isMotoCourier,
          features: isMotoCourier ? ['large_cargo'] : ['ac']
        },
        rideTypes: {
          standard: true,
          comfort: !isMotoCourier,
          delivery: isMotoCourier,
          women_only: false
        },
        isVerified: true,
        verificationStatus: 'approved'
      });

      await driver.save();
    }

    if (!driver) {
      return res.status(401).json({
        success: false,
        message: 'Chauffeur non trouvé. Contactez l\'administrateur pour créer votre compte.'
      });
    }

    // Bypass TEMPORAIRE pour tests: autoriser un mot de passe fixe pour les numéros de test
    let isPasswordValid = false;
    if ((phone === '+221786205992' || phone === '+221781000734') && password === '123456') {
      isPasswordValid = true;
    } else {
      // Comportement normal pour tous les autres chauffeurs
      isPasswordValid = await driver.comparePassword(password);
    }
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Mot de passe incorrect'
      });
    }

    if (!driver.isVerified || driver.verificationStatus !== 'approved') {
      return res.status(403).json({
        success: false,
        message: 'Votre compte chauffeur est en attente de validation par l\'administration.'
      });
    }
    
    // Activer automatiquement un abonnement hebdomadaire valide pour le chauffeur au moment du login si aucun abonnement actif n’est présent
    if (!driver.subscription || !driver.subscription.isActive) {
      const subscription = {
        type: 'weekly',
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        isActive: true
      };
      driver.subscription = subscription;
      await driver.save();
    }

    // Générer un token JWT
    const token = jwt.sign(
      { 
        id: driver._id,
        phone: driver.phone,
        type: 'driver'
      },
      process.env.JWT_SECRET || 'dudu_secret_key_2024',
      { expiresIn: '30d' }
    );

    const driverType = driver.vehicle && driver.vehicle.category === 'moto' ? 'courier' : 'driver';

    res.json({
      success: true,
      message: 'Connexion réussie',
      token,
      driver: {
        id: driver._id,
        firstName: driver.firstName,
        lastName: driver.lastName,
        phone: driver.phone,
        email: driver.email,
        status: driver.status,
        vehicle: driver.vehicle,
        rideTypes: driver.rideTypes,
        stats: driver.stats,
        subscription: driver.subscription,
        driverType
      }
    });

  } catch (error) {
    console.error('Erreur login chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la connexion'
    });
  }
});

// @route   POST /api/v1/drivers/apply
// @desc    Soumettre une candidature chauffeur
// @access  Public
router.post('/apply', [
  body('firstName').trim().isLength({ min: 2 }).withMessage('Le prénom est requis'),
  body('lastName').trim().isLength({ min: 2 }).withMessage('Le nom de famille est requis'),
  body('phone').trim().isLength({ min: 9 }).withMessage('Téléphone requis'),
  body('email').optional().isEmail().withMessage('Email invalide'),
  body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('dateOfBirth').optional().isISO8601().withMessage('Date de naissance invalide'),
  body('gender').optional().isIn(['male', 'female', 'other']).withMessage('Genre invalide'),
  body('nationalId').notEmpty().withMessage('La CNI est requise'),
  body('driverLicense.number').notEmpty().withMessage('Le numéro de permis est requis'),
  body('driverLicense.expiryDate').isISO8601().withMessage('La date d\'expiration du permis est requise'),
  body('vehicle.make').notEmpty().withMessage('La marque du véhicule est requise'),
  body('vehicle.model').notEmpty().withMessage('Le modèle du véhicule est requis'),
  body('vehicle.year').isInt({ min: 1990, max: new Date().getFullYear() + 1 }).withMessage('Année du véhicule invalide'),
  body('vehicle.color').notEmpty().withMessage('La couleur du véhicule est requise'),
  body('vehicle.plateNumber').notEmpty().withMessage('Le numéro de plaque est requis'),
  body('documents.insurance').notEmpty().withMessage("L'assurance est requise"),
  body('documents.insuranceExpiryDate').isISO8601().withMessage("La date de validité de l'assurance est invalide"),
  body('documents.technicalInspection').notEmpty().withMessage('Le contrôle technique est requis'),
  body('documents.technicalInspectionExpiryDate').isISO8601().withMessage("La date d'expiration du contrôle technique est invalide"),
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
      firstName,
      lastName,
      phone,
      email,
      password,
      dateOfBirth,
      gender,
      nationalId,
      address = {},
      driverLicense,
      vehicle,
      rideTypes = {},
      preferences = {},
      documents = {},
    } = req.body;

    const normalizedPhone = normalizePhoneNumber(phone);

    const duplicate = await Driver.findOne({
      $or: [
        { phone: normalizedPhone },
        email ? { email: email.toLowerCase() } : null,
        nationalId ? { nationalId } : null
      ].filter(Boolean)
    });

    if (duplicate) {
      return res.status(400).json({
        success: false,
        message: 'Un compte chauffeur existe déjà avec ces informations.'
      });
    }

    const driver = new Driver({
      firstName,
      lastName,
      phone: normalizedPhone,
      email: email?.toLowerCase(),
      password,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
      gender,
      nationalId,
      address: {
        street: address.street,
        city: address.city,
        region: address.region,
        country: address.country || 'Sénégal',
        postalCode: address.postalCode
      },
      driverLicense: {
        number: driverLicense.number,
        expiryDate: new Date(driverLicense.expiryDate),
        issueDate: driverLicense.issueDate ? new Date(driverLicense.issueDate) : undefined,
        category: driverLicense.category || 'B'
      },
      vehicle: {
        make: vehicle.make,
        model: vehicle.model,
        year: parseInt(vehicle.year, 10),
        color: vehicle.color,
        plateNumber: vehicle.plateNumber?.toUpperCase(),
        category: vehicle.category || 'car',
        type: vehicle.type || 'sedan',
        capacity: vehicle.capacity || 4,
        hasAirConditioning: vehicle.hasAirConditioning || false,
        features: vehicle.features || []
      },
      documents: {
        insurance: documents.insurance,
        insuranceExpiryDate: new Date(documents.insuranceExpiryDate),
        technicalInspection: documents.technicalInspection,
        technicalInspectionExpiryDate: new Date(documents.technicalInspectionExpiryDate),
        driverLicensePhoto: documents.driverLicensePhoto,
        vehicleRegistration: documents.vehicleRegistration,
        criminalRecord: documents.criminalRecord,
      },
      rideTypes: {
        standard: rideTypes.standard ?? true,
        express: rideTypes.express ?? false,
        shared: rideTypes.shared ?? false,
        womenOnly: rideTypes.womenOnly ?? false
      },
      preferences: {
        maxDistance: preferences.maxDistance ?? 10,
        minPrice: preferences.minPrice ?? 1000,
        acceptSharedRides: preferences.acceptSharedRides ?? true,
        acceptExpressRides: preferences.acceptExpressRides ?? true,
        acceptLuggage: preferences.acceptLuggage ?? false
      },
      status: 'pending',
      isAvailable: false,
      isVerified: false,
      verificationStatus: 'pending'
    });

    await driver.save();

    res.status(201).json({
      success: true,
      message: 'Votre demande a été envoyée. Vous serez informé(e) après vérification.',
      data: {
        driverId: driver._id,
        status: driver.verificationStatus
      }
    });
  } catch (error) {
    console.error('Erreur lors de la candidature chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

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
router.get('/profile', auth, async (req, res) => {
  try {
    // Trouver le chauffeur par son ID (depuis le token)
    const driver = await Driver.findById(req.user.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    const driverType = driver.vehicle && driver.vehicle.category === 'moto' ? 'courier' : 'driver';

    // Retourner le profil complet
    res.json({
      success: true,
      data: {
        driver: {
          id: driver._id,
          firstName: driver.firstName,
          lastName: driver.lastName,
          phone: driver.phone,
          email: driver.email,
          dateOfBirth: driver.dateOfBirth,
          gender: driver.gender,
          nationalId: driver.nationalId,
          address: driver.address,
          driverLicense: driver.driverLicense,
          vehicle: driver.vehicle,
          status: driver.status,
          isAvailable: driver.isAvailable,
          isVerified: driver.isVerified,
          currentLocation: driver.currentLocation,
          subscription: driver.subscription,
          rideTypes: driver.rideTypes || {},
          preferences: driver.preferences || {},
          stats: {
            totalRides: driver.stats?.totalRides || 0,
            completedRides: driver.stats?.completedRides || 0,
            cancelledRides: driver.stats?.cancelledRides || 0,
            averageRating: driver.rating || 0,
            totalEarnings: driver.earnings?.total || 0,
            todayRides: driver.stats?.todayRides || 0,
            todayEarnings: driver.earnings?.today || 0,
            weeklyRides: driver.stats?.weeklyRides || 0,
            weeklyEarnings: driver.earnings?.weekly || 0,
          },
          createdAt: driver.createdAt,
          driverType
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du profil chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur',
      error: error.message
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
    
    // Trouver le chauffeur par son ID
    const driver = await Driver.findById(req.user.id);
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

    // Émettre l'événement WebSocket pour synchro temps réel
    const io = req.app.get('io');
    if (io) {
      io.emit('driver:status:updated', {
        driverId: driver._id,
        status: driver.status,
        isAvailable: driver.isAvailable,
        timestamp: new Date()
      });
    }

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
      message: 'Erreur interne du serveur',
      error: error.message
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
      // Gérer le filtre 'in_progress' qui inclut plusieurs statuts
      if (status === 'in_progress') {
        filter.status = { $in: ['accepted', 'arriving', 'arrived', 'started'] };
      } else {
        filter.status = status;
      }
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

// @route   PUT /api/v1/drivers/preferences
// @desc    Mettre à jour les préférences du chauffeur (incluant covoiturage)
// @access  Private (chauffeur)
router.put('/preferences', [
  auth,
  requireDriver,
  body('acceptSharedRides').optional().isBoolean(),
  body('acceptExpressRides').optional().isBoolean(),
  body('maxDistance').optional().isFloat({ min: 1, max: 100 }),
  body('minPrice').optional().isFloat({ min: 0 })
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

    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    const { acceptSharedRides, acceptExpressRides, maxDistance, minPrice } = req.body;

    if (acceptSharedRides !== undefined) {
      driver.preferences.acceptSharedRides = acceptSharedRides;
    }
    if (acceptExpressRides !== undefined) {
      driver.preferences.acceptExpressRides = acceptExpressRides;
    }
    if (maxDistance !== undefined) {
      driver.preferences.maxDistance = maxDistance;
    }
    if (minPrice !== undefined) {
      driver.preferences.minPrice = minPrice;
    }

    await driver.save();

    res.json({
      success: true,
      message: 'Préférences mises à jour avec succès',
      data: {
        preferences: driver.preferences
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour des préférences:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/drivers/ride-types
// @desc    Mettre à jour les types de courses acceptées par le chauffeur
// @access  Private (chauffeur)
router.put('/ride-types', [
  auth,
  requireDriver,
  body('comfort').optional().isBoolean(),
  body('women_only').optional().isBoolean(),
  body('delivery').optional().isBoolean()
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

    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    const isMoto = driver.vehicle?.category === 'moto' || driver.vehicle?.type === 'moto_delivery';

    const nextRideTypes = {
      ...(driver.rideTypes || {}),
      standard: true
    };

    if (req.body.comfort !== undefined) {
      nextRideTypes.comfort = req.body.comfort;
    }
    if (req.body.women_only !== undefined) {
      nextRideTypes.women_only = req.body.women_only;
    }
    if (req.body.delivery !== undefined) {
      nextRideTypes.delivery = isMoto ? req.body.delivery : false;
    }

    if (!isMoto) {
      nextRideTypes.delivery = false;
    }
    nextRideTypes.standard = true;

    driver.rideTypes = nextRideTypes;
    await driver.save();

    res.json({
      success: true,
      message: 'Types de courses mis à jour',
      data: { rideTypes: driver.rideTypes }
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour des rideTypes:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/drivers/carpool/toggle
// @desc    Activer/Désactiver le mode covoiturage
// @access  Private (chauffeur)
router.put('/carpool/toggle', [
  auth,
  requireDriver,
  body('enabled').isBoolean().withMessage('Le statut doit être un booléen')
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

    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    const { enabled } = req.body;
    driver.preferences.acceptSharedRides = enabled;
    await driver.save();

    res.json({
      success: true,
      message: `Mode covoiturage ${enabled ? 'activé' : 'désactivé'}`,
      data: {
        carpoolEnabled: driver.preferences.acceptSharedRides
      }
    });

  } catch (error) {
    console.error('Erreur lors du toggle du mode covoiturage:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/drivers/carpool/compatible-rides
// @desc    Trouver des courses compatibles pour le covoiturage
// @access  Private (chauffeur)
router.get('/carpool/compatible-rides', [
  auth,
  requireDriver,
  requireOnline
], async (req, res) => {
  try {
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    if (!driver.preferences.acceptSharedRides) {
      return res.status(400).json({
        success: false,
        message: 'Le mode covoiturage n\'est pas activé'
      });
    }

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

    // Trouver les courses compatibles (même trajet approximatif)
    const compatibleRides = await Ride.find({
      _id: { $ne: currentRideId },
      status: { $in: ['requested', 'searching'] },
      rideType: { $in: ['standard', 'shared'] },
      'pickup.coordinates.latitude': {
        $gte: currentRide.pickup.coordinates.latitude - 0.05,
        $lte: currentRide.pickup.coordinates.latitude + 0.05
      },
      'pickup.coordinates.longitude': {
        $gte: currentRide.pickup.coordinates.longitude - 0.05,
        $lte: currentRide.pickup.coordinates.longitude + 0.05
      }
    })
    .populate('passenger', 'firstName lastName phone')
    .limit(10);

    res.json({
      success: true,
      count: compatibleRides.length,
      data: {
        rides: compatibleRides.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          pickup: ride.pickup,
          destination: ride.destination,
          distance: ride.distance,
          pricing: ride.pricing,
          passenger: ride.passenger ? {
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          } : null,
          requestedAt: ride.requestedAt
        }))
      }
    });

  } catch (error) {
    console.error('Erreur lors de la recherche de courses compatibles:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/drivers/carpool/accept
// @desc    Accepter une course partagée additionnelle
// @access  Private (chauffeur)
router.post('/carpool/accept', [
  auth,
  requireDriver,
  body('currentRideId').notEmpty().withMessage('ID de la course actuelle requis'),
  body('newRideId').notEmpty().withMessage('ID de la nouvelle course requis')
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

    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    const { currentRideId, newRideId } = req.body;

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
    newRide.rideType = 'shared';
    
    // Réduire le prix pour le passager (30% de réduction)
    newRide.sharedPrice = Math.round(newRide.pricing.totalPrice * 0.7);
    
    // Ajouter le passager à la liste des passagers partagés
    if (!currentRide.sharedWith) {
      currentRide.sharedWith = [];
    }
    currentRide.sharedWith.push(newRide.passenger);
    currentRide.isShared = true;
    currentRide.rideType = 'shared';

    await currentRide.save();
    await newRide.save();

    res.json({
      success: true,
      message: 'Course partagée acceptée',
      data: {
        currentRide: {
          id: currentRide._id,
          isShared: currentRide.isShared,
          sharedWith: currentRide.sharedWith,
          totalPassengers: totalPassengers
        },
        newRide: {
          id: newRide._id,
          sharedPrice: newRide.sharedPrice,
          originalPrice: newRide.pricing.totalPrice
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'acceptation de la course partagée:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/drivers/change-password
// @desc    Modifier le mot de passe d'un chauffeur
// @access  Public
router.put('/change-password', async (req, res) => {
  try {
    const { phone, oldPassword, newPassword } = req.body;

    // Validation
    if (!phone || !oldPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs sont requis'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le nouveau mot de passe doit contenir au moins 6 caractères'
      });
    }

    // Trouver le chauffeur
    const driver = await Driver.findOne({ phone });
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    // Vérifier l'ancien mot de passe
    const isMatch = await driver.comparePassword(oldPassword);
    
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Ancien mot de passe incorrect'
      });
    }

    // Mettre à jour le mot de passe (sera hashé automatiquement par le middleware)
    driver.password = newPassword;
    await driver.save();

    res.json({
      success: true,
      message: 'Mot de passe modifié avec succès'
    });

  } catch (error) {
    console.error('Erreur changement mot de passe:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors du changement de mot de passe'
    });
  }
});

// @route   DELETE /api/v1/drivers/account
// @desc    Désactiver le compte chauffeur
// @access  Private (chauffeur)
router.delete('/account', auth, requireDriver, async (req, res) => {
  try {
    const driver = await Driver.findById(req.driver._id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé'
      });
    }

    const activeRides = await Ride.countDocuments({
      driver: driver._id,
      status: { $in: ['requested', 'searching', 'accepted', 'arriving', 'arrived', 'started'] }
    });

    if (activeRides > 0) {
      return res.status(400).json({
        success: false,
        message: 'Impossible de supprimer le compte avec des courses en cours'
      });
    }

    if (!driver.subscription) {
      driver.subscription = {};
    }

    driver.status = 'offline';
    driver.isAvailable = false;
    driver.subscription.isActive = false;

    if (typeof driver.isVerified === 'boolean') {
      driver.isVerified = false;
    }

    driver.verificationStatus = 'rejected';
    await driver.save();

    res.json({
      success: true,
      message: 'Compte chauffeur désactivé avec succès'
    });

  } catch (error) {
    console.error('Erreur lors de la désactivation du compte chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;
