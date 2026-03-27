const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicleController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['vehicle_type', 'company', 'model', 'year', 'number_plate']),
  vehicleController.addVehicle
);

router.get('/my', authMiddleware, vehicleController.getMyVehicles);
router.put('/:vehicleId', authMiddleware, vehicleController.updateVehicle);
router.get('/verification-status', authMiddleware, vehicleController.getVehicleVerificationStatus);

module.exports = router;