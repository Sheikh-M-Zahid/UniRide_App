const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const controller = require('../controllers/appStatsController');

router.use(adminAuthMiddleware);

router.get('/', controller.getAppStats);

module.exports = router;