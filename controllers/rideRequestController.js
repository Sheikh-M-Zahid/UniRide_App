const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const rideRequestService = require('../services/rideRequestService');

const createRequest = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.createRequest(
      req.user.userId,
      req.body
    );

    return successResponse(res, 'Ride request created successfully.', data, 201);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to create ride request.', 400);
  }
});

const getRequestStatus = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.getRequestStatus(
      req.user.userId,
      req.params.requestId
    );

    return successResponse(res, 'Ride request status fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch request status.', 400);
  }
});

const cancelRequest = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.cancelRequest(
      req.user.userId,
      req.params.requestId,
      req.body.cancelReason || null
    );

    return successResponse(res, 'Ride request cancelled successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to cancel request.', 400);
  }
});

const acceptRequest = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.acceptRequest(
      req.user.userId,
      req.params.requestId
    );

    return successResponse(res, 'Ride request accepted successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to accept request.', 400);
  }
});

const rejectRequest = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.rejectRequest(
      req.user.userId,
      req.params.requestId,
      req.body.cancelReason || null
    );

    return successResponse(res, 'Ride request rejected successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to reject request.', 400);
  }
});

const getPassengerActiveRequest = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.getPassengerActiveRequest(
      req.user.userId
    );
    return successResponse(res, 'Active request fetched.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed.', 400);
  }
});

const getRiderLiveLocation = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.getRiderLiveLocation(
      req.user.userId,
      req.params.requestId
    );
    return successResponse(res, 'Rider location fetched.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed.', 400);
  }
});

const getRiderDashboard = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.getRiderDashboard(req.user.userId);
    return successResponse(res, 'Rider dashboard fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch dashboard.', 400);
  }
});

const getScoredPendingRequests = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.getScoredPendingRequestsForRider(req.user.userId);
    return successResponse(res, 'Pending requests fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch pending requests.', 400);
  }
});

const cancelAcceptedParticipant = asyncHandler(async (req, res) => {
  try {
    const data = await rideRequestService.cancelAcceptedParticipant(
      req.user.userId,
      req.params.requestId,
      req.body.cancelReason || null
    );
    return successResponse(res, 'Confirmed ride cancelled successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to cancel confirmed ride.', 400);
  }
});

module.exports = {
  createRequest,
  getRequestStatus,
  cancelRequest,
  acceptRequest,
  rejectRequest,
  getPassengerActiveRequest,
  getRiderLiveLocation,
  getRiderDashboard,
  getScoredPendingRequests,
  cancelAcceptedParticipant,
};
