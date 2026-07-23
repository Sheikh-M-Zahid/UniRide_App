const rideDb = require('../config/rideDb');
const {
  emitRideRequestStatusUpdate,
  emitToRider,
  emitToRiderEvent,
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
    applied_promo_code = null,
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
      vehicle_type,
      applied_promo_code
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, 'pending',
      CURRENT_TIMESTAMP + ($7 || ' seconds')::interval,
      $8, $9, $10, $11, $12
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
      applied_promo_code || null,
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

  await rideDb.query(
    `UPDATE ride_availability_alerts
     SET is_active = FALSE
     WHERE user_id = $1
       AND is_active = TRUE`,
    [passengerId]
  );

  emitToRider(request.rider_id, riderPayload);

  const { createNotification } = require('./notificationService');
  await createNotification({
    userId: ride.rider_id,
    title: 'New Ride Request!',
    message: `${passengerName} wants to ride from ${pickupAddress} to ${destinationAddress}. Fare: ৳${fare || 0}${applied_promo_code ? ` · Offer applied: ${applied_promo_code}` : ''}`,
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
    
    await rideDb.query(
      `UPDATE ride_availability_alerts
       SET is_active = FALSE
       WHERE user_id = $1
         AND is_active = TRUE`,
      [request.passenger_id]
    );

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
    // ✅ rider-এর অন্য device/ট্যাব sync রাখতে — RideRequestService.dart এর
    // 'ride-request:accepted' listener এই payload shape-ই আশা করে
    emitToRiderEvent(acceptedRequest.rider_id, 'ride-request:accepted', {
      requestId: acceptedRequest.request_id,
      confirmedRideId: acceptedRequest.ride_id,
      confirmedAt: acceptedRequest.confirmed_at,
    });

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

const getPassengerActiveRequest = async (passengerId) => {
  // ✅ শুধু ride_requests.status='accepted' চেক করলেই হবে না — rides.status ও চেক করা
  // হচ্ছে, যাতে অন্য কোনো cancel/complete flow ride_requests sync করতে ভুলে গেলেও
  // Home page-এ zombie/stale "Ride in progress" কার্ড আর না দেখায়।
  const activeResult = await rideDb.query(
    `SELECT 
        rr.request_id,
        rr.ride_id,
        rr.rider_id,
        rr.pickup_location,
        rr.destination,
        rr.estimated_fare,
        rr.distance_km,
        rr.estimated_minutes,
        rr.status AS request_status,
        rr.pickup_latitude,
        rr.pickup_longitude,
        rr.destination_latitude,
        rr.destination_longitude,
        u.first_name AS rider_first_name,
        u.last_name  AS rider_last_name,
        u.phone      AS rider_phone,
        u.profile_picture AS rider_photo,
        ll.latitude  AS rider_lat,
        ll.longitude AS rider_lng,
        r.status AS ride_status
     FROM ride_requests rr
     JOIN users u ON rr.rider_id = u.user_id
     JOIN rides r ON r.ride_id = rr.ride_id
     LEFT JOIN LATERAL (
       SELECT latitude, longitude
       FROM live_locations
       WHERE user_id = rr.rider_id
       ORDER BY updated_at DESC
       LIMIT 1
     ) ll ON TRUE
     WHERE rr.passenger_id = $1
       AND rr.status = 'accepted'
       AND r.status IN ('assigned', 'ongoing')
     ORDER BY rr.confirmed_at DESC
     LIMIT 1`,
    [passengerId]
  );

  if (activeResult.rows.length) {
    return mapActiveRequestRow(activeResult.rows[0], false);
  }

  // ✅ Ride সম্পূর্ণ হওয়ার ২ মিনিট পর্যন্ত কার্ড দেখাতে থাকা (rider drop confirm করার পর)
  const recentlyCompletedResult = await rideDb.query(
    `SELECT 
        rr.request_id,
        rr.ride_id,
        rr.rider_id,
        rr.pickup_location,
        rr.destination,
        rr.estimated_fare,
        rr.distance_km,
        rr.estimated_minutes,
        rr.status AS request_status,
        rr.pickup_latitude,
        rr.pickup_longitude,
        rr.destination_latitude,
        rr.destination_longitude,
        u.first_name AS rider_first_name,
        u.last_name  AS rider_last_name,
        u.phone      AS rider_phone,
        u.profile_picture AS rider_photo,
        NULL AS rider_lat,
        NULL AS rider_lng,
        r.status AS ride_status
     FROM ride_requests rr
     JOIN users u ON rr.rider_id = u.user_id
     JOIN rides r ON r.ride_id = rr.ride_id
     WHERE rr.passenger_id = $1
       AND r.status = 'completed'
       AND r.completed_at > NOW() - INTERVAL '2 minutes'
     ORDER BY r.completed_at DESC
     LIMIT 1`,
    [passengerId]
  );

  if (recentlyCompletedResult.rows.length) {
    return mapActiveRequestRow(recentlyCompletedResult.rows[0], true);
  }

  return null;
};

const mapActiveRequestRow = (row, isCompleted) => {
  // ✅ Pickup হয়েছে কিনা rides.status দিয়ে বোঝা হচ্ছে — rider "Start Navigation" চাপলেই
  // status 'assigned' থেকে 'ongoing' হয়, যেটাকেই pickup হিসেবে ধরা হচ্ছে।
  let rideStage = 'waiting_for_pickup';
  if (isCompleted) {
    rideStage = 'completed';
  } else if (row.ride_status === 'ongoing') {
    rideStage = 'ongoing';
  }

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
    rideStage,
    canCancel: rideStage === 'waiting_for_pickup',
    pickupLat: row.pickup_latitude ? Number(row.pickup_latitude) : null,
    pickupLng: row.pickup_longitude ? Number(row.pickup_longitude) : null,
    destinationLat: row.destination_latitude ? Number(row.destination_latitude) : null,
    destinationLng: row.destination_longitude ? Number(row.destination_longitude) : null,
    riderLat: row.rider_lat ? Number(row.rider_lat) : null,
    riderLng: row.rider_lng ? Number(row.rider_lng) : null,
  };
};

const getRiderLiveLocation = async (passengerId, requestId) => {
  const result = await rideDb.query(
    `SELECT 
        ll.latitude,
        ll.longitude,
        ll.updated_at
     FROM ride_requests rr
     JOIN LATERAL (
       SELECT latitude, longitude, updated_at
       FROM live_locations
       WHERE user_id = rr.rider_id
       ORDER BY updated_at DESC
       LIMIT 1
     ) ll ON TRUE
     WHERE rr.request_id = $1
       AND rr.passenger_id = $2
       AND rr.status = 'accepted'
     LIMIT 1`,
    [requestId, passengerId]
  );

  if (!result.rows.length) return null;
  const row = result.rows[0];
  return {
    lat: row.latitude ? Number(row.latitude) : null,
    lng: row.longitude ? Number(row.longitude) : null,
    updatedAt: row.updated_at,
  };
};

const { scoreRequest } = require('./rideRequestScoringService');
const { calculateCancelFine } = require('./cancelFineService');

const ACTIVE_RIDE_STATUSES = ['assigned', 'ongoing'];

// রাইডারের বর্তমান active ride (multi-seat) খুঁজে বের করে
const getRiderActiveRide = async (riderId) => {
  const res = await rideDb.query(
    `SELECT *
     FROM rides
     WHERE rider_id = $1
       AND status = ANY($2::text[])
     ORDER BY created_at DESC
     LIMIT 1`,
    [riderId, ACTIVE_RIDE_STATUSES]
  );
  return res.rows[0] || null;
};

// রাইডারের ড্যাশবোর্ড — active ride, confirmed passengers (একাধিক হতে পারে), ও
// score-সহ pending requests একসাথে রিটার্ন করে
const getRiderDashboard = async (riderId) => {
  const ride = await getRiderActiveRide(riderId);

  if (!ride) {
    return {
      hasActiveRide: false,
      ride: null,
      confirmedPassengers: [],
      pendingRequests: [],
    };
  }

  const confirmedRes = await rideDb.query(
    `SELECT
        rp.participant_id,
        rp.passenger_id,
        rp.fare,
        rp.confirmed,
        rp.created_at,
        rr.request_id,
        rr.pickup_location,
        rr.destination,
        rr.free_cancel_until,
        rr.confirmed_at,
        u.first_name,
        u.last_name,
        u.phone
     FROM ride_participants rp
     JOIN users u ON u.user_id = rp.passenger_id
     LEFT JOIN ride_requests rr
        ON rr.ride_id = rp.ride_id
       AND rr.passenger_id = rp.passenger_id
       AND rr.status = 'accepted'
     WHERE rp.ride_id = $1
       AND rp.confirmed = TRUE
     ORDER BY rp.created_at ASC`,
    [ride.ride_id]
  );

  const confirmedPassengers = confirmedRes.rows.map((row) => {
    const remainingFreeCancelSeconds = row.free_cancel_until
      ? Math.max(0, Math.floor((new Date(row.free_cancel_until).getTime() - Date.now()) / 1000))
      : 0;

    return {
      requestId: row.request_id,
      participantId: row.participant_id,
      passengerId: row.passenger_id,
      passengerName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
      phoneNumber: row.phone,
      pickupLocation: row.pickup_location,
      destination: row.destination,
      fare: Number(row.fare || 0),
      confirmedAt: row.confirmed_at,
      remainingFreeCancelSeconds,
      isFreeCancelAvailable: remainingFreeCancelSeconds > 0,
    };
  });

  const pendingRes = await rideDb.query(
    `SELECT rr.*, u.first_name, u.last_name, u.phone
     FROM ride_requests rr
     JOIN users u ON u.user_id = rr.passenger_id
     WHERE rr.ride_id = $1
       AND rr.status = 'pending'
       AND rr.expires_at > CURRENT_TIMESTAMP
     ORDER BY rr.requested_at ASC`,
    [ride.ride_id]
  );

  const scoredPending = await Promise.all(
    pendingRes.rows.map(async (row) => {
      const scoring = await scoreRequest({ ride, request: row });
      return {
        requestId: row.request_id,
        passengerName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
        phoneNumber: row.phone,
        pickupAddress: row.pickup_location,
        destinationAddress: row.destination,
        distanceKm: Number(row.distance_km || 0),
        fare: Number(row.estimated_fare || 0),
        estimatedMinutes: Number(row.estimated_minutes || 0),
        requestedAt: row.requested_at,
        expiresAt: row.expires_at,
        ...scoring,
      };
    })
  );

  scoredPending.sort((a, b) => b.score - a.score);

  return {
    hasActiveRide: true,
    ride: {
      rideId: ride.ride_id,
      startLocation: ride.start_location,
      destination: ride.destination,
      vehicleType: ride.vehicle_type,
      availableSeats: Number(ride.available_seats || 0),
      status: ride.status,
      totalFare: Number(ride.total_fare || 0),
    },
    confirmedPassengers,
    pendingRequests: scoredPending,
  };
};

// শুধু scored pending list চাই (dashboard এর বাকি অংশ ছাড়া) — পোলিং হালকা রাখতে
const getScoredPendingRequestsForRider = async (riderId) => {
  const ride = await getRiderActiveRide(riderId);
  if (!ride) return [];

  const dashboard = await getRiderDashboard(riderId);
  return dashboard.pendingRequests;
};

// Rider একটা confirmed (accepted) passenger বাতিল করে — সিট ফেরত আসে, fine লজিক প্রযোজ্য
const cancelAcceptedParticipant = async (riderId, requestId, cancelReason = null) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const requestRes = await client.query(
      `SELECT * FROM ride_requests WHERE request_id = $1 FOR UPDATE`,
      [requestId]
    );

    if (!requestRes.rows.length) throw new Error('Ride request not found.');
    const request = requestRes.rows[0];

    if (request.rider_id !== riderId) throw new Error('Unauthorized cancellation.');
    if (request.status !== 'accepted') throw new Error('This request is not in accepted state.');

    const rideRes = await client.query(
      `SELECT * FROM rides WHERE ride_id = $1 FOR UPDATE`,
      [request.ride_id]
    );
    if (!rideRes.rows.length) throw new Error('Ride not found.');
    const ride = rideRes.rows[0];

    const fineResult = await calculateCancelFine({
      client,
      riderId,
      confirmedAt: request.confirmed_at,
      freeCancelUntil: request.free_cancel_until,
    });

    await client.query(
      `UPDATE ride_requests
       SET status = 'cancelled',
           cancel_reason = $2,
           cancelled_by = $3,
           updated_at = CURRENT_TIMESTAMP
       WHERE request_id = $1`,
      [requestId, cancelReason || fineResult.fineType, riderId]
    );

    await client.query(
      `UPDATE ride_participants
       SET confirmed = FALSE
       WHERE ride_id = $1 AND passenger_id = $2`,
      [request.ride_id, request.passenger_id]
    );

    if (['assigned', 'ongoing'].includes(ride.status)) {
      await client.query(
        `UPDATE rides SET available_seats = available_seats + 1 WHERE ride_id = $1`,
        [request.ride_id]
      );
    }

    let updatedDueBalance = null;
    if (fineResult.fineAmount > 0) {
      const dueRes = await client.query(
        `UPDATE users SET due_balance = due_balance + $2 WHERE user_id = $1 RETURNING due_balance`,
        [riderId, fineResult.fineAmount]
      );
      updatedDueBalance = Number(dueRes.rows[0].due_balance);

      await client.query(
        `INSERT INTO transactions (user_id, amount, type, method, reference_id, status)
         VALUES ($1, $2, 'debit', 'cancel_fine', $3, 'completed')`,
        [riderId, fineResult.fineAmount, `CANCEL-FINE-${requestId}`]
      );
    }

    await client.query('COMMIT');

    const { createNotification } = require('./notificationService');
    await createNotification({
      userId: request.passenger_id,
      title: 'Ride Cancelled',
      message: 'The rider has cancelled your confirmed ride. Please book another ride.',
      type: 'booking',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: String(request.request_id),
    });

    const payload = {
      requestId: request.request_id,
      rideId: request.ride_id,
      status: 'cancelled',
      fineAmount: fineResult.fineAmount,
      fineType: fineResult.fineType,
    };

    emitRideRequestStatusUpdate(request.request_id, payload);
    emitToPassenger(request.passenger_id, payload);
    // RideRequestService.dart এর 'confirmed-ride:cancelled' listener এই event নামেই শোনে
    emitToRiderEvent(riderId, 'confirmed-ride:cancelled', {
      ...payload,
      dueBalance: updatedDueBalance,
    });

    return {
      ...mapRequestResponse({ ...request, status: 'cancelled' }),
      fineAmount: fineResult.fineAmount,
      fineType: fineResult.fineType,
      dueBalance: updatedDueBalance,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

// ✅ Passenger নিজে confirmed ride cancel করবে — শুধু pickup হওয়ার আগ পর্যন্ত
// (অর্থাৎ rides.status এখনও 'assigned', rider এখনও Start Navigation চাপেনি)
const cancelActiveRideByPassenger = async (passengerId, requestId) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const requestRes = await client.query(
      `SELECT * FROM ride_requests WHERE request_id = $1 AND passenger_id = $2 FOR UPDATE`,
      [requestId, passengerId]
    );

    if (!requestRes.rows.length) throw new Error('Ride request not found.');
    const request = requestRes.rows[0];

    if (request.status !== 'accepted') {
      throw new Error('This ride cannot be cancelled at this stage.');
    }

    const rideRes = await client.query(
      `SELECT * FROM rides WHERE ride_id = $1 FOR UPDATE`,
      [request.ride_id]
    );

    if (!rideRes.rows.length) throw new Error('Ride not found.');
    const ride = rideRes.rows[0];

    if (ride.status !== 'assigned') {
      throw new Error('You can no longer cancel — pickup has already happened.');
    }

    await client.query(
      `UPDATE ride_requests
       SET status = 'cancelled',
           cancel_reason = 'Cancelled by passenger before pickup',
           cancelled_by = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE request_id = $1`,
      [requestId, passengerId]
    );

    await client.query(
      `UPDATE ride_participants
       SET confirmed = FALSE
       WHERE ride_id = $1 AND passenger_id = $2`,
      [request.ride_id, passengerId]
    );

    await client.query(
      `UPDATE rides SET available_seats = available_seats + 1 WHERE ride_id = $1`,
      [request.ride_id]
    );

    await client.query('COMMIT');

    const { createNotification } = require('./notificationService');
    await createNotification({
      userId: request.rider_id,
      title: 'Passenger Cancelled Ride',
      message: 'The passenger has cancelled their confirmed ride before pickup.',
      type: 'booking',
      isImportant: true,
      targetRole: 'rider',
      relatedId: String(request.request_id),
    });

    const payload = {
      requestId: request.request_id,
      rideId: request.ride_id,
      status: 'cancelled',
      message: 'Passenger cancelled the ride',
    };

    emitRideRequestStatusUpdate(request.request_id, payload);
    emitToRiderEvent(request.rider_id, 'confirmed-ride:cancelled', payload);

    return { requestId: request.request_id, status: 'cancelled' };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  createRequest,
  getRequestStatus,
  cancelRequest,
  acceptRequest,
  rejectRequest,
  expireRequestIfPending,
  getPassengerActiveRequest,
  getRiderLiveLocation,
  getRiderDashboard,
  getScoredPendingRequestsForRider,
  cancelAcceptedParticipant,
  cancelActiveRideByPassenger,
};
