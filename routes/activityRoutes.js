const express = require('express');
const router = express.Router();

const activityController = require('../controllers/activityController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/me', authMiddleware, activityController.getMyActivity);

module.exports = router;