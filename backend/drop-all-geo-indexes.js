// Script pour supprimer TOUS les index géospatiaux
const mongoose = require('mongoose');

async function dropAllGeoIndexes() {
  try {
    await mongoose.connect('mongodb://localhost:27017/dudu');
    console.log('✅ Connecté à MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('drivers');

    // Lister tous les index
    const indexes = await collection.indexes();
    console.log('\n📋 Index actuels:');
    indexes.forEach(idx => {
      console.log(`   - ${idx.name}`);
    });

    // Supprimer tous les index géospatiaux
    for (const idx of indexes) {
      if (idx.name.includes('2dsphere') || idx.name.includes('Location')) {
        console.log(`\n🗑️  Suppression de: ${idx.name}`);
        try {
          await collection.dropIndex(idx.name);
          console.log(`   ✅ ${idx.name} supprimé`);
        } catch (err) {
          console.log(`   ⚠️  Erreur: ${err.message}`);
        }
      }
    }

    // Vérifier les index restants
    const remainingIndexes = await collection.indexes();
    console.log('\n📋 Index restants:');
    remainingIndexes.forEach(idx => {
      console.log(`   - ${idx.name}`);
    });

    await mongoose.disconnect();
    console.log('\n✅ Terminé!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  }
}

dropAllGeoIndexes();
