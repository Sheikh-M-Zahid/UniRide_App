const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/adminRiderService');

const getAllRiders = async (req, res) => {
  try {
    const data = await service.getAllRiders(req.query);

    return successResponse(res, 'Riders fetched successfully.', data);
  } catch (error) {
    console.error('getAllRiders error:', error);
    return errorResponse(res, error.message, 500);
  }
};

const updateRiderStatus = async (req, res) => {
  try {
    const data = await service.updateRiderStatus({
      userId: req.params.id,
      status: req.body.status,
    });

    return successResponse(res, 'Rider status updated successfully.', data);
  } catch (error) {
    console.error('updateRiderStatus error:', error);
    return errorResponse(res, error.message, 400);
  }
};

module.exports = {
  getAllRiders,
  updateRiderStatus,
};