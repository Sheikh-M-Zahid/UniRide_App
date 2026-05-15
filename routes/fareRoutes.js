const express = require('express');
const router  = express.Router();

const { getFareSettings, updateFareSettings, getActiveFare } = require('../controllers/fareController');
const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

// Admin only
router.get('/settings',  verifyToken, isAdmin, getFareSettings);
router.put('/settings',  verifyToken, isAdmin, updateFareSettings);

// Passenger/Rider (যেকোনো logged-in user)
router.get('/active/:vehicleType', verifyToken, getActiveFare);

module.exports = router;
