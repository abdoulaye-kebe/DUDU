const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  // Informations de base
  paymentId: {
    type: String,
    unique: true,
    required: true
  },
  
  // Participants
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver'
  },
  ride: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride'
  },
  
  // Type de paiement
  type: {
    type: String,
    enum: ['ride_payment', 'subscription', 'refund', 'bonus', 'penalty'],
    required: true
  },
  
  // Montant
  amount: {
    type: Number,
    required: [true, 'Le montant est requis'],
    min: [0, 'Le montant ne peut pas être négatif']
  },
  currency: {
    type: String,
    default: 'XOF',
    enum: ['XOF', 'EUR', 'USD']
  },
  
  // Méthode de paiement
  method: {
    type: String,
    enum: ['orange_money', 'wave', 'free_money', 'cash', 'bank_transfer'],
    required: true
  },
  
  // Statut du paiement
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'],
    default: 'pending'
  },
  
  // Informations de transaction
  transaction: {
    externalId: String, // ID de la transaction externe
    reference: String,   // Référence de paiement
    provider: String,    // Fournisseur (Orange, Wave, etc.)
    fees: {
      type: Number,
      default: 0
    },
    netAmount: Number,   // Montant net après frais
    processedAt: Date,
    failureReason: String
  },
  
  // Détails du paiement mobile money
  mobileMoney: {
    phone: String,
    operator: {
      type: String,
      enum: ['orange', 'wave', 'free']
    },
    transactionCode: String,
    confirmationCode: String
  },
  
  // Informations bancaires (pour les virements)
  bankTransfer: {
    bankName: String,
    accountNumber: String,
    reference: String,
    processedAt: Date
  },
  
  // Paiement en espèces
  cash: {
    collectedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Driver'
    },
    collectedAt: Date,
    verified: {
      type: Boolean,
      default: false
    }
  },
  
  // Détails de l'abonnement (si applicable)
  subscription: {
    plan: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly']
    },
    duration: Number, // en jours
    startDate: Date,
    endDate: Date
  },
  
  // Remboursement
  refund: {
    originalPayment: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Payment'
    },
    reason: {
      type: String,
      enum: ['cancelled_ride', 'driver_cancelled', 'system_error', 'dispute', 'refund_request']
    },
    refundedAt: Date,
    refundMethod: String
  },
  
  // Frais et commissions
  fees: {
    platformFee: {
      type: Number,
      default: 0
    },
    processingFee: {
      type: Number,
      default: 0
    },
    totalFees: {
      type: Number,
      default: 0
    }
  },
  
  // Métadonnées
  metadata: {
    ipAddress: String,
    userAgent: String,
    deviceInfo: String,
    location: {
      latitude: Number,
      longitude: Number,
      address: String
    }
  },
  
  // Notifications
  notifications: {
    sent: [{
      type: String,
      enum: ['payment_initiated', 'payment_completed', 'payment_failed', 'refund_processed']
    }],
    lastSent: Date
  },
  
  // Historique des statuts
  statusHistory: [{
    status: String,
    timestamp: {
      type: Date,
      default: Date.now
    },
    reason: String,
    updatedBy: {
      type: String,
      enum: ['user', 'driver', 'system', 'admin']
    }
  }],
  
  // Dates importantes
  initiatedAt: {
    type: Date,
    default: Date.now
  },
  completedAt: Date,
  failedAt: Date,
  cancelledAt: Date,
  
  // Validation
  isVerified: {
    type: Boolean,
    default: false
  },
  verifiedAt: Date,
  verifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Index pour les recherches
paymentSchema.index({ user: 1, status: 1 });
paymentSchema.index({ driver: 1, status: 1 });
paymentSchema.index({ ride: 1 });
paymentSchema.index({ status: 1, initiatedAt: 1 });
paymentSchema.index({ 'transaction.externalId': 1 });

// Méthode pour générer un ID de paiement unique
paymentSchema.statics.generatePaymentId = function() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 6);
  return `PAY${timestamp}${random}`.toUpperCase();
};

// Méthode pour calculer les frais
paymentSchema.methods.calculateFees = function() {
  let platformFee = 0;
  let processingFee = 0;
  
  // Frais de plateforme (0% pour DUDU - avantage concurrentiel)
  platformFee = 0;
  
  // Frais de traitement selon la méthode
  switch (this.method) {
    case 'orange_money':
      processingFee = Math.round(this.amount * 0.01); // 1%
      break;
    case 'wave':
      processingFee = Math.round(this.amount * 0.015); // 1.5%
      break;
    case 'free_money':
      processingFee = Math.round(this.amount * 0.01); // 1%
      break;
    case 'cash':
      processingFee = 0;
      break;
    case 'bank_transfer':
      processingFee = 500; // Frais fixes
      break;
  }
  
  this.fees.platformFee = platformFee;
  this.fees.processingFee = processingFee;
  this.fees.totalFees = platformFee + processingFee;
  this.transaction.netAmount = this.amount - this.fees.totalFees;
  
  return this.fees;
};

// Méthode pour mettre à jour le statut
paymentSchema.methods.updateStatus = function(newStatus, reason = '', updatedBy = 'system') {
  this.statusHistory.push({
    status: newStatus,
    reason,
    updatedBy,
    timestamp: new Date()
  });
  
  const oldStatus = this.status;
  this.status = newStatus;
  
  // Mettre à jour les dates selon le statut
  switch (newStatus) {
    case 'completed':
      this.completedAt = new Date();
      this.isVerified = true;
      this.verifiedAt = new Date();
      break;
    case 'failed':
      this.failedAt = new Date();
      this.transaction.failureReason = reason;
      break;
    case 'cancelled':
      this.cancelledAt = new Date();
      break;
  }
  
  return { oldStatus, newStatus };
};

// Méthode pour initier un paiement mobile money
paymentSchema.methods.initiateMobileMoneyPayment = function(phone, operator) {
  this.mobileMoney = {
    phone,
    operator,
    transactionCode: this.generateTransactionCode()
  };
  
  this.status = 'processing';
  this.updateStatus('processing', 'Paiement mobile money initié', 'system');
};

// Méthode pour générer un code de transaction
paymentSchema.methods.generateTransactionCode = function() {
  return Math.random().toString(36).substr(2, 8).toUpperCase();
};

// Méthode pour confirmer un paiement
paymentSchema.methods.confirmPayment = function(confirmationCode, externalId) {
  this.transaction.externalId = externalId;
  this.transaction.confirmationCode = confirmationCode;
  this.transaction.processedAt = new Date();
  this.mobileMoney.confirmationCode = confirmationCode;
  
  this.updateStatus('completed', 'Paiement confirmé', 'system');
};

// Méthode pour traiter un remboursement
paymentSchema.methods.processRefund = function(reason, refundMethod = 'original') {
  this.refund = {
    reason,
    refundedAt: new Date(),
    refundMethod
  };
  
  this.updateStatus('refunded', `Remboursement: ${reason}`, 'system');
};

// Méthode pour vérifier si le paiement peut être annulé
paymentSchema.methods.canBeCancelled = function() {
  return ['pending', 'processing'].includes(this.status);
};

// Méthode pour obtenir le résumé du paiement
paymentSchema.methods.getSummary = function() {
  return {
    paymentId: this.paymentId,
    amount: this.amount,
    currency: this.currency,
    method: this.method,
    status: this.status,
    netAmount: this.transaction.netAmount,
    fees: this.fees,
    initiatedAt: this.initiatedAt,
    completedAt: this.completedAt
  };
};

// Middleware pour générer l'ID de paiement
paymentSchema.pre('save', function(next) {
  if (!this.paymentId) {
    this.paymentId = this.constructor.generatePaymentId();
  }
  
  // Calculer les frais si pas déjà fait
  if (this.isNew && this.amount > 0) {
    this.calculateFees();
  }
  
  next();
});

module.exports = mongoose.model('Payment', paymentSchema);

