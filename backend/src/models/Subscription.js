const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true
  },
  plan: {
    type: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly'],
      required: true
    },
    name: {
      type: String,
      required: true
    },
    price: {
      type: Number,
      required: true
    },
    currency: {
      type: String,
      default: 'XOF'
    },
    duration: {
      type: Number, // en jours
      required: true
    },
    features: [{
      type: String
    }]
  },
  vehicleType: {
    type: String,
    enum: ['car', 'moto'],
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
  activatedAt: {
    type: Date
  },
  expiredAt: {
    type: Date
  },
  cancelledAt: {
    type: Date
  },
  autoRenew: {
    type: Boolean,
    default: false
  },
  nextRenewalDate: {
    type: Date
  },
  payment: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Payment'
  },
  usage: {
    ridesCompleted: {
      type: Number,
      default: 0
    },
    totalEarnings: {
      type: Number,
      default: 0
    },
    bonusEarned: {
      type: Number,
      default: 0
    }
  },
  // Bonus spécifiques aux livreurs moto
  weeklyBonus: {
    type: {
      type: String,
      enum: ['free_subscription', 'cash_bonus', 'none'],
      default: 'none'
    },
    amount: {
      type: Number,
      default: 0
    },
    lastBonusDate: {
      type: Date
    },
    bonusHistory: [{
      type: {
        type: String,
        enum: ['free_subscription', 'cash_bonus']
      },
      amount: Number,
      date: Date,
      description: String
    }]
  },
  // Restrictions pour livreurs moto
  restrictions: {
    maxDailyRides: {
      type: Number,
      default: 20 // Limite pour moto
    },
    allowedPlans: [{
      type: String,
      enum: ['daily'] // Seul le journalier pour moto
    }]
  }
}, {
  timestamps: true
});

// Index
subscriptionSchema.index({ driver: 1, status: 1 });
subscriptionSchema.index({ endDate: 1 });
subscriptionSchema.index({ vehicleType: 1 });

// Méthodes statiques pour obtenir les plans disponibles
subscriptionSchema.statics.getAvailablePlans = function() {
  return [
    // Plans pour chauffeurs voiture (tous les plans)
    {
      type: 'daily',
      name: 'Forfait Journalier',
      price: 2000,
      currency: 'XOF',
      duration: 1,
      features: ['Courses illimitées', 'Support 24/7', 'Statistiques de base'],
      vehicleTypes: ['car', 'moto']
    },
    {
      type: 'weekly',
      name: 'Forfait Hebdomadaire',
      price: 12000,
      currency: 'XOF',
      duration: 7,
      features: ['Courses illimitées', 'Support prioritaire', 'Statistiques avancées', 'Réduction 15%'],
      vehicleTypes: ['car'] // Seulement pour voiture
    },
    {
      type: 'monthly',
      name: 'Forfait Mensuel',
      price: 45000,
      currency: 'XOF',
      duration: 30,
      features: ['Courses illimitées', 'Support prioritaire', 'Statistiques avancées', 'Réduction 25%', 'Formation gratuite'],
      vehicleTypes: ['car'] // Seulement pour voiture
    },
    {
      type: 'yearly',
      name: 'Forfait Annuel',
      price: 450000,
      currency: 'XOF',
      duration: 365,
      features: ['Courses illimitées', 'Support prioritaire', 'Statistiques avancées', 'Réduction 40%', 'Formation gratuite', 'Assurance incluse'],
      vehicleTypes: ['car'] // Seulement pour voiture
    }
  ];
};

// Méthodes d'instance
subscriptionSchema.methods.isActive = function() {
  return this.status === 'active' && this.endDate > new Date();
};

subscriptionSchema.methods.isExpiringSoon = function(days = 3) {
  const now = new Date();
  const expiryDate = new Date(this.endDate.getTime() - (days * 24 * 60 * 60 * 1000));
  return this.status === 'active' && now >= expiryDate && this.endDate > now;
};

subscriptionSchema.methods.activate = function() {
  this.status = 'active';
  this.activatedAt = new Date();
  return this.save();
};

subscriptionSchema.methods.cancel = function(reason = 'Demande du chauffeur') {
  this.status = 'cancelled';
  this.cancelledAt = new Date();
  return this.save();
};

subscriptionSchema.methods.extend = function(days) {
  this.endDate = new Date(this.endDate.getTime() + (days * 24 * 60 * 60 * 1000));
  return this.save();
};

subscriptionSchema.methods.addBonus = function(type, amount, description) {
  if (this.vehicleType !== 'moto') {
    throw new Error('Les bonus sont uniquement pour les livreurs moto');
  }

  this.weeklyBonus.bonusHistory.push({
    type,
    amount,
    date: new Date(),
    description
  });

  this.weeklyBonus.lastBonusDate = new Date();
  this.usage.bonusEarned += amount;

  return this.save();
};

subscriptionSchema.methods.getSummary = function() {
  return {
    id: this._id,
    subscriptionId: this._id.toString().substr(-8).toUpperCase(),
    plan: this.plan,
    vehicleType: this.vehicleType,
    status: this.status,
    startDate: this.startDate,
    endDate: this.endDate,
    isActive: this.isActive(),
    isExpiringSoon: this.isExpiringSoon(),
    usage: this.usage,
    weeklyBonus: this.weeklyBonus,
    restrictions: this.restrictions
  };
};

// Middleware pour vérifier l'expiration avant de sauvegarder
subscriptionSchema.pre('save', function(next) {
  if (this.isModified('endDate') && this.endDate <= new Date() && this.status === 'active') {
    this.status = 'expired';
    this.expiredAt = new Date();
  }
  next();
});

module.exports = mongoose.model('Subscription', subscriptionSchema);



