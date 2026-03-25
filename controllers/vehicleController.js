const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const vehicleService = require('../services/vehicleService');

const addVehicle = asyncHandler(async (req, res) => {
  const data = await vehicleService.addVehicle(req.user.userId, req.body);
  return successResponse(res, 'Vehicle added successfully.', data, 201);
});

const getMyVehicles = asyncHandler(async (req, res) => {
  const data = await vehicleService.getMyVehicles(req.user.userId);
  return successResponse(res, 'Vehicles fetched successfully.', data);
});

const updateVehicle = asyncHandler(async (req, res) => {
  const data = await vehicleService.updateVehicle(
    req.user.userId,
    req.params.vehicleId,
    req.body
  );
  return successResponse(res, 'Vehicle updated successfully.', data);
});

const getVehicleVerificationStatus = asyncHandler(async (req, res) => {
  const data = await vehicleService.getVehicleVerificationStatus(req.user.userId);
  return successResponse(res, 'Vehicle verification status fetched successfully.', data);
});

module.exports = {
  addVehicle,
  getMyVehicles,
  updateVehicle,
  getVehicleVerificationStatus,
};