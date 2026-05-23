const express = require('express');
const router = express.Router();

const offersController = require('../controllers/offerController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

// Get active offers
router.get('/active', offersController.getActiveOffers);

// Get active offers count
router.get('/active-count', offersController.getActiveOffersCount);

// All offers (active + expired within 30 days)
router.get('/recent', offersController.getRecentOffers);

// Apply promo code
router.post(
  '/apply',
  validateRequiredFields(['promo_code']),
  offersController.applyOffer
);

// Create offer (ADMIN)
router.post(
  '/',
  validateRequiredFields([
    'offer_name',
    'offer_type',
    'reward_percentage',
    'eligible_user',
    'start_date',
    'end_date',
    'promo_code'
  ]),
  offersController.createOffer
);

module.exports = router;
