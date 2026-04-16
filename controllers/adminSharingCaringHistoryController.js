const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminSharingCaringHistoryService = require('../services/adminSharingCaringHistoryService');

const getSharingCaringHistory = async (req, res) => {
  try {
    const {
      search = '',
      status = 'all',
      safety = 'all',
      page = 1,
      limit = 20,
    } = req.query;

    const data = await adminSharingCaringHistoryService.getSharingCaringHistory({
      search,
      status,
      safety,
      page: Number(page),
      limit: Number(limit),
      req,
    });

    return successResponse(
      res,
      'Sharing & Caring history fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getSharingCaringHistory error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch sharing & caring history.',
      500
    );
  }
};

module.exports = {
  getSharingCaringHistory,
};