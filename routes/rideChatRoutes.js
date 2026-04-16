const express = require('express');
const router = express.Router();
const rideChatController = require('../controllers/rideChatController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/:rideId',
  authMiddleware,
  validateRequiredFields(['message_text']),
  rideChatController.sendMessage
);

router.get('/:rideId', authMiddleware, rideChatController.getChatMessagesByRide);

module.exports = router;