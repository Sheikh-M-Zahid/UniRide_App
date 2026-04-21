const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const adminAuth = require('../middlewares/adminAuthMiddleware');
const controller = require('../controllers/adminVehicleController');

router.use(auth, adminAuth);

router.get('/rider-verifications', controller.getPendingVehicleRequests);
router.get('/rider-verifications/:vehicleId', controller.getVehicleRequestDetails);
router.patch('/rider-verifications/:vehicleId/approve', controller.approveVehicleRequest);
router.patch('/rider-verifications/:vehicleId/reject', controller.rejectVehicleRequest);

module.exports = router;