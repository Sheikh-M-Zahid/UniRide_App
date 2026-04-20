const express = require('express');
const router = express.Router();
const companySharingController = require('../controllers/companySharingController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['start_location', 'destination']),
  companySharingController.createSession
);

router.post('/:sessionId/join', authMiddleware, companySharingController.joinSession);
router.get('/', authMiddleware, companySharingController.listSessions);

router.post(
  '/:sessionId/chat',
  authMiddleware,
  validateRequiredFields(['message_text']),
  companySharingController.sendCompanyChatMessage
);

router.get('/:sessionId/chat', authMiddleware, companySharingController.fetchCompanyChatMessages);

module.exports = router;