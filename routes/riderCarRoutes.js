const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');
const controller = require('../controllers/riderCarController');

router.use(auth);

router.post(
  '/register',
  upload.fields([
    { name: 'varsity_id_photo', maxCount: 1 },
    { name: 'driver_profile_photo', maxCount: 1 },
    { name: 'driving_license_photo', maxCount: 1 },
    { name: 'vehicle_registration_photo', maxCount: 1 },
    { name: 'tax_token_photo', maxCount: 1 },
  ]),
  controller.registerCar
);

module.exports = router;