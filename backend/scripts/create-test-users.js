const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Importer le modèle User
const User = require('../src/models/User');

// Fonction pour créer ou mettre à jour un utilisateur de test
async function createTestUser(firstName, lastName, phone, password, isVerified = true) {
  try {
    // Vérifier si l'utilisateur existe déjà
    let user = await User.findOne({ phone });
    
    if (user) {
      console.log(`⚠️  Utilisateur ${phone} existe déjà, mise à jour du mot de passe...`);
      // Mettre à jour le mot de passe et les informations
      user.firstName = firstName;
      user.lastName = lastName;
      user.password = password; // Le modèle User hash automatiquement le mot de passe
      user.isVerified = isVerified;
      user.isActive = true;
      await user.save();
      console.log(`✅ Utilisateur mis à jour : ${firstName} ${lastName} (${phone})`);
      return user;
    }

    // Créer le nouvel utilisateur
    user = new User({
      firstName,
      lastName,
      phone,
      password, // Le modèle User hash automatiquement le mot de passe
      isVerified,
      language: 'fr',
      currency: 'XOF'
    });

    // Générer le code de parrainage
    user.generateReferralCode();

    // Sauvegarder l'utilisateur
    await user.save();

    console.log(`✅ Utilisateur créé : ${firstName} ${lastName} (${phone})`);
    return user;
  } catch (error) {
    console.error(`❌ Erreur lors de la création de ${phone}:`, error.message);
    throw error;
  }
}

// Fonction principale
async function main() {
  try {
    // Connexion à MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu';
    console.log('🔌 Connexion à MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('✅ Connecté à MongoDB');

    // Créer 3 utilisateurs de test
    console.log('\n📝 Création des utilisateurs de test...\n');

    const testUsers = [
      {
        firstName: 'Mamadou',
        lastName: 'Sall',
        phone: '+221771234567',
        password: 'test123',
        isVerified: true
      },
      {
        firstName: 'Aissatou',
        lastName: 'Diallo',
        phone: '+221776543210',
        password: 'test123',
        isVerified: true
      },
      {
        firstName: 'Ibrahima',
        lastName: 'Ndiaye',
        phone: '+221775550000',
        password: 'test123',
        isVerified: true
      }
    ];

    for (const userData of testUsers) {
      await createTestUser(
        userData.firstName,
        userData.lastName,
        userData.phone,
        userData.password,
        userData.isVerified
      );
    }

    console.log('\n✅ Tous les utilisateurs ont été créés avec succès!\n');

    // Afficher les identifiants de connexion
    console.log('📋 IDENTIFIANTS DE CONNEXION :');
    console.log('═══════════════════════════════════════════════════');
    testUsers.forEach((user, index) => {
      console.log(`\n${index + 1}. ${user.firstName} ${user.lastName}`);
      console.log(`   📱 Téléphone : ${user.phone}`);
      console.log(`   🔑 Mot de passe : ${user.password}`);
    });
    console.log('\n═══════════════════════════════════════════════════\n');

    // Fermer la connexion
    await mongoose.connection.close();
    console.log('👋 Connexion fermée');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    await mongoose.connection.close();
    process.exit(1);
  }
}

// Exécuter le script
main();



