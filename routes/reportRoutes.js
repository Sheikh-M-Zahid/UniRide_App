const express = require('express');
const router = express.Router();

const reportController = require('../controllers/reportController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

// Submit report
router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['comment']),
  reportController.submitReport
);

// Get my reports
router.get(
  '/my',
  authMiddleware,
  reportController.getMyReports
);

module.exports = router;