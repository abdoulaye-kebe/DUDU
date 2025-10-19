const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware d'authentification
const auth = async (req, res, next) => {
  try {
    // Récupérer le token depuis l'en-tête Authorization
    const authHeader = req.header('Authorization');
    
    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: 'Token d\'accès requis'
      });
    }

    // Vérifier le format "Bearer <token>"
    const token = authHeader.startsWith('Bearer ') 
      ? authHeader.slice(7) 
      : authHeader;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token d\'accès requis'
      });
    }

    // Vérifier le token JWT
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Vérifier que l'utilisateur existe toujours
    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Token invalide - utilisateur non trouvé'
      });
    }

    // Vérifier que le compte est actif
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Compte désactivé'
      });
    }

    // Ajouter l'ID de l'utilisateur à la requête
    req.userId = user._id;
    req.user = user;
    
    next();
  } catch (error) {
    console.error('Erreur d\'authentification:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token invalide'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expiré'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Erreur d\'authentification'
    });
  }
};

// Middleware pour vérifier si l'utilisateur est vérifié
const requireVerification = (req, res, next) => {
  if (!req.user.isVerified) {
    return res.status(403).json({
      success: false,
      message: 'Vérification du numéro de téléphone requise'
    });
  }
  next();
};

// Middleware pour vérifier les rôles (si nécessaire)
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentification requise'
      });
    }

    // Pour l'instant, tous les utilisateurs ont le même rôle
    // On peut étendre cela plus tard avec un système de rôles
    next();
  };
};

// Middleware pour les chauffeurs uniquement
const requireDriver = async (req, res, next) => {
  try {
    const Driver = require('../models/Driver');
    const driver = await Driver.findOne({ user: req.userId });
    
    if (!driver) {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé aux chauffeurs'
      });
    }

    req.driver = driver;
    next();
  } catch (error) {
    console.error('Erreur de vérification chauffeur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur de vérification du statut chauffeur'
    });
  }
};

// Middleware pour vérifier l'abonnement actif du chauffeur
const requireActiveSubscription = async (req, res, next) => {
  try {
    if (!req.driver) {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé aux chauffeurs'
      });
    }

    // Vérifier si l'abonnement est actif
    if (!req.driver.isSubscriptionValid()) {
      return res.status(403).json({
        success: false,
        message: 'Abonnement expiré. Veuillez renouveler votre forfait.',
        data: {
          subscription: req.driver.subscription
        }
      });
    }

    next();
  } catch (error) {
    console.error('Erreur de vérification d\'abonnement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur de vérification de l\'abonnement'
    });
  }
};

// Middleware pour vérifier la localisation (pour les chauffeurs)
const requireLocation = (req, res, next) => {
  if (!req.driver || !req.driver.currentLocation) {
    return res.status(400).json({
      success: false,
      message: 'Localisation requise pour cette action'
    });
  }
  next();
};

// Middleware pour vérifier le statut en ligne (pour les chauffeurs)
const requireOnline = (req, res, next) => {
  if (!req.driver || req.driver.status !== 'online') {
    return res.status(403).json({
      success: false,
      message: 'Vous devez être en ligne pour effectuer cette action'
    });
  }
  next();
};

// Middleware pour vérifier la disponibilité (pour les chauffeurs)
const requireAvailable = (req, res, next) => {
  if (!req.driver || !req.driver.isAvailable) {
    return res.status(403).json({
      success: false,
      message: 'Vous n\'êtes pas disponible pour accepter des courses'
    });
  }
  next();
};

module.exports = {
  auth,
  requireVerification,
  requireRole,
  requireDriver,
  requireActiveSubscription,
  requireLocation,
  requireOnline,
  requireAvailable
};




