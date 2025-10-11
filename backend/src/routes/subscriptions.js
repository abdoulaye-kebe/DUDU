const express = require('express');
const { body, validationResult } = require('express-validator');
const Subscription = require('../models/Subscription');
const Payment = require('../models/Payment');
const Driver = require('../models/Driver');
const { auth, requireDriver } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/v1/subscriptions/plans
// @desc    Obtenir les plans d'abonnement disponibles
// @access  Public
router.get('/plans', (req, res) => {
  try {
    const plans = Subscription.getAvailablePlans();
    
    res.json({
      success: true,
      data: {
        plans: plans.map(plan => ({
          type: plan.type,
          name: plan.name,
          price: plan.price,
          currency: plan.currency,
          duration: plan.duration,
          features: plan.features,
          description: plan.description,
          savings: calculateSavings(plan)
        }))
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des plans:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   POST /api/v1/subscriptions/purchase
// @desc    Acheter un abonnement
// @access  Private (chauffeur)
router.post('/purchase', [
  auth,
  requireDriver,
  body('planType').isIn(['daily', 'weekly', 'monthly', 'yearly']).withMessage('Type de plan invalide'),
  body('paymentMethod').isIn(['orange_money', 'wave', 'free_money', 'cash']).withMessage('Méthode de paiement invalide'),
  body('phone').optional().matches(/^(\+221|221)?[0-9]{9}$/).withMessage('Format de téléphone invalide'),
  body('autoRenew').optional().isBoolean()
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

    const { planType, paymentMethod, phone, autoRenew = false } = req.body;

    // Vérifier si le chauffeur a déjà un abonnement actif
    const existingSubscription = await Subscription.findOne({
      driver: req.driver._id,
      status: 'active'
    });

    if (existingSubscription) {
      return res.status(400).json({
        success: false,
        message: 'Vous avez déjà un abonnement actif',
        data: {
          currentSubscription: existingSubscription.getSummary()
        }
      });
    }

    // Obtenir les détails du plan
    const plans = Subscription.getAvailablePlans();
    const plan = plans.find(p => p.type === planType);
    
    if (!plan) {
      return res.status(400).json({
        success: false,
        message: 'Plan d\'abonnement non trouvé'
      });
    }

    // Calculer les dates
    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + (plan.duration * 24 * 60 * 60 * 1000));

    // Créer l'abonnement
    const subscription = new Subscription({
      driver: req.driver._id,
      plan: {
        type: plan.type,
        name: plan.name,
        price: plan.price,
        currency: plan.currency,
        duration: plan.duration,
        features: plan.features
      },
      startDate,
      endDate,
      autoRenew
    });

    await subscription.save();

    // Créer le paiement
    const payment = new Payment({
      user: req.userId,
      driver: req.driver._id,
      type: 'subscription',
      amount: plan.price,
      currency: plan.currency,
      method: paymentMethod,
      status: 'pending',
      subscription: {
        plan: plan.type,
        duration: plan.duration,
        startDate,
        endDate
      }
    });

    // Ajouter les informations de paiement mobile money
    if (paymentMethod !== 'cash' && phone) {
      payment.mobileMoney = {
        phone,
        operator: paymentMethod.split('_')[0]
      };
    }

    await payment.save();

    // Lier l'abonnement au paiement
    subscription.payment = payment._id;
    await subscription.save();

    // Initier le paiement
    if (paymentMethod === 'cash') {
      payment.status = 'completed';
      payment.cash = {
        collectedBy: null,
        collectedAt: null,
        verified: false
      };
      await payment.save();

      // Activer l'abonnement
      subscription.activate();
      await subscription.save();

      // Mettre à jour le chauffeur
      const driver = await Driver.findById(req.driver._id);
      driver.subscription = {
        type: plan.type,
        startDate,
        endDate,
        isActive: true,
        autoRenew
      };
      await driver.save();

      res.json({
        success: true,
        message: 'Abonnement acheté avec succès',
        data: {
          subscription: subscription.getSummary(),
          payment: payment.getSummary()
        }
      });
    } else {
      // Initier le paiement mobile money
      payment.initiateMobileMoneyPayment(phone, paymentMethod.split('_')[0]);
      await payment.save();

      // TODO: Intégrer avec les APIs de paiement mobile money
      // Pour l'instant, on simule
      setTimeout(async () => {
        payment.confirmPayment(
          Math.random().toString(36).substr(2, 8),
          `TXN_${Date.now()}`
        );
        await payment.save();

        // Activer l'abonnement
        subscription.activate();
        await subscription.save();

        // Mettre à jour le chauffeur
        const driver = await Driver.findById(req.driver._id);
        driver.subscription = {
          type: plan.type,
          startDate,
          endDate,
          isActive: true,
          autoRenew
        };
        await driver.save();
      }, 5000);

      res.json({
        success: true,
        message: 'Paiement initié. Votre abonnement sera activé après confirmation.',
        data: {
          subscription: subscription.getSummary(),
          payment: payment.getSummary(),
          transactionCode: payment.mobileMoney.transactionCode
        }
      });
    }

  } catch (error) {
    console.error('Erreur lors de l\'achat de l\'abonnement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/subscriptions/current
// @desc    Obtenir l'abonnement actuel du chauffeur
// @access  Private (chauffeur)
router.get('/current', auth, requireDriver, async (req, res) => {
  try {
    const subscription = await Subscription.findOne({
      driver: req.driver._id,
      status: 'active'
    }).populate('payment', 'status amount method');

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Aucun abonnement actif trouvé'
      });
    }

    res.json({
      success: true,
      data: {
        subscription: {
          id: subscription._id,
          subscriptionId: subscription.subscriptionId,
          plan: subscription.plan,
          status: subscription.status,
          startDate: subscription.startDate,
          endDate: subscription.endDate,
          activatedAt: subscription.activatedAt,
          autoRenew: subscription.autoRenew,
          nextRenewalDate: subscription.nextRenewalDate,
          usage: subscription.usage,
          isActive: subscription.isActive(),
          isExpiringSoon: subscription.isExpiringSoon(),
          payment: subscription.payment ? {
            status: subscription.payment.status,
            amount: subscription.payment.amount,
            method: subscription.payment.method
          } : null
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération de l\'abonnement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/subscriptions/history
// @desc    Obtenir l'historique des abonnements
// @access  Private (chauffeur)
router.get('/history', auth, requireDriver, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const subscriptions = await Subscription.find({ driver: req.driver._id })
      .populate('payment', 'status amount method initiatedAt completedAt')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Subscription.countDocuments({ driver: req.driver._id });

    res.json({
      success: true,
      data: {
        subscriptions: subscriptions.map(sub => ({
          id: sub._id,
          subscriptionId: sub.subscriptionId,
          plan: sub.plan,
          status: sub.status,
          startDate: sub.startDate,
          endDate: sub.endDate,
          activatedAt: sub.activatedAt,
          expiredAt: sub.expiredAt,
          cancelledAt: sub.cancelledAt,
          autoRenew: sub.autoRenew,
          payment: sub.payment ? {
            status: sub.payment.status,
            amount: sub.payment.amount,
            method: sub.payment.method,
            initiatedAt: sub.payment.initiatedAt,
            completedAt: sub.payment.completedAt
          } : null,
          isActive: sub.isActive(),
          isExpiringSoon: sub.isExpiringSoon()
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalSubscriptions: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération de l\'historique:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/subscriptions/:id/cancel
// @desc    Annuler un abonnement
// @access  Private (chauffeur)
router.put('/:id/cancel', [
  auth,
  requireDriver,
  body('reason').optional().isString()
], async (req, res) => {
  try {
    const { reason = 'Demande du chauffeur' } = req.body;

    const subscription = await Subscription.findById(req.params.id);
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Abonnement non trouvé'
      });
    }

    if (subscription.driver.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    if (subscription.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Seuls les abonnements actifs peuvent être annulés'
      });
    }

    // Annuler l'abonnement
    subscription.cancel(reason);
    await subscription.save();

    // Mettre à jour le chauffeur
    const driver = await Driver.findById(req.driver._id);
    driver.subscription.isActive = false;
    driver.status = 'offline';
    driver.isAvailable = false;
    await driver.save();

    res.json({
      success: true,
      message: 'Abonnement annulé avec succès',
      data: {
        subscription: subscription.getSummary()
      }
    });

  } catch (error) {
    console.error('Erreur lors de l\'annulation de l\'abonnement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/subscriptions/:id/auto-renew
// @desc    Modifier le renouvellement automatique
// @access  Private (chauffeur)
router.put('/:id/auto-renew', [
  auth,
  requireDriver,
  body('autoRenew').isBoolean().withMessage('Valeur de renouvellement automatique requise')
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

    const { autoRenew } = req.body;

    const subscription = await Subscription.findById(req.params.id);
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Abonnement non trouvé'
      });
    }

    if (subscription.driver.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    subscription.autoRenew = autoRenew;
    if (autoRenew) {
      subscription.nextRenewalDate = subscription.endDate;
    } else {
      subscription.nextRenewalDate = undefined;
    }

    await subscription.save();

    // Mettre à jour le chauffeur
    const driver = await Driver.findById(req.driver._id);
    driver.subscription.autoRenew = autoRenew;
    await driver.save();

    res.json({
      success: true,
      message: `Renouvellement automatique ${autoRenew ? 'activé' : 'désactivé'}`,
      data: {
        subscription: subscription.getSummary()
      }
    });

  } catch (error) {
    console.error('Erreur lors de la modification du renouvellement automatique:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/subscriptions/expiring
// @desc    Obtenir les abonnements expirant bientôt
// @access  Private (chauffeur)
router.get('/expiring', auth, requireDriver, async (req, res) => {
  try {
    const { days = 3 } = req.query;

    const subscriptions = await Subscription.find({
      driver: req.driver._id,
      status: 'active',
      endDate: {
        $lte: new Date(Date.now() + days * 24 * 60 * 60 * 1000),
        $gt: new Date()
      }
    });

    res.json({
      success: true,
      data: {
        subscriptions: subscriptions.map(sub => ({
          id: sub._id,
          subscriptionId: sub.subscriptionId,
          plan: sub.plan,
          endDate: sub.endDate,
          isExpiringSoon: sub.isExpiringSoon(parseInt(days)),
          daysUntilExpiry: Math.ceil((sub.endDate - new Date()) / (1000 * 60 * 60 * 24))
        }))
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des abonnements expirants:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// Fonction utilitaire pour calculer les économies
function calculateSavings(plan) {
  const dailyPrice = 2000; // Prix journalier de référence
  const dailyCost = dailyPrice * plan.duration;
  const savings = dailyCost - plan.price;
  const percentage = Math.round((savings / dailyCost) * 100);
  
  return {
    amount: savings,
    percentage: percentage
  };
}

module.exports = router;



