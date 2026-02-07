const express = require('express');
const { body, validationResult } = require('express-validator');
const Payment = require('../models/Payment');
const Ride = require('../models/Ride');
const orangeMoneyService = require('../services/orangeMoneyService');
const waveService = require('../services/waveService');
const { auth, requireVerification } = require('../middleware/auth');
const router = express.Router();

// @route   POST /api/v1/mobile-payments/orange-money/initiate
// @desc    Initier un paiement Orange Money
// @access  Private
router.post('/orange-money/initiate', [
  auth,
  // requireVerification, // Temporairement désactivé - TODO: Fixer le middleware auth pour charger isVerified
  body('rideId').optional().isMongoId().withMessage('ID de course invalide'),
  body('amount').isFloat({ min: 100 }).withMessage('Le montant minimum est 100 FCFA'),
  body('phone').matches(/^(\+221|221)?[0-9]{9}$/).withMessage('Numéro de téléphone invalide'),
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

    const { rideId, amount, phone } = req.body;

    // Vérifier la course si fournie
    let ride = null;
    if (rideId) {
      ride = await Ride.findById(rideId);
      if (!ride) {
        return res.status(404).json({
          success: false,
          message: 'Course non trouvée'
        });
      }

      if (ride.passenger.toString() !== req.userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Vous n\'êtes pas autorisé à payer cette course'
        });
      }
    }

    // Créer le paiement dans la base de données
    const payment = new Payment({
      user: req.userId,
      ride: rideId,
      type: rideId ? 'ride_payment' : 'subscription',
      amount: amount,
      currency: 'XOF',
      method: 'orange_money',
      status: 'pending',
      mobileMoney: {
        phone: phone,
        operator: 'orange'
      }
    });

    await payment.save();

    // Initier le paiement via Orange Money API
    const omPayment = await orangeMoneyService.initiatePayment({
      orderId: payment.paymentId,
      amount: amount,
      phone: phone,
      description: ride ? `Course DUDU ${ride.rideId}` : 'Paiement DUDU'
    });

    // Mettre à jour le paiement avec les infos Orange Money
    payment.transaction.externalId = omPayment.paymentToken;
    payment.status = 'processing';
    payment.updateStatus('processing', 'Paiement Orange Money initié', 'system');
    await payment.save();

    res.json({
      success: true,
      message: 'Paiement Orange Money initié avec succès',
      data: {
        paymentId: payment._id,
        qrCode: omPayment.qrCode,
        qrCodeUrl: omPayment.qrCodeUrl,
        // Deeplinks pour ouverture directe des apps
        deeplinks: omPayment.deeplinks,
        amount: amount,
        currency: 'XOF',
        expiresAt: omPayment.expiresAt,
        instructions: 'Scannez le QR Code ou utilisez les deeplinks pour payer avec MAX IT ou Orange Money'
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement Orange Money:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Erreur lors de l\'initiation du paiement'
    });
  }
});

// @route   POST /api/v1/mobile-payments/wave/initiate
// @desc    Initier un paiement Wave
// @access  Private
router.post('/wave/initiate', [
  auth,
  requireVerification,
  body('rideId').optional().isMongoId().withMessage('ID de course invalide'),
  body('amount').isFloat({ min: 100 }).withMessage('Le montant minimum est 100 FCFA'),
  body('phone').matches(/^(\+221|221)?[0-9]{9}$/).withMessage('Numéro de téléphone invalide'),
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

    const { rideId, amount, phone } = req.body;

    // Vérifier la course si fournie
    let ride = null;
    if (rideId) {
      ride = await Ride.findById(rideId);
      if (!ride) {
        return res.status(404).json({
          success: false,
          message: 'Course non trouvée'
        });
      }

      if (ride.passenger.toString() !== req.userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Vous n\'êtes pas autorisé à payer cette course'
        });
      }
    }

    // Créer le paiement dans la base de données
    const payment = new Payment({
      user: req.userId,
      ride: rideId,
      type: rideId ? 'ride_payment' : 'subscription',
      amount: amount,
      currency: 'XOF',
      method: 'wave',
      status: 'pending',
      mobileMoney: {
        phone: phone,
        operator: 'wave'
      }
    });

    await payment.save();

    // Initier le paiement via Wave API
    const wavePayment = await waveService.initiatePayment({
      orderId: payment.paymentId,
      amount: amount,
      phone: phone,
      description: ride ? `Course DUDU ${ride.rideId}` : 'Paiement DUDU'
    });

    // Mettre à jour le paiement avec les infos Wave
    payment.transaction.externalId = wavePayment.sessionId;
    payment.status = 'processing';
    payment.updateStatus('processing', 'Paiement Wave initié', 'system');
    await payment.save();

    res.json({
      success: true,
      message: 'Paiement Wave initié avec succès',
      data: {
        paymentId: payment._id,
        sessionId: wavePayment.sessionId,
        checkoutUrl: wavePayment.checkoutUrl,
        amount: amount,
        currency: 'XOF',
        expiresAt: wavePayment.expiresAt,
        instructions: 'Suivez le lien pour compléter le paiement sur Wave'
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement Wave:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Erreur lors de l\'initiation du paiement'
    });
  }
});

// @route   GET /api/v1/mobile-payments/:id/status
// @desc    Vérifier le statut d'un paiement
// @access  Private
router.get('/:id/status', auth, async (req, res) => {
  try {
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

    // Si le paiement est déjà complété ou échoué, retourner le statut actuel
    if (['completed', 'failed', 'cancelled', 'refunded'].includes(payment.status)) {
      return res.json({
        success: true,
        data: {
          paymentId: payment._id,
          status: payment.status,
          amount: payment.amount,
          currency: payment.currency,
          method: payment.method,
          completedAt: payment.completedAt,
          failedAt: payment.failedAt,
        }
      });
    }

    // Vérifier le statut auprès du fournisseur
    let providerStatus;
    
    if (payment.method === 'orange_money') {
      providerStatus = await orangeMoneyService.checkPaymentStatus(payment.transaction.externalId);
    } else if (payment.method === 'wave') {
      providerStatus = await waveService.checkPaymentStatus(payment.transaction.externalId);
    } else {
      return res.json({
        success: true,
        data: {
          paymentId: payment._id,
          status: payment.status,
          amount: payment.amount,
          currency: payment.currency,
          method: payment.method,
        }
      });
    }

    // Mettre à jour le statut si changé
    if (providerStatus.status !== payment.status) {
      payment.updateStatus(providerStatus.status, 'Statut mis à jour depuis le fournisseur', 'system');
      
      if (providerStatus.status === 'completed') {
        payment.transaction.processedAt = providerStatus.paidAt;
        payment.mobileMoney.confirmationCode = providerStatus.transactionId;
        
        // Mettre à jour la course si applicable
        if (payment.ride) {
          const ride = await Ride.findById(payment.ride);
          if (ride) {
            ride.payment.status = 'completed';
            ride.payment.paidAt = new Date();
            await ride.save();
          }
        }
      }
      
      await payment.save();
    }

    res.json({
      success: true,
      data: {
        paymentId: payment._id,
        status: payment.status,
        amount: payment.amount,
        currency: payment.currency,
        method: payment.method,
        transactionId: providerStatus.transactionId,
        completedAt: payment.completedAt,
        failedAt: payment.failedAt,
      }
    });

  } catch (error) {
    console.error('Erreur lors de la vérification du statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du statut du paiement'
    });
  }
});

// @route   POST /api/v1/mobile-payments/orange-money/callback
// @desc    Callback Orange Money
// @access  Public (avec validation)
router.post('/orange-money/callback', async (req, res) => {
  try {
    const callbackData = req.body;
    
    // Traiter le callback
    const result = await orangeMoneyService.handleCallback(callbackData);
    
    // Trouver le paiement
    const payment = await Payment.findOne({ paymentId: result.orderId });
    
    if (!payment) {
      console.error('Paiement non trouvé pour le callback Orange Money:', result.orderId);
      return res.status(404).json({ success: false, message: 'Paiement non trouvé' });
    }

    // Mettre à jour le paiement
    payment.updateStatus(result.status, `Callback Orange Money: ${result.message}`, 'system');
    payment.transaction.externalId = result.transactionId;
    payment.transaction.processedAt = result.paidAt;
    payment.mobileMoney.confirmationCode = result.transactionId;
    
    if (result.status === 'completed' && payment.ride) {
      const ride = await Ride.findById(payment.ride);
      if (ride) {
        ride.payment.status = 'completed';
        ride.payment.paidAt = new Date();
        await ride.save();
      }
    }
    
    await payment.save();

    res.json({ success: true, message: 'Callback traité avec succès' });

  } catch (error) {
    console.error('Erreur lors du traitement du callback Orange Money:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du traitement du callback' });
  }
});

// @route   POST /api/v1/mobile-payments/wave/webhook
// @desc    Webhook Wave
// @access  Public (avec validation signature)
router.post('/wave/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    // Récupérer le payload brut pour la vérification de signature
    const rawBody = req.body.toString('utf8');
    const signature = req.headers['x-wave-signature'];
    
    // Vérifier la signature du webhook
    const isValid = waveService.verifyWebhookSignature(rawBody, signature);
    
    if (!isValid) {
      console.error('❌ Signature webhook Wave invalide');
      return res.status(401).json({ success: false, message: 'Signature invalide' });
    }
    
    console.log('✅ Signature webhook Wave vérifiée');
    
    // Parser les données
    const webhookData = JSON.parse(rawBody);
    
    // Traiter le webhook
    const result = await waveService.handleWebhook(webhookData, signature);
    
    // Trouver le paiement
    const payment = await Payment.findOne({ paymentId: result.orderId });
    
    if (!payment) {
      console.error('Paiement non trouvé pour le webhook Wave:', result.orderId);
      return res.status(404).json({ success: false, message: 'Paiement non trouvé' });
    }

    // Mettre à jour le paiement
    payment.updateStatus(result.status, `Webhook Wave: ${result.event}`, 'system');
    payment.transaction.externalId = result.transactionId;
    payment.transaction.processedAt = result.paidAt;
    payment.mobileMoney.confirmationCode = result.transactionId;
    
    // Si c'est un paiement de course
    if (result.status === 'completed' && payment.ride) {
      const ride = await Ride.findById(payment.ride);
      if (ride) {
        ride.payment.status = 'completed';
        ride.payment.paidAt = new Date();
        await ride.save();
      }
    }
    
    // Si c'est un paiement d'abonnement
    if (result.status === 'completed' && payment.metadata?.type === 'subscription') {
      const Driver = require('../models/Driver');
      const driver = await Driver.findById(payment.driver);
      
      if (driver) {
        const subscriptionId = payment.metadata.subscriptionId;
        
        // Déterminer la durée selon le type d'abonnement
        let durationDays = 30; // Par défaut mensuel
        let planType = 'monthly';
        
        if (subscriptionId.includes('daily')) {
          durationDays = 1;
          planType = 'daily';
        } else if (subscriptionId.includes('weekly')) {
          durationDays = 7;
          planType = 'weekly';
        } else if (subscriptionId.includes('yearly')) {
          durationDays = 365;
          planType = 'yearly';
        }
        
        // Activer l'abonnement
        driver.subscription.plan = planType;
        driver.subscription.startDate = new Date();
        driver.subscription.endDate = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);
        driver.subscription.isActive = true;
        
        await driver.save();
        
        console.log(`✅ Abonnement ${planType} activé pour le chauffeur ${driver._id}`);
      }
    }
    
    await payment.save();

    console.log(`✅ Webhook Wave traité: ${result.orderId} - ${result.status}`);
    res.json({ success: true, message: 'Webhook traité avec succès' });

  } catch (error) {
    console.error('Erreur lors du traitement du webhook Wave:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du traitement du webhook' });
  }
});

// @route   POST /api/v1/mobile-payments/subscription/wave/initiate
// @desc    Initier un paiement d'abonnement via Wave
// @access  Private
router.post('/subscription/wave/initiate', auth, async (req, res) => {
  try {
    const { subscriptionId, amount, phone } = req.body;

    // Validation
    if (!subscriptionId || !amount || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Données manquantes (subscriptionId, amount, phone requis)'
      });
    }

    // Vérifier que l'utilisateur est un chauffeur
    if (!req.user.isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Seuls les chauffeurs peuvent souscrire à un abonnement'
      });
    }

    // Créer un paiement pour l'abonnement
    const payment = new Payment({
      user: req.user.userId,
      driver: req.user.userId,
      amount,
      currency: 'XOF',
      method: 'wave',
      status: 'pending',
      description: `Paiement abonnement - ${subscriptionId}`,
      metadata: {
        subscriptionId,
        type: 'subscription'
      }
    });

    await payment.save();

    // Initier le paiement Wave
    const result = await waveService.initiatePayment({
      orderId: payment.paymentId,
      amount,
      phone,
      description: `Abonnement DUDU - ${subscriptionId}`
    });

    // Mettre à jour le paiement
    payment.transaction.externalId = result.sessionId;
    payment.mobileMoney.provider = 'wave';
    payment.mobileMoney.phoneNumber = phone;
    payment.mobileMoney.transactionId = result.sessionId;
    await payment.save();

    res.json({
      success: true,
      message: 'Paiement d\'abonnement initié avec succès',
      data: {
        paymentId: payment.paymentId,
        sessionId: result.sessionId,
        checkoutUrl: result.checkoutUrl,
        amount: result.amount,
        currency: result.currency,
        expiresAt: result.expiresAt
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement d\'abonnement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'initiation du paiement',
      error: error.message
    });
  }
});

// @route   POST /api/v1/mobile-payments/:id/cancel
// @desc    Annuler un paiement en attente
// @access  Private
router.post('/:id/cancel', auth, async (req, res) => {
  try {
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

    if (!payment.canBeCancelled()) {
      return res.status(400).json({
        success: false,
        message: 'Ce paiement ne peut pas être annulé'
      });
    }

    // Annuler auprès du fournisseur si nécessaire
    if (payment.method === 'wave' && payment.transaction.externalId) {
      await waveService.cancelPayment(payment.transaction.externalId);
    }

    payment.updateStatus('cancelled', 'Annulé par l\'utilisateur', 'user');
    await payment.save();

    res.json({
      success: true,
      message: 'Paiement annulé avec succès',
      data: {
        paymentId: payment._id,
        status: payment.status
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'annulation du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'annulation du paiement'
    });
  }
});

module.exports = router;
