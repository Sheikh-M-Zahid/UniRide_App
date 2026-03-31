const express = require('express');
const router = express.Router();

const rideHistoryController = require('../controllers/rideHistoryController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/history', authMiddleware, rideHistoryController.getRideHistory);

module.exports = router;