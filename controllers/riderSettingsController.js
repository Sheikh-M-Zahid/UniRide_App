const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderSettingsService = require('../services/riderSettingsService');

const getSettingsSummary = async (req, res) => {
  try {
    const userId = req.user.userId;

    const data = await riderSettingsService.getSettingsSummary({
      userId,
      req,
    });

    return successResponse(res, 'Settings summary fetched successfully.', data);
  } catch (error) {
    console.error('getSettingsSummary error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch settings summary.',
      500
    );
  }
};

module.exports = {
  getSettingsSummary,
};