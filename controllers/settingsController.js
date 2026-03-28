const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const settingsService = require('../services/settingsService');

const getSettingsSummary = asyncHandler(async (req, res) => {
  const data = await settingsService.getSettingsSummary(req.user.userId);

  return successResponse(
    res,
    'Settings summary fetched successfully',
    data
  );
});

module.exports = {
  getSettingsSummary,
};