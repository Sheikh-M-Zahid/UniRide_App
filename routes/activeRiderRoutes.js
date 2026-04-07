const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const activeRiderController = require('../controllers/activeRiderController');
const activeRideController = require('../controllers/activeRideController');

router.get('/', authMiddleware, activeRiderController.getActiveRiders);
router.patch('/toggle', authMiddleware, activeRideController.toggleActiveRideStatus);

module.exports = router;