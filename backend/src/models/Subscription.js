const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true
  },
  plan: {
    type: String,
    enum: ['basic', 'premium', 'pro'],
    required: true
  },
  status: {
    type: String,
    enum: ['active', 'expired', 'cancelled', 'pending'],
    default: 'pending'
  },
  startDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  endDate: {
    type: Date,
    required: true
  },
  autoRenew: {
    type: Boolean,
    default: true
  },
  paymentMethod: {
    type: String,
    enum: ['orange_money', 'wave', 'free_money', 'bank_transfer'],
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    enum: ['XOF', 'EUR', 'USD'],
    default: 'XOF'
  },
  features: {
    maxRidesPerDay: {
      type: Number,
      default: 50
    },
    prioritySupport: {
      type: Boolean,
      default: false
    },
    advancedAnalytics: {
      type: Boolean,
      default: false
    },
    customBranding: {
      type: Boolean,
      default: false
    }
  },
  paymentHistory: [{
    amount: Number,
    date: Date,
    method: String,
    transactionId: String,
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed']
    }
  }]
}, {
  timestamps: true
});

// Index
subscriptionSchema.index({ driver: 1, status: 1 });
subscriptionSchema.index({ endDate: 1 });

// Méthodes
subscriptionSchema.methods.isActive = function() {
  return this.status === 'active' && this.endDate > new Date();
};

subscriptionSchema.methods.isExpired = function() {
  return this.endDate <= new Date();
};

subscriptionSchema.methods.daysRemaining = function() {
  const now = new Date();
  const diffTime = this.endDate - now;
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};

subscriptionSchema.methods.extend = function(days) {
  this.endDate = new Date(this.endDate.getTime() + (days * 24 * 60 * 60 * 1000));
  return this.save();
};

// Middleware pour vérifier l'expiration avant de sauvegarder
subscriptionSchema.pre('save', function(next) {
  if (this.isModified('endDate') && this.endDate <= new Date()) {
    this.status = 'expired';
  }
  next();
});

module.exports = mongoose.model('Subscription', subscriptionSchema);


