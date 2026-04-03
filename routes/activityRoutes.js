const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const activityController = require('../controllers/activityController');

router.get('/', authMiddleware, activityController.getActivityDashboard);

module.exports = router;