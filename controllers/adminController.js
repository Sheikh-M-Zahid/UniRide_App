const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const adminService = require('../services/adminService');

const adminLogin = asyncHandler(async (req, res) => {
  const data = await adminService.adminLogin(req.body.email, req.body.password);
  return successResponse(res, 'Admin login successful.', data);
});

const listUsers = asyncHandler(async (req, res) => {
  const data = await adminService.listUsers();
  return successResponse(res, 'Users fetched successfully.', data);
});

const viewReports = asyncHandler(async (req, res) => {
  const data = await adminService.listAllReports();
  return successResponse(res, 'Reports fetched successfully.', data);
});

const markReportSolved = asyncHandler(async (req, res) => {
  const data = await adminService.markReportSolved(req.params.reportId);
  return successResponse(res, 'Report marked as solved.', data);
});

const createOffer = asyncHandler(async (req, res) => {
  const data = await adminService.createOffer(req.body);
  return successResponse(res, 'Offer created successfully.', data, 201);
});

const listOffers = asyncHandler(async (req, res) => {
  const data = await adminService.listOffers();
  return successResponse(res, 'Offers fetched successfully.', data);
});

const suspendUser = asyncHandler(async (req, res) => {
  const data = await adminService.suspendOrActivateUser(req.params.userId, 'Suspended');
  return successResponse(res, 'User suspended successfully.', data);
});

const activateUser = asyncHandler(async (req, res) => {
  const data = await adminService.suspendOrActivateUser(req.params.userId, 'Active');
  return successResponse(res, 'User activated successfully.', data);
});

module.exports = {
  adminLogin,
  listUsers,
  viewReports,
  markReportSolved,
  createOffer,
  listOffers,
  suspendUser,
  activateUser,
};