const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const controller = require('../controllers/activeRideSetupController');

router.use(authMiddleware);

// page load data
router.get('/setup', controller.getActiveRideSetupData);

// confirm / activate ride
router.post('/activate', controller.activateRide);

// optional live location update
router.post('/location', controller.updateCurrentLocation);

module.exports = router;