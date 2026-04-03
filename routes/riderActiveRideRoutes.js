const express = require('express');
const router = express.Router();

const riderActiveRideController = require('../controllers/riderActiveRideController');
const authMiddleware = require('../middlewares/authMiddleware');

router.use(authMiddleware);

router.patch('/availability', riderActiveRideController.updateAvailability);
router.get('/dashboard', riderActiveRideController.getDashboard);

router.post('/ride-requests/:requestId/accept', riderActiveRideController.acceptRideRequest);
router.post('/ride-requests/:requestId/reject', riderActiveRideController.rejectRideRequest);

router.post('/confirmed-ride/:requestId/cancel', riderActiveRideController.cancelConfirmedRide);

router.patch('/rides/:rideId/start', riderActiveRideController.startRide);
router.patch('/rides/:rideId/complete', riderActiveRideController.completeRide);

module.exports = router;