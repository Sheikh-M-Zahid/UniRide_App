const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const rideRequestController = require('../controllers/rideRequestController');

router.use(authMiddleware);

// rider — নতুন multi-seat dashboard/pending/cancel-confirmed (System B এর replacement)
router.get('/rider/dashboard', rideRequestController.getRiderDashboard);
router.get('/rider/pending', rideRequestController.getScoredPendingRequests);
router.patch('/:requestId/cancel-confirmed', rideRequestController.cancelAcceptedParticipant);

// passenger
router.get('/passenger/active', rideRequestController.getPassengerActiveRequest);
router.post('/', rideRequestController.createRequest);
router.get('/:requestId', rideRequestController.getRequestStatus);
router.patch('/:requestId/cancel', rideRequestController.cancelRequest);

// rider — accept/reject (already existed)
router.patch('/:requestId/accept', rideRequestController.acceptRequest);
router.patch('/:requestId/reject', rideRequestController.rejectRequest);
router.get('/:requestId/rider-location', rideRequestController.getRiderLiveLocation);

module.exports = router;
