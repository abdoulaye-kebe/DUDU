const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const driverSchema = new mongoose.Schema({
  // Informations de base (héritées de User)
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  
  // Informations professionnelles
  driverLicense: {
    number: {
      type: String,
      required: [true, 'Le numéro de permis est requis'],
      unique: true
    },
    expiryDate: {
      type: Date,
      required: [true, 'La date d\'expiration du permis est requise']
    },
    issueDate: Date,
    category: {
      type: String,
      enum: ['A', 'B', 'C', 'D'],
      default: 'B'
    }
  },
  
  // Informations du véhicule
  vehicle: {
    make: {
      type: String,
      required: [true, 'La marque du véhicule est requise']
    },
    model: {
      type: String,
      required: [true, 'Le modèle du véhicule est requis']
    },
    year: {
      type: Number,
      required: [true, 'L\'année du véhicule est requise'],
      min: [1990, 'L\'année doit être supérieure à 1990'],
      max: [new Date().getFullYear() + 1, 'L\'année ne peut pas être dans le futur']
    },
    color: {
      type: String,
      required: [true, 'La couleur du véhicule est requise']
    },
    plateNumber: {
      type: String,
      required: [true, 'Le numéro de plaque est requis'],
      unique: true,
      uppercase: true
    },
    type: {
      type: String,
      enum: ['taxi', 'uber', 'private'],
      default: 'taxi'
    },
    capacity: {
      type: Number,
      default: 4,
      min: 1,
      max: 8
    },
    features: [{
      type: String,
      enum: ['ac', 'wifi', 'charging', 'child_seat', 'wheelchair_access']
    }],
    photos: [String] // URLs des photos du véhicule
  },
  
  // Statut et disponibilité
  status: {
    type: String,
    enum: ['offline', 'online', 'busy', 'unavailable'],
    default: 'offline'
  },
  isAvailable: {
    type: Boolean,
    default: false
  },
  currentLocation: {
    latitude: Number,
    longitude: Number,
    address: String,
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  },
  
  // Zone de travail
  workingZones: [{
    name: String,
    coordinates: {
      center: {
        latitude: Number,
        longitude: Number
      },
      radius: Number // en kilomètres
    }
  }],
  
  // Forfait et abonnement
  subscription: {
    type: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly'],
      required: true
    },
    startDate: {
      type: Date,
      required: true
    },
    endDate: {
      type: Date,
      required: true
    },
    isActive: {
      type: Boolean,
      default: true
    },
    autoRenew: {
      type: Boolean,
      default: false
    }
  },
  
  // Informations financières
  earnings: {
    today: {
      type: Number,
      default: 0
    },
    thisWeek: {
      type: Number,
      default: 0
    },
    thisMonth: {
      type: Number,
      default: 0
    },
    total: {
      type: Number,
      default: 0
    }
  },
  
  // Statistiques
  stats: {
    totalRides: {
      type: Number,
      default: 0
    },
    completedRides: {
      type: Number,
      default: 0
    },
    cancelledRides: {
      type: Number,
      default: 0
    },
    averageRating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    totalRatingCount: {
      type: Number,
      default: 0
    },
    totalDistance: {
      type: Number,
      default: 0 // en kilomètres
    },
    totalEarnings: {
      type: Number,
      default: 0
    }
  },
  
  // Préférences de travail
  preferences: {
    maxDistance: {
      type: Number,
      default: 20 // kilomètres
    },
    minPrice: {
      type: Number,
      default: 500 // FCFA
    },
    workingHours: {
      start: String, // format "HH:MM"
      end: String,   // format "HH:MM"
      days: [{
        type: String,
        enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
      }]
    },
    acceptSharedRides: {
      type: Boolean,
      default: true
    },
    acceptExpressRides: {
      type: Boolean,
      default: true
    }
  },
  
  // Documents et vérifications
  documents: {
    driverLicensePhoto: String,
    vehicleRegistration: String,
    insurance: String,
    technicalInspection: String,
    criminalRecord: String
  },
  
  // Vérifications
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  verificationNotes: String,
  
  // Mode spécial
  specialModes: [{
    type: String,
    enum: ['women_only', 'elderly_friendly', 'student_discount', 'ceremony_mode']
  }],
  
  // Historique des positions
  locationHistory: [{
    latitude: Number,
    longitude: Number,
    timestamp: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Notifications
  notifications: {
    newRideRequest: {
      type: Boolean,
      default: true
    },
    rideUpdates: {
      type: Boolean,
      default: true
    },
    earnings: {
      type: Boolean,
      default: true
    },
    subscription: {
      type: Boolean,
      default: true
    }
  }
}, {
  timestamps: true
});

// Index pour les recherches géospatiales
driverSchema.index({ 'currentLocation': '2dsphere' });
driverSchema.index({ status: 1, isAvailable: 1 });
driverSchema.index({ 'subscription.isActive': 1 });
driverSchema.index({ 'vehicle.plateNumber': 1 });

// Méthode pour mettre à jour la localisation
driverSchema.methods.updateLocation = function(latitude, longitude, address) {
  this.currentLocation = {
    latitude,
    longitude,
    address,
    lastUpdated: new Date()
  };
  
  // Garder seulement les 100 dernières positions
  this.locationHistory.push({
    latitude,
    longitude,
    timestamp: new Date()
  });
  
  if (this.locationHistory.length > 100) {
    this.locationHistory = this.locationHistory.slice(-100);
  }
};

// Méthode pour calculer la distance avec un point
driverSchema.methods.calculateDistance = function(latitude, longitude) {
  const R = 6371; // Rayon de la Terre en km
  const dLat = (latitude - this.currentLocation.latitude) * Math.PI / 180;
  const dLon = (longitude - this.currentLocation.longitude) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(this.currentLocation.latitude * Math.PI / 180) * Math.cos(latitude * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

// Méthode pour vérifier si le chauffeur est dans sa zone de travail
driverSchema.methods.isInWorkingZone = function() {
  if (!this.workingZones.length) return true;
  
  return this.workingZones.some(zone => {
    const distance = this.calculateDistance(
      zone.coordinates.center.latitude,
      zone.coordinates.center.longitude
    );
    return distance <= zone.coordinates.radius;
  });
};

// Méthode pour obtenir les statistiques du jour
driverSchema.methods.getTodayStats = function() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  return {
    earnings: this.earnings.today,
    rides: this.stats.totalRides,
    rating: this.stats.averageRating,
    onlineTime: this.isAvailable ? 'En ligne' : 'Hors ligne'
  };
};

// Méthode pour vérifier si l'abonnement est valide
driverSchema.methods.isSubscriptionValid = function() {
  return this.subscription.isActive && 
         this.subscription.endDate > new Date();
};

// Middleware pour mettre à jour les statistiques
driverSchema.pre('save', function(next) {
  if (this.isModified('stats.totalRides')) {
    this.stats.completedRides = this.stats.totalRides - this.stats.cancelledRides;
  }
  next();
});

module.exports = mongoose.model('Driver', driverSchema);

