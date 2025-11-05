// Script pour supprimer l'index géospatial problématique
const mongoose = require('mongoose');

async function fixGeoIndex() {
  try {
    await mongoose.connect('mongodb://localhost:27017/dudu');
    console.log('✅ Connecté à MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('drivers');

    // Supprimer l'index géospatial
    console.log('🔧 Suppression de l\'index currentLocation_2dsphere...');
    await collection.dropIndex('currentLocation_2dsphere');
    console.log('✅ Index supprimé avec succès!');

    await mongoose.disconnect();
    console.log('✅ Déconnecté de MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  }
}

fixGeoIndex();
