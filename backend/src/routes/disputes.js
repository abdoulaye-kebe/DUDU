const express = require('express');
const { body, validationResult } = require('express-validator');
const Ride = require('../models/Ride');
const { auth, requireDriver } = require('../middleware/auth');
const router = express.Router();

// Middleware pour vérifier les droits d'administration
const requireAdmin = (req, res, next) => {
  // TODO: Implémenter un système de rôles d'administration
  next();
};

// @route   POST /api/v1/disputes/report
// @desc    Signaler un litige sur une course
// @access  Private (passager ou chauffeur)
router.post('/report', [
  auth,
  body('rideId').notEmpty().withMessage('L\'ID de la course est requis'),
  body('reason').notEmpty().withMessage('La raison du litige est requise'),
  body('description').notEmpty().withMessage('Une description est requise')
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

    const { rideId, reason, description } = req.body;

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Course non trouvée'
      });
    }

    // Vérifier que l'utilisateur est impliqué dans cette course
    const isPassenger = ride.passenger.toString() === req.userId?.toString();
    const isDriver = ride.driver && ride.driver.toString() === req.driver?._id.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas autorisé à signaler un litige sur cette course'
      });
    }

    // Vérifier qu'il n'y a pas déjà un litige
    if (ride.dispute && ride.dispute.isDisputed) {
      return res.status(400).json({
        success: false,
        message: 'Un litige a déjà été signalé pour cette course'
      });
    }

    // Créer le litige
    ride.dispute = {
      isDisputed: true,
      reportedBy: isPassenger ? 'passenger' : 'driver',
      reason,
      description,
      status: 'pending',
      reportedAt: new Date()
    };
    await ride.save();

    // Notifier l'admin via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.emit('new-dispute', {
        rideId: ride._id,
        reportedBy: ride.dispute.reportedBy,
        reason,
        description
      });
    }

    res.status(201).json({
      success: true,
      message: 'Litige signalé avec succès. Notre équipe va examiner votre demande.',
      data: {
        rideId: ride._id,
        disputeStatus: ride.dispute.status
      }
    });

  } catch (error) {
    console.error('Erreur lors du signalement du litige:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/disputes
// @desc    Obtenir la liste des litiges (admin)
// @access  Private (admin)
router.get('/', [auth, requireAdmin], async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const filter = { 'dispute.isDisputed': true };
    if (status) {
      filter['dispute.status'] = status;
    }

    const disputes = await Ride.find(filter)
      .populate('passenger', 'firstName lastName phone email')
      .populate('driver', 'firstName lastName phone')
      .sort({ 'dispute.reportedAt': -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Ride.countDocuments(filter);

    res.json({
      success: true,
      data: {
        disputes: disputes.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          passenger: ride.passenger ? {
            id: ride.passenger._id,
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone,
            email: ride.passenger.email
          } : null,
          driver: ride.driver ? {
            id: ride.driver._id,
            name: `${ride.driver.firstName} ${ride.driver.lastName}`,
            phone: ride.driver.phone
          } : null,
          dispute: ride.dispute,
          pricing: ride.pricing,
          status: ride.status,
          completedAt: ride.completedAt,
          cancelledAt: ride.cancelledAt
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalDisputes: total,
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des litiges:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   PUT /api/v1/disputes/:id/resolve
// @desc    Résoudre un litige (admin)
// @access  Private (admin)
router.put('/:id/resolve', [
  auth,
  requireAdmin,
  body('resolution').notEmpty().withMessage('La résolution est requise'),
  body('adminNotes').optional().isString()
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

    const { resolution, adminNotes } = req.body;

    const ride = await Ride.findById(req.params.id);
    if (!ride || !ride.dispute || !ride.dispute.isDisputed) {
      return res.status(404).json({
        success: false,
        message: 'Litige non trouvé'
      });
    }

    ride.dispute.status = 'resolved';
    ride.dispute.resolution = resolution;
    ride.dispute.adminNotes = adminNotes || '';
    ride.dispute.resolvedAt = new Date();
    await ride.save();

    // Notifier les parties concernées
    const io = req.app.get('io');
    if (io) {
      io.to(`passenger_${ride.passenger}`).emit('dispute-resolved', {
        rideId: ride._id,
        resolution
      });
      
      if (ride.driver) {
        io.to(`driver_${ride.driver}`).emit('dispute-resolved', {
          rideId: ride._id,
          resolution
        });
      }
    }

    res.json({
      success: true,
      message: 'Litige résolu avec succès',
      data: {
        rideId: ride._id,
        dispute: ride.dispute
      }
    });

  } catch (error) {
    console.error('Erreur lors de la résolution du litige:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// @route   GET /api/v1/disputes/my-disputes
// @desc    Obtenir les litiges de l'utilisateur connecté
// @access  Private
router.get('/my-disputes', auth, async (req, res) => {
  try {
    const filter = {
      'dispute.isDisputed': true,
      $or: [
        { passenger: req.userId },
        { driver: req.driver?._id }
      ]
    };

    const disputes = await Ride.find(filter)
      .populate('passenger', 'firstName lastName')
      .populate('driver', 'firstName lastName')
      .sort({ 'dispute.reportedAt': -1 });

    res.json({
      success: true,
      data: {
        disputes: disputes.map(ride => ({
          id: ride._id,
          rideId: ride.rideId,
          dispute: ride.dispute,
          pricing: ride.pricing,
          status: ride.status,
          completedAt: ride.completedAt
        }))
      }
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des litiges:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;
