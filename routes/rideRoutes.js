const express = require('express');
const router = express.Router();
const rideController = require('../controllers/rideController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');
router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['start_location', 'destination', 'available_seats']),
  rideController.createRide
);

router.post('/search', authMiddleware, rideController.searchRides);
router.get('/active', rideController.listActiveRides);
router.get('/my-created', authMiddleware, rideController.listMyCreatedRides);
router.get('/joined', authMiddleware, rideController.listJoinedRides);
router.get('/:rideId', rideController.getRideDetails);
router.post('/:rideId/join', authMiddleware, rideController.joinRide);
router.patch('/:rideId/status', authMiddleware, validateRequiredFields(['status']), rideController.changeRideStatus);
router.patch('/:rideId/confirm/:participantId', authMiddleware, rideController.confirmParticipant);
router.patch('/status', authenticate, riderController.updateStatus);
router.get('/dashboard-summary', authenticate, riderController.getDashboard);


module.exports = router;