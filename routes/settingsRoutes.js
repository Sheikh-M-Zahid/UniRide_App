const express = require('express');
const router = express.Router();

const settingsController = require('../controllers/settingsController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get(
  '/summary',
  authMiddleware,
  settingsController.getSettingsSummary
);

module.exports = router;