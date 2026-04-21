const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminVehicleService = require('../services/adminVehicleService');
const { buildFileUrl } = require('../utils/fileUrl');

const mapVehicleImages = (req, item) => ({
  ...item,
  universityIdImage: buildFileUrl(req, item.universityIdImage),
  profilePhoto: buildFileUrl(req, item.profilePhoto),
  drivingLicenseImage: buildFileUrl(req, item.drivingLicenseImage),
  registrationPaperImage: buildFileUrl(req, item.registrationPaperImage),
  taxTokenImage: buildFileUrl(req, item.taxTokenImage),
});

const getPendingVehicleRequests = async (req, res) => {
  try {
    const search = req.query.search || '';
    const data = await adminVehicleService.getPendingVehicleRequests(search);

    const formatted = data.map((item) => mapVehicleImages(req, item));

    return successResponse(
      res,
      'Pending rider verification requests fetched successfully.',
      formatted
    );
  } catch (error) {
    console.error('getPendingVehicleRequests error:', error);
    return errorResponse(res, error.message || 'Failed to fetch requests', 400);
  }
};

const getVehicleRequestDetails = async (req, res) => {
  try {
    const { vehicleId } = req.params;
    const data = await adminVehicleService.getVehicleRequestDetails(vehicleId);

    return successResponse(
      res,
      'Vehicle request details fetched successfully.',
      mapVehicleImages(req, data)
    );
  } catch (error) {
    console.error('getVehicleRequestDetails error:', error);
    return errorResponse(res, error.message || 'Failed to fetch request details', 400);
  }
};

const approveVehicleRequest = async (req, res) => {
  try {
    const { vehicleId } = req.params;
    const adminUserId = req.user.userId || req.user.user_id;

    const data = await adminVehicleService.approveVehicleRequest(vehicleId, adminUserId);

    return successResponse(res, 'Rider verification approved successfully.', data);
  } catch (error) {
    console.error('approveVehicleRequest error:', error);
    return errorResponse(res, error.message || 'Failed to approve request', 400);
  }
};

const rejectVehicleRequest = async (req, res) => {
  try {
    const { vehicleId } = req.params;
    const adminUserId = req.user.userId || req.user.user_id;
    const { reason } = req.body;

    const data = await adminVehicleService.rejectVehicleRequest(vehicleId, adminUserId, reason);

    return successResponse(res, 'Rider verification rejected successfully.', data);
  } catch (error) {
    console.error('rejectVehicleRequest error:', error);
    return errorResponse(res, error.message || 'Failed to reject request', 400);
  }
};

module.exports = {
  getPendingVehicleRequests,
  getVehicleRequestDetails,
  approveVehicleRequest,
  rejectVehicleRequest,
};