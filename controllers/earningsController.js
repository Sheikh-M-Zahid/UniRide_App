const { successResponse, errorResponse } = require('../utils/apiResponse');
const earningsService = require('../services/earningsService');

const getEarningsDashboard = async (req, res) => {
  try {
    const { range = 'today' } = req.query;

    const data = await earningsService.getEarningsDashboard({
      userId: req.user.userId,
      range,
    });

    return successResponse(res, 'Earnings dashboard fetched successfully.', data);
  } catch (error) {
    console.error('getEarningsDashboard error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch earnings dashboard.',
      500
    );
  }
};

module.exports = {
  getEarningsDashboard,
};