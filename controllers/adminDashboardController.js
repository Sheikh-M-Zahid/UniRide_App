const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminDashboardService = require('../services/adminDashboardService');

const getDashboardSummary = async (req, res) => {
  try {
    const adminId = req.admin.id;

    const data = await adminDashboardService.getDashboardSummary({ adminId, req });

    return successResponse(res, 'Admin dashboard fetched successfully.', data);
  } catch (error) {
    console.error('getDashboardSummary error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch admin dashboard.',
      500
    );
  }
};

module.exports = {
  getDashboardSummary,
};