const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post('/', authMiddleware, validateRequiredFields(['comment']), reportController.submitReport);
router.get('/my', authMiddleware, reportController.listMyReports);

module.exports = router;