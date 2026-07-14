const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const controller = require('../controllers/adminSafetyController');

router.get('/', authMiddleware, controller.getReports);

module.exports = router;
