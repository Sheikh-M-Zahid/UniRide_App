const express = require('express');
const router = express.Router();

const offersController = require('../controllers/offersController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');
const authMiddleware = require('../middlewares/authMiddleware');

// Get active offers
router.get('/active', authMiddleware, offersController.getActiveOffers);

// Get active offers count
router.get('/active-count', authMiddleware, offersController.getActiveOffersCount);

// Apply promo code
router.post(
  '/apply',
  authMiddleware,
  validateRequiredFields(['promo_code']),
  offersController.applyOffer
);

module.exports = router;