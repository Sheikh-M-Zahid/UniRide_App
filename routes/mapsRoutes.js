const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const mapsController = require('../controllers/mapsController');

// auth optional, but recommended for production usage control
router.use(authMiddleware);

router.get('/autocomplete', mapsController.autocomplete);
router.get('/place-details', mapsController.placeDetails);
router.get('/reverse-geocode', mapsController.reverseGeocode);

module.exports = router;