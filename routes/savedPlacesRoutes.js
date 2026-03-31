const express = require('express');
const router = express.Router();

const savedPlacesController = require('../controllers/savedPlacesController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/me/saved-places', authMiddleware, savedPlacesController.getSavedPlaces);
router.put('/me/saved-places', authMiddleware, savedPlacesController.updateSavedPlaces);

module.exports = router;