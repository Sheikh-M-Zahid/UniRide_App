const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderVehicleSelectionService = require('../services/riderVehicleSelectionService');

const getVehicleSelectionStatus = async (req, res) => {
  try {
    const userId = req.user.userId;

    const data = await riderVehicleSelectionService.getVehicleSelectionStatus({ userId });

    return successResponse(res, 'Vehicle selection status fetched successfully.', data);
  } catch (error) {
    console.error('getVehicleSelectionStatus error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch vehicle selection status.',
      500
    );
  }
};

const selectVehicleType = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { selectedVehicleType } = req.body;

    const data = await riderVehicleSelectionService.selectVehicleType({
      userId,
      selectedVehicleType,
    });

    return successResponse(res, 'Vehicle type selection processed successfully.', data);
  } catch (error) {
    console.error('selectVehicleType error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to process vehicle type selection.',
      400
    );
  }
};

module.exports = {
  getVehicleSelectionStatus,
  selectVehicleType,
};