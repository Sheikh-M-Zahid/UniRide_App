const rideDb = require('../config/rideDb');

// =========================
// Common helpers
// =========================
const toRadians = (degree) => degree * (Math.PI / 180);

const calculateHaversineDistanceKm = (lat1, lng1, lat2, lng2) => {
  const R = 6371; // Earth radius in KM

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

const formatRideDisplayText = (ride) => {
  return `${ride.start_location} → ${ride.destination} | ${
    ride.vehicle_type || 'vehicle'
  } | Fare: BDT ${ride.total_fare}`;
};

// =========================
// Create ride
// =========================
const createRide = async (userId, payload) => {
  const {
    vehicle_id,
    start_location,
    destination,
    total_distance_km,
    per_km_rate,
    total_fare,
    available_seats,
    status,
  } = payload;

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
      status
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
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
      status || 'active',
    ]
  );

  return result.rows[0];
};

// =========================
// List active rides
// =========================
const listActiveRides = async () => {
  const result = await rideDb.query(
    `SELECT 
        r.*,
        u.first_name,
        u.last_name,
        u.university_email,
        u.phone,
        u.rating,
        v.vehicle_type,
        v.company,
        v.model,
        v.number_plate
     FROM rides r
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
     WHERE LOWER(r.status) IN ('active', 'reserve', 'processing')
       AND r.available_seats > 0
     ORDER BY r.created_at DESC`
  );

  return result.rows;
};

// =========================
// Ride details
// =========================
const getRideDetails = async (rideId) => {
  const rideResult = await rideDb.query(
    `SELECT 
        r.*,
        u.first_name,
        u.last_name,
        u.university_email,
        u.phone,
        u.rating,
        v.vehicle_type,
        v.company,
        v.model,
        v.number_plate,
        v.total_seats
     FROM rides r
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
     WHERE r.ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const participantsResult = await rideDb.query(
    `SELECT 
        rp.*,
        u.first_name,
        u.last_name,
        u.university_email,
        u.phone
     FROM ride_participants rp
     JOIN users u ON rp.passenger_id = u.user_id
     WHERE rp.ride_id = $1
     ORDER BY rp.participant_id DESC`,
    [rideId]
  );

  return {
    ride: rideResult.rows[0],
    participants: participantsResult.rows,
  };
};

// =========================
// Join ride
// =========================
const joinRide = async (rideId, passengerId, fare) => {
  const rideResult = await rideDb.query(
    `SELECT * FROM rides WHERE ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const ride = rideResult.rows[0];

  if (ride.rider_id === passengerId) {
    throw new Error('Rider cannot join own ride.');
  }

  if (String(ride.status).toLowerCase() !== 'active') {
    throw new Error('This ride is not available for joining.');
  }

  const existing = await rideDb.query(
    `SELECT participant_id
     FROM ride_participants
     WHERE ride_id = $1 AND passenger_id = $2`,
    [rideId, passengerId]
  );

  if (existing.rowCount > 0) {
    throw new Error('You already joined this ride.');
  }

  const totalJoinedResult = await rideDb.query(
    `SELECT COUNT(*)::int AS total
     FROM ride_participants
     WHERE ride_id = $1`,
    [rideId]
  );

  if (totalJoinedResult.rows[0].total >= Number(ride.available_seats)) {
    throw new Error('No available seats left.');
  }

  const result = await rideDb.query(
    `INSERT INTO ride_participants (
      ride_id,
      passenger_id,
      fare,
      rider_payment,
      confirmed
    )
    VALUES ($1, $2, $3, 'Unpaid', FALSE)
    RETURNING *`,
    [rideId, passengerId, fare]
  );

  return result.rows[0];
};

// =========================
// Confirm participant
// =========================
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

// =========================
// Change ride status
// =========================
const changeRideStatus = async (rideId, riderId, status) => {
  const result = await rideDb.query(
    `UPDATE rides
     SET status = $1
     WHERE ride_id = $2 AND rider_id = $3
     RETURNING *`,
    [status, rideId, riderId]
  );

  if (result.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  return result.rows[0];
};

// My created rides
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

// =========================
// Joined rides
// =========================
const listJoinedRides = async (passengerId) => {
  const result = await rideDb.query(
    `SELECT 
        rp.*,
        r.*,
        u.first_name,
        u.last_name,
        u.phone
     FROM ride_participants rp
     JOIN rides r ON rp.ride_id = r.ride_id
     JOIN users u ON r.rider_id = u.user_id
     WHERE rp.passenger_id = $1
     ORDER BY r.created_at DESC`,
    [passengerId]
  );

  return result.rows;
};

// =========================
// Search rides for PlanYourRidePage
// =========================
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
     WHERE LOWER(status) = 'active'
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
     WHERE LOWER(r.status) = 'active'
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

    // frontend-friendly aliases
    routeDistanceKm: distanceKm,
    estimatedTravelMinutes: estimatedTimeMinutes,
    totalCost: estimatedFare,
    availableRides,
  };
};

const getDashboardSummary = async (userId) => {
  // 1. Online status
  const userRes = await rideDb.query(
    `SELECT is_online FROM users WHERE user_id = $1`,
    [userId]
  );

  // 2. Today earnings
  const earningsRes = await rideDb.query(
    `SELECT COALESCE(SUM(amount),0) AS total
     FROM transactions
     WHERE user_id = $1
     AND DATE(created_at) = CURRENT_DATE`,
    [userId]
  );

  // 3. Active ride
  const activeRide = await rideDb.query(
    `SELECT * FROM rides
     WHERE rider_id = $1
     AND status IN ('accepted','ongoing')
     LIMIT 1`,
    [userId]
  );

  // 4. Upcoming ride
  const upcoming = await rideDb.query(
    `SELECT * FROM rides
     WHERE rider_id = $1
     AND status = 'scheduled'
     ORDER BY created_at ASC
     LIMIT 1`,
    [userId]
  );

  // 5. Notifications (simple count example)
  const notificationCount = 0;

  return {
    is_online: userRes.rows[0]?.is_online || false,
    today_earnings: earningsRes.rows[0].total,
    notification_count: notificationCount,
    active_ride: activeRide.rows[0] || null,
    upcoming_reserved_ride: upcoming.rows[0] || null,
  };
};

const updateStatus = async (userId, status) => {
  await rideDb.query(
    `UPDATE users SET is_online = $1 WHERE user_id = $2`,
    [status, userId]
  );

  return { message: "Status updated" };
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
  getDashboardSummary,
  updateStatus,
};