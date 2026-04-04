const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/riderVehicleService');

const getMyVehicles = async (req, res) => {
  try {
    const data = await service.getMyVehicles(req.user.userId);
    return successResponse(res, 'Vehicles fetched', data);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

const getVehicleDocuments = async (req, res) => {
  try {
    const data = await service.getVehicleDocuments({
      userId: req.user.userId,
      vehicleId: req.params.id,
      req,
    });

    return successResponse(res, 'Documents fetched', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

module.exports = {
  getMyVehicles,
  getVehicleDocuments,
};