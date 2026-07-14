const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const controller = require('../controllers/safetyCheckController');

router.patch('/:checkId/respond', authMiddleware, controller.respond);

module.exports = router;
