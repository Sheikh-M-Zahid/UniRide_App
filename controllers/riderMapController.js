const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderMapService = require('../services/riderMapService');

const getMapDashboard = async (req, res) => {
  try {
    const riderId = req.user.userId;

    const data = await riderMapService.getMapDashboard({ riderId });

    return successResponse(res, 'Map data fetched', data);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

const updateLocation = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const io = req.app.get('io');

    const data = await riderMapService.updateLocation({
      riderId,
      body: req.body,
      io,
    });

    return successResponse(res, 'Location updated', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

const acceptRequest = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const io = req.app.get('io');

    const data = await riderMapService.acceptRequest({
      riderId,
      requestId: req.params.requestId,
      io,
    });

    return successResponse(res, 'Request accepted', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

const startNavigation = async (req, res) => {
  try {
    const riderId = req.user.userId;

    const data = await riderMapService.startNavigation({
      riderId,
      rideId: req.params.rideId,
    });

    return successResponse(res, 'Navigation started', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

const getRoutePolyline = async (req, res) => {
  try {
    const { originLat, originLng, destinationLat, destinationLng } = req.query;

    if (!originLat || !originLng || !destinationLat || !destinationLng) {
      return errorResponse(res, 'originLat, originLng, destinationLat, destinationLng required', 400);
    }

    const data = await riderMapService.getRoutePolyline({
      originLat, originLng, destinationLat, destinationLng,
    });

    return successResponse(res, 'Route fetched', data);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

// ✅ Passenger tracking map এ rider এর confirm করা exact route দেখানোর জন্য
const getSavedRoutePolyline = async (req, res) => {
  try {
    const userId = req.user.userId;

    const data = await riderMapService.getSavedRoutePolyline({
      userId,
      rideId: req.params.rideId,
    });

    return successResponse(res, 'Saved route fetched', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

const completeRideFromMap = async (req, res) => {
  try {
    const riderId = req.user.userId;

    const data = await riderMapService.completeRideFromMap({
      riderId,
      rideId: req.params.rideId,
    });

    return successResponse(res, 'Ride completed successfully', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

module.exports = {
  getMapDashboard,
  updateLocation,
  acceptRequest,
  startNavigation,
  getRoutePolyline,
  getSavedRoutePolyline,
  completeRideFromMap,
};
