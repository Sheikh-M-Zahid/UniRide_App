const express = require('express');
const router = express.Router();

const controller = require('../controllers/companyChatRoomController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/:sessionId/chats', authMiddleware, controller.getMessages);

router.post('/:sessionId/chats', authMiddleware, controller.sendMessage);

router.patch('/:sessionId/chats/read', authMiddleware, controller.markAsRead);

module.exports = router;