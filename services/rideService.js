const rideDb = require('../config/rideDb');
const { notifyUsersForRide } = require('./rideAlertMatcherService');
const {
  emitSeatUpdate,
  emitRideUnavailable,
  emitRideAvailable,
} = require('../utils/rideAvailabilityEmitter');

/* =========================
   COMMON HELPERS
========================= */
const toRadians = (degree) => degree * (Math.PI / 180);

const calculateHaversineDistanceKm = (lat1, lng1, lat2, lng2) => {
  const R = 6371;

  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
};

const validateCoordinate = (value, min, max, label) => {
  const num = Number(value);

  if (Number.isNaN(num)) {
    throw new Error(`${label} must be a valid number.`);
  }

  if (num < min || num > max) {
    throw new Error(`${label} is out of range.`);
  }

  return num;
};

const normalizeRideStatus = (status) => {
  const allowed = ['assigned', 'ongoing', 'completed', 'cancelled'];

  if (!status) return 'assigned';

  const normalized = String(status).trim().toLowerCase();

  if (!allowed.includes(normalized)) {
    throw new Error('Invalid ride status.');
  }

  return normalized;
};

const formatRideDisplayText = (ride) => {
  return `${ride.start_location} → ${ride.destination} | ${
    ride.vehicle_type || 'vehicle'
  } | Fare: BDT ${ride.total_fare}`;
};

/* =========================
   CREATE RIDE
   Frontend: rider create/publish ride page
========================= */
const createRide = async (userId, payload) => {
  const {
    vehicle_id,
    start_location,
    destination,
    total_distance_km,
    per_km_rate,
    total_fare,
    available_seats,
    travel_date = null,
    travel_time = null,
    vehicle_type = null,
    gender_preference = null,
    note = null,
    status,
  } = payload;

  if (
    !vehicle_id ||
    !start_location ||
    !destination ||
    total_distance_km === undefined ||
    per_km_rate === undefined ||
    total_fare === undefined ||
    available_seats === undefined
  ) {
    throw new Error('Missing required ride fields.');
  }

  const rideStatus = normalizeRideStatus(status || 'assigned');

  const result = await rideDb.query(
    `INSERT INTO rides (
      rider_id,
      vehicle_id,
      start_location,
      destination,
      total_distance_km,
      per_km_rate,
      total_fare,
      available_seats,
      status,
      travel_date,
      travel_time,
      vehicle_type,
      gender_preference,
      note
    )
    VALUES (
      $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14
    )
    RETURNING *`,
    [
      userId,
      vehicle_id,
      start_location,
      destination,
      total_distance_km,
      per_km_rate,
      total_fare,
      available_seats,
      rideStatus,
      travel_date,
      travel_time,
      vehicle_type,
      gender_preference,
      note,
    ]
  );

  const createdRide = result.rows[0];

  // Emit newly available ride
  emitRideAvailable({
    rideId: createdRide.ride_id,
    emptySeats: Number(createdRide.available_seats || 0),
    vehicleType: createdRide.vehicle_type,
    pickupLocation: createdRide.start_location,
    destinationLocation: createdRide.destination,
  });

  // Notify matching alert users
  try {
    await notifyUsersForRide({ ride: createdRide });
  } catch (notifyError) {
    console.error('notifyUsersForRide error:', notifyError.message);
  }

  return createdRide;
};

/* =========================
   LIST AVAILABLE RIDES
   Frontend: available rides list / passenger browse
========================= */
const listActiveRides = async () => {
  const result = await rideDb.query(
    `SELECT
        r.ride_id,
        r.rider_id,
        r.vehicle_id,
        r.start_location,
        r.destination,
        r.total_distance_km,
        r.per_km_rate,
        r.total_fare,
        r.available_seats,
        r.status,
        r.travel_date,
        r.travel_time,
        r.vehicle_type,
        r.gender_preference,
        r.note,
        r.created_at,
        u.first_name,
        u.last_name,
        u.university_email,
        u.phone,
        u.rating,
        v.vehicle_type AS rider_vehicle_type,
        v.company,
        v.model,
        v.number_plate
     FROM rides r
     JOIN users u
       ON r.rider_id = u.user_id
     LEFT JOIN vehicles v
       ON r.vehicle_id = v.vehicle_id
     WHERE r.status = 'assigned'
       AND r.available_seats > 0
     ORDER BY r.created_at DESC`
  );

  return result.rows;
};

/* =========================
   RIDE DETAILS
   Frontend: ride details page / ride details popup
========================= */
const getRideDetails = async (rideId) => {
  const rideResult = await rideDb.query(
    `SELECT
        r.ride_id,
        r.rider_id,
        r.vehicle_id,
        r.start_location,
        r.destination,
        r.total_distance_km,
        r.per_km_rate,
        r.total_fare,
        r.available_seats,
        r.status,
        r.travel_date,
        r.travel_time,
        r.vehicle_type,
        r.gender_preference,
        r.note,
        r.created_at,
        u.first_name,
        u.last_name,
        u.university_email,
        u.phone,
        u.rating,
        v.vehicle_type AS rider_vehicle_type,
        v.company,
        v.model,
        v.number_plate,
        v.total_seats
     FROM rides r
     JOIN users u
       ON r.rider_id = u.user_id
     LEFT JOIN vehicles v
       ON r.vehicle_id = v.vehicle_id
     WHERE r.ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const participantsResult = await rideDb.query(
    `SELECT
        rp.participant_id,
        rp.ride_id,
        rp.passenger_id,
        rp.fare,
        rp.confirmed,
        rp.created_at,
        u.first_name,
        u.last_name,
        u.university_email,
        u.phone
     FROM ride_participants rp
     JOIN users u
       ON rp.passenger_id = u.user_id
     WHERE rp.ride_id = $1
     ORDER BY rp.created_at DESC`,
    [rideId]
  );

  return {
    ride: rideResult.rows[0],
    participants: participantsResult.rows,
  };
};

/* =========================
   JOIN RIDE
   Frontend: passenger join ride button
========================= */
const joinRide = async (rideId, passengerId, fare) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const rideResult = await client.query(
      `SELECT *
       FROM rides
       WHERE ride_id = $1
       FOR UPDATE`,
      [rideId]
    );

    if (rideResult.rowCount === 0) {
      throw new Error('Ride not found.');
    }

    const ride = rideResult.rows[0];

    if (ride.rider_id === passengerId) {
      throw new Error('Rider cannot join own ride.');
    }

    if (ride.status !== 'assigned') {
      throw new Error('This ride is not available for joining.');
    }

    if (Number(ride.available_seats) <= 0) {
      throw new Error('No available seats left.');
    }

    const existing = await client.query(
      `SELECT participant_id
       FROM ride_participants
       WHERE ride_id = $1 AND passenger_id = $2`,
      [rideId, passengerId]
    );

    if (existing.rowCount > 0) {
      throw new Error('You already joined this ride.');
    }

    const insertResult = await client.query(
      `INSERT INTO ride_participants (
        ride_id,
        passenger_id,
        fare,
        confirmed
      )
      VALUES ($1, $2, $3, FALSE)
      RETURNING *`,
      [rideId, passengerId, fare]
    );

    const updatedRideRes = await client.query(
      `UPDATE rides
       SET available_seats = available_seats - 1
       WHERE ride_id = $1
       RETURNING *`,
      [rideId]
    );

    await client.query('COMMIT');

    const updatedRide = updatedRideRes.rows[0];
    const remainingSeats = Number(updatedRide.available_seats || 0);

    emitSeatUpdate({
      rideId: updatedRide.ride_id,
      emptySeats: remainingSeats,
    });

    if (remainingSeats <= 0) {
      emitRideUnavailable({
        rideId: updatedRide.ride_id,
        reason: 'No available seats left',
      });
    }

    return insertResult.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/* =========================
   CONFIRM PARTICIPANT
   Frontend: rider participant confirmation UI
========================= */
const confirmParticipant = async (rideId, riderId, participantId) => {
  const ownership = await rideDb.query(
    `SELECT ride_id
     FROM rides
     WHERE ride_id = $1 AND rider_id = $2`,
    [rideId, riderId]
  );

  if (ownership.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  const result = await rideDb.query(
    `UPDATE ride_participants
     SET confirmed = TRUE
     WHERE participant_id = $1 AND ride_id = $2
     RETURNING *`,
    [participantId, rideId]
  );

  if (result.rowCount === 0) {
    throw new Error('Participant not found.');
  }

  return result.rows[0];
};

/* =========================
   CHANGE RIDE STATUS
   Frontend: start / complete / cancel buttons
========================= */
const changeRideStatus = async (rideId, riderId, status) => {
  const rideStatus = normalizeRideStatus(status);

  const result = await rideDb.query(
    `UPDATE rides
     SET status = $1
     WHERE ride_id = $2 AND rider_id = $3
     RETURNING *`,
    [rideStatus, rideId, riderId]
  );

  if (result.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  const updatedRide = result.rows[0];

  if (rideStatus === 'cancelled' || rideStatus === 'completed') {
    emitRideUnavailable({
      rideId: updatedRide.ride_id,
      reason: `Ride ${rideStatus}`,
    });
  } else if (rideStatus === 'assigned' && Number(updatedRide.available_seats || 0) > 0) {
    emitRideAvailable({
      rideId: updatedRide.ride_id,
      emptySeats: Number(updatedRide.available_seats || 0),
      vehicleType: updatedRide.vehicle_type,
      pickupLocation: updatedRide.start_location,
      destinationLocation: updatedRide.destination,
    });

    try {
      await notifyUsersForRide({ ride: updatedRide });
    } catch (notifyError) {
      console.error('notifyUsersForRide error:', notifyError.message);
    }
  }

  return updatedRide;
};

/* =========================
   MY CREATED RIDES
   Frontend: rider created ride list
========================= */
const listMyCreatedRides = async (riderId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM rides
     WHERE rider_id = $1
     ORDER BY created_at DESC`,
    [riderId]
  );

  return result.rows;
};

/* =========================
   JOINED RIDES
   Frontend: passenger joined rides page
========================= */
const listJoinedRides = async (passengerId) => {
  const result = await rideDb.query(
    `SELECT
        rp.participant_id,
        rp.ride_id,
        rp.passenger_id,
        rp.fare,
        rp.confirmed,
        rp.created_at AS joined_at,
        r.rider_id,
        r.start_location,
        r.destination,
        r.total_distance_km,
        r.per_km_rate,
        r.total_fare,
        r.available_seats,
        r.status,
        r.travel_date,
        r.travel_time,
        r.vehicle_type,
        r.created_at,
        u.first_name,
        u.last_name,
        u.phone
     FROM ride_participants rp
     JOIN rides r
       ON rp.ride_id = r.ride_id
     JOIN users u
       ON r.rider_id = u.user_id
     WHERE rp.passenger_id = $1
     ORDER BY r.created_at DESC`,
    [passengerId]
  );

  return result.rows;
};

/* =========================
   SEARCH RIDES
   Frontend: PlanYourRidePage / ReserveRideSearch
========================= */
const searchRides = async (payload) => {
  const {
    pickup_lat,
    pickup_lng,
    destination_lat,
    destination_lng,
  } = payload;

  const pickupLat = validateCoordinate(pickup_lat, -90, 90, 'pickup_lat');
  const pickupLng = validateCoordinate(pickup_lng, -180, 180, 'pickup_lng');
  const destinationLat = validateCoordinate(destination_lat, -90, 90, 'destination_lat');
  const destinationLng = validateCoordinate(destination_lng, -180, 180, 'destination_lng');

  const distanceKmRaw = calculateHaversineDistanceKm(
    pickupLat,
    pickupLng,
    destinationLat,
    destinationLng
  );

  const distanceKm = Number(distanceKmRaw.toFixed(2));

  const averageSpeedKmPerHour = 25;
  const estimatedTimeMinutes = Math.max(
    1,
    Math.round((distanceKm / averageSpeedKmPerHour) * 60)
  );

  const rateResult = await rideDb.query(
    `SELECT COALESCE(AVG(per_km_rate), 25)::numeric(10,2) AS avg_per_km_rate
     FROM rides
     WHERE status = 'assigned'
       AND available_seats > 0
       AND per_km_rate IS NOT NULL
       AND per_km_rate > 0`
  );

  const avgPerKmRate = Number(rateResult.rows[0]?.avg_per_km_rate || 25);
  const estimatedFare = Number((distanceKm * avgPerKmRate).toFixed(2));

  const ridesResult = await rideDb.query(
    `SELECT
        r.ride_id,
        r.start_location,
        r.destination,
        r.total_distance_km,
        r.per_km_rate,
        r.total_fare,
        r.available_seats,
        r.status,
        r.created_at,
        r.travel_date,
        r.travel_time,
        u.user_id AS rider_id,
        u.first_name,
        u.last_name,
        u.phone,
        u.rating,
        v.vehicle_type,
        v.company,
        v.model
     FROM rides r
     INNER JOIN users u
       ON r.rider_id = u.user_id
     LEFT JOIN vehicles v
       ON r.vehicle_id = v.vehicle_id
     WHERE r.status = 'assigned'
       AND r.available_seats > 0
     ORDER BY r.created_at DESC
     LIMIT 20`
  );

  const availableRides = ridesResult.rows.map((row) => ({
    ride_id: row.ride_id,
    start_location: row.start_location,
    destination: row.destination,
    total_distance_km: row.total_distance_km,
    per_km_rate: row.per_km_rate,
    total_fare: row.total_fare,
    available_seats: row.available_seats,
    ride_status: row.status,
    created_at: row.created_at,
    travel_date: row.travel_date,
    travel_time: row.travel_time,
    rider: {
      rider_id: row.rider_id,
      name: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
      phone: row.phone,
      rating: row.rating,
    },
    vehicle_type: row.vehicle_type,
    company: row.company,
    model: row.model,
    display_text: formatRideDisplayText({
      start_location: row.start_location,
      destination: row.destination,
      vehicle_type: row.vehicle_type,
      total_fare: row.total_fare,
    }),
  }));

  return {
    distance_km: distanceKm,
    estimated_time: estimatedTimeMinutes,
    estimated_fare: estimatedFare,
    routeDistanceKm: distanceKm,
    estimatedTravelMinutes: estimatedTimeMinutes,
    totalCost: estimatedFare,
    availableRides,
  };
};

module.exports = {
  createRide,
  listActiveRides,
  getRideDetails,
  joinRide,
  confirmParticipant,
  changeRideStatus,
  listMyCreatedRides,
  listJoinedRides,
  searchRides,
};