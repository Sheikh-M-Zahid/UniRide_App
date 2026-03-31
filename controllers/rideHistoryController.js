const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const rideHistoryService = require('../services/rideHistoryService');

const getRideHistory = asyncHandler(async (req, res) => {
  const data = await rideHistoryService.getRideHistory(req.user.userId);

  const message =
    data.length > 0
      ? 'Ride history fetched successfully'
      : 'No ride history found';

  return successResponse(res, message, data);
});

module.exports = {
  getRideHistory,
};