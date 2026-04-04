const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const riderRideHistoryController = require('../controllers/riderRideHistoryController');

router.use(authMiddleware);

router.get('/', riderRideHistoryController.getRideHistory);

module.exports = router;