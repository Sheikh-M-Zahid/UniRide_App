const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const controller = require('../controllers/riderVerificationController');

router.use(auth);

router.get('/status', controller.getMyRiderVerificationStatus);

module.exports = router;