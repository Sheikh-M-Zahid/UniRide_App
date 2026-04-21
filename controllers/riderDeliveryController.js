const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/riderDeliveryService');

const getDashboard = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const data = await service.getDashboard({ riderId });

    return successResponse(res, 'Delivery dashboard fetched successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

const acceptRequest = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const io = req.app.get('io');

    const data = await service.acceptRequest({
      riderId,
      requestId: req.params.id,
      io,
    });

    return successResponse(res, 'Delivery request accepted successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

const rejectRequest = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const io = req.app.get('io');

    const data = await service.rejectRequest({
      riderId,
      requestId: req.params.id,
      io,
    });

    return successResponse(res, 'Delivery request rejected successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

const markDelivered = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const io = req.app.get('io');

    const data = await service.markDelivered({
      riderId,
      id: req.params.id,
      io,
    });

    return successResponse(res, 'Delivery marked as delivered successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

module.exports = {
  getDashboard,
  acceptRequest,
  rejectRequest,
  markDelivered,
};