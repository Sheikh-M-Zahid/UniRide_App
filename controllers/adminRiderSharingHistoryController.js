const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminRiderSharingHistoryService = require('../services/adminRiderSharingHistoryService');

const getRiderSharingHistory = async (req, res) => {
  try {
    const {
      search = '',
      status = 'all',
      page = 1,
      limit = 20,
    } = req.query;

    const data = await adminRiderSharingHistoryService.getRiderSharingHistory({
      search,
      status,
      page: Number(page),
      limit: Number(limit),
      req,
    });

    return successResponse(
      res,
      'Rider sharing history fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getRiderSharingHistory error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch rider sharing history.',
      500
    );
  }
};

module.exports = {
  getRiderSharingHistory,
};