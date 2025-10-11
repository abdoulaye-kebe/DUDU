const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const router = express.Router();

// @route   POST /api/v1/auth/register
// @desc    Inscription d'un nouvel utilisateur
// @access  Public
router.post('/register', [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Le prénom doit contenir entre 2 et 50 caractères'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Le nom doit contenir entre 2 et 50 caractères'),
  body('phone')
    .matches(/^(\+221|221)?[0-9]{9}$/)
    .withMessage('Format de numéro de téléphone invalide (ex: +221771234567)'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('language')
    .optional()
    .isIn(['fr', 'wo'])
    .withMessage('Langue invalide (fr ou wo)'),
  body('referralCode')
    .optional()
    .trim()
    .custom((value) => {
      if (value && value !== '' && !/^DUDU[A-Z0-9]{6}$/.test(value)) {
        throw new Error('Code de parrainage invalide');
      }
      return true;
    })
], async (req, res) => {
  try {
    // Vérification des erreurs de validation
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Données invalides',
        errors: errors.array()
      });
    }

    const { firstName, lastName, phone, password, language = 'fr', referralCode } = req.body;

    // Normaliser le numéro de téléphone
    let normalizedPhone = phone.replace(/\D/g, '');
    if (normalizedPhone.length === 9) {
      normalizedPhone = '+221' + normalizedPhone;
    } else if (normalizedPhone.startsWith('221')) {
      normalizedPhone = '+' + normalizedPhone;
    }

    // Vérifier si l'utilisateur existe déjà
    const existingUser = await User.findOne({ phone: normalizedPhone });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Un compte existe déjà avec ce numéro de téléphone'
      });
    }

    // Vérifier le code de parrainage si fourni
    let referredBy = null;
    if (referralCode) {
      const referrer = await User.findOne({ referralCode });
      if (!referrer) {
        return res.status(400).json({
          success: false,
          message: 'Code de parrainage invalide'
        });
      }
      referredBy = referrer._id;
    }

    // Créer le nouvel utilisateur
    const user = new User({
      firstName,
      lastName,
      phone: normalizedPhone,
      password,
      language,
      referredBy
    });

    // Générer le code de parrainage pour le nouvel utilisateur
    user.generateReferralCode();

    // Générer un code de vérification
    const verificationCode = user.generateVerificationCode();

    // Sauvegarder l'utilisateur
    await user.save();

    // TODO: Envoyer le code de vérification par SMS
    console.log(`Code de vérification pour ${normalizedPhone}: ${verificationCode}`);

    // Incrémenter le compteur de parrainage si applicable
    if (referredBy) {
      await User.findByIdAndUpdate(referredBy, {
        $inc: { referralCount: 1 }
      });
    }

    // Générer un token JWT temporaire (valide jusqu'à vérification)
    const token = jwt.sign(
      { 
        userId: user._id,
        phone: user.phone,
        isVerified: false 
      },
      process.env.JWT_SECRET || 'dudu_secret_key',
      { expiresIn: '24h' }
    );

    res.status(201).json({
      success: true,
      message: 'Inscription réussie. Un code de vérification a été envoyé à votre téléphone.',
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          language: user.language,
          referralCode: user.referralCode,
          isVerified: user.isVerified
        },
        token
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'inscription:', error);
    
    // Gestion des erreurs MongoDB
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0];
      return res.status(400).json({
        success: false,
        message: `Un compte existe déjà avec ce ${field === 'phone' ? 'numéro de téléphone' : 'email'}`
      });
    }

    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/auth/login
// @desc    Connexion d'un utilisateur
// @access  Public
router.post('/login', [
  body('phone')
    .matches(/^(\+221|221)?[0-9]{9}$/)
    .withMessage('Format de numéro de téléphone invalide'),
  body('password')
    .notEmpty()
    .withMessage('Le mot de passe est requis')
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

    const { phone, password } = req.body;

    // Normaliser le numéro de téléphone
    let normalizedPhone = phone.replace(/\D/g, '');
    if (normalizedPhone.length === 9) {
      normalizedPhone = '+221' + normalizedPhone;
    } else if (normalizedPhone.startsWith('221')) {
      normalizedPhone = '+' + normalizedPhone;
    }

    // Trouver l'utilisateur
    const user = await User.findOne({ phone: normalizedPhone }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Numéro de téléphone ou mot de passe incorrect'
      });
    }

    // Vérifier si le compte est actif
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Ce compte a été désactivé'
      });
    }

    // Vérifier le mot de passe
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Numéro de téléphone ou mot de passe incorrect'
      });
    }

    // Générer un token JWT
    const token = jwt.sign(
      { 
        userId: user._id,
        phone: user.phone,
        isVerified: user.isVerified 
      },
      process.env.JWT_SECRET || 'dudu_secret_key',
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Connexion réussie',
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          email: user.email,
          language: user.language,
          currency: user.currency,
          isVerified: user.isVerified,
          referralCode: user.referralCode,
          totalRides: user.totalRides,
          averageRating: user.averageRating,
          createdAt: user.createdAt
        },
        token
      }
    });

  } catch (error) {
    console.error('Erreur lors de la connexion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/auth/verify
// @desc    Vérifier le numéro de téléphone avec un code SMS
// @access  Public
router.post('/verify', [
  body('phone')
    .matches(/^(\+221|221)?[0-9]{9}$/)
    .withMessage('Format de numéro de téléphone invalide'),
  body('code')
    .isLength({ min: 6, max: 6 })
    .isNumeric()
    .withMessage('Le code de vérification doit contenir 6 chiffres')
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

    const { phone, code } = req.body;

    // Normaliser le numéro de téléphone
    let normalizedPhone = phone.replace(/\D/g, '');
    if (normalizedPhone.length === 9) {
      normalizedPhone = '+221' + normalizedPhone;
    } else if (normalizedPhone.startsWith('221')) {
      normalizedPhone = '+' + normalizedPhone;
    }

    // Trouver l'utilisateur
    const user = await User.findOne({ phone: normalizedPhone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Vérifier le code
    if (user.verificationCode !== code) {
      return res.status(400).json({
        success: false,
        message: 'Code de vérification incorrect'
      });
    }

    // Vérifier l'expiration
    if (user.verificationExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Le code de vérification a expiré'
      });
    }

    // Marquer comme vérifié
    user.isVerified = true;
    user.verificationCode = undefined;
    user.verificationExpires = undefined;
    await user.save();

    // Générer un nouveau token JWT avec le statut vérifié
    const token = jwt.sign(
      { 
        userId: user._id,
        phone: user.phone,
        isVerified: true 
      },
      process.env.JWT_SECRET || 'dudu_secret_key',
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Numéro de téléphone vérifié avec succès',
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          email: user.email,
          language: user.language,
          currency: user.currency,
          isVerified: user.isVerified,
          referralCode: user.referralCode,
          totalRides: user.totalRides,
          averageRating: user.averageRating,
          createdAt: user.createdAt
        },
        token
      }
    });

  } catch (error) {
    console.error('Erreur lors de la vérification:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/auth/resend-verification
// @desc    Renvoyer le code de vérification
// @access  Public
router.post('/resend-verification', [
  body('phone')
    .matches(/^(\+221|221)?[0-9]{9}$/)
    .withMessage('Format de numéro de téléphone invalide')
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

    const { phone } = req.body;

    // Normaliser le numéro de téléphone
    let normalizedPhone = phone.replace(/\D/g, '');
    if (normalizedPhone.length === 9) {
      normalizedPhone = '+221' + normalizedPhone;
    } else if (normalizedPhone.startsWith('221')) {
      normalizedPhone = '+' + normalizedPhone;
    }

    // Trouver l'utilisateur
    const user = await User.findOne({ phone: normalizedPhone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Ce numéro est déjà vérifié'
      });
    }

    // Générer un nouveau code
    const verificationCode = user.generateVerificationCode();
    await user.save();

    // TODO: Envoyer le code par SMS
    console.log(`Nouveau code de vérification pour ${normalizedPhone}: ${verificationCode}`);

    res.json({
      success: true,
      message: 'Un nouveau code de vérification a été envoyé'
    });

  } catch (error) {
    console.error('Erreur lors du renvoi du code:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/auth/me
// @desc    Obtenir les informations de l'utilisateur connecté
// @access  Private
router.get('/me', auth, async (req, res) => {
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
          language: user.language,
          currency: user.currency,
          isVerified: user.isVerified,
          referralCode: user.referralCode,
          totalRides: user.totalRides,
          averageRating: user.averageRating,
          createdAt: user.createdAt
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

// @route   GET /api/v1/auth/test-code/:phone
// @desc    Récupérer le code de vérification pour les tests
// @access  Public (uniquement en développement)
router.get('/test-code/:phone', async (req, res) => {
  try {
    // Normaliser le numéro de téléphone
    let normalizedPhone = req.params.phone.replace(/\D/g, '');
    if (normalizedPhone.length === 9) {
      normalizedPhone = '+221' + normalizedPhone;
    } else if (normalizedPhone.startsWith('221')) {
      normalizedPhone = '+' + normalizedPhone;
    }

    // Trouver l'utilisateur
    const user = await User.findOne({ phone: normalizedPhone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    if (user.isVerified) {
      return res.json({
        success: true,
        message: 'Numéro déjà vérifié',
        code: 'DÉJÀ_VÉRIFIÉ'
      });
    }

    // Vérifier si le code existe et n'est pas expiré
    if (user.verificationCode && user.verificationExpires > new Date()) {
      return res.json({
        success: true,
        message: 'Code de vérification récupéré',
        code: user.verificationCode,
        expires: user.verificationExpires
      });
    }

    // Générer un nouveau code
    const code = user.generateVerificationCode();
    await user.save();

    res.json({
      success: true,
      message: 'Nouveau code généré',
      code: code,
      expires: user.verificationExpires
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du code:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/auth/me
// @desc    Récupérer les informations de l'utilisateur connecté
// @access  Private
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/auth/logout
// @desc    Déconnexion de l'utilisateur
// @access  Private
router.post('/logout', auth, async (req, res) => {
  try {
    // Dans une vraie application, vous pourriez ajouter le token à une liste noire
    // Pour l'instant, on retourne simplement un succès
    res.json({
      success: true,
      message: 'Déconnexion réussie'
    });
  } catch (error) {
    console.error('Erreur lors de la déconnexion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;

