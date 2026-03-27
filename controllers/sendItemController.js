const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const sendItemService = require('../services/sendItemService');

const createSendItemRequest = asyncHandler(async (req, res) => {
  const data = await sendItemService.createSendItemRequest(req.user.userId, req.body);
  return successResponse(res, 'Send item request created successfully.', data, 201);
});

const listSendItemRequests = asyncHandler(async (req, res) => {
  const data = await sendItemService.listSendItemRequests(req.user.userId);
  return successResponse(res, 'Send item requests fetched successfully.', data);
});

const acceptItemRequest = asyncHandler(async (req, res) => {
  const data = await sendItemService.updateSendItemStatus(
    req.params.sId,
    req.user.userId,
    'Accepted'
  );
  return successResponse(res, 'Item request accepted successfully.', data);
});

const cancelItemRequest = asyncHandler(async (req, res) => {
  const data = await sendItemService.updateSendItemStatus(
    req.params.sId,
    req.user.userId,
    'Cancelled'
  );
  return successResponse(res, 'Item request cancelled successfully.', data);
});

const deliverItemRequest = asyncHandler(async (req, res) => {
  const data = await sendItemService.updateSendItemStatus(
    req.params.sId,
    req.user.userId,
    'Delivered'
  );
  return successResponse(res, 'Item request delivered successfully.', data);
});

module.exports = {
  createSendItemRequest,
  listSendItemRequests,
  acceptItemRequest,
  cancelItemRequest,
  deliverItemRequest,
};