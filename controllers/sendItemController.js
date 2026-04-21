const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const sendItemService = require('../services/sendItemService');

const validateReceiver = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.validateReceiver(req.body.receiver_email);
    return successResponse(res, 'Receiver found.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const createSendItemRequest = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.createSendItemRequest(
      req.user.userId,
      req.body
    );

    return successResponse(
      res,
      'Send item request created successfully.',
      data,
      201
    );
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const getAvailableSendItemRequests = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.getAvailableSendItemRequests(req.user.userId);
    return successResponse(res, 'Available send item requests fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const getMySentItems = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.getMySentItems(req.user.userId);
    return successResponse(res, 'My send item requests fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const getMyRiderSendItems = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.getMyRiderSendItems(req.user.userId);
    return successResponse(res, 'My rider send item jobs fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const getSenderItemDetails = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.getSenderItemDetails(req.params.sId, req.user.userId);
    return successResponse(res, 'Sender item details fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const getRiderItemDetails = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.getRiderItemDetails(req.params.sId, req.user.userId);
    return successResponse(res, 'Rider item details fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const acceptItemRequest = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.acceptItemRequest(
      req.params.sId,
      req.user.userId
    );

    return successResponse(res, 'Item request accepted successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const pickupItemRequest = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.pickupItemRequest(
      req.params.sId,
      req.user.userId
    );

    return successResponse(res, 'Item pickup confirmed successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const deliverItemRequest = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.deliverItemRequest(
      req.params.sId,
      req.user.userId
    );

    return successResponse(res, 'Item delivered successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const cancelItemRequest = asyncHandler(async (req, res) => {
  try {
    const data = await sendItemService.cancelItemRequest(
      req.params.sId,
      req.user.userId
    );

    return successResponse(res, 'Item request cancelled successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

module.exports = {
  validateReceiver,
  createSendItemRequest,
  getAvailableSendItemRequests,
  getMySentItems,
  getMyRiderSendItems,
  getSenderItemDetails,
  getRiderItemDetails,
  acceptItemRequest,
  pickupItemRequest,
  deliverItemRequest,
  cancelItemRequest,
};