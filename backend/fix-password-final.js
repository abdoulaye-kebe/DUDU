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

// Importer le vrai modèle Driver
const Driver = require('./src/models/Driver');

async function fixPassword() {
  try {
    const phone = '+221776862514';
    const newPassword = 'Azerty123';

    console.log('\n========================================');
    console.log('  RÉINITIALISATION FORCÉE DU MOT DE PASSE');
    console.log('========================================\n');

    console.log(`🔍 Recherche du chauffeur: ${phone}`);
    
    const driver = await Driver.findOne({ phone });
    
    if (!driver) {
      console.log('❌ Chauffeur non trouvé!');
      process.exit(1);
    }

    console.log(`✅ Chauffeur trouvé: ${driver.firstName} ${driver.lastName}`);
    console.log(`📧 Email: ${driver.email}`);
    
    console.log(`\n🔐 Ancien mot de passe (hash):`);
    console.log(driver.password);
    
    // FORCER le changement du mot de passe
    console.log(`\n🔧 Modification du mot de passe...`);
    driver.password = newPassword;
    
    // Marquer explicitement le champ comme modifié
    driver.markModified('password');
    
    // Sauvegarder (le middleware pre-save va hasher)
    await driver.save();
    
    console.log(`✅ Mot de passe sauvegardé!`);
    
    // Recharger depuis la BDD pour vérifier
    const updatedDriver = await Driver.findOne({ phone });
    
    console.log(`\n🔐 Nouveau mot de passe (hash):`);
    console.log(updatedDriver.password);
    console.log(`\nLongueur: ${updatedDriver.password.length} caractères`);
    console.log(`Format bcrypt: ${updatedDriver.password.startsWith('$2') ? 'OUI ✅' : 'NON ❌'}`);
    
    // Tester le mot de passe
    console.log(`\n🧪 Test de connexion avec: "${newPassword}"`);
    const isValid = await updatedDriver.comparePassword(newPassword);
    
    if (isValid) {
      console.log(`✅ TEST RÉUSSI! Le mot de passe fonctionne parfaitement.`);
      console.log(`\n========================================`);
      console.log(`  🎯 IDENTIFIANTS DE CONNEXION`);
      console.log(`========================================`);
      console.log(`Téléphone: 776862514 (ou +221776862514)`);
      console.log(`Mot de passe: ${newPassword}`);
      console.log(`========================================\n`);
      console.log(`✅ Vous pouvez maintenant vous connecter dans l'app!`);
    } else {
      console.log(`❌ TEST ÉCHOUÉ! Le mot de passe ne fonctionne toujours pas.`);
      console.log(`\n💡 Il y a un problème avec le middleware pre-save.`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    console.error(error.stack);
    process.exit(1);
  }
}

// Exécuter
fixPassword();
