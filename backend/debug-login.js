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

async function debugLogin() {
  try {
    console.log('\n========================================');
    console.log('  DEBUG COMPLET DU LOGIN CHAUFFEUR');
    console.log('========================================\n');

    // Test avec différents formats de téléphone
    const phoneFormats = ['776862514', '+221776862514', '221776862514'];
    
    for (const phone of phoneFormats) {
      console.log(`\n🔍 Test avec: "${phone}"`);
      
      // Normaliser comme le fait le backend
      let normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+')) {
        if (normalizedPhone.startsWith('221')) {
          normalizedPhone = '+' + normalizedPhone;
        } else if (normalizedPhone.length === 9) {
          normalizedPhone = '+221' + normalizedPhone;
        }
      }
      
      console.log(`   → Normalisé en: "${normalizedPhone}"`);
      
      const driver = await Driver.findOne({ phone: normalizedPhone });
      
      if (driver) {
        console.log(`   ✅ Chauffeur trouvé!`);
        console.log(`   📧 Email: ${driver.email}`);
        console.log(`   🔐 Hash: ${driver.password.substring(0, 20)}...`);
      } else {
        console.log(`   ❌ Chauffeur NON trouvé`);
      }
    }

    // Trouver le chauffeur avec le bon téléphone
    const driver = await Driver.findOne({ phone: '+221776862514' });
    
    if (!driver) {
      console.log('\n❌ Aucun chauffeur trouvé avec +221776862514');
      console.log('\n📋 Liste de TOUS les chauffeurs:');
      const allDrivers = await Driver.find({}, 'firstName lastName phone email password');
      allDrivers.forEach(d => {
        console.log(`\n  - ${d.firstName} ${d.lastName}`);
        console.log(`    📞 ${d.phone}`);
        console.log(`    📧 ${d.email}`);
        console.log(`    🔐 ${d.password.substring(0, 30)}...`);
      });
      process.exit(1);
    }

    console.log('\n========================================');
    console.log('  INFORMATIONS DU CHAUFFEUR');
    console.log('========================================');
    console.log(`Nom: ${driver.firstName} ${driver.lastName}`);
    console.log(`Email: ${driver.email}`);
    console.log(`Téléphone: ${driver.phone}`);
    console.log(`\nHash du mot de passe:`);
    console.log(driver.password);
    console.log(`\nLongueur: ${driver.password.length} caractères`);
    console.log(`Format bcrypt: ${driver.password.startsWith('$2') ? 'OUI ✅' : 'NON ❌'}`);

    // Tester plusieurs mots de passe
    console.log('\n========================================');
    console.log('  TEST DES MOTS DE PASSE');
    console.log('========================================\n');

    const passwords = [
      'Azerty123',
      'azerty123', 
      'test123456',
      'Test123456',
      'dudu2514',
      '123456',
      'password'
    ];

    for (const pwd of passwords) {
      try {
        const isValid = await bcrypt.compare(pwd, driver.password);
        if (isValid) {
          console.log(`✅ TROUVÉ! Le mot de passe est: "${pwd}"`);
          console.log(`\n🎯 Utilisez ces identifiants:`);
          console.log(`   Téléphone: 776862514`);
          console.log(`   Mot de passe: ${pwd}`);
          process.exit(0);
        } else {
          console.log(`❌ "${pwd}" - incorrect`);
        }
      } catch (err) {
        console.log(`❌ "${pwd}" - erreur: ${err.message}`);
      }
    }

    console.log('\n❌ Aucun mot de passe ne correspond!');
    console.log('\n💡 Solution: Réinitialiser le mot de passe');
    console.log('   Exécutez: node reset-driver-password.js');
    
    process.exit(1);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Exécuter
debugLogin();
