const express = require('express');
const router  = express.Router();
const {
  getFareSettings,
  updateFareSettings,
  getActiveFareForVehicle,
} = require('../controllers/fareController');
const { verifyToken, isAdmin } = require('../middleware/authMiddleware');

// Admin: GET current fare settings
router.get('/fare-settings', verifyToken, isAdmin, getFareSettings);

// Admin: PUT update fare settings
router.put('/fare-settings', verifyToken, isAdmin, updateFareSettings);

// Public: GET active fare by vehicle type
router.get('/active/:vehicleType', verifyToken, getActiveFareForVehicle);

module.exports = router;
