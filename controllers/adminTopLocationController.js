const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/adminTopLocationService');

const getTopLocationStats = async (req, res) => {
  try {
    const data = await service.getTopLocationStats();

    return successResponse(
      res,
      'Top location stats fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getTopLocationStats error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch location stats.',
      500
    );
  }
};

module.exports = {
  getTopLocationStats,
};