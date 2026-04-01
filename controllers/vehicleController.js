const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const vehicleService = require('../services/vehicleService');

/* =========================
   CREATE VEHICLE
========================= */
const createVehicle = asyncHandler(async (req, res) => {
  const data = await vehicleService.createVehicle(
    req.user.userId,
    req.body,
    req.files
  );

  return successResponse(res, 'Vehicle added successfully.', data, 201);
});

/* =========================
   GET MY VEHICLES
========================= */
const getMyVehicles = asyncHandler(async (req, res) => {
  const data = await vehicleService.getMyVehicles(req.user.userId);

  return successResponse(res, 'Vehicles fetched successfully.', data);
});

/* =========================
   UPDATE VEHICLE
========================= */
const updateVehicle = asyncHandler(async (req, res) => {
  const data = await vehicleService.updateVehicle(
    req.user.userId,
    req.params.vehicleId,
    req.body
  );

  return successResponse(res, 'Vehicle updated successfully.', data);
});

/* =========================
   VERIFICATION STATUS
========================= */
const getVehicleVerificationStatus = asyncHandler(async (req, res) => {
  const data = await vehicleService.getVehicleVerificationStatus(
    req.user.userId
  );

  return successResponse(
    res,
    'Vehicle verification status fetched successfully.',
    data
  );
});

module.exports = {
  createVehicle,
  getMyVehicles,
  updateVehicle,
  getVehicleVerificationStatus,
};