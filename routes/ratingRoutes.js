const express = require('express');
const router = express.Router();
const ratingController = require('../controllers/ratingController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/passenger-rate-rider',
  authMiddleware,
  validateRequiredFields(['ride_id', 'rating']),
  ratingController.passengerRatesRider
);

router.post(
  '/rider-rate-participants',
  authMiddleware,
  validateRequiredFields(['ride_id', 'rating']),
  ratingController.riderRatesParticipants
);

router.get('/summary/:userId', authMiddleware, ratingController.fetchRatingSummary);

module.exports = router;