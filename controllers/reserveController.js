const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const reserveService = require('../services/reserveService');

const getUpcomingReserve = asyncHandler(async (req, res) => {
  const data = await reserveService.getUpcomingReserve(req.user.userId);

  const message =
    data.length > 0
      ? 'Upcoming reserves fetched successfully'
      : 'No active booking found';

  return successResponse(res, message, data);
});

module.exports = {
  getUpcomingReserve,
};