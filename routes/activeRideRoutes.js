const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const activeRideController = require('../controllers/activeRideController');

router.get('/', authMiddleware, activeRideController.getActiveRideDashboard);
router.patch('/toggle', authMiddleware, activeRideController.toggleActiveRideStatus);

module.exports = router;