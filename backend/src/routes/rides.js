const express = require('express');
const { body, validationResult } = require('express-validator');
const Ride = require('../models/Ride');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { auth, requireVerification, requireDriver, requireActiveSubscription, requireOnline, requireAvailable } = require('../middleware/auth');
const router = express.Router();

// @route   POST /api/v1/rides/request
// @desc    Demander une course
// @access  Private (utilisateur vérifié)
router.post('/request', [
  auth,
  requireVerification,
  body('pickup.address').notEmpty().withMessage('L\'adresse de prise en charge est requise'),
  body('pickup.coordinates.latitude').isFloat().withMessage('Latitude invalide'),
  body('pickup.coordinates.longitude').isFloat().withMessage('Longitude invalide'),
  body('destination.address').notEmpty().withMessage('L\'adresse de destination est requise'),
  body('destination.coordinates.latitude').isFloat().withMessage('Latitude invalide'),
  body('destination.coordinates.longitude').isFloat().withMessage('Longitude invalide'),
  body('pricing.totalPrice').isFloat({ min: 0 }).withMessage('Le prix doit être positif'),
  body('rideType').optional().isIn(['standard', 'express', 'shared', 'premium', 'women_only'])
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
      pickup,
      destination,
      pricing,
      rideType = 'standard',
      passengers = 1,
      specialRequests = [],
      specialMode
    } = req.body;

    // Calculer la distance et la durée estimée
    // TODO: Intégrer avec l'API Google Maps pour calculer la distance réelle
    const distance = calculateDistance(
      pickup.coordinates.latitude,
      pickup.coordinates.longitude,
      destination.coordinates.latitude,
      destination.coordinates.longitude
    );

    const estimatedDuration = Math.round(distance * 2); // Estimation basique

    // Créer la course
    const ride = new Ride({
      passenger: req.userId,
      pickup,
      destination,
      distance,
      estimatedDuration,
      pricing: {
        basePrice: pricing.basePrice || 500,
        distancePrice: pricing.distancePrice || Math.round(distance * 200),
        timePrice: pricing.timePrice || Math.round(estimatedDuration * 10),
        surgeMultiplier: pricing.surgeMultiplier || 1.0,
        totalPrice: pricing.totalPrice,
        currency: 'XOF',
        isPriceFixed: true
      },
      rideType,
      passengers,
      specialRequests,
      specialMode,
      status: 'requested'
    });

    await ride.save();

    // Rechercher des chauffeurs disponibles dans un rayon de 2km
    const availableDrivers = await Driver.find({
      status: 'online',
      isAvailable: true,
      'subscription.isActive': true,
      'subscription.endDate': { $gt: new Date() },
      'currentLocation': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [pickup.coordinates.longitude, pickup.coordinates.latitude]
          },
          $maxDistance: 2000 // 2km en mètres
        }
      }
    }).limit(10);

    if (availableDrivers.length === 0) {
      ride.status = 'no_driver';
      await ride.save();
      
      return res.status(404).json({
        success: false,
        message: 'Aucun chauffeur disponible dans la zone',
        data: {
          rideId: ride.rideId,
          status: ride.status
        }
      });
    }

    // TODO: Envoyer des notifications aux chauffeurs via Socket.io
    // TODO: Implémenter un système d'expiration (3 minutes)

    res.status(201).json({
      success: true,
      message: 'Demande de course envoyée',
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          pickup: ride.pickup,
          destination: ride.destination,
          distance: ride.distance,
          estimatedDuration: ride.estimatedDuration,
          pricing: ride.pricing,
          status: ride.status,
          rideType: ride.rideType,
          requestedAt: ride.requestedAt
        },
        availableDrivers: availableDrivers.length
      }
    });

  } catch (error) {
    console.error('Erreur lors de la demande de course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/rides/:id/accept
// @desc    Accepter une course (chauffeur)
// @access  Private (chauffeur en ligne)
router.post('/:id/accept', [
  auth,
  requireDriver,
  requireActiveSubscription,
  requireOnline,
  requireAvailable
], async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    if (ride.status !== 'requested' && ride.status !== 'searching') {
      return res.status(400).json({
        success: false,
        message: 'Cette course ne peut plus être acceptée'
      });
    }

    // Vérifier que le chauffeur est toujours dans la zone
    const driver = await Driver.findById(req.driver._id);
    const distance = driver.calculateDistance(
      ride.pickup.coordinates.latitude,
      ride.pickup.coordinates.longitude
    );

    if (distance > 2) { // 2km
      return res.status(400).json({
        success: false,
        message: 'Vous êtes trop loin du point de prise en charge'
      });
    }

    // Assigner la course au chauffeur
    ride.driver = driver._id;
    ride.status = 'accepted';
    ride.acceptedAt = new Date();
    await ride.save();

    // Mettre le chauffeur en mode occupé
    driver.status = 'busy';
    driver.isAvailable = false;
    await driver.save();

    // TODO: Notifier le passager via Socket.io

    res.json({
      success: true,
      message: 'Course acceptée avec succès',
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          pickup: ride.pickup,
          destination: ride.destination,
          pricing: ride.pricing,
          status: ride.status,
          acceptedAt: ride.acceptedAt
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'acceptation de la course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/rides/:id/arrive
// @desc    Signaler l'arrivée du chauffeur
// @access  Private (chauffeur assigné)
router.post('/:id/arrive', [
  auth,
  requireDriver
], async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    if (ride.driver.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas assigné à cette course'
      });
    }

    if (ride.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: 'Statut de course invalide'
      });
    }

    ride.status = 'arrived';
    ride.arrivedAt = new Date();
    await ride.save();

    // TODO: Notifier le passager via Socket.io

    res.json({
      success: true,
      message: 'Arrivée signalée',
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          status: ride.status,
          arrivedAt: ride.arrivedAt
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la signalisation d\'arrivée:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/rides/:id/start
// @desc    Commencer la course
// @access  Private (chauffeur assigné)
router.post('/:id/start', [
  auth,
  requireDriver
], async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    if (ride.driver.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas assigné à cette course'
      });
    }

    if (ride.status !== 'arrived') {
      return res.status(400).json({
        success: false,
        message: 'Statut de course invalide'
      });
    }

    ride.status = 'started';
    ride.startedAt = new Date();
    await ride.save();

    // TODO: Notifier le passager via Socket.io

    res.json({
      success: true,
      message: 'Course commencée',
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          status: ride.status,
          startedAt: ride.startedAt
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors du démarrage de la course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/rides/:id/complete
// @desc    Terminer la course
// @access  Private (chauffeur assigné)
router.post('/:id/complete', [
  auth,
  requireDriver,
  body('actualDuration').optional().isInt({ min: 0 }),
  body('actualDistance').optional().isFloat({ min: 0 })
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

    const { actualDuration, actualDistance } = req.body;

    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    if (ride.driver.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas assigné à cette course'
      });
    }

    if (ride.status !== 'started') {
      return res.status(400).json({
        success: false,
        message: 'Statut de course invalide'
      });
    }

    ride.status = 'completed';
    ride.completedAt = new Date();
    if (actualDuration) ride.actualDuration = actualDuration;
    if (actualDistance) ride.distance = actualDistance;
    await ride.save();

    // Mettre à jour les statistiques du chauffeur
    const driver = await Driver.findById(req.driver._id);
    driver.stats.totalRides += 1;
    driver.stats.completedRides += 1;
    driver.stats.totalEarnings += ride.pricing.totalPrice;
    driver.stats.totalDistance += ride.distance;
    driver.earnings.today += ride.pricing.totalPrice;
    driver.earnings.thisWeek += ride.pricing.totalPrice;
    driver.earnings.thisMonth += ride.pricing.totalPrice;
    driver.earnings.total += ride.pricing.totalPrice;
    driver.status = 'online';
    driver.isAvailable = true;
    await driver.save();

    // Mettre à jour les statistiques du passager
    const passenger = await User.findById(ride.passenger);
    passenger.totalRides += 1;
    passenger.totalSpent += ride.pricing.totalPrice;
    await passenger.save();

    // TODO: Notifier le passager via Socket.io
    // TODO: Déclencher le processus de paiement

    res.json({
      success: true,
      message: 'Course terminée avec succès',
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          status: ride.status,
          completedAt: ride.completedAt,
          pricing: ride.pricing
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la finalisation de la course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/rides/:id/cancel
// @desc    Annuler une course
// @access  Private (passager ou chauffeur assigné)
router.post('/:id/cancel', [
  auth,
  body('reason').notEmpty().withMessage('La raison de l\'annulation est requise')
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

    const { reason } = req.body;

    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    // Vérifier les permissions
    const isPassenger = ride.passenger.toString() === req.userId.toString();
    const isDriver = ride.driver && ride.driver.toString() === req.userId.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'avez pas l\'autorisation d\'annuler cette course'
      });
    }

    if (!ride.canBeCancelled()) {
      return res.status(400).json({
        success: false,
        message: 'Cette course ne peut plus être annulée'
      });
    }

    // Déterminer qui annule
    const cancelledBy = isPassenger ? 'passenger' : 'driver';
    const cancellationReason = isPassenger ? 'passenger_cancelled' : 'driver_cancelled';

    ride.status = 'cancelled';
    ride.cancelledAt = new Date();
    ride.cancellation = {
      reason: cancellationReason,
      cancelledBy,
      refundAmount: ride.pricing.totalPrice
    };
    await ride.save();

    // Si c'est le chauffeur qui annule, le remettre en ligne
    if (isDriver) {
      const driver = await Driver.findById(req.driver._id);
      driver.status = 'online';
      driver.isAvailable = true;
      await driver.save();
    }

    // TODO: Notifier l'autre partie via Socket.io
    // TODO: Traiter le remboursement si nécessaire

    res.json({
      success: true,
      message: 'Course annulée avec succès',
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          status: ride.status,
          cancelledAt: ride.cancelledAt,
          cancellation: ride.cancellation
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'annulation de la course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/rides/:id
// @desc    Obtenir les détails d'une course
// @access  Private (passager ou chauffeur assigné)
router.get('/:id', auth, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id)
      .populate('passenger', 'firstName lastName phone')
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName phone');

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    // Vérifier les permissions
    const isPassenger = ride.passenger._id.toString() === req.userId.toString();
    const isDriver = ride.driver && ride.driver._id.toString() === req.userId.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    res.json({
      success: true,
      data: {
        ride: {
          id: ride._id,
          rideId: ride.rideId,
          pickup: ride.pickup,
          destination: ride.destination,
          distance: ride.distance,
          estimatedDuration: ride.estimatedDuration,
          actualDuration: ride.actualDuration,
          pricing: ride.pricing,
          status: ride.status,
          rideType: ride.rideType,
          passengers: ride.passengers,
          specialRequests: ride.specialRequests,
          specialMode: ride.specialMode,
          passenger: ride.passenger ? {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          } : null,
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
          acceptedAt: ride.acceptedAt,
          arrivedAt: ride.arrivedAt,
          startedAt: ride.startedAt,
          completedAt: ride.completedAt,
          cancelledAt: ride.cancelledAt,
          rating: ride.rating,
          cancellation: ride.cancellation
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération de la course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// Fonction utilitaire pour calculer la distance
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la Terre en km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

module.exports = router;




