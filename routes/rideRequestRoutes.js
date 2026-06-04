const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const rideRequestController = require('../controllers/rideRequestController');

router.use(authMiddleware);

// passenger
router.get('/passenger/active', rideRequestController.getPassengerActiveRequest);
router.post('/', rideRequestController.createRequest);
router.get('/:requestId', rideRequestController.getRequestStatus);
router.patch('/:requestId/cancel', rideRequestController.cancelRequest);

// rider
router.patch('/:requestId/accept', rideRequestController.acceptRequest);
router.patch('/:requestId/reject', rideRequestController.rejectRequest);

module.exports = router;
