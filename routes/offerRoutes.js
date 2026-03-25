const express = require('express');
const router = express.Router();
const offerController = require('../controllers/offerController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.get('/active', offerController.getActiveOffers);
router.post('/validate-promo', validateRequiredFields(['promo_code']), offerController.validatePromoCode);

module.exports = router;