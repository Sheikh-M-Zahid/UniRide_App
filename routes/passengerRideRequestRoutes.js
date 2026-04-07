const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const passengerRideRequestController = require('../controllers/passengerRideRequestController');

router.use(authMiddleware);

router.post('/create', passengerRideRequestController.createRideRequest);

module.exports = router;