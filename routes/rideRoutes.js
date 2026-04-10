const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const rideController = require('../controllers/rideController');

router.get('/active', authMiddleware, rideController.listActiveRides);
router.get('/my-created', authMiddleware, rideController.listMyCreatedRides);
router.get('/joined', authMiddleware, rideController.listJoinedRides);
router.get('/:rideId', authMiddleware, rideController.getRideDetails);

router.post('/create', authMiddleware, rideController.createRide);
router.post('/search', authMiddleware, rideController.searchRides);
router.post('/:rideId/join', authMiddleware, rideController.joinRide);
router.patch('/:rideId/status', authMiddleware, rideController.changeRideStatus);
router.patch(
  '/:rideId/participants/:participantId/confirm',
  authMiddleware,
  rideController.confirmParticipant
);

module.exports = router;