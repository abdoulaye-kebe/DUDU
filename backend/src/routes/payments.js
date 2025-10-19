const express = require('express');
const { body, validationResult } = require('express-validator');
const Payment = require('../models/Payment');
const Ride = require('../models/Ride');
const { auth, requireVerification, requireDriver } = require('../middleware/auth');
const router = express.Router();

// @route   POST /api/v1/payments/initiate
// @desc    Initier un paiement
// @access  Private
router.post('/initiate', [
  auth,
  requireVerification,
  body('rideId').optional().isMongoId().withMessage('ID de course invalide'),
  body('subscriptionId').optional().isMongoId().withMessage('ID d\'abonnement invalide'),
  body('amount').isFloat({ min: 0 }).withMessage('Le montant doit être positif'),
  body('method').isIn(['orange_money', 'wave', 'free_money', 'cash']).withMessage('Méthode de paiement invalide'),
  body('phone').optional().matches(/^(\+221|221)?[0-9]{9}$/).withMessage('Format de téléphone invalide')
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

    const { rideId, subscriptionId, amount, method, phone, currency = 'XOF' } = req.body;

    // Vérifier qu'au moins un ID est fourni
    if (!rideId && !subscriptionId) {
      return res.status(400).json({
        success: false,
        message: 'ID de course ou d\'abonnement requis'
      });
    }

    // Déterminer le type de paiement
    let type, relatedId;
    if (rideId) {
      const ride = await Ride.findById(rideId);
      if (!ride) {
        return res.status(404).json({
          success: false,
          message: 'Course non trouvée'
        });
      }
      type = 'ride_payment';
      relatedId = rideId;
    } else {
      type = 'subscription';
      relatedId = subscriptionId;
    }

    // Créer le paiement
    const payment = new Payment({
      user: req.userId,
      ride: rideId,
      type,
      amount,
      currency,
      method,
      status: 'pending'
    });

    // Ajouter les informations spécifiques à la méthode
    if (method !== 'cash' && phone) {
      payment.mobileMoney = {
        phone,
        operator: method.split('_')[0] // orange, wave, free
      };
    }

    await payment.save();

    // Initier le paiement selon la méthode
    if (method === 'cash') {
      payment.status = 'completed';
      payment.cash = {
        collectedBy: null, // Sera rempli par le chauffeur
        collectedAt: null,
        verified: false
      };
      await payment.save();

      res.json({
        success: true,
        message: 'Paiement en espèces enregistré',
        data: {
          payment: payment.getSummary()
        }
      });
    } else {
      // Initier le paiement mobile money
      payment.initiateMobileMoneyPayment(phone, method.split('_')[0]);
      await payment.save();

      // TODO: Intégrer avec les APIs de paiement mobile money
      // Pour l'instant, on simule
      setTimeout(async () => {
        payment.confirmPayment(
          Math.random().toString(36).substr(2, 8),
          `TXN_${Date.now()}`
        );
        await payment.save();
      }, 5000);

      res.json({
        success: true,
        message: 'Paiement mobile money initié',
        data: {
          payment: payment.getSummary(),
          transactionCode: payment.mobileMoney.transactionCode
        }
      });
    }

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/payments/:id/confirm
// @desc    Confirmer un paiement
// @access  Private
router.post('/:id/confirm', [
  auth,
  body('confirmationCode').notEmpty().withMessage('Code de confirmation requis'),
  body('externalId').optional().isString()
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

    const { confirmationCode, externalId } = req.body;

    const payment = await Payment.findById(req.params.id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Paiement non trouvé'
      });
    }

    if (payment.user.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    if (payment.status !== 'processing') {
      return res.status(400).json({
        success: false,
        message: 'Ce paiement ne peut pas être confirmé'
      });
    }

    // Confirmer le paiement
    payment.confirmPayment(confirmationCode, externalId);
    await payment.save();

    // Si c'est un paiement de course, mettre à jour le statut
    if (payment.type === 'ride_payment' && payment.ride) {
      const ride = await Ride.findById(payment.ride);
      if (ride) {
        ride.payment.status = 'completed';
        ride.payment.paidAt = new Date();
        await ride.save();
      }
    }

    res.json({
      success: true,
      message: 'Paiement confirmé avec succès',
      data: {
        payment: payment.getSummary()
      }
    });

  } catch (error) {
    console.error('Erreur lors de la confirmation du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/payments/:id/verify-cash
// @desc    Vérifier un paiement en espèces (chauffeur)
// @access  Private (chauffeur)
router.post('/:id/verify-cash', [
  auth,
  requireDriver,
  body('verified').isBoolean().withMessage('Statut de vérification requis')
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

    const { verified } = req.body;

    const payment = await Payment.findById(req.params.id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Paiement non trouvé'
      });
    }

    if (payment.method !== 'cash') {
      return res.status(400).json({
        success: false,
        message: 'Ce paiement n\'est pas en espèces'
      });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Ce paiement n\'est pas encore complété'
      });
    }

    // Vérifier que le chauffeur est assigné à la course
    if (payment.ride) {
      const ride = await Ride.findById(payment.ride);
      if (!ride || ride.driver.toString() !== req.driver._id.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Vous n\'êtes pas autorisé à vérifier ce paiement'
        });
      }
    }

    payment.cash.collectedBy = req.driver._id;
    payment.cash.collectedAt = new Date();
    payment.cash.verified = verified;
    payment.isVerified = verified;
    payment.verifiedAt = new Date();
    payment.verifiedBy = req.userId;

    await payment.save();

    res.json({
      success: true,
      message: verified ? 'Paiement vérifié avec succès' : 'Paiement marqué comme non vérifié',
      data: {
        payment: payment.getSummary()
      }
    });

  } catch (error) {
    console.error('Erreur lors de la vérification du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/payments
// @desc    Obtenir l'historique des paiements
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, type, status } = req.query;
    const skip = (page - 1) * limit;

    // Construire le filtre
    const filter = { user: req.userId };
    if (type) filter.type = type;
    if (status) filter.status = status;

    const payments = await Payment.find(filter)
      .populate('ride', 'rideId pickup destination pricing')
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Payment.countDocuments(filter);

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
          ride: payment.ride ? {
            id: payment.ride._id,
            rideId: payment.ride.rideId,
            pickup: payment.ride.pickup,
            destination: payment.ride.destination,
            pricing: payment.ride.pricing
          } : null,
          driver: payment.driver ? {
            id: payment.driver._id,
            name: payment.driver.user ? 
              `${payment.driver.user.firstName} ${payment.driver.user.lastName}` : 
              'Chauffeur inconnu',
            vehicle: payment.driver.vehicle ? {
              make: payment.driver.vehicle.make,
              model: payment.driver.vehicle.model,
              plateNumber: payment.driver.vehicle.plateNumber
            } : null
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

// @route   GET /api/v1/payments/:id
// @desc    Obtenir les détails d'un paiement
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id)
      .populate('ride', 'rideId pickup destination pricing')
      .populate('driver', 'user vehicle')
      .populate('driver.user', 'firstName lastName');

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Paiement non trouvé'
      });
    }

    if (payment.user.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    res.json({
      success: true,
      data: {
        payment: {
          id: payment._id,
          paymentId: payment.paymentId,
          type: payment.type,
          amount: payment.amount,
          currency: payment.currency,
          method: payment.method,
          status: payment.status,
          transaction: payment.transaction,
          mobileMoney: payment.mobileMoney,
          cash: payment.cash,
          fees: payment.fees,
          ride: payment.ride,
          driver: payment.driver,
          initiatedAt: payment.initiatedAt,
          completedAt: payment.completedAt,
          isVerified: payment.isVerified,
          statusHistory: payment.statusHistory
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/payments/:id/refund
// @desc    Demander un remboursement
// @access  Private
router.post('/:id/refund', [
  auth,
  body('reason').notEmpty().withMessage('Raison du remboursement requise')
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

    const payment = await Payment.findById(req.params.id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Paiement non trouvé'
      });
    }

    if (payment.user.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Seuls les paiements complétés peuvent être remboursés'
      });
    }

    // Traiter le remboursement
    payment.processRefund(reason, payment.method);
    await payment.save();

    res.json({
      success: true,
      message: 'Demande de remboursement traitée',
      data: {
        payment: payment.getSummary()
      }
    });

  } catch (error) {
    console.error('Erreur lors du remboursement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;




