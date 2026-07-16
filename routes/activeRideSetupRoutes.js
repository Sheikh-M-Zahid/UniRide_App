const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const controller = require('../controllers/activeRideSetupController');

router.use(authMiddleware);

// current active ride
router.get('/current', controller.getCurrentActiveRide);

// page load data
router.get('/setup', controller.getActiveRideSetupData);
router.post('/route-alternatives', controller.getRouteAlternatives);

// confirm / activate ride
router.post('/activate', controller.activateRide);

// cancel current active ride
router.patch('/cancel', controller.cancelCurrentRide);

// optional live location update
router.post('/location', controller.updateCurrentLocation);

module.exports = router;
