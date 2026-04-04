const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const riderVehicleSelectionController = require('../controllers/riderVehicleSelectionController');

router.use(authMiddleware);

router.get('/status', riderVehicleSelectionController.getVehicleSelectionStatus);
router.post('/select', riderVehicleSelectionController.selectVehicleType);

module.exports = router;