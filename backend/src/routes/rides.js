const express = require('express');
const mongoose = require('mongoose');
const { body, validationResult } = require('express-validator');
const Ride = require('../models/Ride');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { getIO } = require('../socket/socketIO');
const { getDistanceAndDuration } = require('../services/googleMapsService');
const { auth, requireVerification, requireDriver, requireActiveSubscription, requireOnline, requireAvailable } = require('../middleware/auth');
const {
  driverShouldReceiveDeliveryNotification,
  driverCanAcceptNewDelivery,
} = require('../utils/deliveryDriverRules');
const { notifyDriversNewRideRequest } = require('../services/notifyDriversNewRideRequest');
const {
  getDriverMatchInitialRadiusKm,
  getDriverMatchExpandedRadiusKm,
} = require('../config/driverMatch.config');
const { buildNewRideRequestPayload } = require('../utils/buildNewRideRequestPayload');
const {
  buildDriverPayloadForPassenger,
  estimateArrivalMinutesToPickup,
} = require('../utils/passengerDriverNotify');
const { buildDriverQueryForRideType } = require('../utils/driverRideTypeMatch');
const { sendScheduledRideAcceptedPush } = require('../utils/scheduledRidePassengerNotify');
const router = express.Router();

const ACTIVE_RIDE_STATUSES = ['accepted', 'arriving', 'arrived', 'started'];

/** Suppléments autorisés pour contre-proposition chauffeur (FCFA, vs prix client). */
const COUNTER_OFFER_AMOUNTS = [300, 500, 750, 1000, 1500, 2000];

// Fonction pour calculer la distance entre deux points (formule de Haversine)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la Terre en km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // Distance en km
}

// @route   POST /api/v1/rides/request
// @desc    Demander une course
// @access  Private (utilisateur)
router.post('/request', [
  auth,
  body('pickup.address').notEmpty().withMessage('L\'adresse de prise en charge est requise'),
  body('pickup.coordinates.latitude').isFloat().withMessage('Latitude invalide'),
  body('pickup.coordinates.longitude').isFloat().withMessage('Longitude invalide'),
  body('destination.address').notEmpty().withMessage('L\'adresse de destination est requise'),
  body('destination.coordinates.latitude').isFloat().withMessage('Latitude invalide'),
  body('destination.coordinates.longitude').isFloat().withMessage('Longitude invalide'),
  body('pricing.totalPrice').isFloat({ min: 0 }).withMessage('Le prix doit être positif'),
  body('rideType').optional().isIn(['standard', 'comfort', 'women_only', 'delivery', 'luxe'])
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

    // Calculer la distance et la durée (Google Maps si clé API, sinon Haversine)
    let distance;
    let estimatedDuration;
    const mapsResult = await getDistanceAndDuration(
      pickup.coordinates.latitude,
      pickup.coordinates.longitude,
      destination.coordinates.latitude,
      destination.coordinates.longitude
    );
    if (mapsResult) {
      distance = mapsResult.distanceKm;
      estimatedDuration = mapsResult.durationMinutes;
    } else {
      distance = calculateDistance(
        pickup.coordinates.latitude,
        pickup.coordinates.longitude,
        destination.coordinates.latitude,
        destination.coordinates.longitude
      );
      estimatedDuration = Math.round(distance * 2);
    }

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

    // Chauffeurs disponibles, type de course compatible avec le véhicule / options
    const driverQuery = {
      status: 'online',
      isAvailable: true,
      verificationStatus: 'approved',
      ...buildDriverQueryForRideType(rideType),
    };

    let allDrivers = await Driver.find(driverQuery);
    
    const INITIAL_RADIUS_KM = getDriverMatchInitialRadiusKm();
    const EXPANDED_RADIUS_KM = getDriverMatchExpandedRadiusKm();
    let availableDrivers = allDrivers.filter(driver => {
      if (!driver.currentLocation || !driver.currentLocation.coordinates) {
        return false;
      }
      const driverLat = driver.currentLocation.coordinates[1];
      const driverLon = driver.currentLocation.coordinates[0];
      const distance = calculateDistance(
        pickup.coordinates.latitude,
        pickup.coordinates.longitude,
        driverLat,
        driverLon
      );
      return distance <= INITIAL_RADIUS_KM;
    });

    console.log(`🔍 Recherche chauffeurs dans rayon de ${INITIAL_RADIUS_KM}km: ${availableDrivers.length} trouvés`);
    
    // Stocker le rayon initial dans la course pour l'élargissement ultérieur
    ride.searchRadius = INITIAL_RADIUS_KM;
    await ride.save();
    
    // Si aucun chauffeur en ligne, chercher tous les chauffeurs approuvés
    if (availableDrivers.length === 0) {
      const fallbackQuery = {
        verificationStatus: 'approved',
        ...buildDriverQueryForRideType(rideType),
      };

      availableDrivers = await Driver.find(fallbackQuery).limit(10);
      console.log(`🔍 Fallback: ${availableDrivers.length} chauffeurs approuvés trouvés`);
    }

    // Envoyer la demande via Socket.io aux chauffeurs dans le rayon
    const io = req.app.get('io');
    if (io && availableDrivers.length > 0) {
      const rideData = buildNewRideRequestPayload(ride, req.user);

      // Émettre individuellement à chaque chauffeur dans le rayon
      for (const driver of availableDrivers) {
        const d = driver.calculateDistance
          ? driver.calculateDistance(
            pickup.coordinates.latitude,
            pickup.coordinates.longitude
          )
          : 0;
        io.to(`driver_${driver._id}`).emit('new-ride-request', {
          ...rideData,
          driverDistance: d,
        });
      }
      console.log(`📡 Demande de course envoyée à ${availableDrivers.length} chauffeurs dans rayon de ${INITIAL_RADIUS_KM}km`);
      
      // Programmer l'élargissement du rayon après 5 minutes si pas d'acceptation
      setTimeout(async () => {
        try {
          const updatedRide = await Ride.findById(ride._id);
          if (!updatedRide || updatedRide.status !== 'requested') {
            console.log(`⏭️ Course ${ride._id} déjà acceptée ou annulée, pas d'élargissement`);
            return;
          }

          console.log(`🔄 Élargissement du rayon à ${EXPANDED_RADIUS_KM}km pour course ${ride._id}`);

          const expandedDrivers = allDrivers.filter(driver => {
            if (!driver.currentLocation || !driver.currentLocation.coordinates) {
              return false;
            }
            const driverLat = driver.currentLocation.coordinates[1];
            const driverLon = driver.currentLocation.coordinates[0];
            const distance = calculateDistance(
              pickup.coordinates.latitude,
              pickup.coordinates.longitude,
              driverLat,
              driverLon
            );
            return distance <= EXPANDED_RADIUS_KM && distance > INITIAL_RADIUS_KM;
          });

          console.log(`📡 Envoi à ${expandedDrivers.length} chauffeurs supplémentaires dans rayon ${INITIAL_RADIUS_KM}-${EXPANDED_RADIUS_KM}km`);

          for (const driver of expandedDrivers) {
            const d = driver.calculateDistance
              ? driver.calculateDistance(
                pickup.coordinates.latitude,
                pickup.coordinates.longitude
              )
              : 0;
            io.to(`driver_${driver._id}`).emit('new-ride-request', {
              ...rideData,
              driverDistance: d,
            });
          }
          
          // Mettre à jour le rayon de recherche
          updatedRide.searchRadius = EXPANDED_RADIUS_KM;
          await updatedRide.save();
        } catch (error) {
          console.error('Erreur lors de l\'élargissement du rayon:', error);
        }
      }, 5 * 60 * 1000); // 5 minutes
    }

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

    // Expiration de la demande après 3 minutes si aucun chauffeur n'accepte
    const EXPIRATION_MS = 3 * 60 * 1000;
    setTimeout(async () => {
      try {
        const updatedRide = await Ride.findById(ride._id);
        if (!updatedRide || updatedRide.status !== 'requested') return;
        updatedRide.status = 'expired';
        await updatedRide.save();
        const io = getIO();
        if (io) {
          io.emit('ride-expired', { rideId: ride._id });
        }
        console.log(`⏱️ Course ${ride._id} expirée (3 min sans acceptation)`);
      } catch (err) {
        console.error('Erreur expiration course:', err.message);
      }
    }, EXPIRATION_MS);

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

// @route   POST /api/v1/rides/:id/counter-offer
// @desc    Contre-proposition tarifaire (chauffeur, avant acceptation)
// @access  Private (chauffeur)
router.post('/:id/counter-offer', [
  auth,
  requireDriver,
  requireActiveSubscription,
  requireOnline,
  requireAvailable,
  body('additionalAmount').custom((value) => {
    const n = Number(value);
    return Number.isFinite(n) && COUNTER_OFFER_AMOUNTS.includes(Math.round(n));
  }).withMessage('Supplément invalide (300 à 2000 FCFA, valeurs fixes).'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0]?.msg || 'Données invalides',
      });
    }

    const additionalAmount = Math.round(Number(req.body.additionalAmount));
    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({ success: false, message: 'Course non trouvée' });
    }

    if (ride.status !== 'requested' && ride.status !== 'searching') {
      return res.status(400).json({
        success: false,
        message: 'Cette course ne peut plus recevoir de proposition',
      });
    }

    if (ride.driver) {
      return res.status(400).json({
        success: false,
        message: 'La course est déjà assignée',
      });
    }

    if (ride.counterOffer && ride.counterOffer.status === 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Une proposition est déjà en attente de réponse du client',
      });
    }

    const driver = await Driver.findById(req.driver._id);
    const distance = driver.calculateDistance(
      ride.pickup.coordinates.latitude,
      ride.pickup.coordinates.longitude
    );
    if (distance > 2) {
      return res.status(400).json({
        success: false,
        message: 'Vous êtes trop loin du point de prise en charge',
      });
    }

    const baseTotal = ride.pricing.totalPrice;
    const proposedTotalPrice = baseTotal + additionalAmount;

    ride.counterOffer = {
      driver: driver._id,
      additionalAmount,
      proposedTotalPrice,
      baseTotalPrice: baseTotal,
      status: 'pending',
      createdAt: new Date(),
    };
    await ride.save();

    const io = req.app.get('io');
    if (io) {
      io.to(`passenger_${ride.passenger}`).emit('ride-counter-offer', {
        rideId: ride._id,
        additionalAmount,
        proposedTotalPrice,
        baseTotalPrice: baseTotal,
        driver: {
          id: driver._id,
          firstName: driver.firstName,
          lastName: driver.lastName,
        },
      });
    }

    return res.json({
      success: true,
      message: 'Proposition envoyée au client',
      data: {
        counterOffer: ride.counterOffer,
        pricing: ride.pricing,
      },
    });
  } catch (error) {
    console.error('counter-offer:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur',
    });
  }
});

// @route   POST /api/v1/rides/:id/counter-offer/respond
// @desc    Réponse passager à la contre-proposition
// @access  Private (passager)
router.post('/:id/counter-offer/respond', [auth], async (req, res) => {
  try {
    if (req.userId && req.userId.toString() === 'admin') {
      return res.status(403).json({ success: false, message: 'Action non autorisée' });
    }

    const accept =
      req.body.accept === true ||
      req.body.accept === 'true' ||
      req.body.accept === 1 ||
      req.body.accept === '1';

    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({ success: false, message: 'Course non trouvée' });
    }

    if (ride.passenger.toString() !== req.userId.toString()) {
      return res.status(403).json({ success: false, message: 'Accès non autorisé' });
    }

    if (!ride.counterOffer || ride.counterOffer.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Aucune proposition en attente',
      });
    }

    const driverId = ride.counterOffer.driver.toString();
    const io = req.app.get('io');

    if (accept) {
      ride.pricing.totalPrice = ride.counterOffer.proposedTotalPrice;
      if (ride.pricing.customPrice != null) {
        ride.pricing.customPrice = ride.counterOffer.proposedTotalPrice;
      }
      ride.counterOffer.status = 'accepted';
      await ride.save();

      if (io) {
        io.to(`driver_${driverId}`).emit('ride-counter-offer-passenger-responded', {
          rideId: ride._id,
          accepted: true,
          pricing: ride.pricing,
          counterOffer: ride.counterOffer,
        });
      }
    } else {
      ride.set('counterOffer', undefined);
      await ride.save();

      if (io) {
        io.to(`driver_${driverId}`).emit('ride-counter-offer-passenger-responded', {
          rideId: ride._id,
          accepted: false,
        });
      }
    }

    return res.json({
      success: true,
      message: accept ? 'Nouveau prix accepté' : 'Proposition refusée',
      data: { ride: { id: ride._id, pricing: ride.pricing, counterOffer: ride.counterOffer } },
    });
  } catch (error) {
    console.error('counter-offer respond:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur',
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

    if (ride.counterOffer && ride.counterOffer.status === 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Le client doit d\'abord répondre à la proposition de prix.',
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

    let activeDeliveryCount = 0;
    if (ride.rideType === 'delivery') {
      const acceptCheck = await driverCanAcceptNewDelivery(driver._id, ride);
      if (!acceptCheck.ok) {
        return res.status(403).json({
          success: false,
          message: acceptCheck.message,
          code: acceptCheck.code,
        });
      }
      activeDeliveryCount = await Ride.countDocuments({
        driver: driver._id,
        rideType: 'delivery',
        status: { $in: ACTIVE_RIDE_STATUSES },
      });
    }

    // Assigner la course au chauffeur
    ride.driver = driver._id;
    ride.status = 'accepted';
    ride.acceptedAt = new Date();
    await ride.save();

    // Mettre à jour la disponibilité chauffeur
    if (ride.rideType === 'delivery') {
      // Le livreur peut encore accepter une 2ème livraison
      const nextActiveCount = activeDeliveryCount + 1;
      driver.status = 'online';
      driver.isAvailable = nextActiveCount < 2;
    } else {
      // Règle existante: 1 course à la fois
      driver.status = 'busy';
      driver.isAvailable = false;
    }
    await driver.save();

    // ============================================================
    // NOTIFIER TOUS LES AUTRES CHAUFFEURS QUE LA COURSE EST PRISE
    // ============================================================
    const io = req.app.get('io');
    if (io) {
      // Notifier le passager que sa course a été acceptée
      const driverPayload = buildDriverPayloadForPassenger(driver);
      if (driverPayload) {
        driverPayload.totalRides = driver.stats?.completedRides || 0;
      }
      const estimatedArrival = estimateArrivalMinutesToPickup(
        driver,
        ride.pickup.coordinates.latitude,
        ride.pickup.coordinates.longitude
      );

      io.to(`passenger_${ride.passenger}`).emit('ride-accepted', {
        rideId: ride._id,
        driver: driverPayload,
        estimatedArrival,
        estimatedArrivalMinutes: estimatedArrival,
        pickup: ride.pickup,
        destination: ride.destination,
        pricing: ride.pricing,
        rideType: ride.rideType,
        isScheduled: !!ride.scheduledFor,
        scheduledFor: ride.scheduledFor || null,
      });

      if (ride.scheduledFor) {
        void sendScheduledRideAcceptedPush(ride, driver);
      }

      // Notifier TOUS les chauffeurs que cette course n'est plus disponible
      // Cela permet de retirer la course de leur liste
      io.emit('ride-taken', {
        rideId: ride._id,
        message: 'Cette course a été acceptée par un autre chauffeur'
      });

      console.log(`📢 Course ${ride._id} acceptée par ${driver.phone} - Notification envoyée à tous`);
    }

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

    // Notifier le passager via Socket.io
    const io = req.app.get('io');
    if (io) {
      const driverName =
        req.driver?.firstName && req.driver?.lastName
          ? `${req.driver.firstName} ${req.driver.lastName}`.trim()
          : req.driver?.firstName || req.driver?.lastName || undefined;
      io.to(`passenger_${ride.passenger}`).emit('driver-arrived', {
        rideId: ride._id,
        arrivedAt: ride.arrivedAt,
        message: 'Votre chauffeur est arrivé au point de départ',
        ...(driverName ? { driverName } : {}),
      });
      console.log(`📢 Notification arrivée envoyée au client ${ride.passenger}`);
    }

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

    // Notifier le passager via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`passenger_${ride.passenger}`).emit('ride-started', {
        rideId: ride._id,
        startedAt: ride.startedAt,
        message: 'Votre course a démarré'
      });
      console.log(`📢 Notification démarrage envoyée au client ${ride.passenger}`);
    }

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

    // Permettre de terminer une course qui est en cours (started, in_progress, accepted, arriving, arrived)
    const validStatuses = ['started', 'in_progress', 'accepted', 'arriving', 'arrived'];
    if (!validStatuses.includes(ride.status)) {
      return res.status(400).json({
        success: false,
        message: `Statut de course invalide: ${ride.status}. La course doit être en cours pour être terminée.`
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

    if (ride.rideType === 'delivery') {
      const remainingActive = await Ride.countDocuments({
        driver: driver._id,
        rideType: 'delivery',
        status: { $in: ACTIVE_RIDE_STATUSES }
      });
      driver.status = 'online';
      driver.isAvailable = remainingActive < 2;
    } else {
      driver.status = 'online';
      driver.isAvailable = true;
    }
    await driver.save();

    // Mettre à jour les statistiques du passager
    const passenger = await User.findById(ride.passenger);
    if (passenger) {
      passenger.totalRides += 1;
      passenger.totalSpent += (ride.pricing && ride.pricing.totalPrice) ? ride.pricing.totalPrice : 0;
      await passenger.save();
    } else {
      console.warn('⚠️ Finalisation course: passager introuvable', ride.passenger);
    }

    // Notifier le passager via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`passenger_${ride.passenger}`).emit('ride-completed', {
        rideId: ride._id,
        completedAt: ride.completedAt,
        pricing: ride.pricing,
        distance: ride.distance,
        actualDuration: ride.actualDuration,
        message: 'Votre course est terminée'
      });
      console.log(`📢 Notification fin de course envoyée au client ${ride.passenger}`);
    }

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

      if (ride.rideType === 'delivery') {
        const remainingActive = await Ride.countDocuments({
          driver: driver._id,
          rideType: 'delivery',
          status: { $in: ACTIVE_RIDE_STATUSES }
        });
        driver.status = 'online';
        driver.isAvailable = remainingActive < 2;
      } else {
        driver.status = 'online';
        driver.isAvailable = true;
      }
      await driver.save();
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('ride-no-longer-available', { rideId: ride._id });
      io.emit('ride-cancelled', {
        rideId: ride._id,
        cancelledBy,
        reason,
      });
    }

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

// @route   POST /api/v1/rides/:id/rate
// @desc    Noter une course terminée
// @access  Private (passager uniquement)
router.post('/:id/rate', [
  auth,
  body('rating').isInt({ min: 1, max: 5 }).withMessage('La note doit être entre 1 et 5')
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

    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    // Vérifier que c'est le passager qui note
    if (ride.passenger.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Seul le passager peut noter cette course'
      });
    }

    // Vérifier que la course est terminée
    if (ride.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Seules les courses terminées peuvent être notées'
      });
    }

    // Vérifier que la course n'a pas déjà été notée
    if (ride.rating && ride.rating.score) {
      return res.status(400).json({
        success: false,
        message: 'Cette course a déjà été notée'
      });
    }

    const { rating, comment, feedbacks } = req.body;

    // Enregistrer la note
    ride.rating = {
      score: rating,
      comment: comment || '',
      feedbacks: feedbacks || [],
      ratedAt: new Date()
    };
    await ride.save();

    // Mettre à jour la note moyenne du chauffeur
    if (ride.driver) {
      const driver = await Driver.findById(ride.driver);
      if (driver) {
        const completedRides = await Ride.find({
          driver: driver._id,
          status: 'completed',
          'rating.score': { $exists: true }
        });

        const totalRatings = completedRides.length;
        const sumRatings = completedRides.reduce((sum, r) => sum + (r.rating?.score || 0), 0);
        driver.rating = totalRatings > 0 ? sumRatings / totalRatings : 0;
        driver.totalRides = await Ride.countDocuments({ driver: driver._id, status: 'completed' });
        await driver.save();
      }
    }

    res.json({
      success: true,
      message: 'Merci pour votre note !',
      data: {
        rating: ride.rating
      }
    });

  } catch (error) {
    console.error('Erreur lors de la notation de la course:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/rides/:id/rate-passenger
// @desc    Noter le passager (côté chauffeur)
// @access  Private (chauffeur assigné)
router.post('/:id/rate-passenger', [
  auth,
  body('rating').isInt({ min: 1, max: 5 }).withMessage('La note doit être entre 1 et 5')
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
    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({ success: false, message: 'Course non trouvée' });
    }
    if (ride.driver.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Seul le chauffeur assigné peut noter le passager'
      });
    }
    if (ride.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Seules les courses terminées peuvent être notées'
      });
    }
    if (ride.passengerRating && ride.passengerRating.score) {
      return res.status(400).json({
        success: false,
        message: 'Ce passager a déjà été noté pour cette course'
      });
    }
    const { rating, comment } = req.body;
    ride.passengerRating = {
      score: rating,
      comment: comment || '',
      ratedAt: new Date()
    };
    await ride.save();
    res.json({
      success: true,
      message: 'Évaluation du passager enregistrée',
      data: { passengerRating: ride.passengerRating }
    });
  } catch (error) {
    console.error('Erreur rate-passenger:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/rides/public/tracking/:rideKey
// @desc    Suivi public (ami) — sans auth ; positions limitées aux courses actives
// @access  Public (lien partagé)
router.get('/public/tracking/:rideKey', async (req, res) => {
  try {
    const { rideKey } = req.params;
    if (!rideKey || rideKey.length > 128) {
      return res.status(400).json({ success: false, message: 'Référence invalide' });
    }

    let ride = null;
    if (mongoose.Types.ObjectId.isValid(rideKey)) {
      ride = await Ride.findById(rideKey);
    }
    if (!ride) {
      ride = await Ride.findOne({ rideId: rideKey });
    }
    if (!ride) {
      return res.status(404).json({ success: false, message: 'Course introuvable' });
    }

    const active = ACTIVE_RIDE_STATUSES.includes(ride.status);
    let latitude = null;
    let longitude = null;
    let updatedAt = null;

    if (ride.tracking && ride.tracking.length > 0) {
      const last = ride.tracking[ride.tracking.length - 1];
      latitude = last.latitude;
      longitude = last.longitude;
      updatedAt = last.timestamp || null;
    }

    if ((latitude == null || longitude == null) && ride.driver) {
      const dr = await Driver.findById(ride.driver).select('currentLocation location');
      if (dr?.currentLocation?.coordinates?.length === 2) {
        longitude = dr.currentLocation.coordinates[0];
        latitude = dr.currentLocation.coordinates[1];
        updatedAt = dr.currentLocation.lastUpdated || new Date();
      } else if (dr?.location?.latitude != null && dr?.location?.longitude != null) {
        latitude = dr.location.latitude;
        longitude = dr.location.longitude;
        updatedAt = dr.location.lastUpdated || new Date();
      }
    }

    return res.json({
      success: true,
      data: {
        rideId: ride.rideId,
        status: ride.status,
        active,
        pickup: {
          address: ride.pickup?.address,
          latitude: ride.pickup?.coordinates?.latitude,
          longitude: ride.pickup?.coordinates?.longitude,
        },
        destination: {
          address: ride.destination?.address,
          latitude: ride.destination?.coordinates?.latitude,
          longitude: ride.destination?.coordinates?.longitude,
        },
        location:
          latitude != null && longitude != null
            ? {
                latitude,
                longitude,
                updatedAt,
              }
            : null,
      },
    });
  } catch (error) {
    console.error('public/tracking:', error);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
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
    const isCounterOfferDriver =
      !ride.driver &&
      ride.counterOffer &&
      ride.counterOffer.driver &&
      ride.counterOffer.driver.toString() === req.userId.toString();

    if (!isPassenger && !isDriver && !isCounterOfferDriver) {
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
          cancellation: ride.cancellation,
          counterOffer: ride.counterOffer || null,
          scheduledFor: ride.scheduledFor || null,
          scheduledPickupEnRouteAt: ride.scheduledPickupEnRouteAt || null,
          scheduledPickupArrivedAt: ride.scheduledPickupArrivedAt || null,
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

// @route   POST /api/v1/rides/create
// @desc    Créer une course avec PRIX LIBRE (concept DUDU)
// @access  Private
router.post('/create', [
  auth,
  // requireVerification, // Désactivé temporairement pour les tests
  body('pickup.latitude').isFloat().withMessage('Latitude de départ invalide'),
  body('pickup.longitude').isFloat().withMessage('Longitude de départ invalide'),
  body('pickup.address').notEmpty().withMessage('Adresse de départ requise'),
  body('destination.latitude').isFloat().withMessage('Latitude de destination invalide'),
  body('destination.longitude').isFloat().withMessage('Longitude de destination invalide'),
  body('destination.address').notEmpty().withMessage('Adresse de destination requise'),
  body('rideType').isIn(['standard', 'comfort', 'women_only', 'delivery', 'luxe', 'moto']).withMessage('Type de course invalide'),
  body('customPrice').optional().isInt({ min: 500 }).withMessage('Le prix minimum est 500 FCFA'),
  body('customPricePerKm').optional().isFloat({ min: 500, max: 5000 }).withMessage('Prix par km invalide'),
  body('estimatedDistance').isFloat({ min: 0 }).withMessage('Distance invalide')
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
      rideType,
      customPrice,
      customPricePerKm,
      estimatedDistance,
      isUrgentDelivery,
      isUrgent,
    } = req.body;

    const deliveryIsUrgent =
      rideType === 'delivery' &&
      (isUrgentDelivery === true ||
        isUrgent === true ||
        isUrgentDelivery === 'true' ||
        isUrgent === 'true');

    // Calculer le prix total selon le type
    let totalPrice;
    let normalizedCustomPricePerKm = null;
    if (rideType === 'moto') {
      const perKm = Number(customPricePerKm);
      if (!Number.isFinite(perKm) || perKm <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Pour les motos, le prix par km (customPricePerKm) est requis et doit être > 0'
        });
      }
      normalizedCustomPricePerKm = perKm;
      totalPrice = Math.round(perKm * Number(estimatedDistance));
      if (totalPrice < 500) totalPrice = 500;
    } else if (rideType === 'luxe') {
      // Pour les courses luxe : prix de base 15000 FCFA, le client propose son prix
      if (typeof customPrice !== 'number' && typeof customPrice !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Le prix proposé (customPrice) est requis pour les courses luxe'
        });
      }
      totalPrice = Number(customPrice);
      if (!Number.isFinite(totalPrice) || totalPrice < 15000) {
        return res.status(400).json({
          success: false,
          message: 'Le prix minimum pour les courses luxe est 15000 FCFA'
        });
      }
    } else {
      if (typeof customPrice !== 'number' && typeof customPrice !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Le prix proposé (customPrice) est requis'
        });
      }
      totalPrice = Number(customPrice);
      if (!Number.isFinite(totalPrice) || totalPrice < 500) {
        return res.status(400).json({
          success: false,
          message: 'Le prix minimum est 500 FCFA'
        });
      }
    }

    // Générer un identifiant unique pour la course (rideId requis par le schéma)
    const rideId = `RIDE-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

    // Créer la course avec le prix libre proposé par le client
    const ride = new Ride({
      rideId,
      passenger: (req.user && (req.user.id || req.user._id)) || req.userId,
      pickup: {
        address: pickup.address,
        coordinates: {
          latitude: pickup.latitude,
          longitude: pickup.longitude
        },
        location: {
          type: 'Point',
          coordinates: [pickup.longitude, pickup.latitude]
        }
      },
      destination: {
        address: destination.address,
        coordinates: {
          latitude: destination.latitude,
          longitude: destination.longitude
        },
        location: {
          type: 'Point',
          coordinates: [destination.longitude, destination.latitude]
        }
      },
      distance: estimatedDistance,
      estimatedDuration: Math.round(estimatedDistance * 3), // ~20 km/h moyenne
      pricing: {
        basePrice: 0,
        distancePrice: 0,
        timePrice: 0,
        surgeMultiplier: 1.0,
        totalPrice: totalPrice,
        currency: 'XOF',
        isPriceFixed: true,
        customPrice: totalPrice,
        customPricePerKm: normalizedCustomPricePerKm
      },
      rideType,
      passengers: 1,
      status: 'requested',
      payment: {
        method: 'cash',
        status: 'pending'
      },
      ...(rideType === 'delivery'
        ? {
            delivery: {
              isUrgent: deliveryIsUrgent,
            },
          }
        : {}),
    });

    await ride.save();

    // Définir le rayon de recherche selon le type de course
    const SEARCH_RADIUS = {
      standard: 5000,    // 5 km
      comfort: 7000,     // 7 km - Plus grand rayon pour trouver des véhicules confort
      women_only: 5000,  // 5 km
      delivery: 3000,    // 3 km - Motos plus proches
      moto: 3000,
      luxe: 7000
    };
    
    const searchRadius = SEARCH_RADIUS[rideType] || 5000;
    
    const baseDriverQuery = {
      status: 'online',
      isAvailable: true,
      'subscription.isActive': true,
      'subscription.endDate': { $gt: new Date() },
      'preferences.minPrice': { $lte: totalPrice },
      'location.latitude': { $exists: true, $ne: null },
      'location.longitude': { $exists: true, $ne: null },
      ...buildDriverQueryForRideType(rideType),
    };

    // Rechercher des chauffeurs disponibles
    console.log('🔍 Recherche de chauffeurs pour course PRIX LIBRE', {
      rideId,
      rideType,
      customPrice: totalPrice,
      customPricePerKm: normalizedCustomPricePerKm,
      pickup,
    });

    const allDrivers = await Driver.find(baseDriverQuery)
      .populate('user', 'firstName lastName gender')
      .limit(50);

    console.log('🔎 Chauffeurs correspondant aux filtres de base (hors distance):', allDrivers.length);

    // Filtrer par distance manuellement (car on n'a plus d'index géospatial)
    let availableDrivers = allDrivers.filter(driver => {
      let dLat = driver.location?.latitude;
      let dLng = driver.location?.longitude;
      if (dLat == null || dLng == null) {
        const c = driver.currentLocation?.coordinates;
        if (Array.isArray(c) && c.length >= 2) {
          dLng = c[0];
          dLat = c[1];
        }
      }
      if (dLat == null || dLng == null) {
        return false;
      }

      const distance = calculateDistance(
        pickup.latitude,
        pickup.longitude,
        dLat,
        dLng
      );
      
      const inRadius = distance <= (searchRadius / 1000);
      if (!inRadius) {
        console.log('🚫 Chauffeur en dehors du rayon', {
          driverId: driver._id.toString(),
          phone: driver.phone,
          driverLat: driver.location.latitude,
          driverLng: driver.location.longitude,
          distanceKm: distance,
        });
      }
      return inRadius; // Convertir en km
    }).slice(0, 20);

    console.log('✅ Chauffeurs disponibles après filtre distance:', availableDrivers.length);

    // Livreurs : ne notifier que les livreurs pouvant prendre cette course (2e livraison non urgente, ou urgent seul)
    if (rideType === 'delivery' && availableDrivers.length > 0) {
      const filtered = [];
      for (const d of availableDrivers) {
        if (await driverShouldReceiveDeliveryNotification(d._id, deliveryIsUrgent)) {
          filtered.push(d);
        }
      }
      availableDrivers = filtered;
      console.log('📦 Livreurs éligibles (urgent / empilement):', availableDrivers.length);
    }

    // Fallback de TEST (courses standard uniquement — ne pas contourner confort / luxe / femmes / livraison)
    if (availableDrivers.length === 0 && rideType === 'standard') {
      const testDriver = await Driver.findOne({ phone: '+221781000734' });
      if (testDriver) {
        console.log('🧪 Fallback: chauffeur de test 781000734 (standard)');
        availableDrivers = [testDriver];
      } else {
        console.log('❌ Fallback: chauffeur de test 781000734 introuvable en base');
      }
    }

    if (availableDrivers.length === 0) {
      ride.status = 'no_driver';
      await ride.save();
      
      return res.status(200).json({
        success: true,
        message: 'Aucun chauffeur disponible pour le moment. Veuillez réessayer.',
        data: {
          rideId: ride._id,
          status: 'no_driver'
        }
      });
    }

    // ============================================================
    // LOGIQUE DE NOTIFICATION DES CHAUFFEURS
    // ============================================================
    // - Course STANDARD → Notifier TOUS les chauffeurs (Standard + Express) en même temps
    // - Course EXPRESS → Notifier UNIQUEMENT les chauffeurs Express
    // - Un chauffeur EXPRESS peut prendre des courses standard ET express
    // - Un chauffeur STANDARD ne peut prendre que des courses standard
    // - Quand une course est acceptée, elle disparaît pour tous les autres
    // ============================================================
    
    const comfortDrivers = availableDrivers.filter(
      (d) => d.rideTypes && d.rideTypes.comfort === true
    );

    // Notifier les chauffeurs via Socket.IO
    const io = req.app.get('io');
    if (io) {
      const extras =
        rideType === 'delivery' ? { isUrgentDelivery: deliveryIsUrgent } : {};
      const ridePayload = buildNewRideRequestPayload(ride, req.user, extras);

      const emitToDriver = (driver) => {
        const d = driver.calculateDistance
          ? driver.calculateDistance(pickup.latitude, pickup.longitude)
          : 0;
        io.to(`driver_${driver._id}`).emit('new-ride-request', {
          ...ridePayload,
          driverDistance: d,
        });
      };

      if (rideType === 'comfort') {
        console.log('🎯 Course CONFORT: uniquement chauffeurs avec rideTypes.comfort');
        comfortDrivers.forEach(emitToDriver);
        console.log(`📣 ${comfortDrivers.length} chauffeur(s) Confort notifié(s)`);
      } else {
        console.log(`📢 Course ${rideType}: notification aux chauffeurs filtrés`);
        availableDrivers.forEach(emitToDriver);
        console.log(`📣 ${availableDrivers.length} chauffeur(s) notifié(s)`);
      }
    }

    res.status(201).json({
      success: true,
      message: `Demande envoyée à ${availableDrivers.length} chauffeur(s) disponible(s)`,
      data: {
        rideId: ride._id,
        status: 'requested',
        driversNotified: availableDrivers.length,
        customPrice,
        estimatedDistance
      }
    });

  } catch (error) {
    console.error('Erreur lors de la création de la course:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// @route   POST /api/v1/rides/schedule
// @desc    Planifier une course pour plus tard (utilisée par l'app client)
// @access  Private (utilisateur)
router.post('/schedule', [
  auth,
  body('pickup.address').notEmpty().withMessage('Adresse de départ requise'),
  body('pickup.latitude').isFloat().withMessage('Latitude de départ invalide'),
  body('pickup.longitude').isFloat().withMessage('Longitude de départ invalide'),
  body('destination.address').notEmpty().withMessage('Adresse de destination requise'),
  body('destination.latitude').isFloat().withMessage('Latitude de destination invalide'),
  body('destination.longitude').isFloat().withMessage('Longitude de destination invalide'),
  body('rideType').isIn(['standard', 'comfort', 'women_only', 'delivery']).withMessage('Type de course invalide'),
  body('customPrice').isInt({ min: 500 }).withMessage('Le prix minimum est 500 FCFA'),
  body('scheduledFor').notEmpty().withMessage('Date de programmation requise'),
  body('paymentMethod').optional().isIn(['wave', 'cash']).withMessage('Méthode de paiement invalide')
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
      rideType,
      customPrice,
      scheduledFor,
      paymentMethod: rawPaymentMethod
    } = req.body;

    const paymentMethod = ['wave', 'cash'].includes(rawPaymentMethod)
      ? rawPaymentMethod
      : 'cash';

    const pickupLat = pickup.latitude;
    const pickupLng = pickup.longitude;
    const destLat = destination.latitude;
    const destLng = destination.longitude;

    const distance = calculateDistance(pickupLat, pickupLng, destLat, destLng);
    const estimatedDuration = Math.round(distance * 3); // estimation simple
    // Générer un identifiant unique pour la course planifiée
    const rideId = `RIDE-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

    const ride = new Ride({
      rideId,
      passenger: req.user.id || req.userId,
      pickup: {
        address: pickup.address,
        coordinates: {
          latitude: pickupLat,
          longitude: pickupLng
        },
        location: {
          type: 'Point',
          coordinates: [pickupLng, pickupLat]
        }
      },
      destination: {
        address: destination.address,
        coordinates: {
          latitude: destLat,
          longitude: destLng
        },
        location: {
          type: 'Point',
          coordinates: [destLng, destLat]
        }
      },
      distance,
      estimatedDuration,
      pricing: {
        basePrice: 0,
        distancePrice: 0,
        timePrice: 0,
        surgeMultiplier: 1.0,
        totalPrice: customPrice,
        currency: 'XOF',
        isPriceFixed: true,
        customPrice
      },
      rideType,
      passengers: 1,
      status: 'requested',
      scheduledFor: new Date(scheduledFor),
      payment: {
        method: paymentMethod,
        status: 'pending'
      }
    });

    await ride.save();

    // Notifier tout de suite les chauffeurs à proximité (même format que demande immédiate)
    let driversNotified = 0;
    try {
      const io = getIO();
      const passengerUser = await User.findById(req.userId);
      if (io && passengerUser) {
        const { notified } = await notifyDriversNewRideRequest(io, ride, passengerUser);
        driversNotified = notified;
      }
    } catch (notifyErr) {
      console.error('Notification chauffeurs (course planifiée):', notifyErr);
    }

    return res.status(201).json({
      success: true,
      message: 'Course planifiée avec succès',
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
          scheduledFor: ride.scheduledFor,
          requestedAt: ride.requestedAt
        },
        driversNotified
      }
    });
  } catch (error) {
    console.error('Erreur lors de la planification de la course:', error);
    return res.status(500).json({
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




