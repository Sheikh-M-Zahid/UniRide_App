const express = require('express');
const router = express.Router();
const liveLocationController = require('../controllers/liveLocationController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['ride_id', 'latitude', 'longitude']),
  liveLocationController.updateLiveLocation
);

router.get('/:rideId', authMiddleware, liveLocationController.getRideLiveLocations);

module.exports = router;