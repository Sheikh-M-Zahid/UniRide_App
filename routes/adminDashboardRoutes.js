const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const adminDashboardController = require('../controllers/adminDashboardController');

router.use(adminAuthMiddleware);

router.get('/', adminDashboardController.getDashboardSummary);

module.exports = router;