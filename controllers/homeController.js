const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const homeService = require('../services/homeService');

const getPassengerSummary = asyncHandler(async (req, res) => {
  const data = await homeService.getPassengerSummary(req.user.userId);

  return successResponse(
    res,
    'Passenger home summary fetched successfully',
    data
  );
});

const getNotifications = asyncHandler(async (req, res) => {
  const data = await homeService.getNotifications();

  return successResponse(
    res,
    'Notifications fetched successfully',
    data
  );
});

module.exports = {
  getPassengerSummary,
  getNotifications,
};