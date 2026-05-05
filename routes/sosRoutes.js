const express = require('express');
const router = express.Router();
const controller = require('../controllers/sosController');
const authMiddleware = require('../middlewares/authMiddleware');

// Auth লাগবে
router.post('/coride/host',        authMiddleware, controller.coRideSosHost);
router.post('/coride/participant',  authMiddleware, controller.coRideSosParticipant);
router.post('/rider',               authMiddleware, controller.riderSos);
router.post('/passenger',           authMiddleware, controller.passengerSos);

// Public — emergency contact এর link
router.get('/track/:token', controller.getSosTrackingInfo);

module.exports = router;
