const mongoose = require('mongoose');
const User = require('./src/models/User');
const Driver = require('./src/models/Driver');
require('dotenv').config();

async function testDatabase() {
  try {
    // Connexion à MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu');
    console.log('✅ Connexion à MongoDB réussie\n');

    // Compter les utilisateurs
    const userCount = await User.countDocuments();
    console.log(`👥 Nombre de clients: ${userCount}`);

    // Afficher les 5 derniers clients
    const users = await User.find().sort({ createdAt: -1 }).limit(5);
    console.log('\n📋 Derniers clients:');
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.firstName} ${user.lastName} - ${user.phone} (${user.createdAt})`);
    });

    // Compter les chauffeurs
    const driverCount = await Driver.countDocuments();
    console.log(`\n🚕 Nombre de chauffeurs: ${driverCount}`);

    // Afficher les 5 derniers chauffeurs
    const drivers = await Driver.find().sort({ createdAt: -1 }).limit(5);
    console.log('\n📋 Derniers chauffeurs:');
    drivers.forEach((driver, index) => {
      console.log(`${index + 1}. ${driver.firstName} ${driver.lastName} - ${driver.phone} (${driver.createdAt})`);
    });

    mongoose.connection.close();
    console.log('\n✅ Test terminé');
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

testDatabase();
