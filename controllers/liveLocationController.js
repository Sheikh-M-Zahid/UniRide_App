const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const liveLocationService = require('../services/liveLocationService');

const updateLiveLocation = asyncHandler(async (req, res) => {
  const data = await liveLocationService.updateLiveLocation(
    req.user.userId,
    req.body.ride_id,
    req.body.latitude,
    req.body.longitude
  );
  return successResponse(res, 'Live location updated successfully.', data);
});

const getRideLiveLocations = asyncHandler(async (req, res) => {
  const data = await liveLocationService.getRideLiveLocations(req.params.rideId);
  return successResponse(res, 'Live locations fetched successfully.', data);
});

module.exports = {
  updateLiveLocation,
  getRideLiveLocations,
};