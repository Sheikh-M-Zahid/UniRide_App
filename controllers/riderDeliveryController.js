const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/riderDeliveryService');

// =========================
// GET DELIVERY DASHBOARD
// =========================
const getDashboard = async (req, res) => {
  try {
    const riderId = req.user?.userId;

    if (!riderId) {
      return errorResponse(res, 'Unauthorized: Rider ID missing', 401);
    }

    const data = await service.getDashboard({ riderId });

    return successResponse(
      res,
      'Delivery dashboard fetched successfully.',
      data
    );
  } catch (err) {
    console.error('getDashboard error:', err);
    return errorResponse(res, err.message || 'Failed to fetch dashboard', 500);
  }
};

// =========================
// ACCEPT DELIVERY REQUEST
// =========================
const acceptRequest = async (req, res) => {
  try {
    const riderId = req.user?.userId;
    const requestId = req.params?.id;
    const io = req.app.get('io');

    if (!riderId || !requestId) {
      return errorResponse(res, 'Invalid request data', 400);
    }

    const data = await service.acceptRequest({
      riderId,
      requestId,
      io,
    });

    return successResponse(
      res,
      'Delivery request accepted successfully.',
      data
    );
  } catch (err) {
    console.error('acceptRequest error:', err);
    return errorResponse(res, err.message || 'Failed to accept request', 400);
  }
};

// =========================
// REJECT DELIVERY REQUEST
// =========================
const rejectRequest = async (req, res) => {
  try {
    const riderId = req.user?.userId;
    const requestId = req.params?.id;
    const io = req.app.get('io');

    if (!riderId || !requestId) {
      return errorResponse(res, 'Invalid request data', 400);
    }

    const data = await service.rejectRequest({
      riderId,
      requestId,
      io,
    });

    return successResponse(
      res,
      'Delivery request rejected successfully.',
      data
    );
  } catch (err) {
    console.error('rejectRequest error:', err);
    return errorResponse(res, err.message || 'Failed to reject request', 400);
  }
};

// =========================
// MARK DELIVERY AS DELIVERED
// =========================
const sendDeliveryOtp = async (req, res) => {
  try {
    const riderId = req.user?.userId;
    const deliveryId = req.params?.id;

    if (!riderId || !deliveryId) {
      return errorResponse(res, 'Invalid request data', 400);
    }

    const data = await service.sendDeliveryOtp({ riderId, id: deliveryId });
    return successResponse(res, 'OTP sent to receiver.', data);
  } catch (err) {
    console.error('sendDeliveryOtp error:', err);
    return errorResponse(res, err.message || 'Failed to send OTP', 400);
  }
};

const markDelivered = async (req, res) => {
  try {
    const riderId = req.user?.userId;
    const deliveryId = req.params?.id;
    const otp = req.body?.otp;
    const io = req.app.get('io');

    if (!riderId || !deliveryId) {
      return errorResponse(res, 'Invalid request data', 400);
    }

    if (!otp) {
      return errorResponse(res, 'OTP is required', 400);
    }

    const data = await service.markDelivered({
      riderId,
      id: deliveryId,
      otp,
      io,
    });

    return successResponse(
      res,
      'Delivery marked as delivered successfully.',
      data
    );
  } catch (err) {
    console.error('markDelivered error:', err);
    return errorResponse(res, err.message || 'Failed to mark delivered', 400);
  }
};

// =========================
// MARK DELIVERY AS PICKED UP
// =========================
const markPickedUp = async (req, res) => {
  try {
    const riderId = req.user?.userId;
    const deliveryId = req.params?.id;
    const io = req.app.get('io');

    if (!riderId || !deliveryId) {
      return errorResponse(res, 'Invalid request data', 400);
    }

    const data = await service.markPickedUp({
      riderId,
      id: deliveryId,
      io,
    });

    return successResponse(
      res,
      'Delivery marked as picked up successfully.',
      data
    );
  } catch (err) {
    console.error('markPickedUp error:', err);
    return errorResponse(res, err.message || 'Failed to mark picked up', 400);
  }
};

module.exports = {
  getDashboard,
  acceptRequest,
  rejectRequest,
  sendDeliveryOtp,
  markDelivered,
  markPickedUp,
};
