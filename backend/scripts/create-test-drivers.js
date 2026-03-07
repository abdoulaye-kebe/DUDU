const mongoose = require('mongoose');
const User = require('../src/models/User');
const Driver = require('../src/models/Driver');

// Connexion à MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/dudu';

async function createTestDrivers() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connexion à MongoDB réussie');

    // Coordonnées de Dakar (Place de l'Indépendance)
    const dakarLat = 14.6928;
    const dakarLon = -17.4467;

    // Créer ou récupérer 3 utilisateurs pour les chauffeurs
    const users = [];
    for (let i = 1; i <= 3; i++) {
      const phone = `+22177123456${i}`;
      let user = await User.findOne({ phone });
      
      if (!user) {
        user = new User({
          phone,
          password: 'test123',
          firstName: `Chauffeur${i}`,
          lastName: 'Test',
          email: `chauffeur${i}@test.com`,
          isVerified: true,
          role: 'driver'
        });
        await user.save();
        console.log(`✅ Utilisateur chauffeur ${i} créé: ${phone}`);
      } else {
        // Mettre à jour le mot de passe si nécessaire
        user.password = 'test123';
        user.isVerified = true;
        await user.save();
        console.log(`✅ Utilisateur chauffeur ${i} mis à jour: ${phone}`);
      }
      users.push(user);
    }

    // Créer ou mettre à jour les chauffeurs avec localisation près de Dakar
    const driversData = [
      {
        offset: { lat: 0.001, lon: 0.001 }, // ~150m de Dakar
        vehicle: { make: 'Toyota', model: 'Corolla', year: 2020, color: 'Blanc', plateNumber: `DK-100${1}-AB`, category: 'car' }
      },
      {
        offset: { lat: -0.002, lon: 0.0015 }, // ~250m de Dakar
        vehicle: { make: 'Renault', model: 'Symbol', year: 2019, color: 'Noir', plateNumber: `DK-100${2}-AB`, category: 'car' }
      },
      {
        offset: { lat: 0.0015, lon: -0.001 }, // ~200m de Dakar
        vehicle: { make: 'Peugeot', model: '301', year: 2021, color: 'Gris', plateNumber: `DK-100${3}-AB`, category: 'car' }
      }
    ];

    for (let i = 0; i < users.length; i++) {
      const user = users[i];
      const driverData = driversData[i];
      
      let driver = await Driver.findOne({ user: user._id });
      
      if (!driver) {
        driver = new Driver({
          user: user._id,
          driverLicense: {
            number: `LICENSE${user._id}`,
            expiryDate: new Date('2026-12-31'),
            category: 'B'
          },
          vehicle: driverData.vehicle,
          status: 'online',
          isAvailable: true,
          currentLocation: {
            latitude: dakarLat + driverData.offset.lat,
            longitude: dakarLon + driverData.offset.lon,
            address: `Adresse test chauffeur ${i + 1}, Dakar`,
            lastUpdated: new Date()
          },
          subscription: {
            type: 'monthly',
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 jours
            isActive: true
          }
        });
      } else {
        // Mettre à jour le chauffeur existant
        driver.status = 'online';
        driver.isAvailable = true;
        driver.currentLocation = {
          latitude: dakarLat + driverData.offset.lat,
          longitude: dakarLon + driverData.offset.lon,
          address: `Adresse test chauffeur ${i + 1}, Dakar`,
          lastUpdated: new Date()
        };
        if (!driver.subscription || !driver.subscription.isActive) {
          driver.subscription = {
            type: 'monthly',
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            isActive: true
          };
        }
      }
      
      await driver.save();
      console.log(`✅ Chauffeur ${i + 1} créé/mis à jour: ${driverData.vehicle.make} ${driverData.vehicle.model}`);
      console.log(`   📍 Position: ${driver.currentLocation.latitude.toFixed(6)}, ${driver.currentLocation.longitude.toFixed(6)}`);
    }

    console.log('\n✅ 3 chauffeurs de test créés/mis à jour avec succès!');
    console.log('📍 Tous sont situés autour de Dakar (Place de l\'Indépendance)');
    console.log('🚗 Statut: online et disponible');
    console.log('✅ Abonnement: actif');
    
    await mongoose.disconnect();
    console.log('\n✅ Déconnexion de MongoDB');
    process.exit(0);

  } catch (error) {
    console.error('❌ Erreur:', error);
    await mongoose.disconnect();
    process.exit(1);
  }
}

createTestDrivers();





