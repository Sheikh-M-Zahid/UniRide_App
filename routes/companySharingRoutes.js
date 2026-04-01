const express = require('express');
const router = express.Router();

const controller = require('../controllers/companySharingController');
const authMiddleware = require('../middlewares/authMiddleware');

// Create sharing session
router.post('/create', authMiddleware, controller.createSession);

// Get active sessions
router.get('/active', authMiddleware, controller.getActiveSessions);

// Get history
router.get('/history', authMiddleware, controller.getHistory);

module.exports = router;