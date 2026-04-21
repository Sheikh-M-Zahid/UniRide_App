const rideDb = require('../config/rideDb');
const { getDistanceAndDuration } = require('./distanceService');
const { getActiveRateByVehicleType, calculateFare } = require('./fareService');
const { isRouteMatch } = require('../utils/routeMatcher');

const createRideRequest = async ({ passengerId, body, io }) => {
  const {
    riderId,
    pickupLocation,
    destination,
    pickupLatitude,
    pickupLongitude,
    destinationLatitude,
    destinationLongitude,
  } = body;

  if (
    !riderId ||
    !pickupLocation ||
    !destination ||
    pickupLatitude == null ||
    pickupLongitude == null ||
    destinationLatitude == null ||
    destinationLongitude == null
  ) {
    throw new Error('Required ride request fields are missing.');
  }

  // 1. Rider vehicle check
  const riderVehicleRes = await rideDb.query(
    `SELECT vehicle_id, vehicle_type
     FROM vehicles
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 1`,
    [riderId]
  );

  if (!riderVehicleRes.rows.length) {
    throw new Error('Rider vehicle not found.');
  }

  const vehicle = riderVehicleRes.rows[0];

  // 2. Rider active কিনা check
  const availabilityRes = await rideDb.query(
    `SELECT is_active
     FROM rider_availability
     WHERE rider_id = $1`,
    [riderId]
  );

  if (!availabilityRes.rows.length || !availabilityRes.rows[0].is_active) {
    throw new Error('Rider is not currently active.');
  }

  const activeRideRes = await rideDb.query(
    `SELECT
        pickup_latitude,
        pickup_longitude,
        destination_latitude,
        destination_longitude,
        start_latitude,
        start_longitude
     FROM rides
     WHERE rider_id = $1
       AND status IN ('active', 'assigned', 'ongoing')
     ORDER BY created_at DESC
     LIMIT 1`,
    [riderId]
  );

  if (!activeRideRes.rows.length) {
    throw new Error('Rider does not have an active route right now.');
  }

  const activeRide = activeRideRes.rows[0];

  const matched = isRouteMatch({
    riderStartLat: Number(activeRide.start_latitude ?? activeRide.pickup_latitude ?? 0),
    riderStartLng: Number(activeRide.start_longitude ?? activeRide.pickup_longitude ?? 0),
    riderDestLat: Number(activeRide.destination_latitude ?? 0),
    riderDestLng: Number(activeRide.destination_longitude ?? 0),
    reqPickupLat: Number(pickupLatitude),
    reqPickupLng: Number(pickupLongitude),
    reqDestLat: Number(destinationLatitude),
    reqDestLng: Number(destinationLongitude),
  });

  if (!matched) {
    throw new Error('This ride request does not match the rider route.');
  }

  // 3. Distance + estimated time
  const { distanceKm, estimatedMinutes } = await getDistanceAndDuration({
    pickupLatitude,
    pickupLongitude,
    destinationLatitude,
    destinationLongitude,
  });

  // 4. Fare calculation
  const perKmRate = await getActiveRateByVehicleType(vehicle.vehicle_type);
  const fare = calculateFare({ distanceKm, perKmRate });

  // 5. Insert ride request
  const requestRes = await rideDb.query(
    `INSERT INTO ride_requests (
        passenger_id,
        rider_id,
        pickup_location,
        destination,
        pickup_latitude,
        pickup_longitude,
        destination_latitude,
        destination_longitude,
        estimated_fare,
        estimated_minutes,
        status,
        expires_at,
        distance_km,
        rate_per_km,
        vehicle_type
     )
     VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8,
        $9, $10, 'pending',
        CURRENT_TIMESTAMP + INTERVAL '45 seconds',
        $11, $12, $13
     )
     RETURNING *`,
    [
      passengerId,
      riderId,
      pickupLocation,
      destination,
      pickupLatitude,
      pickupLongitude,
      destinationLatitude,
      destinationLongitude,
      fare,
      estimatedMinutes,
      distanceKm,
      perKmRate,
      vehicle.vehicle_type,
    ]
  );

  const request = requestRes.rows[0];

  // 6. Passenger info
  const passengerRes = await rideDb.query(
    `SELECT first_name, last_name, phone
     FROM users
     WHERE user_id = $1`,
    [passengerId]
  );

  if (!passengerRes.rows.length) {
    throw new Error('Passenger not found.');
  }

  const passenger = passengerRes.rows[0];

  // 7. Frontend exact RideRequestModel payload
  const requestPayload = {
    requestId: request.request_id,
    passengerName: `${passenger.first_name || ''} ${passenger.last_name || ''}`.trim(),
    phoneNumber: passenger.phone || '',
    currentLocation: request.pickup_location,
    destination: request.destination,
    distanceKm: Number(request.distance_km || 0),
    fare: Number(request.estimated_fare || 0),
    estimatedMinutes: Number(request.estimated_minutes || 0),
  };

  // 8. Backend metadata
  const metaPayload = {
    requestId: request.request_id,
    passengerId: request.passenger_id,
    riderId: request.rider_id,
    status: request.status,
    createdAt: request.requested_at || request.created_at,
    confirmedAt: request.confirmed_at || null,
    freeCancelUntil: request.free_cancel_until || null,
    confirmedRideId: request.ride_id || null,
    vehicleType: request.vehicle_type || null,
    ratePerKm: request.rate_per_km ? Number(request.rate_per_km) : null,
  };

  // 9. Final response
  const payload = {
    request: requestPayload,
    meta: metaPayload,
  };

  // 10. Real-time emit to rider
  if (io) {
    io.to(`rider_${riderId}`).emit('ride-request:new', payload);
    io.to(`rider_${riderId}`).emit('new_ride_request', requestPayload);
  }

  return payload;
};

module.exports = {
  createRideRequest,
};
