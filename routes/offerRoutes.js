const express = require('express');
const router = express.Router();

const offersController = require('../controllers/offersController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');
const authMiddleware = require('../middlewares/authMiddleware');

<<<<<<< HEAD
router.get('/active', authMiddleware, offerController.getActiveOffers);

router.get('/active-count', authMiddleware, offerController.getActiveOfferCount);

router.post(
  '/validate-promo',
  authMiddleware,
  validateRequiredFields(['promo_code']),
  offerController.validatePromoCode
=======
// Get active offers
router.get('/active', offersController.getActiveOffers);

// Get active offers count
router.get('/active-count', offersController.getActiveOffersCount);

// Apply promo code
router.post(
  '/apply',
  validateRequiredFields(['promo_code']),
  offersController.applyOffer
>>>>>>> backend-initial
);

module.exports = router;