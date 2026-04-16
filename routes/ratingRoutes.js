const express = require('express');
const router = express.Router();

const ratingController = require('../controllers/ratingController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.use(authMiddleware);

// check endpoint
router.get('/check', ratingController.checkRatingStatus);

// passenger -> rider
router.post(
  '/passenger-rate-rider',
  validateRequiredFields(['ride_id', 'rating']),
  ratingController.passengerRatesRider
);

// rider -> one passenger
router.post(
  '/rider-rate-participant',
  validateRequiredFields(['ride_id', 'participant_id', 'rating']),
  ratingController.riderRatesParticipant
);

// existing summary
router.get('/summary/:userId', ratingController.fetchRatingSummary);

module.exports = router;