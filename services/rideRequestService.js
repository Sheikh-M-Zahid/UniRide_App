const rideDb = require('../config/rideDb');
const {
  emitRideRequestStatusUpdate,
  emitToRiderRoom,
  emitToPassengerRoom,
} = require('../utils/rideRequestEmitter');

const REQUEST_TIMEOUT_SECONDS = 60;

const mapRequestResponse = (row) => ({
  requestId: row.request_id,
  rideId: row.ride_id,
  passengerId: row.passenger_id,
  riderId: row.rider_id,
  pickupAddress: row.pickup_location,
  destinationAddress: row.destination,
  fare: Number(row.estimated_fare || 0),
  distanceKm: Number(row.distance_km || 0),
  estimatedMinutes: Number(row.estimated_minutes || 0),
  status: row.status,
  requestedAt: row.requested_at,
  respondedAt: row.responded_at,
  confirmedAt: row.confirmed_at,
  expiresAt: row.expires_at,
  freeCancelUntil: row.free_cancel_until,
  vehicleType: row.vehicle_type,
  appliedPromoCode: row.applied_promo_code,
  appliedOfferId: row.applied_offer_id,
  cancelReason: row.cancel_reason,
  cancelledBy: row.cancelled_by,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const createRequest = async (passengerId, payload) => {
  const {
    rideId,
    pickupAddress,
    destinationAddress,
    fare,
    distanceKm,
    estimatedMinutes,
  } = payload;

  if (!rideId || !pickupAddress || !destinationAddress) {
    throw new Error('rideId, pickupAddress, and destinationAddress are required.');
  }

  const rideRes = await rideDb.query(
    `SELECT
        ride_id,
        rider_id,
        available_seats,
        status,
        vehicle_type,
        per_km_rate
     FROM rides
     WHERE ride_id = $1
     LIMIT 1`,
    [rideId]
  );

  if (!rideRes.rows.length) {
    throw new Error('Ride not found.');
  }

  const ride = rideRes.rows[0];

  if (ride.rider_id === passengerId) {
    throw new Error('You cannot request your own ride.');
  }

  if (String(ride.status).toLowerCase() !== 'assigned') {
    throw new Error('This ride is not available for request.');
  }

  if (Number(ride.available_seats || 0) <= 0) {
    throw new Error('No seats available for this ride.');
  }

  const existingPending = await rideDb.query(
    `SELECT request_id
     FROM ride_requests
     WHERE ride_id = $1
       AND passenger_id = $2
       AND status IN ('pending', 'accepted')
     LIMIT 1`,
    [rideId, passengerId]
  );

  if (existingPending.rowCount > 0) {
    throw new Error('You already have an active request for this ride.');
  }

  const result = await rideDb.query(
    `INSERT INTO ride_requests (
      passenger_id,
      rider_id,
      pickup_location,
      destination,
      estimated_fare,
      estimated_minutes,
      status,
      expires_at,
      ride_id,
      distance_km,
      rate_per_km,
      vehicle_type
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, 'pending',
      CURRENT_TIMESTAMP + ($7 || ' seconds')::interval,
      $8, $9, $10, $11
    )
    RETURNING *`,
    [
      passengerId,
      ride.rider_id,
      pickupAddress,
      destinationAddress,
      fare || 0,
      estimatedMinutes || 0,
      String(REQUEST_TIMEOUT_SECONDS),
      rideId,
      distanceKm || 0,
      ride.per_km_rate || 0,
      ride.vehicle_type || null,
    ]
  );

  const request = result.rows[0];

  const riderPayload = {
    requestId: request.request_id,
    rideId: request.ride_id,
    passengerId: request.passenger_id,
    riderId: request.rider_id,
    pickupAddress: request.pickup_location,
    destinationAddress: request.destination,
    fare: Number(request.estimated_fare || 0),
    distanceKm: Number(request.distance_km || 0),
    estimatedMinutes: Number(request.estimated_minutes || 0),
    status: request.status,
    expiresAt: request.expires_at,
    vehicleType: request.vehicle_type,
  };

  emitToRiderRoom(request.rider_id, riderPayload);

  setTimeout(async () => {
    try {
      await expireRequestIfPending(request.request_id);
    } catch (error) {
      console.error('expireRequestIfPending error:', error.message);
    }
  }, REQUEST_TIMEOUT_SECONDS * 1000);

  return {
    requestId: request.request_id,
    status: request.status,
    expiresAt: request.expires_at,
  };
};

const getRequestStatus = async (userId, requestId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM ride_requests
     WHERE request_id = $1
       AND (passenger_id = $2 OR rider_id = $2)
     LIMIT 1`,
    [requestId, userId]
  );

  if (!result.rows.length) {
    throw new Error('Ride request not found.');
  }

  return mapRequestResponse(result.rows[0]);
};

const cancelRequest = async (passengerId, requestId, cancelReason = null) => {
  const result = await rideDb.query(
    `UPDATE ride_requests
     SET status = 'cancelled',
         cancel_reason = $3,
         cancelled_by = $2,
         updated_at = CURRENT_TIMESTAMP
     WHERE request_id = $1
       AND passenger_id = $2
       AND status = 'pending'
     RETURNING *`,
    [requestId, passengerId, cancelReason]
  );

  if (!result.rows.length) {
    throw new Error('Pending ride request not found or already processed.');
  }

  const request = result.rows[0];

  const payload = {
    requestId: request.request_id,
    status: 'cancelled',
    rideId: request.ride_id,
    message: 'Ride request cancelled',
  };

  emitRideRequestStatusUpdate(request.request_id, payload);
  emitToRiderRoom(request.rider_id, payload);

  return mapRequestResponse(request);
};

const acceptRequest = async (riderId, requestId) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const requestRes = await client.query(
      `SELECT *
       FROM ride_requests
       WHERE request_id = $1
         AND rider_id = $2
       FOR UPDATE`,
      [requestId, riderId]
    );

    if (!requestRes.rows.length) {
      throw new Error('Ride request not found.');
    }

    const request = requestRes.rows[0];

    if (request.status !== 'pending') {
      throw new Error('Only pending requests can be accepted.');
    }

    const rideRes = await client.query(
      `SELECT *
       FROM rides
       WHERE ride_id = $1
       FOR UPDATE`,
      [request.ride_id]
    );

    if (!rideRes.rows.length) {
      throw new Error('Ride not found.');
    }

    const ride = rideRes.rows[0];

    if (Number(ride.available_seats || 0) <= 0) {
      throw new Error('No seats available.');
    }

    const existingParticipant = await client.query(
      `SELECT participant_id
       FROM ride_participants
       WHERE ride_id = $1
         AND passenger_id = $2
       LIMIT 1`,
      [request.ride_id, request.passenger_id]
    );

    if (existingParticipant.rowCount > 0) {
      throw new Error('Passenger is already added to this ride.');
    }

    await client.query(
      `INSERT INTO ride_participants (
        ride_id,
        passenger_id,
        fare,
        confirmed
      )
      VALUES ($1, $2, $3, TRUE)`,
      [request.ride_id, request.passenger_id, request.estimated_fare]
    );

    await client.query(
      `UPDATE rides
       SET available_seats = available_seats - 1
       WHERE ride_id = $1`,
      [request.ride_id]
    );

    const acceptedRes = await client.query(
      `UPDATE ride_requests
       SET status = 'accepted',
           responded_at = CURRENT_TIMESTAMP,
           confirmed_at = CURRENT_TIMESTAMP,
           free_cancel_until = CURRENT_TIMESTAMP + interval '5 minutes',
           updated_at = CURRENT_TIMESTAMP
       WHERE request_id = $1
       RETURNING *`,
      [requestId]
    );

    await client.query('COMMIT');

    const acceptedRequest = acceptedRes.rows[0];

    const payload = {
      requestId: acceptedRequest.request_id,
      status: 'accepted',
      rideId: acceptedRequest.ride_id,
      message: 'Ride accepted',
    };

    emitRideRequestStatusUpdate(acceptedRequest.request_id, payload);
    emitToPassengerRoom(acceptedRequest.passenger_id, payload);

    return mapRequestResponse(acceptedRequest);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const rejectRequest = async (riderId, requestId, cancelReason = null) => {
  const result = await rideDb.query(
    `UPDATE ride_requests
     SET status = 'rejected',
         responded_at = CURRENT_TIMESTAMP,
         cancel_reason = $3,
         cancelled_by = $2,
         updated_at = CURRENT_TIMESTAMP
     WHERE request_id = $1
       AND rider_id = $2
       AND status = 'pending'
     RETURNING *`,
    [requestId, riderId, cancelReason]
  );

  if (!result.rows.length) {
    throw new Error('Pending ride request not found or already processed.');
  }

  const request = result.rows[0];

  const payload = {
    requestId: request.request_id,
    status: 'rejected',
    rideId: request.ride_id,
    message: 'Ride rejected',
  };

  emitRideRequestStatusUpdate(request.request_id, payload);
  emitToPassengerRoom(request.passenger_id, payload);

  return mapRequestResponse(request);
};

const expireRequestIfPending = async (requestId) => {
  const result = await rideDb.query(
    `UPDATE ride_requests
     SET status = 'expired',
         updated_at = CURRENT_TIMESTAMP
     WHERE request_id = $1
       AND status = 'pending'
       AND expires_at <= CURRENT_TIMESTAMP
     RETURNING *`,
    [requestId]
  );

  if (!result.rows.length) {
    return null;
  }

  const request = result.rows[0];

  const payload = {
    requestId: request.request_id,
    status: 'expired',
    rideId: request.ride_id,
    message: 'Ride request expired',
  };

  emitRideRequestStatusUpdate(request.request_id, payload);
  emitToPassengerRoom(request.passenger_id, payload);

  return request;
};

module.exports = {
  createRequest,
  getRequestStatus,
  cancelRequest,
  acceptRequest,
  rejectRequest,
  expireRequestIfPending,
};