const express = require('express');
const router = express.Router();
const controller = require('../controllers/companySharingController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['start_location', 'destination']),
  controller.createSession
);

router.get('/my-active', authMiddleware, controller.getMyActiveSession);
router.get('/:sessionId', authMiddleware, controller.getSessionById);
router.post('/:sessionId/join', authMiddleware, controller.joinSession);
router.patch('/:sessionId/cancel', authMiddleware, controller.cancelSession);
router.patch('/:sessionId/start', authMiddleware, controller.startSession);
router.post('/:sessionId/location', authMiddleware, controller.updateLiveLocation);
router.get('/:sessionId/location', authMiddleware, controller.getLiveLocation);
router.get('/', authMiddleware, controller.listSessions);

router.post(
  '/:sessionId/chat',
  authMiddleware,
  validateRequiredFields(['message_text']),
  controller.sendCompanyChatMessage
);
router.get('/:sessionId/chat', authMiddleware, controller.fetchCompanyChatMessages);

module.exports = router;
