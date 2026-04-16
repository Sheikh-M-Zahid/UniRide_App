const { successResponse, errorResponse } = require('../utils/apiResponse');
const activeRiderService = require('../services/activeRiderService');

const getActiveRiders = async (req, res) => {
  try {
    const {
      search = '',
      filter = 'all_active',
      location = '',
      page = 1,
      limit = 20,
    } = req.query;

    const result = await activeRiderService.getActiveRiders({
      search,
      filter,
      location,
      page: Number(page),
      limit: Number(limit),
    });

    return successResponse(res, 'Active riders fetched successfully.', result);
  } catch (error) {
    console.error('getActiveRiders error:', error);
    return errorResponse(res, error.message, 500);
  }
};

module.exports = {
  getActiveRiders,
};