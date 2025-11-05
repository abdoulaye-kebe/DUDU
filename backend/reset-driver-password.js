const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu')
  .then(() => console.log('✅ Connecté à MongoDB'))
  .catch(err => {
    console.error('❌ Erreur MongoDB:', err);
    process.exit(1);
  });

// Schéma simplifié du Driver
const driverSchema = new mongoose.Schema({}, { strict: false });
const Driver = mongoose.model('Driver', driverSchema);

async function resetPassword() {
  try {
    // Téléphone du chauffeur
    const phone = '+221776862514';
    const newPassword = 'Azerty123';

    console.log(`\n🔍 Recherche du chauffeur: ${phone}`);
    
    // Trouver le chauffeur
    const driver = await Driver.findOne({ phone });
    
    if (!driver) {
      console.log('❌ Chauffeur non trouvé!');
      console.log('\n📋 Liste des chauffeurs:');
      const drivers = await Driver.find({}, 'firstName lastName phone email');
      drivers.forEach(d => {
        console.log(`  - ${d.firstName} ${d.lastName} | ${d.phone} | ${d.email}`);
      });
      process.exit(1);
    }

    console.log(`✅ Chauffeur trouvé: ${driver.firstName} ${driver.lastName}`);
    console.log(`📧 Email: ${driver.email}`);
    console.log(`📞 Téléphone: ${driver.phone}`);
    
    // Hasher le nouveau mot de passe
    console.log(`\n🔐 Hashage du nouveau mot de passe...`);
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    // Mettre à jour le mot de passe
    driver.password = hashedPassword;
    await driver.save();
    
    console.log(`✅ Mot de passe mis à jour!`);
    console.log(`\n🎯 Nouvelles informations de connexion:`);
    console.log(`   Téléphone: ${phone} (ou 776862514)`);
    console.log(`   Mot de passe: ${newPassword}`);
    
    // Tester le mot de passe
    console.log(`\n🧪 Test de connexion...`);
    const isValid = await bcrypt.compare(newPassword, driver.password);
    
    if (isValid) {
      console.log(`✅ Test réussi! Le mot de passe fonctionne.`);
    } else {
      console.log(`❌ Test échoué! Problème avec le hash.`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Exécuter
resetPassword();
