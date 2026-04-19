const express = require('express');
const router = express.Router();

const reserveController = require('../controllers/reserveController');
const authMiddleware = require('../middlewares/authMiddleware');

// Create reserve (protected)
router.post('/create', authMiddleware, reserveController.createReserve);

// Get upcoming reserved rides (protected)
router.get('/upcoming', authMiddleware, reserveController.getUpcomingReserve);

router.patch(
  '/:reserveId/cancel',
  authMiddleware,
  reserveController.cancelReserve
);

router.patch(
  '/:reserveId/accept',
  authMiddleware,
  reserveController.assignRiderToReserve
);

// Calculate reserve ride (public)
router.post('/calculate', reserveController.calculateReserveRide);

// Validate schedule (protected)
router.post(
  '/validate-schedule',
  authMiddleware,
  reserveController.validateSchedule
);

// Validate preferences (protected)
router.post(
  '/validate-preferences',
  authMiddleware,
  reserveController.validatePreferences
);

module.exports = router;
