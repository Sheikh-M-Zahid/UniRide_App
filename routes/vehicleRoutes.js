const express = require('express');
const router = express.Router();

const vehicleController = require('../controllers/vehicleController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');
const { vehicleUpload } = require('../middlewares/uploadMiddleware');
const { uploadProfilePicture } = require('../middlewares/uploadMiddleware');
/* =========================
   ADD VEHICLE
========================= */
router.post(
  '/',
  authMiddleware,
  vehicleUpload,
  validateRequiredFields([
    'vehicle_type',
    'company',
    'model',
    'year',
    'number_plate',
    uploadProfilePicture,
  ]),
  vehicleController.createVehicle
);
/* =========================
   GET MY VEHICLES
========================= */
router.get(
  '/my',
  authMiddleware,
  vehicleController.getMyVehicles
);

/* =========================
   UPDATE VEHICLE
========================= */
router.put(
  '/:vehicleId',
  authMiddleware,
  vehicleController.updateVehicle
);

/* =========================
   VERIFICATION STATUS
========================= */
router.get(
  '/verification-status',
  authMiddleware,
  vehicleController.getVehicleVerificationStatus
);

module.exports = router;