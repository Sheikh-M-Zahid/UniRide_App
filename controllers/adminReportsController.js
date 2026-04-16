const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/adminReportsService');

const getAllReports = asyncHandler(async (req, res) => {
  const data = await service.getAllReports();

  return successResponse(
    res,
    'Reports fetched successfully.',
    data
  );
});

const markAsSolved = asyncHandler(async (req, res) => {
  const { reportId } = req.params;

  try {
    const data = await service.markAsSolved(reportId);

    return successResponse(
      res,
      'Report marked as solved.',
      data
    );
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
});

module.exports = {
  getAllReports,
  markAsSolved,
};