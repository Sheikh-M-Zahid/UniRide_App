const express = require('express');
const router = express.Router();

const offersController = require('../controllers/offersController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

// Get active offers
router.get('/active', offersController.getActiveOffers);

// Get active offers count
router.get('/active-count', offersController.getActiveOffersCount);

// Apply promo code
router.post(
  '/apply',
  validateRequiredFields(['promo_code']),
  offersController.applyOffer
);

module.exports = router;