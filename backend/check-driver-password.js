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

async function checkPassword() {
  try {
    const phone = '+221776862514';
    const testPassword = 'Azerty123';

    console.log(`\n🔍 Recherche du chauffeur: ${phone}`);
    
    const driver = await Driver.findOne({ phone });
    
    if (!driver) {
      console.log('❌ Chauffeur non trouvé!');
      process.exit(1);
    }

    console.log(`✅ Chauffeur trouvé: ${driver.firstName} ${driver.lastName}`);
    console.log(`📧 Email: ${driver.email}`);
    console.log(`📞 Téléphone: ${driver.phone}`);
    console.log(`\n🔐 Hash du mot de passe stocké:`);
    console.log(driver.password);
    console.log(`\n🔐 Longueur du hash: ${driver.password.length} caractères`);
    
    // Vérifier si c'est un hash bcrypt valide
    const isBcryptHash = driver.password.startsWith('$2a$') || driver.password.startsWith('$2b$');
    console.log(`\n✅ Format bcrypt valide: ${isBcryptHash ? 'OUI' : 'NON'}`);
    
    if (!isBcryptHash) {
      console.log(`\n❌ PROBLÈME: Le mot de passe n'est PAS hashé correctement!`);
      console.log(`Le mot de passe stocké est: "${driver.password}"`);
      console.log(`\n💡 Solution: Le mot de passe doit être re-hashé.`);
      
      // Re-hasher le mot de passe
      console.log(`\n🔧 Re-hashage du mot de passe...`);
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(testPassword, salt);
      
      driver.password = hashedPassword;
      await driver.save();
      
      console.log(`✅ Mot de passe re-hashé avec succès!`);
    }
    
    // Tester le mot de passe
    console.log(`\n🧪 Test de connexion avec: "${testPassword}"`);
    const isValid = await bcrypt.compare(testPassword, driver.password);
    
    if (isValid) {
      console.log(`✅ Test réussi! Le mot de passe fonctionne.`);
      console.log(`\n🎯 Vous pouvez maintenant vous connecter avec:`);
      console.log(`   Téléphone: 776862514`);
      console.log(`   Mot de passe: ${testPassword}`);
    } else {
      console.log(`❌ Test échoué! Le mot de passe ne correspond pas.`);
      console.log(`\n💡 Essayons avec d'autres mots de passe courants...`);
      
      const commonPasswords = ['azerty123', 'Azerty', '123456', 'password', 'dudu2514'];
      
      for (const pwd of commonPasswords) {
        const valid = await bcrypt.compare(pwd, driver.password);
        if (valid) {
          console.log(`✅ Trouvé! Le mot de passe est: "${pwd}"`);
          break;
        }
      }
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Exécuter
checkPassword();
