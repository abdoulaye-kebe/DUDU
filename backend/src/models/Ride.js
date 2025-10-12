const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema({
  // Informations de base
  rideId: {
    type: String,
    unique: true,
    required: true
  },
  
  // Participants
  passenger: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true
  },
  
  // Itinéraire
  pickup: {
    address: {
      type: String,
      required: [true, 'L\'adresse de prise en charge est requise']
    },
    coordinates: {
      latitude: {
        type: Number,
        required: true
      },
      longitude: {
        type: Number,
        required: true
      }
    },
    instructions: String,
    landmark: String
  },
  
  destination: {
    address: {
      type: String,
      required: [true, 'L\'adresse de destination est requise']
    },
    coordinates: {
      latitude: {
        type: Number,
        required: true
      },
      longitude: {
        type: Number,
        required: true
      }
    },
    instructions: String,
    landmark: String
  },
  
  // Informations de la course
  distance: {
    type: Number, // en kilomètres
    required: true
  },
  estimatedDuration: {
    type: Number, // en minutes
    required: true
  },
  actualDuration: Number, // en minutes
  
  // Tarification
  pricing: {
    basePrice: {
      type: Number,
      required: true
    },
    distancePrice: {
      type: Number,
      required: true
    },
    timePrice: {
      type: Number,
      required: true
    },
    surgeMultiplier: {
      type: Number,
      default: 1.0
    },
    totalPrice: {
      type: Number,
      required: true
    },
    currency: {
      type: String,
      default: 'XOF'
    },
    isPriceFixed: {
      type: Boolean,
      default: false
    }
  },
  
  // Statut de la course
  status: {
    type: String,
    enum: [
      'requested',      // Demande envoyée
      'searching',      // Recherche de chauffeur
      'accepted',       // Chauffeur accepté
      'arriving',       // Chauffeur en route
      'arrived',        // Chauffeur arrivé
      'started',        // Course commencée
      'completed',      // Course terminée
      'cancelled',      // Course annulée
      'no_driver',      // Aucun chauffeur trouvé
      'expired'         // Demande expirée
    ],
    default: 'requested'
  },
  
  // Type de course
  rideType: {
    type: String,
    enum: ['standard', 'express', 'shared', 'premium', 'women_only', 'delivery'],
    default: 'standard'
  },
  
  // Informations de livraison (si rideType = 'delivery')
  delivery: {
    packageType: {
      type: String,
      enum: ['document', 'small_package', 'medium_package', 'large_package', 'food', 'fragile']
    },
    weight: Number, // en kg
    dimensions: {
      length: Number, // cm
      width: Number,  // cm
      height: Number  // cm
    },
    description: String,
    recipientName: String,
    recipientPhone: String,
    instructions: String,
    pickupContact: String,
    pickupContactPhone: String,
    deliveryPhotos: {
      beforePickup: String,  // URL photo avant récupération
      afterPickup: String,   // URL photo après récupération
      beforeDelivery: String, // URL photo avant livraison
      afterDelivery: String   // URL photo après livraison
    },
    confirmationCode: String, // Code de confirmation pour la remise
    isFragile: {
      type: Boolean,
      default: false
    },
    requiresSignature: {
      type: Boolean,
      default: false
    }
  },
  
  // Horaires
  scheduledFor: Date, // Pour les courses programmées
  requestedAt: {
    type: Date,
    default: Date.now
  },
  acceptedAt: Date,
  arrivedAt: Date,
  startedAt: Date,
  completedAt: Date,
  cancelledAt: Date,
  
  // Informations de paiement
  payment: {
    method: {
      type: String,
      enum: ['orange_money', 'wave', 'free_money', 'cash'],
      required: true
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed', 'refunded'],
      default: 'pending'
    },
    transactionId: String,
    paidAt: Date,
    refundedAt: Date,
    refundAmount: Number
  },
  
  // Évaluations
  rating: {
    passenger: {
      rating: {
        type: Number,
        min: 1,
        max: 5
      },
      comment: String,
      ratedAt: Date
    },
    driver: {
      rating: {
        type: Number,
        min: 1,
        max: 5
      },
      comment: String,
      ratedAt: Date
    }
  },
  
  // Informations supplémentaires
  passengers: {
    type: Number,
    default: 1,
    min: 1,
    max: 8
  },
  luggage: {
    type: Boolean,
    default: false
  },
  specialRequests: [String],
  
  // Mode spécial
  specialMode: {
    type: String,
    enum: ['ceremony', 'student', 'elderly', 'medical', 'emergency']
  },
  
  // Partage de course
  isShared: {
    type: Boolean,
    default: false
  },
  sharedWith: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  sharedPrice: Number,
  
  // Géolocalisation en temps réel
  tracking: [{
    latitude: Number,
    longitude: Number,
    timestamp: {
      type: Date,
      default: Date.now
    },
    speed: Number, // km/h
    heading: Number // degrés
  }],
  
  // Notifications
  notifications: {
    sent: [{
      type: String,
      enum: ['request_sent', 'driver_found', 'driver_arriving', 'driver_arrived', 'ride_started', 'ride_completed', 'payment_received']
    }],
    lastSent: Date
  },
  
  // Annulation
  cancellation: {
    reason: {
      type: String,
      enum: ['passenger_cancelled', 'driver_cancelled', 'no_driver_found', 'payment_failed', 'system_error', 'weather', 'emergency']
    },
    cancelledBy: {
      type: String,
      enum: ['passenger', 'driver', 'system']
    },
    refundAmount: Number,
    refundProcessed: {
      type: Boolean,
      default: false
    }
  },
  
  // Données de performance
  performance: {
    searchTime: Number, // temps de recherche en secondes
    waitTime: Number,   // temps d'attente en minutes
    responseTime: Number // temps de réponse du chauffeur en secondes
  }
}, {
  timestamps: true
});

// Index pour les recherches
rideSchema.index({ rideId: 1 });
rideSchema.index({ passenger: 1, status: 1 });
rideSchema.index({ driver: 1, status: 1 });
rideSchema.index({ status: 1, requestedAt: 1 });
rideSchema.index({ 'pickup.coordinates': '2dsphere' });
rideSchema.index({ 'destination.coordinates': '2dsphere' });

// Méthode pour générer un ID de course unique
rideSchema.statics.generateRideId = function() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 5);
  return `DUDU${timestamp}${random}`.toUpperCase();
};

// Méthode pour calculer le prix total
rideSchema.methods.calculateTotalPrice = function() {
  const { basePrice, distancePrice, timePrice, surgeMultiplier } = this.pricing;
  const total = (basePrice + distancePrice + timePrice) * surgeMultiplier;
  this.pricing.totalPrice = Math.round(total);
  return this.pricing.totalPrice;
};

// Méthode pour mettre à jour le statut
rideSchema.methods.updateStatus = function(newStatus, additionalData = {}) {
  const statusHistory = this.statusHistory || [];
  statusHistory.push({
    from: this.status,
    to: newStatus,
    timestamp: new Date(),
    ...additionalData
  });
  
  this.status = newStatus;
  this.statusHistory = statusHistory;
  
  // Mettre à jour les horaires selon le statut
  switch (newStatus) {
    case 'accepted':
      this.acceptedAt = new Date();
      break;
    case 'arrived':
      this.arrivedAt = new Date();
      break;
    case 'started':
      this.startedAt = new Date();
      break;
    case 'completed':
      this.completedAt = new Date();
      break;
    case 'cancelled':
      this.cancelledAt = new Date();
      break;
  }
};

// Méthode pour ajouter un point de suivi
rideSchema.methods.addTrackingPoint = function(latitude, longitude, speed = 0, heading = 0) {
  this.tracking.push({
    latitude,
    longitude,
    speed,
    heading,
    timestamp: new Date()
  });
  
  // Garder seulement les 1000 derniers points
  if (this.tracking.length > 1000) {
    this.tracking = this.tracking.slice(-1000);
  }
};

// Méthode pour calculer la distance parcourue
rideSchema.methods.calculateDistanceTraveled = function() {
  if (this.tracking.length < 2) return 0;
  
  let totalDistance = 0;
  for (let i = 1; i < this.tracking.length; i++) {
    const prev = this.tracking[i - 1];
    const curr = this.tracking[i];
    
    const R = 6371; // Rayon de la Terre en km
    const dLat = (curr.latitude - prev.latitude) * Math.PI / 180;
    const dLon = (curr.longitude - prev.longitude) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(prev.latitude * Math.PI / 180) * Math.cos(curr.latitude * Math.PI / 180) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    totalDistance += R * c;
  }
  
  return totalDistance;
};

// Méthode pour vérifier si la course peut être annulée
rideSchema.methods.canBeCancelled = function() {
  const cancellableStatuses = ['requested', 'searching', 'accepted', 'arriving'];
  return cancellableStatuses.includes(this.status);
};

// Méthode pour obtenir le temps d'attente
rideSchema.methods.getWaitTime = function() {
  if (!this.acceptedAt) return null;
  
  const startTime = this.arrivedAt || this.startedAt;
  if (!startTime) return null;
  
  return Math.round((startTime - this.acceptedAt) / (1000 * 60)); // en minutes
};

// Middleware pour générer l'ID de course
rideSchema.pre('save', function(next) {
  if (!this.rideId) {
    this.rideId = this.constructor.generateRideId();
  }
  next();
});

module.exports = mongoose.model('Ride', rideSchema);
