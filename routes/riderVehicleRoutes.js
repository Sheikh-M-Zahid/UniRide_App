const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const controller = require('../controllers/riderVehicleController');

router.use(auth);

router.get('/', controller.getMyVehicles);
router.get('/:id/documents', controller.getVehicleDocuments);

module.exports = router;