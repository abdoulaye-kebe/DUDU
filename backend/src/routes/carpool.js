const express = require('express');
const router = express.Router();
const carpoolController = require('../controllers/carpoolController');

// Routes publiques (pas besoin d'auth pour rechercher)
router.get('/drivers/available', carpoolController.getAvailableCarpoolDrivers);

// Routes de test
router.post('/test/create-drivers', carpoolController.createTestDrivers);

module.exports = router;

