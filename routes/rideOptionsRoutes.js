const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const rideOptionsController = require('../controllers/rideOptionsController');

router.post('/', authMiddleware, rideOptionsController.getRideOptions);

module.exports = router;