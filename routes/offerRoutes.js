const express = require('express');
const router = express.Router();
const offerController = require('../controllers/offerController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/active', authMiddleware, offerController.getActiveOffers);

router.get('/active-count', authMiddleware, offerController.getActiveOfferCount);

router.post(
  '/validate-promo',
  authMiddleware,
  validateRequiredFields(['promo_code']),
  offerController.validatePromoCode
);

module.exports = router;