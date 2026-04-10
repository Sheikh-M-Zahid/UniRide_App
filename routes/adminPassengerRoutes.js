const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const adminPassengerController = require('../controllers/adminPassengerController');

router.use(adminAuthMiddleware);

router.get('/', adminPassengerController.getAllPassengers);

module.exports = router;