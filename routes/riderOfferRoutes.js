const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const riderOfferController = require('../controllers/riderOfferControllers');

// GET /api/rider/offers
router.get('/', authMiddleware, riderOfferController.getRiderOffers);

module.exports = router;
