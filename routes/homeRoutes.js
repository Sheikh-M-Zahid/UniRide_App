const express = require('express');
const router = express.Router();
const homeController = require('../controllers/homeController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get(
  '/passenger-summary',
  authMiddleware,
  homeController.getPassengerSummary
);

router.get(
  '/notifications',
  authMiddleware,
  homeController.getNotifications
);

module.exports = router;