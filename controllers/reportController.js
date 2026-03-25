const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const reportService = require('../services/reportService');

const submitReport = asyncHandler(async (req, res) => {
  const data = await reportService.submitReport(
    req.user.userId,
    req.user.email,
    req.body.comment
  );
  return successResponse(res, 'Report submitted successfully.', data, 201);
});

const listMyReports = asyncHandler(async (req, res) => {
  const data = await reportService.listMyReports(req.user.userId);
  return successResponse(res, 'Reports fetched successfully.', data);
});

module.exports = {
  submitReport,
  listMyReports,
};