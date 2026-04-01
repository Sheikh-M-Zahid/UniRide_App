const express = require('express');
const router = express.Router();

const controller = require('../controllers/companyMessageController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get(
  '/:sessionId/chats',
  authMiddleware,
  controller.getMessages
);

router.post(
  '/:sessionId/chats',
  authMiddleware,
  controller.sendMessage
);

module.exports = router;