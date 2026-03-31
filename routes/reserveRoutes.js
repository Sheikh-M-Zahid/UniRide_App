const express = require('express');
const router = express.Router();

const reserveController = require('../controllers/reserveController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/upcoming', authMiddleware, reserveController.getUpcomingReserve);

module.exports = router;