const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // Informations de base
  firstName: {
    type: String,
    required: [true, 'Le prénom est requis'],
    trim: true,
    maxlength: [50, 'Le prénom ne peut pas dépasser 50 caractères']
  },
  lastName: {
    type: String,
    required: [true, 'Le nom est requis'],
    trim: true,
    maxlength: [50, 'Le nom ne peut pas dépasser 50 caractères']
  },
  phone: {
    type: String,
    required: [true, 'Le numéro de téléphone est requis'],
    unique: true,
    match: [/^(\+221|221)?[0-9]{9}$/, 'Format de numéro de téléphone invalide']
  },
  email: {
    type: String,
    unique: true,
    sparse: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Format d\'email invalide']
  },
  password: {
    type: String,
    required: [true, 'Le mot de passe est requis'],
    minlength: [6, 'Le mot de passe doit contenir au moins 6 caractères']
  },
  
  // Informations de localisation
  address: {
    street: String,
    city: {
      type: String,
      default: 'Dakar'
    },
    neighborhood: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  
  // Préférences
  language: {
    type: String,
    enum: ['fr', 'wo'],
    default: 'fr'
  },
  currency: {
    type: String,
    enum: ['XOF', 'EUR', 'USD'],
    default: 'XOF'
  },
  
  // Statut et vérification
  isVerified: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  verificationCode: String,
  verificationExpires: Date,
  
  // Informations de profil
  profilePicture: String,
  dateOfBirth: Date,
  gender: {
    type: String,
    enum: ['male', 'female', 'other']
  },
  
  // Statistiques
  totalRides: {
    type: Number,
    default: 0
  },
  totalSpent: {
    type: Number,
    default: 0
  },
  averageRating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  
  // Système de parrainage
  referralCode: {
    type: String,
    unique: true,
    sparse: true
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  referralCount: {
    type: Number,
    default: 0
  },
  
  // Préférences de course
  preferredDrivers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver'
  }],
  blockedDrivers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver'
  }],
  
  // Mode économie
  budgetSettings: {
    maxPricePerKm: Number,
    preferredPaymentMethod: {
      type: String,
      enum: ['orange_money', 'wave', 'free_money', 'cash'],
      default: 'orange_money'
    }
  }
}, {
  timestamps: true
});

// Index géospatial pour la localisation
userSchema.index({ 'address.coordinates': '2dsphere' });

// Middleware pour hasher le mot de passe
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Méthode pour comparer les mots de passe
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Méthode pour générer un code de vérification
userSchema.methods.generateVerificationCode = function() {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  this.verificationCode = code;
  this.verificationExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return code;
};

// Méthode pour générer un code de parrainage
userSchema.methods.generateReferralCode = function() {
  const code = 'DUDU' + Math.random().toString(36).substr(2, 6).toUpperCase();
  this.referralCode = code;
  return code;
};

// Méthode pour obtenir le nom complet
userSchema.methods.getFullName = function() {
  return `${this.firstName} ${this.lastName}`;
};

// Méthode pour obtenir les statistiques
userSchema.methods.getStats = function() {
  return {
    totalRides: this.totalRides,
    totalSpent: this.totalSpent,
    averageRating: this.averageRating,
    memberSince: this.createdAt
  };
};

module.exports = mongoose.model('User', userSchema);

