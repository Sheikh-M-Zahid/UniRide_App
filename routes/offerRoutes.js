const express = require('express');
const router = express.Router();

const offersController = require('../controllers/offersController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');
const authMiddleware = require('../middlewares/authMiddleware');
const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');

// User routes
router.get('/active', authMiddleware, offersController.getActiveOffers);
router.get('/active-count', authMiddleware, offersController.getActiveOffersCount);

router.post(
  '/apply',
  authMiddleware,
  validateRequiredFields(['promo_code', 'fare']),
  offersController.applyOffer
);

// Admin routes
router.post(
  '/create',
  adminAuthMiddleware,
  validateRequiredFields([
    'offer_name',
    'offer_type',
    'reward_percentage',
    'eligible_user',
    'start_date',
    'end_date',
    'promo_code',
    'conditions',
  ]),
  offersController.createOffer
);

router.get('/all', adminAuthMiddleware, offersController.getAllOffers);

module.exports = router;