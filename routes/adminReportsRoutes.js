const express = require('express');
const router = express.Router();

const controller = require('../controllers/adminReportsController');
const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');

router.use(adminAuthMiddleware);

// Get all reports
router.get('/', controller.getAllReports);

// Mark as solved
router.patch('/:reportId/solve', controller.markAsSolved);

module.exports = router;