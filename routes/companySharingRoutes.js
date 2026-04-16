const express = require('express');
const router = express.Router();

const companySharingController = require('../controllers/companySharingController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

// Create sharing session
router.post(
  '/create',
  authMiddleware,
  validateRequiredFields(['start_location', 'destination']),
  companySharingController.createSession
);

// Get active sessions
router.get('/active', authMiddleware, companySharingController.getActiveSessions);

// Get sharing history
router.get('/history', authMiddleware, companySharingController.getHistory);

// List all sessions
router.get('/', authMiddleware, companySharingController.listSessions);

// Join a session
router.post(
  '/:sessionId/join',
  authMiddleware,
  companySharingController.joinSession
);

// Send company chat message
router.post(
  '/:sessionId/chat',
  authMiddleware,
  validateRequiredFields(['message_text']),
  companySharingController.sendCompanyChatMessage
);

// Fetch company chat messages
router.get(
  '/:sessionId/chat',
  authMiddleware,
  companySharingController.fetchCompanyChatMessages
);

module.exports = router;