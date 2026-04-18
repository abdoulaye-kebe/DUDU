const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const driverSchema = new mongoose.Schema({
  // Informations de base (héritées de User)
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false, // Optionnel car l'admin peut créer des chauffeurs directement
    unique: true,
    sparse: true // Permet des valeurs null multiples
  },

  fcmToken: {
    type: String,
    default: null
  },

  deviceInfo: {
    platform: {
      type: String,
      default: 'mobile'
    }
  },
  
  // Mot de passe pour connexion directe
  password: {
    type: String,
    required: [true, 'Le mot de passe est requis'],
    minlength: [4, 'Le mot de passe doit contenir au moins 4 caractères']
  },
  
  // Informations personnelles complètes
  firstName: {
    type: String,
    required: [true, 'Le prénom est requis']
  },
  lastName: {
    type: String,
    required: [true, 'Le nom est requis']
  },
  phone: {
    type: String,
    required: [true, 'Le téléphone est requis'],
    unique: true
  },
  email: {
    type: String,
    required: false,
    unique: true,
    sparse: true,
    lowercase: true
  },
  dateOfBirth: {
    type: Date,
    required: [true, 'La date de naissance est requise']
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other'],
    required: [true, 'Le genre est requis']
  },
  address: {
    street: String,
    city: String,
    region: String,
    country: { type: String, default: 'Sénégal' },
    postalCode: String
  },
  nationalId: {
    type: String,
    required: [true, 'La CNI est requise'],
    unique: true
  },
  profilePhoto: String,
  
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
      min: [1960, 'Année du véhicule invalide'],
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
    category: {
      type: String,
      enum: ['car', 'moto'],
      required: [true, 'La catégorie du véhicule est requise'],
      default: 'car'
    },
    type: {
      type: String,
      enum: ['sedan', 'suv', 'minivan', 'moto_delivery', 'motorbike'],
      default: 'sedan'
    },
    capacity: {
      type: Number,
      default: 4,
      min: 1,
      max: 8
    },
    hasAirConditioning: {
      type: Boolean,
      default: false
    },
    features: [{
      type: String,
      enum: ['ac', 'wifi', 'charging', 'child_seat', 'wheelchair_access', 'large_cargo', 'refrigerated']
    }],
    photos: [String] // URLs des photos du véhicule
  },
  
  // Niveau de service du chauffeur (défini par l'admin après vérification du véhicule)
  serviceLevel: {
    type: String,
    enum: ['standard', 'express', 'luxe'],  // standard = véhicule normal, express = véhicule haut de gamme, luxe = véhicule de luxe
    default: 'standard'
  },
  
  // Types de courses acceptées (basé sur serviceLevel)
  rideTypes: {
    standard: {
      type: Boolean,
      default: true  // Tous les chauffeurs peuvent faire du standard
    },
    comfort: {
      type: Boolean,
      default: false  // Seuls les chauffeurs validés "confort" peuvent faire du confort
    },
    luxe: {
      type: Boolean,
      default: false  // Réservé aux véhicules de luxe
    },
    delivery: {
      type: Boolean,
      default: false  // Pour les motos uniquement
    },
    moto: {
      type: Boolean,
      default: false  // Trajet classique en moto
    },
    women_only: {
      type: Boolean,
      default: false  // Réservé aux chauffeuses
    }
  },
  
  // Informations de validation par l'admin
  adminValidation: {
    validatedBy: {
      type: String,
      default: 'admin'
    },
    validatedAt: Date,
    vehicleInspected: {
      type: Boolean,
      default: false
    },
    vehicleCondition: {
      type: String,
      enum: ['excellent', 'good', 'acceptable', 'rejected'],
      default: null
    },
    notes: String,  // Notes de l'admin sur le véhicule
    documentsVerified: {
      type: Boolean,
      default: false
    }
  },
  
  // Statut et disponibilité
  status: {
    type: String,
    enum: ['offline', 'online', 'busy', 'unavailable', 'pending'],
    default: 'offline'
  },
  isAvailable: {
    type: Boolean,
    default: false
  },
  
  // Position actuelle (pour le tracking en temps réel)
  location: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date
  },
  currentLocation: {
    type: {
      type: String,
      enum: ['Point']
    },
    coordinates: {
      type: [Number] // [longitude, latitude]
    },
    address: String,
    lastUpdated: Date
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
    plan: {
      type: String,
      enum: ['free', 'daily', 'weekly', 'monthly', 'yearly'],
      default: 'free'
    },
    startDate: {
      type: Date,
      default: Date.now
    },
    endDate: {
      type: Date,
      default: () => new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    },
    isActive: {
      type: Boolean,
      default: false
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
    carpoolSeats: {
      type: Number,
      default: 1,
      min: 1,
      max: 8 // Nombre de places disponibles pour covoiturage
    },
    acceptExpressRides: {
      type: Boolean,
      default: true
    },
    acceptLuggage: {
      type: Boolean,
      default: false // Pour voitures cargo uniquement
    }
  },
  
  // Documents et vérifications (tous optionnels pour permettre création progressive)
  documents: {
    driverLicensePhoto: String,
    vehicleRegistration: String,
    insurance: {
      type: String,
      required: false,
    },
    insuranceExpiryDate: {
      type: Date,
      required: false,
    },
    technicalInspection: {
      type: String,
      required: false,
    },
    technicalInspectionExpiryDate: {
      type: Date,
      required: false,
    },
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
driverSchema.index({ currentLocation: '2dsphere' });
driverSchema.index({ status: 1, isAvailable: 1 });
driverSchema.index({ 'subscription.isActive': 1 });

// Méthode pour mettre à jour la localisation
driverSchema.methods.updateLocation = function(latitude, longitude, address) {
  const now = new Date();

  this.location = {
    latitude,
    longitude,
    lastUpdated: now
  };

  this.currentLocation = {
    type: 'Point',
    coordinates: [longitude, latitude],
    address,
    lastUpdated: now
  };

  // Garder seulement les 100 dernières positions
  this.locationHistory.push({
    latitude,
    longitude,
    timestamp: now
  });
  
  if (this.locationHistory.length > 100) {
    this.locationHistory = this.locationHistory.slice(-100);
  }
};

// Méthode pour calculer la distance avec un point
driverSchema.methods.calculateDistance = function(latitude, longitude) {
  if (!this.currentLocation || !Array.isArray(this.currentLocation.coordinates)) {
    return null;
  }

  const [currentLon, currentLat] = this.currentLocation.coordinates;
  const R = 6371; // Rayon de la Terre en km
  const dLat = (latitude - currentLat) * Math.PI / 180;
  const dLon = (longitude - currentLon) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(currentLat * Math.PI / 180) * Math.cos(latitude * Math.PI / 180) *
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

// Middleware pour hasher le mot de passe avant sauvegarde
driverSchema.pre('save', async function(next) {
  // Hasher le mot de passe s'il a été modifié
  if (this.isModified('password')) {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  }
  
  // Mettre à jour les statistiques
  if (this.isModified('stats.totalRides')) {
    this.stats.completedRides = this.stats.totalRides - this.stats.cancelledRides;
  }
  
  next();
});

// Méthode pour comparer les mots de passe
driverSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Driver', driverSchema);

