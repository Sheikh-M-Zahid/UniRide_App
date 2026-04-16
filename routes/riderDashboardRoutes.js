const express = require('express');
const router = express.Router();

const riderDashboardController = require('../controllers/riderDashboardController');
const authMiddleware = require('../middlewares/authMiddleware');

router.use(authMiddleware);

router.get('/', riderDashboardController.getRiderDashboard);
router.patch('/status', riderDashboardController.updateRiderStatus);

module.exports = router;
