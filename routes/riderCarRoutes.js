const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const { vehicleUpload } = require('../middlewares/uploadMiddleware');
const controller = require('../controllers/riderCarController');

router.use(auth);

router.post(
  '/register',
  vehicleUpload,
  controller.registerCar
);

module.exports = router;