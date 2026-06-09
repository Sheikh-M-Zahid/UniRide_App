const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const riderMapController = require('../controllers/riderMapController');

router.use(authMiddleware);

router.get('/dashboard', riderMapController.getMapDashboard);
router.get('/route-polyline', riderMapController.getRoutePolyline);
router.post('/location', riderMapController.updateLocation);
router.post('/ride-requests/:requestId/accept', riderMapController.acceptRequest);
router.post('/ride/:rideId/start-navigation', riderMapController.startNavigation);
router.post('/ride/:rideId/complete', riderMapController.completeRideFromMap);

module.exports = router;
