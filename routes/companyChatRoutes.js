const express = require('express');
const router = express.Router();

const controller = require('../controllers/companyChatController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get(
  '/list',
  authMiddleware,
  controller.getChatList
);

module.exports = router;