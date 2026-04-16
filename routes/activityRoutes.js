const express = require('express');
const router = express.Router();

const activityController = require('../controllers/activityController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/my', authMiddleware, activityController.getMyActivity);
router.get('/dashboard', authMiddleware, activityController.getActivityDashboard);

module.exports = router;