const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const reportService = require('../services/reportService');

// Submit report
const submitReport = asyncHandler(async (req, res) => {
  const data = await reportService.submitReport(
    req.user.userId,
    req.user.email,
    req.body.comment // ✅ validation middleware এর সাথে match
  );

  return successResponse(res, 'Report submitted successfully.', data, 201);
});

// Get my reports
const getMyReports = asyncHandler(async (req, res) => {
  const data = await reportService.getMyReports(req.user.userId);

  return successResponse(res, 'Reports fetched successfully.', data);
});

module.exports = {
  submitReport,
  getMyReports,
};