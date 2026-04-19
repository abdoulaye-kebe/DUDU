const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Ride = require('../models/Ride');
const { auth, requireDriver, requireActiveSubscription, requireLocation, requireOnline, requireAvailable } = require('../middleware/auth');
const router = express.Router();

const DRIVER_APPLY_UPLOAD_SUBDIR = 'uploads/driver-apply';
const DRIVER_APPLY_DIR = path.join(process.cwd(), 'public', DRIVER_APPLY_UPLOAD_SUBDIR);

function ensureDriverApplyUploadDir() {
  try {
    fs.mkdirSync(DRIVER_APPLY_DIR, { recursive: true });
  } catch (e) {
    console.error('ensureDriverApplyUploadDir:', e);
  }
}

const driverApplyStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    ensureDriverApplyUploadDir();
    cb(null, DRIVER_APPLY_DIR);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    cb(null, `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`);
  },
});

const uploadDriverApply = multer({
  storage: driverApplyStorage,
  limits: { fileSize: 12 * 1024 * 1024 },
});

const uploadDriverApplyFields = uploadDriverApply.fields([
  { name: 'nationalIdFront', maxCount: 1 },
  { name: 'nationalIdBack', maxCount: 1 },
  { name: 'licenseFront', maxCount: 1 },
  { name: 'licenseBack', maxCount: 1 },
  { name: 'greyCardFront', maxCount: 1 },
  { name: 'greyCardBack', maxCount: 1 },
  { name: 'insuranceFile', maxCount: 1 },
  { name: 'technicalInspectionFile', maxCount: 1 },
  { name: 'vehiclePhoto', maxCount: 1 },
]);

function relUploadUrl(files, field) {
  const arr = files && files[field];
  if (!arr || !arr[0]) return null;
  return `/${DRIVER_APPLY_UPLOAD_SUBDIR}/${arr[0].filename}`;
}

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
        isVerified: driver.isVerified,
        verificationStatus: driver.verificationStatus,
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
// @desc    Soumettre une candidature chauffeur (multipart : scans CNI / permis / carte grise recto-verso, assurance PDF ou Word)
// @access  Public
// @body    Champ texte "data" = JSON (firstName, lastName, phone, password, …) + fichiers nationalIdFront, nationalIdBack, licenseFront, licenseBack, greyCardFront, greyCardBack, insuranceFile [, technicalInspectionFile, vehiclePhoto]
router.post('/apply', uploadDriverApplyFields, async (req, res) => {
  try {
    let body;
    try {
      const raw = req.body.data;
      if (!raw || typeof raw !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Envoi multipart requis : champ "data" (JSON) + fichiers scans.',
        });
      }
      body = JSON.parse(raw);
    } catch (e) {
      return res.status(400).json({
        success: false,
        message: 'Le champ "data" doit être un JSON valide.',
      });
    }

    const files = req.files || {};
    const requiredScanFields = [
      'nationalIdFront',
      'nationalIdBack',
      'licenseFront',
      'licenseBack',
      'greyCardFront',
      'greyCardBack',
      'insuranceFile',
    ];
    const missing = requiredScanFields.filter((f) => !relUploadUrl(files, f));
    if (missing.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Fichiers manquants : ${missing.join(', ')}`,
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
      address = {},
      driverLicense,
      vehicle,
      rideTypes = {},
      preferences = {},
      documents = {},
    } = body;

    if (!firstName || String(firstName).trim().length < 2
      || !lastName || String(lastName).trim().length < 2
      || !phone || String(phone).trim().length < 9
      || !password || String(password).length < 6
      || !dateOfBirth || !gender
      || !driverLicense?.expiryDate
      || !vehicle?.make || !vehicle?.model || !vehicle?.plateNumber || !vehicle?.color) {
      return res.status(400).json({
        success: false,
        message: 'Informations personnelles ou véhicule incomplètes.',
      });
    }

    const yearNum = parseInt(vehicle.year, 10);
    const yMax = new Date().getFullYear() + 1;
    if (!Number.isFinite(yearNum) || yearNum < 1990 || yearNum > yMax) {
      return res.status(400).json({
        success: false,
        message: 'Année du véhicule invalide.',
      });
    }

    const scanToken = () => crypto.randomBytes(8).toString('hex');
    const nationalId = `SCAN-CNI-${scanToken()}`;
    const licenseNumber = `SCAN-PERMIS-${scanToken()}`;

    const normalizedVehicleCategory = vehicle?.category || 'car';
    let normalizedVehicleType = vehicle?.type;
    if (normalizedVehicleCategory === 'moto') {
      if (!normalizedVehicleType || normalizedVehicleType === 'motorbike') {
        normalizedVehicleType = 'moto_delivery';
      }
    } else if (!normalizedVehicleType) {
      normalizedVehicleType = 'sedan';
    }

    const normalizedPhone = normalizePhoneNumber(phone);
    const normalizedEmail = typeof email === 'string' && email.trim().length > 0
      ? email.trim().toLowerCase()
      : undefined;

    const duplicate = await Driver.findOne({
      $or: [
        { phone: normalizedPhone },
        normalizedEmail ? { email: normalizedEmail } : null,
      ].filter(Boolean),
    });

    if (duplicate) {
      return res.status(400).json({
        success: false,
        message: 'Un compte chauffeur existe déjà avec ce téléphone ou cet email.',
      });
    }

    const insuranceUrl = relUploadUrl(files, 'insuranceFile');
    const techUrl = relUploadUrl(files, 'technicalInspectionFile');
    const vehiclePhotoUrl = relUploadUrl(files, 'vehiclePhoto');

    const insuranceExpiry = documents.insuranceExpiryDate
      ? new Date(documents.insuranceExpiryDate)
      : new Date(Date.now() + 365 * 864e5);
    const techExpiry = documents.technicalInspectionExpiryDate
      ? new Date(documents.technicalInspectionExpiryDate)
      : new Date(Date.now() + 730 * 864e5);

    const driverData = {
      firstName: String(firstName).trim(),
      lastName: String(lastName).trim(),
      phone: normalizedPhone,
      password,
      dateOfBirth: new Date(dateOfBirth),
      gender,
      nationalId,
      address: {
        street: address.street,
        city: address.city || 'Dakar',
        region: address.region || 'Dakar',
        country: address.country || 'Sénégal',
        postalCode: address.postalCode,
      },
      driverLicense: {
        number: licenseNumber,
        expiryDate: new Date(driverLicense.expiryDate),
        issueDate: driverLicense.issueDate ? new Date(driverLicense.issueDate) : undefined,
        category: driverLicense.category || (normalizedVehicleCategory === 'moto' ? 'A' : 'B'),
      },
      vehicle: {
        make: vehicle.make,
        model: vehicle.model,
        year: yearNum,
        color: vehicle.color,
        plateNumber: String(vehicle.plateNumber).toUpperCase(),
        category: normalizedVehicleCategory,
        type: normalizedVehicleType,
        capacity: vehicle.capacity || (normalizedVehicleCategory === 'moto' ? 1 : 4),
        hasAirConditioning: vehicle.hasAirConditioning || false,
        features: vehicle.features || [],
        photos: vehiclePhotoUrl ? [vehiclePhotoUrl] : (vehicle.photos && Array.isArray(vehicle.photos) ? vehicle.photos : []),
      },
      documents: {
        nationalIdScanFront: relUploadUrl(files, 'nationalIdFront'),
        nationalIdScanBack: relUploadUrl(files, 'nationalIdBack'),
        driverLicensePhoto: relUploadUrl(files, 'licenseFront'),
        driverLicenseScanVerso: relUploadUrl(files, 'licenseBack'),
        vehicleRegistration: relUploadUrl(files, 'greyCardFront'),
        vehicleRegistrationVerso: relUploadUrl(files, 'greyCardBack'),
        insurance: insuranceUrl,
        insuranceDocument: insuranceUrl,
        insuranceExpiryDate: insuranceExpiry,
        technicalInspection: techUrl || 'SCAN_CT_OPTIONNEL',
        technicalInspectionExpiryDate: techExpiry,
        criminalRecord: documents.criminalRecord,
      },
      rideTypes: {
        standard: true,
        comfort: rideTypes.comfort ?? rideTypes.express ?? false,
        luxe: rideTypes.luxe ?? false,
        delivery: normalizedVehicleCategory === 'moto',
        moto: normalizedVehicleCategory === 'moto',
        women_only: rideTypes.women_only ?? rideTypes.womenOnly ?? false,
      },
      preferences: {
        maxDistance: preferences.maxDistance ?? (normalizedVehicleCategory === 'moto' ? 20 : 10),
        minPrice: preferences.minPrice ?? (normalizedVehicleCategory === 'moto' ? 500 : 1000),
        acceptExpressRides: preferences.acceptExpressRides ?? true,
        acceptLuggage: preferences.acceptLuggage ?? false,
      },
      status: 'pending',
      isAvailable: false,
      isVerified: false,
      verificationStatus: 'pending',
    };

    if (normalizedEmail) {
      driverData.email = normalizedEmail;
    }

    const driver = new Driver(driverData);
    await driver.save();

    const token = jwt.sign(
      {
        id: driver._id,
        phone: driver.phone,
        role: 'driver',
        isVerified: driver.isVerified,
      },
      process.env.JWT_SECRET || 'dudu-secret-key-2024',
      { expiresIn: '30d' },
    );

    res.status(201).json({
      success: true,
      message: 'Inscription réussie ! Votre compte sera vérifié prochainement.',
      token,
      driver: {
        id: driver._id,
        firstName: driver.firstName,
        lastName: driver.lastName,
        phone: driver.phone,
        email: driver.email,
        isVerified: driver.isVerified,
        verificationStatus: driver.verificationStatus,
      },
    });
  } catch (error) {
    console.error('Erreur lors de la candidature chauffeur:', error);

    if (error && (error.code === 11000 || error.name === 'MongoServerError')) {
      const keyValue = error.keyValue || error.errorResponse?.keyValue;
      if (keyValue && Object.prototype.hasOwnProperty.call(keyValue, 'email') && keyValue.email == null) {
        return res.status(400).json({
          success: false,
          message: 'Impossible de créer un compte sans email (index email unique mal configuré en base). Contactez l\'administrateur pour corriger l\'index.',
        });
      }

      return res.status(400).json({
        success: false,
        message: 'Un compte existe déjà avec ces informations.',
      });
    }

    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur',
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

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const rollingWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const [todayRidesCount, weeklyRidesCount] = await Promise.all([
      Ride.countDocuments({
        driver: driver._id,
        status: 'completed',
        completedAt: { $gte: startOfToday },
      }),
      Ride.countDocuments({
        driver: driver._id,
        status: 'completed',
        completedAt: { $gte: rollingWeekAgo },
      }),
    ]);

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
            todayRides: todayRidesCount,
            todayEarnings: driver.earnings?.today || 0,
            weeklyRides: weeklyRidesCount,
            weeklyEarnings: driver.earnings?.thisWeek || 0,
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
      case 'year':
        startDate = new Date(now.getFullYear(), 0, 1);
        endDate = now;
        break;
      default:
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        endDate = new Date(startDate.getTime() + 24 * 60 * 60 * 1000);
    }

    // Calculer les revenus, distance et durée pour la période
    const earnings = await Ride.aggregate([
      {
        $match: {
          driver: driver._id,
          status: 'completed',
          completedAt: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: null,
          totalEarnings: { $sum: '$pricing.totalPrice' },
          totalRides: { $sum: 1 },
          averageEarnings: { $avg: '$pricing.totalPrice' },
          totalDistanceKm: { $sum: '$distance' },
          totalDurationMinutes: {
            $sum: {
              $ifNull: ['$actualDuration', '$estimatedDuration']
            }
          }
        }
      }
    ]);

    const result = earnings.length > 0 ? earnings[0] : {
      totalEarnings: 0,
      totalRides: 0,
      averageEarnings: 0,
      totalDistanceKm: 0,
      totalDurationMinutes: 0
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
          average: Math.round(result.averageEarnings || 0),
          totalDistanceKm: Math.round((result.totalDistanceKm || 0) * 10) / 10,
          totalDurationMinutes: Math.round(result.totalDurationMinutes || 0),
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
    const rawRadius = parseFloat(req.query.radius, 10);
    const radiusKm = Number.isFinite(rawRadius) ? Math.min(Math.max(rawRadius, 1), 100) : 15;
    const limit = parseInt(req.query.limit, 10) || 10;

    const driver = await Driver.findById(req.driver._id);
    if (!driver || !driver.currentLocation) {
      return res.status(400).json({
        success: false,
        message: 'Localisation requise'
      });
    }

    const coords = driver.currentLocation.coordinates;
    if (!Array.isArray(coords) || coords.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Localisation chauffeur invalide'
      });
    }
    const [driverLng, driverLat] = coords;

    // Trouver les courses à proximité (index 2dsphere sur pickup.location)
    const nearbyRides = await Ride.find({
      status: { $in: ['requested', 'searching'] },
      'pickup.location': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [driverLng, driverLat]
          },
          $maxDistance: radiusKm * 1000
        }
      }
    })
    .populate('passenger', 'firstName lastName phone')
    .limit(limit)
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
// @desc    Mettre à jour les préférences du chauffeur
// @access  Private (chauffeur)
router.put('/preferences', [
  auth,
  requireDriver,
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

    const { acceptExpressRides, maxDistance, minPrice } = req.body;

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
  body('luxe').optional().isBoolean(),
  body('women_only').optional().isBoolean(),
  body('delivery').optional().isBoolean(),
  body('moto').optional().isBoolean()
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
    const isCar = !isMoto;

    const nextRideTypes = {
      ...(driver.rideTypes || {}),
      standard: true
    };

    if (req.body.comfort !== undefined) {
      nextRideTypes.comfort = req.body.comfort;
    }
    if (req.body.luxe !== undefined) {
      nextRideTypes.luxe = isCar ? req.body.luxe : false;
    }
    if (req.body.women_only !== undefined) {
      nextRideTypes.women_only = req.body.women_only;
    }
    if (req.body.delivery !== undefined) {
      nextRideTypes.delivery = isMoto ? req.body.delivery : false;
    }
    if (req.body.moto !== undefined) {
      nextRideTypes.moto = isMoto ? req.body.moto : false;
    }

    if (!isMoto) {
      nextRideTypes.delivery = false;
      nextRideTypes.moto = false;
    }
    if (!isCar) {
      nextRideTypes.luxe = false;
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
