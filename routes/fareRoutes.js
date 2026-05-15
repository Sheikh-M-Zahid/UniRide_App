const express = require('express');
const router  = express.Router();

const { getFareSettings, updateFareSettings, getActiveFare } = require('../controllers/fareControllers');
const verifyToken = require('../middlewares/authMiddleware');

// Admin only
router.get('/settings', verifyToken, getFareSettings);
router.put('/settings', verifyToken, updateFareSettings);

// Passenger/Rider (যেকোনো logged-in user)
router.get('/active/:vehicleType', verifyToken, getActiveFare);

module.exports = router;
