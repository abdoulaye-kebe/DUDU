const mongoose = require('mongoose');
require('dotenv').config();
const Driver = require('../src/models/Driver');
const User = require('../src/models/User');

async function showDriverProfile(userId) {
  try {
    // Connexion à MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu');
    console.log('✅ Connexion à MongoDB réussie\n');

    // Rechercher l'utilisateur
    const user = await User.findById(userId);
    if (!user) {
      console.log(`❌ Utilisateur avec l'ID ${userId} non trouvé`);
      process.exit(1);
    }

    console.log(`👤 Utilisateur trouvé:`);
    console.log(`   - Nom: ${user.firstName} ${user.lastName}`);
    console.log(`   - Téléphone: ${user.phone}`);
    console.log(`   - Email: ${user.email || 'N/A'}\n`);

    // Rechercher le profil chauffeur
    const driver = await Driver.findOne({ user: userId })
      .populate('user', 'firstName lastName phone email');

    if (!driver) {
      console.log(`❌ Aucun profil chauffeur trouvé pour cet utilisateur`);
      console.log(`💡 Le profil sera créé automatiquement lors de la première connexion\n`);
      process.exit(0);
    }

    console.log(`🚗 Profil Chauffeur:`);
    console.log(`   - ID Chauffeur: ${driver._id}`);
    console.log(`   - Statut: ${driver.status}`);
    console.log(`   - Disponible: ${driver.isAvailable ? 'Oui' : 'Non'}`);
    console.log(`   - Vérifié: ${driver.isVerified ? 'Oui' : 'Non'}`);
    console.log(`   - Statut vérification: ${driver.verificationStatus}\n`);

    console.log(`📜 Permis de conduire:`);
    console.log(`   - Numéro: ${driver.driverLicense.number}`);
    console.log(`   - Catégorie: ${driver.driverLicense.category}`);
    console.log(`   - Expiration: ${driver.driverLicense.expiryDate}\n`);

    console.log(`🚙 Véhicule:`);
    console.log(`   - Marque: ${driver.vehicle.make}`);
    console.log(`   - Modèle: ${driver.vehicle.model}`);
    console.log(`   - Année: ${driver.vehicle.year}`);
    console.log(`   - Couleur: ${driver.vehicle.color}`);
    console.log(`   - Plaque: ${driver.vehicle.plateNumber}`);
    console.log(`   - Catégorie: ${driver.vehicle.category}`);
    console.log(`   - Type: ${driver.vehicle.type}\n`);

    console.log(`📍 Localisation:`);
    if (driver.currentLocation && driver.currentLocation.latitude) {
      console.log(`   - Latitude: ${driver.currentLocation.latitude}`);
      console.log(`   - Longitude: ${driver.currentLocation.longitude}`);
      console.log(`   - Adresse: ${driver.currentLocation.address || 'N/A'}`);
      console.log(`   - Dernière mise à jour: ${driver.currentLocation.lastUpdated}\n`);
    } else {
      console.log(`   - Aucune localisation enregistrée\n`);
    }

    console.log(`💳 Abonnement:`);
    if (driver.subscription) {
      console.log(`   - Type: ${driver.subscription.type}`);
      console.log(`   - Actif: ${driver.subscription.isActive ? 'Oui' : 'Non'}`);
      console.log(`   - Début: ${driver.subscription.startDate}`);
      console.log(`   - Fin: ${driver.subscription.endDate}`);
      console.log(`   - Valide: ${driver.isSubscriptionValid() ? 'Oui' : 'Non'}\n`);
    } else {
      console.log(`   - Aucun abonnement\n`);
    }

    console.log(`📊 Statistiques:`);
    console.log(`   - Courses totales: ${driver.stats.totalRides}`);
    console.log(`   - Courses terminées: ${driver.stats.completedRides}`);
    console.log(`   - Note moyenne: ${driver.stats.averageRating}\n`);

    console.log(`💰 Revenus:`);
    console.log(`   - Aujourd'hui: ${driver.earnings.today} FCFA`);
    console.log(`   - Cette semaine: ${driver.earnings.thisWeek} FCFA`);
    console.log(`   - Ce mois: ${driver.earnings.thisMonth} FCFA`);
    console.log(`   - Total: ${driver.earnings.total} FCFA\n`);

    await mongoose.disconnect();
    console.log('✅ Connexion fermée');
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Récupérer l'ID utilisateur depuis les arguments
const userId = process.argv[2];
if (!userId) {
  console.log('Usage: node scripts/show_driver_profile.js <userId>');
  console.log('Exemple: node scripts/show_driver_profile.js 507f1f77bcf86cd799439011');
  process.exit(1);
}

showDriverProfile(userId);




