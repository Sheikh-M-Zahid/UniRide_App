const express = require('express');
const router = express.Router();

const adminAuth = require('../middlewares/adminAuthMiddleware');
const controller = require('../controllers/adminRiderController');

router.use(adminAuth);

router.get('/', controller.getAllRiders);
router.patch('/:id/status', controller.updateRiderStatus);

module.exports = router;