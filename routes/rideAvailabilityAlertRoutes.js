const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const controller = require('../controllers/rideAvailabilityAlertController');

router.use(authMiddleware);

router.post('/', controller.createAvailabilityAlert);
router.get('/my-alerts', controller.getMyAvailabilityAlerts);
router.patch('/:alertId/deactivate', controller.deactivateAvailabilityAlert);

module.exports = router;


