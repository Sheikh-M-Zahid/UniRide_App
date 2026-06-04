const rideDb = require('../config/rideDb');
const {
  emitRideRequestStatusUpdate,
  emitToRider,
  emitToPassenger,
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

  const passengerRes = await rideDb.query(
    `SELECT first_name, last_name, university_email, phone FROM users WHERE user_id = $1`,
    [passengerId]
  );
  const passenger = passengerRes.rows[0] || {};
  const passengerName = `${passenger.first_name || ''} ${passenger.last_name || ''}`.trim();

  if (ride.rider_id === passengerId) {
    throw new Error('You cannot request your own ride.');
  }

  const rideStatus = String(ride.status).toLowerCase();
  if (!['active', 'assigned'].includes(rideStatus)) {
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
    passengerName,
    passengerEmail: passenger.university_email || '',
    passengerPhone: passenger.phone || '',
    currentLocation: request.pickup_location,
  };

  emitToRider(request.rider_id, riderPayload);

  const { createNotification } = require('./notificationService');
  await createNotification({
    userId: ride.rider_id,
    title: 'New Ride Request!',
    message: `${passengerName} wants to ride from ${pickupAddress} to ${destinationAddress}. Fare: ৳${fare || 0}`,
    type: 'booking',
    isImportant: true,
    targetRole: 'rider',
    relatedId: String(request.request_id),
  });

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
    `SELECT rr.*,
            u.first_name,
            u.last_name,
            u.university_email AS passenger_email,
            u.phone            AS passenger_phone
     FROM ride_requests rr
     JOIN users u ON rr.passenger_id = u.user_id
     WHERE rr.request_id = $1
       AND (rr.passenger_id = $2 OR rr.rider_id = $2)
     LIMIT 1`,
    [requestId, userId]
  );

  if (!result.rows.length) {
    throw new Error('Ride request not found.');
  }

  const row = result.rows[0];
  return {
    ...mapRequestResponse(row),
    passengerName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
    passengerEmail: row.passenger_email || '',
    passengerPhone: row.passenger_phone || '',
    currentLocation: row.pickup_location || '',
  };
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
  emitToRider(request.rider_id, payload);

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

    const { createNotification } = require('./notificationService');

    const passengerInfoRes = await rideDb.query(
      `SELECT first_name, last_name, phone FROM users WHERE user_id = $1`,
      [acceptedRequest.passenger_id]
    );
    const passengerInfo = passengerInfoRes.rows[0] || {};

    const riderInfoRes = await rideDb.query(
      `SELECT first_name, last_name, phone FROM users WHERE user_id = $1`,
      [acceptedRequest.rider_id]
    );
    const riderInfo = riderInfoRes.rows[0] || {};

    await createNotification({
      userId: acceptedRequest.passenger_id,
      title: 'Ride Confirmed! 🎉',
      message: `Your ride was confirmed by ${riderInfo.first_name || 'the rider'}. Rider phone: ${riderInfo.phone || 'N/A'}`,
      type: 'booking',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: String(acceptedRequest.request_id),
    });

    await createNotification({
      userId: acceptedRequest.rider_id,
      title: 'Ride Confirmed!',
      message: `You confirmed ride for ${passengerInfo.first_name || 'passenger'}. Passenger phone: ${passengerInfo.phone || 'N/A'}`,
      type: 'booking',
      isImportant: true,
      targetRole: 'rider',
      relatedId: String(acceptedRequest.request_id),
    });

    const payload = {
      requestId: acceptedRequest.request_id,
      status: 'accepted',
      rideId: acceptedRequest.ride_id,
      message: 'Ride accepted',
      passengerPhone: passengerInfo.phone || '',
      riderPhone: riderInfo.phone || '',
    };

    // ✅ request room এ emit (passenger socket এখানে join করে)
    emitRideRequestStatusUpdate(acceptedRequest.request_id, payload);
    // ✅ user room এ emit (backup channel)
    emitToPassenger(acceptedRequest.passenger_id, payload);

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

  const { createNotification } = require('./notificationService');
  await createNotification({
    userId: request.passenger_id,
    title: 'Ride Request Rejected',
    message: 'Your ride request was rejected by the rider. Please try another available ride.',
    type: 'booking',
    isImportant: false,
    targetRole: 'passenger',
    relatedId: String(request.request_id),
  });

  const payload = {
    requestId: request.request_id,
    status: 'rejected',
    rideId: request.ride_id,
    message: 'Ride rejected',
  };

  emitRideRequestStatusUpdate(request.request_id, payload);
  emitToPassenger(request.passenger_id, payload);

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
  emitToPassenger(request.passenger_id, payload);

  return request;
};

// ফাইলের একদম শেষে module.exports এর আগে যোগ করো

const getPassengerActiveRequest = async (passengerId) => {
  const result = await rideDb.query(
    `SELECT 
        rr.request_id,
        rr.ride_id,
        rr.rider_id,
        rr.pickup_location,
        rr.destination,
        rr.estimated_fare,
        rr.distance_km,
        rr.estimated_minutes,
        rr.status,
        rr.pickup_latitude,
        rr.pickup_longitude,
        rr.destination_latitude,
        rr.destination_longitude,
        u.first_name AS rider_first_name,
        u.last_name  AS rider_last_name,
        u.phone      AS rider_phone,
        u.profile_picture AS rider_photo,
        ll.latitude  AS rider_lat,
        ll.longitude AS rider_lng
     FROM ride_requests rr
     JOIN users u ON rr.rider_id = u.user_id
     LEFT JOIN LATERAL (
       SELECT latitude, longitude
       FROM live_locations
       WHERE user_id = rr.rider_id
       ORDER BY updated_at DESC
       LIMIT 1
     ) ll ON TRUE
     WHERE rr.passenger_id = $1
       AND rr.status = 'accepted'
     ORDER BY rr.confirmed_at DESC
     LIMIT 1`,
    [passengerId]
  );

  if (!result.rows.length) return null;

  const row = result.rows[0];
  return {
    requestId: row.request_id,
    rideId: row.ride_id,
    riderId: row.rider_id,
    riderName: `${row.rider_first_name || ''} ${row.rider_last_name || ''}`.trim(),
    riderPhone: row.rider_phone || '',
    riderPhoto: row.rider_photo || null,
    pickupLocation: row.pickup_location,
    destination: row.destination,
    fare: Number(row.estimated_fare || 0),
    distanceKm: Number(row.distance_km || 0),
    estimatedMinutes: Number(row.estimated_minutes || 0),
    status: row.status,
    pickupLat: row.pickup_latitude ? Number(row.pickup_latitude) : null,
    pickupLng: row.pickup_longitude ? Number(row.pickup_longitude) : null,
    destinationLat: row.destination_latitude ? Number(row.destination_latitude) : null,
    destinationLng: row.destination_longitude ? Number(row.destination_longitude) : null,
    riderLat: row.rider_lat ? Number(row.rider_lat) : null,
    riderLng: row.rider_lng ? Number(row.rider_lng) : null,
  };
};

module.exports = {
  createRequest,
  getRequestStatus,
  cancelRequest,
  acceptRequest,
  rejectRequest,
  expireRequestIfPending,
  getPassengerActiveRequest,
};
