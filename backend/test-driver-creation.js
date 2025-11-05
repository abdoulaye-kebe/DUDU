/**
 * Script de test pour la création et l'authentification des chauffeurs
 * Usage: node test-driver-creation.js
 */

const axios = require('axios');

const API_URL = 'http://localhost:3000/api/v1';

// Données de test pour un chauffeur
const testDriver = {
  firstName: 'Mamadou',
  lastName: 'Diop',
  phone: '+221771234567',
  email: 'mamadou.diop@test.com',
  password: 'test123456',
  dateOfBirth: '1990-01-15',
  gender: 'male',
  nationalId: '1234567890123',
  address: {
    street: '123 Rue de la Paix',
    city: 'Dakar',
    region: 'Dakar',
    country: 'Sénégal'
  },
  driverLicense: {
    number: 'DL123456789',
    expiryDate: '2025-12-31',
    category: 'B'
  },
  vehicle: {
    make: 'Toyota',
    model: 'Corolla',
    year: 2020,
    color: 'Blanc',
    plateNumber: 'DK-1234-AB',
    category: 'car',
    type: 'sedan',
    capacity: 4,
    hasAirConditioning: true
  },
  rideTypes: {
    standard: true,
    express: true,
    shared: false,
    womenOnly: false
  },
  preferences: {
    maxDistance: 15,
    minPrice: 1000,
    acceptsShared: false
  },
  subscription: {
    plan: 'weekly',
    isActive: true
  }
};

async function testDriverCreation() {
  console.log('🧪 Test 1: Création d\'un chauffeur');
  console.log('=====================================\n');

  try {
    const response = await axios.post(`${API_URL}/admin/drivers`, testDriver);
    
    if (response.data.success) {
      console.log('✅ Chauffeur créé avec succès!');
      console.log('📋 Détails:');
      console.log(`   - ID: ${response.data.driver._id}`);
      console.log(`   - Nom: ${response.data.driver.firstName} ${response.data.driver.lastName}`);
      console.log(`   - Téléphone: ${response.data.driver.phone}`);
      console.log(`   - Email: ${response.data.driver.email}`);
      console.log(`   - Véhicule: ${response.data.driver.vehicle.make} ${response.data.driver.vehicle.model}`);
      console.log(`   - Plaque: ${response.data.driver.vehicle.plateNumber}`);
      console.log(`   - Statut: ${response.data.driver.status}`);
      console.log(`   - Abonnement: ${response.data.driver.subscription.type}\n`);
      return response.data.driver;
    }
  } catch (error) {
    if (error.response?.status === 400 && error.response?.data?.message?.includes('existe déjà')) {
      console.log('ℹ️  Le chauffeur existe déjà, on passe au test de login\n');
      return { phone: testDriver.phone };
    }
    console.error('❌ Erreur lors de la création:', error.response?.data || error.message);
    return null;
  }
}

async function testDriverLogin(phone, password) {
  console.log('🧪 Test 2: Connexion du chauffeur');
  console.log('=====================================\n');

  try {
    const response = await axios.post(`${API_URL}/drivers/login`, {
      phone: phone,
      password: password
    });

    if (response.data.success) {
      console.log('✅ Connexion réussie!');
      console.log('📋 Détails:');
      console.log(`   - Token: ${response.data.token.substring(0, 50)}...`);
      console.log(`   - Chauffeur: ${response.data.driver.firstName} ${response.data.driver.lastName}`);
      console.log(`   - Statut: ${response.data.driver.status}`);
      console.log(`   - Stats: ${response.data.driver.stats.totalRides} courses\n`);
      return response.data.token;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la connexion:', error.response?.data || error.message);
    return null;
  }
}

async function testPasswordChange(phone, oldPassword, newPassword) {
  console.log('🧪 Test 3: Changement de mot de passe');
  console.log('=====================================\n');

  try {
    const response = await axios.put(`${API_URL}/drivers/change-password`, {
      phone: phone,
      oldPassword: oldPassword,
      newPassword: newPassword
    });

    if (response.data.success) {
      console.log('✅ Mot de passe changé avec succès!\n');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors du changement de mot de passe:', error.response?.data || error.message);
    return false;
  }
}

async function testLoginWithNewPassword(phone, newPassword) {
  console.log('🧪 Test 4: Connexion avec le nouveau mot de passe');
  console.log('=====================================\n');

  try {
    const response = await axios.post(`${API_URL}/drivers/login`, {
      phone: phone,
      password: newPassword
    });

    if (response.data.success) {
      console.log('✅ Connexion avec le nouveau mot de passe réussie!\n');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la connexion:', error.response?.data || error.message);
    return false;
  }
}

async function testDashboard() {
  console.log('🧪 Test 5: Récupération du dashboard');
  console.log('=====================================\n');

  try {
    const response = await axios.get(`${API_URL}/admin/dashboard`);

    if (response.data.success) {
      const { overview, today, monthly } = response.data.data;
      console.log('✅ Dashboard récupéré avec succès!');
      console.log('📊 Statistiques:');
      console.log(`   - Total Utilisateurs: ${overview.totalUsers}`);
      console.log(`   - Total Chauffeurs: ${overview.totalDrivers}`);
      console.log(`   - Total Courses: ${overview.totalRides}`);
      console.log(`   - Nouveaux utilisateurs aujourd\'hui: ${today.users}`);
      console.log(`   - Revenus du jour: ${today.revenue} FCFA`);
      console.log(`   - Revenus du mois: ${monthly.revenue} FCFA\n`);
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la récupération du dashboard:', error.response?.data || error.message);
    return false;
  }
}

async function testGetDrivers() {
  console.log('🧪 Test 6: Récupération de la liste des chauffeurs');
  console.log('=====================================\n');

  try {
    const response = await axios.get(`${API_URL}/admin/drivers`);

    if (response.data.success) {
      console.log('✅ Liste des chauffeurs récupérée avec succès!');
      console.log(`📋 Nombre de chauffeurs: ${response.data.drivers.length}`);
      
      if (response.data.drivers.length > 0) {
        console.log('\n👥 Premiers chauffeurs:');
        response.data.drivers.slice(0, 3).forEach((driver, index) => {
          console.log(`   ${index + 1}. ${driver.firstName} ${driver.lastName} - ${driver.phone}`);
          console.log(`      Véhicule: ${driver.vehicle?.make} ${driver.vehicle?.model}`);
          console.log(`      Statut: ${driver.status}`);
        });
      }
      console.log('');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des chauffeurs:', error.response?.data || error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('\n🚀 Démarrage des tests du système de chauffeurs\n');
  console.log('='.repeat(50));
  console.log('\n');

  let testsPassed = 0;
  let testsFailed = 0;

  // Test 1: Création
  const driver = await testDriverCreation();
  if (driver) {
    testsPassed++;
  } else {
    testsFailed++;
  }

  // Test 2: Login
  if (driver) {
    const token = await testDriverLogin(testDriver.phone, testDriver.password);
    if (token) {
      testsPassed++;
    } else {
      testsFailed++;
    }

    // Test 3: Changement de mot de passe
    const newPassword = 'nouveau123456';
    const passwordChanged = await testPasswordChange(testDriver.phone, testDriver.password, newPassword);
    if (passwordChanged) {
      testsPassed++;

      // Test 4: Login avec nouveau mot de passe
      const loginSuccess = await testLoginWithNewPassword(testDriver.phone, newPassword);
      if (loginSuccess) {
        testsPassed++;

        // Remettre l'ancien mot de passe pour les prochains tests
        await testPasswordChange(testDriver.phone, newPassword, testDriver.password);
      } else {
        testsFailed++;
      }
    } else {
      testsFailed += 2; // Test 3 et 4 échoués
    }
  } else {
    testsFailed += 3; // Tests 2, 3 et 4 sautés
  }

  // Test 5: Dashboard
  const dashboardSuccess = await testDashboard();
  if (dashboardSuccess) {
    testsPassed++;
  } else {
    testsFailed++;
  }

  // Test 6: Liste des chauffeurs
  const driversSuccess = await testGetDrivers();
  if (driversSuccess) {
    testsPassed++;
  } else {
    testsFailed++;
  }

  // Résumé
  console.log('\n' + '='.repeat(50));
  console.log('\n📊 RÉSUMÉ DES TESTS\n');
  console.log(`✅ Tests réussis: ${testsPassed}`);
  console.log(`❌ Tests échoués: ${testsFailed}`);
  console.log(`📈 Taux de réussite: ${Math.round((testsPassed / (testsPassed + testsFailed)) * 100)}%\n`);

  if (testsFailed === 0) {
    console.log('🎉 Tous les tests sont passés avec succès!\n');
  } else {
    console.log('⚠️  Certains tests ont échoué. Vérifiez les erreurs ci-dessus.\n');
  }
}

// Vérifier que le serveur est accessible
axios.get(`${API_URL.replace('/api/v1', '')}/api/health`)
  .then(() => {
    console.log('✅ Serveur accessible\n');
    runAllTests();
  })
  .catch((error) => {
    console.error('❌ Impossible de se connecter au serveur');
    console.error('   Assurez-vous que le serveur backend est démarré sur http://localhost:3000');
    console.error('   Commande: cd backend && npm run dev\n');
    process.exit(1);
  });
