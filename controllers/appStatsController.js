const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/appStatsService');

const getAppStats = async (req, res) => {
  try {
    const data = await service.getAppStats();

    return successResponse(
      res,
      'App statistics fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getAppStats error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch app stats.',
      500
    );
  }
};

module.exports = {
  getAppStats,
};